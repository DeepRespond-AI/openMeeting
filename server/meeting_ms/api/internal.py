"""Internal API consumed by user_ms (auth via the shared internal token, enforced on the parent router)."""
from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, Response, Query
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from meeting_ms.db.models import Job, Meeting
from meeting_ms.db.session import get_session
from meeting_ms.jobs.runner import job_runner
from meeting_ms.storage.audio import delete_meeting_files

router = APIRouter(prefix="/internal", tags=["internal"])


@router.get("/oss-config")
async def oss_config(backend: str | None = Query(default=None, pattern="^(oss|minio)$")) -> dict:
    """Effective OSS configuration (secrets resolved) for user_ms release uploads.

     OSS 配置由本服务管理；user_ms 发布安装包时经此获取生效配置。"""
    from meeting_ms.storage.oss import env_overrides, load_oss_config

    cfg = await load_oss_config(backend)
    return {
        "endpoint": cfg.endpoint,
        "region": cfg.region,
        "bucket": cfg.bucket,
        "access_key_id": cfg.access_key_id,
        "access_key_secret": cfg.access_key_secret,
        "prefix": cfg.prefix,
        "provider": cfg.provider,
        "public_endpoint": cfg.public_endpoint,
        "env_pinned": sorted(env_overrides()),
    }


@router.get("/users/{user_id}/stats")
async def user_stats(user_id: str, session: AsyncSession = Depends(get_session)) -> dict:
    count = (
        await session.execute(select(func.count(Meeting.id)).where(Meeting.user_id == user_id))
    ).scalar_one()
    return {"meeting_count": int(count)}


@router.get("/users/stats-batch")
async def users_stats_batch(ids: str, session: AsyncSession = Depends(get_session)) -> dict:
    """Comma-separated user ids -> {"<id>": meeting_count}."""
    wanted = [i for i in (s.strip() for s in ids.split(",")) if i]
    if not wanted:
        return {}
    rows = (
        await session.execute(
            select(Meeting.user_id, func.count(Meeting.id)).where(Meeting.user_id.in_(wanted)).group_by(Meeting.user_id)
        )
    ).all()
    return {uid: int(count) for uid, count in rows}


@router.delete("/users/{user_id}/data", status_code=204)
async def delete_user_data(user_id: str, session: AsyncSession = Depends(get_session)) -> Response:
    """Delete every meeting (rows, audio files, transcripts, notes) and job of a user."""
    meetings = (await session.execute(select(Meeting).where(Meeting.user_id == user_id))).scalars().all()
    jobs = (await session.execute(select(Job).where(Job.user_id == user_id))).scalars().all()
    for job in jobs:
        if job.status not in ("completed", "failed", "cancelled"):
            await job_runner.cancel(job.id)
    for m in meetings:
        await session.delete(m)
    await session.commit()
    for m in meetings:
        await delete_meeting_files(m)
    return Response(status_code=204)
