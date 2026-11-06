"""Client login sessions: bearer `ms_` + 43 url-safe chars, stored as sha256, sliding 30-day expiry.

Since the split, session *validation* for /api/v1 requests happens in the gateway (which keeps the
sliding-expiry touch up to date); this module owns session creation/revocation and the token hashing.
"""
from __future__ import annotations

import hashlib
import secrets
from datetime import timedelta

from fastapi import Request
from sqlalchemy import update
from sqlalchemy.ext.asyncio import AsyncSession

from user_ms.db.models import User, UserSession
from user_ms.monitor.connections import registry
from user_ms.utils import new_uuid, utcnow

TOKEN_PREFIX = "ms_"
SESSION_TTL = timedelta(days=30)
# Sliding-expiry writes (last_used_at / expires_at) happen at most once per hour per session
# (performed by the gateway when it validates a session).
TOUCH_INTERVAL = timedelta(hours=1)


def generate_token() -> str:
    return TOKEN_PREFIX + secrets.token_urlsafe(32)  # 32 bytes -> 43 url-safe chars


def hash_token(token: str) -> str:
    return hashlib.sha256(token.encode()).hexdigest()


def bearer_from_request(request: Request) -> str | None:
    header = request.headers.get("authorization", "")
    scheme, _, value = header.partition(" ")
    if scheme.lower() != "bearer" or not value.strip():
        return None
    return value.strip()


async def create_session(
    session: AsyncSession, user: User, client: dict | None, ip: str | None
) -> tuple[UserSession, str]:
    """Adds a new session row (caller commits) and returns it with the plaintext token."""
    client = client or {}
    plaintext = generate_token()
    now = utcnow()
    row = UserSession(
        id=new_uuid(),
        user_id=user.id,
        token_hash=hash_token(plaintext),
        client_id=(client.get("client_id") or None),
        hostname=(client.get("hostname") or None),
        os=(client.get("os") or None),
        app_version=(client.get("app_version") or None),
        ip=ip,
        created_at=now,
        last_used_at=now,
        expires_at=now + SESSION_TTL,
        revoked=False,
    )
    session.add(row)
    return row, plaintext


async def revoke_user_sessions(session: AsyncSession, user_id: str) -> None:
    """Revoke every session of a user (caller commits) and drop them from the connection registry."""
    await session.execute(
        update(UserSession).where(UserSession.user_id == user_id, UserSession.revoked.is_(False)).values(revoked=True)
    )
    registry.forget_user(user_id)


async def revoke_session_by_id(session: AsyncSession, session_id: str) -> None:
    await session.execute(update(UserSession).where(UserSession.id == session_id).values(revoked=True))
    registry.forget_session(session_id)
