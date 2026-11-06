"""User passwords: scrypt hashing, strength rules and brute-force lockout (§1.0)."""
from __future__ import annotations

import base64
import hashlib
import hmac
import re
import secrets
from datetime import timedelta

from fastapi import HTTPException

from user_ms.db.models import User
from user_ms.utils import utcnow

MIN_LENGTH = 8
MAX_LENGTH = 64
MAX_FAILURES = 5
LOCK_DURATION = timedelta(minutes=15)

# scrypt cost parameters (≈16 MiB, tens of ms per hash); stored with each hash so they can change later.
_N, _R, _P = 2**14, 8, 1
_SALT_BYTES = 16
_KEY_BYTES = 32
_SCHEME = "scrypt"

_LETTER_RE = re.compile(r"[A-Za-z]")
_DIGIT_RE = re.compile(r"\d")


def _b64(data: bytes) -> str:
    return base64.b64encode(data).decode()


def hash_password(password: str) -> str:
    salt = secrets.token_bytes(_SALT_BYTES)
    key = hashlib.scrypt(password.encode(), salt=salt, n=_N, r=_R, p=_P, dklen=_KEY_BYTES)
    return f"{_SCHEME}${_N}${_R}${_P}${_b64(salt)}${_b64(key)}"


def verify_password(password: str, stored: str | None) -> bool:
    if not stored:
        return False
    try:
        scheme, n, r, p, salt, key = stored.split("$")
        if scheme != _SCHEME:
            return False
        expected = base64.b64decode(key)
        actual = hashlib.scrypt(
            password.encode(), salt=base64.b64decode(salt), n=int(n), r=int(r), p=int(p), dklen=len(expected)
        )
    except (ValueError, TypeError):
        return False
    return hmac.compare_digest(actual, expected)


def require_strong_password(raw: str | None) -> str:
    """The password as given (never trimmed), or 422 with a Chinese reason."""
    password = raw or ""
    if not MIN_LENGTH <= len(password) <= MAX_LENGTH:
        raise HTTPException(422, f"密码长度需为 {MIN_LENGTH}-{MAX_LENGTH} 位")
    if password != password.strip():
        raise HTTPException(422, "密码首尾不能有空格")
    if not (_LETTER_RE.search(password) and _DIGIT_RE.search(password)):
        raise HTTPException(422, "密码需同时包含字母和数字")
    return password


def set_password(user: User, password: str) -> None:
    user.password_hash = hash_password(password)
    reset_failures(user)


def reset_failures(user: User) -> None:
    user.password_failed_count = 0
    user.password_locked_until = None


def ensure_not_locked(user: User) -> None:
    now = utcnow()
    if user.password_locked_until is not None and user.password_locked_until > now:
        minutes = max(1, int((user.password_locked_until - now).total_seconds() + 59) // 60)
        raise HTTPException(429, f"密码错误次数过多，请 {minutes} 分钟后再试，或使用验证码登录")


def record_failure(user: User, wrong: str = "手机号或密码错误") -> HTTPException:
    """Count a wrong password (caller commits) and return the error to raise."""
    if user.password_locked_until is not None and user.password_locked_until <= utcnow():
        reset_failures(user)  # the previous lock has expired: start a fresh window
    user.password_failed_count = (user.password_failed_count or 0) + 1
    remaining = MAX_FAILURES - user.password_failed_count
    if remaining <= 0:
        user.password_locked_until = utcnow() + LOCK_DURATION
        minutes = int(LOCK_DURATION.total_seconds()) // 60
        return HTTPException(429, f"密码错误次数过多，请 {minutes} 分钟后再试，或使用验证码登录")
    return HTTPException(400, f"{wrong}，还可尝试 {remaining} 次")
