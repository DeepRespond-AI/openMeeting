"""user_ms entry point: users, sessions, SMS auth, client releases and the connection registry."""
from __future__ import annotations

import logging
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import Depends, FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException

from user_ms import SERVER_VERSION
from user_ms.api import router as api_router
from user_ms.api.deps import require_internal
from user_ms.api.v1.im import callback_router as im_callback_router
from user_ms.config import get_settings
from user_ms.db import session as db
from user_ms.monitor.connections import InflightMiddleware

logger = logging.getLogger("user_ms")


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    settings = get_settings()
    settings.resolved_admin_password()  # fail fast when not configured
    if settings.auto_migrate:
        await db.run_migrations(settings.database_url)
    db.init_engine(settings.database_url)
    logger.info("user_ms %s started (data dir: %s)", SERVER_VERSION, settings.data_dir)
    try:
        yield
    finally:
        # IM 客户端是惰性创建的：用到过才存在，这里负责释放它的连接池。
        from user_ms.infrastructure.im_client import aclose_client

        await aclose_client()
        await db.dispose_engine()


def _configure_logging() -> None:
    level = get_settings().log_level.upper()
    root = logging.getLogger()
    if not root.handlers:
        logging.basicConfig(level=level, format="%(asctime)s %(levelname)s [%(name)s] %(message)s")
    logging.getLogger("user_ms").setLevel(level)


def create_app() -> FastAPI:
    _configure_logging()
    settings = get_settings()
    app = FastAPI(title="OpenMeeting user_ms", version=SERVER_VERSION, lifespan=lifespan)
    app.add_middleware(InflightMiddleware)
    origins = [o.strip() for o in settings.cors_origins.split(",") if o.strip()]
    if origins:
        app.add_middleware(
            CORSMiddleware, allow_origins=origins, allow_credentials=True, allow_methods=["*"], allow_headers=["*"]
        )

    app.include_router(api_router)
    # External callbacks enter via the gateway, which injects the internal token.
    # The platform signature remains mandatory inside the callback handler.
    app.include_router(im_callback_router, dependencies=[Depends(require_internal)])

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
