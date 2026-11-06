"""Key/value access to the system_settings table (meeting_ms keys only)."""
from __future__ import annotations

from typing import Any

from sqlalchemy.dialects.postgresql import insert

from meeting_ms.db.models import SystemSetting
from meeting_ms.db.session import session_factory
from meeting_ms.utils import utcnow

ACTIVE_LLM_PROVIDER = "active_llm_provider_id"


async def get_setting(key: str, default: Any = None) -> Any:
    async with session_factory()() as session:
        row = await session.get(SystemSetting, key)
        return default if row is None else row.value


async def set_setting(key: str, value: Any) -> None:
    async with session_factory()() as session:
        stmt = insert(SystemSetting).values(key=key, value=value, updated_at=utcnow())
        stmt = stmt.on_conflict_do_update(
            index_elements=[SystemSetting.key], set_={"value": stmt.excluded.value, "updated_at": utcnow()}
        )
        await session.execute(stmt)
        await session.commit()
