from __future__ import annotations

import hashlib
import shutil
from pathlib import Path

import httpx
import pytest

from user_ms.storage.oss import OssConfig
from user_ms.updates.service import rollout_bucket
from user_ms.updates.versions import format_version, parse_version, try_parse_version
from user_ms.tests.helpers import register_via_sms

SIG = "dW50cnVzdGVkIGNvbW1lbnQ6IHNpZ25hdHVyZQ=="
CFG = OssConfig("oss-cn-hangzhou.aliyuncs.com", "cn-hangzhou", "bkt", "AKID", "SECRET", "openmeeting/")


class FakeOssStore:
    """In-memory stand-in for the user_ms OssStore (objects are kept as files under a temp dir)."""

    backend = "oss"

    def __init__(self, root: Path) -> None:
        self.cfg = CFG
        self.root = root
        self.fail_upload = False

    def key(self, *parts: str) -> str:
        return self.cfg.prefix + "/".join(parts)

    def objects(self) -> list[str]:
        # as_posix(): OSS key 永远用正斜杠，Windows 下 str(Path) 会渲染成反斜杠
        return sorted(p.relative_to(self.root).as_posix() for p in self.root.rglob("*") if p.is_file())

    async def upload(self, local_path: Path, key: str, content_type: str | None) -> None:
        if self.fail_upload:
            raise RuntimeError("boom")
        dest = self.root / key
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(local_path, dest)

    def presign_get(self, key: str, expires: int = 3600) -> str:
        return f"https://bkt.oss-cn-hangzhou.aliyuncs.com/{key}?signed=1"

    async def download_to(self, key: str, path: Path) -> None:
        shutil.copyfile(self.root / key, path)

    async def delete_prefix(self, prefix: str, keep: str | None = None) -> int:
        deleted = 0
        for name in self.objects():
            if name.startswith(prefix) and name != keep:
                (self.root / name).unlink()
                deleted += 1
        return deleted


@pytest.fixture
def fake_oss(monkeypatch, tmp_path) -> FakeOssStore:
    from user_ms.storage import oss

    store = FakeOssStore(tmp_path / "bucket")

    async def _get(*args, **kwargs) -> FakeOssStore:
        return store

    monkeypatch.setattr(oss, "get_audio_store", _get)
    return store


# ------------------------------------------------------------------ helpers


async def _release(admin: httpx.AsyncClient, platform: str, version: str, **fields) -> dict:
    r = await admin.post("/admin/api/releases", json={"platform": platform, "version": version, **fields})
    assert r.status_code == 201, r.text
    return r.json()


async def _upload(admin: httpx.AsyncClient, release_id: str, arch: str, name: str, payload: bytes,
                  signature: str | None = SIG) -> httpx.Response:
    files = {"file": (name, payload, "application/octet-stream")}
    if signature is not None:
        files["signature"] = (name + ".sig", signature.encode(), "text/plain")
    return await admin.post(f"/admin/api/releases/{release_id}/artifacts", data={"arch": arch}, files=files)


async def _publish(admin: httpx.AsyncClient, release_id: str) -> dict:
    r = await admin.post(f"/admin/api/releases/{release_id}/publish")
    assert r.status_code == 200, r.text
    return r.json()


async def _check(client: httpx.AsyncClient, **params) -> dict:
    r = await client.get("/api/v1/updates/check", params=params)
    assert r.status_code == 200, r.text
    return r.json()


async def _desktop_release(admin: httpx.AsyncClient, version: str, **fields) -> dict:
    rel = await _release(admin, "macos", version, **fields)
    r = await _upload(admin, rel["id"], "aarch64", f"DR_{version}_aarch64.app.tar.gz", b"pkg-" + version.encode())
    assert r.status_code == 201, r.text
    return await _publish(admin, rel["id"])


def _client_in_bucket(release_id: str, below: int) -> str:
    return next(f"cid-{i}" for i in range(10_000) if rollout_bucket(release_id, f"cid-{i}") < below)


