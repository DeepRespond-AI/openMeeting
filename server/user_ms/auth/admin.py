"""Admin session: password login -> HS256 JWT (cookie `openmeeting_admin` or Bearer)."""
from __future__ import annotations

import hashlib
import hmac
from datetime import timedelta

import jwt
from fastapi import HTTPException, Request

from user_ms.auth.sessions import bearer_from_request
from user_ms.config import get_settings
from user_ms.utils import utcnow

COOKIE_NAME = "openmeeting_admin"
_ALGO = "HS256"


def _password_fingerprint(password: str) -> str:
    # Embedding a fingerprint of the password invalidates sessions when the password changes.
    return hashlib.sha256(("pwd:" + password).encode()).hexdigest()[:16]


def verify_password(candidate: str) -> bool:
    expected = get_settings().resolved_admin_password()
    return hmac.compare_digest(candidate.encode(), expected.encode())


def _jwt_key() -> bytes:
    return hashlib.sha256(("openmeeting-jwt:" + get_settings().resolved_secret_key()).encode()).digest()


def issue_admin_token() -> str:
    settings = get_settings()
    now = utcnow()
    payload = {
        "sub": "admin",
        "iat": int(now.timestamp()),
        "exp": int((now + timedelta(hours=settings.admin_token_ttl_hours)).timestamp()),
        "pf": _password_fingerprint(settings.resolved_admin_password()),
    }
    return jwt.encode(payload, _jwt_key(), algorithm=_ALGO)


def _valid(token: str) -> bool:
    settings = get_settings()
    try:
        payload = jwt.decode(token, _jwt_key(), algorithms=[_ALGO])
    except jwt.PyJWTError:
        return False
    return payload.get("sub") == "admin" and payload.get("pf") == _password_fingerprint(
        settings.resolved_admin_password()
    )


async def require_admin(request: Request) -> None:
    token = request.cookies.get(COOKIE_NAME) or bearer_from_request(request)
    if not token or not _valid(token):
        raise HTTPException(401, "未登录或登录已过期")
