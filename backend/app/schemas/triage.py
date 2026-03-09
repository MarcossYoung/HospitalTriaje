from pydantic import BaseModel


class AnswerItem(BaseModel):
    node_id: str
    answer_index: int


class EvaluateRequest(BaseModel):
    answers: list[AnswerItem]


class TriageResult(BaseModel):
    level: int
    label: str
    color_hex: str
    max_wait_minutes: int
    complaint_category: str
    session_id: int


class TriageSessionOut(BaseModel):
    id: int
    level: int
    complaint_category: str
    max_wait_minutes: int
    created_at: str

    model_config = {"from_attributes": True}
