from datetime import datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class Specialty(Base):
    __tablename__ = "specialties"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    name_es: Mapped[str] = mapped_column(String(255), nullable=False, unique=True)
    slug: Mapped[str] = mapped_column(String(100), nullable=False, unique=True, index=True)

    hospital_specialties: Mapped[list["HospitalSpecialty"]] = relationship(
        "HospitalSpecialty", back_populates="specialty", lazy="selectin"
    )


class HospitalSpecialty(Base):
    __tablename__ = "hospital_specialty"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    hospital_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("hospitals.id", ondelete="CASCADE"), nullable=False, index=True
    )
    specialty_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("specialties.id", ondelete="CASCADE"), nullable=False, index=True
    )
    # JSON: {"mon": ["08:00-17:00"], "tue": ["08:00-17:00"], ...}
    schedule_json: Mapped[str | None] = mapped_column(Text, nullable=True)
    is_available_override: Mapped[bool | None] = mapped_column(Boolean, nullable=True)
    override_until: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    hospital: Mapped["Hospital"] = relationship("Hospital", back_populates="specialties", lazy="selectin")  # noqa: F821
    specialty: Mapped["Specialty"] = relationship("Specialty", back_populates="hospital_specialties", lazy="selectin")
