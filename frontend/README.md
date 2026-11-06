# 桌面客户端

Tauri 2 + Next.js/React/TypeScript。UI 在 `src/`，Rust 原生命令、设备采集及服务端通信在 `src-tauri/`。转写、会议存储和总结在服务端执行。

本文分为 **dev 开发与自测**、**test 内部测试包**、**prod 构建与部署**。以下命令默认在 `frontend/` 目录执行，示例使用 Windows PowerShell。

共同准备：Node.js 24.15+（24.x）、pnpm 12.14.0、Rust 1.90+，以及对应系统的原生构建环境。Node 版本同时满足锁定的 IM SDK、jsdom 与构建命令要求；单元测试另需 Bun 1.3.14。工具链和检查入口与[持续集成](../docs/continuous-integration.md#检查范围)保持一致。

| 平台 | 原生构建环境 |
|---|---|
| Windows | Visual Studio C++ Build Tools、WebView2 |
| macOS | Xcode Command Line Tools；系统代码签名按发布证书配置 |
| Linux | Ubuntu 22.04 / 24.04 的依赖安装、环境检查和 Bash 构建命令见 [Linux 构建指南](../docs/building_in_linux.md) |

各平台产物在对应系统构建和验收。首次进入项目安装锁定依赖：

```powershell
pnpm install --frozen-lockfile # 按锁文件安装依赖，保持依赖版本一致
```

首次原生构建会从 GitHub 下载 FFmpeg，需要能访问 GitHub Releases 及其 CDN。已校验的 `src-tauri/binaries/` 是可复用的本地依赖缓存，不提交 Git；下载中断时保留失败日志，检查网络后重试。

会议语音、视频、聊天、共享等模块统一在 [`src/config/meeting-ui.json`](src/config/meeting-ui.json) 配置；字段说明见[会议 UI 模块配置](../docs/meeting-ui-config.md)。

## 一、dev：开发启动、修改验证与自测包

### 1. 准备开发后端

按[快速启动](../quickstart.md)配置并启动后端，对外统一访问网关 `http://127.0.0.1:39110`。需要 Python 源码热重载时，使用 [Docker 开发说明](../server/docker_dev.md)中的开发编排；沿用已有环境配置和数据卷。

### 2. 启动桌面应用

单客户端开发：

```powershell
$env:OPENMEETING_SERVER_URL = 'http://127.0.0.1:39110' # 指定本机开发网关，编译时写入客户端
pnpm tauri:dev # 启动 3118 前端服务，编译并打开一个桌面开发窗口
```

`tauri:dev` 自动启动 Next.js（3118）并编译、打开原生应用。Linux/macOS 使用 `OPENMEETING_SERVER_URL=http://127.0.0.1:39110 pnpm tauri:dev`。

Windows 三客户端联调的启动、状态、停止、重建及服务复用命令统一见[三开开发说明](DEV_MULTI.md)。三个窗口分别保存登录数据，并共用 3118 前端。

`pnpm dev` 单独启动 Next.js，适合网页界面开发；音视频、设备和服务端命令等完整业务需要在 Tauri 应用中验证。

### 3. 修改后怎样生效

| 修改内容 | 生效方式 |
|---|---|
| React 页面、样式及其导入的前端配置 | 保存后由 Next.js 热更新到开发窗口 |
| Rust 原生命令、Tauri 原生配置 | 单开由 Tauri 监听并重新编译；三开重新运行 `pnpm dev:multi`，重建受影响客户端 |
| `OPENMEETING_SERVER_URL` | 设置新地址后重新启动开发命令，编译 Rust；三开也可使用 `--server-url` |
| IM 隐藏引擎入口及其依赖 | 三开先执行 `pnpm dev:multi:stop`，再执行 `pnpm dev:multi`；单开重新运行 `pnpm tauri:dev` |
| 后端 Python、依赖或环境变量 | 按 [Docker 开发说明](../server/docker_dev.md)选择热重载、重建镜像或更新容器配置 |

停止或重建客户端前先结束正在测试的会议和录制。后端地址在 Rust **编译时**写入，桌面界面没有修改入口；单开与打包时都应显式设置，避免沿用源码默认地址。

其他开发选项：`NEXT_PUBLIC_LIVE_MEETING_DATA_SOURCE` 默认 `real`，`mock` 用于显式演示；`OPENMEETING_NEXT_DIST_DIR` 可指定独立 Next 缓存目录，同时启动多个前端服务时应分别设置。

### 4. 检查与构建开发自测包

提交前检查命令与专项回归统一维护在[桌面测试说明](TESTING.md)，真实跨端流程见[E2E 说明](../tests/e2e/README.md)。

需要脱离开发服务分发自测安装包时，首次生成本地更新签名和构建配置：

```powershell
pnpm updater:init --env dev --server-url http://127.0.0.1:39110 # 仅首次执行；跨设备改为可访问的网关
pnpm tauri:build:dev --bundles nsis # 读取 dev 配置和签名，生成 Windows EXE 开发自测安装包
```

日后修改 `.env.build.dev` 后重新执行构建命令即可。密码直接读取 `src-tauri/signing/updater/dev/password.env`，不在构建配置中重复填写。`--bundles nsis` 只生成 Windows EXE 安装包，不生成需要 WiX 的 MSI；macOS/Linux 构建时移除此参数。命令直接调用 Tauri CLI，不依赖额外 PowerShell 打包脚本。

安装后连接包内编译的开发网关；分发给其他电脑时，应将后端地址改为那些电脑可访问的测试网关，`127.0.0.1` 指向安装者自己的电脑。发给内部测试用户的 test 包见下一节。

这里的 dev/test 表示签名环境，构建默认仍生成 release 包。脚本生成的 `src-tauri/signing/updater/dev/tauri.updater.json` 提供 dev 公钥，并为内网自测允许 HTTP 更新；生产配置不启用该选项。应用标识沿用基础配置；需要与正式版并存的包，应另外配置独立应用标识。三开脚本已为三个开发窗口分别设置标识。签名环境说明见 [Updater 签名文档](UPDATER.md)。

### 5. 开发目录约定

代码职责和命名统一见[项目结构](../docs/project-structure.md)，界面遵循 [UI_design.md](UI_design.md)。保留既有路由、命令、存储键和双语命名空间；新增功能优先扩展现有业务目录。

## 二、test：构建内部测试安装包

首次初始化 test 签名和构建配置，将示例域名改为实际测试 HTTPS 网关：

```powershell
pnpm updater:init --env test --server-url https://test-meeting.example.com # 仅首次执行
pnpm tauri:build:test --bundles nsis # 读取 test 配置和签名，生成 Windows EXE 测试安装包
```

发布新版时递增 `package.json`、`src-tauri/Cargo.toml`、`src-tauri/tauri.conf.json` 及根目录 `Cargo.lock` 中应用的版本，当前桌面版本为 `0.1.1`。上传 Windows `*-setup.exe` 时须同时上传同名 `.sig`。test 包需向已安装 test 公钥的客户端分发，不能与其他签名环境的自动更新包混用。

命令读取 `.env.build.test`、`src-tauri/signing/updater/test/password.env`，并加载本地生成的 `src-tauri/signing/updater/test/tauri.updater.json`。密码无需在构建配置中重复填写；测试私钥、密码和包内公钥必须配套。test 更新配置默认要求 HTTPS。

test 包默认生成 release 安装包，版本与 dev、prod 共用基础版本配置，使用独立的 test 更新签名，应用标识沿用基础配置。macOS/Linux 构建时移除 `--bundles nsis`。安装包输出位置见下方[安装与分发](#3-安装与分发)。

## 三、prod：正式构建、安装部署与更新

### 1. 确认生产环境

先按[服务端说明](../server/README.md)部署生产网关及业务服务，确认目标网关地址和所需的 IM/RTC、模型等配置已就绪。客户端构建时使用实际生产网关的 HTTPS 地址。

发布前同步 `package.json`、`src-tauri/Cargo.toml`、`src-tauri/tauri.conf.json` 的版本，并更新根目录 `Cargo.lock` 中对应包版本。按改动范围完成[桌面测试说明](TESTING.md)中的检查和真实流程验收。

### 2. 构建正式安装包

prod 构建显式加载本地生成的 `src-tauri/signing/updater/prod/tauri.updater.json`，与 dev 使用相同的命令形式。首次初始化时传入生产 HTTPS 网关，脚本同时生成私钥、公钥、随机密码和构建配置；密码直接读取 `src-tauri/signing/updater/prod/password.env`：

```powershell
pnpm updater:init --env prod --server-url https://meeting.example.com # 仅首次执行，替换为真实网关
pnpm tauri:build:prod --bundles nsis # 读取 prod 配置和签名，生成 Windows EXE 正式安装包
```

本地 `.env.build.dev` / `.env.build.test` / `.env.build.prod` 已被 Git 忽略；文件中的私钥路径使用绝对路径，含空格或 `#` 的值使用引号。`TAURI_SIGNING_PRIVATE_KEY` 支持私钥文件路径，`TAURI_SIGNING_PRIVATE_KEY_PASSWORD` 只接受密码内容，由命令加载对应环境的 `password.env` 提供。Node 优先使用当前终端已存在的同名环境变量，因此构建终端不要保留其他环境的网关或签名变量。

构建命令自动执行前端构建（含 IM 引擎和 Next.js 静态导出），再编译原生程序并生成当前平台安装包。`OPENMEETING_SERVER_URL` 在这一步写入包内；切换地址需要重新构建并分发客户端。终端或 CI 若直接使用 `pnpm tauri:build`，还须显式传入 `--config src-tauri/signing/updater/<环境>/tauri.updater.json` 加载自己的公钥；公共基础配置不内置发行公钥。

Updater 签名与 Windows/macOS 系统代码签名分别配置，前者不替代系统证书签名；系统签名按发布证书配置。更新密钥生成、公钥及 dev / test / prod 环境的对应关系见 [Updater 签名文档](UPDATER.md)，整个生成目录不提交 Git。使用 Bash 的构建环境也可通过 `package-app.sh` 执行签名检查和打包。

### 3. 安装与分发

Rust 使用仓库根目录的 Cargo workspace。以下默认位置均相对仓库根目录；设置 `CARGO_TARGET_DIR` 后，Rust 产物以该目录为准，指定 `--target` 时还会增加目标三元组目录。保留已有构建缓存。

| 内容 | 默认位置 |
|---|---|
| Windows 单开调试程序 | `target/debug/openmeeting.exe` |
| 桌面安装包与更新签名 | `target/release/bundle/` |
| Next.js 静态导出 | `frontend/out/`，由 Tauri 打包 |
| 三开构建及进程信息 | 见[三客户端说明](DEV_MULTI.md)，与单开输出区分 |

`pnpm build` 只生成前端资源；桌面安装交付使用 Tauri 构建。安装后的桌面包使用内置静态页面，不需要本地 3118 开发服务。

安装后验收登录、入会、摄像头、麦克风、聊天、共享、录制及记录读取等实际使用流程。构建通过只说明产物生成成功，当前功能验收边界见[功能状态](../docs/feature-status.md)。

### 4. 后续发布与更新

生产代码修改后重新检查、构建并发布安装包；已安装客户端通过换装新包或已配置的自动更新渠道获取修改。

桌面更新检查由 Rust 按内置服务器地址构造业务网关更新接口；管理端需发布符合版本、渠道和灰度策略的安装包，签名必须与客户端公钥匹配。配置见[Updater 签名说明](UPDATER.md)。
