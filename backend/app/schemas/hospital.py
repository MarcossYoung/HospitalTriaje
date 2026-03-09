from datetime import datetime

from pydantic import BaseModel


class HospitalStatusUpdate(BaseModel):
    wait_time_min: int
    available_beds: int


class SpecialtyOverride(BaseModel):
    is_available: bool
    override_until: datetime | None = None


class SpecialtyOut(BaseModel):
    id: int
    name_es: str
    slug: str
    is_available: bool

    model_config = {"from_attributes": True}


class HospitalStatusOut(BaseModel):
    wait_time_min: int
    available_beds: int
    updated_at: datetime

    model_config = {"from_attributes": True}


class HospitalOut(BaseModel):
    id: int
    name: str
    address: str
    lat: float
    lng: float
    phone: str | None
    status: HospitalStatusOut | None
    specialties: list[SpecialtyOut] = []

    model_config = {"from_attributes": True}


class NearbyHospitalOut(HospitalOut):
    distance_km: float
    score: float


class ReferralCreate(BaseModel):
    session_id: int
    hospital_id: int


class ReferralOut(BaseModel):
    id: int
    session_id: int
    hospital_id: int
    status: str
    created_at: datetime

    model_config = {"from_attributes": True}
