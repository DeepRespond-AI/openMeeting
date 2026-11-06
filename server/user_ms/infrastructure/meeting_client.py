"""HTTP client for meeting_ms internal APIs (per-user meeting stats and data deletion)."""
from __future__ import annotations

import httpx
from fastapi import HTTPException

from user_ms.config import get_settings

INTERNAL_TOKEN_HEADER = "X-Internal-Token"


def _client(timeout: float = 30.0) -> httpx.AsyncClient:
    settings = get_settings()
    headers = {}
    if settings.internal_service_token:
        headers[INTERNAL_TOKEN_HEADER] = settings.internal_service_token
    # trust_env=False: service-to-service calls must never go through a host proxy.
    return httpx.AsyncClient(
        base_url=f"{settings.gateway_ms_url.rstrip('/')}/internal/meeting/",
        timeout=timeout, headers=headers, trust_env=False
    )


class MeetingClient:
    async def stats_batch(self, ids: list[str]) -> dict[str, int]:
        """id -> meeting_count (missing users map to nothing)."""
        ids = sorted({i for i in ids if i})
        if not ids:
            return {}
        try:
            async with _client(timeout=10) as client:
                r = await client.get("/users/stats-batch", params={"ids": ",".join(ids)})
        except Exception:  # noqa: BLE001 - the admin UI degrades to 0 meetings
            return {}
        if r.status_code != 200:
            return {}
        return {k: int(v) for k, v in r.json().items()}

    async def delete_user_data(self, user_id: str) -> None:
        """Delete the user's meetings/audio/jobs in meeting_ms. Raises on failure (caller aborts)."""
        try:
            async with _client(timeout=120) as client:
                r = await client.delete(f"/users/{user_id}/data")
        except httpx.HTTPError as exc:
            raise HTTPException(502, "会议服务暂不可用，用户未删除，请稍后重试") from exc
        if r.status_code != 204:
            raise HTTPException(502, "会议服务暂不可用，用户未删除，请稍后重试")
