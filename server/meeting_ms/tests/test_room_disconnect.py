"""Confirmed transport loss must expire quickly without evicting reconnects."""
from datetime import timedelta
from uuid import uuid4

import pytest
from sqlalchemy import select

from meeting_ms.config import get_settings
from meeting_ms.db.models import LiveRoom, RoomParticipant
from meeting_ms.db.session import session_factory
from meeting_ms.infrastructure import room_presence, rtc_client
from meeting_ms.tests.test_meeting_im_chat import platform  # noqa: F401 -- shared explicit IM fixture
from meeting_ms.tests.test_rooms import ALICE, BOB, join, room_with_member
from meeting_ms.tests.test_rooms_ws import AsgiWebSocket
from meeting_ms.utils import utcnow

pytestmark = pytest.mark.usefixtures("platform")


@pytest.fixture
def clock(monkeypatch):
    instant = [utcnow()]
    monkeypatch.setattr(room_presence, "utcnow", lambda: instant[0])
    return instant


@pytest.mark.parametrize("close_code", [1000, 1006], ids=["desktop-close", "mobile-process-loss"])
async def test_confirmed_disconnect_broadcasts_departure_within_short_grace(client, clock, close_code):
    room, bob, _ = await room_with_member(client)
    observer = AsgiWebSocket(f"/api/v1/rooms/{room['id']}/ws", ALICE())
    member = AsgiWebSocket(f"/api/v1/rooms/{room['id']}/ws", BOB())
    try:
        await observer.connect()
        await observer.wait_event("room_state")
        await member.connect()
        await member.wait_event("room_state")
        await member.incoming.put({"type": "websocket.disconnect", "code": close_code})
        await member._task
        async with session_factory()() as session:
            assert (await session.get(RoomParticipant, bob["id"])).disconnected_at == clock[0]
        # Brief transport changes must retain identity and permissions.
        await room_presence.sweep_once()
        assert (await client.get(f"/api/v1/rooms/{room['id']}", headers=BOB())).status_code == 200
        clock[0] += timedelta(seconds=get_settings().room_disconnect_grace_seconds + 0.01)
        await room_presence.sweep_once()
        snapshots = [event["data"]["room"] for event in observer.events() if event["type"] == "room_state"]
        assert all(p["id"] != bob["id"] for p in snapshots[-1]["participants"])
        assert (await client.get(f"/api/v1/rooms/{room['id']}", headers=BOB())).status_code == 403
    finally:
        await member.disconnect()
        await observer.disconnect()


async def test_reconnect_cancels_disconnect_deadline_and_late_old_close_is_safe(client, clock):
    room, bob, _ = await room_with_member(client)
    old, new = str(uuid4()), str(uuid4())
    await room_presence.touch(room["id"], bob["id"], old, register=True)
    await room_presence.disconnect(room["id"], bob["id"], old)
    await room_presence.touch(room["id"], bob["id"], new, register=True)
    # A delayed old connection cleanup cannot re-arm the offline deadline.
    await room_presence.disconnect(room["id"], bob["id"], old)
    clock[0] += timedelta(seconds=get_settings().room_disconnect_grace_seconds + 1)
    await room_presence.sweep_once()
    async with session_factory()() as session:
        member = await session.get(RoomParticipant, bob["id"])
        assert member is not None and member.disconnected_at is None


async def test_rest_rejoin_cancels_disconnect_deadline_before_new_socket(client, clock):
    room, bob, _ = await room_with_member(client)
    connection = str(uuid4())
    await room_presence.touch(room["id"], bob["id"], connection, register=True)
    await room_presence.disconnect(room["id"], bob["id"], connection)
    assert (await join(client, room["code"], BOB())).status_code == 200
    await room_presence.disconnect(room["id"], bob["id"], connection)
    clock[0] += timedelta(seconds=get_settings().room_disconnect_grace_seconds + 1)
    await room_presence.sweep_once()
    assert (await client.get(f"/api/v1/rooms/{room['id']}", headers=BOB())).status_code == 200


async def test_host_disconnect_ends_room_once_after_short_grace(client, clock, monkeypatch):
    room, _, _ = await room_with_member(client)
    closes = []

    async def close(room_id):
        closes.append(room_id)

    monkeypatch.setattr(rtc_client, "close", close)
    connection = str(uuid4())
    await room_presence.touch(room["id"], room["hostId"], connection, register=True)
    await room_presence.disconnect(room["id"], room["hostId"], connection)
    clock[0] += timedelta(seconds=get_settings().room_disconnect_grace_seconds + 0.01)
    await room_presence.sweep_once()
    await room_presence.sweep_once()
    async with session_factory()() as session:
        assert (await session.get(LiveRoom, room["id"])).status == "ended"
    assert closes == [room["id"]]


async def test_platform_failure_preserves_retryable_disconnect_deadline(client, clock, monkeypatch):
    from fastapi import HTTPException
    from meeting_ms.infrastructure import im_chat

    room, bob, _ = await room_with_member(client)
    connection = str(uuid4())
    await room_presence.touch(room["id"], bob["id"], connection, register=True)
    await room_presence.disconnect(room["id"], bob["id"], connection)
    clock[0] += timedelta(seconds=get_settings().room_disconnect_grace_seconds + 1)
    real_remove = im_chat.remove

    async def unavailable(*args):
        raise HTTPException(503, "fixture platform unavailable")

    monkeypatch.setattr(im_chat, "remove", unavailable)
    await room_presence.sweep_once()
    async with session_factory()() as session:
        member = await session.get(RoomParticipant, bob["id"])
        assert member is not None and member.disconnected_at is not None
    monkeypatch.setattr(im_chat, "remove", real_remove)
    await room_presence.sweep_once()
    async with session_factory()() as session:
        assert await session.get(RoomParticipant, bob["id"]) is None
