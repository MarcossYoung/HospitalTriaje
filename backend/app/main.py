from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.routers import admin, auth, hospitals, patients, stream, triage


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    yield
    # Shutdown — close SSE manager
    from app.services.sse_manager import sse_manager
    await sse_manager.close_all()


app = FastAPI(
    title="HospitalTriaje API",
    description="Sistema de triaje hospitalario basado en el Manchester Triage System",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    # Allow any localhost port in dev (covers flutter run -d chrome random ports)
    allow_origin_regex=r"http://localhost:\d+" if settings.app_env == "development" else None,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Routers
app.include_router(auth.router, prefix="/auth", tags=["auth"])
app.include_router(triage.router, prefix="/triage", tags=["triage"])
app.include_router(stream.router, prefix="/hospitals", tags=["stream"])
app.include_router(admin.router, prefix="/hospitals", tags=["admin"])
app.include_router(hospitals.router, prefix="/hospitals", tags=["hospitals"])
app.include_router(patients.router, prefix="/patients", tags=["patients"])


@app.get("/health", tags=["health"])
async def health_check():
    return {"status": "ok"}
