from __future__ import annotations

import logging
import os
import secrets
from functools import lru_cache
from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict

logger = logging.getLogger(__name__)


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="OPENMEETING_", env_file=".env", extra="ignore")

    env: str = "production"  # "dev" enables insecure defaults
    database_url: str = "postgresql+asyncpg://openmeeting:openmeeting@localhost:5432/openmeeting_stt"
    data_dir: Path = Path("./data")
    secret_key: str | None = None
    stt_concurrency: int = 1
    auto_migrate: bool = True
    cors_origins: str = ""  # comma separated; empty = CORS disabled
    log_level: str = "INFO"
    # 共享令牌：非空时，除 /healthz 外的所有请求必须携带 X-Internal-Token 头（由网关注入）。
    internal_service_token: str = ""
    egress_proxy_url: str = "http://localhost:39111"

    @property
    def is_dev(self) -> bool:
        return self.env.lower() in {"dev", "development", "test"}

    @property
    def models_dir(self) -> Path:
        return self.data_dir / "models"

    def resolved_secret_key(self) -> str:
        """Secret used for Fernet (cloud STT API key at rest); persisted under data_dir when not configured."""
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
    # Empty passthrough variables (e.g. from docker-compose defaults) would break the hub clients.
    for var in ("HF_ENDPOINT", "MODELSCOPE_DOMAIN"):
        if os.environ.get(var) == "":
            del os.environ[var]
    settings.data_dir = settings.data_dir.resolve()
    for d in (settings.data_dir, settings.models_dir):
        d.mkdir(parents=True, exist_ok=True)
    if not settings.internal_service_token:
        logger.warning("OPENMEETING_INTERNAL_SERVICE_TOKEN not set; downstream API accepts unauthenticated requests")
    return settings
