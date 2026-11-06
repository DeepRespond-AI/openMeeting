"""Scheduled meetings (API.md §1.9, design doc docs/development/archive/P1_BACKEND_DESIGN.md §5.1)."""
from __future__ import annotations

import logging
from datetime import timedelta

from fastapi import APIRouter, Depends, Query, Response
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from service_net.field_limits import MEETING_TITLE_MAX as TITLE_MAX

from meeting_ms.api.deps import AuthContext, api_error, require_client
from meeting_ms.db.models import LiveRoom, ScheduledMeeting
from meeting_ms.db.session import get_session
from meeting_ms.utils import generate_room_code, iso, new_scheduled_id, utcnow
from meeting_ms.infrastructure.im_notifications import scheduled_event

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/scheduled-meetings", tags=["scheduled-meetings"])

DURATION_MIN, DURATION_MAX = 5, 720
_CODE_RE = r"^\d{4,6}$"


# ----------------------------------------------------------------- serializer


def scheduled_dict(m: ScheduledMeeting, active_room_id: str | None = None) -> dict:
    return {
        "id": m.id,
        "code": m.code,
        "title": m.title,
        "startAt": iso(m.start_at),
        "durationMin": m.duration_min,
        "pwdEnabled": m.pwd_enabled,
        "pwd": m.pwd,
        "remind": m.remind,
        "waitRoom": m.wait_room,
        "cancelled": m.cancelled,
        "host": {"id": m.user_id, "name": m.host_name},
        "meetingId": m.meeting_id,
        "activeRoomId": active_room_id,
        "createdAt": iso(m.created_at),
        "updatedAt": iso(m.updated_at),
    }


async def owned_scheduled(session: AsyncSession, ctx: AuthContext, scheduled_id: str) -> ScheduledMeeting:
    row = await session.get(ScheduledMeeting, scheduled_id, with_for_update=True)
    if row is None or row.user_id != ctx.user_id:
        raise api_error(404, "预定不存在")
    return row


async def active_scheduled_room(session: AsyncSession, scheduled_id: str) -> str | None:
    return await session.scalar(select(LiveRoom.id).where(
        LiveRoom.scheduled_meeting_id == scheduled_id, LiveRoom.status != "ended"))


def parse_ts(value: str, field: str):
    from datetime import UTC, datetime

    try:
        dt = datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        raise api_error(422, f"{field} 不是有效的 ISO-8601 时间")
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=UTC)
    return dt.astimezone(UTC)


# ----------------------------------------------------------------- endpoints


class ScheduledCreate(BaseModel):
    title: str | None = Field(default=None, max_length=TITLE_MAX)
    startAt: str
    durationMin: int
    pwdEnabled: bool = False
    pwd: str | None = None
    remind: bool = False
    waitRoom: bool = False


@router.post("", status_code=201)
async def create_scheduled(
    body: ScheduledCreate, ctx: AuthContext = Depends(require_client), session: AsyncSession = Depends(get_session)
) -> dict:
    start_at = parse_ts(body.startAt, "startAt")
    if start_at < utcnow() - timedelta(seconds=60):
        raise api_error(422, "开始时间不能早于当前时间")
    if not (DURATION_MIN <= body.durationMin <= DURATION_MAX):
        raise api_error(422, f"时长须在 {DURATION_MIN}–{DURATION_MAX} 分钟之间")
    pwd = body.pwd
    if body.pwdEnabled:
        if pwd is None or not (4 <= len(pwd) <= 6) or not pwd.isdigit():
            raise api_error(422, "入会密码须为 4–6 位数字")
    else:
        pwd = None
    title = (body.title or "").strip() or f"{ctx.user_name}的会议"
    now = utcnow()
    row = ScheduledMeeting(
        id=new_scheduled_id(),
        code=await generate_room_code(session),
        user_id=ctx.user_id,
        host_name=ctx.user_name,
        title=title,
        start_at=start_at,
        duration_min=body.durationMin,
        pwd_enabled=body.pwdEnabled,
        pwd=pwd,
        remind=body.remind,
        wait_room=body.waitRoom,
        created_at=now,
        updated_at=now,
    )
    session.add(row)
    await scheduled_event(session, row, "scheduled_created")
    await session.commit()
    return scheduled_dict(row)


