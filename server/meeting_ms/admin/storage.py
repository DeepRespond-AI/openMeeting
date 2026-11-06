"""Meeting audio storage statistics and legacy configuration endpoints."""
from __future__ import annotations

from fastapi import APIRouter, Depends
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from meeting_ms.admin import object_storage
from meeting_ms.admin.object_storage import OssSettingsIn
from meeting_ms.db.models import Meeting
from meeting_ms.db.session import get_session
from meeting_ms.storage import oss

router = APIRouter(tags=["admin-storage"])


async def audio_stats(session: AsyncSession) -> dict:
    rows = (
        await session.execute(
            select(Meeting.audio_storage, func.count(Meeting.id), func.coalesce(func.sum(Meeting.audio_size), 0))
            .where(Meeting.audio_path.is_not(None))
            .group_by(Meeting.audio_storage)
        )
    ).all()
    stats = {key: {"meetings": 0, "bytes": 0} for key in ("local", "oss", "minio")}
    for backend, count, size in rows:
        stats.setdefault(backend, {"meetings": 0, "bytes": 0}).update(meetings=count, bytes=int(size))
    return stats


@router.get("/storage/audio")
async def get_audio_storage(session: AsyncSession = Depends(get_session)) -> dict:
    cfg = await oss.load_oss_config()
    return {"provider": cfg.provider, "oss_ready": cfg.ready, "stats": await audio_stats(session)}


@router.get("/storage")
async def get_storage(session: AsyncSession = Depends(get_session)) -> dict:
    """Compatibility response for older admin clients."""
    return {**await object_storage.settings_dict(), "stats": await audio_stats(session)}


@router.put("/storage")
async def put_storage(body: OssSettingsIn, session: AsyncSession = Depends(get_session)) -> dict:
    settings = await object_storage.put_object_storage(body)
    return {**settings, "stats": await audio_stats(session)}


@router.post("/storage/test")
async def storage_test() -> dict:
    return await object_storage.storage_test()
