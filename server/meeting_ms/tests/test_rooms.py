"""Live rooms REST tests (design doc §4/§5.2): create/join/waiting-room/host-controls/chat/end."""
from __future__ import annotations

from datetime import UTC, datetime, timedelta
from urllib.parse import quote

import httpx
import pytest

from meeting_ms.api.v1 import rooms
from meeting_ms.config import get_settings
from meeting_ms.db.session import session_factory
from meeting_ms.tests.conftest import user_headers
from meeting_ms.tests.test_scheduled import future_iso

ALICE = lambda: user_headers(user_id="u-1", name="alice")  # noqa: E731
BOB = lambda: user_headers(user_id="u-2", name="bob")  # noqa: E731
CAROL = lambda: user_headers(user_id="u-3", name="carol")  # noqa: E731


async def make_scheduled(client: httpx.AsyncClient, **overrides) -> dict:
    body = {"startAt": future_iso(), "durationMin": 30, **overrides}
    r = await client.post("/api/v1/scheduled-meetings", json=body, headers=ALICE())
    assert r.status_code == 201
    return r.json()


async def make_room(client: httpx.AsyncClient, **kwargs) -> dict:
    r = await client.post("/api/v1/rooms", json=kwargs, headers=ALICE())
    assert r.status_code == 201
    return r.json()


async def join(client: httpx.AsyncClient, code: str, headers, **overrides) -> httpx.Response:
    body = {"code": code, "micOn": True, "camOn": False, **overrides}
    return await client.post("/api/v1/rooms/join", json=body, headers=headers)


# ----------------------------------------------------------------- create / check


