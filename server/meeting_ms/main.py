"""meeting_ms entry point: meetings, transcription pipeline, summaries and admin data views."""
from __future__ import annotations

import asyncio
import contextlib
import logging
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException

from meeting_ms import SERVER_VERSION
from meeting_ms.admin.dashboard import downstream_ticker
from meeting_ms.api import router as api_router
from meeting_ms.config import get_settings
from meeting_ms.db import session as db
from meeting_ms.jobs.runner import job_runner
from meeting_ms.monitor.inflight import InflightMiddleware
from meeting_ms.summary.templates import seed_rows

logger = logging.getLogger("meeting_ms")


async def _seed_templates() -> None:
    """Ensure the bundled summary templates exist (idempotent upsert)."""
    from sqlalchemy.dialects.postgresql import insert

    from meeting_ms.db.models import SummaryTemplateRow
    from meeting_ms.db.session import session_factory

    async with session_factory()() as session:
        for row in seed_rows():
            stmt = insert(SummaryTemplateRow).values(**row)
            stmt = stmt.on_conflict_do_nothing(index_elements=[SummaryTemplateRow.id])
            await session.execute(stmt)
        await session.commit()


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    settings = get_settings()
    if settings.auto_migrate:
        await db.run_migrations(settings.database_url)
    db.init_engine(settings.database_url)
    await _seed_templates()
    await job_runner.start(settings.job_workers)
    ticker = asyncio.create_task(downstream_ticker())
    from meeting_ms.infrastructure.room_presence import run as run_presence
    presence = asyncio.create_task(run_presence(), name="room-presence")
    from meeting_ms.infrastructure.im_notifications import run as run_notifications
    notifications = asyncio.create_task(run_notifications(), name="im-notifications")
    from meeting_ms.storage.recording_chunks import maintain_chunks
    pcm_maintenance = asyncio.create_task(maintain_chunks(), name="pcm-maintenance")
    logger.info("meeting_ms %s started (data dir: %s)", SERVER_VERSION, settings.data_dir)
    try:
        yield
    finally:
        pcm_maintenance.cancel()
        with contextlib.suppress(asyncio.CancelledError, Exception):
            await pcm_maintenance
        notifications.cancel()
        with contextlib.suppress(asyncio.CancelledError, Exception):
            await notifications
        presence.cancel()
        with contextlib.suppress(asyncio.CancelledError, Exception):
            await presence
        ticker.cancel()
        with contextlib.suppress(asyncio.CancelledError, Exception):
            await ticker
        await job_runner.stop()
        await db.dispose_engine()


def _configure_logging() -> None:
    level = get_settings().log_level.upper()
    root = logging.getLogger()
    if not root.handlers:
        logging.basicConfig(level=level, format="%(asctime)s %(levelname)s [%(name)s] %(message)s")
    logging.getLogger("meeting_ms").setLevel(level)


def create_app() -> FastAPI:
    _configure_logging()
    settings = get_settings()
    app = FastAPI(title="OpenMeeting meeting_ms", version=SERVER_VERSION, lifespan=lifespan)
    app.add_middleware(InflightMiddleware)
    origins = [o.strip() for o in settings.cors_origins.split(",") if o.strip()]
    if origins:
        app.add_middleware(
            CORSMiddleware, allow_origins=origins, allow_credentials=True, allow_methods=["*"], allow_headers=["*"]
        )

    app.include_router(api_router)

    @app.exception_handler(StarletteHTTPException)
    async def http_error(request: Request, exc: StarletteHTTPException) -> JSONResponse:
        detail = exc.detail
        if exc.status_code == 404 and detail == "Not Found":
            detail = "资源不存在"
        headers = getattr(exc, "headers", None)
        # live-meeting 域错误附带机器可读 code：detail 为 {"detail", "code"} 时按原样输出。
        if isinstance(detail, dict):
            return JSONResponse(detail, status_code=exc.status_code, headers=headers)
        return JSONResponse({"detail": detail}, status_code=exc.status_code, headers=headers)

    @app.get("/healthz", include_in_schema=False)
    async def healthz() -> dict:
        return {"ok": True, "version": SERVER_VERSION}

    return app


app = create_app()
