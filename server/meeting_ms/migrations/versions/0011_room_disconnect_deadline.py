"""Persist confirmed socket disconnection separately from silent heartbeats."""
from alembic import op
import sqlalchemy as sa

revision = "e37b21e9f152"
down_revision = "c26a10d8e041"
branch_labels = None
depends_on = None


def upgrade():
    op.add_column("room_participants", sa.Column("disconnected_at", sa.DateTime(timezone=True)))


def downgrade():
    op.drop_column("room_participants", "disconnected_at")