def _client_out_of_bucket(release_id: str, at_least: int) -> str:
    return next(f"cid-{i}" for i in range(10_000) if rollout_bucket(release_id, f"cid-{i}") >= at_least)


# ------------------------------------------------------------------ versions & buckets


def test_versions() -> None:
    assert parse_version("1.2.3") == (1, 2, 3, 0)
    assert parse_version("1.2.3+45") == (1, 2, 3, 45)
    assert parse_version("v0.4.1") == (0, 4, 1, 0)
    assert parse_version("1.10.0") > parse_version("1.9.9")
    assert parse_version("1.0.0+2") > parse_version("1.0.0+1") > parse_version("1.0.0")
    assert try_parse_version("1.2") is None
    assert try_parse_version("1.2.3-beta") is None
    assert format_version("1.0.1", 2) == "1.0.1+2"
    assert format_version("0.4.2", 0) == "0.4.2"


def test_rollout_bucket_is_stable_and_spread() -> None:
    assert rollout_bucket("r1", "device") == rollout_bucket("r1", "device")
    buckets = {rollout_bucket("r1", f"device-{i}") for i in range(2000)}
    assert min(buckets) == 0 and max(buckets) == 99


# ------------------------------------------------------------------ desktop


async def test_desktop_publish_check_and_download(admin: httpx.AsyncClient, client: httpx.AsyncClient) -> None:
    assert await _check(client, platform="macos", version="0.4.1", arch="aarch64") == {
        "update": None, "min_version": None,
    }

    rel = await _release(admin, "macos", "0.4.2", notes="修复若干问题")
    # Desktop packages need the Tauri signature.
    r = await _upload(admin, rel["id"], "aarch64", "DR.app.tar.gz", b"payload", signature=None)
    assert r.status_code == 422
    r = await admin.post(f"/admin/api/releases/{rel['id']}/publish")
    assert r.status_code == 400, "no package yet"
    r = await _upload(admin, rel["id"], "aarch64", "DR Meeting.app.tar.gz", b"payload")
    assert r.status_code == 201, r.text
    artifact = r.json()["artifacts"][0]
    assert artifact["file_name"] == "DR_Meeting.app.tar.gz"
    assert artifact["sha256"] == hashlib.sha256(b"payload").hexdigest()
    assert artifact["signed"] is True and artifact["storage"] == "local"

    # Drafts are not offered.
    assert (await _check(client, platform="macos", version="0.4.1", arch="aarch64"))["update"] is None
    await _publish(admin, rel["id"])

    update = (await _check(client, platform="macos", version="0.4.1", arch="aarch64"))["update"]
    assert update["version"] == "0.4.2" and update["notes"] == "修复若干问题"
    assert update["force"] is False and update["store_url"] is None
    assert update["size"] == 7
    # Same version / other architecture → nothing.
    assert (await _check(client, platform="macos", version="0.4.2", arch="aarch64"))["update"] is None
    assert (await _check(client, platform="macos", version="0.4.1", arch="x86_64"))["update"] is None

    # Tauri updater format.
    r = await client.get("/api/v1/updates/tauri/darwin/aarch64/0.4.1", params={"client_id": "c1"})
    assert r.status_code == 200, r.text
    body = r.json()
    assert body["version"] == "0.4.2" and body["signature"] == SIG and body["force"] is False
    assert body["url"] == update["download_url"]
    assert (await client.get("/api/v1/updates/tauri/darwin/aarch64/0.4.2")).status_code == 204
    assert (await client.get("/api/v1/updates/tauri/darwin/x86_64/0.4.1")).status_code == 204

    r = await client.get(update["download_url"])
    assert r.status_code == 200 and r.content == b"payload"
    listed = (await admin.get("/admin/api/releases", params={"platform": "macos"})).json()
    assert listed[0]["artifacts"][0]["download_count"] == 1


