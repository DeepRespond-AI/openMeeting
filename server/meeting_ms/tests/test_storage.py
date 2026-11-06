from __future__ import annotations

import asyncio
import shutil
from pathlib import Path
from urllib.parse import parse_qs, urlparse

import httpx
import pytest
from sqlalchemy import select

from meeting_ms.config import get_settings
from meeting_ms.db.models import Meeting, SystemSetting
from meeting_ms.db.session import session_factory
from meeting_ms.stt import audio as audio_mod
from meeting_ms.storage import oss
from meeting_ms.storage.audio import move_local_audio_to_oss
from meeting_ms.storage.oss import OssAudioStore, OssConfig
from meeting_ms.tests.conftest import user_headers
from meeting_ms.tests.test_meetings import _wav_bytes
from meeting_ms.tests.test_transcribe import _speechy_wav, _wait_job

CFG = OssConfig("oss-cn-hangzhou.aliyuncs.com", "cn-hangzhou", "bkt", "AKID", "SECRET", "openmeeting/")


async def test_legacy_flat_audio_move_never_removes_shared_audio_directory(client, fake_oss):
    mid = (await client.post('/api/v1/meetings', json={'title': 'legacy'}, headers=user_headers())).json()['id']
    directory = get_settings().audio_dir
    directory.mkdir(parents=True, exist_ok=True)
    legacy = directory / f'{mid}.wav'
    other = directory / 'unrelated-meeting.wav'
    legacy.write_bytes(_wav_bytes(0.1))
    other.write_bytes(b'unrelated recording')
    async with session_factory()() as session:
        meeting = await session.get(Meeting, mid)
        meeting.audio_path, meeting.audio_storage = str(legacy), 'local'
        await session.commit()
    assert await move_local_audio_to_oss(mid)
    assert not legacy.exists()
    assert directory.is_dir() and other.read_bytes() == b'unrelated recording'


class FakeOssStore:
    """In-memory stand-in for OssAudioStore (objects are kept as files under a temp dir)."""

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
    store = FakeOssStore(tmp_path / "bucket")

    async def _get(*args, **kwargs) -> FakeOssStore:
        return store

    monkeypatch.setattr(oss, "get_audio_store", _get)
    return store


async def _meeting_with_audio(client: httpx.AsyncClient, h: dict, filename: str = "audio.wav") -> str:
    mid = (await client.post("/api/v1/meetings", json={"title": "A"}, headers=h)).json()["id"]
    r = await client.put(
        f"/api/v1/meetings/{mid}/audio?filename={filename}", content=_wav_bytes(1.0),
        headers={**h, "Content-Type": "audio/wav"},
    )
    assert r.status_code == 200, r.text
    return mid


async def test_upload_goes_to_oss(client: httpx.AsyncClient, fake_oss: FakeOssStore) -> None:
    h = user_headers("u-1", "alice")
    uid = "u-1"
    mid = await _meeting_with_audio(client, h)
    assert fake_oss.objects() == [f"openmeeting/audio/{uid}/{mid}/audio.wav"]
    assert not (get_settings().audio_dir / uid / mid).exists()

    meta = (await client.get(f"/api/v1/meetings/{mid}/metadata", headers=h)).json()
    assert meta["has_audio"] is True and abs(meta["audio_duration"] - 1.0) < 0.05

    r = await client.get(f"/api/v1/meetings/{mid}/audio", headers=h)
    assert r.status_code == 302
    assert r.headers["location"].startswith(f"https://bkt.oss-cn-hangzhou.aliyuncs.com/openmeeting/audio/{uid}/{mid}/")

    # Replacing with a differently named file leaves exactly one object.
    await client.put(f"/api/v1/meetings/{mid}/audio?filename=audio.m4a", content=_wav_bytes(0.5),
                     headers={**h, "Content-Type": "audio/mp4"})
    assert fake_oss.objects() == [f"openmeeting/audio/{uid}/{mid}/audio.m4a"]

    assert (await client.delete(f"/api/v1/meetings/{mid}", headers=h)).status_code == 204
    assert fake_oss.objects() == []


async def test_upload_failure_is_502(client: httpx.AsyncClient, fake_oss: FakeOssStore) -> None:
    h = user_headers()
    mid = (await client.post("/api/v1/meetings", json={"title": "A"}, headers=h)).json()["id"]
    fake_oss.fail_upload = True
    r = await client.put(f"/api/v1/meetings/{mid}/audio?filename=audio.wav", content=_wav_bytes(1.0),
                         headers={**h, "Content-Type": "audio/wav"})
    assert r.status_code == 502 and "OSS" in r.json()["detail"]
    meta = (await client.get(f"/api/v1/meetings/{mid}/metadata", headers=h)).json()
    assert meta["has_audio"] is False


async def test_oss_audio_without_config_is_503(client: httpx.AsyncClient, fake_oss, monkeypatch) -> None:
    h = user_headers()
    mid = await _meeting_with_audio(client, h)

    async def _none(*args, **kwargs) -> None:
        return None

    monkeypatch.setattr(oss, "get_audio_store", _none)
    assert (await client.get(f"/api/v1/meetings/{mid}/audio", headers=h)).status_code == 503


