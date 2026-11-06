"""STT model catalog, downloads (HuggingFace / ModelScope) and on-disk state."""
from __future__ import annotations

import asyncio
import logging
import os
import shutil
from pathlib import Path

from sqlalchemy import select, update
from sqlalchemy.dialects.postgresql import insert

from stt_ms.config import get_settings
from stt_ms.db import settings_store
from stt_ms.db.models import SttModelRow
from stt_ms.db.session import session_factory
from stt_ms.monitor.events import broker
from stt_ms.stt.base import ModelSpec, module_available
from stt_ms.stt.cloud_engine import DEFAULT_CLOUD_CONFIG, CloudConfig
from stt_ms.utils import secret_box, utcnow

logger = logging.getLogger(__name__)

READY_MARKER = ".openmeeting_ready"

_CATALOG: list[ModelSpec] = [
    ModelSpec("faster-whisper:tiny", "faster-whisper", "tiny", "Whisper Tiny", 75, "multilingual", "hf", "Systran/faster-whisper-tiny"),
    ModelSpec("faster-whisper:base", "faster-whisper", "base", "Whisper Base", 145, "multilingual", "hf", "Systran/faster-whisper-base"),
    ModelSpec("faster-whisper:small", "faster-whisper", "small", "Whisper Small", 484, "multilingual", "hf", "Systran/faster-whisper-small"),
    ModelSpec("faster-whisper:medium", "faster-whisper", "medium", "Whisper Medium", 1530, "multilingual", "hf", "Systran/faster-whisper-medium"),
    ModelSpec("faster-whisper:large-v3", "faster-whisper", "large-v3", "Whisper Large v3", 3090, "multilingual", "hf", "Systran/faster-whisper-large-v3"),
    ModelSpec(
        "faster-whisper:large-v3-turbo", "faster-whisper", "large-v3-turbo", "Whisper Large v3 Turbo", 1620,
        "multilingual", "hf", "mobiuslabsgmbh/faster-whisper-large-v3-turbo",
    ),
    ModelSpec(
        "funasr:sensevoice-small", "funasr", "sensevoice-small", "SenseVoice Small", 900,
        "zh,en,yue,ja,ko", "modelscope", "iic/SenseVoiceSmall",
    ),
    ModelSpec(
        "funasr:paraformer-zh", "funasr", "paraformer-zh", "Paraformer 中文 (含标点)", 1240, "zh", "modelscope",
        "iic/speech_paraformer-large-vad-punc_asr_nat-zh-cn-16k-common-vocab8404-pytorch",
        extra_repos={"punc": "iic/punc_ct-transformer_zh-cn-common-vocab272727-pytorch"},
    ),
    ModelSpec("cloud:default", "cloud", "default", "云端语音识别", 0, "multilingual", None, None, remote=True),
]

_extra_specs: dict[str, ModelSpec] = {}
_download_tasks: dict[str, asyncio.Task] = {}


def register_spec(spec: ModelSpec) -> None:
    """Add a model to the catalog at runtime (used by tests / plugins)."""
    _extra_specs[spec.id] = spec


def catalog() -> list[ModelSpec]:
    return _CATALOG + list(_extra_specs.values())


def get_spec(model_id: str) -> ModelSpec | None:
    return next((s for s in catalog() if s.id == model_id), None)


def model_path(spec: ModelSpec) -> Path | None:
    if spec.remote:
        return None
    return get_settings().models_dir / spec.engine / spec.name


def is_downloaded(spec: ModelSpec) -> bool:
    path = model_path(spec)
    return path is not None and (path / READY_MARKER).exists()


def _dir_size(path: Path) -> int:
    if not path.exists():
        return 0
    return sum(f.stat().st_size for f in path.rglob("*") if f.is_file())


# ---------------------------------------------------------------- cloud config


async def load_cloud_config() -> CloudConfig:
    raw = await settings_store.get_setting(settings_store.STT_CLOUD_CONFIG) or {}
    merged = {**DEFAULT_CLOUD_CONFIG, **{k: v for k, v in raw.items() if v is not None}}
    return CloudConfig(
        mode=merged["mode"],
        base_url=merged["base_url"],
        model=merged["model"],
        api_key=secret_box().decrypt(raw.get("api_key_enc")),
    )


async def save_cloud_config(mode: str, base_url: str, model: str, api_key: str | None) -> CloudConfig:
    raw = await settings_store.get_setting(settings_store.STT_CLOUD_CONFIG) or {}
    raw.update({"mode": mode, "base_url": base_url, "model": model})
    if api_key is not None:
        raw["api_key_enc"] = secret_box().encrypt(api_key) if api_key else None
    await settings_store.set_setting(settings_store.STT_CLOUD_CONFIG, raw)
    return await load_cloud_config()


# ---------------------------------------------------------------- DB state


async def sync_catalog() -> None:
    """Ensure every catalog entry has a row and reconcile status with files on disk."""
    async with session_factory()() as session:
        rows = {r.id: r for r in (await session.execute(select(SttModelRow))).scalars()}
        for spec in catalog():
            if spec.remote:
                continue
            downloaded = is_downloaded(spec)
            row = rows.get(spec.id)
            if row is None:
                session.add(
                    SttModelRow(
                        id=spec.id, engine=spec.engine, name=spec.name, size_mb=spec.size_mb,
                        path=str(model_path(spec)), status="ready" if downloaded else "not_downloaded",
                        progress=100 if downloaded else 0, updated_at=utcnow(),
                    )
                )
                continue
            row.size_mb = spec.size_mb
            if downloaded:
                row.status, row.progress, row.error = "ready", 100, None
            elif row.status in ("ready", "downloading") and spec.id not in _download_tasks:
                row.status, row.progress = "not_downloaded", 0
        await session.commit()


