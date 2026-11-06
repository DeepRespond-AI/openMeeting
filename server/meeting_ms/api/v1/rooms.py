"""Live rooms (API.md §1.10, design doc docs/development/archive/P1_BACKEND_DESIGN.md §4/§5.2).

Wire payloads are camelCase (frozen by frontend/src/services/live-meeting/types.ts).
Errors may carry a machine-readable `code` (not_found/not_started/ended/wrong_pwd/full) — see api_error().
"""
from __future__ import annotations

import asyncio
import logging
from datetime import timedelta, timezone
from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException, Query, Response
from pydantic import BaseModel, Field
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from service_net.field_limits import MEETING_TITLE_MAX as TITLE_MAX, ROOM_NAME_MAX as NAME_MAX

from meeting_ms.api.deps import AuthContext, api_error, require_client
from meeting_ms.db.models import Job, LiveRoom, Meeting, RoomParticipant, RoomRecordingSpeaker, RoomRecordingChunk, ScheduledMeeting
from meeting_ms.db.session import get_session
from meeting_ms.infrastructure.room_events import manager
from meeting_ms.infrastructure import rtc_client, im_chat
from meeting_ms.utils import (
    generate_room_code,
    iso,
    iso_ms,
    new_meeting_id,
    new_participant_id,
    new_room_id,
    utcnow,
)

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/rooms", tags=["rooms"])

# Phase 1 媒体占位（无 SFU）：与前端 mock 完全一致，Phase 2 由 SFU 配置替换。
MEDIA_PLACEHOLDER = {"transport": "webrtc", "iceServers": [{"urls": "stun:stun.l.google.com:19302"}], "token": None}


# ----------------------------------------------------------------- serializers


def participant_dict(p: RoomParticipant, self_participant_id: str | None = None) -> dict:
    return {
        "id": p.id,
        "userId": p.user_id,
        "name": p.name,
        "isHost": p.is_host,
        "isSelf": p.id == self_participant_id,
        "micOn": p.mic_on,
        "mutedByHost": p.muted_by_host,
        "camOn": p.cam_on,
        "handRaised": p.hand_raised,
        "screenSharing": p.screen_sharing,
        "screenShareId": p.screen_share_id,
        "joinedAt": iso(p.joined_at) if p.joined_at else None,
    }


async def room_snapshot(session: AsyncSession, room: LiveRoom, self_participant_id: str | None = None) -> dict:
    parts = (
        await session.execute(
            select(RoomParticipant)
            .where(RoomParticipant.room_id == room.id, RoomParticipant.state == "joined")
            .order_by(RoomParticipant.joined_at.asc().nulls_last(), RoomParticipant.created_at.asc())
        )
    ).scalars().all()
    waiting_rows = (
        await session.execute(
            select(RoomParticipant)
            .where(RoomParticipant.room_id == room.id, RoomParticipant.state == "waiting")
            .order_by(RoomParticipant.created_at.asc())
        )
    ).scalars().all()
    return {
        "id": room.id,
        "title": room.title,
        "code": room.code,
        "scheduledMeetingId": room.scheduled_meeting_id,
        "status": room.status,
        "pwdEnabled": room.pwd_enabled,
        "waitRoom": room.wait_room,
        "hostId": room.host_participant_id,
        "hostUserId": room.host_user_id,
        "participants": [participant_dict(p, self_participant_id) for p in parts],
        "waiting": [
            {"participantId": p.id, "name": p.name, "requestedAt": iso(p.created_at)} for p in waiting_rows
        ],
        "startedAt": iso(room.started_at),
        "endedAt": iso(room.ended_at),
        "meetingId": room.meeting_id,
        "recording": {
            "active": room.recording_active,
            "epoch": room.recording_epoch,
            "startedAt": iso(room.recording_started_at),
            "requests": [{"participantId": p.id, "name": p.name,
                          "requestId": p.recording_request_id, "status": p.recording_request}
                         for p in parts if p.recording_request != "none"],
        },
    }


# ----------------------------------------------------------------- access helpers


async def active_room_by_code(session: AsyncSession, code: str) -> LiveRoom | None:
    return (
        await session.execute(
            select(LiveRoom).where(LiveRoom.code == code, LiveRoom.status != "ended")
        )
    ).scalar_one_or_none()


async def scheduled_by_code(session: AsyncSession, code: str) -> ScheduledMeeting | None:
    return (
        await session.execute(select(ScheduledMeeting).where(ScheduledMeeting.code == code).with_for_update())
    ).scalar_one_or_none()


