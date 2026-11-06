from __future__ import annotations

from fastapi import APIRouter, Depends, Request
from pydantic import BaseModel
from sqlalchemy import or_, update
from sqlalchemy.ext.asyncio import AsyncSession

from user_ms import SERVER_VERSION
from user_ms.api.deps import AuthContext, require_client
from user_ms.auth.sessions import bearer_from_request, hash_token
from user_ms.db.models import UserSession
from user_ms.db.session import get_session
from user_ms.monitor.connections import ClientConnection, client_ip_from_request, registry
from user_ms.monitor.events import broker
from user_ms.utils import iso, utcnow

router = APIRouter(prefix="/client", tags=["client"])


class HeartbeatIn(BaseModel):
    client_id: str
    hostname: str = ""
    os: str = ""
    app_version: str = ""
    recording: bool = False
    meeting_id: str | None = None


@router.post("/heartbeat")
async def heartbeat(
    body: HeartbeatIn,
    request: Request,
    ctx: AuthContext = Depends(require_client),
    session: AsyncSession = Depends(get_session),
) -> dict:
    # The token hash comes from the bearer the client actually sent (matches the sessions table
    # entry the gateway authenticated); it keys the per-token in-flight counters.
    raw = bearer_from_request(request)
    registry.heartbeat(
        ClientConnection(
            client_id=body.client_id,
            session_id=ctx.session_id,
            token_hash=hash_token(raw) if raw else ctx.token_hash,
            user_id=ctx.user_id,
            user_name=ctx.user_name,
            user_phone=ctx.user_phone,
            hostname=body.hostname,
            os=body.os,
            app_version=body.app_version,
            ip=client_ip_from_request(request),
            recording=body.recording,
            meeting_id=body.meeting_id,
            last_seen=utcnow(),
        )
    )
    broker.publish("connections", registry.snapshot())
    if body.app_version:
        # Keep the session's version current after an upgrade (admin version distribution).
        result = await session.execute(
            update(UserSession)
            .where(
                UserSession.id == ctx.session_id,
                or_(
                    UserSession.app_version.is_distinct_from(body.app_version),
                    UserSession.os.is_distinct_from(body.os or None),
                ),
            )
            .values(app_version=body.app_version, os=body.os or None)
        )
        if result.rowcount:
            await session.commit()
    return {"server_time": iso(utcnow()), "server_version": SERVER_VERSION}
