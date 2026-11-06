"""Room signaling WS tests: ConnectionManager unit tests + in-process ASGI websocket integration."""
from __future__ import annotations

import asyncio
import json

import httpx

from meeting_ms.api.v1.rooms_ws import router as rooms_ws_router  # noqa: F401 — route must be registered
from meeting_ms.infrastructure.room_events import ConnectionManager
from meeting_ms.main import app
from meeting_ms.tests.conftest import user_headers
from meeting_ms.tests.test_rooms import ALICE, BOB, CAROL, make_room, room_with_member  # noqa: F401


# ----------------------------------------------------------------- ConnectionManager unit


class StubWebSocket:
    def __init__(self) -> None:
        self.sent: list[dict] = []
        self.closed: int | None = None

    async def send_json(self, event: dict) -> None:
        self.sent.append(event)

    async def close(self, code: int = 1000, reason: str = "") -> None:
        self.closed = code


def _events(ws: StubWebSocket, event_type: str) -> list[dict]:
    return [e for e in ws.sent if e.get("type") == event_type]


async def test_manager_broadcast_participant_tailors_is_self() -> None:
    m = ConnectionManager()
    ws_a, ws_b = StubWebSocket(), StubWebSocket()
    m.register("r1", "p-a", ws_a)
    m.register("r1", "p-b", ws_b)
    assert m.connection_count("r1") == 2

    await m.broadcast_participant("r1", "participant_updated", {"id": "p-a", "name": "a", "isSelf": False})
    assert _events(ws_a, "participant_updated")[0]["data"]["participant"]["isSelf"] is True
    assert _events(ws_b, "participant_updated")[0]["data"]["participant"]["isSelf"] is False
    assert set(_events(ws_a, "participant_updated")[0].keys()) == {"type", "ts", "data"}

    conn_a = m._rooms["r1"][0]
    m.unregister("r1", conn_a)
    assert m.connection_count("r1") == 1

    await m.close_room("r1")
    assert m.connection_count("r1") == 0 and ws_b.closed == 1000


async def test_manager_room_state_tailoring() -> None:
    m = ConnectionManager()
    ws_a, ws_b = StubWebSocket(), StubWebSocket()
    m.register("r2", "p-a", ws_a)
    m.register("r2", "p-b", ws_b)

    snapshot = {"id": "r2", "participants": [{"id": "p-a", "isSelf": False}, {"id": "p-b", "isSelf": False}]}
    await m.send_room_state("r2", snapshot)
    state_a = _events(ws_a, "room_state")[0]["data"]["room"]
    state_b = _events(ws_b, "room_state")[0]["data"]["room"]
    assert {p["id"]: p["isSelf"] for p in state_a["participants"]} == {"p-a": True, "p-b": False}
    assert {p["id"]: p["isSelf"] for p in state_b["participants"]} == {"p-a": False, "p-b": True}

    await m.send_to_participant("r2", "p-b", {"type": "waiting_resolved", "ts": "t", "data": {"admitted": True}})
    assert len(_events(ws_a, "waiting_resolved")) == 0 and len(_events(ws_b, "waiting_resolved")) == 1


# ----------------------------------------------------------------- in-process ASGI ws client


class AsgiWebSocket:
    """Minimal websocket client driving the app's ASGI interface directly (no lifespan involvement)."""

    def __init__(self, path: str, headers: dict[str, str] | None = None) -> None:
        self.scope = {
            "type": "websocket",
            "asgi": {"version": "3.0", "spec_version": "2.3"},
            "http_version": "1.1",
            "scheme": "ws",
            "path": path,
            "raw_path": path.encode(),
            "query_string": b"",
            "root_path": "",
            "headers": [(k.lower().encode(), v.encode()) for k, v in (headers or {}).items()],
            "client": ("testclient", 50000),
            "server": ("testserver", 80),
        }
        self.incoming: asyncio.Queue = asyncio.Queue()
        self.from_app: list[str] = []
        self.accepted = False
        self.close_code: int | None = None
        self.close_reason = ""
        self._task: asyncio.Task | None = None

    async def _receive(self) -> dict:
        return await self.incoming.get()

    async def _send(self, message: dict) -> None:
        t = message.get("type")
        if t == "websocket.accept":
            self.accepted = True
        elif t == "websocket.send":
            self.from_app.append(message.get("text"))
        elif t == "websocket.close":
            self.close_code = message.get("code")
            self.close_reason = message.get("reason", "")

    async def connect(self, timeout: float = 5.0) -> None:
        self._task = asyncio.create_task(app(self.scope, self._receive, self._send))
        await self.incoming.put({"type": "websocket.connect"})
        deadline = asyncio.get_event_loop().time() + timeout
        while not self.accepted and self.close_code is None:
            if asyncio.get_event_loop().time() > deadline:
                raise TimeoutError("websocket handshake did not settle")
            await asyncio.sleep(0.01)

    def events(self) -> list[dict]:
        return [json.loads(m) for m in self.from_app if m]

    async def wait_event(self, event_type: str, timeout: float = 5.0) -> dict:
        deadline = asyncio.get_event_loop().time() + timeout
        while True:
            for event in self.events():
                if event.get("type") == event_type:
                    return event
            if asyncio.get_event_loop().time() > deadline:
                raise TimeoutError(f"no {event_type} within {timeout}s")
            await asyncio.sleep(0.02)

    async def disconnect(self) -> None:
        await self.incoming.put({"type": "websocket.disconnect", "code": 1000})
        if self._task is not None:
            await asyncio.wait_for(self._task, timeout=5.0)


