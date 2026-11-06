# OpenMeeting · 深应会议

私有化部署的 AI 会议助手。桌面端负责会议 UI、音视频及录音采集；服务端负责鉴权、会议数据、转写和总结；管理端负责用户、模型、配置和版本管理。

由 DeepRespond-AI 维护的开源会议助手，提供桌面、移动客户端和可自部署服务端。平台边界见[支持范围](SUPPORT.md)。

| 使用目标 | 所需配置 |
|---|---|
| 管理端、账号与客户端基础开发 | Docker + 本地生成配置；开发验证码可不接真实短信 |
| 录音转写与总结 | 本地 CPU 模型或云端 ASR，以及实际 LLM 提供方 |
| 完整多人会议、聊天和音视频 | 另需 IM/RTC 平台应用与能力，不包含在普通 Compose 服务中 |
| 构建与发布自己的客户端 | 自有网关、应用标识与签名，见[发布指南](docs/releases.md) |

首次体验按快速启动生成配置；发布见[指南](docs/releases.md)，规格与测量见[部署容量](docs/deployment-capacity.md)，隐私及可选统计见[说明](docs/privacy.md)。

## 从这里开始

新开发者先按[快速启动](quickstart.md)跑通后端与客户端，再沿对应路径阅读。工具链版本与[持续集成](docs/continuous-integration.md#检查范围)保持一致。

| 开发方向 | 阅读顺序 |
|---|---|
| 桌面客户端 | [桌面开发与构建](frontend/README.md) → [API 接入](frontend/API.md) → [桌面测试](frontend/TESTING.md)；Linux 先准备[系统依赖](docs/building_in_linux.md) |
| Flutter 移动端 | [环境与构建](mobile/README.md) → [设备连接与对象存储联调](mobile/DEVICE_DEVELOPMENT.md) → [开发规范](mobile/DEVELOPMENT.md) → [移动测试](mobile/TESTING.md) |
| 后端与管理端 | [服务端指南](server/README.md) → [源码热重载](server/docker_dev.md) / [管理端开发](server/admin-web/README.md) → [API 接入指南](server/API_GUIDE.md) → [测试数据库](docs/testing/README.md#后端测试数据库) |

查目录职责看[项目结构](docs/project-structure.md)，查模块关系看[系统架构](docs/architecture.md)，查实现和验收范围看[功能状态](docs/feature-status.md)。部署人员使用下方离线打包步骤及[服务端运维](server/OPERATIONS.md)，日常源码开发无需先生成部署包。完整入口见[文档导航](docs/README.md)。

## 代码与文档入口

桌面客户端位于 `frontend/`，Flutter 客户端位于 `mobile/`，后端与管理端位于 `server/`。完整目录职责、测试及历史档案位置统一见[项目结构](docs/project-structure.md)。客户端与管理端接口统一维护在 [API 契约](server/API.md)。

## 服务端离线打包与部署

打包为 Linux x86_64 CPU 版，包含 MinIO 共 7 个镜像，服务器无需重新构建。

本机在仓库根目录执行 PowerShell 命令（[打包脚本](scripts/build_scripts/package-server-offline.ps1)）：

```powershell
.\scripts\build_scripts\package-server-offline.ps1 -Build # 构建并打包；已构建好镜像时去掉 -Build
```

部署包和 SHA-256 校验文件输出到 `.artifacts/offline-deploy-<时间>-linux-amd64/`。在 Windows PowerShell 中进入实际输出目录，通过 `scp` 上传到服务器：

```powershell
cd '.artifacts/offline-deploy-<时间>-linux-amd64' # 替换为实际打包目录
scp .\shenying-meeting-linux-amd64.tar.gz .\shenying-meeting-linux-amd64.tar.gz.sha256 root@服务器IP:/root/
```

将 `root`、`服务器IP` 和 `/root/` 替换为实际 SSH 用户、服务器地址和上传目录，按提示输入服务器密码。SSH 端口不是默认的 22 时，将命令开头改为 `scp -P 2222`（2222 替换为实际端口）。校验文件可选，不上传时去掉对应文件参数。

上传完成后登录服务器，在上传目录执行：

```bash
sha256sum -c shenying-meeting-linux-amd64.tar.gz.sha256 # 校验部署包 （可选）
mkdir -p /opt/shenying-meeting # 创建部署目录
tar -xzf shenying-meeting-linux-amd64.tar.gz -C /opt/shenying-meeting # 解压部署包
cd /opt/shenying-meeting # 进入部署目录
docker load -i images.tar # 导入镜像
cp -n .env.example .env # 仅首次部署创建配置，更新时保留已有 .env
vi .env # 填写本服务器的密码、密钥和客户端可访问的 MinIO 地址
```

配置完成后启动（服务器需已安装 Docker 和 Docker Compose v2.20 或以上）：

```bash
docker compose --env-file .env -f docker-compose.offline.json up -d --no-build --pull never # 启动服务
docker compose --env-file .env -f docker-compose.offline.json ps -a # 查看服务状态
```

启动后，在服务器本机检查 39110 端口的网关响应：

```bash
curl --noproxy '*' -fsS --max-time 10 http://127.0.0.1:39110/healthz # 绕过代理，检查本机网关
```

返回 JSON 中包含 `"ok":true` 和 `version` 表示网关正常响应，不代表语音模型和音视频服务均已就绪。本机检查成功后，访问管理端：`http://<服务器IP>:39110/admin/`，放行 TCP 39110，或通过宝塔反代到同机 `http://127.0.0.1:39110`。若本机正常而外网无法访问，检查服务器防火墙、云安全组和反代配置。

包内不含本机数据库、录音和模型数据，迁移与备份见[运维指南](server/OPERATIONS.md)；环境配置见[服务端指南](server/README.md)。

## 开发约定

- 新功能接口先写入 `server/API.md`，再实现服务端 → 客户端调用层（桌面 Rust：`frontend/src-tauri/src/server/`；移动端：`mobile/lib/`）→ 页面。
- 语音转写和大模型总结在服务端执行，会议业务数据以服务端为准；客户端保留必要的登录配置、本地录音及 SDK 缓存，不新增本地会议业务数据库或 STT/LLM 推理。
- Fork 仓库后，从 `develop` 创建功能分支并向 `develop` 提交 PR；`main` 用于经过验收的发布，具体流程见[开发协作](CONTRIBUTING.md)。
- 数据库模型和对应迁移脚本一并提交；开发、测试使用独立数据库。详细要求见[开发协作](CONTRIBUTING.md)。

## 常见问题

- **提示“服务器语音识别模型未就绪”**：在管理端“语音模型”检查下载和加载状态，下载所需模型后“设为当前”，等待加载成功；使用云端 ASR 时检查云端配置。
- **提示“服务器尚未配置可用的大模型”**：在管理端“大模型”添加提供方，测试连接并“设为当前”。
- **客户端要求重新登录**：会话过期、退出登录或被管理员强制下线后，使用手机号加密码或短信验证码重新登录。提示“该账号已被禁用”时，由管理员在“用户管理”中启用该用户。
- **收不到验证码**：在管理端“短信与注册”页面的“短信发送记录”查看签名、模板、余额及运营商流控等失败原因，并使用同页的“发送测试短信”排查。若为 `ProxyError`，检查网关出站白名单及 DNS，详见[出站配置](docs/unified-egress.md)。
- **模型下载很慢或失败**：Hugging Face 下载可通过 `server/.env` 的 `HF_ENDPOINT` 配置镜像，例如 `https://hf-mirror.com`；重新应用容器配置，并放行实际镜像及重定向 CDN 域名。也可选择 ModelScope 来源的 FunASR 模型或云端 ASR，配置见[服务端指南](server/README.md)。
- **需要备份哪些数据**：三个 PostgreSQL 数据库、`audio` / `user_data` / `appdata` 数据卷、实际 `.env` 中的 `OPENMEETING_SECRET_KEY` 及已有的 `secret_key` 文件；使用 OSS 时还需备份对象。共享密钥丢失会导致已保存的供应商凭据无法解密。模型可重新下载，按恢复时间要求选择是否备份；具体步骤见[运维指南](server/OPERATIONS.md#备份范围)。

## 按任务阅读

完整入口见[文档导航](docs/README.md)。首次启动按[快速启动](quickstart.md)执行；日常桌面开发与正式发包分别见[桌面 dev / prod 指南](frontend/README.md)，Flutter 见[移动端指南](mobile/README.md)。

服务端部署与环境变量维护在[服务端指南](server/README.md)，源码自动重载见[后端开发](server/docker_dev.md)。当前 HTTP、事件和 Tauri 命令以[API 契约](server/API.md)为准，首次接入先看[中文指南](server/API_GUIDE.md)。

开发协作见[CONTRIBUTING.md](CONTRIBUTING.md)。本地依赖、模型、构建产物、工作树和调试数据不入库。历史阶段通过数不代表当前所有功能已验收，实际边界看[功能状态](docs/feature-status.md)。
