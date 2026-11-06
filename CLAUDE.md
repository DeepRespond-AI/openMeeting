# 仓库开发指南

## 当前架构

深应会议 包含 Tauri/Next.js 桌面客户端、Flutter 移动客户端、四个 FastAPI 服务和 Vue 管理端。对外入口为 gateway_ms，端口 39110；桌面 Next.js 开发服务使用端口 3118。

- 启动步骤见[快速启动](quickstart.md)，目录职责见[项目结构](docs/project-structure.md)，系统关系见[架构说明](docs/architecture.md)。
- 客户端、管理端 API 及 Tauri 命令以 [server/API.md](server/API.md) 为准。修改时同步更新调用方与契约。
- 实现及验收状态统一维护在[功能状态](docs/feature-status.md)。测试夹具和截图不能证明真机、真实模型或生产环境已经验收。

## 目录职责

- `frontend/src/`：界面、状态及 TypeScript 服务。
- `frontend/src-tauri/src/server/`：鉴权请求、原生命令、会话及会议房间信令。
- `frontend/src-tauri/src/audio/`：原生音频设备、缓冲、混音及 VAD。维护关闭流程、缓冲行为及线程和异步安全。
- `server/gateway_ms/`：鉴权、路由及构建后的管理界面。
- `server/user_ms/`：用户、登录、会话、短信、版本发布及 IM 票据。
- `server/meeting_ms/`：会议数据、日程、房间、录音、任务及总结。
- `server/stt_ms/`：语音推理和模型生命周期。
- `server/service_net/`：通过 gateway_ms:39111 出站的共享客户端，连接失败时拒绝直连回退；保留 SDK 的 TLS 校验和签名。详见[出站配置](docs/unified-egress.md)。
- `server/admin-web/`：构建产物输出到 `server/gateway_ms/static/admin/`。
- `mobile/`：遵守其 DEVELOPMENT.md 和独立环境配置，不能推定其功能与桌面端完全一致。
- `legacy/`：仅在本地保留的历史资料，已取消 Git 跟踪，不在此处新增当前功能。

## 开发

在 `server/` 中执行 `docker compose up -d --build`。四个服务的本机开发方式见 `server/README.md`；不再支持旧单体启动入口。

在 `frontend/` 中使用 PowerShell：

```powershell
pnpm install --frozen-lockfile
$env:OPENMEETING_SERVER_URL = 'http://127.0.0.1:39110'
pnpm tauri:dev
```

后端 URL 编译到 Rust 中，桌面界面不能编辑；修改后需要重新构建原生程序。会话和客户端 ID 使用 tauri-plugin-store 保存。IM 应用配置与票据由服务端提供，平台密钥保留在服务端。

Rust 使用仓库根目录的 Cargo 工作区，默认输出到根目录 `target/`，可由 `CARGO_TARGET_DIR` 覆盖。安装包及签名分别见[桌面指南](frontend/README.md)和[移动端指南](mobile/README.md)。不要仅为启动开发环境而删除构建缓存。

## 开发约定

- 业务目录使用 kebab-case，React 组件文件使用 PascalCase，Hooks 使用 useX。
- 会中界面位于 `src/components/live-meeting/`，服务位于 `src/services/live-meeting/`。
- 重构路径时保持路由、IPC 命令名、i18n 命名空间和持久化键稳定。
- 品牌、深色主题、共享组件及中英文界面文案遵守 `frontend/UI_design.md`。
- 默认使用真实适配器；模拟实现或合成输入必须显式标注，并说明验收边界。
- Tauri 命令需要注册到调用处理器，同时更新调用方与契约。
- 桌面端不使用本地会议数据库，也不运行本地 STT 推理。

## 测试与记录

- 前端：`pnpm exec tsc --noEmit`、`pnpm test:unit`（使用 Bun，按文件隔离）及 `pnpm test:recording`。
- 后端：在 `server/` 中使用隔离测试数据库执行 `uv run pytest`，详见 `docs/testing/README.md`。
- 可复用的原生跨客户端测试位于 `tests/e2e/`。
- 历史验收快照和内部开发计划仅在本地保留，不随源码分发；当前测试方法见 `docs/testing/README.md`。
- 本地产物放入已忽略的 `.artifacts/`，归档也应留在已忽略的本地目录。不得提交内部截图、登录令牌、密钥、模型权重或原始录音。
- 隔离测试配置和数据，不停止无关进程，也不重置业务数据库。

验证本次修改涉及的层并完成相关检查，保留现有配置和数据，不将旧版构建步骤复制到当前文档。
