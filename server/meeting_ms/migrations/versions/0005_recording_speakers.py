"""Retain joined identities after leaving; backfill existing joined participants."""
from alembic import op
import sqlalchemy as sa
revision = "f60b14d8ea05"
down_revision = "e5fa03c7d9b4"
branch_labels = None
depends_on = None


def upgrade():
    op.create_table("room_recording_speakers",
        sa.Column("participant_id", sa.String(80), primary_key=True),
        sa.Column("room_id", sa.String(80), sa.ForeignKey("live_rooms.id", ondelete="CASCADE"), nullable=False),
        sa.Column("user_id", sa.String(64)), sa.Column("name", sa.String(80), nullable=False))
    op.create_index("ix_room_recording_speakers_room_id", "room_recording_speakers", ["room_id"])
    op.execute("INSERT INTO room_recording_speakers (participant_id,room_id,user_id,name) SELECT id,room_id,user_id,name FROM room_participants WHERE state='joined'")


def downgrade():
    op.drop_table("room_recording_speakers")
