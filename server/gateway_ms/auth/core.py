"""Client session authentication: sha256(ms_… token) looked up in the user_ms database.

Replaces the monolith's `require_client`: the gateway validates the session once, caches the
identity briefly (revocation/disable lags by at most OPENMEETING_SESSION_CACHE_TTL_SEC) and keeps
the sliding-expiry touch up to date, then injects X-User-* headers for the downstream services.
"""
from __future__ import annotations

import hashlib
import logging
import time
from dataclasses import dataclass
from datetime import timedelta

import jwt
from fastapi import HTTPException, Request
from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from gateway_ms.config import get_settings

logger = logging.getLogger(__name__)

SESSION_TTL = timedelta(days=30)
TOUCH_INTERVAL = timedelta(hours=1)
COOKIE_NAME = "openmeeting_admin"
_ALGO = "HS256"


@dataclass(frozen=True)
class ClientIdentity:
    user_id: str
    user_name: str
    user_phone: str | None
    session_id: str
    token_hash: str
    last_used_at: float  # unix seconds, drives the touch


def bearer_from_request(request: Request) -> str | None:
    header = request.headers.get("authorization", "")
    scheme, _, value = header.partition(" ")
    if scheme.lower() != "bearer" or not value.strip():
        return None
    return value.strip()


def hash_token(token: str) -> str:
    return hashlib.sha256(token.encode()).hexdigest()


# ---------------------------------------------------------------- admin JWT


def _password_fingerprint(password: str) -> str:
    # Mirrors user_ms.auth.admin: embedding a fingerprint invalidates sessions when the password changes.
    return hashlib.sha256(("pwd:" + password).encode()).hexdigest()[:16]


def _jwt_key() -> bytes:
    return hashlib.sha256(("openmeeting-jwt:" + get_settings().resolved_secret_key()).encode()).digest()


def verify_admin(request: Request) -> None:
    """验证管理端 JWT（cookie 或 Bearer）。与 user_ms.auth.admin._valid 完全同构。"""
    token = request.cookies.get(COOKIE_NAME) or bearer_from_request(request)
    if not token:
        raise HTTPException(401, "未登录或登录已过期")
    settings = get_settings()
    try:
        payload = jwt.decode(token, _jwt_key(), algorithms=[_ALGO])
    except jwt.PyJWTError as exc:
        raise HTTPException(401, "未登录或登录已过期") from exc
    if payload.get("sub") != "admin" or payload.get("pf") != _password_fingerprint(
        settings.resolved_admin_password()
    ):
        raise HTTPException(401, "未登录或登录已过期")


# ---------------------------------------------------------------- client sessions

_cache: dict[str, tuple[ClientIdentity, bool, float]] = {}  # token_hash -> (identity, user_disabled, cached_at)


def _cache_get(token_hash: str) -> tuple[ClientIdentity, bool] | None:
    ttl = get_settings().session_cache_ttl_sec
    entry = _cache.get(token_hash)
    if entry is None or time.monotonic() - entry[2] > ttl:
        return None
    return entry[0], entry[1]


def _cache_put(identity: ClientIdentity, user_disabled: bool) -> None:
    if len(_cache) > 10000:  # hard cap; steady state is a handful of desktop clients
        _cache.clear()
    _cache[identity.token_hash] = (identity, user_disabled, time.monotonic())


async def require_client_identity(request: Request, session: AsyncSession) -> ClientIdentity:
    """Validate the bearer session; mirrors the exact error messages of the old require_client."""
    raw = bearer_from_request(request)
    if not raw:
        raise HTTPException(401, "未登录，请先使用手机号登录")
    token_hash = hash_token(raw)

    cached = _cache_get(token_hash)
    if cached is not None:
        identity, disabled = cached
        if disabled:
            raise HTTPException(403, "该账号已被禁用")
        return identity

    from gateway_ms.db.models import User, UserSession

    now = _utcnow()
    row = (
        await session.execute(
            select(UserSession, User).join(User, User.id == UserSession.user_id).where(
                UserSession.token_hash == token_hash
            )
        )
    ).first()
    if row is None:
        raise HTTPException(401, "登录凭证无效，请重新登录")
    sess, user = row
    if sess.revoked:
        raise HTTPException(401, "登录已失效，请重新登录")
    if sess.expires_at <= now:
        raise HTTPException(401, "登录已过期，请重新登录")
    if user.disabled:
        raise HTTPException(403, "该账号已被禁用")

    identity = ClientIdentity(
        user_id=user.id,
        user_name=user.name,
        user_phone=user.phone,
        session_id=sess.id,
        token_hash=token_hash,
        last_used_at=sess.last_used_at.timestamp() if sess.last_used_at else 0.0,
    )
    _cache_put(identity, False)

    # Sliding expiry (same cadence as the monolith: at most once per hour per session).
    if sess.last_used_at is None or now - sess.last_used_at >= TOUCH_INTERVAL:
        await session.execute(
            update(UserSession)
            .where(UserSession.id == sess.id)
            .values(last_used_at=now, expires_at=now + SESSION_TTL, ip=client_ip_from_scope(request))
        )
        await session.commit()
    return identity


def _utcnow():
    from datetime import UTC, datetime

    return datetime.now(UTC)


def invalidate_session_cache(token_hash: str) -> None:
    _cache.pop(token_hash, None)


def _token_hash_from_request(request: Request) -> str | None:
    raw = bearer_from_request(request)
    return hash_token(raw) if raw else None


def clear_cache_for_request(request: Request) -> None:
    """After auth-domain mutations (logout/revoke) drop the cached identity immediately."""
    token_hash = _token_hash_from_request(request)
    if token_hash:
        invalidate_session_cache(token_hash)


# ---------------------------------------------------------------- client IP


def client_ip_from_scope(request: Request) -> str | None:
    """Same right-most-untrusted-hop rule as the monolith's monitor.connections.client_ip."""
    import ipaddress

    spec = get_settings().trusted_proxies
    peer = request.client.host if request.client else None
    networks = []
    for item in spec.split(","):
        item = item.strip()
        if item:
            try:
                networks.append(ipaddress.ip_network(item, strict=False))
            except ValueError:
                continue

    def _is_trusted(ip: str | None) -> bool:
        if not ip or not networks:
            return False
        try:
            addr = ipaddress.ip_address(ip)
        except ValueError:
            return False
        return any(addr in net for net in networks)

    if not _is_trusted(peer):
        return peer
    forwarded = request.headers.get("x-forwarded-for")
    if forwarded:
        hops = [h.strip() for h in forwarded.split(",") if h.strip()]
        for hop in reversed(hops):
            if not _is_trusted(hop):
                return hop
        return hops[0] if hops else peer
    return request.headers.get("x-real-ip") or peer
