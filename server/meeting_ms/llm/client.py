"""OpenAI-compatible chat completions client (relay services, Aliyun Bailian compatible-mode, ...)."""
from __future__ import annotations

import logging
from dataclasses import dataclass

import httpx
from meeting_ms.config import get_settings
from service_net.egress import async_client

logger = logging.getLogger(__name__)

REQUEST_TIMEOUT_SEC = 300.0


class LlmError(Exception):
    pass


@dataclass(frozen=True)
class LlmConfig:
    base_url: str
    model: str
    api_key: str | None = None
    max_tokens: int | None = None
    temperature: float | None = None
    top_p: float | None = None


@dataclass
class LlmCompletion:
    content: str
    reasoning_stripped: bool


def _headers(api_key: str | None) -> dict[str, str]:
    return {"Authorization": f"Bearer {api_key}"} if api_key else {}


def build_chat_body(cfg: LlmConfig, system_prompt: str, user_prompt: str) -> dict:
    body: dict = {
        "model": cfg.model,
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt},
        ],
    }
    if cfg.max_tokens is not None:
        body["max_tokens"] = cfg.max_tokens
    if cfg.temperature is not None:
        body["temperature"] = cfg.temperature
    if cfg.top_p is not None:
        body["top_p"] = cfg.top_p
    return body


async def chat_completion(cfg: LlmConfig, system_prompt: str, user_prompt: str) -> LlmCompletion:
    """POST {base_url}/chat/completions. Cancellation = cancel the awaiting task."""
    url = cfg.base_url.rstrip("/") + "/chat/completions"
    try:
        async with async_client(get_settings(), timeout=REQUEST_TIMEOUT_SEC) as client:
            resp = await client.post(url, headers=_headers(cfg.api_key), json=build_chat_body(cfg, system_prompt, user_prompt))
    except httpx.TimeoutException as exc:
        raise LlmError(f"LLM request timed out after {int(REQUEST_TIMEOUT_SEC)} seconds") from exc
    except httpx.HTTPError as exc:
        raise LlmError(f"Failed to send request to LLM: {exc}") from exc
    if resp.status_code >= 400:
        raise LlmError(f"LLM API request failed with status {resp.status_code}: {resp.text[:1000]}")
    try:
        data = resp.json()
        message = data["choices"][0]["message"]
    except (ValueError, KeyError, IndexError, TypeError) as exc:
        raise LlmError(f"Failed to parse LLM response: {resp.text[:500]}") from exc
    reasoning = [message.get("reasoning"), message.get("reasoning_content")]
    return LlmCompletion(
        content=(message.get("content") or "").strip(),
        reasoning_stripped=any(isinstance(r, str) and r.strip() for r in reasoning),
    )


async def list_models(base_url: str, api_key: str | None) -> list[str]:
    """Proxy GET {base_url}/models; empty list on any failure."""
    try:
        async with async_client(get_settings(), timeout=20) as client:
            resp = await client.get(base_url.rstrip("/") + "/models", headers=_headers(api_key))
        resp.raise_for_status()
        items = resp.json().get("data", [])
        return sorted({str(i["id"]) for i in items if isinstance(i, dict) and i.get("id")})
    except Exception as exc:  # noqa: BLE001
        logger.info("Listing models from %s failed: %s", base_url, exc)
        return []
