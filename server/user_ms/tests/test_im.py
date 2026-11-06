"""IM 封装层测试：假 SDK 注入 + 端点行为（不依赖外部 IM 服务）。

客户端（签凭证/发消息）走假 SDK 注入 sys.modules 验证封装层的创建参数、降级路径
与错误映射。假对象只覆盖封装层用到的接口面（AsyncDRClient 构造参数、
users.issue_login_ticket、messages.send、aclose），真实 SDK 语义不变。

服务端回调走真实 SDK（deeprespond-im-server-sdk 已发布安装）：用 SDK 的 sign/
signature_header 构造签名请求，验证端点的 503 降级、URL 验证、签名校验与事件去重。
"""
from __future__ import annotations

import json
import sys
import time
import types
import uuid
from typing import Any

import pytest
from deeprespond_im.callback import signature_header, sign

from user_ms.config import get_settings
from user_ms.infrastructure import im_client
from user_ms.tests.helpers import PASSWORD, register_via_sms

CALLBACK_ENDPOINT_ID = "ep-test"
CALLBACK_SECRET = "cbs-test-secret"

FULL_CONFIG: dict[str, Any] = {
    "im_enabled": True,
    "im_base_url": "https://im.example.com",
    "im_org_name": "1100250925",
    "im_app_name": "demo",
    "im_client_id": "cid",
    "im_client_secret": "secret",
    "im_callback_endpoint_id": CALLBACK_ENDPOINT_ID,
    "im_callback_secret": CALLBACK_SECRET,
}


@pytest.fixture(autouse=True)
def _clean_clients():
    """AsyncDRClient 绑定事件循环，测试间不能残留（全部用例共享 session 循环）。"""
    im_client._clients.clear()
    im_client._callback_cache.clear()
    yield
    im_client._clients.clear()
    im_client._callback_cache.clear()


@pytest.fixture
def im_enabled():
    s = get_settings()
    original = {k: getattr(s, k) for k in FULL_CONFIG}
    for k, v in FULL_CONFIG.items():
        setattr(s, k, v)
    yield
    for k, v in original.items():
        setattr(s, k, v)


class _FakeResult:
    def __init__(self, **kwargs) -> None:
        self.__dict__.update(kwargs)


class _SDKError(Exception):
    """模拟 deeprespond_im 的异常：带 code 属性（如 user_disabled）。"""

    def __init__(self, code: str) -> None:
        super().__init__(code)
        self.code = code


def _install_fake_sdk(monkeypatch, *, ticket_hook=None, send_hook=None) -> dict:
    """注入假 deeprespond_im / deeprespond_im.redis，返回调用记录字典。"""
    calls: dict[str, list] = {"init": [], "ticket": [], "send": [], "closed": 0}

    class FakeAsyncDRClient:
        def __init__(self, **kwargs) -> None:
            calls["init"].append(kwargs)
            self.users = types.SimpleNamespace(issue_login_ticket=self._issue)
            self.messages = types.SimpleNamespace(send=self._send)

        async def _issue(self, user_id, auto_create=False):  # noqa: ANN001
            calls["ticket"].append((user_id, auto_create))
            if ticket_hook is not None:
                return ticket_hook(user_id, auto_create)
            return _FakeResult(ticket="TICKET", expires_in=300, user_created=True)

        async def _send(self, **kwargs):  # noqa: ANN001, ANN003
            calls["send"].append(kwargs)
            if send_hook is not None:
                return send_hook(**kwargs)
            return _FakeResult(message_id="m1", duplicate=False)

        async def aclose(self) -> None:
            calls["closed"] += 1

    module = types.ModuleType("deeprespond_im")
    module.AsyncDRClient = FakeAsyncDRClient
    redis_module = types.ModuleType("deeprespond_im.redis")
    redis_module.AsyncRedisTokenStore = lambda *args, **kwargs: object()  # noqa: ARG005
    monkeypatch.setitem(sys.modules, "deeprespond_im", module)
    monkeypatch.setitem(sys.modules, "deeprespond_im.redis", redis_module)
    return calls


