"""admin features: on_call_doctors, obras_sociales, hospital_obras_sociales

Revision ID: 0002
Revises: 0001
Create Date: 2026-03-18

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "0002"
down_revision: Union[str, None] = "0001"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "obras_sociales",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("name", sa.String(255), nullable=False),
        sa.Column("code", sa.String(50), nullable=False),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("name"),
        sa.UniqueConstraint("code"),
    )
    op.create_index("ix_obras_sociales_id", "obras_sociales", ["id"])

    op.create_table(
        "hospital_obras_sociales",
        sa.Column("hospital_id", sa.Integer(), nullable=False),
        sa.Column("obra_social_id", sa.Integer(), nullable=False),
        sa.ForeignKeyConstraint(["hospital_id"], ["hospitals.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["obra_social_id"], ["obras_sociales.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("hospital_id", "obra_social_id"),
    )

    op.create_table(
        "on_call_doctors",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("hospital_id", sa.Integer(), nullable=False),
        sa.Column("doctor_name", sa.String(255), nullable=False),
        sa.Column("specialty_id", sa.Integer(), nullable=True),
        sa.Column("shift_start", sa.DateTime(timezone=True), nullable=False),
        sa.Column("shift_end", sa.DateTime(timezone=True), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.ForeignKeyConstraint(["hospital_id"], ["hospitals.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["specialty_id"], ["specialties.id"], ondelete="SET NULL"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_on_call_doctors_id", "on_call_doctors", ["id"])
    op.create_index("ix_on_call_doctors_hospital_id", "on_call_doctors", ["hospital_id"])


def downgrade() -> None:
    op.drop_table("on_call_doctors")
    op.drop_table("hospital_obras_sociales")
    op.drop_table("obras_sociales")
