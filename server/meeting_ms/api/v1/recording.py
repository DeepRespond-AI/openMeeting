"""Participant-track recording. All writes are authenticated and host controlled."""
import base64
import binascii
import math
import hashlib
from typing import Literal
from uuid import uuid4

from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from meeting_ms.api.deps import AuthContext, accessible_meeting, api_error, owned_meeting, require_client
from meeting_ms.api.v1.rooms import require_host, require_room_participant, room_snapshot, broadcast_state
from meeting_ms.db.models import Job, LiveRoom, RoomParticipant, RoomRecordingChunk, RoomRecordingSpeaker
from meeting_ms.db.session import get_session
from meeting_ms.jobs.runner import job_runner
from meeting_ms.jobs.store import job_dict
from meeting_ms.storage.recording_chunks import upload_pcm
from meeting_ms.utils import utcnow

router = APIRouter(tags=["room-recording"])


class ControlIn(BaseModel):
    action: Literal['start', 'stop', 'request', 'approve', 'deny']
    epoch: int = Field(ge=0)
    participantId: str | None = Field(default=None, max_length=80)
    requestId: str | None = Field(default=None, max_length=36)


@router.post('/rooms/{room_id}/recording/control')
async def control_recording(room_id: str, body: ControlIn, ctx: AuthContext = Depends(require_client),
                            session: AsyncSession = Depends(get_session)):
    await session.execute(select(LiveRoom).where(LiveRoom.id == room_id).with_for_update())
    room, me = await require_room_participant(session, ctx, room_id)
    if body.action != 'start':
        raise api_error(409, '会议已采用自动录音，无需手动控制或审批', code='automatic_recording')
    if body.action != 'request' and not me.is_host:
        raise api_error(403, '仅主持人可控制或审批会议录制', code='host_required')
    if body.epoch != room.recording_epoch:
        raise api_error(409, '录制状态已更新，请重试', code='recording_changed')
    changed = not room.recording_active
    if changed:
        room.recording_active = True
        room.recording_epoch += 1
        room.recording_started_at = utcnow()
    if changed:
        room.updated_at = utcnow()
        from meeting_ms.infrastructure.im_notifications import room_changed
        await room_changed(session, room, 'recording')
        await session.commit()
        await broadcast_state(session, room)
    return await room_snapshot(session, room, me.id)


class ChunkIn(BaseModel):
    chunkId: str = Field(min_length=1, max_length=80, pattern=r"^[\w-]+$")
    participantId: str = Field(max_length=80)
    startTime: float = Field(ge=0, le=43200)
    pcm: str = Field(max_length=426668)
    epoch: int = Field(ge=1)


@router.post("/rooms/{room_id}/recording/chunks", status_code=201)
async def upload_chunk(room_id: str, body: ChunkIn, ctx: AuthContext = Depends(require_client),
                       session: AsyncSession = Depends(get_session)):
    # Serialize with end_room: a committed final job sees every acknowledged chunk.
    locked = (await session.execute(select(LiveRoom).where(LiveRoom.id == room_id).with_for_update())).scalar_one_or_none()
    if locked is not None and locked.status == "ended":
        raise api_error(409, "会议已结束")
    room, _ = await require_host(session, ctx, room_id)
    try:
        pcm = base64.b64decode(body.pcm, validate=True)
    except (ValueError, binascii.Error):
        raise api_error(422, "音频编码无效")
    if not pcm or len(pcm) % 2 or len(pcm) > 320000 or not math.isfinite(body.startTime) or body.startTime + len(pcm) / 32000 > 43200:
        raise api_error(422, "音频须为不超过 10 秒的 PCM16，会议时长不超过 12 小时")
    existing = (await session.execute(select(RoomRecordingChunk).where(
        RoomRecordingChunk.room_id == room_id, RoomRecordingChunk.chunk_id == body.chunkId).with_for_update())).scalar_one_or_none()
    if existing:
        same_audio = existing.sha256 == hashlib.sha256(pcm).hexdigest() and existing.size == len(pcm)
        if not same_audio or existing.participant_id != body.participantId or existing.start_time != body.startTime or existing.recording_epoch != body.epoch:
            raise api_error(409, "音频分段标识已被使用", code="recording_conflict")
        return {"chunkId": existing.chunk_id}
    if not room.recording_active or body.epoch != room.recording_epoch:
        raise api_error(409, '录制未开始或该轮录制已停止', code='recording_inactive')
    participant = await session.get(RoomParticipant, body.participantId)
    speaker = await session.get(RoomRecordingSpeaker, body.participantId)
    if not speaker or speaker.room_id != room.id or (participant and participant.state != "joined"):
        raise api_error(422, "音轨所属参会者不在会议中")
    stored = await upload_pcm(room.id, body.chunkId, pcm)
    session.add(RoomRecordingChunk(id=str(uuid4()), room_id=room.id, chunk_id=body.chunkId,
        participant_id=speaker.participant_id, speaker_name=speaker.name, start_time=body.startTime,
        recording_epoch=body.epoch, **stored))
    await session.commit()
    return {"chunkId": body.chunkId}


async def latest_job(session, meeting_id):
    return (await session.execute(select(Job).where(Job.meeting_id == meeting_id, Job.kind == "room_recording")
        .order_by(Job.created_at.desc()).limit(1))).scalar_one_or_none()


@router.get("/meetings/{meeting_id}/recording")
async def recording_status(meeting_id: str, ctx: AuthContext = Depends(require_client),
                           session: AsyncSession = Depends(get_session)):
    await accessible_meeting(session, ctx, meeting_id)
    job = await latest_job(session, meeting_id)
    return {"status": job.status if job else "none", "error": job.error if job else None,
            "jobId": job.id if job else None, "message": job.message if job else None}


@router.post("/meetings/{meeting_id}/recording/retry", status_code=202)
async def retry_recording(meeting_id: str, ctx: AuthContext = Depends(require_client),
                          session: AsyncSession = Depends(get_session)):
    await owned_meeting(session, ctx, meeting_id)
    job = await latest_job(session, meeting_id)
    if job is None:
        raise api_error(404, "录制任务不存在")
    await session.refresh(job, with_for_update=True)
    if job.status not in ("failed", "cancelled"):
        raise api_error(409, "任务正在运行或已完成")
    job.status, job.error, job.progress, job.updated_at = "queued", None, 0, utcnow()
    await session.commit()
    job_runner.submit(job.id)
    return job_dict(job)
