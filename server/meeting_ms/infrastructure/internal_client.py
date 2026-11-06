"""Shared httpx client for service-to-service calls (internal token header included)."""
from __future__ import annotations

from typing import Literal

import httpx

from meeting_ms.config import get_settings

INTERNAL_TOKEN_HEADER = "X-Internal-Token"


def client_for(service: Literal["user", "stt"], timeout: float = 30.0) -> httpx.AsyncClient:
    settings = get_settings()
    if service not in {"user", "stt"}:
        raise ValueError("Unknown internal service")
    headers = {}
    if settings.internal_service_token:
        headers[INTERNAL_TOKEN_HEADER] = settings.internal_service_token
    # trust_env=False: service-to-service calls must never go through a host proxy.
    return httpx.AsyncClient(base_url=f"{settings.gateway_ms_url.rstrip('/')}/internal/{service}/",
                             timeout=timeout, headers=headers, trust_env=False)
