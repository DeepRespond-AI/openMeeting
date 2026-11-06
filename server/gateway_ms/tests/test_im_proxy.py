"""IM 回调的网关透传与 /api/v1/im 路由验证。

网关按前缀表分流：/api/v1/im 必须命中 user（且要求登录会话），/im/* 是 IM 服务器
的回调透传（无会话，直接转发给 user_ms 的签名校验）。下游是进程内真实 user_ms。
"""
from __future__ import annotations

import httpx

from user_ms.tests.helpers import register_via_sms


async def test_im_callback_proxied_to_user_ms(client: httpx.AsyncClient):
    """IM 回调经网关原样转发；IM 未开启时 user_ms 回 503（触发 IM 服务器重投）。"""
    r = await client.post("/im/callback", content=b"{}")
    assert r.status_code == 503
    assert "IM 回调暂不可用" in r.json()["detail"]


async def test_im_ticket_requires_session(client: httpx.AsyncClient):
    r = await client.post("/api/v1/im/ticket")
    assert r.status_code == 401


async def test_im_ticket_forwarded_with_identity(client: httpx.AsyncClient):
    """带登录会话时网关注入身份头转发；IM 未开启时透传 user_ms 的 503。

    网关剥离开户端伪造的 X-User-* 头，认证只能走 Bearer token。
    """
    user = await register_via_sms(client, "im-user")
    r = await client.post("/api/v1/im/ticket", headers={"Authorization": f"Bearer {user['token']}"})
    assert r.status_code == 503
    assert "IM 服务未开启" in r.json()["detail"]
