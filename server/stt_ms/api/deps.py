"""Downstream trust: only the gateway (holding the shared internal token) may call this service."""
from __future__ import annotations

import hmac

from fastapi import HTTPException, Request

from stt_ms.config import get_settings

INTERNAL_TOKEN_HEADER = "x-internal-token"


def require_internal(request: Request) -> None:
    """Reject any request that did not come through the gateway."""
    token = get_settings().internal_service_token
    if not token:
        return  # disabled (local dev); compose always sets it
    given = request.headers.get(INTERNAL_TOKEN_HEADER, "")
    if not given or not hmac.compare_digest(given, token):
        raise HTTPException(401, "缺少内部服务令牌")
