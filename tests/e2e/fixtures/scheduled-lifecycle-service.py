"""Real meeting_ms + isolated PostgreSQL; explicit identity/IM/RTC/job fixtures.

Never launch this acceptance module as a production entry point.
"""
import os
from pathlib import Path

DB = os.environ["OPENMEETING_SCHEDULED_TEST_DATABASE"]
if DB != "postgresql+asyncpg://openmeeting:openmeeting@localhost:55442/scheduled_lifecycle_e2e":
    raise RuntimeError("Refusing any database outside the owned scheduled-lifecycle test instance")
os.environ.update(OPENMEETING_ENV="test", OPENMEETING_DATABASE_URL=DB, OPENMEETING_SECRET_KEY="scheduled-fixture-only",
                  OPENMEETING_EGRESS_PROXY_URL="", OPENMEETING_INTERNAL_SERVICE_TOKEN="",
                  OPENMEETING_DATA_DIR=str(Path(os.environ["OPENMEETING_SCHEDULED_OUTPUT"]) / "server-data"))
for key in ["ENDPOINT", "REGION", "BUCKET", "ACCESS_KEY_ID", "ACCESS_KEY_SECRET", "PREFIX"]:
    os.environ[f"OPENMEETING_OSS_{key}"] = ""

import asyncio
from fastapi import Request, Response
from fastapi.responses import JSONResponse
from sqlalchemy import select, text
from meeting_ms.main import app
from meeting_ms.db.models import LiveRoom, Meeting, ScheduledMeeting
from meeting_ms.db.session import session_factory
from meeting_ms.infrastructure import im_chat, rtc_client
from meeting_ms.jobs.runner import job_runner
from meeting_ms.api.deps import api_error

flags = {"scheduleError": False, "cancelError": False, "endError": False, "delayMs": 0}

async def chat(session, room, participant, **kwargs):
    return {"transport": "dr-im-group", "groupId": f"explicit-fixture-{room.id}"}

async def close(room):
    if flags["endError"]:
        raise api_error(503, "测试夹具：结束会议暂不可用，请重试")

async def noop(*args, **kwargs):
    return None

async def media(room, user_id):
    return {"transport": "dr-rtc", "channelId": room.id, "ticket": "explicit-sdk-fixture", "expiresAt": "2099-01-01T00:00:00Z"}

im_chat.session_for, im_chat.close, im_chat.remove = chat, close, noop
rtc_client.ensure_channel, rtc_client.close, rtc_client.remove, rtc_client.media_for = noop, noop, noop, media
job_runner.submit = lambda *args: None  # The real Meeting and Job rows are created; models are not run.

class TestIdentity:
    def __init__(self, app): self.inner = app
    async def __call__(self, scope, receive, send):
        if scope["type"] in {"http", "websocket"}:
            headers = dict(scope.get("headers", []))
            actor = headers.get(b"x-test-actor", b"").decode()
            if not actor:
                actor = headers.get(b"authorization", b"").decode().removeprefix("Bearer fixture-")
            if not actor and scope["type"] == "websocket":
                from urllib.parse import parse_qs
                actor = parse_qs(scope.get("query_string", b"").decode()).get("actor", [""])[0]
            if actor in {"host", "member", "outsider"}:
                headers.update({b"x-user-id": f"scheduled-{actor}".encode(), b"x-user-name": actor.encode(),
                                b"x-session-id": f"fixture-{actor}".encode()})
                scope = {**scope, "headers": list(headers.items())}
        await self.inner(scope, receive, send)

app.add_middleware(TestIdentity)

@app.middleware("http")
async def faults(request: Request, call_next):
    path = request.url.path
    if path.startswith("/api/v1/scheduled-meetings") and request.method in {"POST", "PATCH", "DELETE"}:
        if flags["delayMs"]: await asyncio.sleep(flags["delayMs"] / 1000)
        fail = flags["cancelError"] if request.method == "DELETE" else flags["scheduleError"]
        if fail: return JSONResponse({"detail": "测试夹具：预定服务暂不可用，请保留输入后重试"}, status_code=503)
    return await call_next(request)

@app.post("/__control")
async def control(body: dict):
    for key in flags:
        if key in body: flags[key] = body[key]
    return flags

@app.post("/__reset")
async def reset():
    async with session_factory()() as db:
        await db.execute(text("TRUNCATE live_rooms, scheduled_meetings, meetings, jobs, im_notifications CASCADE"))
        await db.commit()
    flags.update(scheduleError=False, cancelError=False, endError=False, delayMs=0)
    return {"reset": True, "isolatedDatabase": True}

@app.get("/__snapshot")
async def snapshot():
    async with session_factory()() as db:
        schedules = (await db.execute(select(ScheduledMeeting))).scalars().all()
        rooms = (await db.execute(select(LiveRoom))).scalars().all()
        meetings = (await db.execute(select(Meeting))).scalars().all()
        return {"schedules": [{"id": x.id, "code": x.code, "title": x.title, "cancelled": x.cancelled, "meetingId": x.meeting_id} for x in schedules],
                "rooms": [{"id": x.id, "code": x.code, "status": x.status, "meetingId": x.meeting_id} for x in rooms],
                "meetings": [{"id": x.id, "title": x.title} for x in meetings]}

if __name__ == '__main__':
    import uvicorn
    uvicorn.run(app, host='127.0.0.1', port=3169)
