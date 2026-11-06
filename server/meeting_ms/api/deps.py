"""Downstream trust: identity comes from gateway-injected headers; direct calls need the internal token."""
from __future__ import annotations

import hmac
from dataclasses import dataclass
from urllib.parse import unquote

from fastapi import HTTPException, Request
from sqlalchemy import exists, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from meeting_ms.config import get_settings
from meeting_ms.db.models import LiveRoom, Meeting, RoomRecordingSpeaker

INTERNAL_TOKEN_HEADER = "x-internal-token"


def require_internal(request: Request) -> None:
    """Reject any request that did not come through the gateway."""
    token = get_settings().internal_service_token
    if not token:
        return  # disabled (local dev); compose always sets it
    given = request.headers.get(INTERNAL_TOKEN_HEADER, "")
    if not given or not hmac.compare_digest(given, token):
        raise HTTPException(401, "缺少内部服务令牌")


def api_error(status_code: int, detail: str, code: str | None = None) -> HTTPException:
    """live-meeting 域错误：可选附带机器可读 code（响应体 {"detail", "code"}，由 main.py 扁平化）。"""
    if code is None:
        code = {401: "unauthorized", 403: "forbidden", 404: "not_found", 409: "conflict",
                422: "invalid_input", 429: "rate_limited", 503: "unavailable"}.get(status_code, "request_failed")
    return HTTPException(status_code, {"detail": detail, "code": code})


@dataclass(frozen=True)
class AuthContext:
    """Identity as resolved by the gateway and injected via X-User-* headers."""

    user_id: str
    user_name: str
    user_phone: str | None
    session_id: str
    token_hash: str = ""


def require_client(request: Request) -> AuthContext:
    """Identity for client endpoints — always present because the gateway authenticated the request."""
    user_id = request.headers.get("x-user-id", "")
    if not user_id:
        raise HTTPException(401, "未登录，请先使用手机号登录")
    return AuthContext(
        user_id=user_id,
        # The gateway percent-encodes the display name (HTTP headers are ASCII-only).
        user_name=unquote(request.headers.get("x-user-name", "")),
        user_phone=request.headers.get("x-user-phone") or None,
        session_id=request.headers.get("x-session-id", ""),
    )


async def owned_meeting(session: AsyncSession, ctx: AuthContext, meeting_id: str) -> Meeting:
    meeting = await session.get(Meeting, meeting_id)
    if meeting is None or meeting.user_id != ctx.user_id:
        raise HTTPException(404, "会议不存在")
    return meeting


def visible_meeting(user_id: str):
    """Attendance survives leave/remove; waiting-only identities never enter this table."""
    attended = exists(select(RoomRecordingSpeaker.participant_id).join(
        LiveRoom, LiveRoom.id == RoomRecordingSpeaker.room_id).where(
        LiveRoom.meeting_id == Meeting.id, RoomRecordingSpeaker.user_id == user_id))
    return or_(Meeting.user_id == user_id, attended)


async def accessible_meeting(session: AsyncSession, ctx: AuthContext, meeting_id: str) -> Meeting:
    meeting = await session.scalar(select(Meeting).where(Meeting.id == meeting_id, visible_meeting(ctx.user_id)))
    if meeting is None:
        raise HTTPException(404, "会议不存在")
    return meeting
