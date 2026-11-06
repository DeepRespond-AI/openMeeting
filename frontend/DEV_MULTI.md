# Windows 三客户端开发

一份代码、一个 Next.js 服务（3118）、三个 Tauri 开发客户端。先按 [快速启动](../quickstart.md) 启动后端，再在 `frontend/` 执行：

```powershell
pnpm install --frozen-lockfile
pnpm dev:multi
```

首次启动需要编译三个不同应用标识的 Rust 客户端，工具链按[桌面指南](README.md)准备，包括 Node.js、pnpm、Rust 和 Visual Studio C++ Build Tools。后续启动复用构建缓存。脚本目前只支持 Windows。

| 窗口 | 应用标识 | 登录和 WebView 数据目录 |
|---|---|---|
| DEV A | `com.openmeeting.ai.dev1` | `%APPDATA%\com.openmeeting.ai.dev1` |
| DEV B | `com.openmeeting.ai.dev2` | `%APPDATA%\com.openmeeting.ai.dev2` |
| DEV C | `com.openmeeting.ai.dev3` | `%APPDATA%\com.openmeeting.ai.dev3` |

三个窗口分别登录不同测试账号，即可测试同一会议。账号、会话和客户端标识分别持久化；业务数据使用同一个后端。脚本不会创建账号。关闭后重新启动仍保留登录记录。普通 `pnpm tauri:dev` 的应用标识和数据目录独立于这三个客户端。

React、页面样式等前端修改通过 Next.js 热更新到三个窗口，无需复制代码或重新打包 exe。Rust、原生配置或后端地址修改后，重新执行 `pnpm dev:multi` 会重建受影响客户端。IM 隐藏引擎由单独的打包脚本生成，修改 `src/im/engine-entry.ts` 及其依赖后执行 `pnpm dev:multi:stop`，再执行 `pnpm dev:multi`。重新构建或停止前，请先结束测试中的会议和录制。

```powershell
pnpm dev:multi:status
pnpm dev:multi:stop
pnpm dev:multi --rebuild
pnpm dev:multi --server-url http://127.0.0.1:39110
```

后端地址优先级：`--server-url`、环境变量 `OPENMEETING_SERVER_URL`、`frontend/.env` 中的同名变量，默认 `http://127.0.0.1:39110`。该地址编译进三个客户端。

已存在的本仓库 Next.js 3118 服务会被复用，停止命令保留该服务。没有服务时脚本自动启动；此时停止命令也会停止它。复用的服务沿用其启动环境，请确保使用真实后端模式（`NEXT_PUBLIC_LIVE_MEETING_DATA_SOURCE=real`，也是默认值）。端口被其他项目占用时，脚本报错并保留现有进程。

重复启动复用仍在运行的客户端，只补开缺失窗口。停止命令通过 PID、进程创建时间和可执行路径核对进程身份，不会批量结束其他 Node/Tauri 应用。

生成文件、每个客户端的日志及运行记录位于根目录 `.artifacts/dev-multi/`；Cargo 默认缓存为 `target/dev-multi-native/`，均被 Git 忽略。可通过 `--target-dir E:\path\to\cargo-cache` 复用已有 Cargo 缓存，该路径会保存在本机运行记录中。不要指定正在运行 `debug/openmeeting.exe` 的构建目录。

脚本提供三开开发环境；真实音视频、屏幕共享和录制仍需使用三个账号实际操作验证。
