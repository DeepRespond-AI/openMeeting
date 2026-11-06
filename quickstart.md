# 深应会议 快速启动

本文包含从配置后端到启动客户端的最短流程，可以直接按顺序操作。以下以 Windows PowerShell 为例，新终端先进入仓库根目录（例如 `C:\projects\meeting`）。

## 运行准备

- 后端：安装并启动 Docker Desktop，使用 Linux 容器；Docker Compose v2.20+。
- 桌面开发：Node.js 24.15+（24.x）、pnpm 12.14.0、Rust 1.90+、Visual Studio C++ Build Tools 和 WebView2。Linux 开发另见 [Linux 构建指南](docs/building_in_linux.md)。
- Android 开发：另外准备 Flutter 3.47.7（Dart 3.13.5）、Android SDK、JDK 17 及模拟器或已授权的真机。工具链与测试要求见[持续集成](docs/continuous-integration.md#检查范围)。

默认端口：业务网关 **39110**，桌面开发前端 **3118**，管理端入口为网关的 `/admin`，MinIO 文件入口为 **39120**。三个 PostgreSQL 和业务服务由 Compose 编排。客户端的业务地址只配置网关；完整文件直传和下载还需访问后端签发的对象存储地址。

## 1. 启动服务端

首次在仓库根目录生成本地开发配置，已有文件会保留，不改动生产 `.env`：

```powershell
node scripts/init-server-env.mjs --env dev
cd server
```

管理员密码、内部令牌及数据库密码已分别随机生成，保存在 `server/.env.dev`，请在本地编辑器中查看管理员密码，不提交这个文件。默认使用 MinIO 和轻量 `stt-cloud` 镜像，无需下载本地 Torch 或准备短信/RTC 账号即可完成基础开发。只需要本地文件存储时，首次生成加 `--storage local`；local 不支持多人会议 PCM 分片。生产配置按[服务端指南](server/README.md)单独准备。

在当前 `server/` 终端执行：

```powershell
docker compose --env-file .env.dev up -d --build # 构建并启动三个数据库和四个应用服务，包含管理端
docker compose --env-file .env.dev ps -a # 等待数据库、应用及 MinIO 就绪；minio-init 应成功退出，首次构建可能较慢
Invoke-RestMethod 'http://127.0.0.1:39110/healthz' # 检查网关响应，不能代替模型与媒体就绪检查
```

需要修改 Python 代码并自动重载时，使用下面的开发启动命令代替普通启动。仍在 `server/` 目录，先构建管理端静态文件，再挂载源码：

```powershell
pnpm --dir admin-web install --frozen-lockfile
pnpm --dir admin-web build # 生成 gateway_ms/static/admin/，供下面的源码挂载使用
docker compose --env-file .env.dev -f docker-compose.yml -f docker-compose.dev.yml up -d --build # 挂载源码，保存 Python 文件后自动重载
```

开发编排会用宿主机 `gateway_ms/` 覆盖镜像内同名目录；全新克隆不含管理端构建产物，不能省略上面的构建后直接访问 `/admin`。修改管理端页面后需重新构建；需要 Vue 热更新时另在 `server/admin-web/` 执行 `pnpm dev`，访问 `http://localhost:5173/admin/`。完整说明见[后端开发](server/docker_dev.md)。

有 NVIDIA GPU 且已安装驱动和 NVIDIA Container Toolkit 时，使用 GPU 编排：

```powershell
docker compose --env-file .env.dev -f docker-compose.yml -f docker-compose.gpu.yml up -d --build # 只为 stt_ms 启用 GPU
```

已有服务时先用 `docker compose ls` 确认实际项目和覆盖文件，后续保持相同编排组合；无需删除数据卷。

## 2. 配置模型和会议平台

浏览器打开 **http://127.0.0.1:39110/admin**，使用 `.env.dev` 中的管理员密码登录：

基础体验可先不配置云服务，继续启动客户端。`dev` 环境未配置真实短信时，验证码由开发接口返回，开发客户端会显示；不要将此模式用于公网生产。

按所需功能逐项开启：

1. **云端转写**：在管理端配置实际 ASR 提供方并测试，激活云端模型；轻量镜像不需要本地模型权重。
2. **本地 CPU 转写**：将 `.env.dev` 的 `OPENMEETING_STT_RUNTIME` 改为 `stt-cpu`，执行 `docker compose --env-file .env.dev up -d --build stt_ms`。再在管理端下载、加载模型并确认就绪；资源选择见[部署容量](docs/deployment-capacity.md)。
3. **总结**：配置实际 OpenAI 兼容 LLM 提供方，测试连接后设为当前；不配置时不承诺总结可用。
4. **多人会议**：准备 IM/RTC 平台应用及相应能力，按 [server/.env.example](server/.env.example) 配置服务端凭据和出站白名单。平台账号、额度和媒体网络不由普通 Compose 栈提供。
5. **生产短信**：按[服务端短信配置](server/README.md#四短信配置阿里云短信服务)接入短信服务，并使用独立生产环境；不依赖开发验证码。

修改 `.env.dev` 后重新执行本轮使用的 Compose 命令；模型、云服务和媒体的就绪状态分别确认。客户端不填写平台服务端密钥。

## 3. 启动桌面客户端

另开终端，从仓库根目录执行：

```powershell
cd frontend # 进入桌面客户端目录
pnpm install --frozen-lockfile # 首次安装或锁文件变化后安装依赖
$env:OPENMEETING_SERVER_URL = 'http://127.0.0.1:39110' # 连接本机网关；远程后端改为实际地址
pnpm tauri:dev # 自动启动 3118 前端、编译原生程序并打开桌面窗口
```

需要 Windows 三客户端联调时，在 `frontend/` 中执行以下命令，分别登录不同测试账号：

```powershell
pnpm dev:multi --server-url http://127.0.0.1:39110 # 启动或复用三个独立登录窗口
pnpm dev:multi:status # 查看客户端和共用前端服务状态
pnpm dev:multi:stop # 结束联调时停止脚本管理的客户端与服务，保留登录数据
```

单开和三开按实际需要选择。后端地址在 Rust 编译时写入，改变地址后需重新运行开发命令完成编译；

## 4. 启动 Android 客户端（可选）

另开终端，从仓库根目录执行：

```powershell
cd mobile # 进入 Flutter 客户端目录
flutter doctor # 检查 Flutter 与 Android 工具链
$env:PUB_HOSTED_URL = 'https://pub.flutter-io.cn' # 国内镜像 （可选）
$env:FLUTTER_STORAGE_BASE_URL= 'https://storage.flutter-io.cn'   # 国内镜像 （可选）
flutter pub get # 安装移动端依赖
dart run tool/init_app_config.dart --env dev --server-url http://10.0.2.2:39110 # 首次生成本地应用配置，不提交 Git
flutter emulators # 查看已创建的模拟器
flutter emulators --launch '<AVD名称>' # 替换为列表中的模拟器名称
flutter devices # 查看运行后的设备 ID
flutter run -d '<设备ID>' --dart-define=APP_ENV=dev --dart-define=OPENMEETING_SERVER_URL=http://10.0.2.2:39110 # Android 模拟器连接本机网关
```

真机通过 USB 连接并授权调试后，先用 `adb devices -l` 确认设备；后端在同一电脑上时可使用反向映射：

```powershell
adb -s '<设备ID>' reverse tcp:39110 tcp:39110 # 把真机回环端口转发到电脑网关
adb -s '<设备ID>' reverse tcp:39120 tcp:39120 # 默认 MinIO 入口；用于完整录音直传和签名下载
flutter run -d '<设备ID>' --dart-define=APP_ENV=dev --dart-define=OPENMEETING_SERVER_URL=http://127.0.0.1:39110 # 启动连接本机后端的真机开发版
```

MinIO 地址需要单独选择：

| 联调方式 | `server/.env.dev` 中的 `OPENMEETING_MINIO_PUBLIC_ENDPOINT` | 设备准备 |
|---|---|---|
| 电脑、模拟器或真机共同联调 | `http://<开发电脑局域网IP>:39120` | 所有设备能访问该地址，防火墙放行 39120；推荐用于跨设备测试 |
| 同一电脑通过 USB / ADB 调试 | `http://localhost:39120`（模板默认值） | 对每台目标设备都执行上面的两条 `adb reverse`；模拟器也可使用此方案 |

仅将业务地址改成 `10.0.2.2` 或映射 39110，不会让默认的 `localhost:39120` 在 Android 上自动可达。修改存储公网地址后，在 `server/` 重新执行本轮使用的 Compose 启动命令，再重新申请上传或下载链接。`OPENMEETING_MINIO_ENDPOINT=http://minio:9000` 是服务端内部地址，保持不变；使用远程 OSS / MinIO 时直接确保设备能访问其实际地址。详细说明见[对象存储](docs/object-storage.md#客户端联调地址)。

替换尖括号占位符并保留引号。后端在其他电脑时使用设备可访问的实际地址；`10.0.2.2` 仅用于 Android 模拟器访问宿主机。Flutter 运行后按 `r` 热重载、`R` 热重启、`q` 退出。

## 5. 常用命令

在 `server/` 目录执行：

| 用途 | 命令 |
|---|---|
| 启动服务 / 应用配置 | `docker compose --env-file .env.dev up -d` |
| 更新代码后重新构建 | `docker compose --env-file .env.dev up -d --build` |
| 查看状态 | `docker compose --env-file .env.dev ps` |
| 查看日志 | `docker compose --env-file .env.dev logs -f` |
| 停止服务 | `docker compose --env-file .env.dev stop` |

更多说明：[服务端说明](server/README.md)、[测试说明](docs/testing/README.md)，接口约定：[server/API.md](server/API.md)。