# ---------- 配置判定与降级 ----------


async def test_disabled_by_default_degrades_everything():
    """默认配置（im_enabled=false）：签凭证 503、发消息静默返回 None。"""
    assert get_settings().im_enabled is False
    with pytest.raises(im_client.ImUnavailableError, match="OPENMEETING_IM_ENABLED"):
        await im_client.get_client()
    assert await im_client.send_message(to_user="u1", client_msg_id="x-1", body={}) is None


async def test_enabled_but_sdk_missing(im_enabled, monkeypatch):
    """sys.modules 里放 None 使 import 抛 ImportError，模拟 SDK 未安装。"""
    monkeypatch.setitem(sys.modules, "deeprespond_im", None)
    with pytest.raises(im_client.ImUnavailableError, match="deeprespond-im-server-sdk 未安装"):
        await im_client.get_client()


async def test_enabled_but_config_incomplete(im_enabled, monkeypatch):
    monkeypatch.setattr(get_settings(), "im_client_secret", "")
    with pytest.raises(im_client.ImUnavailableError, match="配置不完整"):
        await im_client.get_client()


# ---------- 客户端创建 ----------


async def test_get_client_kwargs_and_reuse(im_enabled, monkeypatch):
    calls = _install_fake_sdk(monkeypatch)
    client = await im_client.get_client()
    assert await im_client.get_client() is client  # 同一事件循环内复用
    assert len(calls["init"]) == 1
    kwargs = calls["init"][0]
    assert kwargs["base_url"] == "https://im.example.com"
    assert kwargs["org_name"] == "1100250925"
    assert kwargs["app_name"] == "demo"
    assert kwargs["client_id"] == "cid"
    assert kwargs["client_secret"] == "secret"
    assert kwargs["timeout"] == 10.0


# ---------- 签发登录凭证 ----------


async def test_issue_login_ticket_success(im_enabled, monkeypatch):
    calls = _install_fake_sdk(monkeypatch)
    result = await im_client.issue_login_ticket("user-42")
    assert result == {"ticket": "TICKET", "expires_in": 300, "user_created": True}
    # IM 用户名直接用业务用户 ID，且 auto_create=True。
    assert calls["ticket"] == [("user-42", True)]


async def test_issue_login_ticket_user_disabled(im_enabled, monkeypatch):
    _install_fake_sdk(
        monkeypatch, ticket_hook=lambda *_args: (_ for _ in ()).throw(_SDKError("user_disabled"))
    )
    with pytest.raises(_SDKError):
        await im_client.issue_login_ticket("user-42")


# ---------- 发送消息 ----------


async def test_send_message_success_passes_all_kwargs(im_enabled, monkeypatch):
    calls = _install_fake_sdk(monkeypatch)
    result = await im_client.send_message(
        to_user="user-42",
        client_msg_id="meeting-1001-summary",
        body={"card": "summary", "meeting_id": "1001"},
        push={"title": "纪要已生成", "body": "会议纪要已生成"},
    )
    assert result == {"message_id": "m1", "duplicate": False}
    kwargs = calls["send"][0]
    assert kwargs["from_"] == im_client.NOTICE_USERNAME
    assert kwargs["to_user"] == "user-42"
    assert kwargs["client_msg_id"] == "meeting-1001-summary"
    assert kwargs["type"] == "custom"
    assert kwargs["body"] == {"card": "summary", "meeting_id": "1001"}
    assert kwargs["push"] == {"title": "纪要已生成", "body": "会议纪要已生成"}


async def test_send_message_without_push_omits_key(im_enabled, monkeypatch):
    calls = _install_fake_sdk(monkeypatch)
    await im_client.send_message(to_user="user-42", client_msg_id="x-1", body={})
    assert "push" not in calls["send"][0]


async def test_send_message_swallows_any_error(im_enabled, monkeypatch):
    """通知是尽力而为：SDK 抛什么都只记日志，绝不影响调用方。"""

    def _boom(**_kwargs):
        raise RuntimeError("connection reset")

    _install_fake_sdk(monkeypatch, send_hook=_boom)
    assert await im_client.send_message(to_user="user-42", client_msg_id="x-1", body={}) is None