async def list_models(active_model_id: str | None) -> list[dict]:
    async with session_factory()() as session:
        rows = {r.id: r for r in (await session.execute(select(SttModelRow))).scalars()}
    cloud = await load_cloud_config()
    return [_model_dict(spec, rows.get(spec.id), active_model_id, bool(cloud.api_key)) for spec in catalog()]


async def get_model_dict(model_id: str, active_model_id: str | None) -> dict | None:
    spec = get_spec(model_id)
    if spec is None:
        return None
    async with session_factory()() as session:
        row = await session.get(SttModelRow, model_id)
    cloud = await load_cloud_config()
    return _model_dict(spec, row, active_model_id, bool(cloud.api_key))


def _model_dict(spec: ModelSpec, row: SttModelRow | None, active: str | None, cloud_key: bool) -> dict:
    if spec.remote:
        ready = cloud_key or spec.engine != "cloud"
        status, progress, error = ("ready", 100, None) if ready else ("not_downloaded", 0, None)
    elif row is None:
        status, progress, error = "not_downloaded", 0, None
    else:
        status, progress, error = row.status, row.progress, row.error
    return {
        "id": spec.id,
        "engine": spec.engine,
        "name": spec.name,
        "display_name": spec.display_name,
        "size_mb": spec.size_mb,
        "languages": spec.languages,
        "status": status,
        "progress": progress,
        "error": error,
        "active": spec.id == active,
        "remote": spec.remote,
    }


async def _update_row(model_id: str, **values) -> None:
    async with session_factory()() as session:
        result = await session.execute(
            update(SttModelRow).where(SttModelRow.id == model_id).values(**values, updated_at=utcnow())
        )
        if result.rowcount == 0:
            spec = get_spec(model_id)
            if spec is not None:
                base = {"engine": spec.engine, "name": spec.name, "size_mb": spec.size_mb}
                await session.execute(
                    insert(SttModelRow).values(id=model_id, updated_at=utcnow(), **{**base, **values})
                    .on_conflict_do_nothing()
                )
        await session.commit()


async def _publish(model_id: str) -> None:
    from stt_ms.stt.registry import stt_registry

    data = await get_model_dict(model_id, stt_registry.model_id)
    if data:
        broker.publish("model-download", data)


# ---------------------------------------------------------------- download / delete


def download_dependency_error(spec: ModelSpec) -> str | None:
    if spec.source == "hf" and not module_available("huggingface_hub"):
        return "缺少依赖 huggingface_hub，请安装 whisper 扩展"
    if spec.source == "modelscope" and not module_available("modelscope"):
        return "缺少依赖 modelscope，请安装 funasr 扩展"
    return None


def _download_blocking(spec: ModelSpec, target: Path) -> None:
    from service_net.egress import configure_sdk_environment
    configure_sdk_environment(get_settings())
    target.mkdir(parents=True, exist_ok=True)
    if spec.source == "hf":
        # Plain HTTP downloads land in the target dir, which keeps size-based progress meaningful
        # (the Xet backend buffers chunks in a separate cache). Set HF_HUB_DISABLE_XET=0 to opt back in.
        os.environ.setdefault("HF_HUB_DISABLE_XET", "1")
        from huggingface_hub import snapshot_download

        snapshot_download(repo_id=spec.repo, local_dir=str(target))
    elif spec.source == "modelscope":
        from modelscope import snapshot_download as ms_download

        ms_download(spec.repo, local_dir=str(target))
        for subdir, repo in spec.extra_repos.items():
            ms_download(repo, local_dir=str(target / subdir))
    else:
        raise RuntimeError(f"model {spec.id} cannot be downloaded")
    (target / READY_MARKER).write_text("ok")


async def start_download(spec: ModelSpec) -> None:
    if spec.id in _download_tasks:
        return
    target = model_path(spec)
    assert target is not None
    await _update_row(spec.id, engine=spec.engine, name=spec.name, size_mb=spec.size_mb, path=str(target),
                      status="downloading", progress=0, error=None)
    _download_tasks[spec.id] = asyncio.create_task(_run_download(spec, target))
    await _publish(spec.id)


async def _run_download(spec: ModelSpec, target: Path) -> None:
    logger.info("Downloading STT model %s from %s:%s", spec.id, spec.source, spec.repo)
    worker = asyncio.create_task(asyncio.to_thread(_download_blocking, spec, target))
    expected = max(spec.size_mb, 1) * 1024 * 1024
    last = -1
    try:
        while not worker.done():
            await asyncio.wait({worker}, timeout=2.0)
            progress = min(99, int(_dir_size(target) * 100 / expected))
            if progress != last and not worker.done():
                last = progress
                await _update_row(spec.id, progress=progress)
                await _publish(spec.id)
        worker.result()
        await _update_row(spec.id, status="ready", progress=100, error=None)
        logger.info("STT model %s downloaded", spec.id)
    except Exception as exc:  # noqa: BLE001
        logger.exception("Download of %s failed", spec.id)
        await _update_row(spec.id, status="error", error=f"下载失败：{exc}"[:1000])
    finally:
        _download_tasks.pop(spec.id, None)
        await _publish(spec.id)


def is_downloading(model_id: str) -> bool:
    return model_id in _download_tasks


async def delete_model(spec: ModelSpec) -> None:
    path = model_path(spec)
    if path is not None and path.exists():
        await asyncio.to_thread(shutil.rmtree, path, True)
    await _update_row(spec.id, status="not_downloaded", progress=0, error=None)
    await _publish(spec.id)
