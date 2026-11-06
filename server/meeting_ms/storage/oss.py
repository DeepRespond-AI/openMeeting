"""Aliyun OSS configuration and a thin async wrapper over the (synchronous) oss2 SDK."""
from __future__ import annotations

import asyncio
import logging
import re
import uuid
from dataclasses import dataclass
from functools import lru_cache
from pathlib import Path

from meeting_ms.config import get_settings
from meeting_ms.db.settings_store import get_setting, set_setting
from meeting_ms.utils import secret_box
from service_net.egress import configure_requests
from service_net.minio_store import MinioStore
from service_net.oss_direct_upload import OssDirectUpload

logger = logging.getLogger(__name__)

OSS_CONFIG_KEY = "oss_config"
PRESIGN_TTL_SEC = 3600
MULTIPART_THRESHOLD = 32 * 1024 * 1024
PART_SIZE = 8 * 1024 * 1024

_REGION_RE = re.compile(r"oss-([a-z0-9-]+?)(?:-internal)?\.aliyuncs\.com$")


def normalize_endpoint(raw: str | None) -> str | None:
    endpoint = (raw or "").strip().removeprefix("https://").removeprefix("http://").rstrip("/")
    return endpoint or None


def normalize_prefix(raw: str | None) -> str:
    prefix = (raw or "").strip().strip("/")
    return f"{prefix}/" if prefix else ""


def region_from_endpoint(endpoint: str | None) -> str | None:
    m = _REGION_RE.search(endpoint or "")
    return m.group(1) if m else None


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
        if self.provider == "local":
            return False
        if self.provider == "minio" and not self.public_endpoint:
            return False
        return bool(self.endpoint and self.region and self.bucket and self.access_key_id and self.access_key_secret)


async def load_stored_oss_config() -> dict:
    raw = await get_setting(OSS_CONFIG_KEY, None)
    return dict(raw) if isinstance(raw, dict) else {}


async def save_stored_oss_config(data: dict) -> None:
    await set_setting(OSS_CONFIG_KEY, data)


def env_overrides() -> set[str]:
    """Config fields currently pinned by OPENMEETING_OSS_* env vars (read-only in the admin UI)."""
    s = get_settings()
    fields = ("endpoint", "region", "bucket", "access_key_id", "access_key_secret", "prefix")
    if getattr(s, "storage_provider", "auto") in {"minio", "local"}:
        return set(fields)
    return {f for f in fields if getattr(s, f"oss_{f}")}


async def load_oss_config(backend: str | None = None) -> OssConfig:
    """Effective config: values saved in system_settings, overridden by OPENMEETING_OSS_* env vars."""
    s = get_settings()
    provider = backend or getattr(s, "storage_provider", "auto")
    if provider == "minio":
        return OssConfig(s.minio_endpoint, s.minio_region, s.minio_bucket, s.minio_access_key_id,
                         s.minio_access_key_secret, normalize_prefix(s.minio_prefix), "minio", s.minio_public_endpoint)
    if provider == "local":
        return OssConfig(None, None, None, None, None, "", "local")
    stored = await load_stored_oss_config()
    endpoint = normalize_endpoint(s.oss_endpoint or stored.get("endpoint"))
    secret = s.oss_access_key_secret or secret_box().decrypt(stored.get("access_key_secret_enc"))
    return OssConfig(
        endpoint=endpoint,
        region=(s.oss_region or stored.get("region") or region_from_endpoint(endpoint) or None),
        bucket=(s.oss_bucket or stored.get("bucket") or None),
        access_key_id=(s.oss_access_key_id or stored.get("access_key_id") or None),
        access_key_secret=secret or None,
        prefix=normalize_prefix(s.oss_prefix or stored.get("prefix")),
    )


class OssAudioStore(OssDirectUpload):
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

    def presign_get(self, key: str, expires: int = PRESIGN_TTL_SEC) -> str:
        # No response-content-type / response-content-disposition overrides: OSS rejects them
        # on the bucket's default domain (400 "Can not override response header"). The object
        # already carries the Content-Type set at upload.
        return self.bucket.sign_url("GET", key, expires, slash_safe=True)

    async def download_to(self, key: str, path: Path) -> None:
        await asyncio.to_thread(self.bucket.get_object_to_file, key, str(path))

    async def delete_prefix(self, prefix: str, keep: str | None = None) -> int:
        """Delete every object under `prefix` (except `keep`); returns the number deleted."""

        def _run() -> int:
            keys = [o.key for o in self._oss2.ObjectIterator(self.bucket, prefix=prefix, max_keys=1000)
                    if o.key != keep]
            for i in range(0, len(keys), 1000):
                self.bucket.batch_delete_objects(keys[i:i + 1000])
            return len(keys)

        return await asyncio.to_thread(_run)

    async def test(self) -> None:
        """Round-trip a tiny object; raises on any failure."""
        key = self.key(".openmeeting-test", uuid.uuid4().hex)
        payload = b"openmeeting oss connectivity test"

        def _run() -> None:
            self.bucket.put_object(key, payload)
            try:
                if self.bucket.get_object(key).read() != payload:
                    raise RuntimeError("读回的内容与写入的不一致")
            finally:
                self.bucket.delete_object(key)

        await asyncio.to_thread(_run)


@lru_cache(maxsize=4)
def _store_for(cfg: OssConfig) -> OssAudioStore | MinioStore:
    return MinioStore(cfg, get_settings()) if cfg.provider == "minio" else OssAudioStore(cfg)


async def get_audio_store(backend: str | None = None) -> OssAudioStore | MinioStore | None:
    """The OSS store when fully configured, else None (meeting audio stays on local disk)."""
    cfg = await load_oss_config(backend)
    if not cfg.ready and backend is None and get_settings().storage_provider in {"minio", "oss"}:
        from fastapi import HTTPException
        raise HTTPException(503, f"{cfg.provider} 对象存储配置不完整，请检查环境变量")
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
