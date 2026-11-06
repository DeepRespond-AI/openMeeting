"""RTC administration stays behind the service token; App credentials stay in user_ms."""
from __future__ import annotations

import logging
import asyncio
from hashlib import sha256

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

from user_ms.infrastructure.im_client import get_client, issue_login_ticket

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/internal/im/rtc/channels", tags=["internal"])
CHANNEL = r"^[A-Za-z0-9][A-Za-z0-9_-]{0,63}$"


class ChannelIn(BaseModel):
    channel_id: str = Field(pattern=CHANNEL)
    name: str = Field(min_length=1, max_length=128)
    max_participants: int = Field(ge=1, le=64)


class UserIn(BaseModel):
    username: str = Field(min_length=1, max_length=80)


class ReasonIn(BaseModel):
    reason: str = Field(min_length=1, max_length=256)


class RemoveIn(UserIn, ReasonIn):
    operation_id: str = Field(pattern=r"^[!-~]{1,64}$")


class RecoverIn(UserIn):
    session_id: str = Field(pattern=r"^[A-Za-z0-9_-]{1,64}$")


async def channels():
    return (await get_client()).channels


def unavailable(exc: Exception, detail: str = "音视频服务暂不可用") -> HTTPException:
    # SDK exception payloads can contain credentials. Log class/code only.
    logger.warning("RTC unavailable: type=%s code=%s", type(exc).__name__, getattr(exc, "code", None))
    return HTTPException(503, detail)


@router.post("")
async def create_channel(body: ChannelIn) -> dict:
    try:
        service = await channels()
        try:
            await service.create(body.channel_id, name=body.name, media="video",
                                 access_mode="ticket", default_role="publisher",
                                 max_participants=body.max_participants)
        except Exception as exc:
            # A room title may have changed since creation; it is not a new channel.
            if getattr(exc, "code", None) != "already_exists":
                raise
            current = (await service.get(body.channel_id)).channel
            if (current.status != "open" or current.media != "video" or current.access_mode != "ticket"
                    or current.default_role != "publisher" or current.max_participants != body.max_participants):
                raise
        return {"ok": True}
    except Exception as exc:
        raise unavailable(exc) from exc


@router.post("/{channel_id}/tickets")
async def issue_ticket(channel_id: str, body: UserIn) -> dict:
    try:
        # Ensure the IM identity exists even when the client has not opened Chats.
        # The login ticket is intentionally discarded; only the RTC ticket is delivered.
        await issue_login_ticket(body.username)
        result = await (await channels()).issue_tickets(
            channel_id, users=[{"username": body.username, "role": "publisher"}], ttl_seconds=120)
        item = result.tickets[0]
        expiry = item.expires_at
        return {"ticket": item.ticket, "expires_at": expiry.isoformat() if hasattr(expiry, "isoformat") else str(expiry)}
    except Exception as exc:
        raise unavailable(exc) from exc


@router.post("/{channel_id}/close")
async def close_channel(channel_id: str, body: ReasonIn) -> dict:
    try:
        await (await channels()).close(channel_id, reason=body.reason)
        return {"ok": True}
    except Exception as exc:
        raise unavailable(exc) from exc


@router.post("/{channel_id}/remove")
async def remove_member(channel_id: str, body: RemoveIn) -> dict:
    try:
        service = await channels()
        results = await asyncio.gather(
            service.revoke_tickets(channel_id, usernames=[body.username], operation_id=body.operation_id, reason=body.reason),
            service.remove_member(channel_id, body.username, operation_id=body.operation_id, reason=body.reason),
            return_exceptions=True)
        for result in results:
            if isinstance(result, Exception):
                raise result
        return {"ok": True}
    except Exception as exc:
        raise unavailable(exc) from exc


async def recovery_sessions(service, channel_id: str) -> list:
    """Read every page: a healthy session may be after the stale one."""
    items, cursor, seen = [], None, set()
    while True:
        page = await service.sessions(channel_id, limit=100, **({"cursor": cursor} if cursor else {}))
        items.extend(page.items)
        cursor = page.next_cursor
        if not cursor:
            return items
        if cursor in seen:
            raise RuntimeError("RTC session pagination did not advance")
        seen.add(cursor)


def recoverable_sessions(items: list, body: RecoverIn) -> list:
    target = next((item for item in items if item.session_id == body.session_id), None)
    if target is not None and target.username != body.username:
        raise HTTPException(409, "旧音视频会话不属于当前账号")
    own = [item for item in items if item.username == body.username and item.status != "left"]
    # remove_member is scoped to a user, not a session. Never request removal
    # when a replacement/healthy session was observed, including on another page.
    if any(item.session_id != body.session_id or item.status != "leaving" for item in own):
        raise HTTPException(409, "音视频会话已变化或仍在正常参会，请重新检查连接")
    return own


@router.post("/{channel_id}/recover")
async def recover_session(channel_id: str, body: RecoverIn) -> dict:
    """Explicit self recovery only; never close the channel or ban the user."""
    try:
        async with asyncio.timeout(6):
            service = await channels()
            own = recoverable_sessions(await recovery_sessions(service, channel_id), body)
            if not own:
                return {"released": True}
            operation_id = sha256(f"recover:{channel_id}:{body.username}:{body.session_id}".encode()).hexdigest()[:32]
            await service.remove_member(channel_id, body.username, operation_id=operation_id,
                                        reason="Recover leaving RTC session")
            remaining = recoverable_sessions(await recovery_sessions(service, channel_id), body)
            return {"released": not remaining}
    except HTTPException:
        raise
    except Exception as exc:
        raise unavailable(exc, "平台未能释放旧音视频会话，请稍后重试") from exc
