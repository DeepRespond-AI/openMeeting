"""stt_ms admin routes（/admin/api/stt/*）与 internal API（/internal/*）。

测试环境未设置 OPENMEETING_INTERNAL_SERVICE_TOKEN → require_internal 直接放行；
管理端 JWT 校验在网关，本服务的管理路由可直连访问。
"""
from __future__ import annotations

import io

import httpx
import numpy as np
import soundfile as sf

from stt_ms.stt.registry import stt_registry


def _wav(seconds: float = 0.5, freq: float = 300.0, sr: int = 16000) -> bytes:
    t = np.arange(int(seconds * sr)) / sr
    buf = io.BytesIO()
    sf.write(buf, (0.3 * np.sin(2 * np.pi * freq * t)).astype(np.float32), sr, format="WAV")
    return buf.getvalue()


def _pcm(seconds: float, silent: bool = False) -> bytes:
    n = int(seconds * 16000)
    if silent:
        return np.zeros(n, dtype="<i2").tobytes()
    t = np.arange(n) / 16000
    return (np.sin(2 * np.pi * 300 * t) * 8000).astype("<i2").tobytes()


# ------------------------------------------------------------------ admin routes


async def test_stt_activate_and_test(client: httpx.AsyncClient) -> None:
    models = (await client.get("/admin/api/stt/models")).json()
    ids = {m["id"] for m in models}
    assert {"faster-whisper:large-v3", "funasr:sensevoice-small", "cloud:default"} <= ids
    cloud = next(m for m in models if m["id"] == "cloud:default")
    assert cloud["remote"] is True and cloud["status"] == "not_downloaded"

    assert (await client.post("/admin/api/stt/activate", json={"model_id": "faster-whisper:tiny"})).status_code == 409
    assert (await client.post("/admin/api/stt/activate", json={"model_id": "cloud:default"})).status_code == 409

    r = await client.post("/admin/api/stt/activate", json={"model_id": "fake:test"})
    assert r.status_code == 200, r.text
    assert r.json() == {"engine": "fake", "model": "test", "ready": True, "error": None}
    assert stt_registry.model_id == "fake:test"
    active = [m for m in (await client.get("/admin/api/stt/models")).json() if m["active"]]
    assert [m["id"] for m in active] == ["fake:test"]

    r = await client.post("/admin/api/stt/test", files={"file": ("t.wav", _wav(), "audio/wav")}, data={"language": "zh"})
    assert r.status_code == 200, r.text
    assert r.json()["text"] == "segment 0.50s lang=zh" and r.json()["engine"] == "fake"

    assert (await client.delete("/admin/api/stt/models/fake:test")).status_code == 409


async def test_cloud_config_roundtrip(client: httpx.AsyncClient) -> None:
    cfg = (await client.get("/admin/api/stt/cloud-config")).json()
    assert cfg["api_key_set"] is False and cfg["mode"] == "openai"
    r = await client.put(
        "/admin/api/stt/cloud-config",
        json={"mode": "openai", "base_url": "https://asr.example/v1", "model": "whisper-1", "api_key": "k"},
    )
    assert r.json() == {"mode": "openai", "base_url": "https://asr.example/v1", "model": "whisper-1", "api_key_set": True}
    r = await client.put("/admin/api/stt/cloud-config", json={"mode": "dashscope", "base_url": "", "model": "paraformer-realtime-v2"})
    assert r.json()["api_key_set"] is True  # key kept when omitted
    cloud = next(m for m in (await client.get("/admin/api/stt/models")).json() if m["id"] == "cloud:default")
    assert cloud["status"] == "ready"


async def test_stt_engines(client: httpx.AsyncClient) -> None:
    engines = (await client.get("/admin/api/stt/engines")).json()
    assert {e["engine"] for e in engines} == {"faster-whisper", "funasr", "cloud"}


# ------------------------------------------------------------------ internal API（meeting_ms 消费）


async def test_internal_transcribe_pcm(client: httpx.AsyncClient, fake_stt) -> None:
    r = await client.post(
        "/internal/transcribe?language=zh", content=_pcm(1.5), headers={"X-Audio-Format": "pcm16le"}
    )
    assert r.status_code == 200, r.text
    body = r.json()
    assert body["text"] == "segment 1.50s lang=zh" and abs(body["confidence"] - 0.9) < 1e-6
    assert fake_stt.calls == 1


async def test_internal_transcribe_silence(client: httpx.AsyncClient, fake_stt) -> None:
    r = await client.post("/internal/transcribe", content=_pcm(1, silent=True), headers={"X-Audio-Format": "pcm16le"})
    assert r.status_code == 200
    assert r.json()["text"] == ""


async def test_internal_transcribe_wav(client: httpx.AsyncClient, fake_stt) -> None:
    r = await client.post("/internal/transcribe", content=_wav(1.0), headers={"X-Audio-Format": "wav"})
    assert r.status_code == 200, r.text
    assert r.json()["text"] == "segment 1.00s lang=auto"


async def test_internal_transcribe_rejects_bad_input(client: httpx.AsyncClient, fake_stt) -> None:
    # 空内容
    r = await client.post("/internal/transcribe", content=b"", headers={"X-Audio-Format": "pcm16le"})
    assert r.status_code == 400
    # 奇数字节数的 PCM16（网关侧 400 的来源）
    r = await client.post("/internal/transcribe", content=b"\x00", headers={"X-Audio-Format": "pcm16le"})
    assert r.status_code == 400 and "odd" in r.json()["detail"]
    # 不支持的格式
    r = await client.post("/internal/transcribe", content=_pcm(0.1), headers={"X-Audio-Format": "flac"})
    assert r.status_code == 400 and "flac" in r.json()["detail"]


async def test_internal_transcribe_requires_active_model(client: httpx.AsyncClient) -> None:
    stt_registry.clear()  # 防御：启动时的 restore 可能恢复了上次持久化的模型
    r = await client.post("/internal/transcribe", content=_pcm(0.1), headers={"X-Audio-Format": "pcm16le"})
    assert r.status_code == 503 and r.json()["detail"] == "语音识别模型未就绪"


async def test_internal_status_models_and_engines(client: httpx.AsyncClient, fake_stt) -> None:
    status = (await client.get("/internal/status")).json()
    assert status["ready"] is True and status["engine"] == "fake" and status["device"]

    models = (await client.get("/internal/models")).json()
    assert "fake:test" in {m["id"] for m in models}
    assert [m["id"] for m in models if m["active"]] == ["fake:test"]

    r = await client.post("/internal/models/fake:test/activate")
    assert r.status_code == 200
    assert r.json() == {"engine": "fake", "model": "test", "ready": True, "error": None}
    assert (await client.post("/internal/models/nope/activate")).status_code == 404

    engines = (await client.get("/internal/engines")).json()
    assert {e["engine"] for e in engines} == {"faster-whisper", "funasr", "cloud"}
