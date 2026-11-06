"""Job persistence helpers shared by the runner, the summary service and the API."""
from __future__ import annotations

from meeting_ms.db.models import Job, Meeting
from meeting_ms.db.session import session_factory
from meeting_ms.infrastructure.user_client import UserClient
from meeting_ms.monitor.events import broker
from meeting_ms.utils import iso, new_job_id, utcnow

TERMINAL = {"completed", "failed", "cancelled"}


def job_dict(job: Job, user_name: str | None = None, include_user: bool = False) -> dict:
    d = {
        "id": job.id,
        "kind": job.kind,
        "status": job.status,
        "progress": job.progress,
        "message": job.message,
        "meeting_id": job.meeting_id,
        "error": job.error,
        "segments": job.segments,
        "created_at": iso(job.created_at),
        "updated_at": iso(job.updated_at),
    }
    if include_user:
        d["user_name"] = user_name
    return d


async def _publish(job_id: str) -> None:
    async with session_factory()() as session:
        job = await session.get(Job, job_id)
    if job is not None:
        names = await UserClient().users_batch([job.user_id])
        broker.publish("jobs", job_dict(job, names.get(job.user_id), include_user=True))


async def create_job(user_id: str, kind: str, meeting_id: str | None, params: dict | None = None,
                     status: str = "queued", message: str | None = None) -> Job:
    now = utcnow()
    job = Job(
        id=new_job_id(), user_id=user_id, kind=kind, status=status, progress=0, message=message,
        meeting_id=meeting_id, params=params or {}, created_at=now, updated_at=now,
    )
    async with session_factory()() as session:
        session.add(job)
        await session.commit()
    await _publish(job.id)
    return job


async def update_job(job_id: str, *, only_if_active: bool = True, **values) -> Job | None:
    """Update a job (skipped once it reached a terminal state, unless only_if_active=False)."""
    async with session_factory()() as session:
        job = await session.get(Job, job_id, with_for_update=True)
        if job is None or (only_if_active and job.status in TERMINAL):
            return job
        for key, value in values.items():
            setattr(job, key, value)
        job.updated_at = utcnow()
        if job.kind == "room_recording" and values.get("status") in ("completed", "failed"):
            from meeting_ms.infrastructure.im_notifications import meeting_event
            meeting = await session.get(Meeting, job.meeting_id)
            if meeting:
                event = "processing_" + values["status"]
                await meeting_event(session, job.params.get('room_id'), meeting, event, f"processing:{job.id}:{event}")
        await session.commit()
    await _publish(job_id)
    return job


async def get_job(job_id: str) -> Job | None:
    async with session_factory()() as session:
        return await session.get(Job, job_id)
