"""Explicit recording and per-member requests; existing rooms start with recording off."""
from alembic import op
import sqlalchemy as sa

revision = 'c26a10d8e041'
down_revision = 'd04f58ac2e49'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column('live_rooms', sa.Column('recording_active', sa.Boolean(), nullable=False, server_default=sa.false()))
    op.add_column('live_rooms', sa.Column('recording_epoch', sa.Integer(), nullable=False, server_default='0'))
    op.add_column('live_rooms', sa.Column('recording_started_at', sa.DateTime(timezone=True)))
    op.add_column('room_participants', sa.Column('recording_request', sa.String(16), nullable=False, server_default='none'))
    op.add_column('room_participants', sa.Column('recording_request_id', sa.String(36)))
    op.add_column('room_recording_chunks', sa.Column('recording_epoch', sa.Integer(), nullable=False, server_default='0'))


def downgrade():
    op.drop_column('room_recording_chunks', 'recording_epoch')
    op.drop_column('room_participants', 'recording_request_id')
    op.drop_column('room_participants', 'recording_request')
    op.drop_column('live_rooms', 'recording_started_at')
    op.drop_column('live_rooms', 'recording_epoch')
    op.drop_column('live_rooms', 'recording_active')
