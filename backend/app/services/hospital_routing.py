"""
Hospital routing / scoring algorithm.

score = (distance_km × 0.4) + (wait_time_min × 0.4) - (specialist_match × 10 × 0.2)

Lower score is better.
"""
import json
import math
from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import noload

from app.models.hospital import Hospital
from app.models.hospital_status import HospitalStatus
from app.models.specialty import HospitalSpecialty, Specialty


def _haversine(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    """Return distance in kilometres between two lat/lng pairs."""
    R = 6371.0
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlambda = math.radians(lng2 - lng1)
    a = math.sin(dphi / 2) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda / 2) ** 2
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


def _is_specialty_available(hs: HospitalSpecialty) -> bool:
    """Return True if the specialty is currently available."""
    now = datetime.now(timezone.utc)

    # Check active override first
    if hs.is_available_override is not None and hs.override_until:
        if hs.override_until > now:
            return hs.is_available_override

    # Fall back to weekly schedule
    if not hs.schedule_json:
        return False

    try:
        schedule: dict = json.loads(hs.schedule_json)
    except Exception:
        return False

    weekday_names = ["mon", "tue", "wed", "thu", "fri", "sat", "sun"]
    day_key = weekday_names[now.weekday()]
    slots: list[str] = schedule.get(day_key, [])

    current_time = now.strftime("%H:%M")
    for slot in slots:
        try:
            start, end = slot.split("-")
            if start <= current_time <= end:
                return True
        except ValueError:
            continue
    return False


async def get_nearby_hospitals(
    db: AsyncSession,
    lat: float,
    lng: float,
    specialty_slug: str | None = None,
    triage_level: int | None = None,
    limit: int = 5,
) -> list[dict]:
    # Pre-filter by bounding box (~55 km at Argentina's latitude) before Python sees any rows.
    # Skip relationships not used by the scoring algorithm.
    _BBOX_DEG = 0.5
    result = await db.execute(
        select(Hospital)
        .where(Hospital.lat.between(lat - _BBOX_DEG, lat + _BBOX_DEG))
        .where(Hospital.lng.between(lng - _BBOX_DEG, lng + _BBOX_DEG))
        .options(
            noload(Hospital.referrals),
            noload(Hospital.on_call_doctors),
            noload(Hospital.obras_sociales),
        )
    )
    hospitals: list[Hospital] = list(result.scalars().all())

    scored: list[dict] = []

    for h in hospitals:
        distance_km = _haversine(lat, lng, h.lat, h.lng)

        # Wait time
        wait_time_min = 30  # default
        if h.status:
            wait_time_min = h.status.wait_time_min

        # Specialist match
        specialist_match = 0
        if specialty_slug:
            specialist_match = int(any(
                hs.specialty and hs.specialty.slug == specialty_slug and _is_specialty_available(hs)
                for hs in h.specialties
            ))
            if not specialist_match:
                continue  # required specialty not available → skip hospital

        # Urgent/immediate cases (level 1–2): prioritise short waits over distance
        if triage_level in (1, 2):
            wait_w = 0.8
            dist_w = 0.2
        else:
            wait_w = 0.4
            dist_w = 0.4

        # For level-1 (Immediate) skip hospitals with no available beds
        if triage_level == 1 and h.status and h.status.available_beds == 0:
            continue

        score = (distance_km * dist_w) + (wait_time_min * wait_w) - (specialist_match * 10 * 0.2)

        scored.append({
            "hospital": h,
            "distance_km": round(distance_km, 2),
            "score": round(score, 4),
            "specialist_match": bool(specialist_match),
        })

    scored.sort(key=lambda x: x["score"])
    return scored[:limit]
