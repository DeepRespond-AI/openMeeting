"""Gateway auth semantics：会话校验（旧单体 require_client 的错误文案）、admin JWT、
公开路径放行与身份头覆盖。数据库是 openmeeting_user（user_ms 的表），会话缓存每测试清空。
"""
from __future__ import annotations

import hashlib
from datetime import timedelta

import httpx
import jwt as pyjwt
import pytest
from sqlalchemy import text

import gateway_ms.config as gcfg
from gateway_ms.auth.core import client_ip_from_scope, hash_token
from user_ms.db.session import session_factory
from user_ms.tests.helpers import next_phone, register_via_sms
from user_ms.utils import utcnow


def test_update_policy_route_is_forwarded_to_user_ms() -> None:
    from gateway_ms.api.gateway import ADMIN_ROUTES, resolve_downstream

    assert resolve_downstream("/admin/api/update-policy", ADMIN_ROUTES) == "user"


async def test_update_policy_auth_validation_and_round_trip(client: httpx.AsyncClient) -> None:
    path = "/admin/api/update-policy"
    assert (await client.get(path)).status_code == 401
    assert (await client.put(path, json={"windows": {"min_version": "0.4.2"}})).status_code == 401

    login = await client.post("/admin/api/login", json={"password": "test-admin-pw"})
    assert login.status_code == 200
    initial = await client.get(path)
    assert initial.status_code == 200
    assert initial.json()["windows"]["min_version"] == ""

    invalid = await client.put(path, json={"windows": {"min_version": "invalid"}})
    assert invalid.status_code == 422
    updated = await client.put(path, json={"windows": {"min_version": "0.4.2"}})
    assert updated.status_code == 200
    assert updated.json()["windows"]["min_version"] == "0.4.2"
    assert (await client.get(path)).json()["windows"]["min_version"] == "0.4.2"


async def _sql(stmt: str, **params) -> list:
    async with session_factory()() as session:
        result = await session.execute(text(stmt), params)
        rows = result.fetchall() if result.returns_rows else []
        await session.commit()
        return rows


def _clear_cache() -> None:
    """直接改库 / 吊销后清空网关的进程内会话缓存（生产中最迟 OPENMEETING_SESSION_CACHE_TTL_SEC 过期）。"""
    from gateway_ms.auth import core as auth_core

    auth_core._cache.clear()


# ------------------------------------------------------------------ 公开路径


async def test_healthz_and_public_paths(client: httpx.AsyncClient) -> None:
    assert (await client.get("/healthz")).json()["ok"] is True
    r = await client.get("/api/v1/auth/config")
    assert r.status_code == 200 and r.json()["sms_ready"] is True  # dev 模式
    r = await client.get("/api/v1/updates/check", params={"platform": "macos", "version": "0.4.1", "arch": "aarch64"})
    assert r.status_code == 200 and r.json()["update"] is None
    # 公开路径携带无效 token 时按匿名处理（与拆分前一致）。
    r = await client.get("/api/v1/auth/config", headers={"Authorization": "Bearer ms_bogus"})
    assert r.status_code == 200
    r = await client.get("/api/v1/auth/me", headers={"Authorization": "Bearer ms_bogus"})
    assert r.status_code == 401 and r.json()["detail"] == "未登录，请先使用手机号登录"


# ------------------------------------------------------------------ 会话语义（错误文案与旧单体一致）


async def _registered(client: httpx.AsyncClient, name: str) -> dict:
    u = await register_via_sms(client, name)
    return u


async def test_missing_and_unknown_token(client: httpx.AsyncClient) -> None:
    # 非公开路径：无 token / 未知 token 由网关拒绝（文案与旧 require_client 一致）。
    r = await client.post("/api/v1/client/heartbeat", json={})
    assert r.status_code == 401 and r.json()["detail"] == "未登录，请先使用手机号登录"
    r = await client.post("/api/v1/client/heartbeat", json={}, headers={"Authorization": "Bearer ms_bogus"})
    assert r.status_code == 401 and r.json()["detail"] == "登录凭证无效，请重新登录"


async def test_revoked_session(client: httpx.AsyncClient) -> None:
    u = await _registered(client, "alice")
    h = {"Authorization": f"Bearer {u['token']}"}
    assert (await client.get("/api/v1/auth/me", headers=h)).status_code == 200
    await _sql("UPDATE sessions SET revoked = true")
    _clear_cache()
    # 公开前缀（/api/v1/auth）会把失效会话降级为匿名；精确文案在非公开路径上验证。
    r = await client.post("/api/v1/client/heartbeat", json={}, headers=h)
    assert r.status_code == 401 and r.json()["detail"] == "登录已失效，请重新登录"


