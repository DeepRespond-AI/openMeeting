from __future__ import annotations

from fastapi import APIRouter, Depends, Request

from meeting_ms import SERVER_VERSION
from meeting_ms.api.deps import AuthContext, require_client
from meeting_ms.infrastructure.stt_client import SttClient, SttUnavailable
from meeting_ms.llm.providers import llm_status

router = APIRouter(prefix="/client", tags=["client"])


def get_stt_client(request: Request) -> SttClient:
    return SttClient()


@router.get("/capabilities")
async def capabilities(
    ctx: AuthContext = Depends(require_client), stt: SttClient = Depends(get_stt_client)
) -> dict:
    try:
        status = await stt.status()
        stt_status = {k: status.get(k) for k in ("engine", "model", "ready", "error")}
    except SttUnavailable as exc:
        stt_status = {"engine": None, "model": None, "ready": False, "error": str(exc)}
    return {
        "server_version": SERVER_VERSION,
        "user": {"id": ctx.user_id, "name": ctx.user_name, "phone": ctx.user_phone},
        "stt": stt_status,
        "llm": await llm_status(),
    }