@router.get("")
async def list_scheduled(
    from_ts: str | None = Query(default=None, alias="from"),
    to_ts: str | None = Query(default=None, alias="to"),
    ctx: AuthContext = Depends(require_client),
    session: AsyncSession = Depends(get_session),
) -> list[dict]:
    start = parse_ts(from_ts, "from") if from_ts is not None else None
    end = parse_ts(to_ts, "to") if to_ts is not None else None
    query = select(ScheduledMeeting).where(ScheduledMeeting.user_id == ctx.user_id)
    if start is not None:
        query = query.where(ScheduledMeeting.start_at >= start)
    if end is not None:
        query = query.where(ScheduledMeeting.start_at < end)
    rows = (
        await session.execute(
            query.order_by(ScheduledMeeting.start_at.asc())
        )
    ).scalars().all()
    active = dict((await session.execute(select(LiveRoom.scheduled_meeting_id, LiveRoom.id).where(
        LiveRoom.scheduled_meeting_id.in_([r.id for r in rows]), LiveRoom.status != "ended"))).all()) if rows else {}
    return [scheduled_dict(r, active.get(r.id)) for r in rows]


@router.get("/{scheduled_id}")
async def get_scheduled(
    scheduled_id: str, ctx: AuthContext = Depends(require_client), session: AsyncSession = Depends(get_session)
) -> dict:
    row = await owned_scheduled(session, ctx, scheduled_id)
    return scheduled_dict(row, await active_scheduled_room(session, row.id))


@router.delete("/{scheduled_id}", status_code=204)
async def delete_scheduled(
    scheduled_id: str, ctx: AuthContext = Depends(require_client), session: AsyncSession = Depends(get_session)
) -> Response:
    row = await owned_scheduled(session, ctx, scheduled_id)
    if row.cancelled:
        return Response(status_code=204)
    await ensure_editable(session, row)
    row.cancelled = True
    row.updated_at = utcnow()
    await scheduled_event(session, row, "scheduled_cancelled")
    await session.commit()
    return Response(status_code=204)


async def ensure_editable(session: AsyncSession, row: ScheduledMeeting):
    if row.cancelled:
        raise api_error(409, "预定已取消，不能修改")
    if await active_scheduled_room(session, row.id):
        raise api_error(409, "该预定当前正在开会，请先结束当前场次再修改或取消")


@router.patch("/{scheduled_id}")
async def update_scheduled(scheduled_id: str, body: ScheduledCreate,
                           ctx: AuthContext = Depends(require_client),
                           session: AsyncSession = Depends(get_session)):
    row = await owned_scheduled(session, ctx, scheduled_id)
    await ensure_editable(session, row)
    start = parse_ts(body.startAt, "startAt")
    if start <= utcnow() and start != row.start_at:
        raise api_error(422, "开始时间不能早于当前时间")
    if not DURATION_MIN <= body.durationMin <= DURATION_MAX:
        raise api_error(422, f"时长须在 {DURATION_MIN}–{DURATION_MAX} 分钟之间")
    if body.pwdEnabled and (body.pwd is None or not (4 <= len(body.pwd) <= 6) or not body.pwd.isdigit()):
        raise api_error(422, "入会密码须为 4–6 位数字")
    row.title = (body.title or "").strip() or f"{ctx.user_name}的会议"
    row.start_at, row.duration_min = start, body.durationMin
    row.pwd_enabled, row.pwd = body.pwdEnabled, body.pwd if body.pwdEnabled else None
    row.remind, row.wait_room, row.updated_at = body.remind, body.waitRoom, utcnow()
    await scheduled_event(session, row, "scheduled_updated")
    await session.commit()
    return scheduled_dict(row)
