"""Business membership orchestration only; messages and files live in IM."""
from __future__ import annotations

import logging

from meeting_ms.api.deps import api_error
from meeting_ms.config import get_settings
from meeting_ms.infrastructure.internal_client import client_for

logger = logging.getLogger(__name__)


async def request(path: str, payload: dict | None = None) -> dict:
    try:
        async with client_for("user", timeout=15) as client:
            response = await client.post("/im/meeting-chat" + path, json=payload)
        if response.is_success:
            return response.json()
        logger.warning("Meeting IM request failed: status=%s", response.status_code)
    except Exception as exc:
        logger.warning("Meeting IM request failed: type=%s", type(exc).__name__)
    raise api_error(503, "会议聊天服务暂不可用，请重试", code="im_chat_unavailable")


def settings_for(room) -> dict:
    return {"room_id": room.id, "name": room.title,
            "max_members": min(501, max(2, get_settings().room_max_participants + 1))}


async def session_for(session, room, participant, *, commit: bool = True) -> dict:
    # Caller holds the room row lock throughout platform grant + DB commit.
    # End/remove cannot commit while a new membership is being granted.
    if not room.im_group_id:
        result = await request("", settings_for(room))
        room.im_group_id = result["group_id"]
        # Flush but leave the transaction locked until the grant is complete.
        await session.flush()
    await request(f"/{room.im_group_id}/members", {"username": participant.user_id, "name": participant.name})
    if commit:
        await session.commit()
    return {"transport": "dr-im-group", "groupId": room.im_group_id}


async def remove(room, user_id: str) -> None:
    if room.im_group_id:
        await request(f"/{room.im_group_id}/remove", {"username": user_id})


async def close(room) -> None:
    if room.im_group_id:
        await request(f"/{room.im_group_id}/close")


async def rename(room) -> None:
    if room.im_group_id:
        await request(f"/{room.im_group_id}/title", settings_for(room))
