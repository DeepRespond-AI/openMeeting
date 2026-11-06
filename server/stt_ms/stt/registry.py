"""Single active STT engine with hot swap and bounded concurrent inference."""
from __future__ import annotations

import asyncio
import logging
from collections.abc import Awaitable, Callable

import numpy as np

from stt_ms.db import settings_store
from stt_ms.monitor.events import broker
from stt_ms.stt import model_store
from stt_ms.stt.base import ModelSpec, SttEngine, SttResult, detect_device, module_available

logger = logging.getLogger(__name__)

EngineFactory = Callable[[ModelSpec], Awaitable[SttEngine]]


async def _faster_whisper_factory(spec: ModelSpec) -> SttEngine:
    from stt_ms.stt.faster_whisper_engine import FasterWhisperEngine

    return FasterWhisperEngine()


async def _funasr_factory(spec: ModelSpec) -> SttEngine:
    from stt_ms.stt.funasr_engine import FunAsrEngine

    return FunAsrEngine()


async def _cloud_factory(spec: ModelSpec) -> SttEngine:
    from stt_ms.stt.cloud_engine import CloudEngine

    return CloudEngine(await model_store.load_cloud_config())


class SttNotReady(Exception):
    pass


class SttRegistry:
    def __init__(self) -> None:
        self._factories: dict[str, EngineFactory] = {
            "faster-whisper": _faster_whisper_factory,
            "funasr": _funasr_factory,
            "cloud": _cloud_factory,
        }
        self._engine: SttEngine | None = None
        self._spec: ModelSpec | None = None
        self._error: str | None = None
        self._loading: str | None = None
        self._lock = asyncio.Lock()
        self._sem = asyncio.Semaphore(1)

    def configure(self, concurrency: int) -> None:
        self._sem = asyncio.Semaphore(max(1, concurrency))

    def register_engine(self, engine: str, factory: EngineFactory) -> None:
        self._factories[engine] = factory

    @property
    def model_id(self) -> str | None:
        return self._spec.id if self._spec else None

    @property
    def ready(self) -> bool:
        return self._engine is not None

    @property
    def device(self) -> str:
        if self._engine is not None and self._spec and not self._spec.remote:
            return self._engine.device
        return detect_device()

    def status(self) -> dict:
        spec = self._spec
        if spec is None and self._loading:
            spec = model_store.get_spec(self._loading)
        return {
            "engine": spec.engine if spec else None,
            "model": spec.name if spec else None,
            "ready": self._engine is not None,
            "error": self._error,
        }

    def engines(self) -> list[dict]:
        out = []
        checks = {
            "faster-whisper": ("faster_whisper", "未安装 faster-whisper（安装 whisper 扩展）"),
            "funasr": ("funasr", "未安装 funasr（安装 funasr 扩展）"),
        }
        for name in ("faster-whisper", "funasr", "cloud"):
            if name in checks:
                module, reason = checks[name]
                ok = module_available(module)
                out.append({"engine": name, "available": ok, "reason": None if ok else reason})
            else:
                out.append({"engine": name, "available": True, "reason": None})
        return out

    async def activate(self, model_id: str, persist: bool = True) -> dict:
        """Load the new model, then swap it in. On failure keep the old engine and raise."""
        spec = model_store.get_spec(model_id)
        if spec is None:
            raise ValueError(f"unknown model {model_id}")
        factory = self._factories.get(spec.engine)
        if factory is None:
            raise ValueError(f"engine {spec.engine} not available")
        async with self._lock:
            self._loading = model_id
            broker.publish("stt", self.status())
            try:
                engine = await factory(spec)
                await asyncio.to_thread(engine.load, spec, model_store.model_path(spec))
            except Exception as exc:
                logger.exception("Failed to load STT model %s", model_id)
                if self._engine is None:
                    self._error = f"模型加载失败：{exc}"
                raise
            finally:
                self._loading = None
            old = self._engine
            self._engine, self._spec, self._error = engine, spec, None
            if old is not None:
                # In-flight requests hold their own reference; drop ours.
                await asyncio.to_thread(old.unload)
            logger.info("Active STT model is now %s", model_id)
        if persist:
            await settings_store.set_setting(settings_store.ACTIVE_STT_MODEL, model_id)
        broker.publish("stt", self.status())
        return self.status()

    def install(self, engine: SttEngine, spec: ModelSpec) -> None:
        """Directly install a loaded engine (tests)."""
        self._engine, self._spec, self._error = engine, spec, None

    def clear(self) -> None:
        if self._engine is not None:
            self._engine.unload()
        self._engine, self._spec, self._error = None, None, None

    async def restore(self) -> None:
        model_id = await settings_store.get_setting(settings_store.ACTIVE_STT_MODEL)
        if not model_id or self._engine is not None:
            return
        try:
            await self.activate(model_id, persist=False)
        except Exception as exc:  # noqa: BLE001
            self._error = f"模型加载失败：{exc}"
            # Remember which model should be active even though it failed to load.
            self._spec = None
            broker.publish("stt", self.status())

    async def transcribe(self, audio: np.ndarray, language: str | None) -> SttResult:
        engine = self._engine
        if engine is None:
            raise SttNotReady()
        async with self._sem:
            return await asyncio.to_thread(engine.transcribe, audio, language)


stt_registry = SttRegistry()
