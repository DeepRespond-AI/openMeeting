"""Release package files: local disk under `data_dir/releases`, or OSS when it is configured
(same bucket as meeting audio, under `releases/`)."""
from __future__ import annotations

import asyncio
import hashlib
import logging
import re
import shutil
from collections.abc import AsyncIterator
from dataclasses import dataclass
from pathlib import Path

from fastapi import HTTPException

from user_ms.config import get_settings
from user_ms.storage import oss
from service_net.minio_store import OBJECT_BACKENDS

logger = logging.getLogger(__name__)

LOCAL = "local"
OSS = "oss"

_SAFE = re.compile(r"[^A-Za-z0-9._+-]+")

_CONTENT_TYPES = {
    ".apk": "application/vnd.android.package-archive",
    ".dmg": "application/x-apple-diskimage",
    ".exe": "application/vnd.microsoft.portable-executable",
    ".msi": "application/x-msi",
    ".gz": "application/gzip",
    ".zip": "application/zip",
    ".appimage": "application/octet-stream",
}


def safe_filename(name: str | None) -> str:
    base = _SAFE.sub("_", Path(name or "package").name).strip("._") or "package"
    return base[:200]


def content_type_for(file_name: str) -> str:
    return _CONTENT_TYPES.get(Path(file_name).suffix.lower(), "application/octet-stream")


@dataclass(frozen=True)
class StoredFile:
    storage: str
    key: str
    file_name: str
    content_type: str
    size: int
    sha256: str


def _release_dir(release_id: str, arch: str) -> Path:
    return get_settings().releases_dir / release_id / arch


async def store_package(release_id: str, arch: str, file_name: str, chunks: AsyncIterator[bytes]) -> StoredFile:
    """Spool the upload to disk (hashing it), then keep it there or move it to OSS."""
    file_name = safe_filename(file_name)
    directory = _release_dir(release_id, arch)
    staging = directory.parent / ".incoming"
    staging.mkdir(parents=True, exist_ok=True)
    tmp = staging / f"{arch}-{file_name}"
    digest = hashlib.sha256()
    size = 0
    with tmp.open("wb") as fh:
        async for chunk in chunks:
            if chunk:
                fh.write(chunk)
                digest.update(chunk)
                size += len(chunk)
    if size == 0:
        tmp.unlink(missing_ok=True)
        raise HTTPException(400, "上传的安装包为空")
    content_type = content_type_for(file_name)

    store = await oss.get_audio_store()
    if store is not None:
        key = store.key("releases", release_id, arch, file_name)
        try:
            await store.upload(tmp, key, content_type)
        except Exception as exc:
            logger.exception("OSS upload failed for release %s", release_id)
            raise HTTPException(502, f"安装包上传到 {store.backend.upper()} 对象存储失败：{oss.describe_error(exc)}") from exc
        finally:
            tmp.unlink(missing_ok=True)
        return StoredFile(store.backend, key, file_name, content_type, size, digest.hexdigest())

    if directory.exists():
        await asyncio.to_thread(shutil.rmtree, directory, True)
    directory.mkdir(parents=True, exist_ok=True)
    final = directory / file_name
    tmp.rename(final)
    return StoredFile(LOCAL, str(final), file_name, content_type, size, digest.hexdigest())


async def delete_package(storage: str, key: str) -> None:
    """Best effort: a missing file or an OSS error never blocks deleting the database row."""
    try:
        if storage in OBJECT_BACKENDS:
            store = await oss.get_audio_store(storage)
            if store is not None:
                await store.delete_prefix(key)
        else:
            Path(key).unlink(missing_ok=True)
    except Exception:  # noqa: BLE001
        logger.warning("Deleting release package %s failed", key, exc_info=True)


async def delete_release_dir(release_id: str) -> None:
    await asyncio.to_thread(shutil.rmtree, get_settings().releases_dir / release_id, True)
