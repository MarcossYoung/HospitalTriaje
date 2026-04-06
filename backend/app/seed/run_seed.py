"""
Seed the database from JSON files.
Run via:  python -m app.seed.run_seed
"""
import asyncio
import json
import logging
from pathlib import Path

import bcrypt as _bcrypt
from sqlalchemy import select, text, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import AsyncSessionLocal
from app.models.hospital import Hospital
from app.models.hospital_status import HospitalStatus
from app.models.obra_social import ObraSocial
from app.models.patient import Patient
from app.models.referral import Referral
from app.models.specialty import HospitalSpecialty, Specialty
from app.models.triage_session import TriageSession

logger = logging.getLogger(__name__)

SEED_DIR = Path(__file__).parent


async def seed_specialties(db: AsyncSession) -> dict[str, int]:
    """Seed specialties and return slug→id map."""
    data = json.loads((SEED_DIR / "specialists.json").read_text())
    slug_to_id: dict[str, int] = {}
    for item in data:
        result = await db.execute(select(Specialty).where(Specialty.slug == item["slug"]))
        sp = result.scalar_one_or_none()
        if not sp:
            sp = Specialty(name_es=item["name_es"], slug=item["slug"])
            db.add(sp)
            await db.flush()
            logger.info("Created specialty: %s", item["slug"])
        slug_to_id[item["slug"]] = sp.id
    return slug_to_id


async def seed_hospitals(db: AsyncSession) -> None:
    data = json.loads((SEED_DIR / "hospitals.json").read_text())
    for item in data:
        result = await db.execute(select(Hospital).where(Hospital.id == item["id"]))
        h = result.scalar_one_or_none()
        if not h:
            h = Hospital(
                id=item["id"],
                name=item["name"],
                address=item["address"],
                lat=item["lat"],
                lng=item["lng"],
                phone=item.get("phone"),
                api_token_hash=_bcrypt.hashpw(item["api_token"].encode(), _bcrypt.gensalt()).decode(),
            )
            db.add(h)
            await db.flush()
            # Create default status
            status = HospitalStatus(hospital_id=h.id, wait_time_min=30, available_beds=10)
            db.add(status)
            await db.flush()
            logger.info("Created hospital: %s", item["name"])
        else:
            # Update mutable fields so changes to hospitals.json take effect on re-seed
            h.name = item["name"]
            h.address = item["address"]
            h.lat = item["lat"]
            h.lng = item["lng"]
            h.phone = item.get("phone")
            logger.info("Updated hospital: %s", item["name"])


async def seed_hospital_specialties(db: AsyncSession, slug_to_id: dict[str, int]) -> None:
    data = json.loads((SEED_DIR / "hospital_specialties.json").read_text())
    for item in data:
        specialty_id = slug_to_id.get(item["specialty_slug"])
        if specialty_id is None:
            logger.warning("Unknown specialty slug: %s", item["specialty_slug"])
            continue
        result = await db.execute(
            select(HospitalSpecialty).where(
                HospitalSpecialty.hospital_id == item["hospital_id"],
                HospitalSpecialty.specialty_id == specialty_id,
            )
        )
        hs = result.scalar_one_or_none()
        if not hs:
            hs = HospitalSpecialty(
                hospital_id=item["hospital_id"],
                specialty_id=specialty_id,
                schedule_json=json.dumps(item.get("schedule", {})),
            )
            db.add(hs)
    await db.flush()
    logger.info("Hospital specialties seeded")


async def seed_trial_patients(db: AsyncSession) -> None:
    data = json.loads((SEED_DIR / "patients.json").read_text())
    for item in data:
        result = await db.execute(select(Patient).where(Patient.id == item["id"]))
        p = result.scalar_one_or_none()
        if not p:
            p = Patient(
                id=item["id"],
                email=item["email"],
                hashed_password=_bcrypt.hashpw(item["password"].encode(), _bcrypt.gensalt()).decode(),
                profile_json=json.dumps(item["profile"], ensure_ascii=False),
            )
            db.add(p)
            await db.flush()
            logger.info("Created trial patient: %s", item["email"])


