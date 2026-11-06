from __future__ import annotations

import json
from urllib.parse import parse_qsl

import httpx
import pytest
import respx
from sqlalchemy import text

from user_ms.auth import aliyun_sms
from user_ms.auth.sessions import hash_token
from user_ms.config import get_settings
from user_ms.db.session import session_factory
from user_ms.tests.helpers import PASSWORD, identity_headers, next_phone, register_via_sms
from user_ms.utils import utcnow

CLIENT = {"client_id": "cid-1", "hostname": "mbp", "os": "macos", "app_version": "1.0.0"}
SMS_URL = "https://dysmsapi.aliyuncs.com/"


async def _sql(stmt: str, **params) -> list:
    async with session_factory()() as session:
        result = await session.execute(text(stmt), params)
        rows = result.fetchall() if result.returns_rows else []
        await session.commit()
        return rows


async def _age_sms_logs(seconds: int = 120) -> None:
    """Pretend earlier sends happened `seconds` ago so the 60 s resend limit does not apply."""
    await _sql("UPDATE sms_logs SET created_at = created_at - make_interval(secs => :s)", s=seconds)


async def _send(client: httpx.AsyncClient, phone: str, purpose: str, **headers: str) -> httpx.Response:
    return await client.post("/api/v1/auth/sms/send", json={"phone": phone, "purpose": purpose}, headers=headers)


async def _login(client: httpx.AsyncClient, phone: str) -> dict:
    await _age_sms_logs()
    r = await _send(client, phone, "login")
    assert r.status_code == 200, r.text
    r = await client.post("/api/v1/auth/login", json={"phone": phone, "code": r.json()["dev_code"], "client": CLIENT})
    assert r.status_code == 200, r.text
    return r.json()


async def _headers(result: dict) -> dict:
    """Gateway-injected identity headers built from an auth response (user_ms trusts them)."""
    return await identity_headers(result["token"], result["user"])


async def _configure_sms(admin: httpx.AsyncClient) -> None:
    r = await admin.put(
        "/admin/api/auth-settings",
        json={"sms": {"access_key_id": "LTAIkey", "access_key_secret": "s3cr3t", "sign_name": "深应会议",
                      "template_code": "SMS_123"}},
    )
    assert r.status_code == 200 and r.json()["sms_ready"] is True


# ----------------------------------------------------------------- admin login


async def test_admin_login_required(client: httpx.AsyncClient) -> None:
    assert (await client.get("/admin/api/me")).status_code == 401
    r = await client.post("/admin/api/login", json={"password": "wrong"})
    assert r.status_code == 401
    assert r.json()["detail"]


async def test_admin_login_cookie_and_bearer(client: httpx.AsyncClient) -> None:
    r = await client.post("/admin/api/login", json={"password": "test-admin-pw"})
    assert r.status_code == 200
    token = r.json()["token"]
    assert "openmeeting_admin" in r.cookies
    assert (await client.get("/admin/api/me")).json() == {"ok": True}
    client.cookies.clear()
    r = await client.get("/admin/api/me", headers={"Authorization": f"Bearer {token}"})
    assert r.status_code == 200
    await client.post("/admin/api/logout")


async def test_tokens_endpoints_removed(admin: httpx.AsyncClient) -> None:
    assert (await admin.get("/admin/api/tokens")).status_code == 404
    assert (await admin.post("/admin/api/tokens", json={"user_id": "x", "name": "y"})).status_code in (404, 405)


# ----------------------------------------------------------------- phone auth


async def test_auth_config(client: httpx.AsyncClient) -> None:
    r = await client.get("/api/v1/auth/config")
    assert r.status_code == 200
    body = r.json()
    assert body["registration_open"] is True and body["sms_ready"] is True  # dev mode
    assert body["code_length"] == 6 and body["resend_interval_sec"] == 60 and body["server_version"]


