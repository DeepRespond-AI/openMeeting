"""In-process room signaling connections (Phase 1 = single instance; multi-replica needs Redis pub/sub).

REST handlers call `broadcast*` after commit; the WS endpoint (api/v1/rooms_ws.py) registers/unregisters
connections. Participant events are tailored per receiving connection (`isSelf` depends on the receiver).
"""
from __future__ import annotations

import asyncio
import logging
from dataclasses import dataclass

from fastapi import WebSocket

logger = logging.getLogger(__name__)
_send_timeout = 5.0


@dataclass
class Connection:
    participant_id: str
    websocket: WebSocket


class ConnectionManager:
    def __init__(self) -> None:
        self._rooms: dict[str, list[Connection]] = {}

    # ---------------------------------------------------------------- registry

    def register(self, room_id: str, participant_id: str, websocket: WebSocket) -> Connection:
        conn = Connection(participant_id=participant_id, websocket=websocket)
        self._rooms.setdefault(room_id, []).append(conn)
        return conn

    def unregister(self, room_id: str, conn: Connection) -> None:
        conns = self._rooms.get(room_id)
        if conns and conn in conns:
            conns.remove(conn)
        if conns is not None and not conns:
            self._rooms.pop(room_id, None)

    async def close_room(self, room_id: str) -> None:
        conns = self._rooms.pop(room_id, [])
        for conn in conns:
            await _close(conn.websocket)

    def connection_count(self, room_id: str) -> int:
        return len(self._rooms.get(room_id, []))

    # ---------------------------------------------------------------- sends

    async def broadcast(self, room_id: str, event: dict) -> None:
        """Uniform event to every connection in the room (data already receiver-independent)."""
        conns = list(self._rooms.get(room_id, []))
        if conns:
            await asyncio.gather(*(_safe_send(c.websocket, event) for c in conns))

    async def broadcast_participant(self, room_id: str, event_type: str, participant: dict) -> None:
        """participant_joined/left/updated: `isSelf` is rewritten per receiving connection."""
        conns = list(self._rooms.get(room_id, []))
        if not conns:
            return
        await asyncio.gather(
            *(
                _safe_send(
                    c.websocket,
                    _envelope(event_type, {"participant": {**participant, "isSelf": participant["id"] == c.participant_id}}),
                )
                for c in conns
            )
        )

    async def send_to_participant(self, room_id: str, participant_id: str, event: dict) -> None:
        for conn in list(self._rooms.get(room_id, [])):
            if conn.participant_id == participant_id:
                await _safe_send(conn.websocket, event)

    async def send_room_state(self, room_id: str, snapshot: dict) -> None:
        """room_state with per-connection isSelf (participants carry isSelf relative to each receiver)."""
        conns = list(self._rooms.get(room_id, []))
        if not conns:
            return
        await asyncio.gather(*(_safe_send(c.websocket, _room_state_for(snapshot, c.participant_id)) for c in conns))

    async def send_room_state_to(self, websocket: WebSocket, snapshot: dict, participant_id: str) -> None:
        await _safe_send(websocket, _room_state_for(snapshot, participant_id))


def room_state_event(snapshot: dict, participant_id: str) -> dict:
    """Public helper: room_state envelope with isSelf tailored to one participant."""
    return _room_state_for(snapshot, participant_id)


def _envelope(event_type: str, data: dict) -> dict:
    from meeting_ms.utils import iso_ms, utcnow

    return {"type": event_type, "ts": iso_ms(utcnow()), "data": data}


def _room_state_for(snapshot: dict, participant_id: str) -> dict:
    import copy

    room = copy.deepcopy(snapshot)
    for p in room.get("participants", []):
        p["isSelf"] = p["id"] == participant_id
    return _envelope("room_state", {"room": room})


async def _safe_send(websocket: WebSocket, event: dict) -> None:
    try:
        await asyncio.wait_for(websocket.send_json(event), timeout=_send_timeout)
    except Exception:  # noqa: BLE001 — a dead connection must never break the broadcast
        logger.debug("room ws send failed (dropped connection)")


async def _close(websocket: WebSocket) -> None:
    try:
        await asyncio.wait_for(websocket.close(code=1000), timeout=5)
    except Exception:  # noqa: BLE001
        pass


manager = ConnectionManager()
