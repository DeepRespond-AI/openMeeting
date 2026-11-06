from __future__ import annotations

import base64
import hashlib
import uuid
from datetime import UTC, datetime

from cryptography.fernet import Fernet, InvalidToken


def utcnow() -> datetime:
    return datetime.now(UTC)


def iso(dt: datetime | None) -> str | None:
    """ISO-8601 UTC with second precision and trailing Z (API convention)."""
    if dt is None:
        return None
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=UTC)
    return dt.astimezone(UTC).strftime("%Y-%m-%dT%H:%M:%SZ")


def iso_ms(dt: datetime) -> str:
    dt = dt.astimezone(UTC)
    return dt.strftime("%Y-%m-%dT%H:%M:%S.") + f"{dt.microsecond // 1000:03d}Z"


def rfc3339_nanos(dt: datetime) -> str:
    """Matches chrono `to_rfc3339_opts(SecondsFormat::Nanos, true)`."""
    dt = dt.astimezone(UTC)
    return dt.strftime("%Y-%m-%dT%H:%M:%S.") + f"{dt.microsecond:06d}000Z"


def rfc3339(dt: datetime | None) -> str | None:
    """Matches chrono `to_rfc3339()` (+00:00 offset)."""
    if dt is None:
        return None
    return dt.astimezone(UTC).isoformat()


def new_meeting_id() -> str:
    return f"meeting-{uuid.uuid4()}"


def new_job_id() -> str:
    return f"job-{uuid.uuid4()}"


def new_uuid() -> str:
    return str(uuid.uuid4())


class SecretBox:
    """Fernet encryption for secrets at rest (LLM / cloud STT API keys)."""

    def __init__(self, secret: str) -> None:
        key = base64.urlsafe_b64encode(hashlib.sha256(("openmeeting-fernet:" + secret).encode()).digest())
        self._fernet = Fernet(key)

    def encrypt(self, plaintext: str) -> str:
        return self._fernet.encrypt(plaintext.encode()).decode()

    def decrypt(self, token: str | None) -> str | None:
        if not token:
            return None
        try:
            return self._fernet.decrypt(token.encode()).decode()
        except InvalidToken:
            return None


_box: SecretBox | None = None


def secret_box() -> SecretBox:
    global _box
    if _box is None:
        from stt_ms.config import get_settings

        _box = SecretBox(get_settings().resolved_secret_key())
    return _box
