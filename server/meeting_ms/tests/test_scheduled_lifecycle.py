"""A reservation is a stable entry, while every ended room is an independent record."""
import asyncio
from datetime import timedelta

import httpx
from sqlalchemy import func, select

from meeting_ms.db.models import Job, LiveRoom, Meeting, ScheduledMeeting
from meeting_ms.db.session import session_factory
from meeting_ms.tests.conftest import user_headers
from meeting_ms.utils import utcnow

HOST = user_headers("scheduled-host", "host")
MEMBER = user_headers("scheduled-member", "member")


def values(**changes):
    return {"title": "固定会议号预定", "startAt": (utcnow() + timedelta(days=2)).isoformat(),
            "durationMin": 30, "pwdEnabled": True, "pwd": "1234", **changes}


async def reserve(client):
    r = await client.post("/api/v1/scheduled-meetings", headers=HOST, json=values())
    assert r.status_code == 201, r.text
    return r.json()


async def enter(client, code, headers=HOST):
    r = await client.post("/api/v1/rooms/join", headers=headers, json={"code": code, "pwd": "1234"})
    assert r.status_code == 200, r.text
    return r.json()["room"]


async def test_owner_preview_is_read_only_and_guest_cannot_start(client: httpx.AsyncClient):
    sched = await reserve(client)
    for _ in range(2):
        preview = await client.get("/api/v1/rooms", params={"code": sched["code"]}, headers=HOST)
        assert preview.status_code == 200
        assert preview.json()["status"] == "waiting"
        assert preview.json()["hostUserId"] == "scheduled-host"
        assert preview.json()["recording"]["active"] is False
    for response in [
        await client.get("/api/v1/rooms", params={"code": sched["code"]}, headers=MEMBER),
        await client.post("/api/v1/rooms/join", headers=MEMBER, json={"code": sched["code"]}),
    ]:
        assert response.status_code == 404
        assert response.json()["code"] == "not_started"
        assert response.json()["detail"] == "会议尚未开始，请等待房主进入后重试"
    unknown = f"{(int(sched['code']) + 1) % 1000000:06d}"
    for response in [
        await client.get("/api/v1/rooms", params={"code": unknown}, headers=MEMBER),
        await client.post("/api/v1/rooms/join", headers=MEMBER, json={"code": unknown}),
    ]:
        assert response.status_code == 404 and response.json()["code"] == "not_found"
    async with session_factory()() as db:
        assert await db.scalar(select(func.count()).select_from(LiveRoom)) == 0
    await enter(client, sched["code"])
    assert (await client.get("/api/v1/rooms", params={"code": sched["code"]}, headers=MEMBER)).status_code == 200
    await enter(client, sched["code"], MEMBER)


async def test_concurrent_owner_create_and_join_reuse_one_scene(client: httpx.AsyncClient):
    sched = await reserve(client)
    async def create():
        r = await client.post("/api/v1/rooms", headers=HOST, json={"scheduledMeetingId": sched["id"]})
        assert r.status_code == 201, r.text
        return r.json()["id"]
    async def join():
        return (await enter(client, sched["code"]))["id"]
    ids = await asyncio.gather(create(), create(), join(), create(), join())
    assert len(set(ids)) == 1
    async with session_factory()() as db:
        assert await db.scalar(select(func.count()).select_from(LiveRoom)) == 1
    listed = (await client.get("/api/v1/scheduled-meetings", headers=HOST)).json()
    assert listed[0]["code"] == sched["code"] and listed[0]["activeRoomId"] == ids[0]
    assert (await client.get(f"/api/v1/scheduled-meetings/{sched['id']}", headers=HOST)).json()["activeRoomId"] == ids[0]