async def require_room_participant(
    session: AsyncSession, ctx: AuthContext, room_id: str, *, joined: bool = True
) -> tuple[LiveRoom, RoomParticipant]:
    room = await session.get(LiveRoom, room_id)
    if room is None:
        raise api_error(404, "会议不存在")
    if room.status == "ended":
        raise api_error(404, "会议已结束", code="ended")
    p = (
        await session.execute(
            select(RoomParticipant).where(RoomParticipant.room_id == room_id, RoomParticipant.user_id == ctx.user_id)
        )
    ).scalar_one_or_none()
    if p is None:
        raise api_error(403, "你不在会议中", code="not_joined")
    if joined and p.state != "joined":
        raise api_error(403, "你尚未获准入会", code="waiting")
    return room, p


async def require_host(
    session: AsyncSession, ctx: AuthContext, room_id: str
) -> tuple[LiveRoom, RoomParticipant]:
    await session.execute(select(LiveRoom).where(LiveRoom.id == room_id).with_for_update())
    room, p = await require_room_participant(session, ctx, room_id)
    if not p.is_host:
        raise api_error(403, "仅主持人可执行该操作", code="host_required")
    return room, p


async def authorized_media(session: AsyncSession, room: LiveRoom, user_id: str) -> dict:
    media = await rtc_client.media_for(room, user_id)
    # Removal/end can commit while the platform issues the ticket. Recheck after
    # issuance so a concurrent revocation cannot be followed by a fresh grant.
    valid = (await session.execute(select(RoomParticipant.id).join(LiveRoom).where(
        RoomParticipant.room_id == room.id, RoomParticipant.user_id == user_id,
        RoomParticipant.state == "joined", LiveRoom.status != "ended"))).scalar_one_or_none()
    if valid is None:
        await rtc_client.remove(room.id, user_id)
        return rtc_client.PLACEHOLDER
    return media


async def broadcast_state(session: AsyncSession, room: LiveRoom) -> None:
    await manager.send_room_state(room.id, await room_snapshot(session, room))


async def close_participant(room_id: str, participant_id: str) -> None:
    for conn in list(manager._rooms.get(room_id, [])):
        if conn.participant_id == participant_id:
            manager.unregister(room_id, conn)
            try:
                await asyncio.wait_for(conn.websocket.close(code=1000), timeout=5)
            except Exception:  # noqa: BLE001
                pass


def _validate_pwd(pwd: str | None, *, required: bool) -> str | None:
    if not required:
        return None
    if pwd is None or not (4 <= len(pwd) <= 6) or not pwd.isascii() or not pwd.isdigit():
        raise api_error(422, "入会密码须为 4–6 位数字")
    return pwd


async def _create_room_for_scheduled(
    session: AsyncSession, ctx: AuthContext, sched: ScheduledMeeting
) -> tuple[LiveRoom, RoomParticipant]:
    # The caller owns the schedule row lock. A concurrent create/join may have
    # committed while it waited: always recheck before allocating a new scene.
    existing = await active_room_by_code(session, sched.code)
    if existing is not None:
        host = await session.scalar(select(RoomParticipant).where(
            RoomParticipant.room_id == existing.id, RoomParticipant.user_id == ctx.user_id))
        if host is None:
            raise api_error(409, "当前场次正在恢复，请稍后重试")
        # Release the schedule lock before taking the room lock in platform
        # preparation. Ending a scene locks the room then updates the schedule.
        await session.commit()
        await prepare_created_room(session, existing, host)
        return existing, host
    now = utcnow()
    room = LiveRoom(
        id=new_room_id(),
        code=sched.code,
        title=sched.title,
        scheduled_meeting_id=sched.id,
        status="active",
        pwd_enabled=sched.pwd_enabled,
        pwd=sched.pwd,
        wait_room=sched.wait_room,
        host_participant_id="",  # filled below
        host_user_id=ctx.user_id,
        started_at=now,
        recording_active=True, recording_epoch=1, recording_started_at=now,
        created_at=now,
        updated_at=now,
    )
    host = RoomParticipant(
        id=new_participant_id(),
        room_id=room.id,
        user_id=ctx.user_id,
        name=ctx.user_name[:NAME_MAX],
        is_host=True,
        state="joined",
        joined_at=now,
        created_at=now,
        updated_at=now,
    )
    room.host_participant_id = host.id
    session.add_all([room, host, RoomRecordingSpeaker(participant_id=host.id, room_id=room.id, user_id=host.user_id, name=host.name)])
    await session.commit()
    await prepare_created_room(session, room, host)
    return room, host


