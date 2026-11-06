"""HTTP client for stt_ms (replaces the former in-process stt_registry calls)."""
from __future__ import annotations

import numpy as np

from meeting_ms.infrastructure.internal_client import client_for
from meeting_ms.stt.base import SttResult


class SttNotReady(Exception):
    """stt_ms reports no active model (HTTP 503)."""


class SttAudioError(Exception):
    """stt_ms rejected the audio payload (HTTP 400)."""


class SttUnavailable(Exception):
    """stt_ms could not be reached or returned an unexpected error."""


def _detail(response) -> str:  # noqa: ANN001 - httpx.Response
    try:
        return response.json().get("detail") or response.text
    except Exception:  # noqa: BLE001
        return response.text[:200]


class SttClient:
    async def status(self) -> dict:
        """Engine status incl. device and per-model download progress ({"models": [...]})."""
        try:
            async with client_for("stt", timeout=15) as client:
                r = await client.get("/status")
        except Exception as exc:  # noqa: BLE001
            raise SttUnavailable(f"stt_ms 无法访问：{exc}") from exc
        if r.status_code != 200:
            raise SttUnavailable(f"stt_ms 状态查询失败：{_detail(r)}")
        return r.json()

    async def ready(self) -> bool:
        try:
            status = await self.status()
        except SttUnavailable:
            return False
        return bool(status.get("ready"))

    @staticmethod
    def _raise_for_transcribe(status_code: int, detail: str) -> Exception:
        if status_code == 503:
            return SttNotReady(detail)
        if status_code == 400:
            return SttAudioError(detail)
        if status_code > 400:
            return SttUnavailable(detail)
        return SttUnavailable(f"stt_ms 返回异常状态 {status_code}")

    async def transcribe_pcm(self, data: bytes, language: str | None) -> SttResult:
        """Transcribe raw 16 kHz mono PCM16LE bytes."""
        try:
            async with client_for("stt", timeout=300) as client:
                r = await client.post(
                    "/transcribe", content=data, headers={"X-Audio-Format": "pcm16le"},
                    params={"language": language} if language else {},
                )
        except Exception as exc:  # noqa: BLE001
            raise SttUnavailable(f"stt_ms 无法访问：{exc}") from exc
        if r.status_code != 200:
            raise self._raise_for_transcribe(r.status_code, _detail(r))
        body = r.json()
        return SttResult(text=body.get("text") or "", confidence=body.get("confidence"), language=body.get("language"))

    async def transcribe_segment(self, audio: np.ndarray, language: str | None) -> SttResult:
        """Transcribe a float32 mono 16 kHz slice (sends PCM16LE to stt_ms)."""
        pcm = (np.clip(audio, -1.0, 1.0) * 32767.0).astype("<i2").tobytes()
        return await self.transcribe_pcm(pcm, language)

    async def models(self) -> list[dict]:
        try:
            async with client_for("stt", timeout=15) as client:
                r = await client.get("/models")
        except Exception as exc:  # noqa: BLE001
            raise SttUnavailable(f"stt_ms 无法访问：{exc}") from exc
        if r.status_code != 200:
            raise SttUnavailable(f"stt_ms 模型查询失败：{_detail(r)}")
        return r.json()
