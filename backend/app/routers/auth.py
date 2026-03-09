from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models.patient import Patient
from app.schemas.auth import GoogleAuthRequest, LoginRequest, RegisterRequest, TokenResponse
from app.services.auth import create_access_token, hash_password, verify_google_id_token, verify_password

router = APIRouter()


@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
async def register(body: RegisterRequest, db: AsyncSession = Depends(get_db)):
    existing = await db.execute(select(Patient).where(Patient.email == body.email))
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=409, detail="Email ya registrado")
    patient = Patient(email=body.email, hashed_password=hash_password(body.password))
    db.add(patient)
    await db.flush()
    return TokenResponse(access_token=create_access_token(patient.id))


@router.post("/login", response_model=TokenResponse)
async def login(body: LoginRequest, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Patient).where(Patient.email == body.email))
    patient = result.scalar_one_or_none()
    if not patient or not patient.hashed_password or not verify_password(body.password, patient.hashed_password):
        raise HTTPException(status_code=401, detail="Credenciales inválidas")
    return TokenResponse(access_token=create_access_token(patient.id))


@router.post("/google", response_model=TokenResponse)
async def google_auth(body: GoogleAuthRequest, db: AsyncSession = Depends(get_db)):
    try:
        payload = await verify_google_id_token(body.id_token)
    except ValueError as exc:
        raise HTTPException(status_code=401, detail=str(exc)) from exc

    google_id = payload.get("sub")
    email = payload.get("email")

    result = await db.execute(select(Patient).where(Patient.google_id == google_id))
    patient = result.scalar_one_or_none()

    if not patient:
        # Try matching by email
        if email:
            result2 = await db.execute(select(Patient).where(Patient.email == email))
            patient = result2.scalar_one_or_none()
        if patient:
            patient.google_id = google_id
        else:
            patient = Patient(google_id=google_id, email=email)
            db.add(patient)
            await db.flush()

    return TokenResponse(access_token=create_access_token(patient.id))
