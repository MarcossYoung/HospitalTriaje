# HospitalTriaje

Sistema de triaje hospitalario basado en el **Manchester Triage System (MTS)** — aplicación
cross-platform (Android · iOS · Web) con backend FastAPI y PostgreSQL.

---

## Arquitectura

| Capa | Tecnología |
|---|---|
| Frontend | Flutter 3.x (Android + iOS + Web) |
| Backend | Python 3.12 + FastAPI (async) |
| Base de datos | PostgreSQL 16 + SQLAlchemy async + Alembic |
| Mapas | Google Maps Platform (`google_maps_flutter`) |
| Tiempo real | Server-Sent Events (SSE) |
| Notificaciones | Firebase Cloud Messaging (FCM) + APNs |
| Caché offline | Hive (árbol de preguntas + tips de emergencia) |
| Contenedores | Docker + docker-compose |

---

## Inicio rápido

### 1. Clonar y configurar variables de entorno

```bash
git clone <repo-url>
cd HospitalTriaje
cp .env.example .env
# Editar .env con sus credenciales reales
```

### 2. Levantar con Docker Compose

```bash
docker-compose up --build
```

Esto:
- Levanta PostgreSQL en el puerto **5432**
- Ejecuta las migraciones (`alembic upgrade head`)
- Sembrado inicial de hospitales y especialidades
- Levanta la API en **http://localhost:8000**
- Levanta PgAdmin en **http://localhost:5050**

### 3. Verificar salud de la API

```bash
curl http://localhost:8000/health
# {"status": "ok"}
```

### 4. Ver árbol de triaje

```bash
curl http://localhost:8000/triage/questions
```

### 5. Flutter (web)

```bash
cd frontend
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000
```

### 6. Flutter (Android/iOS)

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000  # Android emulator
```

---

## API Referencia rápida

| Método | Ruta | Auth | Descripción |
|---|---|---|---|
| GET | `/health` | — | Estado del servidor |
| GET | `/triage/questions` | — | Árbol de preguntas MTS completo |
| POST | `/triage/evaluate` | Opcional JWT | Evaluar respuestas → nivel MTS |
| GET | `/hospitals/nearby` | — | Lista ordenada de hospitales |
| GET | `/hospitals/{id}` | — | Detalle del hospital |
| GET | `/hospitals/stream` | — | SSE: actualizaciones en tiempo real |
| POST | `/hospitals/{id}/status` | API Token | Actualizar tiempo de espera |
| POST | `/hospitals/{id}/specialists/{sid}/override` | API Token | Sobreescribir disponibilidad |
| POST | `/auth/register` | — | Registro con email |
| POST | `/auth/login` | — | Inicio de sesión |
| POST | `/auth/google` | — | OAuth Google |
| GET | `/patients/me` | JWT | Perfil del paciente |
| POST | `/patients/me/fcm-token` | JWT | Registrar token FCM |
| GET | `/patients/me/evaluations` | JWT | Historial de evaluaciones |
| POST | `/hospitals/referrals` | — | Crear derivación |

---

## Tokens de API para hospitales (staff)

Los tokens de los hospitales semilla son:
```
Hospital 1: token-hospital-1-change-in-prod
Hospital 2: token-hospital-2-change-in-prod
...
```

Actualizar estado de hospital:
```bash
curl -X POST http://localhost:8000/hospitals/1/status \
  -H "X-API-Token: token-hospital-1-change-in-prod" \
  -H "Content-Type: application/json" \
  -d '{"wait_time_min": 45, "available_beds": 12}'
```

Escuchar SSE en otra terminal:
```bash
curl -N http://localhost:8000/hospitals/stream
```

---

## Tests del backend

```bash
cd backend
pip install -r requirements.txt
pip install aiosqlite
pytest -v
```

---

## Niveles MTS

| Nivel | Color | Nombre | Tiempo máx. |
|---|---|---|---|
| 1 | 🔴 Rojo | Inmediato | 0 min |
| 2 | 🟠 Naranja | Muy urgente | 10 min |
| 3 | 🟡 Amarillo | Urgente | 60 min |
| 4 | 🟢 Verde | Menos urgente | 120 min |
| 5 | 🔵 Azul | No urgente | 240 min |

---

## Variables de entorno requeridas

Ver `.env.example` para la lista completa. Las más críticas:

- `DATABASE_URL` — URL de PostgreSQL
- `SECRET_KEY` — clave secreta JWT (mínimo 32 chars en producción)
- `GOOGLE_CLIENT_ID` — para OAuth de Google
- `FIREBASE_CREDENTIALS_JSON` — ruta al JSON de credenciales de Firebase Admin SDK

---

## Estructura del proyecto

```
HospitalTriaje/
├── backend/             # FastAPI + SQLAlchemy
│   ├── app/
│   │   ├── models/      # ORM models
│   │   ├── routers/     # Endpoints REST
│   │   ├── services/    # Lógica de negocio
│   │   ├── schemas/     # Pydantic schemas
│   │   ├── middleware/  # API token auth
│   │   └── seed/        # JSON data + seed script
│   ├── alembic/         # Migraciones DB
│   └── tests/           # pytest
├── frontend/            # Flutter
│   ├── lib/
│   │   ├── core/        # Theme, router, network
│   │   ├── features/    # triage, hospitals, map, auth, emergency
│   │   └── shared/      # Widgets compartidos
│   └── test/            # Flutter tests
└── docker-compose.yml
```
