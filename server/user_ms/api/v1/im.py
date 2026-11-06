"""deeprespond IM：登录凭证签发与服务端回调接收。"""
from __future__ import annotations

import logging

from fastapi import APIRouter, Depends, HTTPException, Request
from fastapi.responses import JSONResponse, Response

from user_ms.api.deps import AuthContext, require_client
from user_ms.infrastructure import im_client
from user_ms.config import get_settings

logger = logging.getLogger(__name__)

# 需要登录会话的端点：挂到 /api/v1 下的受保护路由组（网关已完成认证）。
router = APIRouter(prefix="/im", tags=["im"])
# 回调由 IM 服务器经网关透传发起（无用户会话）：请求合法性由 SDK 回调模块的
# 签名校验与防重放保证；应用根路由仍要求网关注入的内部服务令牌，不要求用户会话。
callback_router = APIRouter(prefix="/im", tags=["im"])


@router.post("/ticket")
@router.get("/ticket", include_in_schema=False)
async def issue_ticket(response: Response, ctx: AuthContext = Depends(require_client)) -> dict:
    """为当前登录用户签发 IM 登录凭证（一次性，5 分钟内有效，IM 用户不存在时自动创建）。

    客户端拿到 ticket 后交给 IM 客户端 SDK 登录；IM 未开启时返回 503，
    账号被 IM 侧封禁时返回 403。
    """
    try:
        result = await im_client.issue_login_ticket(ctx.user_id)
        settings = get_settings()
        response.headers["Cache-Control"] = "private, no-store"
        return {**result, "api_url": settings.im_base_url.rstrip("/"),
                "app_key": f"{settings.im_org_name}#{settings.im_app_name}",
                "expires_in_sec": result["expires_in"]}
    except im_client.ImUnavailableError as exc:
        raise HTTPException(503, f"IM 服务未开启：{exc}") from exc
    except Exception as exc:  # noqa: BLE001 —— SDK 异常类型随版本演进，按属性识别
        if getattr(exc, "code", None) == "user_disabled":
            raise HTTPException(403, "该账号已被禁用") from exc
        logger.error("签发 IM 登录凭证失败: user_id=%s", ctx.user_id, exc_info=True)
        raise HTTPException(502, "IM 服务暂时不可用，请稍后重试") from exc


@callback_router.post("/callback")
async def receive_callback(request: Request) -> Response:
    """接收并分派 IM 服务器的事件回调。

    签名校验、防重放、事件去重与 URL 验证应答由 SDK 回调处理器完成，其
    status/headers/body 原样写回（如签名失败 401、事件处理完成 204、
    存储故障 503 触发 IM 服务器重投）。IM 未开启或回调未配置时回 503。
    """
    body = await request.body()
    try:
        result = await im_client.handle_callback(headers=dict(request.headers), body=body)
    except im_client.ImUnavailableError as exc:
        return JSONResponse({"detail": f"IM 回调暂不可用：{exc}"}, status_code=503)
    return Response(content=result.body, status_code=result.status, headers=result.headers)
