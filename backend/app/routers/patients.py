from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models.patient import Patient
from app.schemas.patient import FcmTokenUpdate, PatientProfile
from app.schemas.triage import TriageSessionOut
from app.services.deps import get_current_patient

router = APIRouter()


@router.get("/me", response_model=PatientProfile)
async def get_profile(patient: Patient = Depends(get_current_patient)):
    return PatientProfile(
        id=patient.id,
        email=patient.email,
        google_id=patient.google_id,
        fcm_token=patient.fcm_token,
    )


@router.post("/me/fcm-token")
async def update_fcm_token(
    body: FcmTokenUpdate,
    patient: Patient = Depends(get_current_patient),
    db: AsyncSession = Depends(get_db),
):
    patient.fcm_token = body.fcm_token
    return {"status": "ok"}


@router.get("/me/evaluations", response_model=list[TriageSessionOut])
async def get_evaluations(patient: Patient = Depends(get_current_patient)):
    return [
        TriageSessionOut(
            id=s.id,
            level=s.level,
            complaint_category=s.complaint_category,
            max_wait_minutes=s.max_wait_minutes,
            created_at=s.created_at.isoformat(),
        )
        for s in patient.triage_sessions
    ]


@router.delete("/me")
async def delete_account(
    patient: Patient = Depends(get_current_patient),
    db: AsyncSession = Depends(get_db),
):
    await db.delete(patient)
    return {"status": "deleted"}