async def seed_hospital_statuses(db: AsyncSession) -> None:
    """Update hospital statuses with realistic varied values for demo."""
    data = json.loads((SEED_DIR / "hospital_statuses.json").read_text())
    for item in data:
        result = await db.execute(
            select(HospitalStatus).where(HospitalStatus.hospital_id == item["hospital_id"])
        )
        status = result.scalar_one_or_none()
        if status:
            status.wait_time_min = item["wait_time_min"]
            status.available_beds = item["available_beds"]
            logger.info(
                "Updated status for hospital %d: wait=%dmin, beds=%d",
                item["hospital_id"],
                item["wait_time_min"],
                item["available_beds"],
            )


async def seed_trial_sessions(db: AsyncSession) -> None:
    data = json.loads((SEED_DIR / "trial_sessions.json").read_text())
    for item in data:
        result = await db.execute(select(TriageSession).where(TriageSession.id == item["id"]))
        session = result.scalar_one_or_none()
        if not session:
            session = TriageSession(
                id=item["id"],
                patient_id=item["patient_id"],
                level=item["level"],
                complaint_category=item["complaint_category"],
                answers_json=json.dumps(item["answers"]),
                max_wait_minutes=item["max_wait_minutes"],
            )
            db.add(session)
            await db.flush()
            logger.info("Created triage session id=%d level=%d", item["id"], item["level"])

            for ref in item.get("referrals", []):
                referral = Referral(
                    session_id=session.id,
                    hospital_id=ref["hospital_id"],
                    status=ref["status"],
                )
                db.add(referral)
            await db.flush()


async def seed_obras_sociales(db: AsyncSession) -> None:
    """Seed obras sociales (upsert by code)."""
    data = json.loads((SEED_DIR / "obras_sociales.json").read_text())
    for item in data:
        result = await db.execute(select(ObraSocial).where(ObraSocial.code == item["code"]))
        os = result.scalar_one_or_none()
        if not os:
            os = ObraSocial(name=item["name"], code=item["code"])
            db.add(os)
            logger.info("Created obra social: %s", item["code"])
        else:
            os.name = item["name"]
    await db.flush()
    logger.info("Obras sociales seeded")


async def seed_hospital_obras_sociales(db: AsyncSession) -> None:
    """Seed hospital–obra social mappings (idempotent via ON CONFLICT DO NOTHING)."""
    data = json.loads((SEED_DIR / "hospital_obras_sociales.json").read_text())
    for item in data:
        await db.execute(
            text(
                "INSERT INTO hospital_obras_sociales (hospital_id, obra_social_id) "
                "VALUES (:hid, :osid) ON CONFLICT DO NOTHING"
            ),
            {"hid": item["hospital_id"], "osid": item["obra_social_id"]},
        )
    logger.info("Hospital obras sociales seeded")


async def reset_sequences(db: AsyncSession) -> None:
    """Advance PostgreSQL sequences past any explicitly-seeded IDs."""
    tables = ["hospitals", "patients", "triage_sessions", "referrals", "specialties"]
    for table in tables:
        await db.execute(
            text(
                f"SELECT setval(pg_get_serial_sequence('{table}', 'id'),"
                f" COALESCE((SELECT MAX(id) FROM {table}), 0) + 1, false)"
            )
        )
    logger.info("Sequences reset")


async def run() -> None:
    logging.basicConfig(level=logging.INFO)
    async with AsyncSessionLocal() as db:
        try:
            slug_to_id = await seed_specialties(db)
            await seed_hospitals(db)
            await seed_hospital_specialties(db, slug_to_id)
            await seed_trial_patients(db)
            await seed_hospital_statuses(db)
            await seed_trial_sessions(db)
            await seed_obras_sociales(db)
            await seed_hospital_obras_sociales(db)
            await reset_sequences(db)
            await db.commit()
            logger.info("Seed completed successfully")
        except Exception:
            await db.rollback()
            logger.exception("Seed failed")
            raise


if __name__ == "__main__":
    asyncio.run(run())
