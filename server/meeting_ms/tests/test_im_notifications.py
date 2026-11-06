from contextlib import asynccontextmanager
from datetime import timedelta
from unittest.mock import AsyncMock
import pytest

import httpx
from sqlalchemy import select

from meeting_ms.db.models import ImNotification
from meeting_ms.db.session import session_factory
from meeting_ms.infrastructure import im_notifications as notices
from meeting_ms.tests.conftest import user_headers
from meeting_ms.utils import utcnow


async def test_transactional_events_and_retry(client, monkeypatch):
    body = {"title": "Review", "startAt": (utcnow() + timedelta(minutes=5)).isoformat(),
            "durationMin": 30, "remind": True, "pwdEnabled": True, "pwd": "1234"}
    created = await client.post("/api/v1/scheduled-meetings", json=body, headers=user_headers())
    assert created.status_code == 201
    request = AsyncMock(return_value=httpx.Response(503, request=httpx.Request("POST", "http://im")))

    @asynccontextmanager
    async def fixture(*args, **kwargs):
        yield type("Client", (), {"post": request})()

    monkeypatch.setattr(notices, "client_for", fixture)
    await notices.tick()
    async with session_factory()() as db:
        rows = list((await db.execute(select(ImNotification))).scalars())
        assert len(rows) == 2
        assert all(r.delivered_at is None and r.attempts == 1 for r in rows)
        assert all("pwd" not in r.body and "1234" not in str(r.body) for r in rows)
        for row in rows:
            row.next_attempt_at = utcnow()
        await db.commit()
    request.return_value = httpx.Response(200, json={"ok": True}, request=httpx.Request("POST", "http://im"))
    await notices.tick()
    async with session_factory()() as db:
        rows = list((await db.execute(select(ImNotification))).scalars())
        assert len(rows) == 2 and all(r.delivered_at and r.body == {} for r in rows)
    # A delivered reminder is deduplicated even though its content was purged.
    await notices.tick()
    assert request.await_count == 4


async def test_cancelled_reminder_is_not_delivered(client, monkeypatch):
    body = {"startAt": (utcnow() + timedelta(minutes=5)).isoformat(), "durationMin": 30, "remind": True}
    row = (await client.post("/api/v1/scheduled-meetings", json=body, headers=user_headers())).json()
    async with session_factory()() as db:
        await notices.enqueue(db, "stale", "u-1", {"event": "reminder", "scheduledId": row["id"], "startAt": row["startAt"]})
        await db.commit()
    assert (await client.delete(f'/api/v1/scheduled-meetings/{row["id"]}', headers=user_headers())).status_code == 204
    request = AsyncMock(return_value=httpx.Response(200, request=httpx.Request("POST", "http://im")))

    @asynccontextmanager
    async def fixture(*args, **kwargs):
        yield type("Client", (), {"post": request})()

    monkeypatch.setattr(notices, "client_for", fixture)
    await notices.tick()
    assert all(call.kwargs["json"]["body"]["event"] != "reminder" for call in request.await_args_list)
    assert {call.kwargs["json"]["body"]["event"] for call in request.await_args_list} == {"scheduled_created", "scheduled_cancelled"}


async def test_room_settings_hint_is_private_and_transactional(client, monkeypatch):
    from meeting_ms.infrastructure import rtc_client
    from meeting_ms.tests.test_rooms import ALICE, BOB, make_room, join
    monkeypatch.setattr(rtc_client, "ensure_channel", AsyncMock(return_value=False))
    monkeypatch.setattr(rtc_client, "media_for", AsyncMock(return_value=rtc_client.PLACEHOLDER))
    room = await make_room(client)
    await join(client, room["code"], BOB())
    response = await client.patch(f'/api/v1/rooms/{room["id"]}', json={"pwdEnabled": True, "pwd": "9876"}, headers=ALICE())
    assert response.status_code == 200
    async with session_factory()() as db:
        rows = list((await db.execute(select(ImNotification))).scalars())
        assert len(rows) == 2
        assert {r.body["reason"] for r in rows} == {"settings"}
        assert all(r.body["roomId"] == room["id"] and "9876" not in str(r.body) for r in rows)
    assert (await client.patch(f'/api/v1/rooms/{room["id"]}', json={"title": "forged"}, headers=BOB())).status_code == 403
    async with session_factory()() as db:
        assert len(list((await db.execute(select(ImNotification))).scalars())) == 2


async def test_processing_result_and_notification_commit_together(client, monkeypatch):
    from meeting_ms.db.models import Meeting
    from meeting_ms.jobs import store
    async with session_factory()() as db:
        db.add(Meeting(id="meeting-notify-test", user_id="u-1", title="Processing notification"))
        await db.commit()
    job = await store.create_job("u-1", "room_recording", "meeting-notify-test")
    await store.update_job(job.id, status="completed")
    await store.update_job(job.id, status="completed")
    async with session_factory()() as db:
        rows = list((await db.execute(select(ImNotification))).scalars())
        assert len(rows) == 1 and rows[0].body["event"] == "processing_completed"
    other = await store.create_job("u-1", "room_recording", "meeting-notify-test")
    monkeypatch.setattr(notices, "enqueue", AsyncMock(side_effect=RuntimeError("DB unavailable")))
    with pytest.raises(RuntimeError):
        await store.update_job(other.id, status="failed")
    assert (await store.get_job(other.id)).status == "queued"
