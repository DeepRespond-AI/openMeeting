"""gateway_ms entry point: unified entry, authentication, path forwarding and the admin SPA."""
from __future__ import annotations

import logging
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from pathlib import Path

import httpx
from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, JSONResponse, RedirectResponse
from starlette.exceptions import HTTPException as StarletteHTTPException

from gateway_ms import SERVER_VERSION
from gateway_ms.api import router as api_router
from gateway_ms.api.internal import router as internal_router
from gateway_ms.config import get_settings
from gateway_ms.db import session as db
from gateway_ms.infrastructure.egress import EgressProxy

logger = logging.getLogger("gateway_ms")

ADMIN_STATIC_DIR = Path(__file__).resolve().parent / "static" / "admin"


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    settings = get_settings()
    settings.resolved_admin_password()  # fail fast when not configured
    settings.resolved_secret_key()
    db.init_engine(settings.database_url)
    # trust_env=False: downstream services are addressed by fixed internal URLs, never via a proxy.
    app.state.http_client = httpx.AsyncClient(
        timeout=httpx.Timeout(600.0, connect=10.0), trust_env=False
    )
    egress = None
    try:
        if settings.egress_enabled:
            egress = await EgressProxy(settings).start()
        app.state.egress_proxy = egress
        logger.info("gateway_ms %s started (port %s)", SERVER_VERSION, settings.port)
        yield
    finally:
        if egress:
            await egress.close()
        await app.state.http_client.aclose()
        await db.dispose_engine()


def _configure_logging() -> None:
    level = get_settings().log_level.upper()
    root = logging.getLogger()
    if not root.handlers:
        logging.basicConfig(level=level, format="%(asctime)s %(levelname)s [%(name)s] %(message)s")
    logging.getLogger("gateway_ms").setLevel(level)


def create_app() -> FastAPI:
    _configure_logging()
    settings = get_settings()
    app = FastAPI(title="OpenMeeting Gateway", version=SERVER_VERSION, lifespan=lifespan)
    origins = [o.strip() for o in settings.cors_origins.split(",") if o.strip()]
    if origins:
        app.add_middleware(
            CORSMiddleware, allow_origins=origins, allow_credentials=True, allow_methods=["*"], allow_headers=["*"]
        )

    app.include_router(api_router)
    app.include_router(internal_router)

    @app.exception_handler(StarletteHTTPException)
    async def http_error(request: Request, exc: StarletteHTTPException) -> JSONResponse:
        detail = exc.detail
        if exc.status_code == 404 and detail == "Not Found":
            detail = "资源不存在"
        return JSONResponse({"detail": detail}, status_code=exc.status_code, headers=getattr(exc, "headers", None))

    @app.get("/", include_in_schema=False)
    async def root() -> RedirectResponse:
        return RedirectResponse("/admin/")

    @app.get("/healthz", include_in_schema=False)
    async def healthz() -> dict:
        return {"ok": True, "version": SERVER_VERSION}

    @app.get("/admin", include_in_schema=False)
    @app.get("/admin/{path:path}", include_in_schema=False)
    async def admin_spa(path: str = "") -> FileResponse:
        """Serve the admin SPA: static files when they exist, index.html otherwise (history mode)."""
        if path.startswith("api/") or path == "api":
            raise HTTPException(404, "资源不存在")
        index = ADMIN_STATIC_DIR / "index.html"
        if not index.exists():
            raise HTTPException(404, "管理端前端未构建（server/gateway_ms/static/admin 不存在）")
        if path:
            candidate = (ADMIN_STATIC_DIR / path).resolve()
            if candidate.is_file() and ADMIN_STATIC_DIR.resolve() in candidate.parents:
                return FileResponse(candidate)
        return FileResponse(index, headers={"Cache-Control": "no-cache"})

    return app


app = create_app()