async def test_universal_package_serves_every_mac(admin: httpx.AsyncClient, client: httpx.AsyncClient) -> None:
    rel = await _release(admin, "macos", "0.5.0")
    assert (await _upload(admin, rel["id"], "universal", "DR.app.tar.gz", b"u")).status_code == 201
    await _publish(admin, rel["id"])
    for arch in ("aarch64", "x86_64"):
        assert (await _check(client, platform="macos", version="0.4.1", arch=arch))["update"]["version"] == "0.5.0"


async def test_newest_release_and_skipped_force(admin: httpx.AsyncClient, client: httpx.AsyncClient) -> None:
    await _desktop_release(admin, "0.4.2", force=True)
    await _desktop_release(admin, "0.4.3")
    update = (await _check(client, platform="macos", version="0.4.1", arch="aarch64"))["update"]
    assert update["version"] == "0.4.3"
    assert update["force"] is True, "skips over a forced release"
    update = (await _check(client, platform="macos", version="0.4.2", arch="aarch64"))["update"]
    assert update["version"] == "0.4.3" and update["force"] is False


async def test_pause_and_archive(admin: httpx.AsyncClient, client: httpx.AsyncClient) -> None:
    rel = await _desktop_release(admin, "0.4.2")
    r = await admin.post(f"/admin/api/releases/{rel['id']}/pause")
    assert r.json()["status"] == "paused"
    assert (await _check(client, platform="macos", version="0.4.1", arch="aarch64"))["update"] is None
    await _publish(admin, rel["id"])
    assert (await _check(client, platform="macos", version="0.4.1", arch="aarch64"))["update"] is not None
    r = await admin.delete(f"/admin/api/releases/{rel['id']}")
    assert r.status_code == 400, "published releases cannot be deleted"
    await admin.post(f"/admin/api/releases/{rel['id']}/archive")
    assert (await _check(client, platform="macos", version="0.4.1", arch="aarch64"))["update"] is None
    assert (await admin.delete(f"/admin/api/releases/{rel['id']}")).status_code == 204
    assert (await admin.get("/admin/api/releases")).json() == []


# ------------------------------------------------------------------ rollout & policy


async def test_staged_rollout(admin: httpx.AsyncClient, client: httpx.AsyncClient) -> None:
    await _desktop_release(admin, "0.4.2")  # fully rolled out
    rel = await _desktop_release(admin, "0.4.3", rollout_percent=20)
    inside = _client_in_bucket(rel["id"], 20)
    outside = _client_out_of_bucket(rel["id"], 20)

    up = lambda body: body["update"]["version"]  # noqa: E731
    assert up(await _check(client, platform="macos", version="0.4.1", arch="aarch64", client_id=inside)) == "0.4.3"
    # Not in the rollout → the previous release.
    assert up(await _check(client, platform="macos", version="0.4.1", arch="aarch64", client_id=outside)) == "0.4.2"
    assert (await _check(client, platform="macos", version="0.4.2", arch="aarch64", client_id=outside))["update"] is None

    # Allow-listed users get it whatever their bucket (the gateway resolves their identity).
    user = await register_via_sms(client, "tester")
    body = {**rel, "rollout_users": [user["user"]["id"], "missing-user"]}
    r = await admin.put(f"/admin/api/releases/{rel['id']}", json=body)
    assert [u["id"] for u in r.json()["rollout_users"]] == [user["user"]["id"]]
    r = await client.get("/api/v1/updates/check", headers=user["headers"],
                         params={"platform": "macos", "version": "0.4.2", "arch": "aarch64", "client_id": outside})
    assert r.json()["update"]["version"] == "0.4.3"

    # Raising the percentage keeps everyone who already had it.
    await admin.put(f"/admin/api/releases/{rel['id']}", json={**body, "rollout_percent": 100})
    assert up(await _check(client, platform="macos", version="0.4.2", arch="aarch64", client_id=outside)) == "0.4.3"


