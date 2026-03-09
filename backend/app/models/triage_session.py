from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, Integer, SmallInteger, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func

from app.database import Base


class TriageSession(Base):
    __tablename__ = "triage_sessions"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    patient_id: Mapped[int | None] = mapped_column(
        Integer, ForeignKey("patients.id", ondelete="SET NULL"), nullable=True, index=True
    )
    level: Mapped[int] = mapped_column(SmallInteger, nullable=False)  # 1-5
    complaint_category: Mapped[str] = mapped_column(String(100), nullable=False)
    answers_json: Mapped[str] = mapped_column(Text, nullable=False)  # [{node_id, answer_index}]
    max_wait_minutes: Mapped[int] = mapped_column(Integer, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    patient: Mapped["Patient | None"] = relationship("Patient", back_populates="triage_sessions", lazy="selectin")  # noqa: F821
    referrals: Mapped[list["Referral"]] = relationship(  # noqa: F821
        "Referral", back_populates="session", lazy="selectin"
    )
