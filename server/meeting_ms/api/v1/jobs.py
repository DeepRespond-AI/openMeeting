from __future__ import annotations

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile
from pydantic import BaseModel, Field
from sqlalchemy import select, text
from sqlalchemy.ext.asyncio import AsyncSession
from service_net.field_limits import MEETING_TITLE_MAX

from meeting_ms.api.deps import AuthContext, owned_meeting, require_client
from meeting_ms.api.v1.audio import safe_filename, store_audio_stream
from meeting_ms.db.models import Job, Meeting
from meeting_ms.db.session import get_session
from meeting_ms.infrastructure.stt_client import SttClient
from meeting_ms.jobs import store as job_store
from meeting_ms.jobs.runner import job_runner
from meeting_ms.storage.audio import delete_meeting_files
from meeting_ms.storage import oss
from meeting_ms.config import get_settings
from service_net.direct_upload import UploadProof, UploadComplete, create_offer, read_ticket, confirm_object, cleanup_pending
from meeting_ms.utils import new_meeting_id, utcnow

router = APIRouter(prefix="/jobs", tags=["jobs"])


async def _upload_chunks(upload: UploadFile):
    while chunk := await upload.read(1024 * 1024):
        yield chunk


async def _require_stt() -> None:
    if not await SttClient().ready():
        raise HTTPException(503, "语音识别模型未就绪")


@router.post("/import", status_code=202)
async def import_audio(
    file: UploadFile = File(...),
    title: str = Form(..., max_length=MEETING_TITLE_MAX),
    language: str | None = Form(None),
    ctx: AuthContext = Depends(require_client),
    session: AsyncSession = Depends(get_session),
) -> dict:
    await _require_stt()
    now = utcnow()
    meeting = Meeting(id=new_meeting_id(), user_id=ctx.user_id, title=title.strip() or "导入的会议", created_at=now, updated_at=now)
    session.add(meeting)
    await session.flush()
    try:
        # Kept on local disk: the client's upload ends now; the job moves it to OSS when done.
        await store_audio_stream(
            meeting, _upload_chunks(file), safe_filename(file.filename), file.content_type, keep_local=True
        )
    except Exception:
        await session.rollback()
        await delete_meeting_files(meeting)
        raise
    await session.commit()
    job = await job_store.create_job(ctx.user_id, "import", meeting.id, {"language": language}, message="排队中")
    job_runner.submit(job.id)
    return job_store.job_dict(job)


class DirectImportIn(UploadProof):
    title: str = Field(min_length=1, max_length=MEETING_TITLE_MAX)
    language: str | None = Field(default=None, max_length=32)


@router.post("/import/uploads")
async def prepare_import_upload(body: DirectImportIn, ctx: AuthContext = Depends(require_client)):
    await _require_stt()
    store = await oss.get_audio_store()
    if store is None:
        return {"mode": "proxy"}
    import mimetypes
    meeting_id = new_meeting_id()
    return create_offer(store, get_settings().resolved_secret_key(), ctx.user_id, "audio-import", meeting_id,
                        body, ["audio", ctx.user_id, meeting_id],
                        mimetypes.guess_type(body.file_name)[0] or "application/octet-stream",
                        title=body.title.strip() or "导入的会议", language=body.language)


@router.post("/import/uploads/complete", status_code=202)
async def complete_import_upload(body: UploadComplete, ctx: AuthContext = Depends(require_client),
                                 session: AsyncSession = Depends(get_session)):
    claims = read_ticket(body.ticket, get_settings().resolved_secret_key(), ctx.user_id, "audio-import")
    # Serialize retries even before a meeting/job row exists. The database is PostgreSQL.
    await session.execute(text("SELECT pg_advisory_xact_lock(hashtext(:id))"), {"id": claims["upload_id"]})
    job_id = "job-" + claims["upload_id"]
    existing = await session.get(Job, job_id)
    if existing is not None:
        return job_store.job_dict(existing)
    await _require_stt()
    store = await oss.get_audio_store(claims["backend"])
    await confirm_object(store, claims)
    now = utcnow()
    meeting = Meeting(id=claims["resource"], user_id=ctx.user_id, title=claims["extra"]["title"],
                      created_at=now, updated_at=now, audio_storage=store.backend, audio_path=claims["key"],
                      audio_size=claims["size"], audio_content_type=claims["content_type"])
    session.add(meeting)
    await session.flush()
    job = Job(id=job_id, user_id=ctx.user_id, kind="import", meeting_id=meeting.id,
              params={"language": claims["extra"].get("language")}, status="queued", progress=0,
              message="排队中", created_at=now, updated_at=now)
    session.add(job)
    await session.commit()
    await cleanup_pending(store, claims)
    job_runner.submit(job.id)
    return job_store.job_dict(job)


class RetranscribeIn(BaseModel):
    meeting_id: str
    language: str | None = None


@router.post("/retranscribe", status_code=202)
async def retranscribe(
    body: RetranscribeIn, ctx: AuthContext = Depends(require_client), session: AsyncSession = Depends(get_session)
) -> dict:
    meeting = await owned_meeting(session, ctx, body.meeting_id)
    if not meeting.audio_path:
        raise HTTPException(404, "该会议没有音频，无法重新转写")
    await _require_stt()
    active = (
        await session.execute(
            select(Job.id).where(
                Job.meeting_id == meeting.id, Job.kind.in_(("import", "retranscribe")), Job.status.in_(("queued", "running"))
            )
        )
    ).first()
    if active is not None:
        raise HTTPException(409, "该会议已有正在进行的转写任务")
    job = await job_store.create_job(ctx.user_id, "retranscribe", meeting.id, {"language": body.language}, message="排队中")
    job_runner.submit(job.id)
    return job_store.job_dict(job)


async def _owned_job(job_id: str, ctx: AuthContext) -> Job:
    job = await job_store.get_job(job_id)
    if job is None or job.user_id != ctx.user_id:
        raise HTTPException(404, "任务不存在")
    return job


@router.get("/{job_id}")
async def get_job(job_id: str, ctx: AuthContext = Depends(require_client)) -> dict:
    return job_store.job_dict(await _owned_job(job_id, ctx))


@router.delete("/{job_id}")
async def cancel_job(job_id: str, ctx: AuthContext = Depends(require_client)) -> dict:
    await _owned_job(job_id, ctx)
    job = await job_runner.cancel(job_id)
    assert job is not None
    return job_store.job_dict(job)
