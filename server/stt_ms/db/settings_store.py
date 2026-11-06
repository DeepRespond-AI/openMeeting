"""Key/value access to the system_settings table (stt_ms keys only)."""
from __future__ import annotations

from typing import Any

from sqlalchemy.dialects.postgresql import insert

from stt_ms.db.models import SystemSetting
from stt_ms.db.session import session_factory
from stt_ms.utils import utcnow

ACTIVE_STT_MODEL = "active_stt_model"
STT_CLOUD_CONFIG = "stt_cloud_config"


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
