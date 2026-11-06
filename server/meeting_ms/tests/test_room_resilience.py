"""Fault tests against the real test DB; platform side effects are explicit substitutes."""
import asyncio
from datetime import timedelta
from uuid import uuid4

from sqlalchemy import func, select, update

from meeting_ms.config import get_settings
from meeting_ms.db.models import Job, LiveRoom, Meeting, RoomConnectionLease, RoomParticipant
from meeting_ms.db.session import session_factory
from meeting_ms.infrastructure import room_presence, rtc_client
from meeting_ms.tests.test_rooms import ALICE, BOB, CAROL, join, make_room, room_with_member
from meeting_ms.tests.test_rooms_ws import AsgiWebSocket
from meeting_ms.tests.test_room_recording import start_recording
from meeting_ms.utils import utcnow


async def age(participant_id, seconds):
    async with session_factory()() as session:
        await session.execute(update(RoomParticipant).where(RoomParticipant.id == participant_id)
            .values(last_seen_at=utcnow()-timedelta(seconds=seconds)))
        await session.commit()


async def test_permission_and_recording_conflict_have_specific_codes(client):
    room, bob, _ = await room_with_member(client)
    response = await client.patch(f"/api/v1/rooms/{room['id']}", headers=BOB(), json={"title": "denied"})
    assert response.status_code == 403 and response.json()["code"] == "host_required"
    await client.post(f"/api/v1/rooms/{room['id']}/participants/{bob['id']}/mute", headers=ALICE(), json={"muted": True})
    response = await client.post(f"/api/v1/rooms/{room['id']}/participants/me", headers=BOB(), json={"micOn": True})
    assert response.status_code == 403 and response.json()["code"] == "muted_by_host"
    await start_recording(client, room)
    from meeting_ms.tests.test_room_recording import chunk
    upload = f"/api/v1/rooms/{room['id']}/recording/chunks"
    data = chunk(bob["id"])
    assert (await client.post(upload, headers=ALICE(), json=data)).status_code == 201
    response = await client.post(upload, headers=ALICE(), json={**data, "startTime": 2})
    assert response.status_code == 409 and response.json()["code"] == "recording_conflict"


async def test_concurrent_end_replays_same_result_only_to_host(client):
    room, _, _ = await room_with_member(client)
    await start_recording(client, room)
    url = f"/api/v1/rooms/{room['id']}/end"
    first, second = await asyncio.gather(client.post(url, headers=ALICE()), client.post(url, headers=ALICE()))
    assert first.status_code == second.status_code == 200
    assert first.json() == second.json()
    denied = await client.post(url, headers=BOB())
    assert denied.status_code == 403 and "meetingId" not in denied.json()
    async with session_factory()() as session:
        assert await session.scalar(select(func.count(Meeting.id))) == 1
        assert await session.scalar(select(func.count(Job.id)).where(Job.kind == "room_recording")) == 1


async def test_member_expiry_respects_grace_and_revokes_platform_access(client, monkeypatch):
    room, bob, _ = await room_with_member(client)
    removed = []

    async def remove(room_id, user_id):
        removed.append((room_id, user_id))

    monkeypatch.setattr(rtc_client, "remove", remove)
    await age(bob["id"], get_settings().room_member_grace_seconds-5)
    await room_presence.sweep_once()
    assert (await client.get(f"/api/v1/rooms/{room['id']}", headers=BOB())).status_code == 200
    await age(bob["id"], get_settings().room_member_grace_seconds+5)
    await room_presence.sweep_once()
    assert removed == [(room["id"], "u-2")]
    assert (await client.get(f"/api/v1/rooms/{room['id']}", headers=BOB())).json()["code"] == "not_joined"
    await room_presence.sweep_once()
    assert len(removed) == 1


async def test_host_has_longer_grace_then_ends_once_with_durable_job(client, monkeypatch):
    room = await make_room(client)
    await start_recording(client, room)
    closed = []

    async def close(room_id):
        closed.append(room_id)

    monkeypatch.setattr(rtc_client, "close", close)
    await age(room["hostId"], get_settings().room_member_grace_seconds+5)
    await room_presence.sweep_once()
    assert (await client.get(f"/api/v1/rooms/{room['id']}", headers=ALICE())).status_code == 200
    await age(room["hostId"], get_settings().room_host_grace_seconds+5)
    await room_presence.sweep_once()
    await room_presence.sweep_once()
    assert closed == [room["id"]]
    response = await client.post(f"/api/v1/rooms/{room['id']}/end", headers=ALICE())
    assert response.status_code == 200 and response.json()["jobId"]
    assert (await client.get(f"/api/v1/meetings/{response.json()['meetingId']}", headers=ALICE())).status_code == 200


