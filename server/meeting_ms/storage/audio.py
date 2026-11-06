"""Where a meeting's audio lives: a local file under data_dir/audio, or an object in Aliyun OSS.

`Meeting.audio_storage` says which; `Meeting.audio_path` holds the absolute local path ("local")
or the object key ("oss").
"""
from __future__ import annotations

import asyncio
import logging
import shutil
import tempfile
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from pathlib import Path

from meeting_ms.config import get_settings
from meeting_ms.db.models import Meeting
from meeting_ms.db.session import session_factory
from meeting_ms.storage import oss
from meeting_ms.storage.oss import OssAudioStore
from service_net.minio_store import OBJECT_BACKENDS

logger = logging.getLogger(__name__)

LOCAL = "local"
OSS = "oss"


def meeting_audio_dir(m: Meeting) -> Path:
    return get_settings().audio_dir / m.user_id / m.id


def meeting_object_prefix(store: OssAudioStore, m: Meeting) -> str:
    return store.key("audio", m.user_id, m.id) + "/"


async def upload_to_oss(store: OssAudioStore, m: Meeting, local_file: Path, filename: str) -> str:
    """Upload `local_file` as the meeting's audio, drop its other objects, point the row at it."""
    key = meeting_object_prefix(store, m) + filename
    await store.upload(local_file, key, m.audio_content_type)
    try:
        await store.delete_prefix(meeting_object_prefix(store, m), keep=key)
    except Exception:  # noqa: BLE001 - a stale object is harmless, the row points at the new key
        logger.warning("Failed to delete old OSS audio for meeting %s", m.id, exc_info=True)
    m.audio_storage = store.backend
    m.audio_path = key
    return key


@asynccontextmanager
async def open_meeting_audio(m: Meeting) -> AsyncIterator[Path]:
    """Yield a local path to the meeting's audio, downloading OSS objects to a temp dir."""
    if not m.audio_path:
        raise RuntimeError("会议音频不存在")
    if m.audio_storage not in OBJECT_BACKENDS:
        path = Path(m.audio_path)
        if not path.exists():
            raise RuntimeError("会议音频不存在")
        yield path
        return
    store = await oss.get_audio_store(m.audio_storage)
    if store is None:
        raise RuntimeError(f"会议音频存放在 {m.audio_storage}，但对应对象存储未配置")
    tmp_root = get_settings().data_dir / "tmp"
    tmp_root.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="audio-", dir=tmp_root) as d:
        path = Path(d) / Path(m.audio_path).name
        try:
            await store.download_to(m.audio_path, path)
        except Exception as exc:
            raise RuntimeError(f"从 OSS 下载会议音频失败：{oss.describe_error(exc)}") from exc
        yield path


async def move_local_audio_to_oss(meeting_id: str) -> bool:
    """Move a meeting's local audio to OSS (when configured); True when moved. The local copy is
    removed only after the row points at the object."""
    store = await oss.get_audio_store()
    if store is None:
        return False
    async with session_factory()() as session:
        m = await session.get(Meeting, meeting_id)
        if m is None or m.audio_storage in OBJECT_BACKENDS or not m.audio_path:
            return False
        local = Path(m.audio_path)
        if not local.exists():
            return False
        await upload_to_oss(store, m, local, local.name)
        await session.commit()
    # 多人会议旧录音可能直接位于 audio 根目录，只删除该文件，绝不递归删除公共目录。
    owned_dir = meeting_audio_dir(m).resolve()
    if local.parent.resolve() == owned_dir and owned_dir.is_relative_to(get_settings().audio_dir.resolve()):
        await asyncio.to_thread(shutil.rmtree, owned_dir, True)
    else:
        local.unlink(missing_ok=True)
    return True


async def delete_meeting_files(m: Meeting) -> None:
    path = meeting_audio_dir(m)
    if path.exists():
        await asyncio.to_thread(shutil.rmtree, path, True)
    if m.audio_storage not in OBJECT_BACKENDS:
        if m.audio_path:
            local = Path(m.audio_path).resolve()
            if local.is_relative_to(get_settings().audio_dir.resolve()):
                local.unlink(missing_ok=True)
        return
    try:
        store = await oss.get_audio_store(m.audio_storage)
        if store is not None:
            await store.delete_prefix(meeting_object_prefix(store, m))
    except Exception:  # noqa: BLE001 - the meeting is already gone; an orphaned object is only cost
        logger.warning("Failed to delete OSS audio for meeting %s", m.id, exc_info=True)
