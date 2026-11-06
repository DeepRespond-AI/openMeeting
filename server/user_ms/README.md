# user_ms：用户域服务

负责手机号注册/登录、业务会话、用户资料、短信、客户端版本发布、连接注册表及 IM/RTC 平台服务端接入。内部端口为 `39113`，独占 `openmeeting_user` 数据库；客户端和管理端经网关访问。

本页维护用户域的代码位置、数据归属和开发约束。完整操作统一从以下入口阅读：

| 任务 | 入口 |
|---|---|
| Docker / 裸机启动、环境变量、短信和版本发布配置 | [服务端指南](../README.md) |
| 源码重载、依赖更新及数据库结构开发 | [Docker 开发指南](../docker_dev.md) |
| 客户端、管理端及内部调用契约 | [API 契约](../API.md)、[接入示例](../API_GUIDE.md) |
| 测试数据库和执行方式 | [测试入口](../../docs/testing/README.md#后端测试数据库) |
| 数据与密钥备份、恢复及故障排查 | [运维指南](../OPERATIONS.md) |

## 身份与会话实现

- 业务令牌仅保存 SHA-256 摘要；本服务创建、吊销会话，网关负责校验、进程内缓存及滑动续期。参数和有效期见 [API 鉴权契约](../API.md#client-auth)，校验实现见[网关鉴权](../gateway_ms/auth/core.py)。
- 用户密码使用带独立盐的 scrypt 哈希；短信验证码使用服务端密钥参与哈希，短信审计不保存验证码原文。密码强度、锁定与短信限流由 [auth/](auth/) 实现，不在文档中复制算法代码。
- 管理端 JWT 在网关与用户服务分别校验。服务间调用和回调经内部令牌保护，平台回调另外验证平台签名；认证边界见 [API 内部网关契约](../API.md#internal-gateway)。
- 生产部署须显式配置共享密钥、管理员密码和内部令牌；本地 `dev_code` 与弱口令仅用于开发环境。实际配置项以 [config.py](config.py) 和[环境变量示例](.env.example)为准。

## 代码定位

| 目录 / 文件 | 职责 |
|---|---|
| [main.py](main.py)、[config.py](config.py) | 启动、数据库迁移、配置与资源释放 |
| [api/](api/) | 业务认证、心跳、更新、IM 票据及内部接口挂载和鉴权 |
| [admin/](admin/) | 用户、会话、短信与版本发布管理 |
| [auth/](auth/) | 会话、密码、验证码和管理员认证 |
| [db/](db/)、[migrations/](migrations/) | 数据模型、系统配置及 Alembic 迁移 |
| [updates/](updates/)、[storage/](storage/) | 版本比较、灰度、安装包及本地/OSS 存储 |
| [infrastructure/](infrastructure/) | 经网关的业务 RPC、IM 服务端 SDK 及其生命周期 |
| [monitor/](monitor/) | 在线连接、录制状态与请求统计 |
| [tests/](tests/) | 用户域回归测试 |

## 数据归属与变更约束

`users`、`sessions`、`sms_codes`、`sms_logs`、`user_settings`、`client_releases`、`client_release_artifacts` 和用户域 `system_settings` 由本服务维护，完整定义见 [db/models.py](db/models.py)。会议与推理数据分别属于另外两个数据库。

新增接口在对应路由模块定义请求/响应模型，同步更新 API 契约和消费者；结构变化通过 Alembic 迁移，不直接修改已有数据库表。会话吊销须同步清理在线注册表，用户删除须先确认会议服务的数据清理成功。

内部 HTTP 通过网关，平台 SDK 和 OSS/短信出站通过[统一出站代理](../../docs/unified-egress.md)。供应商密钥留在服务端；客户端只获得按业务权限签发的凭证。IM 会中群的授权与结束规则见[聊天生命周期](../../docs/meeting-im-chat.md)。
