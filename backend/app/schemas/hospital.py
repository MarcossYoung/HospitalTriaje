from datetime import datetime

from pydantic import BaseModel


class OnCallDoctorCreate(BaseModel):
    doctor_name: str
    specialty_id: int | None = None
    shift_start: datetime
    shift_end: datetime


class OnCallDoctorOut(BaseModel):
    id: int
    hospital_id: int
    doctor_name: str
    specialty_id: int | None
    specialty_name: str | None
    shift_start: datetime
    shift_end: datetime
    created_at: datetime

    model_config = {"from_attributes": True}


class ObraSocialOut(BaseModel):
    id: int
    name: str
    code: str

    model_config = {"from_attributes": True}


class HospitalObrasSocialesUpdate(BaseModel):
    obra_social_ids: list[int]


class BedsUpdate(BaseModel):
    available_beds: int


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


class HospitalInfoUpdate(BaseModel):
    address: str | None = None
    phone: str | None = None


class SpecialtyScheduleUpdate(BaseModel):
    schedule: dict[str, list[str]]  # {"mon": ["08:00-20:00"], ...}


class TokenRotateOut(BaseModel):
    token: str  # plaintext — shown once, never stored


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
