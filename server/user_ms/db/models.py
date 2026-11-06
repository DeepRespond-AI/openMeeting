from __future__ import annotations

from datetime import datetime

from sqlalchemy import BigInteger, Boolean, DateTime, ForeignKey, Index, Integer, String, Text, UniqueConstraint, func
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column


class Base(DeclarativeBase):
    pass


TS = DateTime(timezone=True)


class User(Base):
    __tablename__ = "users"
    __table_args__ = (UniqueConstraint("phone", name="uq_users_phone"),)
    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    # Normalized 11-digit mainland mobile number; null only for legacy users created before phone login.
    phone: Mapped[str | None] = mapped_column(String(20))
    name: Mapped[str] = mapped_column(String(200))
    disabled: Mapped[bool] = mapped_column(Boolean, default=False, server_default="false")
    created_at: Mapped[datetime] = mapped_column(TS, server_default=func.now())
    last_login_at: Mapped[datetime | None] = mapped_column(TS)
    # scrypt hash (user_ms.auth.passwords); null = no password set yet (SMS-code login only).
    password_hash: Mapped[str | None] = mapped_column(Text)
    password_failed_count: Mapped[int] = mapped_column(Integer, default=0, server_default="0")
    password_locked_until: Mapped[datetime | None] = mapped_column(TS)


class UserSession(Base):
    """Client login session (bearer `ms_…`, only the sha256 is stored). Sliding expiry."""

    __tablename__ = "sessions"
    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    user_id: Mapped[str] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    token_hash: Mapped[str] = mapped_column(String(64), unique=True)
    client_id: Mapped[str | None] = mapped_column(String(200))
    hostname: Mapped[str | None] = mapped_column(String(255))
    os: Mapped[str | None] = mapped_column(String(100))
    app_version: Mapped[str | None] = mapped_column(String(64))
    ip: Mapped[str | None] = mapped_column(String(64))
    created_at: Mapped[datetime] = mapped_column(TS, server_default=func.now())
    last_used_at: Mapped[datetime | None] = mapped_column(TS)
    expires_at: Mapped[datetime] = mapped_column(TS)
    revoked: Mapped[bool] = mapped_column(Boolean, default=False, server_default="false")


class SmsCode(Base):
    """Verification codes (hashed with the server secret as pepper)."""

    __tablename__ = "sms_codes"
    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    phone: Mapped[str] = mapped_column(String(20), index=True)
    purpose: Mapped[str] = mapped_column(String(16))
    code_hash: Mapped[str] = mapped_column(String(64))
    ip: Mapped[str | None] = mapped_column(String(64))
    attempts: Mapped[int] = mapped_column(Integer, default=0, server_default="0")
    created_at: Mapped[datetime] = mapped_column(TS, server_default=func.now())
    expires_at: Mapped[datetime] = mapped_column(TS)
    consumed_at: Mapped[datetime | None] = mapped_column(TS)


class SmsLog(Base):
    """Audit log of SMS send attempts (never contains the code). Also drives rate limiting."""

    __tablename__ = "sms_logs"
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    phone: Mapped[str] = mapped_column(String(20), index=True)
    purpose: Mapped[str] = mapped_column(String(16))
    ip: Mapped[str | None] = mapped_column(String(64), index=True)
    ok: Mapped[bool] = mapped_column(Boolean)
    error: Mapped[str | None] = mapped_column(Text)
    request_id: Mapped[str | None] = mapped_column(String(128))
    created_at: Mapped[datetime] = mapped_column(TS, server_default=func.now(), index=True)


class UserSettings(Base):
    __tablename__ = "user_settings"
    user_id: Mapped[str] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), primary_key=True)
    data: Mapped[dict] = mapped_column(JSONB, default=dict, server_default="{}")
    updated_at: Mapped[datetime] = mapped_column(TS, server_default=func.now())


class ClientRelease(Base):
    """A client version published from the admin console (upgrade prompts, staged rollout)."""

    __tablename__ = "client_releases"
    __table_args__ = (UniqueConstraint("platform", "version", "build", name="uq_client_releases_version"),)
    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    # windows | macos | linux | android | ios
    platform: Mapped[str] = mapped_column(String(16), index=True)
    # x.y.z; `build` orders releases with the same version (Android versionCode), 0 = none.
    version: Mapped[str] = mapped_column(String(32))
    build: Mapped[int] = mapped_column(Integer, default=0, server_default="0")
    notes: Mapped[str] = mapped_column(Text, default="", server_default="")
    force: Mapped[bool] = mapped_column(Boolean, default=False, server_default="false")
    # draft | published | paused | archived; only published releases are offered.
    status: Mapped[str] = mapped_column(String(16), default="draft", server_default="draft")
    # Staged rollout: share of devices (stable hash of client id) plus allow-listed user ids.
    rollout_percent: Mapped[int] = mapped_column(Integer, default=100, server_default="100")
    rollout_users: Mapped[list] = mapped_column(JSONB, default=list, server_default="[]")
    published_at: Mapped[datetime | None] = mapped_column(TS)
    created_at: Mapped[datetime] = mapped_column(TS, server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(TS, server_default=func.now())


class ClientReleaseArtifact(Base):
    """Installer / update package of a release, one per architecture."""

    __tablename__ = "client_release_artifacts"
    __table_args__ = (UniqueConstraint("release_id", "arch", name="uq_client_release_artifacts_arch"),)
    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    release_id: Mapped[str] = mapped_column(ForeignKey("client_releases.id", ondelete="CASCADE"), index=True)
    # x86_64 | aarch64 | universal (macOS) | any (Android)
    arch: Mapped[str] = mapped_column(String(16))
    file_name: Mapped[str] = mapped_column(String(255))
    content_type: Mapped[str | None] = mapped_column(String(100))
    size: Mapped[int] = mapped_column(BigInteger)
    sha256: Mapped[str] = mapped_column(String(64))
    # Tauri updater signature (contents of the `.sig` file); desktop only.
    signature: Mapped[str | None] = mapped_column(Text)
    storage: Mapped[str] = mapped_column(String(8))  # local | oss
    storage_key: Mapped[str] = mapped_column(Text)  # local path or OSS object key
    download_count: Mapped[int] = mapped_column(Integer, default=0, server_default="0")
    created_at: Mapped[datetime] = mapped_column(TS, server_default=func.now())


class SystemSetting(Base):
    __tablename__ = "system_settings"
    key: Mapped[str] = mapped_column(String(120), primary_key=True)
    value: Mapped[dict | list | str | int | float | bool | None] = mapped_column(JSONB)
    updated_at: Mapped[datetime] = mapped_column(TS, server_default=func.now())