async def _create_quick_room(
    session: AsyncSession, ctx: AuthContext, title: str | None
) -> tuple[LiveRoom, RoomParticipant]:
    now = utcnow()
    creator = (ctx.user_name.strip() or (ctx.user_phone or "").strip() or "用户")[:NAME_MAX]
    # Persist one title for every client; Beijing time is independent of the server's timezone.
    timestamp = now.astimezone(timezone(timedelta(hours=8))).strftime("%Y-%m-%d %H:%M:%S")
    room = LiveRoom(
        id=new_room_id(),
        code=await generate_room_code(session),
        title=(title or "").strip() or f"{creator}的快速会议 {timestamp}",
        scheduled_meeting_id=None,
        status="active",
        pwd_enabled=False,
        pwd=None,
        wait_room=False,
        host_participant_id="",
        host_user_id=ctx.user_id,
        started_at=now,
        recording_active=True, recording_epoch=1, recording_started_at=now,
        created_at=now,
        updated_at=now,
    )
    host = RoomParticipant(
        id=new_participant_id(),
        room_id=room.id,
        user_id=ctx.user_id,
        name=ctx.user_name[:NAME_MAX],
        is_host=True,
        state="joined",
        joined_at=now,
        created_at=now,
        updated_at=now,
    )
    room.host_participant_id = host.id
    session.add_all([room, host, RoomRecordingSpeaker(participant_id=host.id, room_id=room.id, user_id=host.user_id, name=host.name)])
    await session.commit()
    await prepare_created_room(session, room, host)
    return room, host


async def prepare_created_room(session: AsyncSession, room: LiveRoom, host: RoomParticipant) -> None:
    # The business room is already committed. A platform outage must not turn a
    # successful room creation into a retry that creates another business room.
    # Serialize grants with end/remove exactly like the chat-session endpoint.
    await session.execute(select(LiveRoom).where(LiveRoom.id == room.id).with_for_update().execution_options(populate_existing=True))
    try:
        if room.status != "ended":
            await im_chat.session_for(session, room, host, commit=False)
    except HTTPException:
        # Keep a successful group binding even if the member grant failed;
        # chat-session retries the same group after the client enters this room.
        logger.warning("Meeting created; IM preparation awaits retry")
    finally:
        if room.status != "ended":
            await rtc_client.ensure_channel(room)
        await session.commit()


async def prepare_joined_chat(session: AsyncSession, room: LiveRoom, participant: RoomParticipant) -> None:
    # The caller holds the room lock. Grant before announcing admission, so
    # messages sent in response to participant_joined already reach this member.
    # As with creation, an IM outage leaves the business room recoverable; both
    # clients request chat-session on entry, without waiting for its UI to open.
    try:
        await im_chat.session_for(session, room, participant, commit=False)
    except HTTPException:
        logger.warning("Meeting joined; IM preparation awaits retry")


async def _owned_scheduled_for_room(session: AsyncSession, ctx: AuthContext, scheduled_id: str) -> ScheduledMeeting:
    sched = await session.get(ScheduledMeeting, scheduled_id, with_for_update=True)
    if sched is None or sched.user_id != ctx.user_id:
        raise api_error(404, "预定不存在")
    if sched.cancelled:
        raise api_error(409, "该预定已取消，无法开始会议")
    return sched


# ----------------------------------------------------------------- create / check / join


class RoomCreate(BaseModel):
    title: str | None = Field(default=None, max_length=TITLE_MAX)
    scheduledMeetingId: str | None = None


@router.post("", status_code=201)
async def create_room(
    body: RoomCreate, ctx: AuthContext = Depends(require_client), session: AsyncSession = Depends(get_session)
) -> dict:
    if body.scheduledMeetingId:
        sched = await _owned_scheduled_for_room(session, ctx, body.scheduledMeetingId)
        room, _host = await _create_room_for_scheduled(session, ctx, sched)
    else:
        room, _host = await _create_quick_room(session, ctx, body.title)
    return await room_snapshot(session, room, _host.id)


