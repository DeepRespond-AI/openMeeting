"""Internal API consumed by meeting_ms (auth via the shared internal token, enforced on the parent router)."""
from __future__ import annotations

from fastapi import APIRouter, Header, HTTPException, Request
from pydantic import BaseModel

from stt_ms.stt import model_store
from stt_ms.stt.audio import AudioDecodeError, pcm16le_to_float32
from stt_ms.stt.base import SAMPLE_RATE, normalize_language
from stt_ms.stt.registry import SttNotReady, stt_registry

router = APIRouter()

MAX_AUDIO_BYTES = 600 * SAMPLE_RATE * 2  # hard cap: ~6 minutes of PCM16 per call


@router.get("/status")
async def status() -> dict:
    return {"device": stt_registry.device, **stt_registry.status()}


@router.get("/models")
async def models() -> list[dict]:
    return await model_store.list_models(stt_registry.model_id)


@router.post("/models/{model_id}/activate")
async def activate_model(model_id: str) -> dict:
    spec = model_store.get_spec(model_id)
    if spec is None:
        raise HTTPException(404, "模型不存在")
    try:
        return await stt_registry.activate(model_id)
    except Exception as exc:  # noqa: BLE001
        raise HTTPException(500, f"模型加载失败：{exc}") from exc


async def _audio_from_body(request: Request, audio_format: str):
    body = await request.body()
    if not body:
        raise HTTPException(400, "音频内容为空")
    if len(body) > MAX_AUDIO_BYTES:
        raise HTTPException(413, "音频过长")
    if audio_format == "wav":
        import io

        import soundfile as sf

        try:
            data, sr = sf.read(io.BytesIO(body), dtype="float32", always_2d=True)
        except Exception as exc:  # noqa: BLE001
            raise HTTPException(400, f"无法解码音频：{exc}") from exc
        return data.mean(axis=1).astype("float32")
    if audio_format in ("", "pcm16le"):
        try:
            return pcm16le_to_float32(body)
        except AudioDecodeError as exc:
            raise HTTPException(400, str(exc)) from exc
    raise HTTPException(400, f"不支持的音频格式：{audio_format}")


@router.post("/transcribe")
async def transcribe(
    request: Request,
    language: str | None = None,
    x_audio_format: str = Header("", alias="X-Audio-Format"),
) -> dict:
    audio = await _audio_from_body(request, (x_audio_format or "").strip().lower())
    try:
        result = await stt_registry.transcribe(audio, normalize_language(language))
    except SttNotReady as exc:
        raise HTTPException(503, "语音识别模型未就绪") from exc
    except Exception as exc:  # noqa: BLE001
        raise HTTPException(500, f"转写失败：{exc}") from exc
    return {"text": result.text, "confidence": result.confidence, "language": result.language}


class EngineInfo(BaseModel):
    name: str


@router.get("/engines")
async def engines() -> list[dict]:
    return stt_registry.engines()
