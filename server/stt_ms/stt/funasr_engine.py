from __future__ import annotations

import logging
import re
from pathlib import Path

import numpy as np

from stt_ms.stt.base import ModelSpec, SttEngine, SttResult, detect_device

logger = logging.getLogger(__name__)

_TAG_RE = re.compile(r"<\|[^|>]*\|>")
_SENSEVOICE_LANGS = {"zh", "en", "yue", "ja", "ko"}


def strip_sensevoice_tags(text: str) -> str:
    """Remove SenseVoice markers such as <|zh|><|NEUTRAL|><|Speech|><|withitn|>."""
    return _TAG_RE.sub("", text).strip()


class FunAsrEngine(SttEngine):
    engine_name = "funasr"

    def __init__(self) -> None:
        self._model = None
        self._spec: ModelSpec | None = None
        self._device = "cpu"

    def load(self, spec: ModelSpec, path: Path | None) -> None:
        from funasr import AutoModel

        if path is None or not path.exists():
            raise RuntimeError(f"model files not found for {spec.id}")
        self._device = "cuda:0" if detect_device() == "cuda" else "cpu"
        kwargs: dict = {"model": str(path), "device": self._device, "disable_update": True}
        punc = path / "punc"
        if spec.name == "paraformer-zh" and punc.exists():
            kwargs["punc_model"] = str(punc)
        logger.info("Loading FunASR %s on %s", spec.name, self._device)
        self._model = AutoModel(**kwargs)
        self._spec = spec

    def transcribe(self, audio: np.ndarray, language: str | None) -> SttResult:
        if self._model is None or self._spec is None:
            raise RuntimeError("model not loaded")
        if self._spec.name == "sensevoice-small":
            lang = language if language in _SENSEVOICE_LANGS else "auto"
            res = self._model.generate(
                input=audio, cache={}, language=lang, use_itn=True, batch_size_s=60, disable_pbar=True
            )
        else:
            res = self._model.generate(input=audio, cache={}, batch_size_s=300, disable_pbar=True)
        text = " ".join(strip_sensevoice_tags(r.get("text", "")) for r in (res or [])).strip()
        return SttResult(text=text, confidence=None, language=language)

    def unload(self) -> None:
        self._model = None

    @property
    def device(self) -> str:
        return "cuda" if self._device.startswith("cuda") else "cpu"
