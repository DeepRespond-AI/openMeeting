"""stt_ms entry point: speech-to-text inference, model catalog and downloads."""
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

from stt_ms import SERVER_VERSION
from stt_ms.api import router as api_router
from stt_ms.config import get_settings
from stt_ms.db import session as db
from stt_ms.stt import model_store
from stt_ms.stt.registry import stt_registry
from service_net.egress import configure_sdk_environment

logger = logging.getLogger("stt_ms")


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    settings = get_settings()
    configure_sdk_environment(settings)
    if settings.auto_migrate:
        await db.run_migrations(settings.database_url)
    db.init_engine(settings.database_url)
    stt_registry.configure(settings.stt_concurrency)
    await model_store.sync_catalog()
    # Restore the active STT model in the background so startup is not blocked by model loading.
    restore_task = asyncio.create_task(stt_registry.restore())
    logger.info("stt_ms %s started (data dir: %s)", SERVER_VERSION, settings.data_dir)
    try:
        yield
    finally:
        restore_task.cancel()
        with contextlib.suppress(asyncio.CancelledError, Exception):
            await restore_task
        await db.dispose_engine()


def _configure_logging() -> None:
    level = get_settings().log_level.upper()
    root = logging.getLogger()
    if not root.handlers:
        logging.basicConfig(level=level, format="%(asctime)s %(levelname)s [%(name)s] %(message)s")
    logging.getLogger("stt_ms").setLevel(level)


def create_app() -> FastAPI:
    _configure_logging()
    settings = get_settings()
    app = FastAPI(title="OpenMeeting stt_ms", version=SERVER_VERSION, lifespan=lifespan)
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
        return JSONResponse({"detail": detail}, status_code=exc.status_code, headers=getattr(exc, "headers", None))

    @app.get("/healthz", include_in_schema=False)
    async def healthz() -> dict:
        return {"ok": True, "version": SERVER_VERSION}

    return app


app = create_app()
