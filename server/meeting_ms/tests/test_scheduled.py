"""Scheduled meetings REST tests (design doc §5.1)."""
from __future__ import annotations

from datetime import UTC, datetime, timedelta

import httpx

from meeting_ms.tests.conftest import user_headers


def future_iso(minutes: float = 30) -> str:
    return (datetime.now(UTC) + timedelta(minutes=minutes)).strftime("%Y-%m-%dT%H:%M:%SZ")


def past_iso(minutes: float = 30) -> str:
    return (datetime.now(UTC) - timedelta(minutes=minutes)).strftime("%Y-%m-%dT%H:%M:%SZ")


async def test_create_defaults_and_code(client: httpx.AsyncClient) -> None:
    r = await client.post(
        "/api/v1/scheduled-meetings",
        json={"startAt": future_iso(), "durationMin": 30},
        headers=user_headers(),
    )
    assert r.status_code == 201
    body = r.json()
    assert body["id"].startswith("sched-")
    assert len(body["code"]) == 6 and body["code"].isdigit()
    assert body["title"] == "alice的会议"
    assert body["pwdEnabled"] is False and body["pwd"] is None
    assert body["remind"] is False and body["waitRoom"] is False and body["cancelled"] is False
    assert body["host"] == {"id": "u-1", "name": "alice"}
    assert body["meetingId"] is None


async def test_create_with_pwd(client: httpx.AsyncClient) -> None:
    r = await client.post(
        "/api/v1/scheduled-meetings",
        json={"title": "评审会", "startAt": future_iso(), "durationMin": 90,
              "pwdEnabled": True, "pwd": "1234", "remind": True, "waitRoom": True},
        headers=user_headers(),
    )
    assert r.status_code == 201
    body = r.json()
    assert body["pwdEnabled"] is True and body["pwd"] == "1234"
    assert body["remind"] is True and body["waitRoom"] is True


async def test_create_validation(client: httpx.AsyncClient) -> None:
    base = {"startAt": future_iso(), "durationMin": 30}
    h = user_headers()
    r = await client.post("/api/v1/scheduled-meetings", json={**base, "startAt": past_iso()}, headers=h)
    assert r.status_code == 422 and "早于" in r.json()["detail"]
    r = await client.post("/api/v1/scheduled-meetings", json={**base, "durationMin": 4}, headers=h)
    assert r.status_code == 422
    r = await client.post("/api/v1/scheduled-meetings", json={**base, "durationMin": 721}, headers=h)
    assert r.status_code == 422
    r = await client.post("/api/v1/scheduled-meetings", json={**base, "pwdEnabled": True}, headers=h)
    assert r.status_code == 422
    r = await client.post("/api/v1/scheduled-meetings", json={**base, "pwdEnabled": True, "pwd": "ab"}, headers=h)
    assert r.status_code == 422
    r = await client.post("/api/v1/scheduled-meetings", json={**base, "pwdEnabled": True, "pwd": "12a4"}, headers=h)
    assert r.status_code == 422
    r = await client.post("/api/v1/scheduled-meetings", json={**base, "title": "x" * 51}, headers=h)
    assert r.status_code == 422
    r = await client.post("/api/v1/scheduled-meetings", json={**base, "startAt": "not-a-date"}, headers=h)
    assert r.status_code == 422


async def test_list_range_filters_and_orders(client: httpx.AsyncClient) -> None:
    h = user_headers()
    other = user_headers(user_id="u-2", name="bob")
    now = datetime.now(UTC)
    early = (now + timedelta(minutes=30)).strftime("%Y-%m-%dT%H:%M:%SZ")
    late = (now + timedelta(hours=5)).strftime("%Y-%m-%dT%H:%M:%SZ")
    far = (now + timedelta(days=5)).strftime("%Y-%m-%dT%H:%M:%SZ")
    assert (await client.post("/api/v1/scheduled-meetings", json={"startAt": late, "durationMin": 30}, headers=h)).status_code == 201
    assert (await client.post("/api/v1/scheduled-meetings", json={"startAt": early, "durationMin": 30}, headers=h)).status_code == 201
    assert (await client.post("/api/v1/scheduled-meetings", json={"startAt": far, "durationMin": 30}, headers=h)).status_code == 201
    assert (await client.post("/api/v1/scheduled-meetings", json={"startAt": late, "durationMin": 30}, headers=other)).status_code == 201

    listed = (await client.get(
        f"/api/v1/scheduled-meetings?from={now.strftime('%Y-%m-%dT%H:%M:%SZ')}&to={far}",
        headers=h,
    )).json()
    assert [m["startAt"] for m in listed] == [early, late]  # asc, far excluded (to exclusive), other user excluded

    # The upcoming tab omits the upper bound, so future days are not hidden.
    unbounded = (await client.get("/api/v1/scheduled-meetings", params={"from": now.isoformat()}, headers=h)).json()
    assert [m["startAt"] for m in unbounded] == [early, late, far]


async def test_unbounded_list_includes_distant_future_and_keeps_validation(client: httpx.AsyncClient) -> None:
    h = user_headers()
    now = datetime.now(UTC)
    distant = (now + timedelta(days=800)).isoformat()
    made = await client.post("/api/v1/scheduled-meetings", json={"startAt": distant, "durationMin": 30}, headers=h)
    assert made.status_code == 201
    rows = (await client.get("/api/v1/scheduled-meetings", params={"from": now.isoformat()}, headers=h)).json()
    assert [m["id"] for m in rows] == [made.json()["id"]]
    assert (await client.get("/api/v1/scheduled-meetings", params={"from": "invalid"}, headers=h)).status_code == 422
    assert (await client.get("/api/v1/scheduled-meetings", params={"from": now.isoformat(), "to": "invalid"}, headers=h)).status_code == 422
    assert (await client.get("/api/v1/scheduled-meetings", headers=h)).status_code == 200


async def test_get_and_delete(client: httpx.AsyncClient) -> None:
    h = user_headers()
    other = user_headers(user_id="u-2", name="bob")
    mid = (await client.post("/api/v1/scheduled-meetings", json={"startAt": future_iso(), "durationMin": 30}, headers=h)).json()["id"]

    got = (await client.get(f"/api/v1/scheduled-meetings/{mid}", headers=h)).json()
    assert got["id"] == mid
    assert (await client.get(f"/api/v1/scheduled-meetings/{mid}", headers=other)).status_code == 404

    assert (await client.delete(f"/api/v1/scheduled-meetings/{mid}", headers=h)).status_code == 204
    assert (await client.get(f"/api/v1/scheduled-meetings/{mid}", headers=h)).json()["cancelled"] is True
    assert (await client.delete(f"/api/v1/scheduled-meetings/{mid}", headers=h)).status_code == 204


async def test_unauthenticated_rejected(client: httpx.AsyncClient) -> None:
    r = await client.get("/api/v1/scheduled-meetings?from=2026-01-01T00:00:00Z&to=2026-01-02T00:00:00Z")
    assert r.status_code == 401
