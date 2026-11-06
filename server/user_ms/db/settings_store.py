"""Key/value access to the system_settings table (key constants live in user_ms.auth.sms / updates.policy)."""
from __future__ import annotations

from typing import Any

from sqlalchemy.dialects.postgresql import insert

from user_ms.db.models import SystemSetting
from user_ms.db.session import session_factory
from user_ms.utils import utcnow


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