import json
import secrets
from datetime import datetime, timedelta, timezone

import bcrypt
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.database import get_db
from app.middleware.hospital_token import verify_hospital_token
from app.models.hospital import Hospital
from app.models.hospital_status import HospitalStatus
from app.models.on_call_doctor import OnCallDoctor
from app.models.obra_social import HospitalObraSocial, ObraSocial
from app.models.specialty import HospitalSpecialty
from app.schemas.hospital import (
    BedsUpdate,
    HospitalObrasSocialesUpdate,
    OnCallDoctorCreate,
    OnCallDoctorOut,
    ObraSocialOut,
    SpecialtyScheduleUpdate,
    TokenRotateOut,
)
from app.services.sse_manager import sse_manager

router = APIRouter()


# ─── Obras sociales (static paths first to avoid /{hospital_id} capture) ─────


@router.get("/obras-sociales", response_model=list[ObraSocialOut])
async def list_obras_sociales(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(ObraSocial).order_by(ObraSocial.name))
    return result.scalars().all()


# ─── On-call doctors ──────────────────────────────────────────────────────────


@router.get("/{hospital_id}/on-call", response_model=list[OnCallDoctorOut])
async def list_on_call_doctors(hospital_id: int, db: AsyncSession = Depends(get_db)):
    now = datetime.now(timezone.utc)
    window = now + timedelta(hours=24)
    result = await db.execute(
        select(OnCallDoctor)
        .options(selectinload(OnCallDoctor.specialty))
        .where(
            OnCallDoctor.hospital_id == hospital_id,
            OnCallDoctor.shift_end >= now,
            OnCallDoctor.shift_start <= window,
        )
    )
    doctors = result.scalars().all()
    return [
        OnCallDoctorOut(
            id=d.id,
            hospital_id=d.hospital_id,
            doctor_name=d.doctor_name,
            specialty_id=d.specialty_id,
            specialty_name=d.specialty.name_es if d.specialty else None,
            shift_start=d.shift_start,
            shift_end=d.shift_end,
            created_at=d.created_at,
        )
        for d in doctors
    ]


@router.post("/{hospital_id}/on-call", response_model=OnCallDoctorOut, status_code=201)
async def add_on_call_doctor(
    hospital_id: int,
    body: OnCallDoctorCreate,
    hospital: Hospital = Depends(verify_hospital_token),
    db: AsyncSession = Depends(get_db),
):
    doctor = OnCallDoctor(
        hospital_id=hospital_id,
        doctor_name=body.doctor_name,
        specialty_id=body.specialty_id,
        shift_start=body.shift_start,
        shift_end=body.shift_end,
    )
    db.add(doctor)
    await db.flush()
    await db.refresh(doctor, attribute_names=["id", "created_at"])
    # Resolve specialty name: refresh() does not trigger selectin relationships
    specialty_name = None
    if doctor.specialty_id is not None:
        from app.models.specialty import Specialty
        spec_result = await db.execute(
            select(Specialty).where(Specialty.id == doctor.specialty_id)
        )
        spec = spec_result.scalar_one_or_none()
        specialty_name = spec.name_es if spec else None
    return OnCallDoctorOut(
        id=doctor.id,
        hospital_id=doctor.hospital_id,
        doctor_name=doctor.doctor_name,
        specialty_id=doctor.specialty_id,
        specialty_name=specialty_name,
        shift_start=doctor.shift_start,
        shift_end=doctor.shift_end,
        created_at=doctor.created_at,
    )


@router.delete("/{hospital_id}/on-call/{doctor_id}", status_code=204)
async def remove_on_call_doctor(
    hospital_id: int,
    doctor_id: int,
    hospital: Hospital = Depends(verify_hospital_token),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(OnCallDoctor).where(
            OnCallDoctor.id == doctor_id,
            OnCallDoctor.hospital_id == hospital_id,
        )
    )
    doctor = result.scalar_one_or_none()
    if not doctor:
        raise HTTPException(status_code=404, detail="Médico no encontrado")
    await db.delete(doctor)


