"""Internal API consumed by meeting_ms (auth via the shared internal token, enforced on the parent router)."""
from __future__ import annotations

from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from user_ms.db.models import User
from user_ms.db.session import get_session
from user_ms.monitor.connections import registry

router = APIRouter(prefix="/internal", tags=["internal"])


@router.get("/connections")
async def connections() -> dict:
    """Connection snapshot plus online/recording counts (dashboard polls this)."""
    snapshot = registry.snapshot()
    return {
        "snapshot": snapshot,
        "online": sum(1 for c in snapshot if c["online"]),
        "recording": sum(1 for c in snapshot if c["recording"]),
    }


@router.get("/users/batch")
async def users_batch(ids: str, session: AsyncSession = Depends(get_session)) -> list[dict]:
    """Comma-separated user ids -> [{"id", "name"}] (only existing users)."""
    wanted = [i for i in (s.strip() for s in ids.split(",")) if i]
    if not wanted:
        return []
    rows = await session.execute(select(User.id, User.name).where(User.id.in_(wanted)))
    return [{"id": uid, "name": name} for uid, name in rows]
