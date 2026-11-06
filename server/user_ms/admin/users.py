from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, Query, Response
from pydantic import BaseModel
from sqlalchemy import func, or_, select, update
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from user_ms.api.v1.auth import clean_name
from service_net.field_limits import UserName
from user_ms.auth.sessions import revoke_user_sessions
from user_ms.auth.sms import require_phone
from user_ms.db.models import User, UserSession
from user_ms.db.session import get_session
from user_ms.infrastructure.meeting_client import MeetingClient
from user_ms.monitor.connections import registry
from user_ms.utils import iso, new_uuid, utcnow

router = APIRouter(tags=["admin-users"])

MAX_LIMIT = 100


async def _session_counts(session: AsyncSession, user_ids: list[str]) -> dict[str, int]:
    if not user_ids:
        return {}
    return dict(
        (
            await session.execute(
                select(UserSession.user_id, func.count(UserSession.id))
                .where(
                    UserSession.user_id.in_(user_ids),
                    UserSession.revoked.is_(False),
                    UserSession.expires_at > utcnow(),
                )
                .group_by(UserSession.user_id)
            )
        ).all()
    )


def _admin_user(u: User, meeting_count: int, session_count: int, online_ids: set[str]) -> dict:
    return {
        "id": u.id,
        "phone": u.phone,
        "name": u.name,
        "disabled": u.disabled,
        "created_at": iso(u.created_at),
        "last_login_at": iso(u.last_login_at),
        "has_password": bool(u.password_hash),
        "meeting_count": meeting_count,
        "session_count": session_count,
        "online": u.id in online_ids,
    }


async def _user_dict(session: AsyncSession, u: User) -> dict:
    sessions, meetings = await _session_counts(session, [u.id]), await MeetingClient().stats_batch([u.id])
    return _admin_user(u, meetings.get(u.id, 0), sessions.get(u.id, 0), registry.online_user_ids())


def _session_dict(s: UserSession) -> dict:
    return {
        "id": s.id,
        "client_id": s.client_id,
        "hostname": s.hostname,
        "os": s.os,
        "app_version": s.app_version,
        "ip": s.ip,
        "created_at": iso(s.created_at),
        "last_used_at": iso(s.last_used_at),
        "expires_at": iso(s.expires_at),
        "revoked": s.revoked,
    }


class UserCreate(BaseModel):
    phone: str
    name: UserName


class UserPatch(BaseModel):
    name: UserName | None = None
    phone: str | None = None
    disabled: bool | None = None


@router.get("/users")
async def list_users(
    q: str = "",
    status: str | None = None,
    limit: int = Query(20, ge=1),
    offset: int = Query(0, ge=0),
    session: AsyncSession = Depends(get_session),
) -> dict:
    limit = min(limit, MAX_LIMIT)
    conditions = []
    if q.strip():
        pattern = f"%{q.strip()}%"
        conditions.append(or_(User.phone.ilike(pattern), User.name.ilike(pattern)))
    if status == "active":
        conditions.append(User.disabled.is_(False))
    elif status == "disabled":
        conditions.append(User.disabled.is_(True))
    total = (await session.execute(select(func.count(User.id)).where(*conditions))).scalar_one()
    users = (
        await session.execute(
            select(User).where(*conditions).order_by(User.created_at.desc(), User.id).limit(limit).offset(offset)
        )
    ).scalars().all()
    ids = [u.id for u in users]
    sessions, meetings = await _session_counts(session, ids), await MeetingClient().stats_batch(ids)
    online = registry.online_user_ids()
    return {
        "items": [_admin_user(u, meetings.get(u.id, 0), sessions.get(u.id, 0), online) for u in users],
        "total": total,
    }


@router.post("/users")
async def create_user(body: UserCreate, session: AsyncSession = Depends(get_session)) -> dict:
    user = User(
        id=new_uuid(), phone=require_phone(body.phone), name=clean_name(body.name), disabled=False, created_at=utcnow()
    )
    session.add(user)
    try:
        await session.commit()
    except IntegrityError as exc:
        raise HTTPException(409, "该手机号已存在") from exc
    return await _user_dict(session, user)


async def _get_user(session: AsyncSession, user_id: str) -> User:
    user = await session.get(User, user_id)
    if user is None:
        raise HTTPException(404, "用户不存在")
    return user


@router.get("/users/{user_id}")
async def get_user(user_id: str, session: AsyncSession = Depends(get_session)) -> dict:
    user = await _get_user(session, user_id)
    rows = (
        await session.execute(
            select(UserSession).where(UserSession.user_id == user_id).order_by(UserSession.created_at.desc())
        )
    ).scalars().all()
    return {**await _user_dict(session, user), "sessions": [_session_dict(s) for s in rows]}


@router.patch("/users/{user_id}")
async def patch_user(user_id: str, body: UserPatch, session: AsyncSession = Depends(get_session)) -> dict:
    user = await _get_user(session, user_id)
    if body.name is not None:
        user.name = clean_name(body.name)
    if body.phone is not None:
        user.phone = require_phone(body.phone)
    if body.disabled is not None:
        user.disabled = body.disabled
        if body.disabled:
            await revoke_user_sessions(session, user.id)
    try:
        await session.commit()
    except IntegrityError as exc:
        raise HTTPException(409, "该手机号已被其他用户使用") from exc
    registry.update_user(user.id, user.name, user.phone)
    return await _user_dict(session, user)


@router.delete("/users/{user_id}", status_code=204)
async def delete_user(user_id: str, session: AsyncSession = Depends(get_session)) -> Response:
    user = await _get_user(session, user_id)
    # Meetings/audio/jobs live in the meeting_ms database; delete them first so a failure
    # here does not leave an unreachable user row behind.
    await MeetingClient().delete_user_data(user_id)
    await session.delete(user)
    await session.commit()
    registry.forget_user(user_id)
    return Response(status_code=204)


@router.delete("/users/{user_id}/sessions/{session_id}", status_code=204)
async def revoke_session(user_id: str, session_id: str, session: AsyncSession = Depends(get_session)) -> Response:
    row = await session.get(UserSession, session_id)
    if row is None or row.user_id != user_id:
        raise HTTPException(404, "会话不存在")
    row.revoked = True
    await session.commit()
    registry.forget_session(session_id)
    return Response(status_code=204)


@router.delete("/users/{user_id}/sessions", status_code=204)
async def revoke_all_sessions(user_id: str, session: AsyncSession = Depends(get_session)) -> Response:
    await _get_user(session, user_id)
    await session.execute(update(UserSession).where(UserSession.user_id == user_id).values(revoked=True))
    await session.commit()
    registry.forget_user(user_id)
    return Response(status_code=204)
