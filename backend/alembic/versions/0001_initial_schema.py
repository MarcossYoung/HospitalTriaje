"""initial schema

Revision ID: 0001
Revises:
Create Date: 2026-02-20

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "0001"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "patients",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("email", sa.String(255), nullable=True),
        sa.Column("google_id", sa.String(255), nullable=True),
        sa.Column("hashed_password", sa.String(255), nullable=True),
        sa.Column("profile_json", sa.Text(), nullable=True),
        sa.Column("fcm_token", sa.String(512), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("email"),
        sa.UniqueConstraint("google_id"),
    )
    op.create_index("ix_patients_id", "patients", ["id"])
    op.create_index("ix_patients_email", "patients", ["email"])
    op.create_index("ix_patients_google_id", "patients", ["google_id"])

    op.create_table(
        "hospitals",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("name", sa.String(255), nullable=False),
        sa.Column("address", sa.Text(), nullable=False),
        sa.Column("lat", sa.Float(), nullable=False),
        sa.Column("lng", sa.Float(), nullable=False),
        sa.Column("phone", sa.String(50), nullable=True),
        sa.Column("api_token_hash", sa.String(255), nullable=True),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_hospitals_id", "hospitals", ["id"])

    op.create_table(
        "specialties",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("name_es", sa.String(255), nullable=False),
        sa.Column("slug", sa.String(100), nullable=False),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("name_es"),
        sa.UniqueConstraint("slug"),
    )
    op.create_index("ix_specialties_id", "specialties", ["id"])
    op.create_index("ix_specialties_slug", "specialties", ["slug"])

    op.create_table(
        "hospital_specialty",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("hospital_id", sa.Integer(), nullable=False),
        sa.Column("specialty_id", sa.Integer(), nullable=False),
        sa.Column("schedule_json", sa.Text(), nullable=True),
        sa.Column("is_available_override", sa.Boolean(), nullable=True),
        sa.Column("override_until", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(["hospital_id"], ["hospitals.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["specialty_id"], ["specialties.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_hospital_specialty_id", "hospital_specialty", ["id"])
    op.create_index("ix_hospital_specialty_hospital_id", "hospital_specialty", ["hospital_id"])
    op.create_index("ix_hospital_specialty_specialty_id", "hospital_specialty", ["specialty_id"])

    op.create_table(
        "hospital_status",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("hospital_id", sa.Integer(), nullable=False),
        sa.Column("wait_time_min", sa.Integer(), nullable=False),
        sa.Column("available_beds", sa.Integer(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.ForeignKeyConstraint(["hospital_id"], ["hospitals.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("hospital_id"),
    )
    op.create_index("ix_hospital_status_id", "hospital_status", ["id"])
    op.create_index("ix_hospital_status_hospital_id", "hospital_status", ["hospital_id"])

    op.create_table(
        "triage_sessions",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("patient_id", sa.Integer(), nullable=True),
        sa.Column("level", sa.SmallInteger(), nullable=False),
        sa.Column("complaint_category", sa.String(100), nullable=False),
        sa.Column("answers_json", sa.Text(), nullable=False),
        sa.Column("max_wait_minutes", sa.Integer(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.ForeignKeyConstraint(["patient_id"], ["patients.id"], ondelete="SET NULL"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_triage_sessions_id", "triage_sessions", ["id"])
    op.create_index("ix_triage_sessions_patient_id", "triage_sessions", ["patient_id"])

    op.create_table(
        "referrals",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("session_id", sa.Integer(), nullable=False),
        sa.Column("hospital_id", sa.Integer(), nullable=False),
        sa.Column("status", sa.String(50), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.ForeignKeyConstraint(["hospital_id"], ["hospitals.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["session_id"], ["triage_sessions.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_referrals_id", "referrals", ["id"])
    op.create_index("ix_referrals_session_id", "referrals", ["session_id"])
    op.create_index("ix_referrals_hospital_id", "referrals", ["hospital_id"])


def downgrade() -> None:
    op.drop_table("referrals")
    op.drop_table("triage_sessions")
    op.drop_table("hospital_status")
    op.drop_table("hospital_specialty")
    op.drop_table("specialties")
    op.drop_table("hospitals")
    op.drop_table("patients")