# ----------------------------------------------------------------- endpoint integration


async def test_ws_rejects_unauthenticated_and_non_members(client: httpx.AsyncClient) -> None:
    ws = AsgiWebSocket("/api/v1/rooms/room-x/ws")
    await ws.connect()
    assert ws.accepted and ws.close_code == 4401
    await ws.disconnect()

    ws = AsgiWebSocket("/api/v1/rooms/room-x/ws", user_headers())
    await ws.connect()
    assert ws.close_code == 4403  # room does not exist
    await ws.disconnect()

    room = await make_room(client)
    ws = AsgiWebSocket(f"/api/v1/rooms/{room['id']}/ws", user_headers(user_id="u-9", name="mallory"))
    await ws.connect()
    assert ws.close_code == 4403  # not a member
    await ws.disconnect()


async def test_ws_member_receives_room_state_and_broadcasts(client: httpx.AsyncClient) -> None:
    room, bob, carol = await room_with_member(client)
    ws = AsgiWebSocket(f"/api/v1/rooms/{room['id']}/ws", BOB())
    await ws.connect()
    assert ws.accepted and ws.close_code is None

    # 1) full snapshot on connect, isSelf tailored to bob
    state = await ws.wait_event("room_state")
    room_view = state["data"]["room"]
    assert room_view["id"] == room["id"]
    assert {p["id"]: p["isSelf"] for p in room_view["participants"]}[bob["id"]] is True
    assert room_view["participants"][0]["name"] == "alice"  # host first

    # 3) carol raises her hand via REST → participant_updated arrives
    await client.post(f"/api/v1/rooms/{room['id']}/participants/me",
                      json={"handRaised": True}, headers=CAROL())
    updated = await ws.wait_event("participant_updated")
    assert updated["data"]["participant"]["handRaised"] is True

    # 4) host ends the room → room_ended then the socket is closed by the server
    r = await client.post(f"/api/v1/rooms/{room['id']}/end", headers=ALICE())
    assert r.status_code == 200
    ended = await ws.wait_event("room_ended")
    assert ended["data"]["meetingId"].startswith("meeting-")
    deadline = asyncio.get_event_loop().time() + 5.0
    while ws.close_code is None and asyncio.get_event_loop().time() < deadline:
        await asyncio.sleep(0.02)
    assert ws.close_code == 1000
    await ws.disconnect()


async def test_approved_guest_receives_unlocked_microphone_without_opening_it(client: httpx.AsyncClient) -> None:
    room, bob, _carol = await room_with_member(client)
    base = f"/api/v1/rooms/{room['id']}"
    await client.post(f"{base}/mute-all", headers=ALICE())
    await client.post(f"{base}/participants/me", json={"handRaised": True}, headers=BOB())
    guest = AsgiWebSocket(f"{base}/ws", BOB())
    host = AsgiWebSocket(f"{base}/ws", ALICE())
    await guest.connect()
    await host.connect()
    try:
        await guest.wait_event("room_state")
        await host.wait_event("room_state")
        assert (await client.post(f"{base}/participants/{bob['id']}/approve-hand", headers=ALICE())).status_code == 204
        for socket, is_self in ((guest, True), (host, False)):
            participant = (await socket.wait_event("participant_updated"))["data"]["participant"]
            assert participant["id"] == bob["id"] and participant["isSelf"] is is_self
            assert participant["handRaised"] is False
            assert participant["mutedByHost"] is False
            assert participant["micOn"] is False
    finally:
        await guest.disconnect()
        await host.disconnect()


async def test_ws_second_connection_same_user_and_reconnect_snapshot(client: httpx.AsyncClient) -> None:
    room, bob, _carol = await room_with_member(client)
    ws1 = AsgiWebSocket(f"/api/v1/rooms/{room['id']}/ws", BOB())
    await ws1.connect()
    await ws1.wait_event("room_state")

    # reconnect (e.g. after a drop): a second socket receives the full snapshot again
    ws2 = AsgiWebSocket(f"/api/v1/rooms/{room['id']}/ws", BOB())
    await ws2.connect()
    state = await ws2.wait_event("room_state")
    assert state["data"]["room"]["id"] == room["id"]

    # broadcasts now reach both sockets
    await client.post(f"/api/v1/rooms/{room['id']}/participants/me", json={"handRaised": True}, headers=CAROL())
    assert (await ws1.wait_event("participant_updated"))["data"]["participant"]["handRaised"] is True
    assert (await ws2.wait_event("participant_updated"))["data"]["participant"]["handRaised"] is True
    await ws1.disconnect()
    await ws2.disconnect()