async def test_send_message_reports_duplicate(im_enabled, monkeypatch):
    _install_fake_sdk(monkeypatch, send_hook=lambda **_k: _FakeResult(message_id="m0", duplicate=True))
    result = await im_client.send_message(to_user="user-42", client_msg_id="x-1", body={})
    assert result == {"message_id": "m0", "duplicate": True}


# ---------- 停机清理 ----------


async def test_aclose_closes_current_loop_client(im_enabled, monkeypatch):
    calls = _install_fake_sdk(monkeypatch)
    await im_client.get_client()
    await im_client.aclose_client()
    assert calls["closed"] == 1
    assert len(im_client._clients) == 0
    await im_client.aclose_client()  # 幂等
    assert calls["closed"] == 1


# ---------- HTTP 端点 ----------


async def test_ticket_requires_login(client):
    r = await client.post("/api/v1/im/ticket")
    assert r.status_code == 401


async def test_ticket_endpoint_disabled_returns_503(client):
    user = await register_via_sms(client, "im-user")
    r = await client.post("/api/v1/im/ticket", headers=user["headers"])
    assert r.status_code == 503
    assert "IM 服务未开启" in r.json()["detail"]


async def test_ticket_endpoint_success(im_enabled, client, monkeypatch):
    calls = _install_fake_sdk(monkeypatch)
    user = await register_via_sms(client, "im-user")
    r = await client.post("/api/v1/im/ticket", headers=user["headers"])
    assert r.status_code == 200, r.text
    assert r.json() == {"ticket": "TICKET", "expires_in": 300, "user_created": True,
                        "api_url": "https://im.example.com", "app_key": "1100250925#demo", "expires_in_sec": 300}
    # 注册响应已经带过一次凭证（登录即有 IM），端点用于过期/重连后重新获取。
    assert calls["ticket"] == [(user["user"]["id"], True)] * 2


async def test_ticket_endpoint_user_disabled_maps_to_403(im_enabled, client, monkeypatch):
    _install_fake_sdk(
        monkeypatch, ticket_hook=lambda *_args: (_ for _ in ()).throw(_SDKError("user_disabled"))
    )
    user = await register_via_sms(client, "im-user")
    r = await client.post("/api/v1/im/ticket", headers=user["headers"])
    assert r.status_code == 403
    assert r.json()["detail"] == "该账号已被禁用"


async def test_ticket_endpoint_other_error_maps_to_502(im_enabled, client, monkeypatch):
    _install_fake_sdk(
        monkeypatch, ticket_hook=lambda *_args: (_ for _ in ()).throw(_SDKError("ip_not_allowed"))
    )
    user = await register_via_sms(client, "im-user")
    r = await client.post("/api/v1/im/ticket", headers=user["headers"])
    assert r.status_code == 502


# ---------- 服务端回调（真实 SDK） ----------


def _signed_headers(body: bytes, *, endpoint_id: str = CALLBACK_ENDPOINT_ID, secret: str = CALLBACK_SECRET) -> dict[str, str]:
    timestamp = str(int(time.time()))
    nonce = uuid.uuid4().hex  # 32 个小写十六进制字符
    return {
        "X-IM-Endpoint-Id": endpoint_id,
        "X-IM-Timestamp": timestamp,
        "X-IM-Nonce": nonce,
        "X-IM-Signature": signature_header([secret], timestamp, nonce, body),
    }


def _payload(kind: str, **extra: Any) -> bytes:
    data = {
        "kind": kind,
        "request_id": uuid.uuid4().hex,
        "app": "demo",
        "endpoint_id": CALLBACK_ENDPOINT_ID,
        "sent_at": time.strftime("%Y-%m-%dT%H:%M:%S+00:00", time.gmtime()),
        **extra,
    }
    return json.dumps(data).encode("utf-8")


async def test_callback_disabled_returns_503(client):
    """IM 未开启：回调拒绝受理（503），IM 服务器会按重试策略重投。"""
    r = await client.post("/im/callback", content=_payload("verify", challenge="ch-1"), headers=_signed_headers(b""))
    assert r.status_code == 503