async def test_min_version_forces_and_ignores_rollout(admin: httpx.AsyncClient, client: httpx.AsyncClient) -> None:
    rel = await _desktop_release(admin, "0.4.3", rollout_percent=0)
    assert (await _check(client, platform="macos", version="0.4.1", arch="aarch64", client_id="c"))["update"] is None

    r = await admin.put("/admin/api/update-policy", json={"macos": {"min_version": "0.4.2"}})
    assert r.status_code == 200 and r.json()["macos"]["min_version"] == "0.4.2"
    body = await _check(client, platform="macos", version="0.4.1", arch="aarch64", client_id="c")
    assert body["min_version"] == "0.4.2"
    assert body["update"]["version"] == "0.4.3" and body["update"]["force"] is True
    r = await client.get("/api/v1/updates/tauri/darwin/aarch64/0.4.1", params={"client_id": "c"})
    assert r.json()["force"] is True and r.json()["min_version"] == "0.4.2"
    # At the minimum: back to the normal rollout (0 %).
    assert (await _check(client, platform="macos", version="0.4.2", arch="aarch64", client_id="c"))["update"] is None
    assert rel["status"] == "published"

    r = await admin.put("/admin/api/update-policy", json={"macos": {"min_version": "1.2"}})
    assert r.status_code == 422


# ------------------------------------------------------------------ mobile


async def test_android_direct_and_store_channels(admin: httpx.AsyncClient, client: httpx.AsyncClient) -> None:
    rel = await _release(admin, "android", "1.0.1", build=2)
    r = await _upload(admin, rel["id"], "x86_64", "app.apk", b"apk", signature=None)
    assert r.status_code == 422, "android packages are arch `any`"
    r = await _upload(admin, rel["id"], "any", "app-release.apk", b"apk", signature=None)
    assert r.status_code == 201, r.text
    await _publish(admin, rel["id"])

    update = (await _check(client, platform="android", version="1.0.0+1"))["update"]
    assert update["full_version"] == "1.0.1+2" and update["build"] == 2
    assert update["download_url"] and update["store_url"] is None
    r = await client.get(update["download_url"])
    assert r.headers["content-type"] == "application/vnd.android.package-archive"
    assert (await _check(client, platform="android", version="1.0.1+2"))["update"] is None
    # Same version name, newer build → newer.
    assert (await _check(client, platform="android", version="1.0.1+1"))["update"] is not None

    # Store builds: only when the channel has a link, and never a download.
    assert (await _check(client, platform="android", version="1.0.0+1", channel="huawei"))["update"] is None
    r = await admin.put("/admin/api/update-policy", json={"android": {
        "store_urls": {"huawei": "appmarket://details?id=cn.deeprespond.meeting", "xiaomi": ""},
    }})
    assert r.json()["android"]["store_urls"] == {"huawei": "appmarket://details?id=cn.deeprespond.meeting"}
    update = (await _check(client, platform="android", version="1.0.0+1", channel="huawei"))["update"]
    assert update["store_url"].startswith("appmarket://") and update["download_url"] is None

    r = await admin.put("/admin/api/update-policy", json={"android": {"store_urls": {"x": "ftp://nope"}}})
    assert r.status_code == 422


async def test_ios_goes_to_the_app_store(admin: httpx.AsyncClient, client: httpx.AsyncClient) -> None:
    rel = await _release(admin, "ios", "1.0.1", build=3)
    assert (await _upload(admin, rel["id"], "any", "x.ipa", b"x", signature=None)).status_code == 400
    await _publish(admin, rel["id"])
    assert (await _check(client, platform="ios", version="1.0.0+1"))["update"] is None, "no App Store link yet"
    await admin.put("/admin/api/update-policy", json={"ios": {
        "min_version": "1.0.1", "store_urls": {"appstore": "https://apps.apple.com/cn/app/id123"},
    }})
    update = (await _check(client, platform="ios", version="1.0.0+1"))["update"]
    assert update["store_url"] == "https://apps.apple.com/cn/app/id123" and update["force"] is True


# ------------------------------------------------------------------ admin details


