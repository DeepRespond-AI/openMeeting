"""Version screen-sharing sessions so stale signals cannot affect a new capture."""
from alembic import op
import sqlalchemy as sa

revision = "e5f0c3a7d9b4"
down_revision = "d4e9b2f6c8a3"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("room_participants", sa.Column("screen_share_id", sa.String(36), nullable=True))


def downgrade() -> None:
    op.drop_column("room_participants", "screen_share_id")
