"""Durable business notification outbox."""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import JSONB

revision = "d04f58ac2e49"
down_revision = "c93e47fb1d38"
branch_labels = None
depends_on = None


def upgrade():
    op.create_table("im_notifications",
        sa.Column("id", sa.String(160), primary_key=True),
        sa.Column("recipient", sa.String(80), nullable=False),
        sa.Column("body", JSONB, nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("next_attempt_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("delivered_at", sa.DateTime(timezone=True)),
        sa.Column("attempts", sa.Integer, server_default="0", nullable=False))
    op.create_index("ix_im_notifications_next_attempt_at", "im_notifications", ["next_attempt_at"])


def downgrade():
    op.drop_table("im_notifications")