async def test_release_validation(admin: httpx.AsyncClient, client: httpx.AsyncClient) -> None:
    r = await admin.post("/admin/api/releases", json={"platform": "macos", "version": "1.2"})
    assert r.status_code == 422
    r = await admin.post("/admin/api/releases", json={"platform": "macos", "version": "1.2.3+4"})
    assert r.status_code == 422, "build is a separate field"
    desktop = await _release(admin, "windows", "0.4.2", build=7)
    assert desktop["build"] == 0, "desktop releases have no build number"
    r = await admin.post("/admin/api/releases", json={"platform": "windows", "version": "0.4.2"})
    assert r.status_code == 409
    r = await admin.post("/admin/api/releases", json={"platform": "symbian", "version": "1.0.0"})
    assert r.status_code == 422

    rel = await _desktop_release(admin, "0.4.3")
    r = await admin.put(f"/admin/api/releases/{rel['id']}", json={**rel, "version": "0.4.4"})
    assert r.status_code == 400, "published version numbers are fixed"

    r = await client.get("/api/v1/updates/check", params={"platform": "macos", "version": "abc"})
    assert r.status_code == 422
    assert (await client.get("/api/v1/updates/download/nope")).status_code == 404


async def test_reupload_replaces_package(admin: httpx.AsyncClient, client: httpx.AsyncClient) -> None:
    rel = await _release(admin, "windows", "0.4.2")
    await _upload(admin, rel["id"], "x86_64", "setup-old.exe", b"old")
    r = await _upload(admin, rel["id"], "x86_64", "setup-new.exe", b"new")
    artifacts = r.json()["artifacts"]
    assert len(artifacts) == 1 and artifacts[0]["file_name"] == "setup-new.exe"
    await _publish(admin, rel["id"])
    update = (await _check(client, platform="windows", version="0.4.1", arch="x86_64"))["update"]
    assert (await client.get(update["download_url"])).content == b"new"

    r = await admin.delete(f"/admin/api/releases/{rel['id']}/artifacts/{artifacts[0]['id']}")
    assert r.json()["artifacts"] == []
    assert (await _check(client, platform="windows", version="0.4.1", arch="x86_64"))["update"] is None


async def test_packages_go_to_oss_when_configured(
    admin: httpx.AsyncClient, client: httpx.AsyncClient, fake_oss: FakeOssStore  # noqa: F811
) -> None:
    rel = await _release(admin, "android", "1.0.1", build=2)
    r = await _upload(admin, rel["id"], "any", "app.apk", b"apk", signature=None)
    assert r.json()["artifacts"][0]["storage"] == "oss"
    assert fake_oss.objects() == [f"openmeeting/releases/{rel['id']}/any/app.apk"]
    await _publish(admin, rel["id"])
    update = (await _check(client, platform="android", version="1.0.0+1"))["update"]
    r = await client.get(update["download_url"])
    assert r.status_code == 302 and "signed=1" in r.headers["location"]

    await admin.post(f"/admin/api/releases/{rel['id']}/archive")
    assert (await admin.delete(f"/admin/api/releases/{rel['id']}")).status_code == 204
    assert fake_oss.objects() == []


async def test_heartbeat_keeps_session_version_current(
    admin: httpx.AsyncClient, client: httpx.AsyncClient
) -> None:
    user = await register_via_sms(client, "upgrader", os="android", app_version="1.0.0+1")
    stats = (await admin.get("/admin/api/releases/stats")).json()
    assert stats["android"] == [{"version": "1.0.0+1", "count": 1}]

    r = await client.post("/api/v1/client/heartbeat", headers=user["headers"], json={
        "client_id": "cid-upgrader", "os": "android", "app_version": "1.0.1+2",
    })
    assert r.status_code == 200
    stats = (await admin.get("/admin/api/releases/stats")).json()
    assert stats["android"] == [{"version": "1.0.1+2", "count": 1}]


@pytest.mark.parametrize("platform", ["windows", "macos", "linux", "android", "ios"])
async def test_policy_round_trip(admin: httpx.AsyncClient, platform: str) -> None:
    r = await admin.get("/admin/api/update-policy")
    assert r.json()[platform] == {"min_version": "", "store_urls": {}}
