"""Isolated real API + PostgreSQL + MinIO fixture. No production data or cloud credentials."""
from __future__ import annotations
import argparse
import asyncio
from contextlib import asynccontextmanager
import json
import os
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "server"))
parser = argparse.ArgumentParser()
parser.add_argument("--port", type=int, default=39362)
parser.add_argument("--pg-port", type=int, default=35461)
parser.add_argument("--storage-port", type=int, default=39361)
parser.add_argument("--out", default=str(ROOT / ".artifacts/direct-upload-20261105"))
args = parser.parse_args()
out = Path(args.out); out.mkdir(parents=True, exist_ok=True)
os.environ.update({"OPENMEETING_ENV": "test", "OPENMEETING_DATA_DIR": str(out / "data"),
    "OPENMEETING_ADMIN_PASSWORD": "direct-upload-e2e-admin", "OPENMEETING_SECRET_KEY": "direct-upload-e2e-secret",
    "OPENMEETING_INTERNAL_SERVICE_TOKEN": "", "OPENMEETING_EGRESS_PROXY_URL": "", "OPENMEETING_IM_ENABLED": "false",
    "OPENMEETING_OSS_DOWNLOAD_DOMAIN": "", "OPENMEETING_STORAGE_PROVIDER": "auto"})
for key in ("SMS_ACCESS_KEY_ID", "SMS_ACCESS_KEY_SECRET", "SMS_SIGN_NAME", "SMS_TEMPLATE_CODE", "OSS_ENDPOINT",
            "OSS_ACCESS_KEY_ID", "OSS_ACCESS_KEY_SECRET", "OSS_BUCKET"):
    os.environ["OPENMEETING_" + key] = ""

import asyncpg
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from minio import Minio
from types import SimpleNamespace
from user_ms.api import router as user_router
from meeting_ms.api import router as meeting_router
from user_ms.config import get_settings as user_settings
from meeting_ms.config import get_settings as meeting_settings
from user_ms.db import session as user_db
from meeting_ms.db import session as meeting_db
from user_ms.storage import oss as user_oss
from meeting_ms.storage import oss as meeting_oss
from meeting_ms.api.v1 import jobs
from service_net.minio_store import MinioStore

USER_DB = f"postgresql+asyncpg://openmeeting:direct-upload-pg@127.0.0.1:{args.pg_port}/direct_user"
MEETING_DB = f"postgresql+asyncpg://openmeeting:direct-upload-pg@127.0.0.1:{args.pg_port}/direct_meeting"
for settings, url in ((user_settings(), USER_DB), (meeting_settings(), MEETING_DB)):
    settings.database_url = url
    settings.internal_service_token = ""
    settings.egress_proxy_url = ""
    settings.secret_key = "direct-upload-e2e-secret"
    settings.env = "test"
user_settings().oss_download_domain = None
user_settings().admin_password = "direct-upload-e2e-admin"

cfg = SimpleNamespace(endpoint=f"http://127.0.0.1:{args.storage_port}",
    public_endpoint=f"http://127.0.0.1:{args.storage_port}", region="us-east-1", bucket="direct-upload-fixture",
    access_key_id="direct-upload-user", access_key_secret="direct-upload-password", prefix="fixture/", provider="minio")
store = MinioStore(cfg, SimpleNamespace(egress_proxy_url="", is_dev=True))
state = {"mode": "normal", "storage": "minio", "requests": [], "submittedJobs": []}

async def get_store(backend=None):
    return None if state["storage"] == "local" else store
user_oss.get_audio_store = meeting_oss.get_audio_store = get_store
async def stt_ready(): pass
jobs._require_stt = stt_ready
jobs.job_runner.submit = lambda job_id: state["submittedJobs"].append(job_id)

@asynccontextmanager
async def lifespan(app):
    conn = await asyncpg.connect(host="127.0.0.1", port=args.pg_port, user="openmeeting",
                                 password="direct-upload-pg", database="postgres")
    for name in ("direct_user", "direct_meeting"):
        if not await conn.fetchval("SELECT 1 FROM pg_database WHERE datname=$1", name):
            await conn.execute(f'CREATE DATABASE "{name}"')
    await conn.close()
    user_db.init_engine(USER_DB); meeting_db.init_engine(MEETING_DB)
    await user_db.run_migrations(USER_DB); await meeting_db.run_migrations(MEETING_DB)
    if not store.client.bucket_exists(cfg.bucket): store.client.make_bucket(cfg.bucket)
    (out / "fixture-ready.json").write_text(json.dumps({"api": args.port, "storage": args.storage_port,
        "database": args.pg_port, "auth": "isolated test admin", "stt": "explicit readiness stub; no ASR run"}))
    print("DIRECT_UPLOAD_FIXTURE_READY", flush=True)
    yield
    (out / "fixture-requests.json").write_text(json.dumps(state, ensure_ascii=False, indent=2))
    await user_db.dispose_engine(); await meeting_db.dispose_engine()

app = FastAPI(lifespan=lifespan)
app.include_router(user_router)
app.include_router(meeting_router)

@app.middleware("http")
async def faults(request: Request, call_next):
    if request.url.path.startswith(("/admin/api", "/api/v1")):
        state["requests"].append({"method": request.method, "path": request.url.path,
                                  "contentLength": int(request.headers.get("content-length", 0))})
    if state["mode"] == "fail-complete" and request.url.path.endswith("/uploads/complete"):
        return JSONResponse({"detail": "夹具：确认失败，文件尚未入库"}, status_code=502)
    response = await call_next(request)
    if state["mode"] == "fail-put" and request.url.path.endswith("/uploads") and response.status_code == 200:
        body = b"".join([chunk async for chunk in response.body_iterator])
        data = json.loads(body)
        if data.get("mode") == "direct":
            data["url"] = f"http://127.0.0.1:{args.port}/__fixture/put-error"
        return JSONResponse(data)
    return response

app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

@app.get("/healthz")
def health(): return {"ok": True, "fixture": True}

@app.get("/__fixture/state")
def fixture_state(): return state

@app.post("/__fixture/state")
async def change_state(request: Request):
    data = await request.json()
    assert data.get("mode", "normal") in {"normal", "fail-put", "fail-complete"}
    assert data.get("storage", "minio") in {"minio", "local"}
    state["mode"] = data.get("mode", "normal"); state["storage"] = data.get("storage", "minio")
    return {"ok": True}

@app.put("/__fixture/put-error")
async def put_error():
    return JSONResponse({"detail": "fixture-storage-outage"}, status_code=503)

@app.post("/__fixture/shutdown")
async def shutdown():
    server.should_exit = True
    return {"ok": True}

if __name__ == "__main__":
    import uvicorn
    server = uvicorn.Server(uvicorn.Config(app, host="127.0.0.1", port=args.port, log_level="warning"))
    server.run()
