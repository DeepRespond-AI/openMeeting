from __future__ import annotations

import importlib.util
from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from functools import lru_cache
from pathlib import Path

import numpy as np

SAMPLE_RATE = 16000


@dataclass(frozen=True)
class ModelSpec:
    id: str  # "<engine>:<name>"
    engine: str
    name: str
    display_name: str
    size_mb: int
    languages: str
    source: str | None = None  # "hf" | "modelscope" | None (remote)
    repo: str | None = None
    extra_repos: dict[str, str] = field(default_factory=dict)  # subdir -> repo
    remote: bool = False


@dataclass
class SttResult:
    text: str
    confidence: float | None = None
    language: str | None = None


class SttEngine(ABC):
    """A loaded STT model. All methods are blocking and run in a worker thread."""

    engine_name: str = ""

    @abstractmethod
    def load(self, spec: ModelSpec, path: Path | None) -> None: ...

    @abstractmethod
    def transcribe(self, audio: np.ndarray, language: str | None) -> SttResult:
        """`audio` is float32 mono 16 kHz in [-1, 1]; `language` None means auto-detect."""

    def unload(self) -> None:  # noqa: B027 - optional hook
        pass

    @property
    def device(self) -> str:
        return "cpu"


def normalize_language(language: str | None) -> str | None:
    if not language:
        return None
    lang = language.strip().lower().replace("_", "-")
    if lang in {"", "auto", "auto-translate"}:
        return None
    return lang.split("-")[0]


def module_available(name: str) -> bool:
    try:
        return importlib.util.find_spec(name) is not None
    except (ImportError, ValueError):
        return False


@lru_cache
def detect_device() -> str:
    """'cuda' when a CUDA device is usable by the installed inference stacks, else 'cpu'."""
    if module_available("ctranslate2"):
        try:
            import ctranslate2

            if ctranslate2.get_cuda_device_count() > 0:
                return "cuda"
        except Exception:  # noqa: BLE001
            pass
    if module_available("torch"):
        try:
            import torch

            if torch.cuda.is_available():
                return "cuda"
        except Exception:  # noqa: BLE001
            pass
    return "cpu"
