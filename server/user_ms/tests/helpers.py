"""Shared test helpers (imported by conftest and tests)."""
from __future__ import annotations

import itertools
from urllib.parse import quote

import httpx
from sqlalchemy import text

from user_ms.auth.sessions import hash_token
from user_ms.db.session import session_factory

_phone_seq = itertools.count(1)

PASSWORD = "Meeting2026"


def next_phone() -> str:
    return f"138{next(_phone_seq):08d}"


async def identity_headers(token: str, user: dict) -> dict:
    """网关注入给下游的身份头（user_ms/meeting_ms 信任它们，不再校验 Bearer）。

    与 gateway_ms 一致：X-User-Name 百分号编码（HTTP 头仅 ASCII），X-Session-ID 由 token
    反查 sessions 表（注册/登录响应不回传会话 ID），有手机号时带 X-User-Phone。
    """
    async with session_factory()() as session:
        row = (await session.execute(
            text("SELECT id FROM sessions WHERE token_hash = :h"), {"h": hash_token(token)}
        )).first()
    headers = {"X-User-ID": user["id"], "X-User-Name": quote(user["name"], safe="")}
    if row is not None:
        headers["X-Session-ID"] = row[0]
    if user.get("phone"):
        headers["X-User-Phone"] = user["phone"]
    return headers


async def register_via_sms(
    c: httpx.AsyncClient, name: str, phone: str | None = None, password: str = PASSWORD, **client_info: str
) -> dict:
    """Register through the dev SMS flow; returns {"user", "token", "phone", "headers", "result"}."""
    phone = phone or next_phone()
    r = await c.post("/api/v1/auth/sms/send", json={"phone": phone, "purpose": "register"})
    assert r.status_code == 200, r.text
    code = r.json()["dev_code"]
    client = {"client_id": f"cid-{name}", "hostname": f"{name}-mbp", "os": "macos", "app_version": "1.0.0",
              **client_info}
    r = await c.post("/api/v1/auth/register", json={"phone": phone, "code": code, "name": name, "password": password,
                                                    "client": client})
    assert r.status_code == 201, r.text
    result = r.json()
    return {"user": result["user"], "token": result["token"], "phone": phone, "result": result,
            "headers": await identity_headers(result["token"], result["user"])}
