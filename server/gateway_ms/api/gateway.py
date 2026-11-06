from __future__ import annotations

import asyncio
import logging
from urllib.parse import quote

from fastapi import APIRouter, Depends, HTTPException, Request, WebSocket, WebSocketDisconnect
from sqlalchemy.ext.asyncio import AsyncSession

from gateway_ms.auth.core import ClientIdentity, require_client_identity, verify_admin
from gateway_ms.config import get_settings
from gateway_ms.db.session import get_session
from gateway_ms.infrastructure.proxy import proxy_stream, target_url

logger = logging.getLogger(__name__)
router = APIRouter()

# ---------------------------------------------------------------- 路由表（最长前缀匹配）

# /api/v1 —— 认证域名与心跳在 user_ms；会议域路由在 meeting_ms
CLIENT_ROUTES: list[tuple[str, str]] = [
    ("/api/v1/auth", "user"),
    ("/api/v1/updates", "user"),
    ("/api/v1/client/heartbeat", "user"),
    ("/api/v1/im", "user"),
    ("/api/v1/client/capabilities", "meeting"),
    ("/api/v1/meetings", "meeting"),
    ("/api/v1/transcripts", "meeting"),
    ("/api/v1/scheduled-meetings", "meeting"),
    ("/api/v1/rooms", "meeting"),
    ("/api/v1/transcribe", "meeting"),
    ("/api/v1/audio", "meeting"),
    ("/api/v1/jobs", "meeting"),
    ("/api/v1/summaries", "meeting"),
]
# /api/v1/* 中无需会话的公开前缀（与旧 app/api/v1/__init__.py 的 public_router 一致）
PUBLIC_CLIENT_PREFIXES = ("/api/v1/auth", "/api/v1/updates")

# /admin/api —— login/logout 公开；stt 独立服务；其余按下表分流
# （旧单体的管理端登录路径是 /admin/api/login|logout|me，没有 /auth 前缀）
ADMIN_PUBLIC_PREFIXES = ("/admin/api/login", "/admin/api/logout")
ADMIN_ROUTES: list[tuple[str, str]] = [
    ("/admin/api/login", "user"),
    ("/admin/api/logout", "user"),
    ("/admin/api/me", "user"),
    ("/admin/api/users", "user"),
    ("/admin/api/auth-settings", "user"),
    ("/admin/api/sms-logs", "user"),
    ("/admin/api/releases", "user"),
    ("/admin/api/update-policy", "user"),
    ("/admin/api/stt", "stt"),
    ("/admin/api/dashboard", "meeting"),
    ("/admin/api/connections", "meeting"),
    ("/admin/api/events", "meeting"),
    ("/admin/api/stats", "meeting"),
    ("/admin/api/llm", "meeting"),
    ("/admin/api/summary-templates", "meeting"),
    ("/admin/api/storage", "meeting"),
    ("/admin/api/object-storage", "meeting"),
    ("/admin/api/jobs", "meeting"),
    ("/admin/api/meetings", "meeting"),
]

# 客户端可能伪造的身份头：网关认证后统一覆盖
IDENTITY_HEADERS = {
    "x-user-id",
    "x-user-name",
    "x-user-phone",
    "x-session-id",
    "x-internal-token",
    "x-forwarded-for",
    "x-real-ip",
}


def resolve_downstream(path: str, table: list[tuple[str, str]]) -> str:
    best, best_len = None, -1
    for prefix, service in table:
        if (path == prefix or path.startswith(prefix + "/")) and len(prefix) > best_len:
            best, best_len = service, len(prefix)
    if best is None:
        raise HTTPException(404, "资源不存在")
    return best


def base_url_for(service: str) -> str:
    settings = get_settings()
    return {"user": settings.user_ms_url, "meeting": settings.meeting_ms_url, "stt": settings.stt_ms_url}[service]


