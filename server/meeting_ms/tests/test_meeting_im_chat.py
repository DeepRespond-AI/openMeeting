"""Real business DB/API with an explicit IM service substitute."""
import asyncio
from types import SimpleNamespace
from unittest.mock import AsyncMock

import pytest
from sqlalchemy import func, select

from meeting_ms.api.deps import api_error
from meeting_ms.db.models import LiveRoom, RoomAttachment, RoomChatMessage, RoomParticipant
from meeting_ms.db.session import session_factory
from meeting_ms.infrastructure import im_chat, rtc_client
from meeting_ms.tests.test_rooms import ALICE, BOB, join, make_room, make_scheduled


@pytest.fixture
def platform(monkeypatch):
    state = SimpleNamespace(calls=[], group_count=0, failure=None, entered=None, release=None)

    async def request(path, payload=None):
        state.calls.append((path, payload))
        if state.failure and path.endswith(state.failure):
            raise api_error(503, "IM unavailable", code="im_chat_unavailable")
        if state.entered and path.endswith("/members"):
            state.entered.set()
            await state.release.wait()
        if not path:
            state.group_count += 1
            return {"group_id": f"group-{state.group_count}"}
        return {"ok": True}

    monkeypatch.setattr(im_chat, "request", request)
    monkeypatch.setattr(rtc_client, "ensure_channel", AsyncMock(return_value=False))
    monkeypatch.setattr(rtc_client, "media_for", AsyncMock(return_value=rtc_client.PLACEHOLDER))
    monkeypatch.setattr(rtc_client, "remove", AsyncMock())
    monkeypatch.setattr(rtc_client, "close", AsyncMock())
    return state


def path(room):
    return f"/api/v1/rooms/{room['id']}/chat-session"


async def test_join_grants_chat_before_announcing_the_member_without_opening_chat(client, platform, monkeypatch):
    from meeting_ms.api.v1.rooms import manager
    room = await make_room(client)
    announced = []

    async def announce(*args, **kwargs):
        if args[1] == "participant_joined":
            assert ("/group-1/members", {"username": "u-2", "name": "bob"}) in platform.calls
            announced.append(args[2]["id"])

    monkeypatch.setattr(manager, "broadcast_participant", announce)
    response = await join(client, room["code"], BOB())
    assert response.status_code == 200
    assert announced == [response.json()["self"]["id"]]
    # A repeated join must re-establish the same group, without opening its UI.
    platform.calls.clear()
    assert (await join(client, room["code"], BOB())).status_code == 200
    assert ("/group-1/members", {"username": "u-2", "name": "bob"}) in platform.calls
    assert platform.group_count == 1


async def test_admission_grants_chat_and_reentry_does_not_require_opening_chat(client, platform):
    sched = await make_scheduled(client, waitRoom=True)
    room = await make_room(client, scheduledMeetingId=sched["id"])
    waiting = (await join(client, room["code"], BOB())).json()
    grant = ("/group-1/members", {"username": "u-2", "name": "bob"})
    assert grant not in platform.calls
    admitted = await client.post(f"/api/v1/rooms/{room['id']}/admit",
                                json={"participantId": waiting["self"]["id"]}, headers=ALICE())
    assert admitted.status_code == 204
    assert grant in platform.calls
    assert (await client.post(f"/api/v1/rooms/{room['id']}/leave", headers=BOB())).status_code == 204
    assert platform.calls[-1][0] == "/group-1/remove"
    await client.patch(f"/api/v1/rooms/{room['id']}", json={"waitRoom": False}, headers=ALICE())
    platform.calls.clear()
    rejoined = await join(client, room["code"], BOB())
    assert rejoined.status_code == 200
    assert grant in platform.calls
    assert platform.group_count == 1


async def test_join_chat_outage_keeps_room_recoverable_without_rejoining(client, platform):
    room = await make_room(client)
    platform.failure = "/members"
    response = await join(client, room["code"], BOB())
    assert response.status_code == 200 and response.json()["state"] == "joined"
    assert (await client.post(path(room), headers=BOB())).status_code == 503
    assert (await client.get(f"/api/v1/rooms/{room['id']}", headers=BOB())).status_code == 200
    platform.failure = None
    assert (await client.post(path(room), headers=BOB())).json() == {
        "transport": "dr-im-group", "groupId": "group-1"}
    assert platform.group_count == 1


async def test_joined_users_share_one_private_im_group_without_local_messages(client, platform):
    room = await make_room(client)
    assert (await client.post(path(room), headers=BOB())).status_code == 403
    await join(client, room["code"], BOB())
    first = await client.post(path(room), headers=ALICE())
    second = await client.post(path(room), headers=BOB())
    assert first.json() == second.json() == {"transport": "dr-im-group", "groupId": "group-1"}
    assert (await client.post(path(room), headers=ALICE())).json() == first.json()
    assert platform.group_count == 1
    other = await make_room(client)
    assert (await client.post(path(other), headers=ALICE())).json()["groupId"] == "group-2"
    async with session_factory()() as session:
        assert await session.scalar(select(func.count(RoomChatMessage.id))) == 0
        assert await session.scalar(select(func.count(RoomAttachment.id))) == 0


async def test_waiting_and_denied_users_never_receive_chat_access(client, platform):
    sched = await make_scheduled(client, waitRoom=True)
    room = await make_room(client, scheduledMeetingId=sched["id"])
    prepared = list(platform.calls)
    waiting = (await join(client, room["code"], BOB())).json()
    assert (await client.post(path(room), headers=BOB())).status_code == 403
    assert platform.calls == prepared  # only the host is granted during creation
    await client.post(f"/api/v1/rooms/{room['id']}/admit", json={"participantId": waiting["self"]["id"]}, headers=ALICE())
    assert (await client.post(path(room), headers=BOB())).status_code == 200