# ─── Obras sociales (hospital-specific) ──────────────────────────────────────


@router.get("/{hospital_id}/obras-sociales", response_model=list[ObraSocialOut])
async def get_hospital_obras_sociales(hospital_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(ObraSocial)
        .join(HospitalObraSocial, HospitalObraSocial.obra_social_id == ObraSocial.id)
        .where(HospitalObraSocial.hospital_id == hospital_id)
        .order_by(ObraSocial.name)
    )
    return result.scalars().all()


@router.put("/{hospital_id}/obras-sociales")
async def update_hospital_obras_sociales(
    hospital_id: int,
    body: HospitalObrasSocialesUpdate,
    hospital: Hospital = Depends(verify_hospital_token),
    db: AsyncSession = Depends(get_db),
):
    await db.execute(
        delete(HospitalObraSocial).where(HospitalObraSocial.hospital_id == hospital_id)
    )
    for obra_social_id in body.obra_social_ids:
        db.add(HospitalObraSocial(hospital_id=hospital_id, obra_social_id=obra_social_id))
    await db.flush()
    return {"status": "ok"}


# ─── Walk-in / beds ───────────────────────────────────────────────────────────


@router.post("/{hospital_id}/walk-in")
async def walk_in(
    hospital_id: int,
    hospital: Hospital = Depends(verify_hospital_token),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(HospitalStatus).where(HospitalStatus.hospital_id == hospital_id))
    status_row = result.scalar_one_or_none()
    if not status_row:
        raise HTTPException(status_code=404, detail="Estado del hospital no encontrado")
    status_row.wait_time_min += 10
    status_row.updated_at = datetime.now(timezone.utc)
    await db.flush()

    await sse_manager.broadcast(
        "hospitals",
        {
            "hospital_id": hospital_id,
            "wait_time_min": status_row.wait_time_min,
            "available_beds": status_row.available_beds,
            "updated_at": datetime.now(timezone.utc).isoformat(),
        },
    )
    return {"wait_time_min": status_row.wait_time_min}


@router.post("/{hospital_id}/beds")
async def update_beds(
    hospital_id: int,
    body: BedsUpdate,
    hospital: Hospital = Depends(verify_hospital_token),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(HospitalStatus).where(HospitalStatus.hospital_id == hospital_id))
    status_row = result.scalar_one_or_none()
    if not status_row:
        raise HTTPException(status_code=404, detail="Estado del hospital no encontrado")
    status_row.available_beds = body.available_beds
    status_row.updated_at = datetime.now(timezone.utc)
    await db.flush()

    await sse_manager.broadcast(
        "hospitals",
        {
            "hospital_id": hospital_id,
            "wait_time_min": status_row.wait_time_min,
            "available_beds": status_row.available_beds,
            "updated_at": datetime.now(timezone.utc).isoformat(),
        },
    )
    return {"available_beds": status_row.available_beds}


# ─── Specialty weekly schedule ─────────────────────────────────────────────────


@router.put("/{hospital_id}/specialties/{specialty_id}/schedule")
async def update_specialty_schedule(
    hospital_id: int,
    specialty_id: int,
    body: SpecialtyScheduleUpdate,
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
    hs.schedule_json = json.dumps(body.schedule)
    await db.flush()
    return {"status": "ok", "schedule": body.schedule}


# ─── Token rotation ────────────────────────────────────────────────────────────


@router.post("/{hospital_id}/token", response_model=TokenRotateOut)
async def rotate_token(
    hospital_id: int,
    hospital: Hospital = Depends(verify_hospital_token),
    db: AsyncSession = Depends(get_db),
):
    new_token = secrets.token_urlsafe(32)
    hospital.api_token_hash = bcrypt.hashpw(
        new_token.encode(), bcrypt.gensalt()
    ).decode()
    await db.flush()
    return TokenRotateOut(token=new_token)
