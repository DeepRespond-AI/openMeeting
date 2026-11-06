"""OSS access for release packages.

The OSS configuration lives in the meeting_ms database (global object storage settings); this module
fetches the effective config from meeting_ms `/internal/oss-config` (short TTL cache) and
talks to the same bucket directly.
"""
from __future__ import annotations

import asyncio
import logging
import time
import uuid
from dataclasses import dataclass
from functools import lru_cache
from pathlib import Path

from user_ms.config import get_settings
from user_ms.infrastructure.meeting_client import _client  # shared internal-token client factory
from service_net.egress import configure_requests
from service_net.minio_store import MinioStore
from service_net.oss_direct_upload import OssDirectUpload

logger = logging.getLogger(__name__)

PRESIGN_TTL_SEC = 3600
MULTIPART_THRESHOLD = 32 * 1024 * 1024
PART_SIZE = 8 * 1024 * 1024
CONFIG_TTL_SEC = 30.0


@dataclass(frozen=True)
class OssConfig:
    endpoint: str | None
    region: str | None
    bucket: str | None
    access_key_id: str | None
    access_key_secret: str | None
    prefix: str
    provider: str = "oss"
    public_endpoint: str | None = None

    @property
    def ready(self) -> bool:
        if self.provider == "local" or (self.provider == "minio" and not self.public_endpoint):
            return False
        return bool(self.endpoint and self.region and self.bucket and self.access_key_id and self.access_key_secret)


_cached_config: OssConfig | None = None
_cached_at: float = 0.0
_backend_configs: dict[str, tuple[OssConfig, float]] = {}


async def load_oss_config(backend: str | None = None) -> OssConfig:
    global _cached_config, _cached_at
    if backend and backend in _backend_configs:
        cfg, at = _backend_configs[backend]
        if time.monotonic() - at < CONFIG_TTL_SEC:
            return cfg
    if backend is None and _cached_config is not None and time.monotonic() - _cached_at < CONFIG_TTL_SEC:
        return _cached_config
    try:
        async with _client(timeout=10) as client:
            r = await client.get("/oss-config", params={"backend": backend} if backend else None)
        r.raise_for_status()
        raw = r.json()
        cfg = OssConfig(
            endpoint=raw.get("endpoint"),
            region=raw.get("region"),
            bucket=raw.get("bucket"),
            access_key_id=raw.get("access_key_id"),
            access_key_secret=raw.get("access_key_secret"),
            prefix=raw.get("prefix") or "",
            provider=raw.get("provider") or "oss",
            public_endpoint=raw.get("public_endpoint"),
        )
        if backend is not None and cfg.provider != backend:
            raise RuntimeError("内部对象存储配置与文件记录的后端不一致")
    except Exception:  # noqa: BLE001 - releases fall back to local disk when meeting_ms is down
        # 无法确认当前配置时不能使用过期配置写入，显式对象存储模式也不能静默落盘。
        if backend is not None or get_settings().storage_provider in {"minio", "oss"}:
            from fastapi import HTTPException
            raise HTTPException(503, "无法取得对象存储配置，请检查会议服务和网关")
        logger.warning("Fetching OSS config from meeting_ms failed; releases stay on local disk")
        return OssConfig(None, None, None, None, None, "")
    if backend:
        _backend_configs[backend] = (cfg, time.monotonic())
    else:
        _cached_config, _cached_at = cfg, time.monotonic()
    return cfg


class OssStore(OssDirectUpload):
    """Async facade over one OSS bucket. All SDK calls run in worker threads."""

    backend = "oss"

    def __init__(self, cfg: OssConfig):
        import oss2

        self.cfg = cfg
        self._oss2 = oss2
        auth = oss2.AuthV4(cfg.access_key_id, cfg.access_key_secret)
        session = oss2.Session()
        configure_requests(session.session, get_settings())
        self.bucket = oss2.Bucket(auth, f"https://{cfg.endpoint}", cfg.bucket, region=cfg.region,
                                  connect_timeout=15, session=session)
        download_domain = get_settings().oss_download_domain
        # Sign with the CNAME-aware SDK client; do not replace the host after signing.
        self.download_bucket = (
            oss2.Bucket(auth, download_domain, cfg.bucket, is_cname=True, region=cfg.region,
                        connect_timeout=15, session=session)
            if download_domain else self.bucket
        )

    def key(self, *parts: str) -> str:
        return self.cfg.prefix + "/".join(parts)

    async def upload(self, local_path: Path, key: str, content_type: str | None) -> None:
        headers = {"x-oss-server-side-encryption": "AES256"}
        if content_type:
            headers["Content-Type"] = content_type
        checkpoints = get_settings().data_dir / "oss-checkpoints"

        def _run() -> None:
            checkpoints.mkdir(parents=True, exist_ok=True)
            self._oss2.resumable_upload(
                self.bucket, key, str(local_path), headers=headers,
                store=self._oss2.ResumableStore(root=str(checkpoints)),
                multipart_threshold=MULTIPART_THRESHOLD, part_size=PART_SIZE, num_threads=2,
            )

        await asyncio.to_thread(_run)

    async def download_to(self, key: str, path: Path) -> None:
        await asyncio.to_thread(self.bucket.get_object_to_file, key, str(path))

    def presign_get(self, key: str, expires: int = PRESIGN_TTL_SEC) -> str:
        return self.download_bucket.sign_url("GET", key, expires, slash_safe=True)

    async def delete_prefix(self, prefix: str, keep: str | None = None) -> int:
        """Delete every object under `prefix` (except `keep`); returns the number deleted."""

        def _run() -> int:
            keys = [o.key for o in self._oss2.ObjectIterator(self.bucket, prefix=prefix, max_keys=1000)
                    if o.key != keep]
            for i in range(0, len(keys), 1000):
                self.bucket.batch_delete_objects(keys[i:i + 1000])
            return len(keys)

        return await asyncio.to_thread(_run)


@lru_cache(maxsize=4)
def _store_for(cfg: OssConfig) -> OssStore | MinioStore:
    return MinioStore(cfg, get_settings()) if cfg.provider == "minio" else OssStore(cfg)


async def get_audio_store(backend: str | None = None) -> OssStore | MinioStore | None:
    """The OSS store when fully configured, else None (release packages stay on local disk)."""
    cfg = await load_oss_config(backend)
    if not cfg.ready and backend is None and get_settings().storage_provider in {"minio", "oss"}:
        from fastapi import HTTPException
        raise HTTPException(503, "对象存储配置不完整，请检查环境变量")
    return _store_for(cfg) if cfg.ready else None


def describe_error(exc: BaseException) -> str:
    """Short, human-readable message for oss2 errors (which carry code/message/request id)."""
    code = getattr(exc, "code", None)
    message = getattr(exc, "message", None)
    if code or message:
        request_id = getattr(exc, "request_id", None)
        text = f"{code or ''} {message or ''}".strip()
        return f"{text} (RequestId: {request_id})" if request_id else text
    return str(exc) or exc.__class__.__name__
