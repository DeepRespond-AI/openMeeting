from __future__ import annotations

import logging
import os
import secrets
from functools import lru_cache
from pathlib import Path

from pydantic import HttpUrl, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

logger = logging.getLogger(__name__)


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="OPENMEETING_", env_file=".env", extra="ignore")

    env: str = "production"  # "dev" enables insecure defaults
    database_url: str = "postgresql+asyncpg://openmeeting:openmeeting@localhost:5432/openmeeting_user"
    data_dir: Path = Path("./data")
    admin_password: str | None = None
    secret_key: str | None = None
    admin_token_ttl_hours: int = 24 * 7
    auto_migrate: bool = True
    cors_origins: str = ""  # comma separated; empty = CORS disabled
    # Comma-separated IPs/CIDRs of reverse proxies allowed to set X-Forwarded-For / X-Real-IP.
    # Empty = ignore those headers (they are client-controlled and would bypass per-IP SMS limits).
    trusted_proxies: str = ""
    log_level: str = "INFO"
    # 共享令牌：非空时，除 /healthz 外的所有请求必须携带 X-Internal-Token 头（由网关注入）。
    internal_service_token: str = ""
    gateway_ms_url: str = "http://localhost:39110"
    egress_proxy_url: str = "http://localhost:39111"
    storage_provider: str = "auto"
    # Optional OSS CNAME for release downloads only; uploads retain the storage endpoint.
    oss_download_domain: str | None = None
    # Aliyun SMS overrides (take precedence over the values saved in the admin UI)
    sms_access_key_id: str | None = None
    sms_access_key_secret: str | None = None
    sms_sign_name: str | None = None
    sms_template_code: str | None = None
    sms_template_param: str | None = None
    sms_endpoint: str | None = None
    # deeprespond IM（可选）。enabled=false 或 SDK 未安装时所有 IM 调用自动降级；
    # org/app 取 AppKey「#」前后两段，client_id/secret 在 IM 控制台创建应用后取得。
    im_enabled: bool = False
    im_base_url: str = ""
    im_org_name: str = ""
    im_app_name: str = ""
    im_client_id: str = ""
    im_client_secret: str = ""
    im_timeout_seconds: float = 10.0
    # IM 服务端回调（「接收回调」地址）：endpoint_id 与密钥在 IM 控制台创建地址后取得；
    # secret 支持逗号分隔多个（轮换期间新旧密钥并存，任一签名通过即可）。
    im_callback_endpoint_id: str = ""
    im_callback_secret: str = ""

    @field_validator("oss_download_domain")
    @classmethod
    def validate_oss_download_domain(cls, value: str | None) -> str | None:
        if not value or not value.strip():
            return None
        url = HttpUrl(value.strip())
        if (url.scheme != "https" or url.path not in (None, "", "/")
                or url.query is not None or url.fragment is not None
                or url.username is not None or url.password is not None):
            raise ValueError("OSS download domain must be an HTTPS origin without path, query or credentials")
        return str(url).rstrip("/")

    @property
    def is_dev(self) -> bool:
        return self.env.lower() in {"dev", "development", "test"}

    @property
    def releases_dir(self) -> Path:
        return self.data_dir / "releases"

    def resolved_admin_password(self) -> str:
        if self.admin_password:
            return self.admin_password
        if self.is_dev:
            return "admin"
        raise RuntimeError("OPENMEETING_ADMIN_PASSWORD must be set (or OPENMEETING_ENV=dev for the insecure default)")

    def resolved_secret_key(self) -> str:
        """Secret used for admin JWTs and Fernet; persisted under data_dir when not configured."""
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
    settings.data_dir.mkdir(parents=True, exist_ok=True)
    if not settings.admin_password and settings.is_dev:
        logger.warning("OPENMEETING_ADMIN_PASSWORD not set; using insecure default 'admin' (dev mode)")
    if not settings.internal_service_token:
        logger.warning("OPENMEETING_INTERNAL_SERVICE_TOKEN not set; downstream API accepts unauthenticated requests")
    return settings
