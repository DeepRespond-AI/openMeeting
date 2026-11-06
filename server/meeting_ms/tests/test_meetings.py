from __future__ import annotations

import io
import uuid

import httpx
import numpy as np
import soundfile as sf

from meeting_ms.tests.conftest import user_headers


async def test_capabilities(client: httpx.AsyncClient, fake_stt) -> None:
    # 拆分前 admin 测试的 capabilities 断言：stt 状态经 SttClient 拉取（fake_stt 提供 fake 引擎）。
    caps = (await client.get("/api/v1/client/capabilities", headers=user_headers())).json()
    assert caps["user"] == {"id": "u-1", "name": "alice", "phone": None}
    assert caps["stt"] == {"engine": "fake", "model": "fake", "ready": True, "error": None}
    assert "llm" in caps and "server_version" in caps


async def test_meeting_crud(client: httpx.AsyncClient) -> None:
    h = user_headers()
    r = await client.post("/api/v1/meetings", json={"title": "Standup"}, headers=h)
    assert r.status_code == 201
    meta = r.json()
    assert meta["id"].startswith("meeting-")
    assert meta["folder_path"] is None and meta["has_audio"] is False and meta["audio_duration"] is None
    mid = meta["id"]

    await client.post("/api/v1/meetings", json={"title": "Second"}, headers=h)
    listed = (await client.get("/api/v1/meetings", headers=h)).json()
    assert [m["title"] for m in listed] == ["Second", "Standup"]
    assert all(m["created_at"] and m["updated_at"] for m in listed)

    r = await client.patch(f"/api/v1/meetings/{mid}", json={"title": "Renamed"}, headers=h)
    assert r.json()["title"] == "Renamed"

    segs = [
        {"id": str(uuid.uuid4()), "text": "second line", "timestamp": "2026-10-07T00:00:02Z",
         "audio_start_time": 5.0, "audio_end_time": 7.0},
        {"id": str(uuid.uuid4()), "text": "first line about budget", "timestamp": "2026-10-07T00:00:01Z",
         "audio_start_time": 1.0, "audio_end_time": 3.0, "duration": 2.0},
    ]
    r = await client.post(f"/api/v1/meetings/{mid}/transcripts", json={"transcripts": segs}, headers=h)
    assert r.json() == {"inserted": 2}
    r = await client.post(f"/api/v1/meetings/{mid}/transcripts", json={"transcripts": segs}, headers=h)
    assert r.json() == {"inserted": 0}

    details = (await client.get(f"/api/v1/meetings/{mid}", headers=h)).json()
    assert [t["text"] for t in details["transcripts"]] == ["first line about budget", "second line"]
    assert details["transcripts"][1]["duration"] == 2.0

    page = (await client.get(f"/api/v1/meetings/{mid}/transcripts?limit=1&offset=0", headers=h)).json()
    assert page["total_count"] == 2 and page["has_more"] is True and len(page["transcripts"]) == 1

    hits = (await client.get("/api/v1/transcripts/search?q=BUDGET", headers=h)).json()
    assert len(hits) == 1 and hits[0]["id"] == mid and "budget" in hits[0]["matchContext"]

    notes = (await client.get(f"/api/v1/meetings/{mid}/notes", headers=h)).json()
    assert notes == {"meeting_id": mid, "notes_markdown": None, "notes_json": None, "updated_at": None}
    notes = (
        await client.put(f"/api/v1/meetings/{mid}/notes", json={"notes_markdown": "# n", "notes_json": "[]"}, headers=h)
    ).json()
    assert notes["notes_markdown"] == "# n" and notes["updated_at"]

    lang = (await client.put(f"/api/v1/meetings/{mid}/summary-language", json={"language": "zh"}, headers=h)).json()
    assert lang == {"language": "zh", "detected_language": None}
    lang = (
        await client.put(f"/api/v1/meetings/{mid}/summary-language", json={"detected_language": "en"}, headers=h)
    ).json()
    assert lang == {"language": "zh", "detected_language": "en"}

    assert (await client.delete(f"/api/v1/meetings/{mid}", headers=h)).status_code == 204
    assert (await client.get(f"/api/v1/meetings/{mid}", headers=h)).status_code == 404


async def test_user_isolation(client: httpx.AsyncClient) -> None:
    # 会话隔离由网关认证后的 X-User-ID 驱动；不同用户用不同头模拟。
    alice = user_headers("u-1", "alice")
    bob = user_headers("u-2", "bob")
    mid = (await client.post("/api/v1/meetings", json={"title": "Secret"}, headers=alice)).json()["id"]
    await client.post(
        f"/api/v1/meetings/{mid}/transcripts",
        json={"transcripts": [{"id": str(uuid.uuid4()), "text": "classified plan", "timestamp": "t"}]},
        headers=alice,
    )
    assert (await client.get("/api/v1/meetings", headers=bob)).json() == []
    for method, path in [
        ("GET", f"/api/v1/meetings/{mid}"),
        ("GET", f"/api/v1/meetings/{mid}/metadata"),
        ("GET", f"/api/v1/meetings/{mid}/transcripts"),
        ("GET", f"/api/v1/meetings/{mid}/summary"),
        ("GET", f"/api/v1/meetings/{mid}/notes"),
        ("GET", f"/api/v1/meetings/{mid}/audio"),
        ("DELETE", f"/api/v1/meetings/{mid}"),
    ]:
        r = await client.request(method, path, headers=bob)
        assert r.status_code == 404, (method, path, r.status_code)
    assert (await client.get("/api/v1/transcripts/search?q=classified", headers=bob)).json() == []
    assert len((await client.get("/api/v1/transcripts/search?q=classified", headers=alice)).json()) == 1


def _wav_bytes(seconds: float, sr: int = 16000) -> bytes:
    t = np.arange(int(seconds * sr)) / sr
    audio = (0.3 * np.sin(2 * np.pi * 220 * t)).astype(np.float32)
    buf = io.BytesIO()
    sf.write(buf, audio, sr, format="WAV", subtype="PCM_16")
    return buf.getvalue()


async def test_audio_upload_and_range(client: httpx.AsyncClient) -> None:
    h = user_headers()
    mid = (await client.post("/api/v1/meetings", json={"title": "A"}, headers=h)).json()["id"]
    assert (await client.get(f"/api/v1/meetings/{mid}/audio", headers=h)).status_code == 404
    wav = _wav_bytes(1.0)
    r = await client.put(
        f"/api/v1/meetings/{mid}/audio?filename=audio.wav", content=wav, headers={**h, "Content-Type": "audio/wav"}
    )
    assert r.status_code == 200
    body = r.json()
    assert body["size"] == len(wav) and abs(body["duration"] - 1.0) < 0.05
    meta = (await client.get(f"/api/v1/meetings/{mid}/metadata", headers=h)).json()
    assert meta["has_audio"] is True
    r = await client.get(f"/api/v1/meetings/{mid}/audio", headers={**h, "Range": "bytes=0-99"})
    assert r.status_code == 206 and len(r.content) == 100
