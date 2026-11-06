"""Global storage API contracts, using an in-memory settings backend."""
from types import SimpleNamespace

import httpx
import pytest
from fastapi import FastAPI

from gateway_ms.api.gateway import ADMIN_ROUTES, resolve_downstream
from meeting_ms.admin import object_storage, storage
from meeting_ms.db.session import get_session
from meeting_ms.storage import oss
from meeting_ms.utils import SecretBox


@pytest.fixture
async def storage_api(monkeypatch):
    saved = {}
    env = SimpleNamespace(**{f"oss_{field}": "" for field in (
        "endpoint", "region", "bucket", "access_key_id", "access_key_secret", "prefix",
    )})
    box = SecretBox("object-storage-test")

    async def get_setting(key, default):
        assert key == "oss_config"
        return saved.get(key, default)

    async def set_setting(key, value):
        saved[key] = value

    async def session():
        yield None

    async def stats(session):
        return {"local": {"meetings": 2, "bytes": 10}, "oss": {"meetings": 1, "bytes": 20}}

    monkeypatch.setattr(oss, "get_setting", get_setting)
    monkeypatch.setattr(oss, "set_setting", set_setting)
    monkeypatch.setattr(oss, "get_settings", lambda: env)
    monkeypatch.setattr(oss, "secret_box", lambda: box)
    monkeypatch.setattr(object_storage, "secret_box", lambda: box)
    monkeypatch.setattr(storage, "audio_stats", stats)
    app = FastAPI()
    app.include_router(object_storage.router, prefix="/admin/api")
    app.include_router(storage.router, prefix="/admin/api")
    app.dependency_overrides[get_session] = session
    async with httpx.AsyncClient(transport=httpx.ASGITransport(app=app), base_url="http://test") as client:
        yield client, saved, env


async def test_global_config_reuses_legacy_settings_and_hides_secret(storage_api):
    client, saved, _ = storage_api
    response = await client.put("/admin/api/storage", json={
        "endpoint": "https://oss-cn-shanghai.aliyuncs.com/", "bucket": "bucket",
        "access_key_id": "test-id", "access_key_secret": "test-secret", "prefix": "/openmeeting/",
    })
    assert response.status_code == 200
    response = await client.get("/admin/api/object-storage")
    assert response.status_code == 200
    assert response.json()["oss_ready"] is True
    assert response.json()["oss"]["prefix"] == "openmeeting/"
    assert "stats" not in response.json()
    assert "test-secret" not in response.text
    assert "test-secret" not in str(saved)

    response = await client.put("/admin/api/object-storage", json={"bucket": "new-bucket"})
    assert response.json()["oss"]["access_key_secret_set"] is True
    assert (await oss.load_oss_config()).bucket == "new-bucket"
    assert (await oss.load_oss_config()).access_key_secret == "test-secret"
    legacy = (await client.get("/admin/api/storage")).json()
    assert legacy["oss"] == response.json()["oss"]
    audio = (await client.get("/admin/api/storage/audio")).json()
    assert audio == {"provider": "oss", "oss_ready": True, "stats": legacy["stats"]}

    response = await client.put("/admin/api/object-storage", json={"access_key_secret": None})
    assert response.json()["oss_ready"] is True
    response = await client.put("/admin/api/object-storage", json={"access_key_secret": ""})
    assert response.json()["oss_ready"] is False
    assert (await client.get("/admin/api/storage/audio")).json()["oss_ready"] is False


async def test_environment_override_and_connection_test(storage_api, monkeypatch):
    client, _, env = storage_api
    response = await client.post("/admin/api/object-storage/test")
    assert response.json()["ok"] is False
    env.oss_bucket = "env-bucket"
    response = await client.put("/admin/api/object-storage", json={
        "endpoint": "oss-cn-hangzhou.aliyuncs.com", "bucket": "saved-bucket",
        "access_key_id": "id", "access_key_secret": "secret",
    })
    assert response.json()["oss"]["bucket"] == "env-bucket"
    assert response.json()["env_overrides"] == ["bucket"]
    calls = []

    class TestStore:
        def __init__(self, config):
            assert config.bucket == "env-bucket"

        async def test(self):
            calls.append(True)

    monkeypatch.setattr(oss, "OssAudioStore", TestStore)
    assert (await client.post("/admin/api/object-storage/test")).json() == {"ok": True, "error": None}
    assert (await client.post("/admin/api/storage/test")).json()["ok"] is True
    assert len(calls) == 2

    async def fail(self):
        raise RuntimeError("test outage")

    monkeypatch.setattr(TestStore, "test", fail)
    assert (await client.post("/admin/api/object-storage/test")).json() == {"ok": False, "error": "test outage"}


@pytest.mark.parametrize("path", ["/object-storage", "/object-storage/test", "/storage/audio"])
def test_storage_gateway_routes(path):
    assert resolve_downstream("/admin/api" + path, ADMIN_ROUTES) == "meeting"
