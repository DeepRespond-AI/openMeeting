"""Gateway test fixtures: user_ms + gateway in one process, proxied via a host-routing transport.

参考 e2e_split.py 的做法：gateway 的 httpx client 按 host 路由到下游 ASGI transport，
X-User-* 头注入 / 剥离、代理与鉴权逻辑都跑真实路径。数据库用 openmeeting_user（TRUNCATE user_ms 的表）；
gateway 的 auth/core.py 有进程内会话缓存，每个测试前后都要清空 `_cache`。
"""
from __future__ import annotations

import os
import tempfile
from collections.abc import AsyncIterator

import pytest

# 测试绝不读取本地 .env 里的真实短信配置（否则会走真实发送而不返回 dev_code）。
os.environ["OPENMEETING_ENV"] = "test"
os.environ["OPENMEETING_EGRESS_PROXY_URL"] = ""  # Isolated ASGI/fake SDK tests never use the local egress proxy.
os.environ["OPENMEETING_IM_ENABLED"] = "false"  # IM-specific tests explicitly enable their fake SDK.
os.environ["OPENMEETING_ADMIN_PASSWORD"] = "test-admin-pw"
os.environ["OPENMEETING_SECRET_KEY"] = "test-secret-key"
os.environ.setdefault("OPENMEETING_DATABASE_URL", "postgresql+asyncpg://openmeeting:openmeeting@localhost:55432/openmeeting_user")
os.environ["OPENMEETING_DATA_DIR"] = os.path.join(tempfile.mkdtemp(prefix="gateway-ms-test-"), "data")
# 内部令牌保持未设置：下游 require_internal 放行，网关注入逻辑依然被执行（与测试环境契约一致）。
os.environ.pop("OPENMEETING_INTERNAL_SERVICE_TOKEN", None)
for _var in (
    "OPENMEETING_SMS_ACCESS_KEY_ID", "OPENMEETING_SMS_ACCESS_KEY_SECRET", "OPENMEETING_SMS_SIGN_NAME",
    "OPENMEETING_SMS_TEMPLATE_CODE", "OPENMEETING_SMS_TEMPLATE_PARAM", "OPENMEETING_SMS_ENDPOINT",
    "OPENMEETING_OSS_ENDPOINT", "OPENMEETING_OSS_REGION", "OPENMEETING_OSS_BUCKET",
    "OPENMEETING_OSS_ACCESS_KEY_ID", "OPENMEETING_OSS_ACCESS_KEY_SECRET", "OPENMEETING_OSS_PREFIX",
):
    os.environ[_var] = ""

import httpx  # noqa: E402
from asgi_lifespan import LifespanManager  # noqa: E402
from sqlalchemy import text  # noqa: E402

import gateway_ms.config as gcfg  # noqa: E402
import user_ms.config as ucfg  # noqa: E402
from user_ms.db.session import session_factory  # noqa: E402

TABLES = ["client_release_artifacts", "client_releases", "system_settings", "user_settings", "sms_codes", "sms_logs",
          "sessions", "users"]

# 进程内多 ms 共存时环境变量只有一个值；启动前改写各 ms 的配置对象。
TEST_DATABASE_URL = os.environ.get(
    "OPENMEETING_TEST_DATABASE_URL", "postgresql+asyncpg://openmeeting:openmeeting@localhost:55432/openmeeting_user"
)
ucfg.get_settings().database_url = TEST_DATABASE_URL
gcfg.get_settings().database_url = TEST_DATABASE_URL
gcfg.get_settings().user_ms_url = "http://user_ms:39113"

from gateway_ms.auth import core as auth_core  # noqa: E402
from gateway_ms.main import app as gateway_app  # noqa: E402
from user_ms.main import app as user_app  # noqa: E402


class HostRouterTransport(httpx.AsyncBaseTransport):
    """Routes by URL host to the downstream ASGI transports (user_ms here)."""

    def __init__(self, apps: dict[str, httpx.ASGITransport]) -> None:
        self.apps = apps

    async def handle_async_request(self, request: httpx.Request) -> httpx.Response:
        return await self.apps[request.url.host].handle_async_request(request)


@pytest.fixture(scope="session")
async def app_ready() -> AsyncIterator[None]:
    # user_ms 侧只做迁移 + 引擎初始化（若 user_ms/tests 已启动过同一个 app，不重复跑它的 lifespan）。
    from user_ms.db import session as udb

    url = ucfg.get_settings().database_url
    await udb.run_migrations(url)
    udb.init_engine(url)
    async with LifespanManager(gateway_app, startup_timeout=60):
        gateway_app.state.http_client = httpx.AsyncClient(
            transport=HostRouterTransport({"user_ms": httpx.ASGITransport(app=user_app)})
        )
        yield
        await gateway_app.state.http_client.aclose()


@pytest.fixture(autouse=True)
async def clean_db(app_ready: None) -> AsyncIterator[None]:
    async with session_factory()() as session:
        await session.execute(text(f"TRUNCATE {', '.join(TABLES)} RESTART IDENTITY CASCADE"))
        await session.commit()
    auth_core._cache.clear()
    from user_ms.monitor.connections import registry

    registry._clients.clear()
    yield
    auth_core._cache.clear()


@pytest.fixture
async def client(app_ready: None) -> AsyncIterator[httpx.AsyncClient]:
    transport = httpx.ASGITransport(app=gateway_app)
    async with httpx.AsyncClient(transport=transport, base_url="http://testserver") as c:
        yield c
