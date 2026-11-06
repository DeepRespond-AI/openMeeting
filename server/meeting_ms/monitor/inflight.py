"""In-flight /api/v1 request counter per bearer token (merged into admin connection views)."""
from __future__ import annotations

import hashlib
from collections import defaultdict

from starlette.types import ASGIApp, Receive, Scope, Send


class InflightTracker:
    def __init__(self) -> None:
        self._inflight: dict[str, int] = defaultdict(int)

    def enter(self, token_hash: str) -> None:
        self._inflight[token_hash] += 1

    def exit(self, token_hash: str) -> None:
        self._inflight[token_hash] = max(0, self._inflight[token_hash] - 1)

    def merge(self, snapshot: list[dict]) -> list[dict]:
        """Overlay local counters onto a connection snapshot from user_ms."""
        for item in snapshot:
            local = self._inflight.get(item.get("token_hash", ""), 0)
            if local:
                item["inflight_requests"] = item.get("inflight_requests", 0) + local
        return snapshot


tracker = InflightTracker()


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
        tracker.enter(token_hash)
        try:
            await self.app(scope, receive, send)
        finally:
            tracker.exit(token_hash)
