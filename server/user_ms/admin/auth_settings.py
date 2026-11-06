"""Admin: registration switch, Aliyun SMS configuration, SMS test and SMS audit logs."""
from __future__ import annotations

from fastapi import APIRouter, Depends, Query, Request
from pydantic import BaseModel
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from user_ms.auth import sms
from user_ms.auth.aliyun_sms import DEFAULT_ENDPOINT
from user_ms.db.models import SmsLog
from user_ms.db.session import get_session
from user_ms.monitor.connections import client_ip_from_request
from user_ms.utils import iso, secret_box

router = APIRouter(tags=["admin-auth-settings"])

MAX_LIMIT = 100


class SmsSettingsIn(BaseModel):
    access_key_id: str | None = None
    access_key_secret: str | None = None  # omitted / null = keep, "" = clear
    sign_name: str | None = None
    template_code: str | None = None
    template_param: str | None = None
    endpoint: str | None = None


class AuthSettingsIn(BaseModel):
    registration_open: bool | None = None
    sms: SmsSettingsIn | None = None


class SmsTestIn(BaseModel):
    phone: str


async def _settings_dict() -> dict:
    cfg = await sms.load_sms_config()
    return {
        "registration_open": await sms.registration_open(),
        "sms": {
            "access_key_id": cfg.access_key_id,
            "access_key_secret_set": bool(cfg.access_key_secret),
            "sign_name": cfg.sign_name,
            "template_code": cfg.template_code,
            "template_param": cfg.template_param,
            "endpoint": cfg.endpoint,
        },
        "sms_ready": cfg.ready,
    }


@router.get("/auth-settings")
async def get_auth_settings() -> dict:
    return await _settings_dict()


@router.put("/auth-settings")
async def put_auth_settings(body: AuthSettingsIn) -> dict:
    if body.registration_open is not None:
        await sms.set_registration_open(body.registration_open)
    if body.sms is not None:
        stored = await sms.load_stored_sms_config()
        given = body.sms.model_fields_set
        for key in ("access_key_id", "sign_name", "template_code"):
            if key in given:
                stored[key] = (getattr(body.sms, key) or "").strip() or None
        if "template_param" in given:
            stored["template_param"] = (body.sms.template_param or "").strip() or "code"
        if "endpoint" in given:
            endpoint = (body.sms.endpoint or "").strip()
            endpoint = endpoint.removeprefix("https://").removeprefix("http://").rstrip("/")
            stored["endpoint"] = endpoint or DEFAULT_ENDPOINT
        if body.sms.access_key_secret is not None:
            secret = body.sms.access_key_secret.strip()
            stored["access_key_secret_enc"] = secret_box().encrypt(secret) if secret else None
        await sms.save_stored_sms_config(stored)
    return await _settings_dict()


@router.post("/auth-settings/sms-test")
async def sms_test(body: SmsTestIn, request: Request, session: AsyncSession = Depends(get_session)) -> dict:
    phone = sms.normalize_phone(body.phone)
    if phone is None:
        return {"ok": False, "request_id": None, "error": "手机号格式不正确，请输入 11 位中国大陆手机号"}
    cfg = await sms.load_sms_config()
    if not cfg.ready:
        return {"ok": False, "request_id": None, "error": "短信配置不完整：请填写 AccessKey ID/Secret、签名和模板编号"}
    result = await sms.deliver_code(cfg, phone, sms.generate_code())
    await sms.log_sms(session, phone, "test", client_ip_from_request(request), result.ok, result.message,
                      result.request_id)
    await session.commit()
    return {"ok": result.ok, "request_id": result.request_id, "error": result.message}


@router.get("/sms-logs")
async def sms_logs(
    phone: str | None = None,
    limit: int = Query(20, ge=1),
    offset: int = Query(0, ge=0),
    session: AsyncSession = Depends(get_session),
) -> dict:
    limit = min(limit, MAX_LIMIT)
    conditions = []
    if phone and phone.strip():
        normalized = sms.normalize_phone(phone)
        conditions.append(
            SmsLog.phone == normalized if normalized else SmsLog.phone.like(f"%{phone.strip()}%")
        )
    total = (await session.execute(select(func.count(SmsLog.id)).where(*conditions))).scalar_one()
    rows = (
        await session.execute(
            select(SmsLog).where(*conditions).order_by(SmsLog.created_at.desc(), SmsLog.id.desc())
            .limit(limit).offset(offset)
        )
    ).scalars().all()
    return {
        "items": [
            {"id": r.id, "phone": r.phone, "purpose": r.purpose, "ip": r.ip, "ok": r.ok, "error": r.error,
             "created_at": iso(r.created_at)}
            for r in rows
        ],
        "total": total,
    }
