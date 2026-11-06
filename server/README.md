# 深应会议 服务端

后端外部请求也统一经过 gateway_ms 的内部认证代理 39111：IM、短信、OSS、LLM、云 ASR 和模型下载均已接入。各业务服务与自有数据库处于独立内部网络，仅网关连接 edge。部署前须配置供应商域名白名单并重建镜像；见[统一出入网关](../docs/unified-egress.md)。

深应会议的 C/S 架构服务端采用 Python FastAPI 微服务，业务 API 统一由网关对外提供，接口契约见 [API.md](API.md)。客户端另外直连 IM/RTC 平台及后端签发的对象存储上传、下载地址：

| 服务 | 端口 | 数据库 | 职责 |
|---|---|---|---|
| `gateway_ms` | 39110（唯一对外） | openmeeting_user（只读会话校验） | 统一入口：客户端会话认证（`ms_` token）、管理端 JWT 验签、身份注入、路径转发、托管 `/admin` 管理端 SPA |
| `user_ms` | 39113 | openmeeting_user | 用户域：手机号注册/登录、会话签发与吊销、短信验证码、客户端在线注册表、版本发布（`users`、`sessions`、`sms_*`、`client_releases`、`system_settings`(SMS)） |
| `meeting_ms` | 39107 | openmeeting_meeting | 会议域：会议/转写/总结/笔记/录音、后台任务、大模型配置（`meetings`、`transcripts`、`summary_*`、`jobs`、`llm_providers`、`system_settings`(OSS/LLM)） |
| `stt_ms` | 39109 | openmeeting_stt | 转写推理域：faster-whisper / FunASR / 云端 ASR，模型下载与热切换（唯一含 torch 重依赖的镜像） |

所有服务间 HTTP 也经 gateway_ms：meeting_ms → gateway_ms → stt_ms（转写推理、模型状态），meeting_ms/user_ms → gateway_ms → 目标服务（在线连接、用户名、用户数据删除、OSS、IM 和 RTC）。网关内部入口使用必填的 `X-Internal-Token`，不接受用户会话代替。
各服务目录下有独立 README 说明其 internal API 契约。

当前支持的功能和验收边界见[功能状态](../docs/feature-status.md)，服务之间的调用关系见[系统架构](../docs/architecture.md)。

首次接入先看 [API 中文接入指南](API_GUIDE.md)：包含 PowerShell / cURL 示例、参数与返回值说明、搜索合并规则、会议与异步任务调用顺序、错误排查。完整 HTTP、管理端、事件和 Tauri 命令契约见 [API.md](API.md)。

日常修改 Python 代码时可启用源码挂载及自动重载；开发命令、依赖更新、迁移和重启选择统一见[后端日常开发指南](docker_dev.md)。本页维护常规部署及服务配置。

会议录音、会中 PCM 分片和版本安装包可使用 Docker MinIO 或阿里云 OSS；会中分片仅使用对象存储，数据库只保存索引，录音、转写及总结全部成功后默认保留源分片 3 天再清理。启动、客户端下载地址、已有文件读取和备份边界见[对象存储指南](../docs/object-storage.md)。

上线后的数据库与文件备份、隔离恢复、巡检、发布回退及故障定位见[运维指南](OPERATIONS.md)。

---

## 一、部署

### 1. Docker（推荐）

```bash
cd server
cp .env.example .env          # 仅首次复制；设置管理员密码、共享密钥、内部令牌及数据库密码
docker compose up -d --build  # 3 个独立 PostgreSQL 容器 + 4 个应用服务
# 浏览器访问 http://<服务器>:39110/admin

```

NVIDIA GPU 的宿主机要求及启动命令统一见[GPU 部署](../docs/GPU_ACCELERATION.md)。