async def test_import_and_retranscribe_from_oss(
    client: httpx.AsyncClient, fake_stt, fake_oss: FakeOssStore, monkeypatch
) -> None:
    monkeypatch.setattr(audio_mod, "module_available", lambda name: False)
    h = user_headers()
    r = await client.post("/api/v1/jobs/import", files={"file": ("talk.wav", _speechy_wav(), "audio/wav")},
                          data={"title": "Imported"}, headers=h)
    assert r.status_code == 202, r.text
    job = await _wait_job(client, r.json()["id"], h)
    assert job["status"] == "completed", job
    # Transcribed from local disk; the audio moves to OSS right after the job.
    meeting = None
    for _ in range(100):
        async with session_factory()() as session:
            meeting = await session.get(Meeting, job["meeting_id"])
        if fake_oss.objects() and meeting.audio_storage == "oss":
            break
        await asyncio.sleep(0.02)
    assert len(fake_oss.objects()) == 1
    assert meeting is not None and meeting.audio_storage == "oss"
    assert not (get_settings().audio_dir / meeting.user_id / meeting.id).exists()

    r = await client.post("/api/v1/jobs/retranscribe", json={"meeting_id": job["meeting_id"]}, headers=h)
    job = await _wait_job(client, r.json()["id"], h)
    assert job["status"] == "completed" and job["segments"] == 2
    assert not list((get_settings().data_dir / "tmp").glob("audio-*"))  # temp download cleaned up


async def test_import_responds_before_oss(
    client: httpx.AsyncClient, fake_stt, fake_oss: FakeOssStore, monkeypatch
) -> None:
    """The import request no longer uploads to OSS: an OSS outage neither delays nor fails it."""
    monkeypatch.setattr(audio_mod, "module_available", lambda name: False)
    fake_oss.fail_upload = True
    h = user_headers()
    r = await client.post("/api/v1/jobs/import", files={"file": ("talk.wav", _speechy_wav(), "audio/wav")},
                          data={"title": "Imported"}, headers=h)
    assert r.status_code == 202, r.text
    job = await _wait_job(client, r.json()["id"], h)
    assert job["status"] == "completed", job
    await asyncio.sleep(0.05)  # the failed move
    assert fake_oss.objects() == []
    r = await client.get(f"/api/v1/meetings/{job['meeting_id']}/audio", headers=h)
    assert r.status_code == 200 and r.content == _speechy_wav(), "still served from local disk"


async def test_admin_storage_settings(admin: httpx.AsyncClient, client: httpx.AsyncClient, fake_oss) -> None:
    r = await admin.get("/admin/api/storage")
    assert r.status_code == 200
    assert r.json()["oss_ready"] is False

    r = await admin.put("/admin/api/storage", json={
        "endpoint": "https://oss-cn-shanghai.aliyuncs.com/", "bucket": "b1", "access_key_id": "id1",
        "access_key_secret": "top-secret", "prefix": "/openmeeting/",
    })
    body = r.json()
    assert body["oss_ready"] is True
    assert body["oss"] == {"endpoint": "oss-cn-shanghai.aliyuncs.com", "region": "cn-shanghai", "bucket": "b1",
                           "access_key_id": "id1", "access_key_secret_set": True, "prefix": "openmeeting/"}
    assert "top-secret" not in r.text
    async with session_factory()() as session:
        stored = (await session.execute(select(SystemSetting.value).where(SystemSetting.key == "oss_config"))).scalar_one()
    assert "top-secret" not in str(stored)

    # Omitting the secret keeps it; "" clears it.
    body = (await admin.put("/admin/api/storage", json={"bucket": "b2"})).json()
    assert body["oss"]["access_key_secret_set"] is True and body["oss"]["bucket"] == "b2"
    body = (await admin.put("/admin/api/storage", json={"access_key_secret": ""})).json()
    assert body["oss"]["access_key_secret_set"] is False and body["oss_ready"] is False

    h = user_headers()
    await _meeting_with_audio(client, h)
    stats = (await admin.get("/admin/api/storage")).json()["stats"]
    assert stats["oss"]["meetings"] == 1 and stats["local"]["meetings"] == 0


def test_region_and_presign() -> None:
    assert oss.region_from_endpoint("oss-cn-beijing.aliyuncs.com") == "cn-beijing"
    assert oss.region_from_endpoint("oss-cn-beijing-internal.aliyuncs.com") == "cn-beijing"
    assert oss.region_from_endpoint("example.com") is None
    url = OssAudioStore(CFG).presign_get("openmeeting/audio/u/m/录音.mp4")
    parsed = urlparse(url)
    assert parsed.netloc == "bkt.oss-cn-hangzhou.aliyuncs.com"
    qs = parse_qs(parsed.query)
    assert "x-oss-signature" in qs
    # OSS rejects response-header overrides on the default domain (400).
    assert not any(k.startswith("response-") for k in qs)
