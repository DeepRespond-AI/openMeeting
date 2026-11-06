"""Phone-number registration / login (§1.0)."""
from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, Request, Response
from pydantic import BaseModel, Field
from sqlalchemy import select, update
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession
from service_net.field_limits import USER_NAME_MAX, UserName

from user_ms import SERVER_VERSION
from user_ms.auth import passwords, sms
from user_ms.api.deps import AuthContext, require_client
from user_ms.auth.sessions import create_session, revoke_user_sessions
from user_ms.db.models import User, UserSession
from user_ms.db.session import get_session
from user_ms.infrastructure import im_client
from user_ms.monitor.connections import client_ip_from_request, registry
from user_ms.utils import iso, new_uuid, utcnow

# Public endpoints (no Authorization header).
public_router = APIRouter(prefix="/auth", tags=["auth"])
# Endpoints that need a session; mounted under the authenticated /api/v1 router.
router = APIRouter(prefix="/auth", tags=["auth"])


class ClientInfo(BaseModel):
    client_id: str = Field(default="", max_length=200)
    hostname: str = Field(default="", max_length=255)
    os: str = Field(default="", max_length=100)
    app_version: str = Field(default="", max_length=64)


class SendCodeIn(BaseModel):
    phone: str
    purpose: str


class RegisterIn(BaseModel):
    phone: str
    code: str
    name: UserName
    password: str | None = None
    client: ClientInfo = Field(default_factory=ClientInfo)


class LoginIn(BaseModel):
    """Exactly one of `code` (SMS login) or `password`."""

    phone: str
    code: str | None = None
    password: str | None = None
    client: ClientInfo = Field(default_factory=ClientInfo)


class ResetPasswordIn(BaseModel):
    phone: str
    code: str
    password: str | None = None
    client: ClientInfo = Field(default_factory=ClientInfo)


class ChangePasswordIn(BaseModel):
    old_password: str | None = None
    password: str | None = None


class ProfilePatch(BaseModel):
    name: UserName


def user_dict(u: User) -> dict:
    return {
        "id": u.id,
        "phone": u.phone,
        "name": u.name,
        "created_at": iso(u.created_at),
        "last_login_at": iso(u.last_login_at),
        "has_password": bool(u.password_hash),
    }


def clean_name(raw: str | None) -> str:
    name = (raw or "").strip()
    if not name:
        raise HTTPException(422, "请填写姓名")
    if len(name) > USER_NAME_MAX:
        raise HTTPException(422, f"昵称不能超过 {USER_NAME_MAX} 个字符")
    return name


async def _user_by_phone(session: AsyncSession, phone: str) -> User | None:
    return (await session.execute(select(User).where(User.phone == phone))).scalar_one_or_none()


async def _auth_result(session: AsyncSession, user: User, client: ClientInfo, request: Request) -> dict:
    user.last_login_at = utcnow()
    row, token = await create_session(session, user, client.model_dump(), client_ip_from_request(request))
    await session.commit()
    # 登录即有 IM：顺手签发 IM 登录凭证（用户首次签发时自动创建 IM 账号）。
    # 尽力而为：IM 未开启或失败时为 null，不影响登录本身。凭证 5 分钟有效且
    # 一次性，过期/重连时客户端再调 POST /api/v1/im/ticket 重新获取。
    im_ticket = await im_client.issue_login_ticket_best_effort(user.id)
    return {
        "token": token,
        "expires_at": iso(row.expires_at),
        "user": user_dict(user),
        "im_ticket": im_ticket,
    }


@public_router.get("/config")
async def auth_config() -> dict:
    cfg = await sms.load_sms_config()
    return {
        "registration_open": await sms.registration_open(),
        # True whenever codes can be obtained (configured, or dev mode which returns `dev_code`).
        "sms_ready": cfg.ready or sms.dev_mode_without_sms(cfg),
        "code_length": sms.CODE_LENGTH,
        "resend_interval_sec": sms.RESEND_INTERVAL_SEC,
        "password_min_length": passwords.MIN_LENGTH,
        "password_max_length": passwords.MAX_LENGTH,
        "server_version": SERVER_VERSION,
    }


@public_router.post("/sms/send")
async def send_code(body: SendCodeIn, request: Request, session: AsyncSession = Depends(get_session)) -> dict:
    if body.purpose not in sms.PURPOSES:
        raise HTTPException(422, "purpose 只能是 register、login 或 reset_password")
    phone = sms.require_phone(body.phone)
    ip = client_ip_from_request(request)
    await sms.check_rate_limits(session, phone, ip)

    user = await _user_by_phone(session, phone)
    if body.purpose == "register":
        if user is not None:
            raise HTTPException(409, "该手机号已注册，请直接登录")
        if not await sms.registration_open():
            raise HTTPException(403, "暂未开放注册，请联系管理员")
    else:
        if user is None:
            raise HTTPException(404, "该手机号未注册")
        if user.disabled:
            raise HTTPException(403, "该账号已被禁用")

    dev_code = await sms.issue_code(session, phone, body.purpose, ip)
    result = {
        "sent": True,
        "resend_after_sec": sms.RESEND_INTERVAL_SEC,
        "expires_in_sec": int(sms.CODE_TTL.total_seconds()),
    }
    if dev_code is not None:
        result["dev_code"] = dev_code
    return result


