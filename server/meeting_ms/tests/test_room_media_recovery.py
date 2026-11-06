from unittest.mock import AsyncMock

from meeting_ms.infrastructure import rtc_client
from meeting_ms.tests.test_rooms import ALICE, BOB, CAROL, join, make_room, room_with_member


async def test_recovery_uses_authenticated_identity_and_keeps_business_room(client, monkeypatch):
    room, bob, _ = await room_with_member(client)
    recover = AsyncMock(return_value={"released":False})
    monkeypatch.setattr(rtc_client, "recover", recover)
    media = AsyncMock()
    monkeypatch.setattr(rtc_client, "media_for", media)
    url = f"/api/v1/rooms/{room['id']}/media/recover"
    response = await client.post(url, headers=BOB(), json={"sessionId":"stale", "username":"u-1"})
    assert response.json() == {"released":False}
    recover.assert_awaited_once_with(room["id"], "u-2", "stale")
    media.assert_not_awaited()
    snapshot = (await client.get(f"/api/v1/rooms/{room['id']}", headers=BOB())).json()
    assert snapshot["status"] == room["status"]
    assert any(p["id"] == bob["id"] for p in snapshot["participants"])


async def test_outsiders_waiting_removed_and_ended_cannot_request_cleanup(client, monkeypatch):
    room = await make_room(client)
    bob = (await join(client, room["code"], BOB())).json()["self"]
    recover = AsyncMock(return_value={"released":True})
    monkeypatch.setattr(rtc_client, "recover", recover)
    url = f"/api/v1/rooms/{room['id']}/media/recover"
    body = {"sessionId":"stale"}
    assert (await client.post(url, headers=CAROL(), json=body)).status_code == 403
    await client.patch(f"/api/v1/rooms/{room['id']}", headers=ALICE(), json={"waitRoom":True})
    await join(client, room["code"], CAROL())
    assert (await client.post(url, headers=CAROL(), json=body)).status_code == 403
    await client.post(f"/api/v1/rooms/{room['id']}/participants/{bob['id']}/remove", headers=ALICE())
    assert (await client.post(url, headers=BOB(), json=body)).status_code == 403
    await client.post(f"/api/v1/rooms/{room['id']}/end", headers=ALICE())
    assert (await client.post(url, headers=ALICE(), json=body)).status_code == 404
    recover.assert_not_awaited()


async def test_recovery_failure_does_not_issue_ticket(client, monkeypatch):
    from fastapi import HTTPException
    room = await make_room(client)
    monkeypatch.setattr(rtc_client, "recover", AsyncMock(side_effect=HTTPException(503,"Release failed")))
    media = AsyncMock()
    monkeypatch.setattr(rtc_client, "media_for", media)
    response = await client.post(f"/api/v1/rooms/{room['id']}/media/recover", headers=ALICE(), json={"sessionId":"stale"})
    assert response.status_code == 503
    media.assert_not_awaited()