@router.get("")
async def check_room_code(
    code: str = Query(min_length=6, max_length=6),
    ctx: AuthContext = Depends(require_client),
    session: AsyncSession = Depends(get_session),
) -> dict:
    if not code.isdigit():
        raise api_error(422, "会议号格式不正确")
    room = await active_room_by_code(session, code)
    if room is not None:
        # Waiting clients have no WS yet; their existing authenticated polling
        # renews only their own seat, serialized with timeout cleanup.
        room = await session.get(LiveRoom, room.id, with_for_update=True, populate_existing=True)
        if room.status == "ended":
            raise api_error(404, "会议已结束", code="ended")
        waiting = (await session.execute(select(RoomParticipant).where(
            RoomParticipant.room_id == room.id, RoomParticipant.user_id == ctx.user_id,
            RoomParticipant.state == "waiting"))).scalar_one_or_none()
        if waiting:
            waiting.last_seen_at = utcnow()
            await session.commit()
        return await room_snapshot(session, room)
    sched = await scheduled_by_code(session, code)
    if sched is not None and not sched.cancelled:
        if sched.user_id == ctx.user_id:
            # Read-only owner preview: POST /rooms/join materializes the scene.
            # GET must not create an IM group or start automatic recording.
            return {
                "id": sched.id, "title": sched.title, "code": sched.code,
                "scheduledMeetingId": sched.id, "status": "waiting",
                "pwdEnabled": sched.pwd_enabled, "waitRoom": sched.wait_room,
                "hostId": "", "hostUserId": sched.user_id, "participants": [], "waiting": [],
                "startedAt": None, "endedAt": None, "meetingId": None,
                "recording": {"active": False, "epoch": 0, "startedAt": None, "requests": []},
            }
        raise api_error(404, "会议尚未开始，请等待房主进入后重试", code="not_started")
    ended = (
        await session.execute(
            select(LiveRoom.id).where(LiveRoom.code == code, LiveRoom.status == "ended").limit(1)
        )
    ).first()
    if ended is not None:
        raise api_error(404, "会议已结束", code="ended")
    raise api_error(404, "会议号不存在", code="not_found")


class JoinRoom(BaseModel):
    code: str
    name: str | None = Field(default=None, max_length=NAME_MAX)
    micOn: bool = False
    camOn: bool = False
    pwd: str | None = None


@router.post("/join")
async def join_room(
    body: JoinRoom, ctx: AuthContext = Depends(require_client), session: AsyncSession = Depends(get_session)
) -> dict:
    code = (body.code or "").strip()
    if not (len(code) == 6 and code.isdigit()):
        raise api_error(422, "会议号格式不正确")
    name = (body.name or "").strip() or ctx.user_name
    if len(name) > NAME_MAX:
        raise api_error(422, f"昵称不能超过 {NAME_MAX} 个字符")

    room = await active_room_by_code(session, code)
    host_join = False
    if room is None:
        # §4.2 入口表：有预定、无未结束房间 —— owner 加入即自动建房；非 owner → 404。
        sched = await scheduled_by_code(session, code)
        if sched is None:
            raise api_error(404, "会议号不存在", code="not_found")
        if sched.cancelled:
            raise api_error(404, "该预定已取消", code="not_found")
        if sched.user_id != ctx.user_id:
            raise api_error(404, "会议尚未开始，请等待房主进入后重试", code="not_started")
        room, _host = await _create_room_for_scheduled(session, ctx, sched)
        host_join = True

    room = await session.get(LiveRoom, room.id, with_for_update=True, populate_existing=True)
    if room.status == "ended":
        raise api_error(404, "会议已结束", code="ended")
    me = (
        await session.execute(
            select(RoomParticipant).where(
                RoomParticipant.room_id == room.id, RoomParticipant.user_id == ctx.user_id
            )
        )
    ).scalar_one_or_none()

    if me is not None:
        # 幂等重入（与 mock 一致，不受容量限制）：刷新昵称与初始开关。
        me.name = name
        me.mic_on = body.micOn and not me.muted_by_host
        me.cam_on = body.camOn
        me.updated_at = utcnow()
        me.last_seen_at = utcnow()
        me.disconnected_at = None
        if me.state == "joined":
            await prepare_joined_chat(session, room, me)
        await session.commit()
        state = me.state
    else:
        if room.pwd_enabled and not host_join and body.pwd != room.pwd:
            raise api_error(403, "入会密码错误", code="wrong_pwd")
        joined_count = (
            await session.execute(
                select(func.count(RoomParticipant.id)).where(
                    RoomParticipant.room_id == room.id, RoomParticipant.state == "joined"
                )
            )
        ).scalar_one()
        if joined_count >= get_max_participants():
            raise api_error(409, "会议人数已满", code="full")
        now = utcnow()
        is_host = room.host_user_id == ctx.user_id
        waiting = room.wait_room and not is_host
        me = RoomParticipant(
            id=new_participant_id(),
            room_id=room.id,
            user_id=ctx.user_id,
            name=name,
            is_host=is_host,
            state="waiting" if waiting else "joined",
            mic_on=body.micOn,
            cam_on=body.camOn,
            joined_at=None if waiting else now,
            created_at=now,
            updated_at=now,
        )
        session.add(me)
        if not waiting:
            session.add(RoomRecordingSpeaker(participant_id=me.id, room_id=room.id, user_id=me.user_id, name=me.name))
            await prepare_joined_chat(session, room, me)
        await session.commit()
        state = me.state
        if waiting:
            await manager.send_to_participant(
                room.id,
                room.host_participant_id,
                _envelope("waiting_requested", {"participantId": me.id, "name": me.name}),
            )
        else:
            await manager.broadcast_participant(room.id, "participant_joined", participant_dict(me))

    return {
        "room": await room_snapshot(session, room, me.id),
        "self": participant_dict(me, me.id),
        "state": state,
        "media": await authorized_media(session, room, ctx.user_id) if state == "joined" else MEDIA_PLACEHOLDER,
    }


