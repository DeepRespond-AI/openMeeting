"""meeting_ms test fixtures. Requires a PostgreSQL instance, e.g.

    docker run -d --rm -p 55432:5432 -e POSTGRES_PASSWORD=openmeeting -e POSTGRES_USER=openmeeting \
        -e POSTGRES_DB=openmeeting_test postgres:16
"""
from __future__ import annotations

import os
import tempfile
from collections.abc import AsyncIterator

import numpy as np
import pytest

# 测试绝不读取本地 .env 里的真实配置。
os.environ["OPENMEETING_ENV"] = "test"
os.environ["OPENMEETING_STORAGE_PROVIDER"] = "auto"
os.environ["OPENMEETING_RECORDING_CHUNK_MAINTENANCE_INTERVAL_SECONDS"] = "86400"
os.environ["OPENMEETING_EGRESS_PROXY_URL"] = ""  # Explicit direct transport for isolated respx contracts only.
os.environ["OPENMEETING_SECRET_KEY"] = "test-secret-key"
os.environ.setdefault("OPENMEETING_DATABASE_URL", "postgresql+asyncpg://openmeeting:openmeeting@localhost:55432/openmeeting_test")
os.environ["OPENMEETING_DATA_DIR"] = os.path.join(tempfile.mkdtemp(prefix="meeting-ms-test-"), "data")
for _var in ("OPENMEETING_OSS_ENDPOINT", "OPENMEETING_OSS_REGION", "OPENMEETING_OSS_BUCKET",
             "OPENMEETING_OSS_ACCESS_KEY_ID", "OPENMEETING_OSS_ACCESS_KEY_SECRET", "OPENMEETING_OSS_PREFIX"):
    os.environ[_var] = ""

import httpx  # noqa: E402
from asgi_lifespan import LifespanManager  # noqa: E402
from sqlalchemy import text  # noqa: E402

from meeting_ms.config import get_settings  # noqa: E402
from meeting_ms.db.models import SummaryTemplateRow  # noqa: E402
from meeting_ms.db.session import session_factory  # noqa: E402
from meeting_ms.infrastructure.stt_client import SttClient, SttNotReady, SttResult  # noqa: E402
from meeting_ms.main import app  # noqa: E402
from meeting_ms.summary.templates import seed_rows  # noqa: E402

TABLES = [
    "im_notifications",
    "room_chat_messages", "room_participants", "live_rooms", "scheduled_meetings",
    "summary_templates", "request_logs", "jobs", "system_settings", "llm_providers", "meeting_notes",
    "transcript_chunks", "summary_processes", "transcripts", "meetings",
]

# 进程内多 ms 共存时环境变量只有一个值；启动前改写本 ms 的配置对象。
get_settings().database_url = os.environ.get("OPENMEETING_TEST_DATABASE_URL", "postgresql+asyncpg://openmeeting:openmeeting@localhost:55432/openmeeting_meeting")


def user_headers(user_id: str = "u-1", name: str = "alice", session_id: str = "s-1") -> dict:
    """Gateway-injected identity headers (the meeting_ms deps trust these)."""
    return {
        "X-User-ID": user_id,
        "X-User-Name": name,
        "X-Session-ID": session_id,
    }


@pytest.fixture(scope="session")
async def app_ready() -> AsyncIterator[None]:
    async with LifespanManager(app, startup_timeout=60):
        yield


@pytest.fixture(autouse=True)
async def clean_db(app_ready: None) -> AsyncIterator[None]:
    async with session_factory()() as session:
        await session.execute(text(f"TRUNCATE {', '.join(TABLES)} RESTART IDENTITY CASCADE"))
        session.add_all(SummaryTemplateRow(**row) for row in seed_rows())
        await session.commit()
    yield


@pytest.fixture
async def client(app_ready: None) -> AsyncIterator[httpx.AsyncClient]:
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://testserver") as c:
        yield c


@pytest.fixture
def admin(client: httpx.AsyncClient) -> httpx.AsyncClient:
    """Admin routes no longer log in locally — the gateway authorizes; tests call them directly."""
    return client


@pytest.fixture(autouse=True)
def chunk_object_store(monkeypatch):
    """Explicit object-store fixture for room PCM only; other audio tests keep their own storage."""
    from meeting_ms.storage import recording_chunks
    from meeting_ms.tests.test_storage import FakeOssStore

    # Object keys are not filesystem paths in production; keep the fake root short on Windows.
    directory = tempfile.TemporaryDirectory(prefix="pcm-fixture-")
    from pathlib import Path
    store = FakeOssStore(Path(directory.name))

    async def get_store(backend=None):
        return store

    monkeypatch.setattr(recording_chunks, "require_store", get_store)
    yield store
    directory.cleanup()


class _FakeStt:
    """Monkeypatched SttClient recording calls; silence yields empty transcripts."""

    def __init__(self) -> None:
        self.calls: list[tuple[bytes, str | None]] = []
        self.ready = True

    def text_for(self, data: bytes, language: str | None) -> SttResult:
        if not any(np.frombuffer(data, dtype="<i2")):
            return SttResult(text="")
        return SttResult(text=f"segment {len(data) / 32000:.2f}s lang={language or 'auto'}", confidence=0.9)


@pytest.fixture
def fake_stt(monkeypatch: pytest.MonkeyPatch) -> _FakeStt:
    fake = _FakeStt()

    async def transcribe_pcm(self: SttClient, data: bytes, language: str | None) -> SttResult:
        if not fake.ready:
            raise SttNotReady("语音识别模型未就绪")
        fake.calls.append((data, language))
        return fake.text_for(data, language)

    async def ready(self: SttClient) -> bool:
        return fake.ready

    async def status(self: SttClient) -> dict:
        return {"device": "cpu", "engine": "fake", "model": "fake", "ready": fake.ready, "error": None, "models": []}

    monkeypatch.setattr(SttClient, "transcribe_pcm", transcribe_pcm)
    monkeypatch.setattr(SttClient, "ready", ready)
    monkeypatch.setattr(SttClient, "status", status)
    return fake