async def test_two_scenes_keep_code_and_records_survive_edit_and_cancel(client: httpx.AsyncClient):
    sched = await reserve(client)
    scene_ids, record_ids = [], []
    for _ in range(2):
        room = await enter(client, sched["code"])
        assert room["hostUserId"] == "scheduled-host"
        scene_ids.append(room["id"])
        await enter(client, sched["code"], MEMBER)
        assert (await client.post(f"/api/v1/rooms/{room['id']}/leave", headers=MEMBER)).status_code == 204
        first = await client.post(f"/api/v1/rooms/{room['id']}/end", headers=HOST)
        assert first.status_code == 200, first.text
        replay = await client.post(f"/api/v1/rooms/{room['id']}/end", headers=HOST)
        assert replay.json() == first.json()
        record_ids.append(first.json()["meetingId"])
        still_reserved = (await client.get(f"/api/v1/scheduled-meetings/{sched['id']}", headers=HOST)).json()
        assert still_reserved["code"] == sched["code"] and not still_reserved["cancelled"]
        assert still_reserved["activeRoomId"] is None and still_reserved["meetingId"] == record_ids[-1]
        unstarted = await client.get("/api/v1/rooms", params={"code": sched["code"]}, headers=MEMBER)
        assert unstarted.status_code == 404 and unstarted.json()["code"] == "not_started"
    assert len(set(scene_ids)) == len(set(record_ids)) == 2
    async with session_factory()() as db:
        assert await db.scalar(select(func.count()).select_from(Meeting)) == 2
        assert await db.scalar(select(func.count()).select_from(Job).where(Job.kind == "room_recording")) == 2
    updated = await client.patch(f"/api/v1/scheduled-meetings/{sched['id']}", headers=HOST, json=values(title="再次编辑预定"))
    assert updated.status_code == 200, updated.text
    assert updated.json()["code"] == sched["code"]
    assert (await client.delete(f"/api/v1/scheduled-meetings/{sched['id']}", headers=HOST)).status_code == 204
    assert (await client.delete(f"/api/v1/scheduled-meetings/{sched['id']}", headers=HOST)).status_code == 204
    assert (await client.post("/api/v1/rooms/join", headers=HOST, json={"code": sched["code"]})).status_code == 404
    assert (await client.post("/api/v1/rooms", headers=HOST, json={"scheduledMeetingId": sched["id"]})).status_code == 409
    for record_id in record_ids:
        for headers in [HOST, MEMBER]:
            response = await client.get(f"/api/v1/meetings/{record_id}/metadata", headers=headers)
            assert response.status_code == 200, response.text


async def test_active_scene_blocks_edit_cancel_and_foreign_accounts(client: httpx.AsyncClient):
    sched = await reserve(client)
    await enter(client, sched["code"])
    for method in ["PATCH", "DELETE"]:
        response = await client.request(method, f"/api/v1/scheduled-meetings/{sched['id']}", headers=HOST,
                                        json=values() if method == "PATCH" else None)
        assert response.status_code == 409
        assert "先结束当前场次" in response.json()["detail"]
        foreign = await client.request(method, f"/api/v1/scheduled-meetings/{sched['id']}", headers=MEMBER,
                                       json=values() if method == "PATCH" else None)
        assert foreign.status_code == 404


async def test_past_schedule_stays_manageable_until_cancelled(client: httpx.AsyncClient):
    sched = await reserve(client)
    past = utcnow() - timedelta(days=2)
    async with session_factory()() as db:
        row = await db.get(ScheduledMeeting, sched["id"])
        row.start_at = past
        await db.commit()
    rows = (await client.get("/api/v1/scheduled-meetings", headers=HOST)).json()
    assert [row["id"] for row in rows] == [sched["id"]]
    unchanged_time = await client.patch(f"/api/v1/scheduled-meetings/{sched['id']}", headers=HOST,
                                        json=values(title="保留时间只改标题", startAt=past.isoformat()))
    assert unchanged_time.status_code == 200, unchanged_time.text
    moved_past = await client.patch(f"/api/v1/scheduled-meetings/{sched['id']}", headers=HOST,
                                   json=values(startAt=(past - timedelta(days=1)).isoformat()))
    assert moved_past.status_code == 422
    assert (await client.delete(f"/api/v1/scheduled-meetings/{sched['id']}", headers=HOST)).status_code == 204