async def test_expired_session(client: httpx.AsyncClient) -> None:
    u = await _registered(client, "bob")
    h = {"Authorization": f"Bearer {u['token']}"}
    await _sql("UPDATE sessions SET expires_at = now() - interval '1 second'")
    _clear_cache()
    r = await client.post("/api/v1/client/heartbeat", json={}, headers=h)
    assert r.status_code == 401 and r.json()["detail"] == "登录已过期，请重新登录"


async def test_disabled_user_403(client: httpx.AsyncClient) -> None:
    u = await _registered(client, "carol")
    h = {"Authorization": f"Bearer {u['token']}"}
    # 会话未吊销但用户已禁用 → 403（旧单体 require_client 的行为）。
    await _sql("UPDATE users SET disabled = true")
    _clear_cache()
    r = await client.post("/api/v1/client/heartbeat", json={}, headers=h)
    assert r.status_code == 403 and r.json()["detail"] == "该账号已被禁用"


async def test_sliding_expiry(client: httpx.AsyncClient) -> None:
    u = await _registered(client, "dave")
    h = {"Authorization": f"Bearer {u['token']}"}
    # Recently used: no write (throttled to once per hour).
    await _sql("UPDATE sessions SET last_used_at = now() - interval '10 minutes', expires_at = now() + interval '1 day'")
    _clear_cache()
    assert (await client.get("/api/v1/auth/me", headers=h)).status_code == 200
    (exp,) = (await _sql("SELECT expires_at FROM sessions"))[0]
    assert exp - utcnow() < timedelta(days=2)

    # Used after more than an hour: expiry slides to now + 30 days.
    await _sql("UPDATE sessions SET last_used_at = now() - interval '2 hours', expires_at = now() + interval '1 minute'")
    _clear_cache()
    assert (await client.get("/api/v1/auth/me", headers=h)).status_code == 200
    (exp, last) = (await _sql("SELECT expires_at, last_used_at FROM sessions"))[0]
    assert exp - utcnow() > timedelta(days=29) and utcnow() - last < timedelta(minutes=1)


async def test_logout_revokes_session(client: httpx.AsyncClient) -> None:
    u = await _registered(client, "erin")
    h = {"Authorization": f"Bearer {u['token']}"}
    # 登出走 /api/v1/auth（公开前缀 + 有效 bearer），网关注入真实 X-Session-ID 供 user_ms 吊销。
    assert (await client.post("/api/v1/auth/logout", headers=h)).status_code == 204
    _clear_cache()
    r = await client.post("/api/v1/client/heartbeat", json={}, headers=h)
    assert r.status_code == 401 and r.json()["detail"] == "登录已失效，请重新登录"


# ------------------------------------------------------------------ admin JWT


async def test_admin_jwt_valid_invalid_and_password_fingerprint(client: httpx.AsyncClient, monkeypatch) -> None:
    # /admin/api/events 需要 admin JWT（meeting_ms 侧不再本地鉴权，由网关统一校验）。
    r = await client.get("/admin/api/events")
    assert r.status_code == 401 and r.json()["detail"] == "未登录或登录已过期"

    r = await client.post("/admin/api/login", json={"password": "wrong"})
    assert r.status_code == 401

    r = await client.post("/admin/api/login", json={"password": "test-admin-pw"})
    assert r.status_code == 200
    token = r.json()["token"]
    assert "openmeeting_admin" in r.cookies
    assert (await client.get("/admin/api/me")).json() == {"ok": True}
    r = await client.get("/admin/api/users", headers={"Authorization": f"Bearer {token}"})
    assert r.status_code == 200 and r.json() == {"items": [], "total": 0}

    # 清掉登录 cookie，单独验证 Bearer 语义（verify_admin 里 cookie 优先于 Bearer）。
    client.cookies.clear()
    # 篡改 / 错误密钥签名的 token。
    r = await client.get("/admin/api/users", headers={"Authorization": "Bearer not-a-jwt"})
    assert r.status_code == 401 and r.json()["detail"] == "未登录或登录已过期"
    forged = pyjwt.encode({"sub": "admin", "pf": "x"}, b"wrong-key-but-long-enough-for-hs256-signing", algorithm="HS256")
    assert (await client.get("/admin/api/users", headers={"Authorization": f"Bearer {forged}"})).status_code == 401
    # 正确密钥但 sub 不是 admin。
    key = hashlib.sha256(("openmeeting-jwt:" + gcfg.get_settings().resolved_secret_key()).encode()).digest()
    other = pyjwt.encode({"sub": "user", "pf": "x"}, key, algorithm="HS256")
    assert (await client.get("/admin/api/users", headers={"Authorization": f"Bearer {other}"})).status_code == 401

    # 密码指纹：admin 密码变更后旧 token 立即失效。
    monkeypatch.setattr(gcfg.get_settings(), "admin_password", "rotated-pw")
    r = await client.get("/admin/api/users", headers={"Authorization": f"Bearer {token}"})
    assert r.status_code == 401 and r.json()["detail"] == "未登录或登录已过期"