def _downstream_headers(request: Request, identity: ClientIdentity | None) -> dict[str, str]:
    headers = {k: v for k, v in request.headers.items() if k.lower() not in IDENTITY_HEADERS}
    if identity is not None:
        headers["X-User-ID"] = identity.user_id
        # HTTP headers are ASCII-only: percent-encode the display name, decoded by the downstream deps.
        headers["X-User-Name"] = quote(identity.user_name, safe="")
        if identity.user_phone:
            headers["X-User-Phone"] = identity.user_phone
        headers["X-Session-ID"] = identity.session_id
    if (token := get_settings().internal_service_token):
        headers["X-Internal-Token"] = token
    # downstream sees the real client address, not the gateway's
    from gateway_ms.auth.core import client_ip_from_scope

    ip = client_ip_from_scope(request) or ""
    headers["X-Forwarded-For"] = ip
    headers["X-Real-IP"] = ip
    return headers


@router.api_route("/api/v1/{full_path:path}", methods=["GET", "POST", "PUT", "DELETE", "PATCH"])
async def api_proxy(full_path: str, request: Request, session: AsyncSession = Depends(get_session)):
    path = f"/api/v1/{full_path}"
    service = resolve_downstream(path, CLIENT_ROUTES)
    is_public = any(path == p or path.startswith(p + "/") for p in PUBLIC_CLIENT_PREFIXES)

    identity = None
    if is_public:
        # Public endpoints may still carry a valid token (personalized/logged answers).
        from gateway_ms.auth.core import bearer_from_request

        if bearer_from_request(request):
            try:
                identity = await require_client_identity(request, session)
            except HTTPException:
                identity = None  # invalid token behaves like anonymous, as before the split
    else:
        identity = await require_client_identity(request, session)

    # Authentication is complete. A slow upstream, upload or streamed response
    # must not retain a database connection for the lifetime of the proxy call.
    await session.close()
    return await proxy_stream(
        request.method,
        target_url(base_url_for(service), path),
        query=list(request.query_params.multi_items()),
        headers=_downstream_headers(request, identity),
        content=request.stream(),
        client=request.app.state.http_client,
    )


# IM 服务端回调：来自 IM 服务器（无用户会话），原样转发给 user_ms；
# 请求合法性由下游 SDK 回调模块的签名校验保证，见 user_ms/api/v1/im.py。
@router.api_route("/im/{full_path:path}", methods=["POST"])
async def im_proxy(full_path: str, request: Request):
    return await proxy_stream(
        request.method,
        target_url(base_url_for("user"), f"/im/{full_path}"),
        query=list(request.query_params.multi_items()),
        headers=_downstream_headers(request, None),
        content=request.stream(),
        client=request.app.state.http_client,
    )


@router.api_route("/admin/api/{full_path:path}", methods=["GET", "POST", "PUT", "DELETE", "PATCH"])
async def admin_proxy(full_path: str, request: Request):
    path = f"/admin/api/{full_path}"
    service = resolve_downstream(path, ADMIN_ROUTES)
    if not any(path == p or path.startswith(p + "/") for p in ADMIN_PUBLIC_PREFIXES):
        verify_admin(request)

    headers = _downstream_headers(request, None)
    # login/logout/revoke mutate sessions; drop any cached identity for this bearer immediately
    if service == "user" and request.method in ("POST", "DELETE"):
        from gateway_ms.auth.core import clear_cache_for_request

        clear_cache_for_request(request)

    return await proxy_stream(
        request.method,
        target_url(base_url_for(service), path),
        query=list(request.query_params.multi_items()),
        headers=headers,
        content=request.stream(),
        client=request.app.state.http_client,
    )


# ---------------------------------------------------------------- 房间信令 WebSocket 代理

try:  # websockets >= 13（asyncio 实现）
    from websockets.asyncio.client import connect as _ws_connect

    def _ws_open(target: str, headers: dict[str, str], open_timeout: float):
        return _ws_connect(target, additional_headers=headers, max_size=None, open_timeout=open_timeout)
