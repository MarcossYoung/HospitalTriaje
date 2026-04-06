"""demo schema fixes: active columns, on_call_doctors specialty index

Revision ID: 0003
Revises: 0002
Create Date: 2026-04-06

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "0003"
down_revision: Union[str, None] = "0002"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "hospitals",
        sa.Column("active", sa.Boolean(), nullable=False, server_default=sa.true()),
    )
    op.add_column(
        "obras_sociales",
        sa.Column("active", sa.Boolean(), nullable=False, server_default=sa.true()),
    )
    op.create_index(
        "ix_on_call_doctors_specialty_id",
        "on_call_doctors",
        ["specialty_id"],
    )


def downgrade() -> None:
    op.drop_index("ix_on_call_doctors_specialty_id", table_name="on_call_doctors")
    op.drop_column("obras_sociales", "active")
    op.drop_column("hospitals", "active")
