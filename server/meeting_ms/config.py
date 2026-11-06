from __future__ import annotations

import logging
import os
import secrets
from functools import lru_cache
from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import Field

logger = logging.getLogger(__name__)


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="OPENMEETING_", env_file=".env", extra="ignore")

    env: str = "production"  # "dev" enables insecure defaults
    database_url: str = "postgresql+asyncpg://openmeeting:openmeeting@localhost:5432/openmeeting_meeting"
    data_dir: Path = Path("./data")
    secret_key: str | None = None
    job_workers: int = 1
    recording_chunk_retention_days: int = Field(default=3, ge=0, le=3650)
    recording_chunk_maintenance_interval_seconds: int = Field(default=60, ge=10, le=86400)
    auto_migrate: bool = True
    cors_origins: str = ""  # comma separated; empty = CORS disabled
    log_level: str = "INFO"
    # 共享令牌：非空时，除 /healthz 外的所有请求必须携带 X-Internal-Token 头（由网关注入）。
    internal_service_token: str = ""
    # 房间容量上限（超出 join → 409 full）
    room_max_participants: int = 50
    room_heartbeat_timeout_seconds: float = Field(default=45, ge=1)
    room_member_grace_seconds: float = Field(default=90, ge=45)
    room_host_grace_seconds: float = Field(default=180, ge=45)
    room_disconnect_grace_seconds: float = Field(default=3, ge=1)
    room_sweep_interval_seconds: float = Field(default=1, ge=1)
    # Authenticated members receive this configuration; never log TURN credentials.
    screen_share_ice_servers: list[dict] = []
    # All service-to-service calls go through the authenticated gateway internal API.
    gateway_ms_url: str = "http://localhost:39110"
    egress_proxy_url: str = "http://localhost:39111"
    # auto 保持旧配置行为；显式 local / minio / oss 决定后续文件写入位置。
    storage_provider: str = Field(default="auto", pattern="^(auto|local|minio|oss)$")
    minio_endpoint: str | None = None
    minio_public_endpoint: str | None = None
    minio_region: str = "us-east-1"
    minio_bucket: str | None = None
    minio_access_key_id: str | None = None
    minio_access_key_secret: str | None = None
    minio_prefix: str = "openmeeting"
    # Aliyun OSS overrides for meeting audio (take precedence over the values saved in the admin UI)
    oss_endpoint: str | None = None
    oss_region: str | None = None
    oss_bucket: str | None = None
    oss_access_key_id: str | None = None
    oss_access_key_secret: str | None = None
    oss_prefix: str | None = None

    @property
    def is_dev(self) -> bool:
        return self.env.lower() in {"dev", "development", "test"}

    @property
    def audio_dir(self) -> Path:
        return self.data_dir / "audio"

    @property
    def templates_dir(self) -> Path:
        return self.data_dir / "templates"

    def resolved_secret_key(self) -> str:
        """Secret used for Fernet (LLM / OSS keys at rest); persisted under data_dir when not configured."""
        if self.secret_key:
            return self.secret_key
        path = self.data_dir / "secret_key"
        if path.exists():
            return path.read_text().strip()
        self.data_dir.mkdir(parents=True, exist_ok=True)
        key = secrets.token_urlsafe(48)
        path.write_text(key)
        os.chmod(path, 0o600)
        logger.warning("OPENMEETING_SECRET_KEY not set; generated one at %s", path)
        return key


@lru_cache
def get_settings() -> Settings:
    settings = Settings()
    settings.data_dir = settings.data_dir.resolve()
    for d in (settings.data_dir, settings.audio_dir):
        d.mkdir(parents=True, exist_ok=True)
    if not settings.internal_service_token:
        logger.warning("OPENMEETING_INTERNAL_SERVICE_TOKEN not set; downstream API accepts unauthenticated requests")
    return settings