@public_router.post("/register", status_code=201)
async def register(body: RegisterIn, request: Request, session: AsyncSession = Depends(get_session)) -> dict:
    phone = sms.require_phone(body.phone)
    name = clean_name(body.name)
    password = passwords.require_strong_password(body.password)
    if not await sms.registration_open():
        raise HTTPException(403, "暂未开放注册，请联系管理员")
    if await _user_by_phone(session, phone) is not None:
        raise HTTPException(409, "该手机号已注册，请直接登录")
    await sms.verify_code(session, phone, "register", body.code)
    user = User(id=new_uuid(), phone=phone, name=name, disabled=False, created_at=utcnow())
    passwords.set_password(user, password)
    session.add(user)
    try:
        await session.flush()
    except IntegrityError as exc:
        await session.rollback()
        raise HTTPException(409, "该手机号已注册，请直接登录") from exc
    return await _auth_result(session, user, body.client, request)


@public_router.post("/login")
async def login(body: LoginIn, request: Request, session: AsyncSession = Depends(get_session)) -> dict:
    """SMS-code login (`code`) or password login (`password`)."""
    if (body.code is None) == (body.password is None):
        raise HTTPException(422, "请填写验证码或密码（二选一）")
    phone = sms.require_phone(body.phone)
    user = await _user_by_phone(session, phone)
    if user is None:
        raise HTTPException(404, "该手机号未注册")
    if user.disabled:
        raise HTTPException(403, "该账号已被禁用")
    if body.code is not None:
        await sms.verify_code(session, phone, "login", body.code)
        return await _auth_result(session, user, body.client, request)

    if not user.password_hash:
        raise HTTPException(400, "该账号尚未设置密码，请使用验证码登录，或通过“忘记密码”设置密码")
    passwords.ensure_not_locked(user)
    if not passwords.verify_password(body.password or "", user.password_hash):
        error = passwords.record_failure(user)
        await session.commit()
        raise error
    passwords.reset_failures(user)
    return await _auth_result(session, user, body.client, request)


@public_router.post("/password/reset")
async def reset_password(
    body: ResetPasswordIn, request: Request, session: AsyncSession = Depends(get_session)
) -> dict:
    """Set a new password with an SMS code (forgot password / first password). Signs out every other device."""
    phone = sms.require_phone(body.phone)
    password = passwords.require_strong_password(body.password)
    user = await _user_by_phone(session, phone)
    if user is None:
        raise HTTPException(404, "该手机号未注册")
    if user.disabled:
        raise HTTPException(403, "该账号已被禁用")
    await sms.verify_code(session, phone, sms.PURPOSE_RESET_PASSWORD, body.code)
    passwords.set_password(user, password)
    await revoke_user_sessions(session, user.id)
    return await _auth_result(session, user, body.client, request)


@router.post("/logout", status_code=204)
async def logout(ctx: AuthContext = Depends(require_client), session: AsyncSession = Depends(get_session)) -> Response:
    await session.execute(update(UserSession).where(UserSession.id == ctx.session_id).values(revoked=True))
    await session.commit()
    registry.forget_session(ctx.session_id)
    return Response(status_code=204)


@router.get("/me")
async def me(ctx: AuthContext = Depends(require_client), session: AsyncSession = Depends(get_session)) -> dict:
    user = await session.get(User, ctx.user_id)
    if user is None:
        raise HTTPException(401, "登录凭证无效，请重新登录")
    return user_dict(user)


@router.put("/me/password")
async def change_password(
    body: ChangePasswordIn, ctx: AuthContext = Depends(require_client), session: AsyncSession = Depends(get_session)
) -> dict:
    """Set (first time) or change the password. Other sessions of the user are signed out."""
    user = await session.get(User, ctx.user_id)
    if user is None:
        raise HTTPException(401, "登录凭证无效，请重新登录")
    password = passwords.require_strong_password(body.password)
    if user.password_hash:
        passwords.ensure_not_locked(user)
        if not passwords.verify_password(body.old_password or "", user.password_hash):
            error = passwords.record_failure(user, wrong="原密码错误")
            await session.commit()
            raise error
    passwords.set_password(user, password)
    others = (
        await session.execute(
            update(UserSession)
            .where(UserSession.user_id == user.id, UserSession.id != ctx.session_id, UserSession.revoked.is_(False))
            .values(revoked=True)
            .returning(UserSession.id)
        )
    ).scalars().all()
    await session.commit()
    for session_id in others:
        registry.forget_session(session_id)
    return user_dict(user)


@router.patch("/me")
async def update_me(
    body: ProfilePatch, ctx: AuthContext = Depends(require_client), session: AsyncSession = Depends(get_session)
) -> dict:
    user = await session.get(User, ctx.user_id)
    if user is None:
        raise HTTPException(401, "登录凭证无效，请重新登录")
    user.name = clean_name(body.name)
    await session.commit()
    registry.update_user(user.id, user.name, user.phone)
    return user_dict(user)
