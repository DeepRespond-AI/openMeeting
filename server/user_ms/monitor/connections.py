"""In-memory registry of desktop clients, fed by heartbeats and a request middleware."""
from __future__ import annotations

import hashlib
import ipaddress
from collections import defaultdict
from dataclasses import dataclass, field
from datetime import datetime, timedelta

from starlette.types import ASGIApp, Receive, Scope, Send

from user_ms.config import get_settings
from user_ms.utils import iso, utcnow

ONLINE_WINDOW = timedelta(seconds=45)


@dataclass
class ClientConnection:
    client_id: str
    session_id: str
    token_hash: str
    user_id: str
    user_name: str
    user_phone: str | None = None
    hostname: str = ""
    os: str = ""
    app_version: str = ""
    ip: str | None = None
    recording: bool = False
    meeting_id: str | None = None
    last_seen: datetime = field(default_factory=utcnow)


class ConnectionRegistry:
    def __init__(self) -> None:
        self._clients: dict[str, ClientConnection] = {}
        self._inflight: dict[str, int] = defaultdict(int)

    def heartbeat(self, conn: ClientConnection) -> None:
        self._clients[conn.client_id] = conn

    def inflight_enter(self, token_hash: str) -> None:
        self._inflight[token_hash] += 1

    def inflight_exit(self, token_hash: str) -> None:
        self._inflight[token_hash] = max(0, self._inflight[token_hash] - 1)

    def forget_session(self, session_id: str) -> None:
        for cid in [c.client_id for c in self._clients.values() if c.session_id == session_id]:
            self._clients.pop(cid, None)

    def forget_user(self, user_id: str) -> None:
        for cid in [c.client_id for c in self._clients.values() if c.user_id == user_id]:
            self._clients.pop(cid, None)

    def update_user(self, user_id: str, name: str, phone: str | None) -> None:
        for c in self._clients.values():
            if c.user_id == user_id:
                c.user_name, c.user_phone = name, phone

    def online_user_ids(self) -> set[str]:
        now = utcnow()
        return {c.user_id for c in self._clients.values() if now - c.last_seen < ONLINE_WINDOW}

    def snapshot(self) -> list[dict]:
        now = utcnow()
        # Drop entries that have been silent for a day.
        for cid in [c.client_id for c in self._clients.values() if now - c.last_seen > timedelta(days=1)]:
            self._clients.pop(cid, None)
        items = []
        for c in sorted(self._clients.values(), key=lambda c: c.last_seen, reverse=True):
            online = now - c.last_seen < ONLINE_WINDOW
            items.append(
                {
                    "client_id": c.client_id,
                    "user_id": c.user_id,
                    "user_name": c.user_name,
                    "user_phone": c.user_phone,
                    "hostname": c.hostname,
                    "os": c.os,
                    "app_version": c.app_version,
                    "ip": c.ip,
                    "recording": c.recording and online,
                    "meeting_id": c.meeting_id,
                    "last_seen": iso(c.last_seen),
                    "online": online,
                    "inflight_requests": self._inflight.get(c.token_hash, 0),
                }
            )
        return items

    def counts(self) -> tuple[int, int]:
        snap = self.snapshot()
        return sum(1 for c in snap if c["online"]), sum(1 for c in snap if c["recording"])


registry = ConnectionRegistry()


def _parse_networks(spec: str) -> list[ipaddress.IPv4Network | ipaddress.IPv6Network]:
    networks = []
    for item in spec.split(","):
        item = item.strip()
        if item:
            networks.append(ipaddress.ip_network(item, strict=False))
    return networks


def _is_trusted(ip: str | None, trusted: list) -> bool:
    if not ip or not trusted:
        return False
    try:
        addr = ipaddress.ip_address(ip)
    except ValueError:
        return False
    return any(addr in net for net in trusted)


def client_ip(scope_headers: dict[str, str], peer: str | None, trusted_proxies: str | None = None) -> str | None:
    """Real client IP. Forwarding headers are honoured only when the direct peer is a trusted proxy;
    then the right-most X-Forwarded-For hop that is not itself a trusted proxy is the client."""
    trusted = _parse_networks(get_settings().trusted_proxies if trusted_proxies is None else trusted_proxies)
    if not _is_trusted(peer, trusted):
        return peer
    forwarded = scope_headers.get("x-forwarded-for")
    if forwarded:
        hops = [h.strip() for h in forwarded.split(",") if h.strip()]
        for hop in reversed(hops):
            if not _is_trusted(hop, trusted):
                return hop
        return hops[0] if hops else peer
    return scope_headers.get("x-real-ip") or peer


def client_ip_from_request(request) -> str | None:  # noqa: ANN001 - starlette Request
    headers = {k.decode().lower(): v.decode() for k, v in request.scope.get("headers", [])}
    return client_ip(headers, request.client.host if request.client else None)


class InflightMiddleware:
    """Counts in-flight /api/v1 requests per bearer token (pure ASGI to keep streaming intact)."""

    def __init__(self, app: ASGIApp) -> None:
        self.app = app

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        if scope["type"] != "http" or not scope["path"].startswith("/api/v1"):
            await self.app(scope, receive, send)
            return
        token_hash = None
        for name, value in scope.get("headers", []):
            if name == b"authorization":
                scheme, _, raw = value.decode("latin-1").partition(" ")
                if scheme.lower() == "bearer" and raw.strip():
                    token_hash = hashlib.sha256(raw.strip().encode()).hexdigest()
                break
        if token_hash is None:
            await self.app(scope, receive, send)
            return
        registry.inflight_enter(token_hash)
        try:
            await self.app(scope, receive, send)
        finally:
            registry.inflight_exit(token_hash)
