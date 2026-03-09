"""FastAPI dependency helpers for optional / required auth."""
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models.patient import Patient
from app.services.auth import decode_token

_bearer = HTTPBearer(auto_error=False)


async def get_current_patient_optional(
    credentials: HTTPAuthorizationCredentials | None = Depends(_bearer),
    db: AsyncSession = Depends(get_db),
) -> Patient | None:
    if credentials is None:
        return None
    try:
        payload = decode_token(credentials.credentials)
        patient_id = int(payload["sub"])
    except (JWTError, KeyError, ValueError):
        return None
    result = await db.execute(select(Patient).where(Patient.id == patient_id))
    return result.scalar_one_or_none()


async def get_current_patient(
    patient: Patient | None = Depends(get_current_patient_optional),
) -> Patient:
    if patient is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="No autenticado")
    return patient