@router.post("/{room_id}/media")
async def room_media(room_id: str, ctx: AuthContext = Depends(require_client),
                     session: AsyncSession = Depends(get_session)) -> dict:
    """Fresh one-use media authorization; waiting/removed users cannot obtain it."""
    room, _me = await require_room_participant(session, ctx, room_id)
    return await authorized_media(session, room, ctx.user_id)


class RecoverMediaIn(BaseModel):
    sessionId: str = Field(pattern=r"^[A-Za-z0-9_-]{1,64}$")


@router.post("/{room_id}/media/recover")
async def recover_room_media(room_id: str, body: RecoverMediaIn,
                             ctx: AuthContext = Depends(require_client),
                             session: AsyncSession = Depends(get_session)) -> dict:
    room, _ = await require_room_participant(session, ctx, room_id)
    # Identity and channel always come from the authenticated membership.
    # This operation does not change membership, chat, recording or the room.
    return await rtc_client.recover(room.id, ctx.user_id, body.sessionId)


def get_max_participants() -> int:
    from meeting_ms.config import get_settings

    return get_settings().room_max_participants


def _envelope(event_type: str, data: dict) -> dict:
    return {"type": event_type, "ts": iso_ms(utcnow()), "data": data}


# ----------------------------------------------------------------- room lifecycle


@router.get("/{room_id}")
async def get_room(
    room_id: str, ctx: AuthContext = Depends(require_client), session: AsyncSession = Depends(get_session)
) -> dict:
    room, me = await require_room_participant(session, ctx, room_id)
    return await room_snapshot(session, room, me.id)


@router.post("/{room_id}/leave", status_code=204)
async def leave_room(
    room_id: str, ctx: AuthContext = Depends(require_client), session: AsyncSession = Depends(get_session)
) -> Response:
    await session.execute(select(LiveRoom).where(LiveRoom.id == room_id).with_for_update())
    room, me = await require_room_participant(session, ctx, room_id, joined=False)
    if me.is_host:
        raise api_error(403, "主持人请使用「离开并结束会议」离场")
    await im_chat.remove(room, me.user_id)
    was_waiting = me.state == "waiting"
    await session.delete(me)
    await session.commit()
    if was_waiting:
        await broadcast_state(session, room)
    else:
        await manager.broadcast(room.id, _envelope("participant_left", {"participantId": me.id}))
    return Response(status_code=204)


class RoomPatch(BaseModel):
    title: str | None = Field(default=None, max_length=TITLE_MAX)
    pwdEnabled: bool | None = None
    pwd: str | None = None
    waitRoom: bool | None = None


