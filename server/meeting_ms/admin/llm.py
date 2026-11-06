from __future__ import annotations

import time

from fastapi import APIRouter, Depends, HTTPException, Response
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from meeting_ms.db import settings_store
from meeting_ms.db.models import LlmProvider
from meeting_ms.db.session import get_session
from meeting_ms.llm import client as llm_client
from meeting_ms.llm.providers import active_provider_id, llm_status, provider_config, provider_dict
from meeting_ms.monitor.events import broker
from meeting_ms.utils import new_uuid, secret_box, utcnow

router = APIRouter(prefix="/llm", tags=["admin-llm"])


class ProviderIn(BaseModel):
    name: str = Field(min_length=1)
    base_url: str = Field(min_length=1)
    model: str = Field(min_length=1)
    api_key: str | None = None
    max_tokens: int | None = None
    temperature: float | None = None
    top_p: float | None = None
    context_tokens: int | None = Field(default=None, ge=1000)


async def _get(session: AsyncSession, provider_id: str) -> LlmProvider:
    p = await session.get(LlmProvider, provider_id)
    if p is None:
        raise HTTPException(404, "大模型配置不存在")
    return p


def _apply(p: LlmProvider, body: ProviderIn) -> None:
    p.name = body.name.strip()
    p.base_url = body.base_url.strip().rstrip("/")
    p.model = body.model.strip()
    p.max_tokens = body.max_tokens
    p.temperature = body.temperature
    p.top_p = body.top_p
    p.context_tokens = body.context_tokens or 32000
    if "api_key" in body.model_fields_set and body.api_key is not None:
        p.api_key_enc = secret_box().encrypt(body.api_key) if body.api_key else None


@router.get("/providers")
async def list_providers(session: AsyncSession = Depends(get_session)) -> list[dict]:
    active = await active_provider_id()
    rows = (await session.execute(select(LlmProvider).order_by(LlmProvider.created_at))).scalars().all()
    return [provider_dict(p, active) for p in rows]


@router.post("/providers")
async def create_provider(body: ProviderIn, session: AsyncSession = Depends(get_session)) -> dict:
    p = LlmProvider(id=new_uuid(), created_at=utcnow(), enabled=True)
    _apply(p, body)
    session.add(p)
    await session.commit()
    active = await active_provider_id()
    if active is None:
        # First provider becomes active automatically.
        await settings_store.set_setting(settings_store.ACTIVE_LLM_PROVIDER, p.id)
        active = p.id
        broker.publish("llm", await llm_status())
    return provider_dict(p, active)


@router.put("/providers/{provider_id}")
async def update_provider(provider_id: str, body: ProviderIn, session: AsyncSession = Depends(get_session)) -> dict:
    p = await _get(session, provider_id)
    _apply(p, body)
    await session.commit()
    active = await active_provider_id()
    if active == p.id:
        broker.publish("llm", await llm_status())
    return provider_dict(p, active)


@router.delete("/providers/{provider_id}", status_code=204)
async def delete_provider(provider_id: str, session: AsyncSession = Depends(get_session)) -> Response:
    p = await _get(session, provider_id)
    await session.delete(p)
    await session.commit()
    if await active_provider_id() == provider_id:
        await settings_store.set_setting(settings_store.ACTIVE_LLM_PROVIDER, None)
        broker.publish("llm", await llm_status())
    return Response(status_code=204)


@router.post("/providers/{provider_id}/test")
async def test_provider(provider_id: str, session: AsyncSession = Depends(get_session)) -> dict:
    p = await _get(session, provider_id)
    cfg = provider_config(p)
    t0 = time.monotonic()
    try:
        completion = await llm_client.chat_completion(
            cfg, "You are a connectivity test. Reply briefly.", "Reply with the single word: OK"
        )
        from meeting_ms.summary.processor import clean_llm_markdown

        reply = clean_llm_markdown(completion.content).markdown
        return {"ok": True, "elapsed_ms": int((time.monotonic() - t0) * 1000), "reply": reply[:500], "error": None}
    except llm_client.LlmError as exc:
        return {"ok": False, "elapsed_ms": int((time.monotonic() - t0) * 1000), "reply": None, "error": str(exc)}


@router.post("/providers/{provider_id}/activate")
async def activate_provider(provider_id: str, session: AsyncSession = Depends(get_session)) -> dict:
    await _get(session, provider_id)
    await settings_store.set_setting(settings_store.ACTIVE_LLM_PROVIDER, provider_id)
    status = await llm_status()
    broker.publish("llm", status)
    return status


@router.get("/providers/{provider_id}/models")
async def provider_models(provider_id: str, session: AsyncSession = Depends(get_session)) -> list[str]:
    p = await _get(session, provider_id)
    return await llm_client.list_models(p.base_url, secret_box().decrypt(p.api_key_enc))


class ModelsProbeIn(BaseModel):
    base_url: str
    api_key: str | None = None
    provider_id: str | None = None


@router.post("/models-probe")
async def models_probe(body: ModelsProbeIn, session: AsyncSession = Depends(get_session)) -> list[str]:
    api_key = body.api_key
    if api_key is None and body.provider_id:
        p = await session.get(LlmProvider, body.provider_id)
        if p is not None:
            api_key = secret_box().decrypt(p.api_key_enc)
    return await llm_client.list_models(body.base_url.strip(), api_key)
