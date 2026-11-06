"""stt_ms test fixtures. Requires a PostgreSQL instance, e.g.

    docker run -d --rm -p 55432:5432 -e POSTGRES_PASSWORD=openmeeting -e POSTGRES_USER=openmeeting \
        -e POSTGRES_DB=openmeeting_test postgres:16
"""
from __future__ import annotations

import os
import tempfile
from collections.abc import AsyncIterator

import numpy as np
import pytest

os.environ["OPENMEETING_ENV"] = "test"
os.environ["OPENMEETING_EGRESS_PROXY_URL"] = ""  # Explicit direct transport for isolated model contracts only.
os.environ["OPENMEETING_SECRET_KEY"] = "test-secret-key"
os.environ.setdefault("OPENMEETING_DATABASE_URL", "postgresql+asyncpg://openmeeting:openmeeting@localhost:55432/openmeeting_test")
os.environ["OPENMEETING_DATA_DIR"] = os.path.join(tempfile.mkdtemp(prefix="stt-ms-test-"), "data")

import httpx  # noqa: E402
from asgi_lifespan import LifespanManager  # noqa: E402
from sqlalchemy import text  # noqa: E402

from stt_ms.config import get_settings  # noqa: E402
from stt_ms.db.session import session_factory  # noqa: E402
from stt_ms.main import app  # noqa: E402
from stt_ms.stt import model_store  # noqa: E402
from stt_ms.stt.base import ModelSpec, SttEngine, SttResult  # noqa: E402
from stt_ms.stt.registry import stt_registry  # noqa: E402

TABLES = ["system_settings", "stt_models"]

get_settings().database_url = os.environ.get("OPENMEETING_TEST_DATABASE_URL", "postgresql+asyncpg://openmeeting:openmeeting@localhost:55432/openmeeting_stt")

FAKE_SPEC = ModelSpec("fake:test", "fake", "test", "Fake", 0, "multilingual", None, None, remote=True)


class FakeEngine(SttEngine):
    """Returns deterministic text; silence (all zeros) yields an empty transcript."""

    engine_name = "fake"

    def __init__(self) -> None:
        self.calls = 0

    def load(self, spec: ModelSpec, path) -> None:  # noqa: ANN001
        pass

    def transcribe(self, audio: np.ndarray, language: str | None) -> SttResult:
        self.calls += 1
        if not np.any(audio):
            return SttResult(text="")
        return SttResult(text=f"segment {audio.size / 16000:.2f}s lang={language or 'auto'}", confidence=0.9)


@pytest.fixture(scope="session")
async def app_ready() -> AsyncIterator[None]:
    async def fake_factory(spec: ModelSpec) -> SttEngine:
        return FakeEngine()

    stt_registry.register_engine("fake", fake_factory)
    model_store.register_spec(FAKE_SPEC)
    async with LifespanManager(app, startup_timeout=60):
        yield


@pytest.fixture(autouse=True)
async def clean_db(app_ready: None) -> AsyncIterator[None]:
    async with session_factory()() as session:
        await session.execute(text(f"TRUNCATE {', '.join(TABLES)} RESTART IDENTITY CASCADE"))
        await session.commit()
    stt_registry.clear()
    yield


@pytest.fixture
async def client(app_ready: None) -> AsyncIterator[httpx.AsyncClient]:
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://testserver") as c:
        yield c


@pytest.fixture
async def fake_stt() -> FakeEngine:
    engine = FakeEngine()
    stt_registry.install(engine, FAKE_SPEC)
    return engine
