"""user_ms test fixtures. Requires a PostgreSQL instance, e.g.

    docker run -d --rm -p 55432:5432 -e POSTGRES_PASSWORD=openmeeting -e POSTGRES_USER=openmeeting \
        -e POSTGRES_DB=openmeeting_test postgres:16
"""
from __future__ import annotations

import os
import tempfile
from collections.abc import AsyncIterator

import pytest

# 测试绝不读取本地 .env 里的真实短信配置（否则会走真实发送而不返回 dev_code）。
os.environ["OPENMEETING_ENV"] = "test"
os.environ["OPENMEETING_STORAGE_PROVIDER"] = "auto"
os.environ["OPENMEETING_EGRESS_PROXY_URL"] = ""  # Explicit direct transport for isolated SDK/respx contracts only.
os.environ["OPENMEETING_IM_ENABLED"] = "false"  # Individual IM tests explicitly enable their fake SDK.
os.environ["OPENMEETING_ADMIN_PASSWORD"] = "test-admin-pw"
os.environ["OPENMEETING_SECRET_KEY"] = "test-secret-key"
os.environ.setdefault("OPENMEETING_DATABASE_URL", "postgresql+asyncpg://openmeeting:openmeeting@localhost:55432/openmeeting_test")
os.environ["OPENMEETING_DATA_DIR"] = os.path.join(tempfile.mkdtemp(prefix="user-ms-test-"), "data")
for _var in (
    "OPENMEETING_SMS_ACCESS_KEY_ID", "OPENMEETING_SMS_ACCESS_KEY_SECRET", "OPENMEETING_SMS_SIGN_NAME",
    "OPENMEETING_SMS_TEMPLATE_CODE", "OPENMEETING_SMS_TEMPLATE_PARAM", "OPENMEETING_SMS_ENDPOINT",
):
    os.environ[_var] = ""

import httpx  # noqa: E402
from asgi_lifespan import LifespanManager  # noqa: E402
from sqlalchemy import text  # noqa: E402

from user_ms.config import get_settings  # noqa: E402
from user_ms.db.session import session_factory  # noqa: E402
from user_ms.main import app  # noqa: E402

TABLES = ["client_release_artifacts", "client_releases", "system_settings", "user_settings", "sms_codes", "sms_logs",
          "sessions", "users"]

# 进程内多 ms 共存时环境变量只有一个值；启动前改写本 ms 的配置对象。
get_settings().database_url = os.environ.get(
    "OPENMEETING_TEST_DATABASE_URL", "postgresql+asyncpg://openmeeting:openmeeting@localhost:55432/openmeeting_user"
)
# user_ms 不再直连 meeting_ms（MeetingClient 在测试里不被触发；万一被触发则失败可见）。
get_settings().gateway_ms_url = "http://gateway_ms.invalid:39110"


@pytest.fixture(scope="session")
async def app_ready() -> AsyncIterator[None]:
    async with LifespanManager(app, startup_timeout=60):
        yield


@pytest.fixture(autouse=True)
async def clean_db(app_ready: None) -> AsyncIterator[None]:
    async with session_factory()() as session:
        await session.execute(text(f"TRUNCATE {', '.join(TABLES)} RESTART IDENTITY CASCADE"))
        await session.commit()
    from user_ms.monitor.connections import registry

    registry._clients.clear()
    yield


@pytest.fixture
async def client(app_ready: None) -> AsyncIterator[httpx.AsyncClient]:
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://testserver") as c:
        yield c


@pytest.fixture
async def admin(app_ready: None) -> AsyncIterator[httpx.AsyncClient]:
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://testserver") as c:
        r = await c.post("/admin/api/login", json={"password": "test-admin-pw"})
        assert r.status_code == 200, r.text
        yield c
