# Linux 桌面开发与构建

本文面向 Linux x86_64 桌面开发，系统依赖以仓库 Linux 工作流列出的 Ubuntu 22.04 / 24.04 为范围。服务器 Docker 部署使用[服务端指南](../server/README.md)，无需安装桌面 WebKitGTK。桌面平台依赖参考 [Tauri 2 官方前置条件](https://v2.tauri.app/start/prerequisites/#linux)，音频与 X11 开发库按本项目原生依赖补充。

## 1. 系统依赖

在 Ubuntu 终端执行，安装系统库需要 sudo：

```bash
sudo apt-get update
sudo apt-get install -y build-essential pkg-config cmake clang libclang-dev \
  curl wget file libssl-dev libwebkit2gtk-4.1-dev libayatana-appindicator3-dev \
  librsvg2-dev patchelf libasound2-dev libxdo-dev libx11-dev libxtst-dev libxrandr-dev
```

使用发行版当前的软件包，不固定 WebKit 小版本。其他发行版按官方前置条件安装对应包；不要将 WebKitGTK 4.0 替代本项目需要的 4.1。CI 的构建目标和参数见 [Linux 工作流](../.github/workflows/build-linux.yml)。

另外安装 Node.js 24.15+（24.x）、pnpm 12.14.0、Rust 1.90+；需要单元测试时安装 Bun 1.3.14。工具链完整版本见[持续集成](continuous-integration.md#检查范围)。在开发终端确认：

```bash
node --version
pnpm --version
rustc --version
cargo --version
pkg-config --modversion webkit2gtk-4.1 alsa
```

首次原生构建会下载 FFmpeg，需能访问 GitHub Releases 及其 CDN；已校验的 `frontend/src-tauri/binaries/` 可复用。构建缓存不需要删除。

## 2. 开发运行

先准备[快速启动](../quickstart.md)中的后端、模型及 IM/RTC 配置。本机 Linux 终端使用 Bash；以下从仓库根开始：

```bash
cd frontend
pnpm install --frozen-lockfile
OPENMEETING_SERVER_URL=http://127.0.0.1:39110 pnpm tauri:dev
```

远程后端改为实际可访问的网关地址。桌面端还需访问对象存储签名入口和 IM/RTC 平台，连接边界见[对象存储](object-storage.md#客户端联调地址)。桌面界面不能修改编译时写入的网关地址，修改后重新运行开发命令。

`pnpm dev` 只启动网页开发服务，完整设备和原生命令需通过 `pnpm tauri:dev` 验证。应用应在当前用户的图形桌面会话中运行；SSH 无图形会话不能代替设备与页面验收。

## 3. 构建安装包

在 `frontend/` 首次初始化自己的开发更新签名，然后生成 DEB；跨设备分发时把回环地址换成设备可达的网关：

```bash
pnpm updater:init --env dev --server-url http://127.0.0.1:39110
pnpm tauri:build:dev --bundles deb
```

正式包改用 `--env prod`、实际生产 HTTPS 网关及 `pnpm tauri:build:prod --bundles deb`。环境配置已有时初始化脚本会保留文件，按需编辑本地配置；已有发行版继续使用原更新密钥。签名原理、配置文件和版本要求统一见[桌面指南](../frontend/README.md#三prod正式构建安装部署与更新)及[Updater 签名](../frontend/UPDATER.md)。

默认安装包位于仓库根 `target/release/bundle/deb/`；设置 `CARGO_TARGET_DIR` 或 `--target` 时路径按[产物说明](../frontend/README.md#3-安装与分发)变化。构建通过后仍需在目标系统验证音频采集、播放、摄像头、共享、系统权限和安装升级；当前验收边界见[功能状态](feature-status.md)。
