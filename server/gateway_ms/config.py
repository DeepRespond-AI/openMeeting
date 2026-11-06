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

    env: str = "production"
    # 网关只读用户库（sessions/users 表）用于会话认证。
    database_url: str = "postgresql+asyncpg://openmeeting:openmeeting@localhost:5432/openmeeting_user"
    port: int = 39110
    admin_password: str | None = None
    secret_key: str | None = None
    admin_token_ttl_hours: int = 24 * 7  # only for the JWT `exp` sanity window
    cors_origins: str = ""
    # Comma-separated IPs/CIDRs of reverse proxies allowed to set X-Forwarded-For (like the old monolith).
    trusted_proxies: str = ""
    log_level: str = "INFO"
    # 下游服务地址
    user_ms_url: str = "http://localhost:39113"
    meeting_ms_url: str = "http://localhost:39107"
    stt_ms_url: str = "http://localhost:39109"
    # 注入给下游的内部令牌（与各 ms 的 OPENMEETING_INTERNAL_SERVICE_TOKEN 一致）
    internal_service_token: str = ""
    # 会话认证结果的进程内缓存秒数（吊销/禁用最迟此时生效）
    session_cache_ttl_sec: float = 30.0
    egress_enabled: bool = False
    egress_host: str = "0.0.0.0"
    egress_port: int = Field(default=39111, ge=1, le=65535)
    egress_allowed_hosts: list[str] = []
    egress_allowed_ports: list[int] = [80, 443]
    # Exact hostnames only: explicitly approved private LLM endpoints / isolated test upstreams.
    egress_private_hosts: list[str] = []
    egress_connect_timeout: float = Field(default=10, gt=0)
    egress_idle_timeout: float = Field(default=600, gt=0)
    egress_max_connections: int = Field(default=256, ge=1)

    @property
    def is_dev(self) -> bool:
        return self.env.lower() in {"dev", "development", "test"}

    @property
    def static_dir(self) -> Path:
        return Path(__file__).resolve().parent / "static" / "admin"

    def resolved_admin_password(self) -> str:
        if self.admin_password:
            return self.admin_password
        if self.is_dev:
            return "admin"
        raise RuntimeError("OPENMEETING_ADMIN_PASSWORD must be set (or OPENMEETING_ENV=dev for the insecure default)")

    def resolved_secret_key(self) -> str:
        """Admin JWT 签名密钥（与 user_ms 一致；只读用途）。网关不落盘生成，必须显式配置。"""
        if self.secret_key:
            return self.secret_key
        raise RuntimeError("OPENMEETING_SECRET_KEY must be set for the gateway (same value as user_ms)")


@lru_cache
def get_settings() -> Settings:
    settings = Settings()
    if not settings.admin_password and settings.is_dev:
        logger.warning("OPENMEETING_ADMIN_PASSWORD not set; using insecure default 'admin' (dev mode)")
    if not settings.internal_service_token:
        logger.warning("OPENMEETING_INTERNAL_SERVICE_TOKEN not set; forwarding without the internal token")
    if not settings.secret_key and not settings.is_dev:
        logger.warning("OPENMEETING_SECRET_KEY not set; admin JWT verification will reject every token")
    return settings
