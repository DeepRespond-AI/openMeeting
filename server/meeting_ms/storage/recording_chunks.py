"""会中 PCM 对象存储与仅针对已完成任务的延迟清理。"""
from __future__ import annotations

import asyncio
from datetime import timedelta
import hashlib
import logging
from pathlib import Path
import tempfile

from fastapi import HTTPException
from sqlalchemy import and_, or_, select

from meeting_ms.config import get_settings
from meeting_ms.db.models import Job, LiveRoom, RoomRecordingChunk
from meeting_ms.db.session import session_factory
from meeting_ms.storage import oss
from meeting_ms.utils import utcnow

logger = logging.getLogger(__name__)


async def require_store(backend: str | None = None):
    store = await oss.get_audio_store(backend)
    if store is None:
        raise HTTPException(503, "会议录音分片需要配置 MinIO 或 OSS 对象存储")
    return store


async def upload_pcm(room_id: str, chunk_id: str, pcm: bytes) -> dict:
    store = await require_store()
    # Same logical chunk/body reuses its key on retry after an interrupted commit.
    digest = hashlib.sha256(pcm).hexdigest()
    identity = hashlib.sha256((chunk_id + "\0" + digest).encode("utf-8")).hexdigest()
    key = store.key("room-recordings", room_id, identity + ".pcm")
    tmp_root = get_settings().data_dir / "tmp"
    tmp_root.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="pcm-upload-", dir=tmp_root) as directory:
        path = Path(directory) / "chunk.pcm"
        await asyncio.to_thread(path.write_bytes, pcm)
        try:
            await store.upload(path, key, "application/octet-stream")
        except Exception as exc:
            logger.warning("PCM upload failed for room %s (%s)", room_id, store.backend, exc_info=True)
            raise HTTPException(502, "会议音频分片上传对象存储失败，请重试") from exc
    return {"storage": store.backend, "storage_key": key, "size": len(pcm),
            "sha256": digest}


async def download_pcm(chunk: RoomRecordingChunk, path: Path) -> None:
    if chunk.purged_at is not None:
        raise RuntimeError("会议音频分片已按保留策略清理")
    store = await require_store(chunk.storage)
    await store.download_to(chunk.storage_key, path)
    size = path.stat().st_size
    if not size or size % 2 or size > 320000 or size != chunk.size:
        raise RuntimeError("会议音频分片校验失败，请检查对象存储")
    payload = await asyncio.to_thread(path.read_bytes)
    if hashlib.sha256(payload).hexdigest() != chunk.sha256:
        raise RuntimeError("会议音频分片校验失败，请检查对象存储")


async def cleanup_chunks(limit: int = 100) -> int:
    """Keep failed/running sources; purge completed sources after retention, or deleted meetings.

    Index rows remain as tombstones. Delete the object first so failed deletes are retried.
    """
    now = utcnow()
    latest_status = select(Job.status).where(Job.meeting_id == LiveRoom.meeting_id,
        Job.kind == "room_recording").order_by(Job.created_at.desc(), Job.id.desc()).limit(1).correlate(LiveRoom).scalar_subquery()
    latest_time = select(Job.updated_at).where(Job.meeting_id == LiveRoom.meeting_id,
        Job.kind == "room_recording").order_by(Job.created_at.desc(), Job.id.desc()).limit(1).correlate(LiveRoom).scalar_subquery()
    async with session_factory()() as session:
        candidates = list((await session.execute(select(RoomRecordingChunk.id, latest_time.label("finished"))
            .join(LiveRoom, LiveRoom.id == RoomRecordingChunk.room_id).where(
                LiveRoom.status == "ended", RoomRecordingChunk.purged_at.is_(None),
                or_(LiveRoom.meeting_id.is_(None), and_(latest_status == "completed", or_(
                    RoomRecordingChunk.expires_at.is_(None), RoomRecordingChunk.expires_at <= now))))
            .order_by(RoomRecordingChunk.created_at).limit(limit))).all())
    purged = 0
    for chunk_id, finished in candidates:
        async with session_factory()() as session:
            chunk = await session.scalar(select(RoomRecordingChunk).where(
                RoomRecordingChunk.id == chunk_id, RoomRecordingChunk.purged_at.is_(None))
                .with_for_update(skip_locked=True))
            if chunk is None:
                continue
            if finished is not None:
                if chunk.expires_at is None:
                    chunk.expires_at = finished + timedelta(days=get_settings().recording_chunk_retention_days)
                if chunk.expires_at > now:
                    await session.commit()
                    continue
            if chunk.storage_key:
                store = await require_store(chunk.storage)
                await store.delete_prefix(chunk.storage_key)
            chunk.purged_at = now
            await session.commit()
            purged += 1
    return purged


async def maintain_chunks() -> None:
    while True:
        # Do not delay startup or the first client request on object-store availability.
        await asyncio.sleep(get_settings().recording_chunk_maintenance_interval_seconds)
        try:
            purged = await cleanup_chunks()
            if purged:
                logger.info("PCM maintenance: purged=%d", purged)
        except Exception:
            logger.exception("PCM maintenance failed; source data retained for retry")
