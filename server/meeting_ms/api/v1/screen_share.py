"""Authenticated signaling only: screen pixels travel over WebRTC, never through REST."""
from typing import Literal
from uuid import uuid4

from fastapi import APIRouter, Depends, Response
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from meeting_ms.api.deps import AuthContext, api_error, require_client
from meeting_ms.api.v1.rooms import require_room_participant, broadcast_state, _envelope
from meeting_ms.config import get_settings
from meeting_ms.db.models import LiveRoom, RoomParticipant
from meeting_ms.db.session import get_session
from meeting_ms.infrastructure.room_events import manager
from meeting_ms.utils import utcnow

router = APIRouter(prefix="/rooms/{room_id}/screen-share", tags=["screen-share"])


@router.get("")
async def config(room_id: str, response: Response, ctx: AuthContext = Depends(require_client), session: AsyncSession = Depends(get_session)):
    await require_room_participant(session, ctx, room_id)
    response.headers["Cache-Control"] = "no-store"
    return {"iceServers": get_settings().screen_share_ice_servers}


async def locked_member(session: AsyncSession, ctx: AuthContext, room_id: str):
    # Every share claim/signal checks membership AFTER taking the same room lock.
    await session.execute(select(LiveRoom).where(LiveRoom.id == room_id).with_for_update())
    return await require_room_participant(session, ctx, room_id)


@router.post("/start")
async def start(room_id: str, ctx: AuthContext = Depends(require_client), session: AsyncSession = Depends(get_session)):
    room, me = await locked_member(session, ctx, room_id)
    active = (await session.execute(select(RoomParticipant).where(
        RoomParticipant.room_id == room_id, RoomParticipant.screen_sharing.is_(True)))).scalars().all()
    for member in active:
        member.screen_sharing = False
        member.screen_share_id = None
    me.screen_sharing = True
    me.screen_share_id = str(uuid4())
    me.updated_at = utcnow()
    await session.commit()
    await broadcast_state(session, room)
    return {"sessionId": me.screen_share_id}


class Stop(BaseModel):
    sessionId: str = Field(min_length=36, max_length=36)


@router.post("/stop", status_code=204)
async def stop(room_id: str, body: Stop, ctx: AuthContext = Depends(require_client), session: AsyncSession = Depends(get_session)):
    room, me = await locked_member(session, ctx, room_id)
    if me.screen_share_id == body.sessionId:
        me.screen_sharing = False
        me.screen_share_id = None
        await session.commit()
        await broadcast_state(session, room)
    return Response(status_code=204)


class Signal(BaseModel):
    sessionId: str = Field(min_length=36, max_length=36)
    targetId: str = Field(min_length=1, max_length=80)
    kind: Literal["ready", "offer", "answer", "candidate"]
    payload: str = Field(default="", max_length=65536)


@router.post("/signal", status_code=204)
async def signal(room_id: str, body: Signal, ctx: AuthContext = Depends(require_client), session: AsyncSession = Depends(get_session)):
    room, me = await locked_member(session, ctx, room_id)
    owner = (await session.execute(select(RoomParticipant).where(
        RoomParticipant.room_id == room_id, RoomParticipant.state == "joined",
        RoomParticipant.screen_sharing.is_(True), RoomParticipant.screen_share_id == body.sessionId))).scalar_one_or_none()
    target = await session.get(RoomParticipant, body.targetId)
    if owner is None:
        raise api_error(409, "共享会话已结束或已被替换")
    if target is None or target.room_id != room_id or target.state != "joined" or target.id == me.id:
        raise api_error(404, "接收成员不存在")
    if owner.id not in (me.id, target.id):
        raise api_error(403, "信令必须与当前共享者通信")
    if (body.kind == "offer" and me.id != owner.id) or (body.kind in ("answer", "ready") and target.id != owner.id):
        raise api_error(403, "共享信令方向无效")
    # SDP/ICE are transient, targeted, not broadcast or persisted; no client-supplied sender.
    await manager.send_to_participant(room.id, target.id, _envelope("screen_signal", {
        "sessionId": body.sessionId, "senderId": me.id, "kind": body.kind, "payload": body.payload}))
    return Response(status_code=204)
