"""live meeting: scheduled_meetings, live_rooms, room_participants, room_chat_messages

Revision ID: c3d8a1e5b7f2
Revises: 9dece074d9a3
Create Date: 2026-10-22
"""
from alembic import op
import sqlalchemy as sa

revision = 'c3d8a1e5b7f2'
down_revision = '9dece074d9a3'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table('scheduled_meetings',
    sa.Column('id', sa.String(length=80), nullable=False),
    sa.Column('code', sa.String(length=6), nullable=False),
    sa.Column('user_id', sa.String(length=64), nullable=False),
    sa.Column('host_name', sa.String(length=80), nullable=False),
    sa.Column('title', sa.Text(), nullable=False),
    sa.Column('start_at', sa.DateTime(timezone=True), nullable=False),
    sa.Column('duration_min', sa.Integer(), nullable=False),
    sa.Column('pwd_enabled', sa.Boolean(), server_default='false', nullable=False),
    sa.Column('pwd', sa.String(length=8), nullable=True),
    sa.Column('remind', sa.Boolean(), server_default='false', nullable=False),
    sa.Column('wait_room', sa.Boolean(), server_default='false', nullable=False),
    sa.Column('cancelled', sa.Boolean(), server_default='false', nullable=False),
    sa.Column('meeting_id', sa.String(length=80), nullable=True),
    sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
    sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
    sa.ForeignKeyConstraint(['meeting_id'], ['meetings.id'], ondelete='SET NULL'),
    sa.PrimaryKeyConstraint('id'),
    sa.UniqueConstraint('code', name='uq_scheduled_code')
    )
    op.create_index('ix_sched_user_start', 'scheduled_meetings', ['user_id', 'start_at'], unique=False)
    op.create_table('live_rooms',
    sa.Column('id', sa.String(length=80), nullable=False),
    sa.Column('code', sa.String(length=6), nullable=False),
    sa.Column('title', sa.Text(), nullable=False),
    sa.Column('scheduled_meeting_id', sa.String(length=80), nullable=True),
    sa.Column('status', sa.String(length=16), server_default='active', nullable=False),
    sa.Column('pwd_enabled', sa.Boolean(), server_default='false', nullable=False),
    sa.Column('pwd', sa.String(length=8), nullable=True),
    sa.Column('wait_room', sa.Boolean(), server_default='false', nullable=False),
    sa.Column('host_participant_id', sa.String(length=80), nullable=False),
    sa.Column('host_user_id', sa.String(length=64), nullable=False),
    sa.Column('started_at', sa.DateTime(timezone=True), nullable=True),
    sa.Column('ended_at', sa.DateTime(timezone=True), nullable=True),
    sa.Column('meeting_id', sa.String(length=80), nullable=True),
    sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
    sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
    sa.ForeignKeyConstraint(['scheduled_meeting_id'], ['scheduled_meetings.id'], ondelete='SET NULL'),
    sa.ForeignKeyConstraint(['meeting_id'], ['meetings.id'], ondelete='SET NULL'),
    sa.PrimaryKeyConstraint('id')
    )
    op.create_index('uq_rooms_active_code', 'live_rooms', ['code'], unique=True,
                    postgresql_where=sa.text("status <> 'ended'"))
    op.create_index('ix_rooms_scheduled', 'live_rooms', ['scheduled_meeting_id'], unique=False)
    op.create_table('room_participants',
    sa.Column('id', sa.String(length=80), nullable=False),
    sa.Column('room_id', sa.String(length=80), nullable=False),
    sa.Column('user_id', sa.String(length=64), nullable=True),
    sa.Column('name', sa.String(length=80), nullable=False),
    sa.Column('is_host', sa.Boolean(), server_default='false', nullable=False),
    sa.Column('state', sa.String(length=16), server_default='joined', nullable=False),
    sa.Column('mic_on', sa.Boolean(), server_default='false', nullable=False),
    sa.Column('cam_on', sa.Boolean(), server_default='false', nullable=False),
    sa.Column('hand_raised', sa.Boolean(), server_default='false', nullable=False),
    sa.Column('screen_sharing', sa.Boolean(), server_default='false', nullable=False),
    sa.Column('muted_by_host', sa.Boolean(), server_default='false', nullable=False),
    sa.Column('joined_at', sa.DateTime(timezone=True), nullable=True),
    sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
    sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
    sa.ForeignKeyConstraint(['room_id'], ['live_rooms.id'], ondelete='CASCADE'),
    sa.PrimaryKeyConstraint('id'),
    sa.UniqueConstraint('room_id', 'user_id', name='uq_participants_room_user')
    )
    op.create_index('ix_participants_room', 'room_participants', ['room_id'], unique=False)
    op.create_table('room_chat_messages',
    sa.Column('id', sa.String(length=80), nullable=False),
    sa.Column('room_id', sa.String(length=80), nullable=False),
    sa.Column('seq', sa.BigInteger(), nullable=False),
    sa.Column('sender_id', sa.String(length=80), nullable=False),
    sa.Column('sender_name', sa.String(length=80), nullable=False),
    sa.Column('text', sa.Text(), server_default='', nullable=False),
    sa.Column('attachment_name', sa.String(length=200), nullable=True),
    sa.Column('attachment_size', sa.BigInteger(), nullable=True),
    sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
    sa.ForeignKeyConstraint(['room_id'], ['live_rooms.id'], ondelete='CASCADE'),
    sa.PrimaryKeyConstraint('id'),
    sa.UniqueConstraint('room_id', 'seq', name='uq_chat_room_seq')
    )


def downgrade() -> None:
    op.drop_table('room_chat_messages')
    op.drop_index('ix_participants_room', table_name='room_participants')
    op.drop_table('room_participants')
    op.drop_index('ix_rooms_scheduled', table_name='live_rooms')
    op.drop_index('uq_rooms_active_code', table_name='live_rooms')
    op.drop_table('live_rooms')
    op.drop_index('ix_sched_user_start', table_name='scheduled_meetings')
    op.drop_table('scheduled_meetings')
