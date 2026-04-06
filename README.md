# HospitalTriaje

Sistema de triaje hospitalario basado en el **Manchester Triage System (MTS)** — aplicación cross-platform (Android · iOS · Web) con backend FastAPI y PostgreSQL.

---

## Tabla de contenidos

- [Arquitectura](#arquitectura)
- [Inicio rápido](#inicio-rápido)
- [API Reference](#api-reference)
- [Panel de administración](#panel-de-administración)
- [Tests del backend](#tests-del-backend)
- [Niveles MTS](#niveles-mts)
- [Variables de entorno](#variables-de-entorno)
- [Estructura del proyecto](#estructura-del-proyecto)
- [Base de datos](#base-de-datos)

---

## Arquitectura

| Capa | Tecnología |
|---|---|
| Frontend | Flutter 3.x (Android + iOS + Web) |
| Backend | Python 3.12 + FastAPI (async) |
| Base de datos | PostgreSQL 16 + SQLAlchemy async + Alembic |
| Estado (frontend) | Riverpod + GoRouter |
| Mapas | Google Maps Platform (`google_maps_flutter`) |
| Tiempo real | Server-Sent Events (SSE) — asyncio, sin Redis |
| Notificaciones | Firebase Cloud Messaging (FCM) + APNs |
| Caché offline | Hive (árbol de preguntas MTS + tips de emergencia) |
| Contenedores | Docker + docker-compose |

---

## Inicio rápido

### 1. Clonar y configurar variables de entorno

```bash
git clone <repo-url>
cd HospitalTriaje
cp .env.example .env
# Editar .env con las credenciales reales
```

### 2. Levantar con Docker Compose

```bash
docker-compose up --build
```

Al iniciar se ejecuta automáticamente:
- PostgreSQL en el puerto **5432**
- Migraciones (`alembic upgrade head`)
- Seed inicial (hospitales, especialidades, obras sociales)
- API en **http://localhost:8000**
- Frontend web en **http://localhost:80**
- PgAdmin en **http://localhost:5050**

### 3. Verificar la API

```bash
curl http://localhost:8000/health
# {"status": "ok"}
```

### 4. Flutter — desarrollo local

```bash
cd frontend
flutter pub get

# Web
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000

# Android emulator
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

---

## API Reference

### Salud

| Método | Ruta | Auth | Descripción |
|---|---|---|---|
| GET | `/health` | — | Estado del servidor |

### Triaje

| Método | Ruta | Auth | Descripción |
|---|---|---|---|
| GET | `/triage/questions` | — | Árbol de preguntas MTS completo |
| POST | `/triage/evaluate` | JWT opcional | Evaluar respuestas → nivel MTS |

### Hospitales

| Método | Ruta | Auth | Descripción |
|---|---|---|---|
| GET | `/hospitals/nearby` | — | Lista ordenada por score (distancia + espera + urgencia) |
| GET | `/hospitals/{id}` | — | Detalle del hospital |
| PUT | `/hospitals/{id}/info` | API Token | Actualizar dirección y teléfono |
| POST | `/hospitals/{id}/status` | API Token | Actualizar tiempo de espera y camas |
| POST | `/hospitals/{id}/beds` | API Token | Actualizar camas disponibles |
| POST | `/hospitals/{id}/walk-in` | API Token | Registrar paciente sin turno (+10 min) |
| POST | `/hospitals/{id}/specialists/{sid}/override` | API Token | Sobreescribir disponibilidad de especialidad |
| PUT | `/hospitals/{id}/specialties/{sid}/schedule` | API Token | Actualizar horario semanal de especialidad |
| POST | `/hospitals/{id}/token` | API Token | Rotar token de acceso del hospital |
| GET | `/hospitals/stream` | — | SSE: actualizaciones en tiempo real |
| POST | `/hospitals/referrals` | — | Crear derivación |

> **Parámetros de `/hospitals/nearby`:**
> `lat`, `lng` (requeridos) · `specialty` (slug) · `level` (nivel MTS 1–5)
>
> Scoring: `dist × dist_w + wait × wait_w − specialty_match × 2` (menor = mejor)
>
> | `level` | `dist_w` | `wait_w` | Filtro extra |
> |---|---|---|---|
> | 1 (Inmediato) | 0.2 | 0.8 | Excluye hospitales con 0 camas |
> | 2 (Muy urgente) | 0.2 | 0.8 | — |
> | 3–5 o sin nivel | 0.4 | 0.4 | — |

### Obras sociales

| Método | Ruta | Auth | Descripción |
|---|---|---|---|
| GET | `/hospitals/obras-sociales` | — | Catálogo completo |
| GET | `/hospitals/{id}/obras-sociales` | — | Coberturas del hospital |
| PUT | `/hospitals/{id}/obras-sociales` | API Token | Actualizar coberturas |

### Médicos de guardia

| Método | Ruta | Auth | Descripción |
|---|---|---|---|
| GET | `/hospitals/{id}/on-call` | — | Médicos con turno activo (ventana 24 h) |
| POST | `/hospitals/{id}/on-call` | API Token | Agregar médico de guardia |
| DELETE | `/hospitals/{id}/on-call/{did}` | API Token | Eliminar médico de guardia |

### Autenticación y pacientes

| Método | Ruta | Auth | Descripción |
|---|---|---|---|
| POST | `/auth/register` | — | Registro con email/contraseña |
| POST | `/auth/login` | — | Inicio de sesión |
| POST | `/auth/google` | — | OAuth Google |
| GET | `/patients/me` | JWT | Perfil del paciente |
| POST | `/patients/me/fcm-token` | JWT | Registrar token FCM |
| GET | `/patients/me/evaluations` | JWT | Historial de evaluaciones |
| DELETE | `/patients/me` | JWT | Eliminar cuenta |

---

## Panel de administración

Cada hospital tiene un panel accesible desde la app en `/hospitals/:id/admin`.
El acceso requiere el **API Token** del hospital (almacenado de forma segura con `flutter_secure_storage`).

### Funcionalidades

| Sección | Descripción |
|---|---|
| **Perfil** | Ver y editar dirección y teléfono del hospital |
| **Estado** | Actualizar camas disponibles · registrar walk-in (+10 min espera) |
| **Médicos de guardia** | Agregar/eliminar médicos con especialidad y turno |
| **Obras sociales** | Seleccionar coberturas aceptadas del catálogo precargado |
| **Token** | Cambiar el token de acceso del hospital |

### Tokens de los hospitales seed

```
Hospital 1: token-hospital-1-change-in-prod
Hospital 2: token-hospital-2-change-in-prod
...
```

> Cambiar todos los tokens antes de usar en producción.

### Ejemplos con curl

```bash
# Actualizar estado
curl -X POST http://localhost:8000/hospitals/1/status \
  -H "X-API-Token: token-hospital-1-change-in-prod" \
  -H "Content-Type: application/json" \
  -d '{"wait_time_min": 45, "available_beds": 12}'

# Actualizar perfil
curl -X PUT http://localhost:8000/hospitals/1/info \
  -H "X-API-Token: token-hospital-1-change-in-prod" \
  -H "Content-Type: application/json" \
  -d '{"address": "Av. Corrientes 1234", "phone": "+54 11 4000-0000"}'

# Agregar médico de guardia
curl -X POST http://localhost:8000/hospitals/1/on-call \
  -H "X-API-Token: token-hospital-1-change-in-prod" \
  -H "Content-Type: application/json" \
  -d '{"doctor_name": "Dr. García", "specialty_id": 1, "shift_start": "2026-03-19T08:00:00Z", "shift_end": "2026-03-19T20:00:00Z"}'

# Actualizar coberturas
curl -X PUT http://localhost:8000/hospitals/1/obras-sociales \
  -H "X-API-Token: token-hospital-1-change-in-prod" \
  -H "Content-Type: application/json" \
  -d '{"obra_social_ids": [1, 2, 5]}'

# Actualizar horario semanal de una especialidad
curl -X PUT http://localhost:8000/hospitals/1/specialties/2/schedule \
  -H "X-API-Token: token-hospital-1-change-in-prod" \
  -H "Content-Type: application/json" \
  -d '{"schedule": {"mon": ["08:00-20:00"], "tue": ["08:00-20:00"], "sat": ["09:00-14:00"]}}'

# Rotar token de acceso
curl -X POST http://localhost:8000/hospitals/1/token \
  -H "X-API-Token: token-hospital-1-change-in-prod"
# Responde con el nuevo token en texto plano — guardarlo inmediatamente

# Escuchar SSE
curl -N http://localhost:8000/hospitals/stream
```

---

## Gestión sin la app (API externa)

Todos los endpoints de gestión aceptan el header `X-API-Token` y pueden usarse directamente desde cualquier sistema externo (HIS hospitalario, scripts de automatización, Postman, etc.) sin abrir la app Flutter.

### Operaciones disponibles

| Operación | Endpoint | Body |
|---|---|---|
| Actualizar dirección/teléfono | `PUT /hospitals/{id}/info` | `{"address": "...", "phone": "..."}` |
| Registrar paciente walk-in (+10 min) | `POST /hospitals/{id}/walk-in` | — |
| Actualizar espera y camas | `POST /hospitals/{id}/status` | `{"wait_time_min": N, "available_beds": N}` |
| Actualizar solo camas | `POST /hospitals/{id}/beds` | `{"available_beds": N}` |
| Horario semanal de especialidad | `PUT /hospitals/{id}/specialties/{sid}/schedule` | `{"schedule": {"mon": ["HH:MM-HH:MM"]}}` |
| Médico de guardia: agregar | `POST /hospitals/{id}/on-call` | `{"doctor_name": "...", "specialty_id": N, "shift_start": "ISO8601", "shift_end": "ISO8601"}` |
| Médico de guardia: eliminar | `DELETE /hospitals/{id}/on-call/{did}` | — |
| Coberturas de obra social | `PUT /hospitals/{id}/obras-sociales` | `{"obra_social_ids": [1, 2, 3]}` |
| Rotar token | `POST /hospitals/{id}/token` | — |

---

## Tests del backend

```bash
cd backend
pip install -r requirements.txt
pytest -v

# Con cobertura
pytest -v --cov=app --cov-report=term-missing
```

Los tests usan SQLite en memoria (aiosqlite). No requieren PostgreSQL ni Docker.

---

## Niveles MTS

| Nivel | Color | Nombre | Tiempo máx. |
|---|---|---|---|
| 1 | Rojo | Inmediato | 0 min |
| 2 | Naranja | Muy urgente | 10 min |
| 3 | Amarillo | Urgente | 60 min |
| 4 | Verde | Menos urgente | 120 min |
| 5 | Azul | No urgente | 240 min |

---

## Variables de entorno

Ver `.env.example` para la lista completa.

| Variable | Descripción |
|---|---|
| `DATABASE_URL` | URL de conexión PostgreSQL (`postgresql+asyncpg://...`) |
| `SECRET_KEY` | Clave secreta JWT (mínimo 32 caracteres en producción) |
| `ALGORITHM` | Algoritmo JWT (default: `HS256`) |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | Duración del token (default: `30`) |
| `GOOGLE_CLIENT_ID` | Client ID para OAuth de Google |
| `FIREBASE_CREDENTIALS_JSON` | Ruta al JSON de credenciales Firebase Admin SDK |
| `GOOGLE_MAPS_API_KEY` | Clave de Google Maps Platform |

---

## Estructura del proyecto

```
HospitalTriaje/
├── backend/
│   ├── app/
│   │   ├── main.py                     # App factory, lifespan, routers
│   │   ├── config.py                   # pydantic-settings
│   │   ├── database.py                 # Engine async + get_db()
│   │   ├── models/                     # SQLAlchemy ORM
│   │   ├── schemas/                    # Pydantic request/response
│   │   ├── routers/                    # Endpoints REST
│   │   │   ├── auth.py
│   │   │   ├── hospitals.py
│   │   │   ├── admin.py
│   │   │   ├── triage.py
│   │   │   ├── patients.py
│   │   │   └── stream.py
│   │   ├── services/
│   │   │   ├── triage_engine.py        # Traversal árbol MTS
│   │   │   ├── hospital_routing.py     # Scoring dinámico por nivel MTS
│   │   │   └── sse_manager.py          # asyncio pub/sub
│   │   ├── middleware/
│   │   │   └── hospital_token.py       # Verificación bcrypt X-API-Token
│   │   └── seed/
│   │       ├── hospitals.json
│   │       ├── obras_sociales.json
│   │       ├── question_tree.json      # Árbol de preguntas MTS
│   │       └── run_seed.py
│   ├── alembic/versions/
│   │   ├── 0001_initial_schema.py
│   │   └── 0002_admin_features.py
│   └── tests/
├── frontend/
│   └── lib/
│       ├── core/
│       │   ├── router/app_router.dart
│       │   ├── theme/app_theme.dart    # TriageColors.forLevel()
│       │   ├── network/api_client.dart
│       │   └── constants/app_constants.dart
│       ├── features/
│       │   ├── triage/                 # TriageScreen → TriageResultScreen (pasa level al navegar)
│       │   ├── hospitals/              # Lista (banner urgencia) · Detalle · Admin (perfil + ops)
│       │   ├── auth/
│       │   │   ├── screens/
│       │   │   │   ├── auth_screen.dart
│       │   │   │   ├── profile_screen.dart      # Carga token async, sign-out, → evaluaciones
│       │   │   │   └── evaluations_screen.dart  # Historial de triajes con badge MTS
│       │   │   └── providers/auth_provider.dart # initializing flag evita race condition
│       │   ├── map/
│       │   └── emergency/
│       └── shared/widgets/
└── docker-compose.yml
```

---

## Base de datos

| Tabla | Migración | Descripción |
|---|---|---|
| `hospitals` | 0001 | Hospitales con coordenadas y hash del token |
| `hospital_status` | 0001 | Tiempo de espera y camas disponibles |
| `specialties` | 0001 | Catálogo de especialidades médicas |
| `hospital_specialty` | 0001 | Relación hospital–especialidad con horario y override |
| `patients` | 0001 | Pacientes registrados |
| `triage_sessions` | 0001 | Sesiones de triaje con nivel MTS 1–5 |
| `referrals` | 0001 | Derivaciones paciente→hospital |
| `obras_sociales` | 0002 | Catálogo de obras sociales (OSDE, PAMI, Swiss Medical…) |
| `hospital_obras_sociales` | 0002 | Coberturas aceptadas por hospital |
| `on_call_doctors` | 0002 | Médicos de guardia con turno y especialidad |