async def test_reconnect_renews_activity_and_old_socket_cannot_delete_new_lease(client):
    room, bob, _ = await room_with_member(client)
    first, second = str(uuid4()), str(uuid4())
    assert await room_presence.touch(room["id"], bob["id"], first, register=True)
    await age(bob["id"], 1000)
    assert await room_presence.touch(room["id"], bob["id"], second, register=True)
    await room_presence.disconnect(room["id"], bob["id"], first)
    await room_presence.sweep_once()
    async with session_factory()() as session:
        assert await session.get(RoomParticipant, bob["id"])
        assert await session.get(RoomConnectionLease, second)
        assert await session.get(RoomConnectionLease, first) is None
    assert not await room_presence.touch(room["id"], bob["id"], first)


async def test_removed_seat_cannot_be_recreated_by_stale_connection(client):
    room, bob, _ = await room_with_member(client)
    connection = str(uuid4())
    assert await room_presence.touch(room["id"], bob["id"], connection, register=True)
    await client.post(f"/api/v1/rooms/{room['id']}/participants/{bob['id']}/remove", headers=ALICE())
    assert not await room_presence.touch(room["id"], bob["id"], connection, register=True)
    async with session_factory()() as session:
        assert await session.get(RoomConnectionLease, connection) is None


async def test_expired_previous_host_is_only_removed_after_manual_transfer(client, monkeypatch):
    room, bob, _ = await room_with_member(client)

    async def remove(*args):
        pass

    monkeypatch.setattr(rtc_client, "remove", remove)
    await client.post(f"/api/v1/rooms/{room['id']}/participants/{bob['id']}/transfer-host", headers=ALICE())
    await age(room["hostId"], 1000)
    await room_presence.sweep_once()
    current = (await client.get(f"/api/v1/rooms/{room['id']}", headers=BOB())).json()
    assert current["status"] == "active" and current["hostId"] == bob["id"]
    assert all(p["id"] != room["hostId"] for p in current["participants"])


async def test_waiting_poll_renews_only_own_seat(client):
    room = await make_room(client)
    await client.patch(f"/api/v1/rooms/{room['id']}", headers=ALICE(), json={"waitRoom": True})
    bob = (await join(client, room["code"], BOB())).json()["self"]
    carol = (await join(client, room["code"], CAROL())).json()["self"]
    await age(bob["id"], 1000)
    await age(carol["id"], 1000)
    assert (await client.get(f"/api/v1/rooms?code={room['code']}", headers=BOB())).status_code == 200
    await room_presence.sweep_once()
    async with session_factory()() as session:
        assert await session.get(RoomParticipant, bob["id"])
        assert await session.get(RoomParticipant, carol["id"]) is None


async def test_ws_ping_pong_and_silent_socket_timeout(client, monkeypatch):
    room = await make_room(client)
    monkeypatch.setattr(get_settings(), "room_heartbeat_timeout_seconds", 0.15)
    ws = AsgiWebSocket(f"/api/v1/rooms/{room['id']}/ws", ALICE())
    try:
        await ws.connect()
        await ws.wait_event("room_state")
        await ws.incoming.put({"type": "websocket.receive", "text": '{ "type": "ping" }'})
        await ws.wait_event("pong")
        await asyncio.wait_for(ws._task, 2)
        assert ws.close_code == 4408
        async with session_factory()() as session:
            assert await session.scalar(select(func.count(RoomConnectionLease.id))) == 0
            assert (await session.get(LiveRoom, room["id"])).status == "active"
    finally:
        await ws.disconnect()


async def test_slow_broadcast_does_not_block_other_receivers(monkeypatch):
    from meeting_ms.infrastructure import room_events
    from meeting_ms.tests.test_rooms_ws import StubWebSocket

    class Slow(StubWebSocket):
        async def send_json(self, event):
            await asyncio.Event().wait()

    # Bound timeouts in the test without waiting five real seconds.
    real_wait = asyncio.wait_for

    monkeypatch.setattr(room_events, "_send_timeout", 0.02)
    manager = room_events.ConnectionManager()
    fast = StubWebSocket()
    manager.register("r", "a", Slow())
    manager.register("r", "b", fast)
    # Use an actual configured deadline rather than replacing asyncio globally.
    await real_wait(manager.broadcast("r", {"type": "test"}), 0.5)
    assert fast.sent == [{"type": "test"}]
