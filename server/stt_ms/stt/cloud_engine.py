"""Cloud ASR engine.

Modes:
- ``openai``: OpenAI-compatible ``POST {base_url}/audio/transcriptions`` (multipart WAV + ``model``),
  works with OpenAI, Groq, SiliconFlow, most relay services, local whisper servers, etc.
- ``dashscope``: Aliyun Bailian (DashScope) Paraformer via the ``dashscope`` SDK
  (``dashscope.audio.asr.Recognition``, e.g. model ``paraformer-realtime-v2``). ``base_url``,
  when set, overrides the SDK websocket endpoint (e.g. ``wss://dashscope-intl.aliyuncs.com/api-ws/v1/inference``).
"""
from __future__ import annotations

import logging
import os
import tempfile
from dataclasses import dataclass
from pathlib import Path

import numpy as np
from service_net.egress import configure_sdk_environment, sync_client
from stt_ms.config import get_settings

from stt_ms.stt.audio import float32_to_wav_bytes
from stt_ms.stt.base import SAMPLE_RATE, ModelSpec, SttEngine, SttResult

logger = logging.getLogger(__name__)

DEFAULT_CLOUD_CONFIG = {"mode": "openai", "base_url": "https://api.openai.com/v1", "model": "whisper-1"}


@dataclass(frozen=True)
class CloudConfig:
    mode: str
    base_url: str
    model: str
    api_key: str | None


class CloudEngine(SttEngine):
    engine_name = "cloud"

    def __init__(self, config: CloudConfig) -> None:
        self.config = config

    def load(self, spec: ModelSpec, path: Path | None) -> None:
        if not self.config.api_key:
            raise RuntimeError("cloud ASR api key is not configured")
        if self.config.mode == "dashscope":
            import dashscope  # noqa: F401 - fail early if the SDK is missing
        elif self.config.mode != "openai":
            raise RuntimeError(f"unknown cloud mode {self.config.mode}")

    def transcribe(self, audio: np.ndarray, language: str | None) -> SttResult:
        if self.config.mode == "dashscope":
            return self._dashscope(audio, language)
        return self._openai(audio, language)

    def _openai(self, audio: np.ndarray, language: str | None) -> SttResult:
        data: dict[str, str] = {"model": self.config.model, "response_format": "json"}
        if language:
            data["language"] = language
        url = self.config.base_url.rstrip("/") + "/audio/transcriptions"
        with sync_client(get_settings(), timeout=120) as client:
            resp = client.post(
                url, headers={"Authorization": f"Bearer {self.config.api_key}"}, data=data,
                files={"file": ("audio.wav", float32_to_wav_bytes(audio), "audio/wav")},
            )
        if resp.status_code >= 400:
            raise RuntimeError(f"cloud ASR HTTP {resp.status_code}: {resp.text[:300]}")
        try:
            text = resp.json().get("text", "")
        except ValueError:
            text = resp.text
        return SttResult(text=(text or "").strip(), confidence=None, language=language)

    def _dashscope(self, audio: np.ndarray, language: str | None) -> SttResult:
        configure_sdk_environment(get_settings())
        import dashscope
        from dashscope.audio.asr import Recognition

        dashscope.api_key = self.config.api_key
        if self.config.base_url and self.config.base_url.startswith("ws"):
            dashscope.base_websocket_api_url = self.config.base_url
        kwargs = {}
        if language:
            kwargs["language_hints"] = [language]
        recognizer = Recognition(
            model=self.config.model or "paraformer-realtime-v2",
            format="wav",
            sample_rate=SAMPLE_RATE,
            callback=None,
            **kwargs,
        )
        fd, tmp = tempfile.mkstemp(suffix=".wav")
        try:
            with os.fdopen(fd, "wb") as fh:
                fh.write(float32_to_wav_bytes(audio))
            result = recognizer.call(tmp)
        finally:
            os.unlink(tmp)
        if getattr(result, "status_code", 200) != 200:
            raise RuntimeError(f"DashScope ASR error: {getattr(result, 'message', result)}")
        sentences = result.get_sentence() or []
        if isinstance(sentences, dict):
            sentences = [sentences]
        text = "".join(s.get("text", "") for s in sentences)
        return SttResult(text=text.strip(), confidence=None, language=language)
