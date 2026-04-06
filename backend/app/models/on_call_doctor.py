from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func

from app.database import Base


class OnCallDoctor(Base):
    __tablename__ = "on_call_doctors"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    hospital_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("hospitals.id", ondelete="CASCADE"), nullable=False, index=True
    )
    doctor_name: Mapped[str] = mapped_column(String(255), nullable=False)
    specialty_id: Mapped[int | None] = mapped_column(
        Integer, ForeignKey("specialties.id", ondelete="SET NULL"), nullable=True
    )
    shift_start: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    shift_end: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    hospital: Mapped["Hospital"] = relationship("Hospital", back_populates="on_call_doctors", lazy="selectin")  # noqa: F821
    specialty: Mapped["Specialty | None"] = relationship("Specialty", lazy="selectin")  # noqa: F821
