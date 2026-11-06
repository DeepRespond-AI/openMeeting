"""Internal API（meeting_ms 消费）：连接注册表快照与用户名批量查询。

测试环境未设置 OPENMEETING_INTERNAL_SERVICE_TOKEN → require_internal 直接放行（可直连访问）。
"""
from __future__ import annotations

import httpx

from user_ms.tests.helpers import register_via_sms


async def test_internal_connections(client: httpx.AsyncClient) -> None:
    u = await register_via_sms(client, "carol")
    r = await client.post(
        "/api/v1/client/heartbeat",
        headers=u["headers"],
        json={"client_id": "c-1", "hostname": "mbp", "os": "macos", "app_version": "1.0.0"},
    )
    assert r.status_code == 200

    body = (await client.get("/internal/connections")).json()
    assert body["online"] == 1 and body["recording"] == 0
    (snap,) = body["snapshot"]
    assert snap["client_id"] == "c-1" and snap["user_id"] == u["user"]["id"]
    assert snap["user_name"] == "carol" and snap["online"] is True and snap["recording"] is False


async def test_internal_users_batch(admin: httpx.AsyncClient, client: httpx.AsyncClient) -> None:
    created = (await admin.post("/admin/api/users", json={"phone": "13900001234", "name": "王五"})).json()
    # 逗号分隔的 id 列表；空段与未知用户被过滤。
    r = await client.get("/internal/users/batch", params={"ids": f"missing-1,{created['id']},"})
    assert r.status_code == 200
    assert r.json() == [{"id": created["id"], "name": "王五"}]
    assert (await client.get("/internal/users/batch", params={"ids": ""})).json() == []
