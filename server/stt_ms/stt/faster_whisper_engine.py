from __future__ import annotations

import logging
import math
from pathlib import Path

import numpy as np

from stt_ms.stt.base import ModelSpec, SttEngine, SttResult

logger = logging.getLogger(__name__)

_NO_SPACE_LANGS = {"zh", "ja", "yue"}


class FasterWhisperEngine(SttEngine):
    engine_name = "faster-whisper"

    def __init__(self) -> None:
        self._model = None
        self._device = "cpu"

    def load(self, spec: ModelSpec, path: Path | None) -> None:
        import ctranslate2
        from faster_whisper import WhisperModel

        if path is None or not path.exists():
            raise RuntimeError(f"model files not found for {spec.id}")
        if ctranslate2.get_cuda_device_count() > 0:
            self._device, compute_type = "cuda", "float16"
        else:
            self._device, compute_type = "cpu", "int8"
        logger.info("Loading faster-whisper %s on %s (%s)", spec.name, self._device, compute_type)
        self._model = WhisperModel(str(path), device=self._device, compute_type=compute_type)

    def transcribe(self, audio: np.ndarray, language: str | None) -> SttResult:
        if self._model is None:
            raise RuntimeError("model not loaded")
        segments, info = self._model.transcribe(
            audio,
            language=language,
            beam_size=5,
            vad_filter=False,  # live segments are already VAD-split by the client
            condition_on_previous_text=False,
            # Nudges Whisper towards Simplified Chinese output instead of Traditional.
            initial_prompt="以下是普通话的句子。" if language == "zh" else None,
        )
        texts: list[str] = []
        logprobs: list[float] = []
        for seg in segments:
            if seg.text.strip():
                texts.append(seg.text.strip())
                logprobs.append(seg.avg_logprob)
        detected = language or getattr(info, "language", None)
        text = ("" if detected in _NO_SPACE_LANGS else " ").join(texts).strip()
        confidence = math.exp(sum(logprobs) / len(logprobs)) if logprobs else None
        return SttResult(text=text, confidence=confidence, language=getattr(info, "language", None))

    def unload(self) -> None:
        self._model = None

    @property
    def device(self) -> str:
        return self._device
