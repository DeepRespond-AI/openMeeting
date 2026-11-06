from __future__ import annotations

import asyncio
import tempfile
import time
from pathlib import Path

from fastapi import APIRouter, File, Form, HTTPException, Response, UploadFile
from pydantic import BaseModel

from stt_ms.stt import model_store
from stt_ms.stt.audio import AudioDecodeError, decode_file
from stt_ms.stt.base import normalize_language
from stt_ms.stt.registry import SttNotReady, stt_registry

router = APIRouter(prefix="/stt", tags=["admin-stt"])


@router.get("/engines")
async def engines() -> list[dict]:
    return stt_registry.engines()


@router.get("/models")
async def models() -> list[dict]:
    return await model_store.list_models(stt_registry.model_id)


@router.post("/models/{model_id}/download")
async def download(model_id: str) -> dict:
    spec = model_store.get_spec(model_id)
    if spec is None:
        raise HTTPException(404, "模型不存在")
    if spec.remote:
        raise HTTPException(409, "云端模型无需下载")
    if error := model_store.download_dependency_error(spec):
        raise HTTPException(409, error)
    if not model_store.is_downloaded(spec):
        await model_store.start_download(spec)
    result = await model_store.get_model_dict(model_id, stt_registry.model_id)
    assert result is not None
    return result


@router.delete("/models/{model_id}", status_code=204)
async def delete(model_id: str) -> Response:
    spec = model_store.get_spec(model_id)
    if spec is None:
        raise HTTPException(404, "模型不存在")
    if spec.remote:
        raise HTTPException(409, "云端模型无法删除")
    if stt_registry.model_id == model_id:
        raise HTTPException(409, "不能删除当前正在使用的模型")
    if model_store.is_downloading(model_id):
        raise HTTPException(409, "模型正在下载中")
    await model_store.delete_model(spec)
    return Response(status_code=204)


class ActivateIn(BaseModel):
    model_id: str


@router.post("/activate")
async def activate(body: ActivateIn) -> dict:
    spec = model_store.get_spec(body.model_id)
    if spec is None:
        raise HTTPException(404, "模型不存在")
    if spec.engine == "cloud":
        cfg = await model_store.load_cloud_config()
        if not cfg.api_key:
            raise HTTPException(409, "请先配置云端识别的 API Key")
    elif not spec.remote and not model_store.is_downloaded(spec):
        raise HTTPException(409, "模型尚未下载")
    try:
        return await stt_registry.activate(body.model_id)
    except Exception as exc:  # noqa: BLE001
        raise HTTPException(500, f"模型加载失败：{exc}") from exc


@router.post("/test")
async def test(file: UploadFile = File(...), language: str | None = Form(None)) -> dict:
    if not stt_registry.ready:
        raise HTTPException(503, "语音识别模型未就绪")
    suffix = Path(file.filename or "audio").suffix or ".bin"
    with tempfile.NamedTemporaryFile(suffix=suffix, delete=False) as tmp:
        while chunk := await file.read(1024 * 1024):
            tmp.write(chunk)
        tmp_path = Path(tmp.name)
    try:
        try:
            audio = await asyncio.to_thread(decode_file, tmp_path)
        except AudioDecodeError as exc:
            raise HTTPException(400, f"无法解码音频：{exc}") from exc
    finally:
        tmp_path.unlink(missing_ok=True)
    t0 = time.monotonic()
    try:
        result = await stt_registry.transcribe(audio, normalize_language(language))
    except SttNotReady as exc:
        raise HTTPException(503, "语音识别模型未就绪") from exc
    except Exception as exc:  # noqa: BLE001
        raise HTTPException(500, f"转写失败：{exc}") from exc
    elapsed = int((time.monotonic() - t0) * 1000)
    status = stt_registry.status()
    return {"text": result.text, "elapsed_ms": elapsed, "engine": status["engine"], "model": status["model"]}


class CloudConfigIn(BaseModel):
    mode: str
    base_url: str
    model: str
    api_key: str | None = None


def _cloud_dict(cfg) -> dict:
    return {"mode": cfg.mode, "base_url": cfg.base_url, "model": cfg.model, "api_key_set": bool(cfg.api_key)}


@router.get("/cloud-config")
async def get_cloud_config() -> dict:
    return _cloud_dict(await model_store.load_cloud_config())


@router.put("/cloud-config")
async def put_cloud_config(body: CloudConfigIn) -> dict:
    if body.mode not in ("openai", "dashscope"):
        raise HTTPException(400, "mode 只能是 openai 或 dashscope")
    api_key = body.api_key if "api_key" in body.model_fields_set else None
    cfg = await model_store.save_cloud_config(body.mode, body.base_url.strip(), body.model.strip(), api_key)
    # Reload the cloud engine so the new configuration takes effect immediately.
    if stt_registry.model_id == "cloud:default" and cfg.api_key:
        try:
            await stt_registry.activate("cloud:default")
        except Exception as exc:  # noqa: BLE001
            raise HTTPException(500, f"云端配置已保存，但重新加载失败：{exc}") from exc
    return _cloud_dict(cfg)
