"""Read-only meeting browser and job management for admins."""
from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import and_, exists, func, select, true
from sqlalchemy.ext.asyncio import AsyncSession

from meeting_ms.api.v1.meetings import meeting_details
from meeting_ms.db.models import Job, Meeting, SummaryProcess, Transcript
from meeting_ms.db.session import get_session
from meeting_ms.infrastructure.user_client import UserClient
from meeting_ms.jobs import store as job_store
from meeting_ms.jobs.runner import job_runner
from meeting_ms.summary.service import get_summary_response
from meeting_ms.utils import iso

router = APIRouter(tags=["admin-data"])


def _user_client() -> UserClient:
    return UserClient()


@router.get("/jobs")
async def list_jobs(
    status: str | None = None, limit: int = Query(200, ge=1, le=1000), session: AsyncSession = Depends(get_session)
) -> list[dict]:
    stmt = select(Job).order_by(Job.created_at.desc()).limit(limit)
    if status:
        stmt = stmt.where(Job.status.in_([s.strip() for s in status.split(",") if s.strip()]))
    jobs = (await session.execute(stmt)).scalars().all()
    names = await _user_client().users_batch([j.user_id for j in jobs])
    return [job_store.job_dict(j, names.get(j.user_id), include_user=True) for j in jobs]


@router.delete("/jobs/{job_id}")
async def cancel_job(job_id: str, session: AsyncSession = Depends(get_session)) -> dict:
    job = await job_runner.cancel(job_id)
    if job is None:
        raise HTTPException(404, "任务不存在")
    names = await _user_client().users_batch([job.user_id])
    return job_store.job_dict(job, names.get(job.user_id), include_user=True)


@router.get("/meetings")
async def list_meetings(
    user_id: str | None = None,
    q: str | None = None,
    limit: int = Query(50, ge=1, le=500),
    offset: int = Query(0, ge=0),
    session: AsyncSession = Depends(get_session),
) -> dict:
    conditions = []
    if user_id:
        conditions.append(Meeting.user_id == user_id)
    if q and q.strip():
        conditions.append(Meeting.title.ilike(f"%{q.strip()}%"))
    where = and_(*conditions) if conditions else true()
    total = (await session.execute(select(func.count(Meeting.id)).where(where))).scalar_one()
    transcript_count = (
        select(func.count(Transcript.id)).where(Transcript.meeting_id == Meeting.id).correlate(Meeting).scalar_subquery()
    )
    has_summary = exists().where(
        SummaryProcess.meeting_id == Meeting.id, SummaryProcess.result.is_not(None)
    ).correlate(Meeting)
    rows = (
        await session.execute(
            select(Meeting, transcript_count, has_summary)
            .where(where)
            .order_by(Meeting.created_at.desc())
            .limit(limit)
            .offset(offset)
        )
    ).all()
    names = await _user_client().users_batch([m.user_id for m, _, _ in rows])
    items = [
        {
            "id": m.id,
            "title": m.title,
            "user_name": names.get(m.user_id),
            "created_at": iso(m.created_at),
            "transcript_count": count,
            "has_audio": bool(m.audio_path),
            "has_summary": bool(summary),
        }
        for m, count, summary in rows
    ]
    return {"items": items, "total": total}


@router.get("/meetings/{meeting_id}")
async def meeting_detail(meeting_id: str, session: AsyncSession = Depends(get_session)) -> dict:
    meeting = await session.get(Meeting, meeting_id)
    if meeting is None:
        raise HTTPException(404, "会议不存在")
    names = await _user_client().users_batch([meeting.user_id])
    summary = await get_summary_response(session, meeting, internal=True)
    return {
        **await meeting_details(session, meeting),
        "user_name": names.get(meeting.user_id),
        "summary": None if summary["status"] == "idle" else summary,
    }