async def test_register_login_me_logout(client: httpx.AsyncClient) -> None:
    # 会话拒绝（401/403）的语义在网关（gateway_ms/tests）；这里直接验证 user_ms 的业务逻辑。
    r = await client.get("/api/v1/auth/me")
    assert r.status_code == 401  # 无网关注入的身份头

    r = await _send(client, "+86 138-0013-8000", "register")
    assert r.status_code == 200, r.text
    body = r.json()
    assert body["sent"] is True and body["resend_after_sec"] == 60 and body["expires_in_sec"] == 300
    code = body["dev_code"]
    assert len(code) == 6 and code.isdigit()

    r = await client.post(
        "/api/v1/auth/register", json={"phone": "13800138000", "code": code, "name": " 张三 ", "password": PASSWORD, "client": CLIENT}
    )
    assert r.status_code == 201, r.text
    result = r.json()
    token = result["token"]
    assert token.startswith("ms_") and len(token) == 46
    assert set(result["user"]) == {"id", "phone", "name", "created_at", "last_login_at", "has_password"}
    assert result["user"]["has_password"] is True
    assert result["user"]["phone"] == "13800138000" and result["user"]["name"] == "张三"
    assert result["user"]["last_login_at"] is not None and result["expires_at"].endswith("Z")
    h = await _headers(result)

    # The code is single use.
    r = await client.post("/api/v1/auth/register", json={"phone": "13800138001", "code": code, "name": "x", "password": PASSWORD})
    assert r.status_code == 400

    assert (await client.get("/api/v1/auth/me", headers=h)).json()["phone"] == "13800138000"
    r = await client.patch("/api/v1/auth/me", json={"name": "张三丰"}, headers=h)
    assert r.status_code == 200 and r.json()["name"] == "张三丰"
    assert (await client.patch("/api/v1/auth/me", json={"name": "  "}, headers=h)).status_code == 422

    # Login creates a second, independent session.
    login = await _login(client, "138 0013 8000")
    assert login["user"]["id"] == result["user"]["id"] and login["token"] != token
    h2 = await _headers(login)

    # 登出只吊销调用方自己的会话（X-Session-ID 由网关注入，helpers 按 token 反查）。
    assert (await client.post("/api/v1/auth/logout", headers=h)).status_code == 204
    rows = await _sql("SELECT token_hash, revoked FROM sessions ORDER BY created_at, id")
    revoked = {th for th, rv in rows if rv}
    assert hash_token(token) in revoked and hash_token(login["token"]) not in revoked
    assert (await client.get("/api/v1/auth/me", headers=h2)).json()["phone"] == "13800138000"

    # Only hashes are stored.
    rows = await _sql("SELECT token_hash FROM sessions")
    assert all(len(r[0]) == 64 and r[0] != token for r in rows)
    logs = await _sql("SELECT phone, purpose, ok FROM sms_logs ORDER BY id")
    assert [(p, pu) for p, pu, _ in logs] == [("13800138000", "register"), ("13800138000", "login")]
    codes = await _sql("SELECT code_hash FROM sms_codes")
    assert code not in {c[0] for c in codes}


async def test_invalid_phone_and_purpose(client: httpx.AsyncClient) -> None:
    r = await _send(client, "12345", "register")
    assert r.status_code == 422 and "手机号" in r.json()["detail"]
    assert (await _send(client, "12800138000", "register")).status_code == 422
    assert (await _send(client, "13800138000", "reset")).status_code == 422


async def test_wrong_code_attempts(client: httpx.AsyncClient) -> None:
    phone = next_phone()
    code = (await _send(client, phone, "register")).json()["dev_code"]
    wrong = "000000" if code != "000000" else "111111"
    details = []
    for _ in range(5):
        r = await client.post("/api/v1/auth/register", json={"phone": phone, "code": wrong, "name": "x", "password": PASSWORD})
        assert r.status_code == 400
        details.append(r.json()["detail"])
    assert "4" in details[0] and "过多" in details[-1]
    # The code is invalidated after 5 wrong attempts, even the right one fails now.
    r = await client.post("/api/v1/auth/register", json={"phone": phone, "code": code, "name": "x", "password": PASSWORD})
    assert r.status_code == 400
    # A fresh code works.
    await _age_sms_logs()
    code = (await _send(client, phone, "register")).json()["dev_code"]
    r = await client.post("/api/v1/auth/register", json={"phone": phone, "code": code, "name": "x", "password": PASSWORD})
    assert r.status_code == 201


