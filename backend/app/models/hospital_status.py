from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, Integer
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func

from app.database import Base


class HospitalStatus(Base):
    __tablename__ = "hospital_status"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    hospital_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("hospitals.id", ondelete="CASCADE"), nullable=False, unique=True, index=True
    )
    wait_time_min: Mapped[int] = mapped_column(Integer, nullable=False, default=30)
    available_beds: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    hospital: Mapped["Hospital"] = relationship("Hospital", back_populates="status", lazy="selectin")  # noqa: F821
