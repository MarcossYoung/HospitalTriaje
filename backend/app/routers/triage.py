import json

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models.patient import Patient
from app.models.triage_session import TriageSession
from app.schemas.triage import EvaluateRequest, TriageResult, TriageSessionOut
from app.services import triage_engine
from app.services.deps import get_current_patient_optional
from app.services.notification import send_triage_notification

router = APIRouter()


@router.get("/questions")
async def get_questions():
    """Return the full MTS question-tree JSON."""
    return triage_engine.get_full_tree()


@router.post("/evaluate", response_model=TriageResult)
async def evaluate_triage(
    body: EvaluateRequest,
    db: AsyncSession = Depends(get_db),
    patient: Patient | None = Depends(get_current_patient_optional),
):
    try:
        result = triage_engine.evaluate([a.model_dump() for a in body.answers])
    except ValueError as exc:
        raise HTTPException(status_code=422, detail=str(exc)) from exc

    session = TriageSession(
        patient_id=patient.id if patient else None,
        level=result["level"],
        complaint_category=result["complaint_category"],
        answers_json=json.dumps([a.model_dump() for a in body.answers]),
        max_wait_minutes=result["max_wait_minutes"],
    )
    db.add(session)
    await db.flush()

    if patient and patient.fcm_token:
        await send_triage_notification(patient.fcm_token, result["level"], result["label"])

    return TriageResult(session_id=session.id, **result)


@router.get("/sessions/{session_id}", response_model=TriageSessionOut)
async def get_session(session_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(TriageSession).where(TriageSession.id == session_id))
    session = result.scalar_one_or_none()
    if not session:
        raise HTTPException(status_code=404, detail="Sesión no encontrada")
    return TriageSessionOut(
        id=session.id,
        level=session.level,
        complaint_category=session.complaint_category,
        max_wait_minutes=session.max_wait_minutes,
        created_at=session.created_at.isoformat(),
    )
