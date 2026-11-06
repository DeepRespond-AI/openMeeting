# gateway_ms（统一入口网关）

唯一对外业务入口，端口 `39110`。桌面、移动端与管理端统一访问网关；部署、环境变量及更新方式见[服务端指南](../README.md)和[运维指南](../OPERATIONS.md)。

## 职责

1. **客户端会话认证**：`ms_` token → sha256 → 查 `openmeeting_user.sessions`（进程内 30s TTL 缓存 + 滑动续期 touch）。
2. **管理端 JWT 认证**：共享 `OPENMEETING_SECRET_KEY` 本地验签（HS256，含密码指纹检查），不查库；`/admin/api/auth/login|logout` 公开。
3. **身份注入**：剥离客户端伪造的 `X-User-*`/`X-Internal-Token` 头，注入 `X-User-ID/Name/Phone`、`X-Session-ID`、`X-Internal-Token`、`X-Forwarded-For/X-Real-IP`。
4. **路径转发**（httpx 全流式，JSON/上传/下载/SSE 一律透传字节）。
5. **服务间路由**：`/internal/{user|meeting|stt}/{path}` → 对应服务 `/internal/{path}`。必须配置并提供内部令牌，不接受用户会话代替；清除调用方身份和 Cookie，保持二进制请求与下游状态。user_ms/meeting_ms 只配置 `OPENMEETING_GATEWAY_MS_URL`，不持有其他业务 ms 的地址。

## 路由维护

对外接口路径以[API 契约](../API.md)为准，实际前缀和匹配顺序见 [gateway.py](api/gateway.py)。新增业务接口必须同步路由与契约；未匹配的 `/api/v1/*`、`/admin/api/*` 直接返回 404。`/admin/*` 的非 API 页面由网关托管。

服务间路由的认证、头处理和错误行为见[内部网关契约](../API.md#internal-gateway)，供应商代理的白名单和运行参数见[出站网关说明](../../docs/unified-egress.md)。不在本页维护另一份路由清单。

会话吊销/账号禁用最多延迟 `OPENMEETING_SESSION_CACHE_TTL_SEC`（默认 30s）生效；相关主动失效操作会清理对应缓存，具体逻辑见[认证实现](auth/core.py)。
