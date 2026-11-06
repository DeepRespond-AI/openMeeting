"""Password login next to SMS-code login (§1.0)."""
from __future__ import annotations

import httpx
from sqlalchemy import text

from user_ms.auth.passwords import hash_password, verify_password
from user_ms.auth.sessions import hash_token
from user_ms.db.session import session_factory
from user_ms.tests.helpers import PASSWORD, identity_headers, next_phone, register_via_sms

CLIENT = {"client_id": "cid-pw", "hostname": "mbp", "os": "macos", "app_version": "1.0.0"}
LOGIN = "/api/v1/auth/login"


async def _sql(stmt: str, **params) -> list:
    async with session_factory()() as session:
        result = await session.execute(text(stmt), params)
        rows = result.fetchall() if result.returns_rows else []
        await session.commit()
        return rows


async def _headers(result: dict) -> dict:
    """Gateway-injected identity headers built from an auth response."""
    return await identity_headers(result["token"], result["user"])


async def _code(client: httpx.AsyncClient, phone: str, purpose: str) -> str:
    await _sql("UPDATE sms_logs SET created_at = created_at - interval '2 minutes'")
    r = await client.post("/api/v1/auth/sms/send", json={"phone": phone, "purpose": purpose})
    assert r.status_code == 200, r.text
    return r.json()["dev_code"]


def test_hashing() -> None:
    stored = hash_password("abc12345")
    assert stored.startswith("scrypt$") and "abc12345" not in stored
    assert hash_password("abc12345") != stored  # salted
    assert verify_password("abc12345", stored)
    assert not verify_password("abc12346", stored)
    assert not verify_password("abc12345", None) and not verify_password("abc12345", "garbage")


async def test_config_exposes_password_rules(client: httpx.AsyncClient) -> None:
    body = (await client.get("/api/v1/auth/config")).json()
    assert body["password_min_length"] == 8 and body["password_max_length"] == 64


async def test_register_requires_strong_password(client: httpx.AsyncClient) -> None:
    phone = next_phone()
    code = await _code(client, phone, "register")
    for bad, reason in [(None, "长度"), ("short1", "长度"), ("onlyletters", "字母和数字"), ("12345678", "字母和数字"),
                        (" abc12345", "空格")]:
        r = await client.post("/api/v1/auth/register", json={"phone": phone, "code": code, "name": "x", "password": bad})
        assert r.status_code == 422 and reason in r.json()["detail"], (bad, r.text)
    # A rejected password does not burn the code.
    r = await client.post("/api/v1/auth/register", json={"phone": phone, "code": code, "name": "x", "password": PASSWORD})
    assert r.status_code == 201 and r.json()["user"]["has_password"] is True
    stored = (await _sql("SELECT password_hash FROM users WHERE phone = :p", p=phone))[0][0]
    assert stored.startswith("scrypt$") and PASSWORD not in stored


async def test_password_login(client: httpx.AsyncClient) -> None:
    u = await register_via_sms(client, "alice")
    r = await client.post(LOGIN, json={"phone": f"+86 {u['phone']}", "password": PASSWORD, "client": CLIENT})
    assert r.status_code == 200, r.text
    assert r.json()["user"]["id"] == u["user"]["id"] and r.json()["token"] != u["token"]
    h = await _headers(r.json())
    assert (await client.get("/api/v1/auth/me", headers=h)).status_code == 200

    # Exactly one of code / password.
    assert (await client.post(LOGIN, json={"phone": u["phone"]})).status_code == 422
    both = {"phone": u["phone"], "code": "123456", "password": PASSWORD}
    assert (await client.post(LOGIN, json=both)).status_code == 422
    assert (await client.post(LOGIN, json={"phone": next_phone(), "password": PASSWORD})).status_code == 404


async def test_wrong_password_lockout(client: httpx.AsyncClient) -> None:
    u = await register_via_sms(client, "bob")
    for remaining in (4, 3, 2, 1):
        r = await client.post(LOGIN, json={"phone": u["phone"], "password": "wrong1234"})
        assert r.status_code == 400 and f"还可尝试 {remaining} 次" in r.json()["detail"]
    r = await client.post(LOGIN, json={"phone": u["phone"], "password": "wrong1234"})
    assert r.status_code == 429 and "15 分钟" in r.json()["detail"]
    # Locked: even the right password is refused, but SMS login still works.
    assert (await client.post(LOGIN, json={"phone": u["phone"], "password": PASSWORD})).status_code == 429
    code = await _code(client, u["phone"], "login")
    assert (await client.post(LOGIN, json={"phone": u["phone"], "code": code})).status_code == 200

    # Lock expired → a fresh window; a successful login clears the counter.
    await _sql("UPDATE users SET password_locked_until = now() - interval '1 second' WHERE phone = :p", p=u["phone"])
    assert (await client.post(LOGIN, json={"phone": u["phone"], "password": "wrong1234"})).status_code == 400
    assert (await client.post(LOGIN, json={"phone": u["phone"], "password": PASSWORD})).status_code == 200
    rows = await _sql("SELECT password_failed_count, password_locked_until FROM users WHERE phone = :p", p=u["phone"])
    assert rows[0] == (0, None)


