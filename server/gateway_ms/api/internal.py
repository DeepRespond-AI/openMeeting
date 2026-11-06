"""Authenticated service-to-service routing. Downstream addresses belong only to the gateway."""
from __future__ import annotations

import hmac

from fastapi import APIRouter, HTTPException, Request

from gateway_ms.api.gateway import _downstream_headers, base_url_for
from gateway_ms.config import get_settings
from gateway_ms.infrastructure.proxy import proxy_stream, target_url

router = APIRouter()


@router.api_route("/internal/{service}/{full_path:path}", methods=["GET", "POST", "PUT", "DELETE", "PATCH"])
async def internal_proxy(service: str, full_path: str, request: Request):
    token = get_settings().internal_service_token
    if not token:
        raise HTTPException(503, "内部服务令牌未配置")
    given = request.headers.get("x-internal-token", "")
    if not hmac.compare_digest(given.encode(), token.encode()):
        raise HTTPException(401, "缺少或无效的内部服务令牌")
    # Never accept a caller-supplied URL or let a path escape the downstream /internal namespace.
    if (service not in {"user", "meeting", "stt"} or not full_path
            or any(part in {"", ".", ".."} for part in full_path.split("/"))
            or any(char in full_path for char in ("\\", "%", "?", "#"))):
        raise HTTPException(404, "资源不存在")
    headers = _downstream_headers(request, None)
    headers = {k: v for k, v in headers.items() if k.lower() not in {"authorization", "cookie"}}
    return await proxy_stream(
        request.method, target_url(base_url_for(service), f"/internal/{full_path}"),
        query=list(request.query_params.multi_items()), headers=headers,
        content=request.stream(), client=request.app.state.http_client,
    )
