from sqlalchemy import Boolean, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


class ObraSocial(Base):
    __tablename__ = "obras_sociales"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    name: Mapped[str] = mapped_column(String(255), nullable=False, unique=True)
    code: Mapped[str] = mapped_column(String(50), nullable=False, unique=True)
    active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True, server_default="true")


class HospitalObraSocial(Base):
    __tablename__ = "hospital_obras_sociales"

    hospital_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("hospitals.id", ondelete="CASCADE"), primary_key=True
    )
    obra_social_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("obras_sociales.id", ondelete="CASCADE"), primary_key=True
    )
