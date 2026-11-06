"""Room attachment metadata and message references.

Revision ID: d4e9b2f6c8a3
Revises: c3d8a1e5b7f2
"""
from alembic import op
import sqlalchemy as sa

revision = "d4e9b2f6c8a3"
down_revision = "c3d8a1e5b7f2"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table("room_attachments",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("room_id", sa.String(80), sa.ForeignKey("live_rooms.id", ondelete="CASCADE"), nullable=False),
        sa.Column("owner_participant_id", sa.String(80), nullable=False),
        sa.Column("name", sa.String(200), nullable=False),
        sa.Column("size", sa.BigInteger(), nullable=False),
        sa.Column("published", sa.Boolean(), server_default="false", nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False))
    op.create_index("ix_room_attachments_room_id", "room_attachments", ["room_id"])
    op.add_column("room_chat_messages", sa.Column("attachment_id", sa.String(80), nullable=True))
    op.create_foreign_key("fk_chat_attachment", "room_chat_messages", "room_attachments", ["attachment_id"], ["id"])


def downgrade() -> None:
    op.drop_constraint("fk_chat_attachment", "room_chat_messages", type_="foreignkey")
    op.drop_column("room_chat_messages", "attachment_id")
    op.drop_table("room_attachments")