@router.patch("/{room_id}")
async def patch_room(
    room_id: str,
    body: RoomPatch,
    ctx: AuthContext = Depends(require_client),
    session: AsyncSession = Depends(get_session),
) -> dict:
    await session.execute(select(LiveRoom).where(LiveRoom.id == room_id).with_for_update())
    room, _host = await require_host(session, ctx, room_id)
    if body.title is not None:
        room.title = body.title.strip() or room.title
    if body.pwdEnabled is not None:
        if body.pwdEnabled:
            room.pwd = _validate_pwd(body.pwd if body.pwd is not None else room.pwd, required=True)
            room.pwd_enabled = True
        else:
            room.pwd_enabled = False
            room.pwd = None
    elif body.pwd is not None and room.pwd_enabled:
        room.pwd = _validate_pwd(body.pwd, required=True)
    if body.waitRoom is not None:
        room.wait_room = body.waitRoom
    if body.title is not None:
        await im_chat.rename(room)
    room.updated_at = utcnow()
    from meeting_ms.infrastructure.im_notifications import room_changed
    await room_changed(session, room, "settings")
    await session.commit()
    snapshot = await room_snapshot(session, room, _host.id)
    await manager.send_room_state(room.id, snapshot)
    return snapshot


@router.post("/{room_id}/end")
async def end_room(
    room_id: str, ctx: AuthContext = Depends(require_client), session: AsyncSession = Depends(get_session)
) -> dict:
    room = await session.get(LiveRoom, room_id, with_for_update=True)
    if room is None:
        raise api_error(404, "会议不存在")
    if room.status == "ended":
        # Response loss must not create another Meeting/Job, or disclose the
        # host's private meeting ID to another member replaying this request.
        if room.host_user_id != ctx.user_id:
            raise api_error(403, "仅主持人可执行该操作", code="host_required")
        job_id = (await session.execute(select(Job.id).where(
            Job.meeting_id == room.meeting_id, Job.kind == "room_recording")
            .order_by(Job.created_at.desc()).limit(1))).scalar_one_or_none()
        return {"meetingId": room.meeting_id, "jobId": job_id}
    me = (
        await session.execute(
            select(RoomParticipant).where(RoomParticipant.room_id == room_id, RoomParticipant.user_id == ctx.user_id)
        )
    ).scalar_one_or_none()
    if me is None or me.state != "joined":
        raise api_error(403, "你不在会议中", code="not_joined")
    if not me.is_host:
        raise api_error(403, "仅主持人可执行该操作", code="host_required")
    return await finalize_room(session, room)


async def finalize_room(session: AsyncSession, room: LiveRoom) -> dict:
    """Caller holds the room row lock; manual and timeout endings share one transaction."""
    await im_chat.close(room)
    now = utcnow()
    meeting = Meeting(id=new_meeting_id(), user_id=room.host_user_id, title=room.title,
                      created_at=now, updated_at=now)
    session.add(meeting)
    # room.meeting_id 是普通字符串赋值，UOW 无法推断依赖顺序——先落 meetings 再改 live_rooms。
    await session.flush()
    room.status = "ended"
    room.recording_active = False
    room.ended_at = now
    room.meeting_id = meeting.id
    if room.scheduled_meeting_id:
        sched = await session.get(ScheduledMeeting, room.scheduled_meeting_id)
        if sched is not None:
            sched.meeting_id = meeting.id
            sched.updated_at = now
    job = None
    has_audio = await session.scalar(select(RoomRecordingChunk.id).where(RoomRecordingChunk.room_id == room.id).limit(1))
    if room.recording_epoch or has_audio:
        job = Job(id="job-" + uuid4().hex, user_id=room.host_user_id, kind="room_recording",
                  status="queued", progress=0, meeting_id=meeting.id, params={"room_id": room.id},
                  message="正在处理会议录音", created_at=now, updated_at=now)
        session.add(job)
    from meeting_ms.infrastructure.im_notifications import meeting_event
    await meeting_event(session, room.id, meeting, "meeting_ended", f"ended:{room.id}")
    await session.commit()
    from meeting_ms.jobs.runner import job_runner
    if job:
        job_runner.submit(job.id)
    await manager.broadcast(room.id, _envelope("room_ended", {"meetingId": meeting.id}))
    await manager.close_room(room.id)
    await rtc_client.close(room.id)
    return {"meetingId": meeting.id, "jobId": job.id if job else None}


# ----------------------------------------------------------------- waiting room


class ParticipantRef(BaseModel):
    participantId: str