async def test_callback_config_incomplete_returns_503(client, im_enabled, monkeypatch):
    """IM 开启但回调地址未配置：同样 503 降级。"""
    monkeypatch.setattr(get_settings(), "im_callback_endpoint_id", "")
    r = await client.post("/im/callback", content=_payload("verify", challenge="ch-1"), headers=_signed_headers(b""))
    assert r.status_code == 503


async def test_callback_verify_challenge(im_enabled, client):
    """URL 验证：签名通过后原样应答 challenge（200）。"""
    body = _payload("verify", challenge="ch-42")
    r = await client.post("/im/callback", content=body, headers=_signed_headers(body))
    assert r.status_code == 200, r.text
    assert r.json() == {"challenge": "ch-42"}


async def test_callback_bad_signature_returns_401(im_enabled, client):
    """密钥不对：401 bad_signature，IM 服务器不会重投。"""
    body = _payload("verify", challenge="ch-1")
    r = await client.post("/im/callback", content=body, headers=_signed_headers(body, secret="wrong-secret"))
    assert r.status_code == 401


async def test_callback_unknown_endpoint_returns_401(im_enabled, client):
    """地址 ID 不在配置中：401 unknown endpoint。"""
    body = _payload("verify", challenge="ch-1")
    r = await client.post("/im/callback", content=body, headers=_signed_headers(body, endpoint_id="ep-other"))
    assert r.status_code == 401


async def test_callback_event_batch_processed_and_deduped(im_enabled, client):
    """事件批次：校验、去重、无注册处理函数时忽略事件 → 204；重投同一事件仍是 204。"""
    event = {"id": f"evt-{uuid.uuid4().hex}", "type": "user.created", "data": {"username": "user-42"}}
    body = _payload("event", events=[event])
    r = await client.post("/im/callback", content=body, headers=_signed_headers(body))
    assert r.status_code == 204
    # IM 服务器按重试策略重投同一事件：去重存储命中 DONE，跳过后仍回 204。
    r = await client.post("/im/callback", content=body, headers=_signed_headers(body))
    assert r.status_code == 204


# ---------- 登录即有 IM ----------

# register_via_sms 默认带密码：后续用密码登录，避开「同手机号 60s 内只能发一次短信」的限流。


async def test_login_and_register_carry_im_ticket(im_enabled, client, monkeypatch):
    """登录/注册响应直接带 IM 凭证；首次签发由 auto_create 自动创建 IM 账号。"""
    calls = _install_fake_sdk(monkeypatch)
    user = await register_via_sms(client, "im-user")
    assert user["result"]["im_ticket"] == {"ticket": "TICKET", "expires_in": 300, "user_created": True}
    assert calls["ticket"] == [(user["user"]["id"], True)]

    r = await client.post("/api/v1/auth/login", json={"phone": user["phone"], "password": PASSWORD})
    assert r.status_code == 200, r.text
    assert r.json()["im_ticket"]["ticket"] == "TICKET"


async def test_login_im_ticket_null_when_disabled(client):
    """IM 未开启：登录/注册完全不受影响，im_ticket 恒为 null。"""
    user = await register_via_sms(client, "im-user")
    assert user["result"]["im_ticket"] is None
    r = await client.post("/api/v1/auth/login", json={"phone": user["phone"], "password": PASSWORD})
    assert r.status_code == 200
    assert r.json()["im_ticket"] is None


async def test_login_survives_im_ticket_failure(im_enabled, client, monkeypatch):
    """尽力而为：IM 服务报错只让 im_ticket 变 null，登录照常成功。"""
    _install_fake_sdk(monkeypatch, ticket_hook=lambda *_args: (_ for _ in ()).throw(_SDKError("rate_limited")))
    user = await register_via_sms(client, "im-user")
    assert user["result"]["im_ticket"] is None
    r = await client.post("/api/v1/auth/login", json={"phone": user["phone"], "password": PASSWORD})
    assert r.status_code == 200
    assert r.json()["im_ticket"] is None