async def test_code_expiry_and_supersede(client: httpx.AsyncClient) -> None:
    phone = next_phone()
    old = (await _send(client, phone, "register")).json()["dev_code"]
    await _sql("UPDATE sms_codes SET expires_at = now() - interval '1 second'")
    r = await client.post("/api/v1/auth/register", json={"phone": phone, "code": old, "name": "x", "password": PASSWORD})
    assert r.status_code == 400 and "过期" in r.json()["detail"]

    await _age_sms_logs()
    first = (await _send(client, phone, "register")).json()["dev_code"]
    await _age_sms_logs()
    second = (await _send(client, phone, "register")).json()["dev_code"]
    if first != second:
        r = await client.post("/api/v1/auth/register", json={"phone": phone, "code": first, "name": "x", "password": PASSWORD})
        assert r.status_code == 400  # superseded by the newer code
    r = await client.post("/api/v1/auth/register", json={"phone": phone, "code": second, "name": "x", "password": PASSWORD})
    assert r.status_code == 201


async def test_rate_limits(client: httpx.AsyncClient, monkeypatch: pytest.MonkeyPatch) -> None:
    # The test transport connects from 127.0.0.1; trust it as a proxy so X-Forwarded-For simulates client IPs.
    monkeypatch.setattr(get_settings(), "trusted_proxies", "127.0.0.1")
    phone = next_phone()
    assert (await _send(client, phone, "register")).status_code == 200
    r = await _send(client, phone, "register")
    assert r.status_code == 429 and "秒后再试" in r.json()["detail"]

    # 10 sends per phone per day.
    phone = next_phone()
    for _ in range(10):
        await _sql(
            "INSERT INTO sms_logs(phone, purpose, ip, ok, created_at) "
            "VALUES (:p, 'register', '10.9.9.9', true, now() - interval '2 hours')", p=phone,
        )
    r = await _send(client, phone, "register")
    assert r.status_code == 429 and "上限" in r.json()["detail"]

    # 30 sends per IP per hour.
    for i in range(30):
        await _sql(
            "INSERT INTO sms_logs(phone, purpose, ip, ok, created_at) "
            "VALUES (:p, 'register', '10.1.1.1', true, now() - interval '10 minutes')", p=f"1390000{i:04d}",
        )
    r = await _send(client, next_phone(), "register", **{"X-Forwarded-For": "10.1.1.1"})
    assert r.status_code == 429
    assert (await _send(client, next_phone(), "register", **{"X-Forwarded-For": "10.1.1.2"})).status_code == 200


async def test_purpose_mismatch(client: httpx.AsyncClient, admin: httpx.AsyncClient) -> None:
    phone = next_phone()
    code = (await _send(client, phone, "register")).json()["dev_code"]
    # Admin pre-creates the user meanwhile; a register code cannot be used to log in.
    assert (await admin.post("/admin/api/users", json={"phone": phone, "name": "预建"})).status_code == 200
    r = await client.post("/api/v1/auth/login", json={"phone": phone, "code": code})
    assert r.status_code == 400
    login = await _login(client, phone)
    assert login["user"]["name"] == "预建"


async def test_duplicate_and_unknown(client: httpx.AsyncClient) -> None:
    u = await register_via_sms(client, "alice")
    await _age_sms_logs()
    r = await _send(client, u["phone"], "register")
    assert r.status_code == 409 and r.json()["detail"] == "该手机号已注册，请直接登录"
    r = await client.post("/api/v1/auth/register", json={"phone": u["phone"], "code": "123456", "name": "x", "password": PASSWORD})
    assert r.status_code == 409

    unknown = next_phone()
    r = await _send(client, unknown, "login")
    assert r.status_code == 404 and r.json()["detail"] == "该手机号未注册"
    assert (await client.post("/api/v1/auth/login", json={"phone": unknown, "code": "123456"})).status_code == 404


async def test_disabled_user(client: httpx.AsyncClient, admin: httpx.AsyncClient) -> None:
    u = await register_via_sms(client, "bob")
    r = await admin.patch(f"/admin/api/users/{u['user']['id']}", json={"disabled": True})
    assert r.json()["disabled"] is True and r.json()["session_count"] == 0 and r.json()["online"] is False
    # 禁用吊销了全部会话（被吊销/禁用会话的请求由网关拒绝，见 gateway_ms/tests）。
    assert all(rv for (rv,) in await _sql("SELECT revoked FROM sessions"))
    await _age_sms_logs()
    r = await _send(client, u["phone"], "login")
    assert r.status_code == 403
    assert (await client.post("/api/v1/auth/login", json={"phone": u["phone"], "code": "123456"})).status_code == 403


