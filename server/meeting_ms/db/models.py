from __future__ import annotations

from datetime import datetime

from sqlalchemy import (
    BigInteger,
    Boolean,
    DateTime,
    Float,
    ForeignKey,
    Index,
    Integer,
    String,
    Text,
    UniqueConstraint,
    func,
    text,
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column


class Base(DeclarativeBase):
    pass


TS = DateTime(timezone=True)


class ImNotification(Base):
    """Business delivery outbox only; IM owns delivered messages and read state."""
    __tablename__ = "im_notifications"
    id: Mapped[str] = mapped_column(String(160), primary_key=True)
    recipient: Mapped[str] = mapped_column(String(80))
    body: Mapped[dict] = mapped_column(JSONB)
    created_at: Mapped[datetime] = mapped_column(TS, server_default=func.now())
    next_attempt_at: Mapped[datetime] = mapped_column(TS, server_default=func.now(), index=True)
    delivered_at: Mapped[datetime | None] = mapped_column(TS)
    attempts: Mapped[int] = mapped_column(Integer, default=0, server_default="0")


class Meeting(Base):
    __tablename__ = "meetings"
    id: Mapped[str] = mapped_column(String(80), primary_key=True)
    # Owner (users.id in the user_ms database; no cross-database FK).
    user_id: Mapped[str] = mapped_column(String(64), index=True)
    title: Mapped[str] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(TS, server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(TS, server_default=func.now())
    # "local" -> audio_path is an absolute file path; "oss" -> audio_path is the OSS object key
    audio_storage: Mapped[str] = mapped_column(String(16), default="local", server_default="local")
    audio_path: Mapped[str | None] = mapped_column(Text)
    audio_content_type: Mapped[str | None] = mapped_column(String(200))
    audio_size: Mapped[int | None] = mapped_column(BigInteger)
    duration: Mapped[float | None] = mapped_column(Float)
    summary_language: Mapped[str | None] = mapped_column(String(32))
    detected_summary_language: Mapped[str | None] = mapped_column(String(32))


class Transcript(Base):
    __tablename__ = "transcripts"
    __table_args__ = (
        UniqueConstraint("meeting_id", "seq", name="uq_transcripts_meeting_seq"),
        Index("ix_transcripts_meeting_order", "meeting_id", "audio_start_time"),
    )
    id: Mapped[str] = mapped_column(String(80), primary_key=True)
    meeting_id: Mapped[str] = mapped_column(ForeignKey("meetings.id", ondelete="CASCADE"))
    transcript: Mapped[str] = mapped_column(Text)
    timestamp: Mapped[str] = mapped_column(String(64))
    audio_start_time: Mapped[float | None] = mapped_column(Float)
    audio_end_time: Mapped[float | None] = mapped_column(Float)
    duration: Mapped[float | None] = mapped_column(Float)
    speaker: Mapped[str | None] = mapped_column(String(32))
    confidence: Mapped[float | None] = mapped_column(Float)
    seq: Mapped[int | None] = mapped_column(BigInteger)
    created_at: Mapped[datetime] = mapped_column(TS, server_default=func.now())


class SummaryProcess(Base):
    __tablename__ = "summary_processes"
    meeting_id: Mapped[str] = mapped_column(ForeignKey("meetings.id", ondelete="CASCADE"), primary_key=True)
    status: Mapped[str] = mapped_column(String(32))
    created_at: Mapped[datetime] = mapped_column(TS)
    updated_at: Mapped[datetime] = mapped_column(TS)
    error: Mapped[str | None] = mapped_column(Text)
    result: Mapped[str | None] = mapped_column(Text)
    start_time: Mapped[datetime | None] = mapped_column(TS)
    end_time: Mapped[datetime | None] = mapped_column(TS)
    chunk_count: Mapped[int] = mapped_column(Integer, default=0, server_default="0")
    processing_time: Mapped[float] = mapped_column(Float, default=0.0, server_default="0")
    metadata_json: Mapped[str | None] = mapped_column("metadata", Text)
    result_backup: Mapped[str | None] = mapped_column(Text)
    result_backup_timestamp: Mapped[datetime | None] = mapped_column(TS)


class TranscriptChunk(Base):
    __tablename__ = "transcript_chunks"
    meeting_id: Mapped[str] = mapped_column(ForeignKey("meetings.id", ondelete="CASCADE"), primary_key=True)
    meeting_name: Mapped[str | None] = mapped_column(Text)
    transcript_text: Mapped[str] = mapped_column(Text)
    model: Mapped[str] = mapped_column(String(200))
    model_name: Mapped[str] = mapped_column(String(200))
    chunk_size: Mapped[int | None] = mapped_column(Integer)
    overlap: Mapped[int | None] = mapped_column(Integer)
    created_at: Mapped[datetime] = mapped_column(TS, server_default=func.now())


class MeetingNotes(Base):
    __tablename__ = "meeting_notes"
    meeting_id: Mapped[str] = mapped_column(ForeignKey("meetings.id", ondelete="CASCADE"), primary_key=True)
    notes_markdown: Mapped[str | None] = mapped_column(Text)
    notes_json: Mapped[str | None] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(TS, server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(TS, server_default=func.now())


class LlmProvider(Base):
    __tablename__ = "llm_providers"
    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    name: Mapped[str] = mapped_column(String(200))
    base_url: Mapped[str] = mapped_column(Text)
    api_key_enc: Mapped[str | None] = mapped_column(Text)
    model: Mapped[str] = mapped_column(String(200))
    max_tokens: Mapped[int | None] = mapped_column(Integer)
    temperature: Mapped[float | None] = mapped_column(Float)
    top_p: Mapped[float | None] = mapped_column(Float)
    context_tokens: Mapped[int] = mapped_column(Integer, default=32000, server_default="32000")
    enabled: Mapped[bool] = mapped_column(Boolean, default=True, server_default="true")
    created_at: Mapped[datetime] = mapped_column(TS, server_default=func.now())


class SummaryTemplateRow(Base):
    """Admin-managed summary template; the server picks one per summary (never exposed to clients)."""

    __tablename__ = "summary_templates"
    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    name: Mapped[str] = mapped_column(String(200))
    description: Mapped[str] = mapped_column(Text)
    prompt: Mapped[str] = mapped_column(Text)
    output_format: Mapped[str] = mapped_column(String(16), default="markdown", server_default="markdown")
    enabled: Mapped[bool] = mapped_column(Boolean, default=True, server_default="true")
    is_default: Mapped[bool] = mapped_column(Boolean, default=False, server_default="false")
    created_at: Mapped[datetime] = mapped_column(TS, server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(TS, server_default=func.now())


class SystemSetting(Base):
    __tablename__ = "system_settings"
    key: Mapped[str] = mapped_column(String(120), primary_key=True)
    value: Mapped[dict | list | str | int | float | bool | None] = mapped_column(JSONB)
    updated_at: Mapped[datetime] = mapped_column(TS, server_default=func.now())


class Job(Base):
    __tablename__ = "jobs"
    id: Mapped[str] = mapped_column(String(80), primary_key=True)
    # Owner (users.id in the user_ms database; no cross-database FK).
    user_id: Mapped[str] = mapped_column(String(64), index=True)
    kind: Mapped[str] = mapped_column(String(32))
    status: Mapped[str] = mapped_column(String(32), index=True)
    progress: Mapped[int] = mapped_column(Integer, default=0, server_default="0")
    message: Mapped[str | None] = mapped_column(Text)
    meeting_id: Mapped[str | None] = mapped_column(String(80))
    error: Mapped[str | None] = mapped_column(Text)
    segments: Mapped[int | None] = mapped_column(Integer)
    params: Mapped[dict] = mapped_column(JSONB, default=dict, server_default="{}")
    created_at: Mapped[datetime] = mapped_column(TS, server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(TS, server_default=func.now())


class RequestLog(Base):
    __tablename__ = "request_logs"
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    session_id: Mapped[str | None] = mapped_column(String(64))
    user_id: Mapped[str | None] = mapped_column(String(64))
    kind: Mapped[str] = mapped_column(String(32))
    duration_ms: Mapped[int] = mapped_column(Integer, default=0)
    audio_sec: Mapped[float] = mapped_column(Float, default=0.0)
    status: Mapped[str] = mapped_column(String(16))
    error: Mapped[str | None] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(TS, server_default=func.now(), index=True)


# ---------------------------------------------------------------- live meeting (P1: scheduled meetings & rooms)


class ScheduledMeeting(Base):
    """预定会议。host 是 user_ms 的登录用户（跨库，无 FK）；展示态由客户端按 start_at 派生，仅取消落库。"""

    __tablename__ = "scheduled_meetings"
    __table_args__ = (
        UniqueConstraint("code", name="uq_scheduled_code"),
        Index("ix_sched_user_start", "user_id", "start_at"),
    )
    id: Mapped[str] = mapped_column(String(80), primary_key=True)  # sched-<uuid4>
    code: Mapped[str] = mapped_column(String(6))
    # Owner/host (users.id in the user_ms database; no cross-database FK).
    user_id: Mapped[str] = mapped_column(String(64))
    host_name: Mapped[str] = mapped_column(String(80))  # snapshot at creation
    title: Mapped[str] = mapped_column(Text)
    start_at: Mapped[datetime] = mapped_column(TS)
    duration_min: Mapped[int] = mapped_column(Integer)
    pwd_enabled: Mapped[bool] = mapped_column(Boolean, default=False, server_default="false")
    pwd: Mapped[str | None] = mapped_column(String(8))  # 4-6 digits, only when pwd_enabled
    remind: Mapped[bool] = mapped_column(Boolean, default=False, server_default="false")
    wait_room: Mapped[bool] = mapped_column(Boolean, default=False, server_default="false")
    cancelled: Mapped[bool] = mapped_column(Boolean, default=False, server_default="false")
    meeting_id: Mapped[str | None] = mapped_column(ForeignKey("meetings.id", ondelete="SET NULL"))
    created_at: Mapped[datetime] = mapped_column(TS, server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(TS, server_default=func.now())


class LiveRoom(Base):
    """会议房间。同一 code 同时至多一个未结束房间（部分唯一索引）；结束后 host 可经 join 自动重建。"""

    __tablename__ = "live_rooms"
    __table_args__ = (
        Index("uq_rooms_active_code", "code", unique=True, postgresql_where=text("status <> 'ended'")),
        Index("ix_rooms_scheduled", "scheduled_meeting_id"),
    )
    id: Mapped[str] = mapped_column(String(80), primary_key=True)  # room-<uuid4>
    im_group_id: Mapped[str | None] = mapped_column(String(80), unique=True)
    code: Mapped[str] = mapped_column(String(6))
    title: Mapped[str] = mapped_column(Text)
    scheduled_meeting_id: Mapped[str | None] = mapped_column(
        ForeignKey("scheduled_meetings.id", ondelete="SET NULL")
    )
    status: Mapped[str] = mapped_column(String(16), default="active", server_default="active")  # waiting|active|ended
    pwd_enabled: Mapped[bool] = mapped_column(Boolean, default=False, server_default="false")
    pwd: Mapped[str | None] = mapped_column(String(8))
    wait_room: Mapped[bool] = mapped_column(Boolean, default=False, server_default="false")
    # host_participant_id 无 FK（与 participants 循环引用，完整性由 Service 层保证）；host_user_id 冗余房主账号。
    host_participant_id: Mapped[str] = mapped_column(String(80))
    host_user_id: Mapped[str] = mapped_column(String(64))
    started_at: Mapped[datetime | None] = mapped_column(TS)
    ended_at: Mapped[datetime | None] = mapped_column(TS)
    meeting_id: Mapped[str | None] = mapped_column(ForeignKey("meetings.id", ondelete="SET NULL"))
    recording_active: Mapped[bool] = mapped_column(Boolean, default=False, server_default="false")
    recording_epoch: Mapped[int] = mapped_column(Integer, default=0, server_default="0")
    recording_started_at: Mapped[datetime | None] = mapped_column(TS)
    created_at: Mapped[datetime] = mapped_column(TS, server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(TS, server_default=func.now())


class RoomParticipant(Base):
    """房间参与者。等候室闸门用 state 表达；离开/移出即删行（聊天已冗余 sender_name）。"""

    __tablename__ = "room_participants"
    __table_args__ = (
        Index("ix_participants_room", "room_id"),
        # Postgres unique index allows multiple NULLs: guests stay unconstrained, logged-in users rejoin idempotently.
        UniqueConstraint("room_id", "user_id", name="uq_participants_room_user"),
    )
    id: Mapped[str] = mapped_column(String(80), primary_key=True)  # user-<uuid4> (guest-<uuid4> reserved)
    room_id: Mapped[str] = mapped_column(ForeignKey("live_rooms.id", ondelete="CASCADE"))
    user_id: Mapped[str | None] = mapped_column(String(64))  # NULL = guest (reserved)
    name: Mapped[str] = mapped_column(String(80))
    is_host: Mapped[bool] = mapped_column(Boolean, default=False, server_default="false")
    state: Mapped[str] = mapped_column(String(16), default="joined", server_default="joined")  # waiting|joined
    mic_on: Mapped[bool] = mapped_column(Boolean, default=False, server_default="false")
    cam_on: Mapped[bool] = mapped_column(Boolean, default=False, server_default="false")
    hand_raised: Mapped[bool] = mapped_column(Boolean, default=False, server_default="false")
    recording_request: Mapped[str] = mapped_column(String(16), default="none", server_default="none")
    recording_request_id: Mapped[str | None] = mapped_column(String(36))
    screen_sharing: Mapped[bool] = mapped_column(Boolean, default=False, server_default="false")
    screen_share_id: Mapped[str | None] = mapped_column(String(36))
    muted_by_host: Mapped[bool] = mapped_column(Boolean, default=False, server_default="false")
    joined_at: Mapped[datetime | None] = mapped_column(TS)  # NULL while waiting (requestedAt = created_at)
    created_at: Mapped[datetime] = mapped_column(TS, server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(TS, server_default=func.now())
    last_seen_at: Mapped[datetime] = mapped_column(TS, server_default=func.now())
    disconnected_at: Mapped[datetime | None] = mapped_column(TS)


class RoomConnectionLease(Base):
    """A reconnect gets a new lease; closing an old socket cannot remove the new one."""
    __tablename__ = "room_connection_leases"
    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    room_id: Mapped[str] = mapped_column(ForeignKey("live_rooms.id", ondelete="CASCADE"), index=True)
    participant_id: Mapped[str] = mapped_column(ForeignKey("room_participants.id", ondelete="CASCADE"), index=True)
    last_seen_at: Mapped[datetime] = mapped_column(TS, server_default=func.now())


class RoomChatMessage(Base):
    """房间聊天消息。sender 不加 FK（参与者行可先删）；seq 为房间内单调游标。"""

    __tablename__ = "room_chat_messages"
    __table_args__ = (UniqueConstraint("room_id", "seq", name="uq_chat_room_seq"),)
    id: Mapped[str] = mapped_column(String(80), primary_key=True)  # msg-<uuid4>
    room_id: Mapped[str] = mapped_column(ForeignKey("live_rooms.id", ondelete="CASCADE"))
    seq: Mapped[int] = mapped_column(BigInteger)
    sender_id: Mapped[str] = mapped_column(String(80))
    sender_name: Mapped[str] = mapped_column(String(80))  # snapshot
    text: Mapped[str] = mapped_column(Text, default="", server_default="")
    attachment_name: Mapped[str | None] = mapped_column(String(200))
    attachment_size: Mapped[int | None] = mapped_column(BigInteger)
    attachment_id: Mapped[str | None] = mapped_column(ForeignKey("room_attachments.id"))
    created_at: Mapped[datetime] = mapped_column(TS, server_default=func.now())


class RoomAttachment(Base):
    __tablename__ = "room_attachments"
    id: Mapped[str] = mapped_column(String(80), primary_key=True)
    room_id: Mapped[str] = mapped_column(ForeignKey("live_rooms.id", ondelete="CASCADE"), index=True)
    owner_participant_id: Mapped[str] = mapped_column(String(80))
    name: Mapped[str] = mapped_column(String(200))
    size: Mapped[int] = mapped_column(BigInteger)
    published: Mapped[bool] = mapped_column(Boolean, default=False, server_default="false")
    created_at: Mapped[datetime] = mapped_column(TS, server_default=func.now())


class RoomRecordingChunk(Base):
    __tablename__ = "room_recording_chunks"
    __table_args__ = (UniqueConstraint("room_id", "chunk_id", name="uq_room_recording_chunk"),)
    id: Mapped[str] = mapped_column(String(80), primary_key=True)
    room_id: Mapped[str] = mapped_column(ForeignKey("live_rooms.id", ondelete="CASCADE"), index=True)
    chunk_id: Mapped[str] = mapped_column(String(80))
    recording_epoch: Mapped[int] = mapped_column(Integer, default=0, server_default="0")
    participant_id: Mapped[str] = mapped_column(String(80))
    speaker_name: Mapped[str] = mapped_column(String(80))
    start_time: Mapped[float] = mapped_column(Float)
    storage: Mapped[str] = mapped_column(String(16))
    storage_key: Mapped[str] = mapped_column(Text)
    size: Mapped[int] = mapped_column(Integer)
    sha256: Mapped[str] = mapped_column(String(64))
    expires_at: Mapped[datetime | None] = mapped_column(TS, index=True)
    purged_at: Mapped[datetime | None] = mapped_column(TS)
    created_at: Mapped[datetime] = mapped_column(TS, server_default=func.now())


class RoomRecordingSpeaker(Base):
    """Joined identity survives leave/remove, so the last buffered audio can be saved."""
    __tablename__ = "room_recording_speakers"
    participant_id: Mapped[str] = mapped_column(String(80), primary_key=True)
    room_id: Mapped[str] = mapped_column(ForeignKey("live_rooms.id", ondelete="CASCADE"), index=True)
    user_id: Mapped[str | None] = mapped_column(String(64))
    name: Mapped[str] = mapped_column(String(80))