async def test_admin_public_prefixes(client: httpx.AsyncClient) -> None:
    # login / logout 不需要管理端 JWT。
    assert (await client.post("/admin/api/logout")).status_code == 204
    assert (await client.post("/admin/api/login", json={"password": "nope"})).status_code == 401


# ------------------------------------------------------------------ 身份头剥离与覆盖


async def test_forged_identity_headers_are_overridden(client: httpx.AsyncClient) -> None:
    alice = await _registered(client, "alice")
    bob = await _registered(client, "bob")

    # 携带有效 bearer 时，伪造的 X-User-ID / X-User-Name 被网关认证结果覆盖。
    h = {"Authorization": f"Bearer {alice['token']}", "X-User-ID": bob["user"]["id"], "X-User-Name": "eve"}
    r = await client.get("/api/v1/auth/me", headers=h)
    assert r.status_code == 200
    assert r.json()["id"] == alice["user"]["id"] and r.json()["name"] == "alice"

    # 无有效会话时，伪造 X-User-ID 不能穿透到下游。
    r = await client.get("/api/v1/auth/me", headers={"X-User-ID": bob["user"]["id"]})
    assert r.status_code == 401 and r.json()["detail"] == "未登录，请先使用手机号登录"

    # 伪造 X-Session-ID 不能吊销他人会话：网关注入的是认证出的真实会话。
    (bob_sid,) = (await _sql("SELECT id FROM sessions WHERE token_hash = :h", h=hash_token(bob["token"])))[0]
    r = await client.post("/api/v1/auth/logout", headers={**h, "X-Session-ID": bob_sid})
    assert r.status_code == 204
    rows = dict(await _sql("SELECT token_hash, revoked FROM sessions"))
    assert rows[hash_token(alice["token"])] is True  # alice 自己的会话被吊销
    assert rows[hash_token(bob["token"])] is False  # bob 不受影响


# ------------------------------------------------------------------ 网关路由兜底


async def test_unknown_admin_route_and_root_redirect(client: httpx.AsyncClient) -> None:
    r = await client.get("/")
    assert r.status_code == 307 and r.headers["location"] == "/admin/"
    r = await client.get("/admin/api/does-not-exist")
    assert r.status_code == 404 and r.json()["detail"] == "资源不存在"
    r = await client.get("/api/v1/does-not-exist", headers={"X-User-ID": "whatever"})
    assert r.status_code == 404 and r.json()["detail"] == "资源不存在"


async def test_admin_proxy_reaches_user_ms(client: httpx.AsyncClient) -> None:
    # 经网关在 user_ms 建用户（跨服务代理 + 内部令牌注入路径）。
    phone = next_phone()
    r = await client.post("/admin/api/login", json={"password": "test-admin-pw"})
    assert r.status_code == 200
    r = await client.post("/admin/api/users", json={"phone": phone, "name": "网关建"})
    assert r.status_code == 200, r.text
    assert r.json()["name"] == "网关建" and r.json()["phone"] == phone
    items = (await client.get("/admin/api/users", params={"q": phone})).json()["items"]
    assert len(items) == 1 and items[0]["meeting_count"] == 0  # meeting 统计在 meeting_ms，此处降级为 0


# ------------------------------------------------------------------ 网关侧 client IP（与 user_ms 同规则的独立实现）


def _request(peer: str | None, headers: dict[str, str]):
    from starlette.requests import Request

    scope = {
        "type": "http",
        "method": "GET",
        "path": "/",
        "query_string": b"",
        "client": (peer, 12345) if peer else None,
        "headers": [(k.lower().encode(), v.encode()) for k, v in headers.items()],
    }
    return Request(scope)


def test_gateway_ip_ignores_headers_without_trusted_proxy(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr(gcfg.get_settings(), "trusted_proxies", "")
    request = _request("203.0.113.9", {"x-forwarded-for": "1.2.3.4", "x-real-ip": "5.6.7.8"})
    assert client_ip_from_scope(request) == "203.0.113.9"


def test_gateway_ip_rightmost_untrusted_hop(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr(gcfg.get_settings(), "trusted_proxies", "10.0.0.0/8")
    request = _request("10.0.0.2", {"x-forwarded-for": "1.1.1.1, 198.51.100.7, 10.0.0.3"})
    assert client_ip_from_scope(request) == "198.51.100.7"


def test_gateway_ip_real_ip_header_from_trusted_proxy(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr(gcfg.get_settings(), "trusted_proxies", "127.0.0.1")
    request = _request("127.0.0.1", {"x-real-ip": "198.51.100.7"})
    assert client_ip_from_scope(request) == "198.51.100.7"


def test_gateway_ip_none_peer(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr(gcfg.get_settings(), "trusted_proxies", "10.0.0.0/8")
    assert client_ip_from_scope(_request(None, {})) is None
