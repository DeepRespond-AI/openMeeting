# 测试入口

可复用自动化与内部验收记录分开维护。运行结果、截图和日志本地输出至根目录 `.artifacts/`，不随公开源码分发。使用专用测试账号、隔离客户端标识及测试数据库，避免覆盖用户配置。

GitHub PR 自动执行范围、工具链版本、报告和必需状态检查见[持续集成](../continuous-integration.md)。`Quality Gate` 汇总各端结果；真实设备和外部平台的验收继续按下文区分。

| 检查 | 入口与职责 |
|---|---|
| 桌面类型、单元及媒体故障契约 | [桌面测试](../../frontend/TESTING.md)：具体命令、设备/SDK 替身和运行范围 |
| Flutter 单元、页面与代码生成 | [移动测试](../../mobile/TESTING.md)：专项命令及原生验收边界 |
| 页面与跨客户端流程 | [E2E 脚本](../../tests/e2e/README.md)：脚本参数、夹具冒烟、原生与合成输入分别说明 |
| Python 单服务回归 | 下方[测试数据库](#后端测试数据库)：各服务连接自己的隔离库，再执行对应 pytest |
| 后端跨服务集成 | [server/tests/](../../server/tests/)：按各用例的说明设置依赖，不默认包含在单服务 pytest 中 |
| 移动能力对齐专项 | [核心能力复现](../../tests/e2e/mobile-parity/README.md)、[自动录音与共享记录复现](../../tests/e2e/mobile-auto-records/README.md)：隔离后端与明确媒体输入 |

## 后端测试数据库

测试使用专用 PostgreSQL 实例，不连接日常业务库。按[数据库隔离说明](../database-isolation.md#隔离验收)创建独立测试项目，每个服务的 pytest 进程通过 `OPENMEETING_TEST_DATABASE_URL` 指向自己的测试库。

| 测试进程 | 测试库 | 专用编排的回环端口 |
|---|---|---|
| user_ms/tests | openmeeting_user | 55451 |
| meeting_ms/tests | openmeeting_meeting | 55452 |
| stt_ms/tests | openmeeting_stt | 55453 |

在 `server/` 中执行单个服务的测试，例如：

```powershell
$env:OPENMEETING_TEST_DATABASE_URL = 'postgresql+asyncpg://openmeeting:<测试库密码>@127.0.0.1:55452/openmeeting_meeting' # 替换为已创建的专用测试库连接串，密码按 URL 编码
uv run pytest meeting_ms/tests # 仅测试该连接对应的会议服务
```

其他服务在各自进程中使用对应连接串，不给多个服务共用同一个数据库 URL。具体设置以对应 `tests/conftest.py` 为准。测试会清空测试表，不在页面验收仍使用同一测试库时并行执行；环境代理也应与夹具地址一致。结束后只关闭本次创建的测试资源，保留业务服务和数据卷。

## 证据与边界

历史报告、当时环境、内部截图、日志和脚本快照仅在维护者本地保留，不作为当前操作入口。公开源码中的测试脚本不内置个人设备地址或开发机路径；按 [E2E 说明](../../tests/e2e/README.md)配置自己的工具链、设备和专用账号。

真实设备、合成输入、SDK 调试构建、模型夹具、真实 STT/LLM、生产安装包应分别记录。功能当前状态见[feature-status.md](../feature-status.md)。可运行 `node scripts/check-doc-links.mjs` 检查本地链接。
