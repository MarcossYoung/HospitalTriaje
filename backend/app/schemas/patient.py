from pydantic import BaseModel


class FcmTokenUpdate(BaseModel):
    fcm_token: str


class PatientProfile(BaseModel):
    id: int
    email: str | None
    google_id: str | None
    fcm_token: str | None

    model_config = {"from_attributes": True}