async def test_legacy_user_without_password(client: httpx.AsyncClient) -> None:
    u = await register_via_sms(client, "carol")
    await _sql("UPDATE users SET password_hash = NULL WHERE phone = :p", p=u["phone"])
    assert (await client.get("/api/v1/auth/me", headers=u["headers"])).json()["has_password"] is False
    r = await client.post(LOGIN, json={"phone": u["phone"], "password": PASSWORD})
    assert r.status_code == 400 and "尚未设置密码" in r.json()["detail"]

    # First password: no old password needed.
    r = await client.put("/api/v1/auth/me/password", json={"password": "NewPass2026"}, headers=u["headers"])
    assert r.status_code == 200 and r.json()["has_password"] is True
    assert (await client.post(LOGIN, json={"phone": u["phone"], "password": "NewPass2026"})).status_code == 200


async def test_change_password_signs_out_other_devices(client: httpx.AsyncClient) -> None:
    u = await register_via_sms(client, "dave")
    other = (await client.post(LOGIN, json={"phone": u["phone"], "password": PASSWORD})).json()
    other_token_hash = hash_token(other["token"])

    url = "/api/v1/auth/me/password"
    r = await client.put(url, json={"old_password": "nope1234", "password": "Changed2026"}, headers=u["headers"])
    assert r.status_code == 400 and "原密码错误" in r.json()["detail"]
    assert (await client.put(url, json={"password": "Changed2026"}, headers=u["headers"])).status_code == 400
    r = await client.put(url, json={"old_password": PASSWORD, "password": "weak"}, headers=u["headers"])
    assert r.status_code == 422
    r = await client.put(url, json={"old_password": PASSWORD, "password": "Changed2026"}, headers=u["headers"])
    assert r.status_code == 200, r.text

    assert (await client.get("/api/v1/auth/me", headers=u["headers"])).status_code == 200  # this device stays
    # 其它设备会话已在数据库吊销（401 拒绝语义在网关，见 gateway_ms/tests）。
    rows = dict(await _sql("SELECT token_hash, revoked FROM sessions"))
    revoked = {th for th, rv in rows.items() if rv}
    assert revoked == {other_token_hash}
    assert (await client.post(LOGIN, json={"phone": u["phone"], "password": PASSWORD})).status_code == 400
    assert (await client.post(LOGIN, json={"phone": u["phone"], "password": "Changed2026"})).status_code == 200


async def test_reset_password_with_sms(client: httpx.AsyncClient, admin: httpx.AsyncClient) -> None:
    u = await register_via_sms(client, "erin")
    # Reset codes are only sent to registered phones.
    r = await client.post("/api/v1/auth/sms/send", json={"phone": next_phone(), "purpose": "reset_password"})
    assert r.status_code == 404
    code = await _code(client, u["phone"], "reset_password")

    reset = "/api/v1/auth/password/reset"
    assert (await client.post(reset, json={"phone": u["phone"], "code": code, "password": "x"})).status_code == 422
    # A login code cannot be used for a reset.
    login_code = await _code(client, u["phone"], "login")
    r = await client.post(reset, json={"phone": u["phone"], "code": login_code, "password": "Reset2026"})
    assert r.status_code == 400

    # Lock the account first: the reset clears the lock.
    await _sql("UPDATE users SET password_failed_count = 5, password_locked_until = now() + interval '10 minutes' "
               "WHERE phone = :p", p=u["phone"])
    r = await client.post(reset, json={"phone": u["phone"], "code": code, "password": "Reset2026", "client": CLIENT})
    assert r.status_code == 200, r.text
    assert r.json()["token"].startswith("ms_") and r.json()["user"]["has_password"] is True
    # 旧会话全部吊销，重置流程签发的新会话保持有效（401 拒绝语义在网关，见 gateway_ms/tests）。
    new_hash = hash_token(r.json()["token"])
    rows = dict(await _sql("SELECT token_hash, revoked FROM sessions"))
    assert rows[new_hash] is False
    assert all(rv for th, rv in rows.items() if th != new_hash)
    assert (await client.post(LOGIN, json={"phone": u["phone"], "password": "Reset2026"})).status_code == 200

    users = (await admin.get("/admin/api/users")).json()["items"]
    assert next(x for x in users if x["phone"] == u["phone"])["has_password"] is True

    # Disabled users cannot reset.
    await _sql("UPDATE users SET disabled = true WHERE phone = :p", p=u["phone"])
    r = await client.post(reset, json={"phone": u["phone"], "code": "123456", "password": "Reset2027"})
    assert r.status_code == 403
