"""HTTP client for user_ms internal APIs (connection registry snapshots, user names)."""
from __future__ import annotations

from meeting_ms.infrastructure.internal_client import client_for


def _detail(response) -> str:  # noqa: ANN001 - httpx.Response
    try:
        return response.json().get("detail") or response.text
    except Exception:  # noqa: BLE001
        return response.text[:200]


class UserClient:
    async def connections(self) -> dict | None:
        """{"snapshot": [...], "online": n, "recording": n} or None when user_ms is unreachable."""
        try:
            async with client_for("user", timeout=10) as client:
                r = await client.get("/connections")
        except Exception:  # noqa: BLE001 - the dashboard must keep working without user_ms
            return None
        if r.status_code != 200:
            return None
        return r.json()

    async def users_batch(self, ids: list[str]) -> dict[str, str]:
        """id -> display name (missing users absent from the result)."""
        ids = sorted({i for i in ids if i})
        if not ids:
            return {}
        try:
            async with client_for("user", timeout=10) as client:
                r = await client.get("/users/batch", params={"ids": ",".join(ids)})
        except Exception:  # noqa: BLE001 - names fall back to None in the admin UI
            return {}
        if r.status_code != 200:
            return {}
        return {row["id"]: row.get("name") for row in r.json()}
