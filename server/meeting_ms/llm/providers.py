"""Active LLM provider resolution and serialization."""
from __future__ import annotations

from meeting_ms.db import settings_store
from meeting_ms.db.models import LlmProvider
from meeting_ms.db.session import session_factory
from meeting_ms.llm.client import LlmConfig
from meeting_ms.utils import iso, secret_box


def provider_dict(p: LlmProvider, active_id: str | None) -> dict:
    return {
        "id": p.id,
        "name": p.name,
        "base_url": p.base_url,
        "model": p.model,
        "api_key_set": bool(p.api_key_enc),
        "max_tokens": p.max_tokens,
        "temperature": p.temperature,
        "top_p": p.top_p,
        "context_tokens": p.context_tokens,
        "active": p.id == active_id,
        "created_at": iso(p.created_at),
    }


def provider_config(p: LlmProvider) -> LlmConfig:
    return LlmConfig(
        base_url=p.base_url,
        model=p.model,
        api_key=secret_box().decrypt(p.api_key_enc),
        max_tokens=p.max_tokens,
        temperature=p.temperature,
        top_p=p.top_p,
    )


async def active_provider_id() -> str | None:
    return await settings_store.get_setting(settings_store.ACTIVE_LLM_PROVIDER)


async def get_active_provider() -> LlmProvider | None:
    pid = await active_provider_id()
    if not pid:
        return None
    async with session_factory()() as session:
        return await session.get(LlmProvider, pid)


async def llm_status() -> dict:
    p = await get_active_provider()
    if p is None:
        return {"name": None, "model": None, "ready": False, "error": None}
    return {"name": p.name, "model": p.model, "ready": True, "error": None}
