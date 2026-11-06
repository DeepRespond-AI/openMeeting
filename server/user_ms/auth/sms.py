"""Phone normalization, SMS configuration, verification codes and send rate limits."""
from __future__ import annotations

import hashlib
import hmac
import logging
import re
import secrets
from dataclasses import dataclass
from datetime import timedelta

from fastapi import HTTPException
from sqlalchemy import delete, func, select, update
from sqlalchemy.ext.asyncio import AsyncSession

from user_ms.auth import aliyun_sms
from user_ms.config import get_settings
from user_ms.db.models import SmsCode, SmsLog
from user_ms.db.settings_store import get_setting, set_setting
from user_ms.utils import new_uuid, secret_box, utcnow

logger = logging.getLogger(__name__)

SMS_CONFIG_KEY = "sms_config"
REGISTRATION_OPEN_KEY = "registration_open"

CODE_LENGTH = 6
CODE_TTL = timedelta(minutes=5)
MAX_ATTEMPTS = 5
RESEND_INTERVAL_SEC = 60
PHONE_DAILY_LIMIT = 10
IP_HOURLY_LIMIT = 30
PURPOSE_RESET_PASSWORD = "reset_password"
PURPOSES = ("register", "login", PURPOSE_RESET_PASSWORD)

_PHONE_RE = re.compile(r"^1[3-9]\d{9}$")


# ----------------------------------------------------------------- phone


def normalize_phone(raw: str | None) -> str | None:
    """Return the 11-digit mainland mobile number, or None when invalid.

    Strips spaces/dashes/parentheses and a leading `+86` / `0086` / `86` country code.
    """
    if not raw:
        return None
    s = re.sub(r"[\s\-()（）]", "", str(raw))
    if s.startswith("+"):
        if not s.startswith("+86"):
            return None  # other country codes are not supported
        s = s[3:]
    elif s.startswith("0086"):
        s = s[4:]
    elif s.startswith("86") and len(s) == 13:
        s = s[2:]
    return s if _PHONE_RE.match(s) else None


def require_phone(raw: str | None) -> str:
    phone = normalize_phone(raw)
    if phone is None:
        raise HTTPException(422, "手机号格式不正确，请输入 11 位中国大陆手机号")
    return phone


# ----------------------------------------------------------------- config


@dataclass(frozen=True)
class SmsConfig:
    access_key_id: str | None
    access_key_secret: str | None
    sign_name: str | None
    template_code: str | None
    template_param: str
    endpoint: str

    @property
    def ready(self) -> bool:
        return bool(self.access_key_id and self.access_key_secret and self.sign_name and self.template_code)


async def load_stored_sms_config() -> dict:
    raw = await get_setting(SMS_CONFIG_KEY, None)
    return dict(raw) if isinstance(raw, dict) else {}


async def save_stored_sms_config(data: dict) -> None:
    await set_setting(SMS_CONFIG_KEY, data)


async def load_sms_config() -> SmsConfig:
    """Effective config: values saved in system_settings, overridden by OPENMEETING_SMS_* env vars."""
    stored = await load_stored_sms_config()
    s = get_settings()
    secret = s.sms_access_key_secret or secret_box().decrypt(stored.get("access_key_secret_enc"))
    return SmsConfig(
        access_key_id=s.sms_access_key_id or stored.get("access_key_id") or None,
        access_key_secret=secret or None,
        sign_name=s.sms_sign_name or stored.get("sign_name") or None,
        template_code=s.sms_template_code or stored.get("template_code") or None,
        template_param=s.sms_template_param or stored.get("template_param") or "code",
        endpoint=s.sms_endpoint or stored.get("endpoint") or aliyun_sms.DEFAULT_ENDPOINT,
    )


async def registration_open() -> bool:
    return bool(await get_setting(REGISTRATION_OPEN_KEY, True))


async def set_registration_open(value: bool) -> None:
    await set_setting(REGISTRATION_OPEN_KEY, bool(value))


def dev_mode_without_sms(cfg: SmsConfig) -> bool:
    return get_settings().is_dev and not cfg.ready


# ----------------------------------------------------------------- codes


def generate_code() -> str:
    return "".join(secrets.choice("0123456789") for _ in range(CODE_LENGTH))


def hash_code(phone: str, purpose: str, code: str) -> str:
    pepper = hashlib.sha256(("openmeeting-sms:" + get_settings().resolved_secret_key()).encode()).digest()
    return hmac.new(pepper, f"{phone}|{purpose}|{code}".encode(), hashlib.sha256).hexdigest()