async def test_registration_closed(client: httpx.AsyncClient, admin: httpx.AsyncClient) -> None:
    phone = next_phone()
    code = (await _send(client, phone, "register")).json()["dev_code"]
    r = await admin.put("/admin/api/auth-settings", json={"registration_open": False})
    assert r.json()["registration_open"] is False
    assert (await client.get("/api/v1/auth/config")).json()["registration_open"] is False
    r = await client.post("/api/v1/auth/register", json={"phone": phone, "code": code, "name": "x", "password": PASSWORD})
    assert r.status_code == 403
    await _age_sms_logs()
    assert (await _send(client, phone, "register")).status_code == 403
    # Pre-created users can still log in.
    await admin.post("/admin/api/users", json={"phone": phone, "name": "内部"})
    await _login(client, phone)


async def test_production_without_sms_config(client: httpx.AsyncClient, monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr(get_settings(), "env", "production")
    assert (await client.get("/api/v1/auth/config")).json()["sms_ready"] is False
    r = await _send(client, next_phone(), "register")
    assert r.status_code == 503 and "短信" in r.json()["detail"]


# ----------------------------------------------------------------- Aliyun SMS (mocked)


@respx.mock(assert_all_called=False)
async def test_aliyun_send_and_register(respx_mock, client: httpx.AsyncClient, admin: httpx.AsyncClient) -> None:
    route = respx_mock.post(SMS_URL).mock(
        return_value=httpx.Response(200, json={"Code": "OK", "Message": "OK", "RequestId": "req-1", "BizId": "b"})
    )
    await _configure_sms(admin)
    phone = next_phone()
    r = await _send(client, phone, "register")
    assert r.status_code == 200, r.text
    assert "dev_code" not in r.json()

    form = dict(parse_qsl(route.calls.last.request.content.decode()))
    assert form["Action"] == "SendSms" and form["Version"] == "2017-05-25" and form["Format"] == "JSON"
    assert form["PhoneNumbers"] == phone and form["SignName"] == "深应会议" and form["TemplateCode"] == "SMS_123"
    assert form["SignatureMethod"] == "HMAC-SHA1" and form["SignatureVersion"] == "1.0" and form["AccessKeyId"] == "LTAIkey"
    signature = form.pop("Signature")
    assert aliyun_sms.sign(form, "s3cr3t", "POST") == signature
    code = json.loads(form["TemplateParam"])["code"]

    r = await client.post("/api/v1/auth/register", json={"phone": phone, "code": code, "name": "dora", "password": PASSWORD})
    assert r.status_code == 201
    logs = (await admin.get("/admin/api/sms-logs")).json()
    assert logs["total"] == 1 and logs["items"][0]["ok"] is True and logs["items"][0]["purpose"] == "register"
    assert set(logs["items"][0]) == {"id", "phone", "purpose", "ip", "ok", "error", "created_at"}


@respx.mock(assert_all_called=False)
async def test_aliyun_errors(respx_mock, client: httpx.AsyncClient, admin: httpx.AsyncClient) -> None:
    await _configure_sms(admin)
    respx_mock.post(SMS_URL).mock(
        return_value=httpx.Response(
            400, json={"Code": "isv.MOBILE_NUMBER_ILLEGAL", "Message": "invalid mobile", "RequestId": "r2"}
        )
    )
    phone = next_phone()
    r = await _send(client, phone, "register")
    assert r.status_code == 502 and r.json()["detail"] == "手机号码格式错误"
    # Failed sends store no usable code.
    assert (await _sql("SELECT count(*) FROM sms_codes"))[0][0] == 0

    respx_mock.post(SMS_URL).mock(
        return_value=httpx.Response(200, json={"Code": "isv.BUSINESS_LIMIT_CONTROL", "Message": "触发流控"})
    )
    r = await _send(client, next_phone(), "register")
    assert r.status_code == 429 and "频繁" in r.json()["detail"]

    respx_mock.post(SMS_URL).mock(return_value=httpx.Response(200, json={"Code": "isv.SOMETHING", "Message": "boom"}))
    r = await _send(client, next_phone(), "register")
    assert r.status_code == 502 and "boom" in r.json()["detail"]

    logs = (await admin.get("/admin/api/sms-logs", params={"phone": phone})).json()
    assert logs["total"] == 1 and logs["items"][0]["ok"] is False and logs["items"][0]["error"] == "手机号码格式错误"


@respx.mock(assert_all_called=False)
async def test_sms_test_endpoint(respx_mock, admin: httpx.AsyncClient) -> None:
    r = await admin.post("/admin/api/auth-settings/sms-test", json={"phone": "13800138000"})
    assert r.json()["ok"] is False and r.json()["error"]
    await _configure_sms(admin)
    respx_mock.post(SMS_URL).mock(return_value=httpx.Response(200, json={"Code": "OK", "RequestId": "req-9"}))
    r = await admin.post("/admin/api/auth-settings/sms-test", json={"phone": "13800138000"})
    assert r.json() == {"ok": True, "request_id": "req-9", "error": None}
    logs = (await admin.get("/admin/api/sms-logs")).json()
    assert logs["items"][0]["purpose"] == "test"


async def test_auth_settings_secret_masking(admin: httpx.AsyncClient, monkeypatch: pytest.MonkeyPatch) -> None:
    r = (await admin.get("/admin/api/auth-settings")).json()
    assert r == {
        "registration_open": True,
        "sms": {"access_key_id": None, "access_key_secret_set": False, "sign_name": None, "template_code": None,
                "template_param": "code", "endpoint": "dysmsapi.aliyuncs.com"},
        "sms_ready": False,
    }
    await _configure_sms(admin)
    r = (await admin.put("/admin/api/auth-settings", json={"sms": {"template_param": "num", "sign_name": "新签名"}})).json()
    assert r["sms"]["access_key_secret_set"] is True and r["sms"]["template_param"] == "num"
    assert r["sms"]["sign_name"] == "新签名" and r["sms"]["access_key_id"] == "LTAIkey"
    assert "s3cr3t" not in json.dumps(r)
    (raw,) = (await _sql("SELECT value::text FROM system_settings WHERE key = 'sms_config'"))[0]
    assert "s3cr3t" not in raw and "access_key_secret_enc" in raw

    monkeypatch.setattr(get_settings(), "sms_sign_name", "环境签名")
    assert (await admin.get("/admin/api/auth-settings")).json()["sms"]["sign_name"] == "环境签名"

    r = (await admin.put("/admin/api/auth-settings", json={"sms": {"access_key_secret": ""}})).json()
    assert r["sms"]["access_key_secret_set"] is False and r["sms_ready"] is False


# ----------------------------------------------------------------- heartbeat, admin users & sessions


async def test_heartbeat_and_force_logout(
    client: httpx.AsyncClient, admin: httpx.AsyncClient, monkeypatch: pytest.MonkeyPatch
) -> None:
    monkeypatch.setattr(get_settings(), "trusted_proxies", "127.0.0.1")
    u = await register_via_sms(client, "carol")
    r = await client.post(
        "/api/v1/client/heartbeat",
        headers={**u["headers"], "X-Forwarded-For": "10.1.2.3"},
        json={"client_id": "c-1", "hostname": "mbp", "os": "macos", "app_version": "0.5.0", "recording": True,
              "meeting_id": None},
    )
    assert r.status_code == 200
    assert set(r.json()) == {"server_time", "server_version"}
    # 连接注册表在 user_ms；meeting_ms 的管理端视图经 /internal/connections 拉取（此处直接查注册表）。
    from user_ms.monitor.connections import registry

    (me,) = registry.snapshot()
    assert me["online"] and me["recording"] and me["ip"] == "10.1.2.3"
    assert me["user_name"] == "carol" and me["user_phone"] == u["phone"] and me["user_id"] == u["user"]["id"]
    assert "token_name" not in me

    # Force logout removes the client from the registry and invalidates the session.
    assert (await admin.delete(f"/admin/api/users/{u['user']['id']}/sessions")).status_code == 204
    assert registry.snapshot() == []
    assert all(rv for (rv,) in await _sql("SELECT revoked FROM sessions"))


async def test_admin_user_crud(
    client: httpx.AsyncClient, admin: httpx.AsyncClient, monkeypatch: pytest.MonkeyPatch
) -> None:
    # 删除用户要联动清理 meeting_ms 数据；单服务测试里用桩替代（真实跨域调用由网关联调覆盖）。
    from user_ms.admin import users as admin_users

    class _StubMeetingClient:
        async def stats_batch(self, ids: list[str]) -> dict[str, int]:
            return {}

        async def delete_user_data(self, user_id: str) -> None:
            return None

    monkeypatch.setattr(admin_users, "MeetingClient", _StubMeetingClient)

    r = await admin.post("/admin/api/users", json={"phone": "+86 13900001111", "name": "王五"})
    assert r.status_code == 200, r.text
    wang = r.json()
    assert set(wang) == {"id", "phone", "name", "disabled", "created_at", "last_login_at", "has_password", "meeting_count",
                         "session_count", "online"}
    assert wang["phone"] == "13900001111" and wang["last_login_at"] is None and wang["session_count"] == 0
    assert wang["meeting_count"] == 0  # meeting_count 由 meeting_ms 统计，不可达时降级为 0
    assert (await admin.post("/admin/api/users", json={"phone": "13900001111", "name": "dup"})).status_code == 409
    assert (await admin.post("/admin/api/users", json={"phone": "123", "name": "bad"})).status_code == 422
    # Names are not unique any more.
    assert (await admin.post("/admin/api/users", json={"phone": "13900002222", "name": "王五"})).status_code == 200

    alice = await register_via_sms(client, "alice")
    await _login(client, alice["phone"])

    page = (await admin.get("/admin/api/users", params={"limit": 2})).json()
    assert page["total"] == 3 and len(page["items"]) == 2
    assert (await admin.get("/admin/api/users", params={"q": "1111"})).json()["items"][0]["id"] == wang["id"]
    assert (await admin.get("/admin/api/users", params={"q": "王"})).json()["total"] == 2
    found = (await admin.get("/admin/api/users", params={"q": "alice"})).json()["items"][0]
    assert found["meeting_count"] == 0 and found["session_count"] == 2 and found["last_login_at"]

    detail = (await admin.get(f"/admin/api/users/{alice['user']['id']}")).json()
    assert len(detail["sessions"]) == 2
    s = detail["sessions"][0]
    assert set(s) == {"id", "client_id", "hostname", "os", "app_version", "ip", "created_at", "last_used_at",
                      "expires_at", "revoked"}
    # Force logout the first registration session only.
    first = next(x for x in detail["sessions"] if x["client_id"] == "cid-alice")
    assert (await admin.delete(f"/admin/api/users/{alice['user']['id']}/sessions/{first['id']}")).status_code == 204
    assert (await admin.delete(f"/admin/api/users/{wang['id']}/sessions/{first['id']}")).status_code == 404
    detail = (await admin.get(f"/admin/api/users/{alice['user']['id']}")).json()
    assert detail["session_count"] == 1 and len(detail["sessions"]) == 2  # revoked ones are listed too
    assert any(x["revoked"] for x in detail["sessions"])

    r = await admin.patch(f"/admin/api/users/{wang['id']}", json={"name": "王六", "phone": "13900003333"})
    assert r.json()["name"] == "王六" and r.json()["phone"] == "13900003333"
    assert (await admin.patch(f"/admin/api/users/{wang['id']}", json={"phone": alice["phone"]})).status_code == 409

    disabled = (await admin.patch(f"/admin/api/users/{wang['id']}", json={"disabled": True})).json()
    assert disabled["disabled"] is True
    assert (await admin.get("/admin/api/users", params={"status": "disabled"})).json()["total"] == 1
    assert (await admin.get("/admin/api/users", params={"status": "active"})).json()["total"] == 2

    assert (await admin.delete(f"/admin/api/users/{alice['user']['id']}")).status_code == 204
    assert (await admin.get(f"/admin/api/users/{alice['user']['id']}")).status_code == 404
    assert (await _sql("SELECT count(*) FROM sessions"))[0][0] == 0
    # 会议数据在 meeting_ms 库（跨域删除经 MeetingClient，这里由桩替代，网关联调覆盖）。


async def test_legacy_user_gets_phone(client: httpx.AsyncClient, admin: httpx.AsyncClient) -> None:
    """Users migrated from the token era have no phone; assigning one lets them log in by SMS."""
    await _sql("INSERT INTO users(id, name) VALUES ('legacy-1', '老用户')")
    items = (await admin.get("/admin/api/users")).json()["items"]
    assert items[0]["phone"] is None
    phone = next_phone()
    assert (await admin.patch("/admin/api/users/legacy-1", json={"phone": phone})).status_code == 200
    assert (await _login(client, phone))["user"]["id"] == "legacy-1"
