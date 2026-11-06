"""Store the IM private group binding; retain legacy chat data without new writes."""
from alembic import op
import sqlalchemy as sa

revision = "c93e47fb1d38"
down_revision = "b82d36fa0c27"
branch_labels = None
depends_on = None


def upgrade():
    op.add_column("live_rooms", sa.Column("im_group_id", sa.String(80), nullable=True))
    op.create_unique_constraint("uq_live_rooms_im_group_id", "live_rooms", ["im_group_id"])


def downgrade():
    op.drop_constraint("uq_live_rooms_im_group_id", "live_rooms", type_="unique")
    op.drop_column("live_rooms", "im_group_id")
