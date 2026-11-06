"""Slow upstreams and room sockets must not pin gateway authentication connections."""
from __future__ import annotations

import asyncio
from contextlib import asynccontextmanager
from types import SimpleNamespace

import httpx
from fastapi.responses import JSONResponse
from sqlalchemy import text

from gateway_ms.api import gateway
from gateway_ms.auth.core import ClientIdentity
from gateway_ms.db import session as db


async def database_identity(_request, session):
    # Model a cache miss which leaves a read transaction open after authentication.
    await session.execute(text("SELECT 1"))
    return ClientIdentity(user_id="test-user", user_name="test", user_phone=None,
                          session_id="test-session", token_hash="test-hash", last_used_at=0)


async def test_slow_upstreams_do_not_exhaust_auth_pool(client: httpx.AsyncClient, monkeypatch):
    monkeypatch.setattr(gateway, "require_client_identity", database_identity)
    entered = 0
    all_entered = asyncio.Event()
    release = asyncio.Event()

    async def slow_proxy(*args, **kwargs):
        nonlocal entered
        entered += 1
        if entered == 20:
            all_entered.set()
        await release.wait()
        return JSONResponse({"ok": True})

    monkeypatch.setattr(gateway, "proxy_stream", slow_proxy)
    requests = [asyncio.create_task(client.get("/api/v1/rooms/room-test")) for _ in range(20)]
    try:
        # More stalled requests than the pool's 5 + 10 connection limit must all
        # reach the upstream, and unrelated authentication must remain possible.
        await asyncio.wait_for(all_entered.wait(), timeout=5)
        assert db._engine.pool.checkedout() == 0
        async with db.session_factory()() as session:
            await asyncio.wait_for(session.execute(text("SELECT 1")), timeout=1)
    finally:
        release.set()
        responses = await asyncio.gather(*requests)
    assert all(response.status_code == 200 for response in responses)


async def test_room_websocket_releases_auth_connection_before_handshake(app_ready, monkeypatch):
    monkeypatch.setattr(gateway, "require_client_identity", database_identity)
    checks = []

    @asynccontextmanager
    async def downstream(*args, **kwargs):
        checks.append(db._engine.pool.checkedout())
        yield object()

    async def accept():
        checks.append(db._engine.pool.checkedout())

    async def pipe(*args):
        checks.append(db._engine.pool.checkedout())

    monkeypatch.setattr(gateway, "_ws_open", downstream)
    monkeypatch.setattr(gateway, "_ws_pipe", pipe)
    websocket = SimpleNamespace(
        query_params={}, accept=accept,
        scope={"type": "websocket", "path": "/api/v1/rooms/test/ws", "headers": [],
               "query_string": b"", "client": ("127.0.0.1", 1234)},
    )
    async with db.session_factory()() as session:
        await gateway.rooms_ws_proxy(websocket, "room-test", session)
    assert checks == [0, 0, 0]
