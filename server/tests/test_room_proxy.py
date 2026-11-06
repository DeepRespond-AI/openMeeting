"""WS auth/handshake regressions. Pure tests; no shared database fixtures."""
from gateway_ms.api.gateway import _ws_headers, _ws_request, _ws_pipe


def test_websocket_scope_is_copied_and_adapted_for_auth():
    scope = {"type": "websocket", "headers": [], "path": "/api/v1/rooms/room-test/ws", "query_string": b""}
    request = _ws_request(scope, "fixture-session")
    assert request.headers["authorization"] == "Bearer fixture-session"
    assert scope["type"] == "websocket"
    assert scope["headers"] == []


def test_bearer_header_takes_precedence_over_query_token():
    scope = {"type": "websocket", "headers": [(b"authorization", b"Bearer header-session")]}
    assert _ws_request(scope, "query-session").headers["authorization"] == "Bearer header-session"


def test_downstream_gets_identity_without_duplicate_handshake_headers():
    headers = {"Host": "incoming", "Connection": "Upgrade", "Upgrade": "websocket",
               "Sec-WebSocket-Key": "old-key", "sec-websocket-version": "13",
               "X-User-ID": "fixture-user", "X-Internal-Token": "fixture-internal"}
    assert _ws_headers(headers) == {"X-User-ID": "fixture-user", "X-Internal-Token": "fixture-internal"}


async def test_downstream_authorization_close_reaches_native_client():
    import asyncio
    from unittest.mock import AsyncMock

    class Downstream:
        close_code = 4403

        def __aiter__(self):
            return self

        async def __anext__(self):
            raise StopAsyncIteration

    client = AsyncMock()
    client.receive_text.side_effect = lambda: asyncio.sleep(3600)
    # Use a coroutine directly so cancellation of the pending receive is exercised.
    async def receive():
        await asyncio.Event().wait()
    client.receive_text.side_effect = receive
    await _ws_pipe(client, Downstream())
    client.close.assert_awaited_once_with(code=4403)
