from sqlalchemy import Float, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class Hospital(Base):
    __tablename__ = "hospitals"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    address: Mapped[str] = mapped_column(Text, nullable=False)
    lat: Mapped[float] = mapped_column(Float, nullable=False)
    lng: Mapped[float] = mapped_column(Float, nullable=False)
    phone: Mapped[str | None] = mapped_column(String(50), nullable=True)
    api_token_hash: Mapped[str | None] = mapped_column(String(255), nullable=True)

    status: Mapped["HospitalStatus | None"] = relationship(  # noqa: F821
        "HospitalStatus", back_populates="hospital", uselist=False, lazy="selectin"
    )
    specialties: Mapped[list["HospitalSpecialty"]] = relationship(  # noqa: F821
        "HospitalSpecialty", back_populates="hospital", lazy="selectin"
    )
    referrals: Mapped[list["Referral"]] = relationship(  # noqa: F821
        "Referral", back_populates="hospital", lazy="selectin"
    )
