"""Admin users view in user_ms (拆分后：meeting_count 等跨域字段降级，时间序列归 meeting_ms）。"""
from __future__ import annotations

import httpx
import pytest
from sqlalchemy import text

from user_ms.db.session import session_factory
from user_ms.tests.helpers import register_via_sms


async def _sql(stmt: str, **params) -> list:
    async with session_factory()() as session:
        result = await session.execute(text(stmt), params)
        rows = result.fetchall() if result.returns_rows else []
        await session.commit()
        return rows


async def test_users_list_and_delete(
    admin: httpx.AsyncClient, client: httpx.AsyncClient, monkeypatch: pytest.MonkeyPatch
) -> None:
    # 删除用户要联动清理 meeting_ms 数据；单服务测试里用桩替代（真实跨域调用由网关联调覆盖）。
    from user_ms.admin import users as admin_users

    class _StubMeetingClient:
        async def stats_batch(self, ids: list[str]) -> dict[str, int]:
            return {}

        async def delete_user_data(self, user_id: str) -> None:
            return None

    monkeypatch.setattr(admin_users, "MeetingClient", _StubMeetingClient)

    issued = await register_via_sms(client, "dave")
    users = (await admin.get("/admin/api/users")).json()["items"]
    dave = next(u for u in users if u["name"] == "dave")
    assert dave["session_count"] == 1
    # meeting_count 由 meeting_ms 统计（MeetingClient 不可达时降级为 0）；真实值由网关联调验证。
    assert dave["meeting_count"] == 0
    assert (await admin.delete(f"/admin/api/users/{dave['id']}")).status_code == 204
    assert (await _sql("SELECT count(*) FROM sessions"))[0][0] == 0


async def test_timeseries_removed_from_user_ms(admin: httpx.AsyncClient) -> None:
    # 请求统计/时间序列归 meeting_ms（request_logs 在其库中）。
    assert (await admin.get("/admin/api/stats/timeseries?hours=6")).status_code == 404
