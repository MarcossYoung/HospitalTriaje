import json
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.middleware.hospital_token import verify_hospital_token
from app.models.hospital import Hospital
from app.models.hospital_status import HospitalStatus
from app.models.referral import Referral
from app.models.specialty import HospitalSpecialty, Specialty
from app.schemas.hospital import (
    HospitalInfoUpdate,
    HospitalOut,
    HospitalStatusUpdate,
    NearbyHospitalOut,
    ReferralCreate,
    ReferralOut,
    SpecialtyOut,
    SpecialtyOverride,
)
from app.services.hospital_routing import get_nearby_hospitals, _is_specialty_available
from app.services.sse_manager import sse_manager

router = APIRouter()


def _build_hospital_out(h: Hospital) -> HospitalOut:
    specialties = []
    for hs in h.specialties:
        if hs.specialty:
            specialties.append(
                SpecialtyOut(
                    id=hs.specialty.id,
                    name_es=hs.specialty.name_es,
                    slug=hs.specialty.slug,
                    is_available=_is_specialty_available(hs),
                )
            )
    from app.schemas.hospital import HospitalStatusOut
    status_out = None
    if h.status:
        status_out = HospitalStatusOut(
            wait_time_min=h.status.wait_time_min,
            available_beds=h.status.available_beds,
            updated_at=h.status.updated_at,
        )
    return HospitalOut(
        id=h.id,
        name=h.name,
        address=h.address,
        lat=h.lat,
        lng=h.lng,
        phone=h.phone,
        status=status_out,
        specialties=specialties,
    )


@router.get("/nearby", response_model=list[NearbyHospitalOut])
async def nearby_hospitals(
    lat: float = Query(...),
    lng: float = Query(...),
    specialty: str | None = Query(None),
    level: int | None = Query(None),
    db: AsyncSession = Depends(get_db),
):
    scored = await get_nearby_hospitals(db, lat, lng, specialty, level)
    result = []
    for item in scored:
        h = item["hospital"]
        out = _build_hospital_out(h)
        result.append(
            NearbyHospitalOut(
                **out.model_dump(),
                distance_km=item["distance_km"],
                score=item["score"],
            )
        )
    return result


@router.get("/{hospital_id}", response_model=HospitalOut)
async def get_hospital(hospital_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Hospital).where(Hospital.id == hospital_id))
    h = result.scalar_one_or_none()
    if not h:
        raise HTTPException(status_code=404, detail="Hospital no encontrado")
    return _build_hospital_out(h)


@router.put("/{hospital_id}/info", response_model=HospitalOut)
async def update_hospital_info(
    hospital_id: int,
    body: HospitalInfoUpdate,
    hospital: Hospital = Depends(verify_hospital_token),
    db: AsyncSession = Depends(get_db),
):
    if body.address is not None:
        hospital.address = body.address
    if body.phone is not None:
        hospital.phone = body.phone
    await db.flush()
    return _build_hospital_out(hospital)


@router.post("/{hospital_id}/status")
async def update_hospital_status(
    hospital_id: int,
    body: HospitalStatusUpdate,
    hospital: Hospital = Depends(verify_hospital_token),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(HospitalStatus).where(HospitalStatus.hospital_id == hospital_id))
    status_row = result.scalar_one_or_none()
    if status_row:
        status_row.wait_time_min = body.wait_time_min
        status_row.available_beds = body.available_beds
        status_row.updated_at = datetime.now(timezone.utc)
    else:
        status_row = HospitalStatus(
            hospital_id=hospital_id,
            wait_time_min=body.wait_time_min,
            available_beds=body.available_beds,
        )
        db.add(status_row)
    await db.flush()

    await sse_manager.broadcast(
        "hospitals",
        {
            "hospital_id": hospital_id,
            "wait_time_min": body.wait_time_min,
            "available_beds": body.available_beds,
            "updated_at": datetime.now(timezone.utc).isoformat(),
        },
    )
    return {"status": "ok"}


@router.post("/{hospital_id}/specialists/{specialty_id}/override")
async def override_specialist(
    hospital_id: int,
    specialty_id: int,
    body: SpecialtyOverride,
    hospital: Hospital = Depends(verify_hospital_token),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(HospitalSpecialty).where(
            HospitalSpecialty.hospital_id == hospital_id,
            HospitalSpecialty.specialty_id == specialty_id,
        )
    )
    hs = result.scalar_one_or_none()
    if not hs:
        raise HTTPException(status_code=404, detail="Especialidad no encontrada en este hospital")
    hs.is_available_override = body.is_available
    hs.override_until = body.override_until
    return {"status": "ok"}


@router.post("/referrals", response_model=ReferralOut, status_code=201)
async def create_referral(body: ReferralCreate, db: AsyncSession = Depends(get_db)):
    from app.models.triage_session import TriageSession

    # Validate that session and hospital exist
    session_result = await db.execute(select(TriageSession).where(TriageSession.id == body.session_id))
    if not session_result.scalar_one_or_none():
        raise HTTPException(status_code=404, detail="Sesión de triaje no encontrada")
    hospital_result = await db.execute(select(Hospital).where(Hospital.id == body.hospital_id))
    if not hospital_result.scalar_one_or_none():
        raise HTTPException(status_code=404, detail="Hospital no encontrado")

    referral = Referral(session_id=body.session_id, hospital_id=body.hospital_id)
    db.add(referral)
    await db.flush()
    return ReferralOut(
        id=referral.id,
        session_id=referral.session_id,
        hospital_id=referral.hospital_id,
        status=referral.status,
        created_at=referral.created_at,
    )
