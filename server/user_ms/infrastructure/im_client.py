"""deeprespond IM 服务端 SDK 封装。

设计要点：
- 尽力而为：IM 不可用只降级记日志，绝不影响登录等主流程（对齐 MeetingClient 的风格）；
- 惰性导入：deeprespond-im-server-sdk 已发布，但 IM 未开启时一切调用抛
  ImUnavailableError（发消息这类通知场景由调用方降级为 None）；
- AsyncDRClient 绑定事件循环：按运行中的事件循环各持有一个客户端。user_ms 单
  worker 部署，即进程内单例；App Token 由 SDK 缓存在客户端里，无需共享存储。
"""
from __future__ import annotations

import asyncio
import logging
from dataclasses import dataclass
from typing import TYPE_CHECKING, Any
from weakref import WeakKeyDictionary

from user_ms.config import get_settings
from service_net.egress import async_client

if TYPE_CHECKING:
    from deeprespond_im.callback import CallbackResponse

logger = logging.getLogger(__name__)

# 通知账号：业务上用它给用户发单聊通知（提前注册为普通用户即可；client_msg_id
# 幂等由 IM 服务端保证）。
NOTICE_USERNAME = "notice"


class ImUnavailableError(RuntimeError):
    """IM 不可用（未开启 / 配置缺失 / SDK 未安装）。异常消息即具体原因。"""


@dataclass
class _LoopState:
    client: Any
    http: Any


# 每个事件循环一个客户端：AsyncDRClient 只能用于首次发请求的事件循环。
_clients: "WeakKeyDictionary[asyncio.AbstractEventLoop, _LoopState]" = WeakKeyDictionary()


def _missing_reason() -> str | None:
    """IM 不可用的原因；可用时返回 None。"""
    s = get_settings()
    if not s.im_enabled:
        return "OPENMEETING_IM_ENABLED=false"
    if not (s.im_base_url and s.im_org_name and s.im_app_name and s.im_client_id and s.im_client_secret):
        return "IM 连接配置不完整（IM_BASE_URL / IM_ORG_NAME / IM_APP_NAME / IM_CLIENT_ID / IM_CLIENT_SECRET）"
    try:
        import deeprespond_im  # noqa: F401
    except ImportError:
        return "deeprespond-im-server-sdk 未安装"
    return None


async def get_client() -> Any:
    """返回当前事件循环的 AsyncDRClient；IM 不可用时抛 ImUnavailableError。

    创建客户端不发请求，第一次调用接口时才换取 App Token（SDK 内部保证并发下
    只换取一次），这里不需要加锁。
    """
    reason = _missing_reason()
    if reason:
        raise ImUnavailableError(reason)

    loop = asyncio.get_running_loop()
    state = _clients.get(loop)
    if state is None:
        from deeprespond_im import AsyncDRClient

        s = get_settings()
        http = async_client(s, timeout=s.im_timeout_seconds, follow_redirects=False)
        try:
            client = AsyncDRClient(
                base_url=s.im_base_url,
                org_name=s.im_org_name,
                app_name=s.im_app_name,
                client_id=s.im_client_id,
                client_secret=s.im_client_secret,
                timeout=s.im_timeout_seconds,
                http_client=http,
            )
        except Exception:
            await http.aclose()
            raise
        state = _LoopState(client=client, http=http)
        _clients[loop] = state
        logger.info("IM 客户端已创建: base_url=%s, org=%s, app=%s", s.im_base_url, s.im_org_name, s.im_app_name)
    return state.client


async def aclose_client() -> None:
    """关闭当前事件循环的客户端（应用停机时释放连接池；没有创建过则什么也不做）。"""
    loop = asyncio.get_running_loop()
    state = _clients.pop(loop, None)
    if state is None:
        return
    try:
        await state.client.aclose()
    except Exception:  # noqa: BLE001 —— 停机清理失败只记日志
        logger.warning("关闭 IM 客户端失败", exc_info=True)
    finally:
        await state.http.aclose()


async def issue_login_ticket(user_id: str) -> dict:
    """为业务用户签发 IM 登录凭证：{ticket, expires_in, user_created}。

    IM 用户名直接用业务用户 ID；用户不存在时自动创建（auto_create=True），
    不必先同步用户。凭证 5 分钟内有效、只能使用一次，重复签发安全（可重试）。

    可能抛出 SDK 异常（凭据错误、用户被封禁 user_disabled、限流等），
    由 API 层决定如何呈现给前端。
    """
    client = await get_client()
    result = await client.users.issue_login_ticket(user_id, auto_create=True)
    return {"ticket": result.ticket, "expires_in": result.expires_in, "user_created": result.user_created}