async def test_creation_prepares_group_host_and_rtc_before_response(client, platform):
    room = await make_room(client)
    assert platform.group_count == 1
    assert platform.calls[-1] == ("/group-1/members", {"username": "u-1", "name": "alice"})
    rtc_client.ensure_channel.assert_awaited_once()
    async with session_factory()() as session:
        assert (await session.get(LiveRoom, room["id"])).im_group_id == "group-1"


async def test_partial_creation_retries_same_bound_group_without_new_room(client, platform):
    platform.failure = "/members"
    room = await make_room(client)
    async with session_factory()() as session:
        assert (await session.get(LiveRoom, room["id"])).im_group_id == "group-1"
    platform.failure = None
    assert (await client.post(path(room), headers=ALICE())).json()["groupId"] == "group-1"
    assert platform.group_count == 1
    async with session_factory()() as session:
        assert await session.scalar(select(func.count(LiveRoom.id))) == 1


async def test_complete_chat_creation_outage_still_returns_recoverable_room(client, platform):
    from unittest.mock import patch
    async def unavailable(*args, **kwargs):
        raise api_error(503, "IM unavailable", code="im_chat_unavailable")
    with patch.object(im_chat, "request", unavailable):
        room = await make_room(client)
    rtc_client.ensure_channel.assert_awaited_once()
    assert (await client.post(path(room), headers=ALICE())).status_code == 200
    assert platform.group_count == 1


async def test_chat_outage_is_explicit_and_never_falls_back_to_local_chat(client, platform):
    room = await make_room(client)
    platform.failure = ""
    async def fail(*args, **kwargs):
        raise api_error(503, "IM unavailable", code="im_chat_unavailable")
    from unittest.mock import patch
    with patch.object(im_chat, "request", fail):
        response = await client.post(path(room), headers=ALICE())
    assert response.status_code == 503 and response.json()["code"] == "im_chat_unavailable"
    assert (await client.get(f"/api/v1/rooms/{room['id']}", headers=ALICE())).status_code == 200
    assert (await client.post(path(room), headers=ALICE())).status_code == 200


async def test_leave_revokes_im_membership_and_platform_failure_preserves_retry(client, platform):
    room = await make_room(client)
    bob = (await join(client, room["code"], BOB())).json()["self"]
    await client.post(path(room), headers=BOB())
    platform.failure = "/remove"
    url = f"/api/v1/rooms/{room['id']}/leave"
    assert (await client.post(url, headers=BOB())).status_code == 503
    async with session_factory()() as session:
        assert await session.get(RoomParticipant, bob["id"]) is not None
    platform.failure = None
    assert (await client.post(url, headers=BOB())).status_code == 204
    assert platform.calls[-1] == ("/group-1/remove", {"username": "u-2"})
    assert (await client.post(path(room), headers=BOB())).status_code == 403


@pytest.mark.parametrize("ending", [True, False])
async def test_inflight_grant_cannot_outlive_end_or_removal(client, platform, ending):
    room = await make_room(client)
    bob = (await join(client, room["code"], BOB())).json()["self"]
    await client.post(path(room), headers=ALICE())
    platform.entered, platform.release = asyncio.Event(), asyncio.Event()
    grant = asyncio.create_task(client.post(path(room), headers=BOB()))
    await asyncio.wait_for(platform.entered.wait(), 5)
    url = f"/api/v1/rooms/{room['id']}/end" if ending else f"/api/v1/rooms/{room['id']}/participants/{bob['id']}/remove"
    revoke = asyncio.create_task(client.post(url, headers=ALICE()))
    await asyncio.sleep(0.05)
    assert not revoke.done()
    platform.release.set()
    assert (await grant).status_code == 200
    assert (await revoke).status_code == (200 if ending else 204)
    assert platform.calls[-1][0].endswith("/close" if ending else "/remove")
    assert (await client.post(path(room), headers=BOB())).status_code in (403, 404)


async def test_end_preserves_binding_and_rename_updates_im(client, platform):
    room = await make_room(client)
    await client.post(path(room), headers=ALICE())
    assert (await client.patch(f"/api/v1/rooms/{room['id']}", json={"title": "新主题"}, headers=ALICE())).status_code == 200
    assert platform.calls[-1][0] == "/group-1/title" and platform.calls[-1][1]["name"] == "新主题"
    platform.failure = "/close"
    assert (await client.post(f"/api/v1/rooms/{room['id']}/end", headers=ALICE())).status_code == 503
    platform.failure = None
    assert (await client.post(f"/api/v1/rooms/{room['id']}/end", headers=ALICE())).status_code == 200
    async with session_factory()() as session:
        row = await session.get(LiveRoom, room["id"])
        assert row.status == "ended" and row.im_group_id == "group-1"


async def test_expiry_revokes_platform_membership_and_host_timeout_closes_group(client, platform):
    from meeting_ms.infrastructure import room_presence
    from meeting_ms.tests.test_room_resilience import age
    room = await make_room(client)
    bob = (await join(client, room["code"], BOB())).json()["self"]
    await client.post(path(room), headers=BOB())
    await age(bob["id"], 120)
    await room_presence.sweep_once()
    assert platform.calls[-1] == ("/group-1/remove", {"username": "u-2"})
    assert (await client.post(path(room), headers=BOB())).status_code == 403
    await age(room["hostId"], 240)
    await room_presence.sweep_once()
    assert platform.calls[-1][0] == "/group-1/close"
    async with session_factory()() as session:
        assert (await session.get(LiveRoom, room["id"])).status == "ended"
