from __future__ import annotations

import asyncio
import logging
from collections.abc import AsyncIterator
from pathlib import Path

from sqlalchemy.ext.asyncio import AsyncEngine, AsyncSession, async_sessionmaker, create_async_engine

logger = logging.getLogger(__name__)

_engine: AsyncEngine | None = None
_sessionmaker: async_sessionmaker[AsyncSession] | None = None

MS_ROOT = Path(__file__).resolve().parents[1]


def init_engine(database_url: str) -> AsyncEngine:
    global _engine, _sessionmaker
    _engine = create_async_engine(database_url, pool_pre_ping=True, pool_size=10, max_overflow=20)
    _sessionmaker = async_sessionmaker(_engine, expire_on_commit=False)
    return _engine


async def dispose_engine() -> None:
    global _engine, _sessionmaker
    if _engine is not None:
        await _engine.dispose()
    _engine = None
    _sessionmaker = None


def session_factory() -> async_sessionmaker[AsyncSession]:
    if _sessionmaker is None:
        raise RuntimeError("Database engine not initialised")
    return _sessionmaker


async def get_session() -> AsyncIterator[AsyncSession]:
    async with session_factory()() as session:
        yield session


def _run_alembic_upgrade(database_url: str) -> None:
    from alembic.config import Config

    from alembic import command

    cfg = Config(str(MS_ROOT / "alembic.ini"))
    cfg.set_main_option("script_location", str(MS_ROOT / "migrations"))
    cfg.set_main_option("sqlalchemy.url", database_url.replace("%", "%%"))
    cfg.attributes["configure_logger"] = False
    logging.getLogger("alembic").setLevel(logging.WARNING)
    command.upgrade(cfg, "head")


async def run_migrations(database_url: str) -> None:
    """Run alembic in a worker thread (alembic's async env uses its own event loop)."""
    logger.info("Running database migrations")
    await asyncio.to_thread(_run_alembic_upgrade, database_url)
