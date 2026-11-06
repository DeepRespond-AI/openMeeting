"""Persist business connection activity across reconnects and service restarts."""
from alembic import op
import sqlalchemy as sa

revision = "b82d36fa0c27"
down_revision = "a71c25e9fb16"
branch_labels = None
depends_on = None


def upgrade():
    op.add_column("room_participants", sa.Column("last_seen_at", sa.DateTime(timezone=True),
                                               nullable=False, server_default=sa.func.now()))
    op.create_table("room_connection_leases",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("room_id", sa.String(80), sa.ForeignKey("live_rooms.id", ondelete="CASCADE"), nullable=False),
        sa.Column("participant_id", sa.String(80), sa.ForeignKey("room_participants.id", ondelete="CASCADE"), nullable=False),
        sa.Column("last_seen_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()))
    op.create_index("ix_room_connection_leases_room_id", "room_connection_leases", ["room_id"])
    op.create_index("ix_room_connection_leases_participant_id", "room_connection_leases", ["participant_id"])


def downgrade():
    op.drop_table("room_connection_leases")
    op.drop_column("room_participants", "last_seen_at")
