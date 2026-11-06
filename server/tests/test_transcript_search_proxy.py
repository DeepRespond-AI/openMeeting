"""Transcript search must reach meeting_ms through the authenticated gateway.

No database fixtures or live accounts: only the session identity boundary is replaced.
The production router and streaming proxy execute against a deterministic downstream.
"""
from unittest.mock import AsyncMock

import httpx
import pytest
from fastapi import FastAPI, HTTPException

from gateway_ms.api import gateway
from gateway_ms.auth.core import ClientIdentity
from gateway_ms.db.session import get_session


@pytest.fixture
def app():
    instance = FastAPI()
    instance.include_router(gateway.router)
    session = AsyncMock()

    async def database_boundary():
        yield session

    instance.dependency_overrides[get_session] = database_boundary
    return instance


@pytest.mark.parametrize("query", ["m", "预算", "100%_完成"])
async def test_search_forwards_query_identity_and_results(app, monkeypatch, query):
    identity = ClientIdentity("search-user", "搜索用户", None, "search-session", "fixture-hash", 0)
    auth = AsyncMock(return_value=identity)
    monkeypatch.setattr(gateway, "require_client_identity", auth)
    received = []
    hits = [{"id": "meeting-1", "title": "Meeting Review", "matchContext": f"match {query}"}]

    def downstream(request):
        received.append(request)
        return httpx.Response(200, json=hits)

    async with httpx.AsyncClient(transport=httpx.MockTransport(downstream)) as upstream:
        app.state.http_client = upstream
        async with httpx.AsyncClient(transport=httpx.ASGITransport(app), base_url="http://gateway") as client:
            response = await client.get("/api/v1/transcripts/search", params={"q": query},
                                        headers={"Authorization": "Bearer fixture", "X-User-ID": "spoofed"})
    assert response.status_code == 200
    assert response.json() == hits
    auth.assert_awaited_once()
    assert len(received) == 1
    assert str(received[0].url).startswith(gateway.base_url_for("meeting"))
    assert received[0].url.path == "/api/v1/transcripts/search"
    assert received[0].url.params["q"] == query
    assert received[0].headers["X-User-ID"] == "search-user"
    assert received[0].headers["X-Session-ID"] == "search-session"


async def test_search_requires_a_session_instead_of_returning_route_404(app):
    async with httpx.AsyncClient(transport=httpx.ASGITransport(app), base_url="http://gateway") as client:
        response = await client.get("/api/v1/transcripts/search", params={"q": "m"})
    assert response.status_code == 401


@pytest.mark.parametrize("status,body", [(200, []), (503, {"detail": "search temporarily unavailable"})])
async def test_search_preserves_empty_and_failure_responses(app, monkeypatch, status, body):
    monkeypatch.setattr(gateway, "require_client_identity", AsyncMock(
        return_value=ClientIdentity("user", "name", None, "session", "hash", 0)))
    async with httpx.AsyncClient(transport=httpx.MockTransport(lambda _: httpx.Response(status, json=body))) as upstream:
        app.state.http_client = upstream
        async with httpx.AsyncClient(transport=httpx.ASGITransport(app), base_url="http://gateway") as client:
            response = await client.get("/api/v1/transcripts/search?q=m")
    assert response.status_code == status
    assert response.json() == body


def test_transcripts_route_keeps_prefix_boundaries():
    assert gateway.resolve_downstream("/api/v1/transcripts/search", gateway.CLIENT_ROUTES) == "meeting"
    with pytest.raises(HTTPException) as error:
        gateway.resolve_downstream("/api/v1/transcripts-other/search", gateway.CLIENT_ROUTES)
    assert error.value.status_code == 404