except ImportError:  # websockets < 13（legacy 实现）
    from websockets.legacy.client import connect as _ws_connect_legacy

    def _ws_open(target: str, headers: dict[str, str], open_timeout: float):
        return _ws_connect_legacy(target, extra_headers=headers, max_size=None, open_timeout=open_timeout)


def _ws_request(scope: dict, token: str | None) -> Request:
    """Adapt a copy for HTTP auth, leaving the live WebSocket scope untouched."""
    scope = dict(scope)
    scope["type"] = "http"
    if token and "authorization" not in {k.decode("latin-1").lower() for k, _v in scope.get("headers", [])}:
        scope["headers"] = list(scope.get("headers", [])) + [(b"authorization", f"Bearer {token}".encode())]
    return Request(scope)


def _ws_headers(headers: dict[str, str]) -> dict[str, str]:
    # The downstream websocket library creates its own handshake headers. Forwarding
    # the incoming key/version/upgrade headers produces duplicate headers and HTTP 426.
    return {k: v for k, v in headers.items()
            if k.lower() not in {"host", "connection", "upgrade"}
            and not k.lower().startswith("sec-websocket-")}


async def _ws_pipe(client: WebSocket, downstream) -> None:
    """双向管道：任一侧断开即取消另一侧（帧原样透传，文本/二进制均支持）。"""

    async def client_to_downstream():
        try:
            while True:
                msg = await client.receive_text()
                await downstream.send(msg)
        except WebSocketDisconnect:
            pass

    async def downstream_to_client():
        close_code = 1000
        try:
            async for msg in downstream:
                await client.send_text(msg if isinstance(msg, str) else bytes(msg).decode("utf-8", "replace"))
        except Exception as exc:  # noqa: BLE001 — propagate authorization close codes
            close_code = getattr(exc, "code", None) or 1011
        finally:
            close_code = getattr(downstream, "close_code", None) or close_code
            if close_code in (1005, 1006, 1015) or not 1000 <= close_code < 5000:
                close_code = 1011
            try:
                await client.close(code=close_code)
            except Exception:  # noqa: BLE001 — the client may already have disconnected
                pass

    tasks = [asyncio.create_task(client_to_downstream()), asyncio.create_task(downstream_to_client())]
    _done, pending = await asyncio.wait(tasks, return_when=asyncio.FIRST_COMPLETED)
    for task in pending:
        task.cancel()
    await asyncio.gather(*tasks, return_exceptions=True)


@router.websocket("/api/v1/rooms/{room_id}/ws")
async def rooms_ws_proxy(websocket: WebSocket, room_id: str, session: AsyncSession = Depends(get_session)):
    """房间信令 WS：网关完成 Bearer 会话认证后注入 X-User-* 头转发给 meeting_ms。

    - Authorization 头优先；无法携带头的客户端可用 ?token=<session> 兜底。
    - 鉴权失败 close 4401；下游不可达 close 4502；非房间成员由下游 close 4403。
    """
    request = _ws_request(websocket.scope, websocket.query_params.get("token"))
    try:
        identity = await require_client_identity(request, session)
    except HTTPException:
        await websocket.accept()
        await websocket.close(code=4401, reason="未登录或登录已过期")
        return

    # Only the copied identity is needed while the WebSocket remains open.
    await session.close()
    ws_base = base_url_for("meeting").replace("http", "ws", 1)
    target = f"{ws_base}/api/v1/rooms/{room_id}/ws"
    try:
        async with _ws_open(target, _ws_headers(_downstream_headers(request, identity)), open_timeout=10.0) as downstream:
            await websocket.accept()
            await _ws_pipe(websocket, downstream)
    except WebSocketDisconnect:
        pass
    except Exception as exc:  # noqa: BLE001 — handshake/transport failure to the downstream
        logger.warning("room ws proxy to %s failed: %s", target, exc)
        try:
            from starlette.websockets import WebSocketState
            if websocket.application_state == WebSocketState.CONNECTING:
                await websocket.accept()
            await websocket.close(code=4502, reason="上游服务不可用")
        except Exception:  # noqa: BLE001
            pass
