"""仅维护对象存储分片；按部署约定清理旧 PCM，已合成录音不受影响。"""
from alembic import op
import sqlalchemy as sa

revision = "f48c32fa0263"
down_revision = "e37b21e9f152"
branch_labels = None
depends_on = None


def upgrade():
    # User-approved removal of legacy source chunks; never remove final audio or transcripts.
    op.execute("""UPDATE jobs SET status='failed',
        error='旧版 PCM 分片已清理，请使用已保存的完整录音重新转写',
        message='旧版分片已清理', updated_at=now()
        WHERE kind='room_recording' AND status IN ('queued','running','failed','cancelled')
        AND params->>'room_id' IN (SELECT DISTINCT room_id FROM room_recording_chunks)""")
    op.execute("DELETE FROM room_recording_chunks")
    op.drop_column("room_recording_chunks", "pcm")
    op.add_column("room_recording_chunks", sa.Column("storage", sa.String(16), nullable=False))
    op.add_column("room_recording_chunks", sa.Column("storage_key", sa.Text(), nullable=False))
    op.add_column("room_recording_chunks", sa.Column("size", sa.Integer(), nullable=False))
    op.add_column("room_recording_chunks", sa.Column("sha256", sa.String(64), nullable=False))
    op.add_column("room_recording_chunks", sa.Column("expires_at", sa.DateTime(timezone=True)))
    op.add_column("room_recording_chunks", sa.Column("purged_at", sa.DateTime(timezone=True)))
    op.create_index("ix_room_recording_chunks_expires_at", "room_recording_chunks", ["expires_at"])


def downgrade():
    raise RuntimeError("旧 PCM 已按部署约定清理，此迁移不可逆；回退需恢复部署前的数据库备份")