async def issue_login_ticket_best_effort(user_id: str) -> dict | None:
    """登录/注册响应里用的尽力而为版本：IM 不可用或失败时返回 None，绝不影响登录。

    用户不存在时由 auto_create 在首次签发时自动创建 IM 账号，无需单独同步用户。
    """
    try:
        return await issue_login_ticket(user_id)
    except ImUnavailableError as exc:
        logger.info("IM 未启用，跳过签发登录凭证: %s, user_id=%s", exc, user_id)
        return None
    except Exception:  # noqa: BLE001 —— 凭证只是登录的附带品，失败不能拖垮登录
        logger.error("签发 IM 登录凭证失败（忽略）: user_id=%s", user_id, exc_info=True)
        return None


async def send_message(
    *,
    to_user: str,
    client_msg_id: str,
    body: dict,
    type: str = "custom",
    push: dict | None = None,
    from_: str = NOTICE_USERNAME,
) -> dict | None:
    """以通知账号给用户发一条单聊消息。尽力而为：任何失败返回 None，绝不抛出。

    client_msg_id 请用业务单号这样的稳定 ID（如 "meeting-{id}-summary"）：服务端按
    「会话、发送者、client_msg_id」去重，业务层重试也不会重复发送。
    返回 {message_id, duplicate}；duplicate=True 表示之前已发送过，本次是幂等重放。
    """
    try:
        client = await get_client()
        kwargs: dict = {
            "from_": from_,
            "to_user": to_user,
            "client_msg_id": client_msg_id,
            "type": type,
            "body": body,
        }
        if push is not None:
            kwargs["push"] = push
        result = await client.messages.send(**kwargs)
    except ImUnavailableError as exc:
        logger.info("IM 未启用，跳过发送消息: %s, to_user=%s, client_msg_id=%s", exc, to_user, client_msg_id)
        return None
    except Exception:  # noqa: BLE001 —— 通知失败不影响业务主流程
        logger.error("IM 发送消息失败: to_user=%s, client_msg_id=%s", to_user, client_msg_id, exc_info=True)
        return None
    if getattr(result, "duplicate", False):
        logger.info("IM 消息重复提交，已返回首次写入: client_msg_id=%s", client_msg_id)
    return {
        "message_id": getattr(result, "message_id", None),
        "duplicate": bool(getattr(result, "duplicate", False)),
    }


# ---------------------------------------------------------------------------
# 服务端回调（「接收回调」）：签名校验、防重放、事件去重、URL 验证应答
# 均由 deeprespond_im.callback 提供，这里只负责配置与装配。
# ---------------------------------------------------------------------------

_callback_cache: dict[tuple[str, tuple[str, ...]], Any] = {}


def _callback_handler() -> Any:
    """返回回调处理器（AsyncCallbackHandler），按回调配置缓存；未开启/配置缺失/SDK 缺失时抛 ImUnavailableError。

    防重放与事件去重存储用进程内存版：user_ms 单 worker 部署（见模块 docstring），
    单进程内即成立；将来改多 worker 或多机部署时须换 deeprespond_im.redis 里的共享存储。
    """
    s = get_settings()
    if not s.im_enabled:
        raise ImUnavailableError("OPENMEETING_IM_ENABLED=false")
    endpoint_id = s.im_callback_endpoint_id.strip()
    secrets = tuple(x.strip() for x in s.im_callback_secret.split(",") if x.strip())
    if not (endpoint_id and secrets):
        raise ImUnavailableError("IM 回调配置不完整（IM_CALLBACK_ENDPOINT_ID / IM_CALLBACK_SECRET）")

    key = (endpoint_id, secrets)
    handler = _callback_cache.get(key)
    if handler is None:
        try:
            from deeprespond_im.callback import (
                Allow,
                AsyncCallbackHandler,
                AsyncMemoryDedupStore,
                AsyncMemoryNonceStore,
            )
        except ImportError as exc:
            raise ImUnavailableError("deeprespond-im-server-sdk 未安装") from exc

        handler = AsyncCallbackHandler(
            secrets={endpoint_id: list(secrets)},
            nonce_store=AsyncMemoryNonceStore(),
            dedup_store=AsyncMemoryDedupStore(),
            # user_ms 不做内容审核：未注册的同步回调（超时或没有处理函数）一律放行，不阻塞 IM 侧流程。
            hook_fallback=Allow(),
        )

        @handler.on_unknown_event
        def _log_unknown(event: Any) -> None:
            logger.info("收到 IM 未知事件（忽略）: type=%s, id=%s", event.type, event.id)

        _callback_cache[key] = handler
    return handler


async def handle_callback(*, headers: dict, body: bytes) -> CallbackResponse:
    """处理一条 IM 服务端回调，返回 SDK 的 CallbackResponse（status/headers/body 由 API 层原样写回）。

    事件处理函数暂未注册业务逻辑：事件照常校验、去重，未注册的记日志后忽略（回 204）。
    IM 未开启或回调配置缺失时抛 ImUnavailableError，API 层回 503，IM 服务器会按
    重试策略重投，不会丢事件。
    """
    handler = _callback_handler()
    return await handler.handle(headers, body)
