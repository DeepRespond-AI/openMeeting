"""Meeting chat uses private IM groups; platform credentials never leave user_ms."""
from __future__ import annotations

import asyncio
import logging
from contextlib import asynccontextmanager
from uuid import NAMESPACE_URL, uuid5

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

from user_ms.infrastructure.im_client import get_client

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/internal/im/meeting-chat", tags=["internal"])
# A service-owned group prevents meeting attendees changing membership in another IM UI.
OWNER = "openmeeting-meetings"


class EnsureIn(BaseModel):
    room_id: str = Field(pattern=r"^room-[A-Za-z0-9-]{1,75}$")
    name: str = Field(min_length=1, max_length=128)
    max_members: int = Field(ge=2, le=501)


class MemberIn(BaseModel):
    username: str = Field(min_length=1, max_length=80)
    name: str = Field(default="", max_length=80)


def unavailable(exc: Exception) -> HTTPException:
    logger.warning("Meeting IM operation failed: type=%s code=%s", type(exc).__name__, getattr(exc, "code", None))
    return HTTPException(503, "会议聊天服务暂不可用，请重试")


@asynccontextmanager
async def platform():
    # Complete before meeting_ms releases its row lock on an internal RPC timeout.
    # In particular, never leave automatic SDK retries running after a failed grant.
    async with asyncio.timeout(10):
        yield (await get_client()).with_options(timeout=3, max_retries=0, max_rate_limited_retries=0)


class NoticeIn(BaseModel):
    event_id: str = Field(min_length=1, max_length=160)
    recipient: str = Field(min_length=1, max_length=80)
    body: dict


@router.post("/notify")
async def notify(body: NoticeIn) -> dict:
    try:
        async with platform() as client:
            await client.users.issue_login_ticket("notice", auto_create=True)
            await client.messages.send(from_="notice", to_user=body.recipient,
                client_msg_id=uuid5(NAMESPACE_URL, "openmeeting-notice:" + body.event_id).hex,
                # Business notices and invalidation hints have no message entry
                # in the meeting UI. Deliver them without unread/push alerts.
                type="custom", body=body.body, exclude_from_unread=True, push={"disabled": True})
            return {"ok": True}
    except Exception as exc:
        raise unavailable(exc) from exc


@router.post("")
async def ensure_group(body: EnsureIn) -> dict:
    try:
        async with platform() as client:
            await client.users.issue_login_ticket(OWNER, auto_create=True)
            groups = client.groups
            # IM generates group IDs and create is not idempotent. Recover by the
            # business attribute after a lost response instead of blindly creating.
            async for group in groups.iter(owner=OWNER, status="active", limit=100):
                if (group.attributes or {}).get("openmeeting_room_id") == body.room_id:
                    return {"group_id": group.group_id}
            result = await groups.create(
                OWNER, type="private", name=body.name, member_invite="disabled",
                max_members=body.max_members, attributes={"openmeeting_room_id": body.room_id},
            )
            return {"group_id": result.group_id}
    except Exception as exc:
        raise unavailable(exc) from exc


@router.post("/{group_id}/members")
async def add_member(group_id: str, body: MemberIn) -> dict:
    try:
        async with platform() as client:
            await client.users.issue_login_ticket(body.username, auto_create=True)
            groups = client.groups
            result = await groups.add_members(group_id, [body.username])
            if len(result.results) != 1 or any(item.status not in ("joined", "already_member") for item in result.results):
                raise RuntimeError("IM rejected meeting membership")
            if body.name:
                await groups.update_member(group_id, body.username, group_nickname=body.name)
            return {"ok": True}
    except Exception as exc:
        raise unavailable(exc) from exc


@router.post("/{group_id}/remove")
async def remove_member(group_id: str, body: MemberIn) -> dict:
    try:
        async with platform() as client:
            result = await client.groups.remove_members(group_id, [body.username])
            if len(result.results) != 1 or any(item.status not in ("removed", "not_member") for item in result.results):
                raise RuntimeError("IM rejected meeting member removal")
            return {"ok": True}
    except Exception as exc:
        raise unavailable(exc) from exc


@router.post("/{group_id}/close")
async def close_group(group_id: str) -> dict:
    try:
        async with platform() as client:
            # A meeting group has the same lifetime as its room. This is
            # idempotent; platform retention is separate from client visibility.
            await client.groups.delete(group_id, reason="Meeting ended")
            return {"ok": True}
    except Exception as exc:
        raise unavailable(exc) from exc


@router.post("/{group_id}/title")
async def update_title(group_id: str, body: EnsureIn) -> dict:
    try:
        async with platform() as client:
            await client.groups.update(group_id, name=body.name)
            return {"ok": True}
    except Exception as exc:
        raise unavailable(exc) from exc
