"""Best-effort RTC orchestration. Business rooms remain usable when media is unavailable."""
from __future__ import annotations

import logging
from uuid import uuid4

from fastapi import HTTPException

from meeting_ms.config import get_settings
from meeting_ms.infrastructure.internal_client import client_for

logger = logging.getLogger(__name__)
PLACEHOLDER = {"transport": "webrtc", "iceServers": [], "token": None}


async def request(path: str, payload: dict) -> dict | None:
    try:
        async with client_for("user", timeout=5) as client:
            response = await client.post("/im/rtc/channels" + path, json=payload)
        if response.is_success:
            return response.json()
        logger.warning("RTC internal operation failed: status=%s", response.status_code)
    except Exception as exc:
        logger.warning("RTC internal operation failed: type=%s", type(exc).__name__)
    return None


async def ensure_channel(room) -> bool:
    return await request("", {"channel_id": room.id, "name": room.title,
                              "max_participants": min(64, max(1, get_settings().room_max_participants))}) is not None


async def media_for(room, user_id: str) -> dict:
    if await ensure_channel(room):
        result = await request(f"/{room.id}/tickets", {"username": user_id})
        if result and result.get("ticket") and result.get("expires_at"):
            return {"transport": "dr-rtc", "channelId": room.id,
                    "ticket": result["ticket"], "expiresAt": result["expires_at"]}
    return {**PLACEHOLDER, "unavailableReason": "rtc_unavailable"}


async def close(room_id: str) -> None:
    await request(f"/{room_id}/close", {"reason": "Meeting ended"})


async def remove(room_id: str, user_id: str) -> None:
    await request(f"/{room_id}/remove", {"username": user_id, "operation_id": uuid4().hex,
                                        "reason": "Room membership revoked"})


async def recover(room_id: str, user_id: str, session_id: str) -> dict:
    """Unlike best-effort teardown, explicit recovery must not hide failures."""
    try:
        async with client_for("user", timeout=8) as client:
            response = await client.post(f"/im/rtc/channels/{room_id}/recover",
                                         json={"username": user_id, "session_id": session_id})
        if response.status_code == 409:
            raise HTTPException(409, "音视频会话已变化或仍在正常参会，请重新检查连接")
        if response.is_success:
            result = response.json()
            if isinstance(result.get("released"), bool):
                return {"released": result["released"]}
    except HTTPException:
        raise
    except Exception as exc:
        logger.warning("RTC recovery failed: type=%s", type(exc).__name__)
    raise HTTPException(503, "暂时无法释放旧音视频会话，请稍后重试")
