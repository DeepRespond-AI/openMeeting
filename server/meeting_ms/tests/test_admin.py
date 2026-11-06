"""Admin dashboard/llm/templates/storage/data views of meeting_ms（跨域字段在无 user_ms 时降级）。"""
from __future__ import annotations

import asyncio
import json

import httpx
import respx

from meeting_ms.monitor.events import broker
from meeting_ms.tests.conftest import user_headers


@respx.mock(assert_all_called=False)
async def test_llm_provider_crud(respx_mock, admin: httpx.AsyncClient) -> None:
    respx_mock.get("http://relay.test/v1/models").mock(
        return_value=httpx.Response(200, json={"data": [{"id": "qwen-max"}, {"id": "qwen-plus"}]})
    )
    body = {"name": "relay", "base_url": "http://relay.test/v1/", "model": "qwen-plus", "api_key": "sk-1"}
    p1 = (await admin.post("/admin/api/llm/providers", json=body)).json()
    assert p1["base_url"] == "http://relay.test/v1" and p1["context_tokens"] == 32000 and p1["active"]
    p2 = (await admin.post("/admin/api/llm/providers", json={**body, "name": "second", "api_key": None})).json()
    assert p2["active"] is False and p2["api_key_set"] is False

    status = (await admin.post(f"/admin/api/llm/providers/{p2['id']}/activate")).json()
    assert status == {"name": "second", "model": "qwen-plus", "ready": True, "error": None}

    updated = (await admin.put(f"/admin/api/llm/providers/{p1['id']}", json={**body, "model": "qwen-max", "api_key": None})).json()
    assert updated["model"] == "qwen-max" and updated["api_key_set"] is True

    assert (await admin.get(f"/admin/api/llm/providers/{p1['id']}/models")).json() == ["qwen-max", "qwen-plus"]
    probe = await admin.post("/admin/api/llm/models-probe", json={"base_url": "http://relay.test/v1", "provider_id": p1["id"]})
    assert probe.json() == ["qwen-max", "qwen-plus"]
    assert respx_mock.calls.last.request.headers["authorization"] == "Bearer sk-1"
    probe = await admin.post("/admin/api/llm/models-probe", json={"base_url": "http://unreachable.test/v1"})
    assert probe.json() == []

    assert (await admin.delete(f"/admin/api/llm/providers/{p2['id']}")).status_code == 204
    dash = (await admin.get("/admin/api/dashboard")).json()
    assert dash["llm"]["ready"] is False
    assert len((await admin.get("/admin/api/llm/providers")).json()) == 1


async def test_timeseries(admin: httpx.AsyncClient) -> None:
    series = (await admin.get("/admin/api/stats/timeseries?hours=6")).json()
    assert len(series) == 6 and set(series[0]) == {
        "ts", "transcribe_requests", "audio_sec", "summary_requests", "errors", "avg_latency_ms"
    }


async def test_dashboard_and_connections_degrade(admin: httpx.AsyncClient) -> None:
    # user_ms / stt_ms 不在测试进程内：在线数与 stt 状态降级为空值，接口本身仍可用。
    dash = (await admin.get("/admin/api/dashboard")).json()
    assert dash["stats"]["online_clients"] == 0 and dash["stats"]["recording_clients"] == 0
    assert dash["stt"]["ready"] is False and dash["device"] == "cpu"
    assert (await admin.get("/admin/api/connections")).json() == []


async def test_admin_meetings_user_name_degrades(client: httpx.AsyncClient, admin: httpx.AsyncClient) -> None:
    h = user_headers("u-1", "alice")
    mid = (await client.post("/api/v1/meetings", json={"title": "m"}, headers=h)).json()["id"]
    listing = (await admin.get("/admin/api/meetings")).json()
    assert listing["total"] == 1
    # user_name / 在线状态等跨域字段来自 user_ms，测试进程不可达 → 降级 None（真实链路由网关联调验证）。
    assert listing["items"][0]["user_name"] is None
    detail = (await admin.get(f"/admin/api/meetings/{mid}")).json()
    assert detail["user_name"] is None and detail["title"] == "m"


async def test_event_broker_payloads() -> None:
    queue = broker.subscribe()
    try:
        broker.publish("ping", {})
        event, data = await asyncio.wait_for(queue.get(), 1)
        assert event == "ping" and json.loads(data) == {}
    finally:
        broker.unsubscribe(queue)