- 各业务服务启动时自动执行自己的数据库迁移（Alembic，库相互独立）；也可用 `docker compose --profile migrate run <ms>-migrate` 手动执行。
- 设备自动检测：检测到 CUDA 时 faster-whisper 使用 `float16`、FunASR 使用 `cuda:0`，否则 CPU（faster-whisper 使用 `int8`）。
- 数据卷：`user_pgdata` / `meeting_pgdata` / `stt_pgdata`（各自独立数据库）、`models`（STT 模型，stt_ms）、`audio`（会议录音，meeting_ms）、`user_data` / `appdata`（`secret_key` 等）。
- `gateway_ms` 镜像构建时会顺带构建 `admin-web/` 管理端前端并由网关托管。
- 数据库与文件需配套备份，操作步骤见[运维指南](OPERATIONS.md#创建一组一致的备份)。

### 2. 裸机（uv，本地开发）

需要 Python ≥ 3.11、三个独立 PostgreSQL 容器、ffmpeg（音频解码）。数据库实例与连接方式见[数据库隔离说明](../docs/database-isolation.md)。

```bash
cd server
uv sync --locked                          # 安装四个服务的核心依赖和开发工具，不含本地转写引擎
```

只修改业务 API 或使用 OpenAI 兼容云 ASR 时，核心依赖即可。需要其他引擎时，在同一个 `server/` 虚拟环境选择锁定的 extra：

| 能力 | 安装命令 |
|---|---|
| CPU：Whisper / FunASR / Silero VAD | `uv sync --locked --extra stt-cpu` |
| NVIDIA CUDA 12.4：上述本地引擎 | `uv sync --locked --extra stt-cuda` |
| DashScope 云 ASR | `uv sync --locked --extra stt-cloud` |

CPU/CUDA extras 互斥，Torch 与 torchaudio 的版本和来源已配套锁定；GPU 宿主机准备见[服务端 GPU 编排](../docs/GPU_ACCELERATION.md)。同步后，下面的 STT 启动命令使用 `--no-sync` 保留所选 extra；之后重新同步环境时也须带上同一 extra。

准备好各自数据库后，在不同终端启动服务；以下仍为 Bash：

```bash
export OPENMEETING_ADMIN_PASSWORD=change-me
export OPENMEETING_SECRET_KEY=replace-with-a-persistent-shared-random-secret
export OPENMEETING_INTERNAL_SERVICE_TOKEN=dev-token
# 分别启动（各终端设置上述相同变量），或在 IDE 中分别运行：

OPENMEETING_DATABASE_URL=postgresql+asyncpg://openmeeting:openmeeting@localhost:55451/openmeeting_user uv run uvicorn user_ms.main:app --port 39113
OPENMEETING_DATABASE_URL=postgresql+asyncpg://openmeeting:openmeeting@localhost:55453/openmeeting_stt uv run --no-sync uvicorn stt_ms.main:app --port 39109
OPENMEETING_DATABASE_URL=postgresql+asyncpg://openmeeting:openmeeting@localhost:55452/openmeeting_meeting uv run uvicorn meeting_ms.main:app --port 39107
OPENMEETING_DATABASE_URL=postgresql+asyncpg://openmeeting:openmeeting@localhost:55451/openmeeting_user uv run uvicorn gateway_ms.main:app --port 39110
```

三个实例分别创建 `openmeeting_user`、`openmeeting_meeting`、`openmeeting_stt`，分别使用独立的数据卷。上例使用本机回环端口 55451/55452/55453；可按[隔离编排说明](../docs/database-isolation.md)发布相应端口，密码按实际配置调整。gateway_ms 使用用户库校验会话。不要给四个服务全局指定同一个数据库 URL。

上述为 Bash 写法；PowerShell 在各服务终端使用 `$env:OPENMEETING_DATABASE_URL = '对应库地址'` 后执行相同 uvicorn 命令。共享密钥、内部令牌和管理员密码须保持一致。

仅网关通过 `OPENMEETING_USER_MS_URL` / `OPENMEETING_MEETING_MS_URL` / `OPENMEETING_STT_MS_URL` 配置目标服务。user_ms 和 meeting_ms 只配置 `OPENMEETING_GATEWAY_MS_URL`（默认 `http://localhost:39110`）。网关需要 `OPENMEETING_SECRET_KEY` 与 `OPENMEETING_ADMIN_PASSWORD` 和 user_ms 一致。

Docker 网关镜像包含管理端；裸机部署和界面开发按[管理端指南](admin-web/README.md)执行构建。

各引擎依赖都是按需导入的：只装核心依赖也能启动 stt_ms，管理端「STT 引擎」处会显示哪些引擎可用。

> 生产环境建议放在 HTTPS 反向代理（Nginx/Caddy）之后，代理目标只暴露网关 39110。管理端 SSE 接口 `/admin/api/events` 需关闭代理缓冲（服务端已返回 `X-Accel-Buffering: no`）。音频和客户端安装包上传可能较大，请调高 `client_max_body_size`（建议 ≥ 500M）。

---

## 二、环境变量

各 ms 只读取与自己相关的变量（前缀均为 `OPENMEETING_`；完整列表见各 `<ms>/.env.example`）。共享的关键变量：

| 变量 | 作用于 | 默认值 | 说明 |
|---|---|---|---|
| `OPENMEETING_ADMIN_PASSWORD` | gateway_ms、user_ms | 无（必填） | 管理端登录密码。修改密码后已有登录会话自动失效 |
| `OPENMEETING_SECRET_KEY` | 全部 | 生产显式配置 | 管理端 JWT 签名 + 数据库中 API Key / 短信与 OSS AccessKey Secret 的加密密钥（Fernet）。**必须全部一致**，否则网关验签失败、跨库密文无法解密 |
| `INTERNAL_SERVICE_TOKEN` → `OPENMEETING_INTERNAL_SERVICE_TOKEN` | 全部 | 无（compose 必填） | 服务间 internal API 的共享令牌（`X-Internal-Token` 头）；网关内部入口在令牌未配置时返回 503；下游空令牌兼容仅限隔离本地测试 |
| `OPENMEETING_DATABASE_URL` | 各 ms 各自配置 | — | 各 ms 连接自己的库（openmeeting_user / openmeeting_meeting / openmeeting_stt） |
| `OPENMEETING_DATA_DIR` | 各 ms 各自配置 | `./data` | stt_ms 存模型、meeting_ms 存录音、user_ms 存安装包；可指向同一根目录 |
| `OPENMEETING_STT_MS_URL` / `OPENMEETING_USER_MS_URL` / `OPENMEETING_MEETING_MS_URL` | gateway_ms | `http://localhost:391xx` | 仅网关持有真实下游地址 |
| `OPENMEETING_GATEWAY_MS_URL` | user_ms / meeting_ms | `http://localhost:39110` | 内部 RPC 网关入口 |
| `USER_POSTGRES_PASSWORD` / `MEETING_POSTGRES_PASSWORD` / `STT_POSTGRES_PASSWORD` | 对应数据库和应用 | 继承 `POSTGRES_PASSWORD` | 三个独立数据库可分别配置密码 |
| `OPENMEETING_SESSION_CACHE_TTL_SEC` | gateway_ms | `30` | 会话认证缓存秒数（吊销/禁用最迟此时生效） |
| `OPENMEETING_STT_CONCURRENCY` | stt_ms | `1` | 同时进行的语音识别推理数 |
| `OPENMEETING_JOB_WORKERS` | meeting_ms | `1` | 导入 / 重转写后台任务的并发数 |
| `OPENMEETING_AUTO_MIGRATE` | 各业务 ms | `true` | 启动时自动执行自己的 `alembic upgrade head` |
| `OPENMEETING_CORS_ORIGINS` | 各 ms | 空（关闭） | 逗号分隔的允许来源；桌面客户端不需要 CORS |
| `OPENMEETING_TRUSTED_PROXIES` | gateway_ms、user_ms、meeting_ms | 空（compose 默认信任 Docker 网段） | 反向代理的 IP/网段。只有直连来源属于这些地址时才信任 `X-Forwarded-For`/`X-Real-IP`；Compose 同时传入 user_ms 的 `FORWARDED_ALLOW_IPS`，使更新接口保留外部 HTTPS 协议 |
| `OPENMEETING_LOG_LEVEL` / `OPENMEETING_ENV` | 各 ms | `INFO` / `production` | `dev` 允许默认管理员密码；未配置短信时验证码返回 `dev_code`（**切勿用于生产**） |
| `OPENMEETING_SMS_*`（见下） | user_ms | 空 | 阿里云短信配置（覆盖管理端保存的值） |
| `OPENMEETING_OSS_*`（见下） | meeting_ms（配置入口）、user_ms（发布包共用） | 空 | 阿里云 OSS 配置（覆盖管理端保存的值） |
| `HF_ENDPOINT` | stt_ms | 空 | HuggingFace 镜像，如 `https://hf-mirror.com` |

---

## 三、首次使用

1. **首次使用入口**：浏览器打开 `http://<服务器>:39110/admin`，输入 `OPENMEETING_ADMIN_PASSWORD`。
2. **准备语音识别模型**：「STT 模型」页面 → 选择模型「下载」（显示进度）→ 下载完成后「设为当前」。
   - 中文会议推荐 `funasr:sensevoice-small` 或 `funasr:paraformer-zh`（ModelScope 下载，国内速度快）；
   - 多语言推荐 `faster-whisper:large-v3-turbo`（GPU）或 `small`（CPU）；
   - 云端识别：在「云端配置」填写模式、地址、模型和 API Key 后，激活 `cloud:default`：
     - `openai` 模式：`POST {base_url}/audio/transcriptions`（multipart WAV），适用于 OpenAI、Groq、硅基流动及各类中转站；
     - `dashscope` 模式：阿里云百炼 Paraformer（需 `cloud` 扩展，模型如 `paraformer-realtime-v2`，`base_url` 可留空，或填写 `wss://dashscope-intl.aliyuncs.com/api-ws/v1/inference` 使用国际站）。
   - 可用「测试」上传一段音频检查识别效果。服务重启后会自动在后台重新加载上次激活的模型。
3. **配置大模型**：「大模型」页面 → 新增：
   - 阿里云百炼：`base_url = https://dashscope.aliyuncs.com/compatible-mode/v1`，模型如 `qwen-plus`；
   - 中转站：填写其 OpenAI 兼容地址（通常以 `/v1` 结尾）与 Key；
   - `context_tokens`（默认 32000）决定长会议的分块总结阈值；
   - 第一个添加的大模型自动设为当前，可「测试连接」、拉取模型列表。
4. **配置短信**：见下文「四、短信配置」。配置完成后用户即可在客户端用手机号自助注册、登录。
5. **用户管理**：「用户」页面可搜索、预建用户（填手机号 + 姓名，用户随后用验证码登录，再自行设置密码）、修改姓名/手机号、禁用（立即使其所有设备下线）、查看登录设备并强制下线、删除用户（连同会议与录音）。

客户端使用手机号登录获取业务会话令牌，网关校验令牌后转发请求。

---

## 四、短信配置（阿里云短信服务）

验证码通过阿里云短信服务 `SendSms` 接口发送（服务端自行实现 RPC 签名，无需额外 SDK）。

1. **开通短信服务**：登录阿里云控制台 → 搜索「短信服务」→ 开通（国内消息）。
2. **申请签名**：「国内消息 → 签名管理」→ 添加签名（如 `深应会议`），等待审核通过。
3. **申请验证码模板**：「国内消息 → 模板管理」→ 添加模板，类型选「验证码」，内容中使用变量 `${code}`，例如：
   `您的验证码为${code}，5分钟内有效，请勿泄露给他人。` 审核通过后记下模板 CODE（`SMS_xxxxxxxx`）。
4. **创建 RAM AccessKey**：「RAM 访问控制 → 用户」→ 创建用户（勾选「OpenAPI 调用访问」）→ 保存 AccessKey ID 与 Secret →
   为该用户「添加权限」`AliyunDysmsFullAccess`。不要使用主账号 AccessKey。
5. **在管理端填写**：「短信与注册」页面填写 AccessKey ID、AccessKey Secret、签名、模板 CODE，模板变量名保持 `code`
   （若模板变量不是 `${code}`，填写对应变量名）→ 保存 → 「发送测试短信」到自己的手机确认。
   AccessKey Secret 加密保存在数据库中，页面只显示「已设置」。也可以用 `OPENMEETING_SMS_*` 环境变量配置（优先级高于管理端）。
6. **注册开关**：同一页面可关闭「开放注册」，关闭后只有管理员预建的用户能登录。

规则：验证码 6 位、5 分钟有效、一次性，同一验证码最多输错 5 次；同一手机号 60 秒内只能发送一次、每天最多 10 次；同一 IP 每小时最多 30 次。
每次发送（含失败原因、不含验证码）记录在「短信记录」中。

> 开发调试：`OPENMEETING_ENV=dev` 且未配置短信时，验证码不会真正发送，而是打印到服务日志并在接口响应中以 `dev_code` 返回。

---

## 五、音频存储（阿里云 OSS）

未配置 OSS 时，会议录音保存在服务器 `$OPENMEETING_DATA_DIR/audio/<用户ID>/<会议ID>/`。配置 OSS 后：

- 客户端上传的完整录音、导入的音频先落到服务器临时目录（用于计算时长），随后上传到 OSS（大文件分片上传，开启服务端加密），**服务器本地不保留**。上传 OSS 失败时接口返回 502，客户端会自动重试。
- 客户端播放录音时，`GET /api/v1/meetings/{id}/audio` 返回 302 跳转到 1 小时有效的签名链接，客户端直接从 OSS 下载到本地录音文件夹，不占用服务器带宽。
- 重新转写时服务器把音频临时下载到 `$OPENMEETING_DATA_DIR/tmp/`，用完即删。删除会议 / 删除用户时同步删除 OSS 中的对象。

配置步骤：

1. OSS 控制台创建 Bucket，读写权限选**私有**。
2. RAM 中创建子账号 AccessKey，仅授予该 Bucket 的读写权限（`oss:PutObject`、`oss:GetObject`、`oss:DeleteObject`、`oss:ListObjects` 及分片上传相关权限）。
3. 管理端「音频存储」页面填写 Endpoint、Bucket、AccessKey ID / Secret（Region 一般可留空自动识别）→ 保存 →「测试连接」。也可以用 `OPENMEETING_OSS_*` 环境变量配置（优先级高于管理端）。

> 停用 OSS（清空 AccessKey Secret）后，新录音回到本地存储，但已在 OSS 中的录音无法播放或重新转写，直到重新配置。

---

## 六、用户登录流程

客户端使用手机号及密码或短信验证码登录。注册、重置密码、会话失效和账号资料接口见 [API 鉴权契约](API.md#client-auth)，实际登录和后续调用示例见[中文接入指南](API_GUIDE.md#quick-start)。桌面与移动端构建时指定网关地址，不能在登录页面修改。

---

## 七、客户端升级（版本发布）

在管理端「版本发布」页面按平台（Windows / macOS / Linux / Android / iOS）发布新版本。客户端启动时和使用中定期检查更新（`/api/v1/updates/*`，未登录也能检查）。

1. **升级策略**（每个平台）：
   - **最低支持版本**：低于它的客户端必须升级才能继续使用（不受灰度限制），留空不限制。
   - **iOS**：填写 App Store 链接（iOS 只能跳转 App Store 更新）。
   - **Android 商店渠道**：为各商店渠道（`huawei`、`xiaomi`……，与打包时的 `APP_CHANNEL` 一致）填写商店链接；`direct` 渠道包直接下载 APK 安装。
2. **新建版本**（草稿）：填写版本号（桌面端与 `tauri.conf.json` 的 `version` 一致；APP 与 `pubspec.yaml` 的 `version` 一致，构建号单独填写）、更新说明、是否强制、灰度比例与白名单用户。
3. **上传安装包**：
   - 桌面端上传 Tauri 更新包和同名 `.sig` 签名文件：macOS `*.app.tar.gz`（按 ARM64 / x86_64，或通用包），Windows `*-setup.exe`，Linux `*.AppImage`。打包时必须设置 `TAURI_SIGNING_PRIVATE_KEY`（见 `frontend` 的打包说明），否则客户端无法校验更新包。
   - Android 上传正式证书签名的 release APK；iOS 无需上传。
   - 已配置 OSS 时安装包存入 OSS（`releases/…`），下载走签名链接；否则存放在 `$OPENMEETING_DATA_DIR/releases/`。
4. **发布与灰度**：先只加白名单用户验证，再把比例从 5% 逐步调到 100%（按设备稳定抽样，调高比例不会让已收到的设备丢失更新）；发现问题点「暂停」立即停止推送。
5. **强制升级**：勾选版本的「强制」，或调高「最低支持版本」。
6. 页面右侧显示近 30 天活跃客户端的版本分布（客户端心跳会更新会话里的版本号）。

---

## 八、开发与测试

- Python 源码重载、依赖更新及 Alembic 结构开发见[Docker 开发指南](docker_dev.md)。
- 测试数据库和执行方法见[测试入口](../docs/testing/README.md#后端测试数据库)，不要将测试连接指向业务库。
- 代码职责和目录定位见[项目结构](../docs/project-structure.md)，各服务 README 维护服务特有约束。
- 导入、分段转写及后台任务的调用与状态见[API 接入指南](API_GUIDE.md#async-processing)。模型下载与预处理实现见 [stt_ms](stt_ms/README.md)，录音、任务及总结实现见 [meeting_ms](meeting_ms/README.md)。


## 锁定依赖与运行时选择

开发、CI 和生产镜像以 `pyproject.toml` / `uv.lock` 为唯一解析来源。核心服务使用 `uv sync --locked --no-dev --no-install-project`；本地 CPU 使用 `--extra stt-cpu`，CUDA 12.4 使用互斥的 `--extra stt-cuda`，轻量云端使用 `--extra stt-cloud`。单服务 requirements.txt 引用从同一锁文件导出的 requirements.lock，兼容按文件安装；镜像直接使用 uv.lock；修改依赖后同步 `uv lock`、相关测试与部署 E2E。

`OPENMEETING_STT_RUNTIME` 控制 CPU Dockerfile 的构建 extra，模板默认 `stt-cpu`；开发初始化选择 `stt-cloud`，生产选择 `stt-cpu`。CUDA 使用单独覆盖文件。规格与测量见[部署容量](../docs/deployment-capacity.md)。
