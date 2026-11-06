"""Opt-in isolated dev API using real IM. Never points the DB at business data.

Run from server/: python ../tests/e2e/fixtures/meeting-im-live-server.py --env <existing .env>
Only IM configuration is reused; test identities, DB and storage are separate.
"""
import argparse
import os
import sys
from pathlib import Path
from uuid import uuid4

parser = argparse.ArgumentParser()
parser.add_argument("--env", required=True)
args = parser.parse_args()
sys.path.insert(0, str(Path.cwd()))
from dotenv import dotenv_values

for key, value in dotenv_values(args.env).items():
    if key.startswith("OPENMEETING_IM_") and value is not None:
        os.environ[key] = value
for key in ("HTTP_PROXY", "HTTPS_PROXY", "ALL_PROXY"):
    os.environ.pop(key, None)
os.environ.update(OPENMEETING_ENV="test", OPENMEETING_SECRET_KEY="meeting-im-live-test",
    OPENMEETING_INTERNAL_SERVICE_TOKEN="meeting-im-live-validation-only",
    OPENMEETING_DATABASE_URL="postgresql+asyncpg://openmeeting:openmeeting@127.0.0.1:55439/openmeeting_im_chat_test",
    OPENMEETING_USER_MS_URL="http://127.0.0.1:3147",
    OPENMEETING_DATA_DIR=str(Path.cwd().parent / ".artifacts/meeting-im-integration/live-data"))

from fastapi import Depends
from meeting_ms.main import app
from user_ms.api.deps import require_internal
from user_ms.api import internal_meeting_chat, internal_rtc
from user_ms.infrastructure.im_client import get_client

app.include_router(internal_meeting_chat.router, dependencies=[Depends(require_internal)])
app.include_router(internal_rtc.router, dependencies=[Depends(require_internal)])
managed = {}


@app.post("/test/setup")
async def setup():
    import httpx
    from user_ms.config import get_settings
    users = ["im-validation-" + uuid4().hex[:12] for _ in range(2)]
    sdk = await get_client()
    tickets = [await sdk.users.issue_login_ticket(user, auto_create=True) for user in users]
    headers = {"X-Internal-Token": "meeting-im-live-validation-only", "X-User-ID": users[0], "X-User-Name": "IM-validation", "X-Session-ID": users[0]}
    async with httpx.AsyncClient(base_url="http://127.0.0.1:3147", trust_env=False) as client:
        response = await client.post("/api/v1/rooms", headers=headers, json={"title":"IM validation temporary meeting"})
        response.raise_for_status()
        room = response.json()
        managed[room["id"]] = {"users": users, "groups": []}
        headers["X-User-ID"] = users[1]
        headers["X-Session-ID"] = users[1]
        response = await client.post("/api/v1/rooms/join", headers=headers, json={"code":room["code"],"name":"IM validation member","micOn":False})
        response.raise_for_status()
        groups = []
        for user in users:
            headers.update({"X-User-ID":user,"X-Session-ID":user})
            response = await client.post(f'/api/v1/rooms/{room["id"]}/chat-session', headers=headers)
            response.raise_for_status()
            groups.append(response.json()["groupId"])
            managed[room["id"]]["groups"] = groups.copy()
    settings = get_settings()
    return {"apiUrl": settings.im_base_url, "appKey": f"{settings.im_org_name}#{settings.im_app_name}",
        "users":users,"tickets":[t.ticket for t in tickets],"groups":groups,"room":room}


@app.post("/test/cleanup")
async def cleanup(body: dict):
    import httpx
    sdk = await get_client()
    errors = []
    owned = managed.get(body.get("roomId"))
    if not owned or owned["users"] != body.get("users") or owned["groups"] != body.get("groups"):
        raise ValueError("Cleanup is restricted to resources created by this process")
    # Only IDs created by this validation may be supplied by the runner.
    for user in body.get("users", []):
        if not user.startswith("im-validation-"):
            raise ValueError("Unexpected test identity")
    headers = {"X-Internal-Token":"meeting-im-live-validation-only", "X-User-ID":body["users"][0], "X-Session-ID":body["users"][0]}
    async with httpx.AsyncClient(base_url="http://127.0.0.1:3147", trust_env=False, timeout=30) as client:
        response = await client.post(f'/api/v1/rooms/{body["roomId"]}/end', headers=headers)
        if not response.is_success:
            errors.append(f"room end HTTP {response.status_code}")
    for group in set(body.get("groups", [])):
        try:
            await sdk.groups.delete(group)
        except Exception as exc:
            errors.append("test group cleanup: " + type(exc).__name__)
    for user in body["users"]:
        try:
            await sdk.users.delete(user)
        except Exception as exc:
            errors.append("test user cleanup: " + type(exc).__name__)
    if not errors:
        managed.pop(body["roomId"], None)
    return {"errors":errors}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=3147)
