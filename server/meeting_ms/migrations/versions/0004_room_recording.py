"""Persist participant audio for room recording and speaker attribution."""
from alembic import op
import sqlalchemy as sa

revision = "e5fa03c7d9b4"
down_revision = "d4e9b2f6c8a3"
branch_labels = None
depends_on = None


def upgrade():
    op.create_table("room_recording_chunks",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("room_id", sa.String(80), sa.ForeignKey("live_rooms.id", ondelete="CASCADE"), nullable=False),
        sa.Column("chunk_id", sa.String(80), nullable=False),
        sa.Column("participant_id", sa.String(80), nullable=False),
        sa.Column("speaker_name", sa.String(80), nullable=False),
        sa.Column("start_time", sa.Float(), nullable=False),
        sa.Column("pcm", sa.LargeBinary(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.UniqueConstraint("room_id", "chunk_id", name="uq_room_recording_chunk"))
    op.create_index("ix_room_recording_chunks_room_id", "room_recording_chunks", ["room_id"])


def downgrade():
    op.drop_table("room_recording_chunks")
