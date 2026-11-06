"""Internal API（user_ms 消费）：会议统计、批量统计与用户数据删除。

测试环境未设置 OPENMEETING_INTERNAL_SERVICE_TOKEN → require_internal 直接放行（可直连访问）。
"""
from __future__ import annotations

import httpx

from meeting_ms.tests.conftest import user_headers


async def test_user_stats_and_stats_batch(client: httpx.AsyncClient) -> None:
    h = user_headers("u-1", "alice")
    await client.post("/api/v1/meetings", json={"title": "A"}, headers=h)
    await client.post("/api/v1/meetings", json={"title": "B"}, headers=h)

    assert (await client.get("/internal/users/u-1/stats")).json() == {"meeting_count": 2}
    assert (await client.get("/internal/users/u-2/stats")).json() == {"meeting_count": 0}
    # 逗号分隔的 id 列表；空段与没有会议的用户不产生条目。
    r = await client.get("/internal/users/stats-batch", params={"ids": "u-1,u-2, "})
    assert r.status_code == 200
    assert r.json() == {"u-1": 2}
    assert (await client.get("/internal/users/stats-batch", params={"ids": ""})).json() == {}


async def test_delete_user_data(client: httpx.AsyncClient) -> None:
    import uuid

    h = user_headers("u-1", "alice")
    mid = (await client.post("/api/v1/meetings", json={"title": "Doomed"}, headers=h)).json()["id"]
    await client.post(
        f"/api/v1/meetings/{mid}/transcripts",
        json={"transcripts": [{"id": str(uuid.uuid4()), "text": "gone soon", "timestamp": "t"}]},
        headers=h,
    )
    assert (await client.get("/api/v1/meetings", headers=h)).json()

    r = await client.delete("/internal/users/u-1/data")
    assert r.status_code == 204
    # 会议行、转写与文件目录一并删除。
    assert (await client.get("/api/v1/meetings", headers=h)).json() == []
    assert (await client.get(f"/api/v1/meetings/{mid}", headers=h)).status_code == 404
