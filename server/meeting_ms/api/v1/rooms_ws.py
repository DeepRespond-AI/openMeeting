"""Room signaling WebSocket (API.md §1.10 / design doc §5.4).

Auth mirrors the REST path: the gateway authenticates the Bearer session and injects
X-User-* / X-Internal-Token headers (see gateway WS proxy). Business commands use REST;
client pings renew a business lease and receive a pong. On connect the client receives a `room_state` snapshot
(the reconnection semantics: events are not buffered or replayed).

The DB session is held only for auth + the initial snapshot; the long-lived receive loop
runs session-free so an open socket can never pin a transaction (which would block
maintenance queries like TRUNCATE).
"""
from __future__ import annotations

import asyncio
import hmac
import json
import logging
from uuid import uuid4

from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from sqlalchemy import select

from meeting_ms.api.v1.rooms import room_snapshot
from meeting_ms.config import get_settings
from meeting_ms.db.models import LiveRoom, RoomParticipant
from meeting_ms.db.session import session_factory
from meeting_ms.infrastructure.room_events import manager, room_state_event
from meeting_ms.infrastructure import room_presence
from meeting_ms.utils import iso_ms, utcnow

logger = logging.getLogger(__name__)
router = APIRouter(tags=["rooms-ws"])


@router.websocket("/api/v1/rooms/{room_id}/ws")
async def room_ws(websocket: WebSocket, room_id: str):
    async def reject(code: int, reason: str) -> None:
        # accept first so the custom close code reaches the client through proxies.
        await websocket.accept()
        await websocket.close(code=code, reason=reason)

    token = get_settings().internal_service_token
    if token and not hmac.compare_digest(websocket.headers.get("x-internal-token", ""), token):
        await reject(4401, "缺少内部服务令牌")
        return
    user_id = websocket.headers.get("x-user-id", "")
    if not user_id:
        await reject(4401, "未登录，请先使用手机号登录")
        return

    try:
        async with session_factory()() as session:
            room = await session.get(LiveRoom, room_id)
            if room is None or room.status == "ended":
                await reject(4403, "会议不存在或已结束")
                return
            participant = (
                await session.execute(
                    select(RoomParticipant).where(
                        RoomParticipant.room_id == room_id,
                        RoomParticipant.user_id == user_id,
                        RoomParticipant.state == "joined",
                    )
                )
            ).scalar_one_or_none()
            if participant is None:
                await reject(4403, "你不在会议中")
                return
            snapshot = await room_snapshot(session, room)
            snapshot = room_state_event(snapshot, participant.id)
    except RuntimeError:  # engine not initialised (startup order) — behave like upstream-down
        await reject(4502, "服务未就绪")
        return

    await websocket.accept()
    connection_id = str(uuid4())
    if not await room_presence.touch(room_id, participant.id, connection_id, register=True):
        await websocket.close(code=4403, reason="会议已结束或成员已离开")
        return
    conn = manager.register(room_id, participant.id, websocket)
    logger.debug("room %s: participant %s connected (%d conns)", room_id, participant.id, manager.connection_count(room_id))
    try:
        # Re-read after registering the lease: an end/remove may have committed
        # between the initial auth and obtaining the room lock.
        async with session_factory()() as session:
            room = await session.get(LiveRoom, room_id)
            snapshot = room_state_event(await room_snapshot(session, room), participant.id)
        await asyncio.wait_for(websocket.send_json(snapshot), timeout=5)
        while True:
            message = await asyncio.wait_for(websocket.receive_text(),
                timeout=get_settings().room_heartbeat_timeout_seconds)
            if not await room_presence.touch(room_id, participant.id, connection_id):
                await websocket.close(code=4403, reason="会议已结束或成员已离开")
                break
            try:
                ping = json.loads(message)
            except (ValueError, TypeError):
                ping = None
            if isinstance(ping, dict) and ping.get("type") == "ping":
                await asyncio.wait_for(websocket.send_json({"type": "pong", "ts": iso_ms(utcnow()), "data": {}}), timeout=5)
    except TimeoutError:
        await websocket.close(code=4408, reason="会议连接心跳超时")
    except WebSocketDisconnect:
        pass
    finally:
        manager.unregister(room_id, conn)
        try:
            await room_presence.disconnect(room_id, participant.id, connection_id)
        except Exception:
            # A dead socket must still be unregistered during DB outages; the
            # persisted lease will expire once the database recovers.
            logger.exception("room lease cleanup failed: room_id=%s participant_id=%s", room_id, participant.id)
        logger.debug("room %s: participant %s disconnected", room_id, participant.id)