async def test_quick_room(client: httpx.AsyncClient, monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr(rooms, "utcnow", lambda: datetime(2026, 10, 27, 20, 30, 45, tzinfo=UTC))
    room = await make_room(client)
    assert room["id"].startswith("room-")
    assert len(room["code"]) == 6 and room["code"].isdigit()
    assert room["title"] == "alice的快速会议 2026-10-28 04:30:45" and room["status"] == "active"
    assert room["scheduledMeetingId"] is None and room["meetingId"] is None
    assert len(room["participants"]) == 1
    host = room["participants"][0]
    assert host["isHost"] is True and host["isSelf"] is True and host["name"] == "alice"
    assert room["hostId"] == host["id"]
    assert "media" not in room  # media 只出现在 JoinResult，不在房间快照里

    ended = await client.post(f"/api/v1/rooms/{room['id']}/end", headers=ALICE())
    assert ended.status_code == 200
    meeting_id = ended.json()["meetingId"]
    records = (await client.get("/api/v1/meetings", headers=ALICE())).json()
    assert next(record for record in records if record["id"] == meeting_id)["title"] == room["title"]


@pytest.mark.parametrize(("name", "title", "prefix"), [
    ("张三", None, "张三的快速会议"),
    ("  张三  ", " \t ", "张三的快速会议"),
    ("", None, "用户的快速会议"),
    ("张" * 100, None, "张" * rooms.NAME_MAX + "的快速会议"),
    ("张三", "  项目评审  ", None),
])
async def test_quick_room_title_defaults_and_overrides(
    client: httpx.AsyncClient, monkeypatch: pytest.MonkeyPatch, name: str, title: str | None, prefix: str | None,
) -> None:
    monkeypatch.setattr(rooms, "utcnow", lambda: datetime(2026, 10, 27, 8, 9, 5, tzinfo=UTC))
    response = await client.post("/api/v1/rooms", json={"title": title}, headers=user_headers(name=quote(name)))
    assert response.status_code == 201
    assert response.json()["title"] == (f"{prefix} 2026-10-27 16:09:05" if prefix else "项目评审")
    assert len(response.json()["title"]) <= rooms.TITLE_MAX


async def test_room_from_scheduled_inherits(client: httpx.AsyncClient) -> None:
    sched = await make_scheduled(client, title="评审会", pwdEnabled=True, pwd="1234", waitRoom=True)
    room = await make_room(client, scheduledMeetingId=sched["id"])
    assert room["code"] == sched["code"]
    assert room["title"] == "评审会"
    assert room["pwdEnabled"] is True and room["pwdEnabled"] and room["waitRoom"] is True
    assert room["scheduledMeetingId"] == sched["id"]


async def test_room_from_foreign_scheduled_404(client: httpx.AsyncClient) -> None:
    sched = await make_scheduled(client)
    r = await client.post("/api/v1/rooms", json={"scheduledMeetingId": sched["id"]}, headers=BOB())
    assert r.status_code == 404


async def test_room_from_cancelled_scheduled_409(client: httpx.AsyncClient) -> None:
    sched = await make_scheduled(client)
    async with session_factory()() as session:
        from meeting_ms.db.models import ScheduledMeeting

        row = await session.get(ScheduledMeeting, sched["id"])
        row.cancelled = True
        await session.commit()
    r = await client.post("/api/v1/rooms", json={"scheduledMeetingId": sched["id"]}, headers=ALICE())
    assert r.status_code == 409


async def test_check_room_code_states(client: httpx.AsyncClient) -> None:
    room = await make_room(client)
    got = (await client.get(f"/api/v1/rooms?code={room['code']}", headers=BOB())).json()
    assert got["id"] == room["id"]
    assert got["participants"][0]["isSelf"] is False  # bob's view of alice

    ended = room["code"]
    await client.post(f"/api/v1/rooms/{room['id']}/end", headers=ALICE())
    r = await client.get(f"/api/v1/rooms?code={ended}", headers=BOB())
    assert r.status_code == 404 and r.json()["code"] == "ended"

    sched = await make_scheduled(client)  # exists but no room yet
    r = await client.get(f"/api/v1/rooms?code={sched['code']}", headers=BOB())
    assert r.status_code == 404 and r.json()["code"] == "not_started"

    r = await client.get("/api/v1/rooms?code=999999", headers=BOB())
    assert r.status_code == 404 and r.json()["code"] == "not_found"
    r = await client.get("/api/v1/rooms?code=abc123", headers=BOB())
    assert r.status_code == 422


# ----------------------------------------------------------------- join


async def test_join_happy_and_broadcast_state(client: httpx.AsyncClient) -> None:
    room = await make_room(client)
    r = await join(client, room["code"], BOB(), name="Bobby")
    assert r.status_code == 200
    result = r.json()
    assert result["state"] == "joined"
    assert result["self"]["isSelf"] is True and result["self"]["name"] == "Bobby"
    assert result["media"]["transport"] == "webrtc"
    assert any(p["id"] == result["self"]["id"] for p in result["room"]["participants"])


async def test_join_errors(client: httpx.AsyncClient) -> None:
    r = await join(client, "abc123", BOB())
    assert r.status_code == 422
    r = await join(client, "999999", BOB())
    assert r.status_code == 404 and r.json()["code"] == "not_found"

    sched = await make_scheduled(client)
    r = await join(client, sched["code"], BOB())
    assert r.status_code == 404 and r.json()["code"] == "not_started"
    assert "尚未开始" in r.json()["detail"]

    # owner joins → auto-creates the room as host
    r = await join(client, sched["code"], ALICE())
    assert r.status_code == 200
    result = r.json()
    assert result["self"]["isHost"] is True and result["state"] == "joined"
    assert result["room"]["scheduledMeetingId"] == sched["id"]


async def test_join_rejoin_idempotent(client: httpx.AsyncClient) -> None:
    room = await make_room(client)
    first = (await join(client, room["code"], BOB())).json()
    again = (await join(client, room["code"], BOB(), name="Robert")).json()
    assert again["self"]["id"] == first["self"]["id"]  # same participant row
    assert again["self"]["name"] == "Robert"
    assert len(again["room"]["participants"]) == 2


async def test_join_pwd_flow(client: httpx.AsyncClient) -> None:
    sched = await make_scheduled(client, pwdEnabled=True, pwd="1234")
    room = await make_room(client, scheduledMeetingId=sched["id"])
    r = await join(client, room["code"], BOB())
    assert r.status_code == 403 and r.json()["code"] == "wrong_pwd"
    r = await join(client, room["code"], BOB(), pwd="9999")
    assert r.status_code == 403 and r.json()["code"] == "wrong_pwd"
    r = await join(client, room["code"], BOB(), pwd="1234")
    assert r.status_code == 200
    # host re-join never needs the pwd (host_join bypass)
    r = await join(client, room["code"], ALICE())
    assert r.status_code == 200


async def test_join_capacity_full(client: httpx.AsyncClient) -> None:
    settings = get_settings()
    original = settings.room_max_participants
    settings.room_max_participants = 2
    try:
        room = await make_room(client)
        assert (await join(client, room["code"], BOB())).status_code == 200
        r = await join(client, room["code"], CAROL())
        assert r.status_code == 409 and r.json()["code"] == "full"
    finally:
        settings.room_max_participants = original


# ----------------------------------------------------------------- waiting room


async def test_waiting_room_admit_deny(client: httpx.AsyncClient) -> None:
    sched = await make_scheduled(client, waitRoom=True)
    room = await make_room(client, scheduledMeetingId=sched["id"])

    r = await join(client, room["code"], BOB())
    assert r.status_code == 200 and r.json()["state"] == "waiting"
    bob_id = r.json()["self"]["id"]
    # 等待者不在成员列表里（host 在）；出现于等候室列表
    assert all(p["id"] != bob_id for p in r.json()["room"]["participants"])
    assert [w["participantId"] for w in r.json()["room"]["waiting"]] == [bob_id]

    # carol joins and gets denied
    r = await join(client, room["code"], CAROL())
    carol_id = r.json()["self"]["id"]
    assert (await client.post(f"/api/v1/rooms/{room['id']}/deny",
                              json={"participantId": carol_id}, headers=ALICE())).status_code == 204
    r = await client.get(f"/api/v1/rooms/{room['id']}", headers=CAROL())
    assert r.status_code == 403  # removed from the room entirely

    # bob gets admitted
    assert (await client.post(f"/api/v1/rooms/{room['id']}/admit",
                              json={"participantId": bob_id}, headers=ALICE())).status_code == 204
    got = (await client.get(f"/api/v1/rooms/{room['id']}", headers=BOB())).json()
    assert len(got["participants"]) == 2 and got["waiting"] == []

    # admit/deny with a bogus target
    r = await client.post(f"/api/v1/rooms/{room['id']}/admit",
                          json={"participantId": "user-none"}, headers=ALICE())
    assert r.status_code == 404


async def test_waiting_member_cannot_access_room(client: httpx.AsyncClient) -> None:
    sched = await make_scheduled(client, waitRoom=True)
    room = await make_room(client, scheduledMeetingId=sched["id"])
    await join(client, room["code"], BOB())  # waiting
    r = await client.get(f"/api/v1/rooms/{room['id']}", headers=BOB())
    assert r.status_code == 403
    r = await client.post(f"/api/v1/rooms/{room['id']}/chat-session", headers=BOB())
    assert r.status_code == 403


# ----------------------------------------------------------------- self / host controls


async def room_with_member(client: httpx.AsyncClient) -> tuple[dict, dict, dict]:
    room = await make_room(client)
    bob = (await join(client, room["code"], BOB())).json()
    return room, bob["self"], (await join(client, room["code"], CAROL())).json()["self"]


async def test_update_self_and_screen_share_arbitration(client: httpx.AsyncClient) -> None:
    room, bob, carol = await room_with_member(client)
    h_bob, h_carol = BOB(), CAROL()
    r = await client.post(f"/api/v1/rooms/{room['id']}/participants/me",
                          json={"handRaised": True, "screenSharing": True}, headers=h_bob)
    assert r.status_code == 200 and r.json()["handRaised"] is True and r.json()["screenSharing"] is True

    # carol starts sharing → bob is kicked off the screen
    r = await client.post(f"/api/v1/rooms/{room['id']}/participants/me",
                          json={"screenSharing": True}, headers=h_carol)
    assert r.status_code == 200
    got = (await client.get(f"/api/v1/rooms/{room['id']}", headers=ALICE())).json()
    shares = {p["name"]: p["screenSharing"] for p in got["participants"]}
    assert shares == {"alice": False, "bob": False, "carol": True}

    # leaving the screen share is allowed; muted_by_host=False so mic is fine
    r = await client.post(f"/api/v1/rooms/{room['id']}/participants/me",
                          json={"micOn": True, "screenSharing": False}, headers=h_bob)
    assert r.status_code == 200 and r.json()["micOn"] is True


async def test_host_controls_and_mute_enforcement(client: httpx.AsyncClient) -> None:
    room, bob, carol = await room_with_member(client)
    h_alice, h_bob = ALICE(), BOB()

    # non-host rejected on every host endpoint
    for method, path, payload in [
        ("POST", f"/api/v1/rooms/{room['id']}/end", None),
        ("POST", f"/api/v1/rooms/{room['id']}/mute-all", None),
        ("PATCH", f"/api/v1/rooms/{room['id']}", {"title": "x"}),
        ("POST", f"/api/v1/rooms/{room['id']}/participants/{bob['id']}/mute", {"muted": True}),
    ]:
        r = await client.request(method, path, json=payload, headers=h_bob)
        assert r.status_code == 403, path

    # host mutes bob → bob cannot unmute himself
    assert (await client.post(f"/api/v1/rooms/{room['id']}/participants/{bob['id']}/mute",
                              json={"muted": True}, headers=h_alice)).status_code == 204
    r = await client.post(f"/api/v1/rooms/{room['id']}/participants/me",
                          json={"micOn": True}, headers=h_bob)
    assert r.status_code == 403 and "静音" in r.json()["detail"]

    # unmute-by-host restores self-mute rights
    assert (await client.post(f"/api/v1/rooms/{room['id']}/participants/{bob['id']}/mute",
                              json={"muted": False}, headers=h_alice)).status_code == 204
    r = await client.post(f"/api/v1/rooms/{room['id']}/participants/me",
                          json={"micOn": True}, headers=h_bob)
    assert r.status_code == 200 and r.json()["micOn"] is True

    # mute-all hits everyone but the host
    assert (await client.post(f"/api/v1/rooms/{room['id']}/mute-all", headers=h_alice)).status_code == 204
    got = (await client.get(f"/api/v1/rooms/{room['id']}", headers=h_alice)).json()
    flags = {p["name"]: (p["micOn"], p["isHost"]) for p in got["participants"]}
    assert flags["alice"][1] is True
    assert flags["bob"] == (False, False) and flags["carol"] == (False, False)
    assert {p["name"]: p["mutedByHost"] for p in got["participants"]} == {
        "alice": False, "bob": True, "carol": True,
    }

    # Release every host restriction through the existing member endpoint. This
    # grants permission to speak without remotely starting anyone's microphone.
    for member in (bob, carol):
        r = await client.post(f"/api/v1/rooms/{room['id']}/participants/{member['id']}/mute",
                              json={"muted": False}, headers=h_alice)
        assert r.status_code == 204
    got = (await client.get(f"/api/v1/rooms/{room['id']}", headers=h_alice)).json()
    assert all(p["mutedByHost"] is False for p in got["participants"])
    assert all(p["micOn"] is False for p in got["participants"] if not p["isHost"])
    for headers in (h_bob, CAROL()):
        r = await client.post(f"/api/v1/rooms/{room['id']}/participants/me",
                              json={"micOn": True}, headers=headers)
        assert r.status_code == 200 and r.json()["micOn"] is True

    # approve-hand lowers the raised hand
    await client.post(f"/api/v1/rooms/{room['id']}/participants/me", json={"handRaised": True}, headers=h_bob)
    assert (await client.post(f"/api/v1/rooms/{room['id']}/participants/{bob['id']}/approve-hand",
                              headers=h_alice)).status_code == 204
    got = (await client.get(f"/api/v1/rooms/{room['id']}", headers=h_alice)).json()
    assert all(p["handRaised"] is False for p in got["participants"])


async def test_hand_approval_releases_only_the_approved_members_microphone(client: httpx.AsyncClient) -> None:
    room, bob, carol = await room_with_member(client)
    base = f"/api/v1/rooms/{room['id']}"
    assert (await client.post(f"{base}/mute-all", headers=ALICE())).status_code == 204
    assert (await client.post(f"{base}/participants/me", json={"handRaised": True}, headers=BOB())).status_code == 200
    assert (await client.post(f"{base}/participants/me", json={"micOn": True}, headers=BOB())).status_code == 403

    # A guest cannot approve their own request or release the host's restriction.
    assert (await client.post(f"{base}/participants/{bob['id']}/approve-hand", headers=BOB())).status_code == 403
    assert (await client.post(f"{base}/participants/{bob['id']}/approve-hand", headers=ALICE())).status_code == 204
    got = (await client.get(base, headers=BOB())).json()
    approved = next(p for p in got["participants"] if p["id"] == bob["id"])
    other = next(p for p in got["participants"] if p["id"] == carol["id"])
    assert approved["handRaised"] is False
    assert approved["mutedByHost"] is False
    assert approved["micOn"] is False  # Approval grants permission; the guest opens their own mic.
    assert other["mutedByHost"] is True and other["micOn"] is False

    r = await client.post(f"{base}/participants/me", json={"micOn": True}, headers=BOB())
    assert r.status_code == 200 and r.json()["micOn"] is True
    assert (await client.post(f"{base}/participants/me", json={"micOn": True}, headers=CAROL())).status_code == 403
    # A later mute-all still revokes the approved guest's permission.
    await client.post(f"{base}/mute-all", headers=ALICE())
    assert (await client.post(f"{base}/participants/me", json={"micOn": True}, headers=BOB())).status_code == 403


async def test_only_guests_can_raise_hands_including_after_host_transfer(client: httpx.AsyncClient) -> None:
    room, bob, _carol = await room_with_member(client)
    base = f"/api/v1/rooms/{room['id']}"
    r = await client.post(f"{base}/participants/me", json={"handRaised": True}, headers=ALICE())
    assert r.status_code == 422 and r.json()["code"] == "host_cannot_raise_hand"
    await client.post(f"{base}/mute-all", headers=ALICE())
    assert (await client.post(f"{base}/participants/me", json={"handRaised": True}, headers=BOB())).status_code == 200
    assert (await client.post(f"{base}/participants/{bob['id']}/transfer-host", headers=ALICE())).status_code == 204
    got = (await client.get(base, headers=BOB())).json()
    new_host = next(p for p in got["participants"] if p["id"] == bob["id"])
    assert new_host["isHost"] is True and new_host["handRaised"] is False
    assert new_host["mutedByHost"] is False and new_host["micOn"] is False
    assert (await client.post(f"{base}/participants/me", json={"handRaised": True}, headers=BOB())).status_code == 422
    assert (await client.post(f"{base}/participants/me", json={"handRaised": True}, headers=ALICE())).status_code == 200


async def test_remove_and_transfer_host(client: httpx.AsyncClient) -> None:
    room, bob, carol = await room_with_member(client)
    h_alice, h_bob = ALICE(), BOB()

    r = await client.post(f"/api/v1/rooms/{room['id']}/participants/{room['hostId']}/remove", headers=h_alice)
    assert r.status_code == 422  # cannot remove the host

    assert (await client.post(f"/api/v1/rooms/{room['id']}/participants/{bob['id']}/remove",
                              headers=h_alice)).status_code == 204
    assert (await client.get(f"/api/v1/rooms/{room['id']}", headers=h_bob)).status_code == 403

    # transfer to carol, then only carol can end; alice demoted
    assert (await client.post(f"/api/v1/rooms/{room['id']}/participants/{carol['id']}/transfer-host",
                              headers=h_alice)).status_code == 204
    got = (await client.get(f"/api/v1/rooms/{room['id']}", headers=CAROL())).json()
    assert got["hostId"] == carol["id"]
    hosts = [p["name"] for p in got["participants"] if p["isHost"]]
    assert hosts == ["carol"]
    r = await client.post(f"/api/v1/rooms/{room['id']}/end", headers=h_alice)
    assert r.status_code == 403
    r = await client.post(f"/api/v1/rooms/{room['id']}/end", headers=CAROL())
    assert r.status_code == 200


async def test_leave(client: httpx.AsyncClient) -> None:
    room, bob, _carol = await room_with_member(client)
    assert (await client.post(f"/api/v1/rooms/{room['id']}/leave", headers=BOB())).status_code == 204
    got = (await client.get(f"/api/v1/rooms/{room['id']}", headers=ALICE())).json()
    assert [p["name"] for p in got["participants"]] == ["alice", "carol"]
    r = await client.post(f"/api/v1/rooms/{room['id']}/leave", headers=ALICE())
    assert r.status_code == 403  # host must end instead


async def test_patch_room(client: httpx.AsyncClient) -> None:
    room = await make_room(client)
    r = await client.patch(f"/api/v1/rooms/{room['id']}",
                           json={"pwdEnabled": True, "pwd": "4321", "waitRoom": True, "title": "改名"}, headers=ALICE())
    assert r.status_code == 200
    body = r.json()
    assert body["pwdEnabled"] is True and body["waitRoom"] is True and body["title"] == "改名"
    # new joiners now need the pwd
    assert (await join(client, room["code"], BOB())).status_code == 403
    assert (await join(client, room["code"], BOB(), pwd="4321")).status_code == 200
    # invalid pwd rejected
    r = await client.patch(f"/api/v1/rooms/{room['id']}", json={"pwdEnabled": True, "pwd": "ab"}, headers=ALICE())
    assert r.status_code == 422
    # disabling clears the pwd
    r = await client.patch(f"/api/v1/rooms/{room['id']}", json={"pwdEnabled": False}, headers=ALICE())
    assert r.json()["pwdEnabled"] is False


# ----------------------------------------------------------------- chat


async def test_local_chat_and_file_routes_are_retired(client: httpx.AsyncClient) -> None:
    room = await make_room(client)
    path = f"/api/v1/rooms/{room['id']}/chat"
    assert (await client.get(path, headers=ALICE())).status_code == 404
    assert (await client.post(path, headers=ALICE(), json={"text": "legacy"})).status_code == 404
    assert (await client.post(path + "/attachments", headers=ALICE(), files={"file": ("a.txt", b"legacy")})).status_code == 404


# ----------------------------------------------------------------- end → minutes


async def test_end_creates_meeting_and_blocks(client: httpx.AsyncClient) -> None:
    sched = await make_scheduled(client)
    room = await make_room(client, scheduledMeetingId=sched["id"])
    await join(client, room["code"], BOB())

    r = await client.post(f"/api/v1/rooms/{room['id']}/end", headers=ALICE())
    assert r.status_code == 200
    meeting_id = r.json()["meetingId"]
    assert meeting_id.startswith("meeting-")

    # meeting row exists under the host account (§1.3 chain)
    got = (await client.get(f"/api/v1/meetings/{meeting_id}", headers=ALICE())).json()
    assert got["id"] == meeting_id and got["title"] == room["title"]
    # Actual participants share the final record; nonparticipants remain excluded.
    assert (await client.get(f"/api/v1/meetings/{meeting_id}", headers=BOB())).status_code == 200
    assert (await client.get(f"/api/v1/meetings/{meeting_id}", headers=CAROL())).status_code == 404

    # scheduled meeting now points at the minutes
    sched_row = (await client.get(f"/api/v1/scheduled-meetings/{sched['id']}", headers=ALICE())).json()
    assert sched_row["meetingId"] == meeting_id

    # room is over: participant endpoints 404; host retry returns the same result.
    r = await client.get(f"/api/v1/rooms/{room['id']}", headers=BOB())
    assert r.status_code == 404 and r.json()["code"] == "ended"
    r = await client.post(f"/api/v1/rooms/{room['id']}/end", headers=ALICE())
    assert r.status_code == 200 and r.json()["meetingId"] == meeting_id

    # owner joining the same code again auto-creates a fresh room (§3.2 reuse)
    r = await join(client, room["code"], ALICE())
    assert r.status_code == 200
    assert r.json()["room"]["id"] != room["id"]


async def test_nonexistent_room_404(client: httpx.AsyncClient) -> None:
    r = await client.get("/api/v1/rooms/room-none", headers=ALICE())
    assert r.status_code == 404
    r = await client.post("/api/v1/rooms/room-none/end", headers=ALICE())
    assert r.status_code == 404