@router.post("/{room_id}/admit", status_code=204)
async def admit_participant(
    room_id: str,
    body: ParticipantRef,
    ctx: AuthContext = Depends(require_client),
    session: AsyncSession = Depends(get_session),
) -> Response:
    room, _host = await require_host(session, ctx, room_id)
    target = await session.get(RoomParticipant, body.participantId)
    if target is None or target.room_id != room.id or target.state != "waiting":
        raise api_error(404, "该成员不在等候室")
    target.state = "joined"
    session.add(RoomRecordingSpeaker(participant_id=target.id, room_id=room.id, user_id=target.user_id, name=target.name))
    target.joined_at = utcnow()
    target.updated_at = utcnow()
    await prepare_joined_chat(session, room, target)
    await session.commit()
    await manager.broadcast_participant(room.id, "participant_joined", participant_dict(target))
    await manager.send_to_participant(
        room.id, target.id, _envelope("waiting_resolved", {"participantId": target.id, "admitted": True})
    )
    return Response(status_code=204)


@router.post("/{room_id}/deny", status_code=204)
async def deny_participant(
    room_id: str,
    body: ParticipantRef,
    ctx: AuthContext = Depends(require_client),
    session: AsyncSession = Depends(get_session),
) -> Response:
    room, _host = await require_host(session, ctx, room_id)
    target = await session.get(RoomParticipant, body.participantId)
    if target is None or target.room_id != room.id or target.state != "waiting":
        raise api_error(404, "该成员不在等候室")
    await session.delete(target)
    await session.commit()
    await rtc_client.remove(room.id, target.user_id)
    await manager.send_to_participant(
        room.id, target.id, _envelope("waiting_resolved", {"participantId": target.id, "admitted": False})
    )
    await close_participant(room.id, target.id)
    await broadcast_state(session, room)
    return Response(status_code=204)


# ----------------------------------------------------------------- self / host controls


class SelfPatch(BaseModel):
    micOn: bool | None = None
    camOn: bool | None = None
    handRaised: bool | None = None
    screenSharing: bool | None = None


@router.post("/{room_id}/participants/me")
async def update_self(
    room_id: str,
    body: SelfPatch,
    ctx: AuthContext = Depends(require_client),
    session: AsyncSession = Depends(get_session),
) -> dict:
    await session.execute(select(LiveRoom).where(LiveRoom.id == room_id).with_for_update())
    room, me = await require_room_participant(session, ctx, room_id)
    if body.handRaised is True and me.is_host:
        raise api_error(422, "主持人无需举手", code="host_cannot_raise_hand")
    if body.micOn is True and me.muted_by_host:
        raise api_error(403, "主持人已开启静音", code="muted_by_host")
    cleared: list[RoomParticipant] = []
    if body.screenSharing is True and not me.screen_sharing:
        # Compatibility for existing clients; new clients use the versioned start endpoint.
        cleared = list((await session.execute(select(RoomParticipant).where(
            RoomParticipant.room_id == room.id, RoomParticipant.screen_sharing.is_(True),
            RoomParticipant.id != me.id))).scalars().all())
        for other in cleared:
            other.screen_sharing = False
            other.screen_share_id = None
            other.updated_at = utcnow()
        me.screen_share_id = str(uuid4())
    for field, column in (("micOn", "mic_on"), ("camOn", "cam_on"), ("handRaised", "hand_raised"),
                          ("screenSharing", "screen_sharing")):
        value = getattr(body, field)
        if value is not None:
            setattr(me, column, value)
    if body.screenSharing is False:
        me.screen_share_id = None
    me.updated_at = utcnow()
    await session.commit()
    for other in cleared:
        await manager.broadcast_participant(room.id, "participant_updated", participant_dict(other))
    await manager.broadcast_participant(room.id, "participant_updated", participant_dict(me))
    return participant_dict(me, me.id)


class MuteIn(BaseModel):
    muted: bool


@router.post("/{room_id}/participants/{participant_id}/mute", status_code=204)
async def mute_participant(
    room_id: str,
    participant_id: str,
    body: MuteIn,
    ctx: AuthContext = Depends(require_client),
    session: AsyncSession = Depends(get_session),
) -> Response:
    room, _host = await require_host(session, ctx, room_id)
    target = await session.get(RoomParticipant, participant_id)
    if target is None or target.room_id != room.id:
        raise api_error(404, "成员不存在")
    if body.muted:
        target.mic_on = False
        target.muted_by_host = True
    else:
        target.muted_by_host = False
    target.updated_at = utcnow()
    await session.commit()
    await manager.broadcast_participant(room.id, "participant_updated", participant_dict(target))
    return Response(status_code=204)


