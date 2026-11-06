from __future__ import annotations

import asyncio
import logging
import re
import shutil
from pathlib import Path

from fastapi import APIRouter, Depends, HTTPException, Request
from fastapi.responses import FileResponse, RedirectResponse, Response
from sqlalchemy.ext.asyncio import AsyncSession

from meeting_ms.api.deps import accessible_meeting, owned_meeting
from meeting_ms.api.deps import AuthContext, require_client
from meeting_ms.db.models import Meeting
from meeting_ms.db.session import get_session
from meeting_ms.storage import oss
from meeting_ms.storage.audio import LOCAL, OSS, meeting_audio_dir, upload_to_oss
from service_net.minio_store import OBJECT_BACKENDS
from service_net.direct_upload import UploadProof, UploadComplete, create_offer, read_ticket, confirm_object, cleanup_pending
from pydantic import Field
from meeting_ms.stt.audio import probe_duration
from meeting_ms.utils import utcnow

logger = logging.getLogger(__name__)
router = APIRouter(tags=["audio"])

_SAFE = re.compile(r"[^A-Za-z0-9._-]+")


def safe_filename(name: str | None, default: str = "audio.mp4") -> str:
    base = Path(name or default).name
    base = _SAFE.sub("_", base).strip("._") or default
    return base[:120]


async def store_audio_stream(
    meeting: Meeting, chunks, filename: str, content_type: str | None, keep_local: bool = False
) -> tuple[int, float | None]:
    """Store an async byte stream as the meeting's audio, replacing any previous file.

    The stream is spooled to the meeting's local audio dir; when OSS is configured it is then
    uploaded and the local copy removed — unless `keep_local` (imports: the job transcribes the
    local file and moves it to OSS afterwards, so the upload request returns right away).
    """
    directory = meeting_audio_dir(meeting)
    staging = directory / ".incoming"
    staging.mkdir(parents=True, exist_ok=True)
    final = directory / filename
    tmp = staging / filename  # keeps the real extension for ffprobe/soundfile
    size = 0
    with tmp.open("wb") as fh:
        async for chunk in chunks:
            if chunk:
                fh.write(chunk)
                size += len(chunk)
    if size == 0:
        tmp.unlink(missing_ok=True)
        raise HTTPException(400, "上传的音频为空")
    duration = await asyncio.to_thread(probe_duration, tmp)
    meeting.audio_content_type = content_type

    store = None if keep_local else await oss.get_audio_store()
    if store is not None:
        try:
            await upload_to_oss(store, meeting, tmp, filename)
        except Exception as exc:
            tmp.unlink(missing_ok=True)
            logger.exception("OSS upload failed for meeting %s", meeting.id)
            raise HTTPException(502, f"音频上传到 {store.backend.upper()} 对象存储失败：{oss.describe_error(exc)}") from exc
        await asyncio.to_thread(shutil.rmtree, directory, True)
    else:
        for old in directory.iterdir():
            if old.is_file() and not old.name.startswith("."):
                old.unlink()
        tmp.rename(final)
        staging.rmdir()
        meeting.audio_storage = LOCAL
        meeting.audio_path = str(final)
    meeting.audio_size = size
    meeting.duration = duration
    meeting.updated_at = utcnow()
    return size, duration


@router.put("/meetings/{meeting_id}/audio")
async def upload_audio(
    meeting_id: str,
    request: Request,
    filename: str = "audio.mp4",
    ctx: AuthContext = Depends(require_client),
    session: AsyncSession = Depends(get_session),
) -> dict:
    meeting = await owned_meeting(session, ctx, meeting_id)
    content_type = request.headers.get("content-type")
    size, duration = await store_audio_stream(meeting, request.stream(), safe_filename(filename), content_type)
    await session.commit()
    return {"size": size, "duration": duration}


class AudioUploadProof(UploadProof):
    duration: float | None = Field(default=None, ge=0, allow_inf_nan=False)


@router.post("/meetings/{meeting_id}/audio/uploads")
async def prepare_audio_upload(meeting_id: str, body: AudioUploadProof,
                               ctx: AuthContext = Depends(require_client), session: AsyncSession = Depends(get_session)):
    meeting = await owned_meeting(session, ctx, meeting_id)
    store = await oss.get_audio_store()
    if store is None:
        return {"mode": "proxy"}
    import mimetypes
    from meeting_ms.config import get_settings
    content_type = mimetypes.guess_type(body.file_name)[0] or "application/octet-stream"
    return create_offer(store, get_settings().resolved_secret_key(), ctx.user_id, "meeting-audio", meeting.id,
                        body, ["audio", ctx.user_id, meeting.id], content_type, duration=body.duration)


@router.post("/meetings/{meeting_id}/audio/uploads/complete")
async def complete_audio_upload(meeting_id: str, body: UploadComplete,
                                ctx: AuthContext = Depends(require_client), session: AsyncSession = Depends(get_session)):
    from meeting_ms.config import get_settings
    claims = read_ticket(body.ticket, get_settings().resolved_secret_key(), ctx.user_id, "meeting-audio", meeting_id)
    meeting = await owned_meeting(session, ctx, meeting_id)
    await session.refresh(meeting, with_for_update=True)
    store = await oss.get_audio_store(claims["backend"])
    await confirm_object(store, claims)
    old_backend, old_key = meeting.audio_storage, meeting.audio_path
    meeting.audio_storage, meeting.audio_path = store.backend, claims["key"]
    meeting.audio_size, meeting.audio_content_type = claims["size"], claims["content_type"]
    if claims["extra"].get("duration") is not None:
        meeting.duration = claims["extra"]["duration"]
    meeting.updated_at = utcnow()
    await session.commit()
    await cleanup_pending(store, claims)
    if old_key and old_key != claims["key"]:
        try:
            if old_backend in OBJECT_BACKENDS:
                previous = await oss.get_audio_store(old_backend)
                if previous:
                    await previous.delete_object(old_key)
            else:
                old = Path(old_key).resolve()
                if old.is_relative_to(get_settings().audio_dir.resolve()):
                    old.unlink(missing_ok=True)
        except Exception:
            logger.warning("Old meeting audio cleanup deferred", exc_info=True)
    return {"size": meeting.audio_size, "duration": meeting.duration}


@router.get("/meetings/{meeting_id}/audio")
async def download_audio(
    meeting_id: str, ctx: AuthContext = Depends(require_client), session: AsyncSession = Depends(get_session)
) -> Response:
    meeting = await accessible_meeting(session, ctx, meeting_id)
    if not meeting.audio_path:
        raise HTTPException(404, "该会议没有音频")
    filename = Path(meeting.audio_path).name
    if meeting.audio_storage in OBJECT_BACKENDS:
        store = await oss.get_audio_store(meeting.audio_storage)
        if store is None:
            raise HTTPException(503, f"会议音频存放在 {meeting.audio_storage}，但对应对象存储未配置")
        url = store.presign_get(meeting.audio_path)
        return RedirectResponse(url, status_code=302, headers={"Cache-Control": "no-store"})
    path = Path(meeting.audio_path)
    if not path.exists():
        raise HTTPException(404, "该会议没有音频")
    return FileResponse(path, media_type=meeting.audio_content_type or None, filename=filename)