async def check_rate_limits(session: AsyncSession, phone: str, ip: str | None) -> None:
    now = utcnow()
    if ip:
        ip_count = (
            await session.execute(
                select(func.count(SmsLog.id)).where(SmsLog.ip == ip, SmsLog.created_at > now - timedelta(hours=1))
            )
        ).scalar_one()
        if ip_count >= IP_HOURLY_LIMIT:
            raise HTTPException(429, "请求过于频繁，请稍后再试")
    last = (
        await session.execute(
            select(func.max(SmsLog.created_at)).where(SmsLog.phone == phone, SmsLog.purpose != "test")
        )
    ).scalar_one()
    if last is not None:
        wait = RESEND_INTERVAL_SEC - int((now - last).total_seconds())
        if wait > 0:
            raise HTTPException(429, f"发送过于频繁，请 {wait} 秒后再试")
    day_count = (
        await session.execute(
            select(func.count(SmsLog.id)).where(
                SmsLog.phone == phone, SmsLog.purpose != "test", SmsLog.created_at > now - timedelta(days=1)
            )
        )
    ).scalar_one()
    if day_count >= PHONE_DAILY_LIMIT:
        raise HTTPException(429, "该手机号今日获取验证码次数已达上限，请明天再试")


async def log_sms(
    session: AsyncSession, phone: str, purpose: str, ip: str | None, ok: bool, error: str | None,
    request_id: str | None,
) -> None:
    session.add(
        SmsLog(phone=phone, purpose=purpose, ip=ip, ok=ok, error=error, request_id=request_id, created_at=utcnow())
    )


async def deliver_code(cfg: SmsConfig, phone: str, code: str) -> aliyun_sms.SmsSendResult:
    return await aliyun_sms.send_sms(
        endpoint=cfg.endpoint,
        access_key_id=cfg.access_key_id or "",
        access_key_secret=cfg.access_key_secret or "",
        phone=phone,
        sign_name=cfg.sign_name or "",
        template_code=cfg.template_code or "",
        template_param={cfg.template_param or "code": code},
    )


async def issue_code(session: AsyncSession, phone: str, purpose: str, ip: str | None) -> str | None:
    """Generate, deliver and store a code. Returns the code only in dev mode without SMS config."""
    cfg = await load_sms_config()
    dev = dev_mode_without_sms(cfg)
    if not cfg.ready and not dev:
        raise HTTPException(503, "短信服务未配置，请联系管理员")

    code = generate_code()
    if dev:
        logger.warning("[dev] SMS code for %s (%s): %s", phone, purpose, code)
        await log_sms(session, phone, purpose, ip, True, "开发模式：未实际发送", None)
    else:
        result = await deliver_code(cfg, phone, code)
        await log_sms(session, phone, purpose, ip, result.ok, result.message, result.request_id)
        if not result.ok:
            await session.commit()
            status = 429 if result.code in ("isv.BUSINESS_LIMIT_CONTROL", "isv.DAY_LIMIT_CONTROL") else 502
            raise HTTPException(status, result.message or "短信发送失败")

    now = utcnow()
    # A new code supersedes older unused codes for the same phone + purpose; prune stale rows.
    await session.execute(
        update(SmsCode)
        .where(SmsCode.phone == phone, SmsCode.purpose == purpose, SmsCode.consumed_at.is_(None))
        .values(consumed_at=now)
    )
    await session.execute(delete(SmsCode).where(SmsCode.created_at < now - timedelta(days=1)))
    session.add(
        SmsCode(
            id=new_uuid(), phone=phone, purpose=purpose, code_hash=hash_code(phone, purpose, code), ip=ip,
            attempts=0, created_at=now, expires_at=now + CODE_TTL,
        )
    )
    await session.commit()
    return code if dev else None


async def verify_code(session: AsyncSession, phone: str, purpose: str, code: str) -> None:
    """Consume a valid code (caller commits on success) or raise 400. Wrong attempts are committed immediately."""
    code = (code or "").strip()
    row = (
        await session.execute(
            select(SmsCode)
            .where(SmsCode.phone == phone, SmsCode.purpose == purpose, SmsCode.consumed_at.is_(None))
            .order_by(SmsCode.created_at.desc())
            .limit(1)
            .with_for_update()
        )
    ).scalar_one_or_none()
    if row is None:
        await session.rollback()
        raise HTTPException(400, "验证码无效，请重新获取")
    now = utcnow()
    if row.expires_at <= now:
        await session.rollback()
        raise HTTPException(400, "验证码已过期，请重新获取")
    if row.attempts >= MAX_ATTEMPTS:
        await session.rollback()
        raise HTTPException(400, "验证码错误次数过多，请重新获取")
    if not hmac.compare_digest(row.code_hash, hash_code(phone, purpose, code)):
        row.attempts += 1
        remaining = MAX_ATTEMPTS - row.attempts
        if remaining <= 0:
            row.consumed_at = now
        await session.commit()
        if remaining <= 0:
            raise HTTPException(400, "验证码错误次数过多，请重新获取")
        raise HTTPException(400, f"验证码错误，还可尝试 {remaining} 次")
    row.consumed_at = now
