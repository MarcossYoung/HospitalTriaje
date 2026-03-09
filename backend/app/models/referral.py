from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func

from app.database import Base


class Referral(Base):
    __tablename__ = "referrals"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    session_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("triage_sessions.id", ondelete="CASCADE"), nullable=False, index=True
    )
    hospital_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("hospitals.id", ondelete="CASCADE"), nullable=False, index=True
    )
    status: Mapped[str] = mapped_column(
        String(50), nullable=False, default="pending"
    )  # pending | confirmed | cancelled
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    session: Mapped["TriageSession"] = relationship("TriageSession", back_populates="referrals", lazy="selectin")  # noqa: F821
    hospital: Mapped["Hospital"] = relationship("Hospital", back_populates="referrals", lazy="selectin")  # noqa: F821
