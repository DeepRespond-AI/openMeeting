"""Downstream trust: identity comes from gateway-injected headers; direct calls need the internal token."""
from __future__ import annotations

import hmac
from dataclasses import dataclass
from urllib.parse import unquote

from fastapi import HTTPException, Request

from user_ms.config import get_settings

INTERNAL_TOKEN_HEADER = "x-internal-token"


def require_internal(request: Request) -> None:
    """Reject any request that did not come through the gateway."""
    token = get_settings().internal_service_token
    if not token:
        return  # disabled (local dev); compose always sets it
    given = request.headers.get(INTERNAL_TOKEN_HEADER, "")
    if not given or not hmac.compare_digest(given, token):
        raise HTTPException(401, "缺少内部服务令牌")


@dataclass(frozen=True)
class AuthContext:
    """Identity as resolved by the gateway and injected via X-User-* headers."""

    user_id: str
    user_name: str
    user_phone: str | None
    session_id: str
    token_hash: str = ""


def require_client(request: Request) -> AuthContext:
    """Identity for client endpoints — always present because the gateway authenticated the request."""
    user_id = request.headers.get("x-user-id", "")
    if not user_id:
        raise HTTPException(401, "未登录，请先使用手机号登录")
    return AuthContext(
        user_id=user_id,
        # The gateway percent-encodes the display name (HTTP headers are ASCII-only).
        user_name=unquote(request.headers.get("x-user-name", "")),
        user_phone=request.headers.get("x-user-phone") or None,
        session_id=request.headers.get("x-session-id", ""),
    )


def optional_user_id(request: Request) -> str | None:
    """User of a valid bearer token as resolved by the gateway, or None on public endpoints."""
    return request.headers.get("x-user-id") or None