@router.post("/{room_id}/participants/{participant_id}/approve-hand", status_code=204)
async def approve_hand(
    room_id: str,
    participant_id: str,
    ctx: AuthContext = Depends(require_client),
    session: AsyncSession = Depends(get_session),
) -> Response:
    await session.execute(select(LiveRoom).where(LiveRoom.id == room_id).with_for_update())
    room, _host = await require_host(session, ctx, room_id)
    target = await session.get(RoomParticipant, participant_id)
    if target is None or target.room_id != room.id:
        raise api_error(404, "成员不存在")
    target.hand_raised = False
    # Grant permission to speak without starting the member's microphone.
    target.muted_by_host = False
    target.updated_at = utcnow()
    await session.commit()
    await manager.broadcast_participant(room.id, "participant_updated", participant_dict(target))
    return Response(status_code=204)


@router.post("/{room_id}/participants/{participant_id}/remove", status_code=204)
async def remove_participant(
    room_id: str,
    participant_id: str,
    ctx: AuthContext = Depends(require_client),
    session: AsyncSession = Depends(get_session),
) -> Response:
    await session.execute(select(LiveRoom).where(LiveRoom.id == room_id).with_for_update())
    room, _host = await require_host(session, ctx, room_id)
    target = await session.get(RoomParticipant, participant_id)
    if target is None or target.room_id != room.id:
        raise api_error(404, "成员不存在")
    if target.is_host:
        raise api_error(422, "不能移除主持人")
    await im_chat.remove(room, target.user_id)
    was_joined = target.state == "joined"
    await session.delete(target)
    await session.commit()
    await rtc_client.remove(room.id, target.user_id)
    if was_joined:
        await manager.broadcast(room.id, _envelope("participant_left", {"participantId": target.id}))
    else:
        await broadcast_state(session, room)
    await close_participant(room.id, target.id)
    return Response(status_code=204)


@router.post("/{room_id}/participants/{participant_id}/transfer-host", status_code=204)
async def transfer_host(
    room_id: str,
    participant_id: str,
    ctx: AuthContext = Depends(require_client),
    session: AsyncSession = Depends(get_session),
) -> Response:
    await session.execute(select(LiveRoom).where(LiveRoom.id == room_id).with_for_update())
    room, host = await require_host(session, ctx, room_id)
    target = await session.get(RoomParticipant, participant_id)
    if target is None or target.room_id != room.id or target.state != "joined":
        raise api_error(404, "成员不存在")
    if target.user_id is None:
        raise api_error(422, "来宾不能成为主持人")
    if target.id == host.id:
        raise api_error(422, "该成员已是主持人")
    host.is_host = False
    target.is_host = True
    target.hand_raised = False
    target.muted_by_host = False
    room.host_participant_id = target.id
    room.host_user_id = target.user_id
    room.updated_at = utcnow()
    from meeting_ms.infrastructure.im_notifications import room_changed
    await room_changed(session, room, "host")
    await session.commit()
    await manager.broadcast_participant(room.id, "participant_updated", participant_dict(host))
    await manager.broadcast_participant(room.id, "participant_updated", participant_dict(target))
    await broadcast_state(session, room)
    return Response(status_code=204)


@router.post("/{room_id}/mute-all", status_code=204)
async def mute_all(
    room_id: str, ctx: AuthContext = Depends(require_client), session: AsyncSession = Depends(get_session)
) -> Response:
    room, host = await require_host(session, ctx, room_id)
    targets = (
        await session.execute(
            select(RoomParticipant).where(
                RoomParticipant.room_id == room.id,
                RoomParticipant.state == "joined",
                RoomParticipant.id != host.id,
            )
        )
    ).scalars().all()
    now = utcnow()
    for target in targets:
        target.mic_on = False
        target.muted_by_host = True
        target.updated_at = now
    await session.commit()
    for target in targets:
        await manager.broadcast_participant(room.id, "participant_updated", participant_dict(target))
    return Response(status_code=204)


# ----------------------------------------------------------------- IM chat binding


@router.post("/{room_id}/chat-session")
async def chat_session(
    room_id: str, ctx: AuthContext = Depends(require_client), session: AsyncSession = Depends(get_session)
) -> dict:
    await session.execute(select(LiveRoom).where(LiveRoom.id == room_id).with_for_update())
    room, participant = await require_room_participant(session, ctx, room_id)
    return await im_chat.session_for(session, room, participant)
