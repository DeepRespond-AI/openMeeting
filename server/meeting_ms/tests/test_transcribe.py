from __future__ import annotations

import asyncio
import io

import httpx
import numpy as np
import pytest
import soundfile as sf

from meeting_ms.stt import audio as audio_mod
from meeting_ms.tests.conftest import user_headers


def _pcm(seconds: float, silent: bool = False) -> bytes:
    n = int(seconds * 16000)
    if silent:
        return np.zeros(n, dtype="<i2").tobytes()
    t = np.arange(n) / 16000
    return (np.sin(2 * np.pi * 300 * t) * 8000).astype("<i2").tobytes()


async def test_segments_requires_ready_stt(client: httpx.AsyncClient, fake_stt) -> None:
    fake_stt.ready = False  # stt_ms 未就绪（模型未激活 / 服务不可达）
    h = user_headers()
    mid = (await client.post("/api/v1/meetings", json={"title": "Live"}, headers=h)).json()["id"]
    r = await client.post(f"/api/v1/meetings/{mid}/segments?seq=0&start=0&end=1", content=_pcm(1), headers=h)
    assert r.status_code == 503


async def test_segments_and_idempotency(client: httpx.AsyncClient, fake_stt) -> None:
    h = user_headers()
    mid = (await client.post("/api/v1/meetings", json={"title": "Live"}, headers=h)).json()["id"]
    h = {**h, "Content-Type": "application/octet-stream"}

    r = await client.post(f"/api/v1/meetings/{mid}/segments?seq=1&start=0&end=1.5&language=zh", content=_pcm(1.5), headers=h)
    assert r.status_code == 200, r.text
    first = r.json()
    assert first["id"] and first["seq"] == 1 and first["text"] == "segment 1.50s lang=zh"
    assert abs(first["confidence"] - 0.9) < 1e-6

    # Retried seq returns the stored row without re-transcribing.
    calls = fake_stt.calls
    r = await client.post(f"/api/v1/meetings/{mid}/segments?seq=1&start=0&end=1.5", content=_pcm(1.5), headers=h)
    assert r.json() == first and fake_stt.calls == calls

    # Silence -> empty text, nothing stored.
    r = await client.post(f"/api/v1/meetings/{mid}/segments?seq=2&start=2&end=3", content=_pcm(1, silent=True), headers=h)
    assert r.json() == {"id": None, "text": "", "confidence": None, "seq": 2}

    # Concurrent retries of the same seq store exactly one transcript.
    results = await asyncio.gather(
        *[
            client.post(f"/api/v1/meetings/{mid}/segments?seq=3&start=4&end=5&language=auto", content=_pcm(1), headers=h)
            for _ in range(4)
        ]
    )
    assert len({r.json()["id"] for r in results}) == 1

    page = (await client.get(f"/api/v1/meetings/{mid}/transcripts", headers=h)).json()
    assert page["total_count"] == 2
    t = page["transcripts"][0]
    assert t["audio_start_time"] == 0 and t["audio_end_time"] == 1.5 and t["duration"] == 1.5
    assert t["timestamp"].endswith("Z")
    # 畸形 PCM（奇数字节数）→ 400 的格式校验在 stt_ms /internal/transcribe 里，fake_stt 不模拟（见 stt_ms/tests）。


def _speechy_wav() -> bytes:
    """2 s tone, 2 s silence, 1.5 s tone at 16 kHz."""
    sr = 16000
    tone = lambda s: (0.4 * np.sin(2 * np.pi * 250 * np.arange(int(s * sr)) / sr)).astype(np.float32)  # noqa: E731
    audio = np.concatenate([tone(2.0), np.zeros(2 * sr, np.float32), tone(1.5), np.zeros(sr // 2, np.float32)])
    buf = io.BytesIO()
    sf.write(buf, audio, sr, format="WAV", subtype="PCM_16")
    return buf.getvalue()


async def _wait_job(client: httpx.AsyncClient, job_id: str, h: dict) -> dict:
    for _ in range(200):
        job = (await client.get(f"/api/v1/jobs/{job_id}", headers=h)).json()
        if job["status"] in ("completed", "failed", "cancelled"):
            return job
        await asyncio.sleep(0.05)
    raise AssertionError("job did not finish")


async def test_import_and_retranscribe_jobs(
    client: httpx.AsyncClient, fake_stt, admin: httpx.AsyncClient, monkeypatch: pytest.MonkeyPatch
) -> None:
    # Synthetic tones are not speech for silero-vad; use the deterministic energy VAD.
    monkeypatch.setattr(audio_mod, "module_available", lambda name: False)
    h = user_headers()
    r = await client.post(
        "/api/v1/jobs/import",
        files={"file": ("talk.wav", _speechy_wav(), "audio/wav")},
        data={"title": "Imported", "language": "en"},
        headers=h,
    )
    assert r.status_code == 202, r.text
    job = r.json()
    assert job["kind"] == "import" and job["id"].startswith("job-") and job["meeting_id"]
    job = await _wait_job(client, job["id"], h)
    assert job["status"] == "completed", job
    assert job["progress"] == 100 and job["segments"] == 2

    mid = job["meeting_id"]
    transcripts = (await client.get(f"/api/v1/meetings/{mid}", headers=h)).json()["transcripts"]
    assert len(transcripts) == 2
    assert transcripts[0]["audio_start_time"] < 0.5 and 3.5 < transcripts[1]["audio_start_time"] < 4.2
    assert all("lang=en" in t["text"] for t in transcripts)

    r = await client.post("/api/v1/jobs/retranscribe", json={"meeting_id": mid, "language": None}, headers=h)
    assert r.status_code == 202
    job = await _wait_job(client, r.json()["id"], h)
    assert job["status"] == "completed"
    transcripts2 = (await client.get(f"/api/v1/meetings/{mid}", headers=h)).json()["transcripts"]
    assert len(transcripts2) == 2
    assert {t["id"] for t in transcripts2}.isdisjoint({t["id"] for t in transcripts})
    assert all("lang=auto" in t["text"] for t in transcripts2)

    admin_jobs = (await admin.get("/admin/api/jobs")).json()
    # user_name 来自 user_ms 的批量查询；本测试进程内 user_ms 不存在 → 降级 None。
    # 该跨域 join 已移至 user_ms 域，真实链路由网关联调（e2e）验证。
    assert len(admin_jobs) == 2 and admin_jobs[0]["user_name"] is None

    stats = (await admin.get("/admin/api/dashboard")).json()["stats"]
    assert stats["today_requests"] >= 2


async def test_job_isolation(client: httpx.AsyncClient, fake_stt) -> None:
    alice = user_headers("u-1", "alice")
    bob = user_headers("u-2", "bob")
    r = await client.post(
        "/api/v1/jobs/import", files={"file": ("a.wav", _speechy_wav(), "audio/wav")}, data={"title": "x"}, headers=alice
    )
    job_id = r.json()["id"]
    assert (await client.get(f"/api/v1/jobs/{job_id}", headers=bob)).status_code == 404
    await _wait_job(client, job_id, alice)
