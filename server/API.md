# 深应会议 API 契约

本文是服务端、管理端、桌面端和 Flutter 移动端共用的接口契约。接口字段或行为变更需要同步实现与调用方。
首次接入请先阅读 **[中文接入指南](API_GUIDE.md)**，其中包含登录请求、字段解释、搜索规则、会议调用顺序和错误排查；本文保留完整接口、事件与命令索引。

表格里的 `{phone, code}`、`str|null`、`字段?` 是**结构简写**：分别表示对象字段、可空类型、可省略字段，并非可直接发送的 JSON。可执行请求和合法 JSON 示例见接入指南。服务端返回结构没有统一的 `{code: 0, data: ...}` 包装。

本文说明统一使用中文；接口路径、字段名、命令名、错误码、枚举值及代码示例保留实现中的名称。类型简写中，`str` / `string` 表示字符串，`bool` 表示布尔值，`int` 表示整数，`i64` / `u64` 分别表示有符号 / 无符号 64 位整数，`f32` / `f64` 表示浮点数，`null` 表示空值。

### 阅读导航

| 要接入的功能 | 契约入口 | 关键说明 |
|---|---|---|
| 注册、登录、账号资料 | [§1.0](#client-auth) | 公开接口与 Bearer 接口分别标注 |
| 心跳、服务能力 | [§1.1](#client-connection) | STT / LLM 未就绪与登录状态分别处理 |
| 单人录音实时转写 | [§1.2](#client-transcription) | PCM16 原始字节，不是音频文件上传 |
| 历史会议、转写与搜索 | [§1.3](#client-records) | 搜索返回转写片段命中，标题匹配由客户端合并 |
| 音频、导入与重转写 | [§1.4](#client-audio)、[§1.5](#client-jobs) | 音频可能 302 跳转，任务受理不等于完成 |
| 总结、笔记 | [§1.6](#client-summary)、[§1.7](#client-notes) | 总结异步生成；格式与编辑字段依契约处理 |
| 客户端更新 | [§1.8](#client-updates) | 登录前也能检查 |
| 预定会议、会中操作 | [§1.9](#client-schedules)、[§1.10](#client-rooms) | 预定、活动场次、会后记录的 ID 不同 |
| IM / RTC 凭证 | [§1.11](#client-im)、[§1.10](#client-rooms) | 业务会话、IM 登录凭证、RTC 媒体凭证不可混用 |
| 自动录音与会后共享读取 | [共享契约](meeting_ms/api/shared-records-contract.md)、[录制补充](#recording-addendum) | 实际参会者可读，写权限仍受所属账号约束 |
| 管理后台 | [§2](#admin-api) | 管理员 cookie / JWT |
| Next.js 调用原生能力 | [§3](#tauri-api) | Tauri IPC 命令，不是 HTTP 路径；Flutter 调用 HTTP / SDK |
| 微服务内部调用 | [内部网关](#internal-gateway) | 仅后端使用 |

> 对外入口为 gateway_ms（默认 39110），内部使用 user_ms、meeting_ms 和 stt_ms。
> 客户端和管理端统一访问网关；当前支持、兼容和退役行为以各分节说明为准，部署方式见 [README](README.md)。
> 内部路由归属：`/api/v1/{auth,updates,im,client/heartbeat}` 与 `/admin/api/{login,logout,me,users,auth-settings,sms-logs,releases}` → user_ms；
> `/api/v1/{meetings,transcripts,scheduled-meetings,rooms,transcribe,audio,jobs,summaries,client/capabilities}` 与 `/admin/api/{dashboard,connections,events,stats,llm,summary-templates,object-storage,storage,jobs,meetings}` → meeting_ms；
> `/admin/api/stt/*` → stt_ms。`GET(WS) /api/v1/rooms/{id}/ws` 由网关 WebSocket 代理转发到 meeting_ms。

### 通用约定

- **服务地址**只配置网关源地址（协议、主机和端口），例如 `https://openmeeting.example.com`；表格路径已经包含 `/api/v1` 或 `/admin/api`，避免重复拼接。客户端通过构建配置确定地址，用户界面不提供修改入口。
- **字段名严格区分大小写**，历史接口包含下划线命名（snake_case）和小驼峰命名（camelCase），不做全局自动转换。时间通常为 UTC ISO-8601；音频的 `start` / `end` / `duration` 单位是秒，`durationMin` 单位是分钟。
- **返回值按 HTTP 状态解析**：200 / 201 返回表格定义的数据；202 表示后台已受理；204 没有 JSON 正文。列表无匹配通常是 200 + `[]`，不是 404。
- **错误有多种结构**：普通业务错误为 `{"detail":"可读说明"}`；会议错误可额外带 `code`；框架校验的 422 中 `detail` 可能是数组。含义与恢复方式见[错误处理](API_GUIDE.md#errors)。
- **身份按接口区分**：客户端 Bearer 会话、管理员 JWT / cookie、内部 `X-Internal-Token` 分别使用，不能互相替代，也不能代替 IM / RTC 凭证。
- **ID 按资源区分**：记录 `meeting-<uuid4>`、房间 `room-<uuid4>`、预定 `sched-<uuid4>`、转写片段 UUID、任务 `job-<uuid4>`；会议号 `code` 是字符串，不是上述任何 ID。
- **更新语义逐接口约定**：省略字段和显式 `null` 不保证等价；例如房间 PATCH 为局部更新，而预定 PATCH 使用完整创建结构。

<a id="internal-gateway"></a>

<a id="service-to-service-gateway-contract"></a>

### 微服务间网关调用契约

业务服务通过 `OPENMEETING_GATEWAY_MS_URL` 调用网关，默认值为 `http://localhost:39110`。只有 gateway_ms 配置直连下游的 `OPENMEETING_USER_MS_URL`、`OPENMEETING_MEETING_MS_URL` 和 `OPENMEETING_STT_MS_URL`。既有对外 API 和下游内部接口的路径与请求、响应结构保持不变。

- `GET|POST|PUT|PATCH|DELETE /internal/{service}/{path}` 映射到指定下游的 `/internal/{path}`；`service` 可取 `user`、`meeting` 或 `stt`。
- 必须提供 `X-Internal-Token`；缺少或错误时返回 401。网关未配置内部令牌时返回 503，开发环境也不例外。客户端会话和管理员 cookie 均不能用于访问内部接口。
- 网关移除调用方身份头、`Authorization` 和 `Cookie`，再注入配置的内部令牌。既有流式代理转发查询参数（包括重复参数）、原始正文、上游状态码和响应头。
- 目标未知或路径不安全时返回 404；连接失败返回 502 `上游服务不可用`。不会自动重试写操作，也不会回退为直连业务服务。
- `/im/callback` 经网关进入；user_ms 校验内部令牌，SDK 校验平台签名。未携带配置的内部令牌而直接调用用户服务回调时返回 401。
- 删除用户的会议数据失败时，`DELETE /admin/api/users/{id}` 返回 502 `会议服务暂不可用，用户未删除，请稍后重试`，保留用户以便重试。

PostgreSQL 使用三个独立容器和数据卷部署，实例与连接归属见[数据库说明](../docs/database-isolation.md)，备份和恢复见[运维指南](OPERATIONS.md)。

后端出站请求：业务服务使用 gateway_ms 在内部端口 39111 提供的鉴权 HTTP 正向代理（`OPENMEETING_EGRESS_PROXY_URL`）。该代理与 API 路由独立，不提供对外业务路径。代理使用 Basic 鉴权，用户名为 `openmeeting`、密码为共享内部令牌；第三方平台凭证另外保留。CONNECT 隧道保留端到端 TLS/WSS 校验和 SDK URL 签名。建隧道前的错误：407 表示代理凭证无效；403 表示主机、端口或地址被拒绝；502 表示上游不可用；503 表示连接容量已满。失败时不会回退为直连。Compose 中的业务服务使用独立内部网络和数据库，仅网关连接外部网络。部署白名单和 SDK 覆盖范围见[统一出站代理说明](../docs/unified-egress.md)。客户端、管理端的接口结构及原生命令不变。

---

<a id="1-client-api--apiv1-header-authorization-bearer-session_token"></a>

## 1. 客户端 API — `/api/v1`（请求头 `Authorization: Bearer <session_token>`）

会话确定当前用户身份。会议记录读取范围为所属账号和持久化的实际参会账号，包含提前离会成员；只进入等候室而未实际入会的账号不获得记录权限。修改、删除、上传与重处理仍校验记录所属账号。列表和元数据接口的 `can_manage` 表示此写权限，不代表能否读取。详见[共享读取契约](meeting_ms/api/shared-records-contract.md)。
会话令牌通过手机号认证获取（§1.0）；不再使用管理员签发的 API 令牌。

<a id="client-auth"></a>

<a id="10-phone-authentication-and-profile"></a>

### 1.0 手机号认证与账号资料

账号使用手机号。注册时必须同时提供短信验证码和密码，登录时可选择短信验证码或密码。

| 方法 | 路径 | 鉴权 | 请求体 | 响应 |
|---|---|---|---|---|
| GET | `/api/v1/auth/config` | 公开 | – | `{"registration_open": bool, "sms_ready": bool, "code_length": 6, "resend_interval_sec": 60, "password_min_length": 8, "password_max_length": 64, "server_version": str}` |
| POST | `/api/v1/auth/sms/send` | 公开 | `{"phone": str, "purpose": "register"\|"login"\|"reset_password"}` | `{"sent": true, "resend_after_sec": 60, "expires_in_sec": 300}` |
| POST | `/api/v1/auth/register` | 公开 | `{"phone", "code", "name", "password", "client"?: ClientInfo}` | `AuthResult` (201) |
| POST | `/api/v1/auth/login` | 公开 | `{"phone", "code"\|"password", "client"?: ClientInfo}`；`code`（短信登录）与 `password` 必须且只能提供一个 | `AuthResult` |
| POST | `/api/v1/auth/password/reset` | 公开 | `{"phone", "code", "password", "client"?: ClientInfo}`；验证码用途须为 `reset_password` | `AuthResult`（设置密码、撤销其他所有会话并登录） |
| POST | `/api/v1/auth/logout` | Bearer | – | 204（撤销当前会话） |
| GET | `/api/v1/auth/me` | Bearer | – | `User` |
| PATCH | `/api/v1/auth/me` | Bearer | `{"name": str}` | `User` |
| PUT | `/api/v1/auth/me/password` | Bearer | `{"old_password"?: str, "password": str}` | `User`；首次设置密码时（`has_password=false`）无需 `old_password`，修改已有密码时必须提供；撤销该用户的其他会话 |

- `phone`：中国大陆 11 位手机号，满足 `^1[3-9]\d{9}$`。服务端移除开头的 `+86` / `86`、空格和连字符，以规范化后的 11 位号码存储。
- `ClientInfo`: `{"client_id": str, "hostname": str, "os": str, "app_version": str}`.
- `User`：`{"id", "phone", "name", "created_at", "last_login_at", "has_password": bool}`。密码功能上线前创建的用户，其 `has_password` 为 `false`；可先短信登录，再通过 `PUT /auth/me/password` 或重置流程设置密码。
- 密码：8–64 个字符，必须包含字母和数字，不能有首尾空格，否则返回 422 并说明原因。仅存储加盐的 scrypt 哈希。
- 密码登录错误：尚未设置密码 → 400「该账号尚未设置密码…」；密码错误 → **400**「手机号或密码错误，还可尝试 N 次」；连续失败 5 次后锁定密码登录 15 分钟 → **429**。锁定期间仍可短信登录或重置密码；密码登录成功或重置后清零计数。修改密码时 `old_password` 错误也计入同一锁定计数（「原密码错误…」）。
- `AuthResult`：`{"token": str, "expires_at": str, "user": User, "im_ticket": {"ticket": str, "expires_in": int, "user_created": bool} | null}`。令牌格式为 `ms_` 加 43 个 URL 安全字符，服务端只存储其 SHA-256 哈希。`im_ticket` 是 IM 登录凭证（5 分钟有效、一次性，首次签发自动创建 IM 账号）；IM 未开启或签发失败时为 `null`，过期或重连后经 `POST /api/v1/im/ticket` 重新获取。
- 验证码：6 位数字，有效期 5 分钟，仅可使用一次；每个验证码最多允许输错 5 次，之后失效。用途必须匹配。
- 频率限制：同一手机号两次发送至少间隔 60 秒，每天最多 10 次；每个 IP 每小时最多 30 次。超限返回 429，`detail` 为中文说明。
- 已注册手机号以 `purpose=register` 调用 `sms/send` → 409「该手机号已注册，请直接登录」；未注册手机号使用 `purpose=login` / `reset_password` → 404「该手机号未注册」；用户被禁用 → 403；`registration_open=false` 时注册 → 403。
- `register` 创建用户并登录；已禁用用户调用 `login` 返回 403。
- 错误状态汇总：验证码错误、过期或次数耗尽 → **400**，`detail` 说明剩余次数；不会返回客户端会视为会话失效的 401。手机号、用途、空姓名等校验失败 → 422；本服务限流或阿里云 `isv.BUSINESS_LIMIT_CONTROL` / `DAY_LIMIT_CONTROL` → 429；阿里云发送失败 → 502；生产环境未配置短信 → 503。发送失败会记录日志，不留下可用验证码。
- 可以获取验证码时（含开发模式），`auth/config.sms_ready` 为 `true`；管理端 `/auth-settings.sms_ready` 只反映真实短信配置是否就绪。
- IP 限流使用 TCP 对端地址；仅信任来自 `OPENMEETING_TRUSTED_PROXIES` 的 `X-Forwarded-For` / `X-Real-IP`。
- 会话采用滑动过期：30 天内持续使用即有效。每次鉴权请求将 `expires_at` 延长至当前时间后 30 天，实际写入最多每小时一次。过期或已撤销时返回 401。
- 短信通过阿里云短信服务 `SendSms` 发送（dysmsapi、RPC 签名 v1、`https://dysmsapi.aliyuncs.com`），使用配置的 `SignName` / `TemplateCode` 和 `TemplateParam={"<param>": code}`。开发模式（`OPENMEETING_ENV=dev`）未配置短信时，验证码会写入日志，并通过发送响应的 `dev_code` 返回；生产环境不会返回该字段。

<a id="client-connection"></a>

<a id="11-connection"></a>

### 1.1 连接与服务能力

| 方法 | 路径 | 请求体 | 响应 |
|---|---|---|---|
| POST | `/api/v1/client/heartbeat` | `{"client_id": str, "hostname": str, "os": str, "app_version": str, "recording": bool, "meeting_id": str\|null}` | `{"server_time": str, "server_version": str}` |
| GET | `/api/v1/client/capabilities` | – | `Capabilities` |

`Capabilities`:
```json
{
  "server_version": "1.0.0",
  "user": {"id": "…", "name": "张三", "phone": "13800138000"},
  "stt": {"engine": "faster-whisper|funasr|cloud", "model": "large-v3", "ready": true, "error": null},
  "llm": {"name": "百炼", "model": "qwen-plus", "ready": true, "error": null}
}
```
未配置相关服务时，`stt` / `llm` 的 `engine`、`model`、`name` 可能为 `null`，且 `ready=false`。
心跳发现 `app_version` / `os` 变化时，还会将新值存入当前会话，供管理端统计版本分布。

<a id="client-transcription"></a>

<a id="12-live-transcription"></a>

### 1.2 实时语音转写

名称字段限制：会议标题最多 **50 个 Unicode 码点**，账号昵称最多 **32 个 Unicode 码点**，入会显示昵称沿用 **20 个 Unicode 码点**。中文、英文和单码点 emoji 均计为 1；组合 emoji 按组成码点计数。桌面端、移动端显示实时计数并限制输入，服务端通过 Pydantic 再次校验，超长返回 HTTP 422。入会默认显示名取账号昵称前 20 个码点，完整账号昵称不变。读取已有记录不截断历史长标题或昵称；修改时须符合新限制。仅调整接口校验，无需数据库迁移。

`POST /api/v1/meetings` 的标题先去除首尾空白，空标题沿用「新会议」默认值；`PATCH /api/v1/meetings/{id}` 重命名时标题去除首尾空白后须为 1–50 字；`POST /api/v1/jobs/import` 的表单 `title` 同样最多 50 字，空白标题使用「导入的会议」。注册、资料修改及管理端用户创建/修改的昵称去除首尾空白后须为 1–32 字。客户端从音频文件名生成的默认标题取前 50 个码点，原文件名不变。

| 方法 | 路径 | 请求体 | 响应 |
|---|---|---|---|
| POST | `/api/v1/meetings` | `{"title": str}` | `MeetingMetadata` (201) |
| POST | `/api/v1/meetings/{id}/segments?seq=<u64>&start=<f64 sec>&end=<f64 sec>&language=<str?>` | 原始字节正文，`Content-Type: application/octet-stream`；**16 kHz、单声道、小端序 PCM16** | `SegmentResult` |

`SegmentResult`: `{"id": str|null, "text": str, "confidence": f32|null, "seq": u64}`
- 服务端使用当前启用的语音转写（STT）引擎。`text` 非空时插入转写记录并返回 `id`：`audio_start_time=start`，`audio_end_time=max(end,start)`，`duration` 为两者之差；`timestamp` 为服务端当前时间的 UTC ISO-8601 字符串。文本为空时返回 `id: null`，不写入记录。
- 以 `(meeting_id, seq)` 保证幂等；重试相同 `seq` 会返回已保存的结果，不重复插入。
- 省略 `language` 或传 `auto` 时自动检测语言。
- 没有就绪的 STT 模型时返回 503。

<a id="client-records"></a>

<a id="13-meetings--transcripts-shapes-mirror-the-existing-rust-structs-in-frontendsrc-taurisrcapiapirs"></a>

### 1.3 会议记录与转写

数据结构与 `frontend/src-tauri/src/api/api.rs` 中的既有 Rust 结构体对应。

| 方法 | 路径 | 请求体 / 查询参数 | 响应 |
|---|---|---|---|
| GET | `/api/v1/meetings` | – | `[{"id","title","created_at","updated_at","can_manage"}]`；仅返回可见记录，按创建时间倒序，不接受分页参数 |
| GET | `/api/v1/meetings/{id}` | – | `MeetingDetails` `{"id","title","created_at","updated_at","transcripts":[MeetingTranscript]}` |
| GET | `/api/v1/meetings/{id}/metadata` | – | `MeetingMetadata` `{"id","title","created_at","updated_at","folder_path":null,"has_audio":bool,"audio_duration":f64\|null,"can_manage":bool}` |
| GET | `/api/v1/meetings/{id}/transcripts?limit=&offset=` | – | `{"transcripts":[MeetingTranscript],"total_count":i64,"has_more":bool}`；先按 `audio_start_time`，再按 `timestamp` 排序 |
| PATCH | `/api/v1/meetings/{id}` | `{"title": str}` | `MeetingMetadata` |
| DELETE | `/api/v1/meetings/{id}` | – | 204（同时删除音频文件、转写、总结和笔记） |
| POST | `/api/v1/meetings/{id}/transcripts` | `{"transcripts":[TranscriptSegment]}` | `{"inserted": int}`；批量插入，跳过已存在的 ID |
| GET | `/api/v1/transcripts/search?q=` | – | `[{"id","title","matchContext","timestamp"}]` |

`MeetingTranscript`：`{"id","text","timestamp","audio_start_time"?,"audio_end_time"?,"duration"?,"speaker"?,"confidence"?}`。批量插入使用 `TranscriptSegment`，接受 `id`、`text` 以及可选的 `timestamp`、`audio_start_time`、`audio_end_time`、`duration`；不提供 `speaker` 或 `confidence` 输入字段。

- 转写分页：`limit` 默认 100，范围 1–10000；`offset` 默认 0，必须非负。通过 `has_more` / `total_count` 判断后续页；`GET /meetings` 和全局搜索不使用这套分页参数。
- 搜索参数 `q` 默认为空；空字符串或纯空白返回 200 + `[]`。非空输入对转写文本做不区分大小写的字面子串匹配，`%` 和 `_` 不作为通配符。客户端应在请求前去除首尾空白；否则服务端按原文搜索，包括其中的空格。
- 搜索最多返回 500 条**转写命中**，先按会议创建时间倒序，再按转写顺序排列。多条结果的 `id` 可能相同，它表示**会议 ID**，不是转写 ID。结果没有 `has_more` 字段，`matchContext` 是命中位置附近的文本片段。
- 全局搜索不搜索标题。桌面端和移动端的历史记录界面应合并本地标题子串匹配与接口返回的会议 ID，按原列表顺序去重并保留命中片段。见[字段说明与示例](API_GUIDE.md#history-search)。

<a id="client-audio"></a>

<a id="14-audio"></a>

### 1.4 音频上传与下载

| 方法 | 路径 | 请求体 | 响应 |
|---|---|---|---|
| PUT | `/api/v1/meetings/{id}/audio?filename=audio.mp4` | 原始流式正文，支持任意音频容器格式；`Content-Type` 使用文件类型 | `{"size": int, "duration": f64\|null}`；可用时由 ffprobe 获取时长。已配置 OSS 但上传失败时返回 502，可重试 |
| GET | `/api/v1/meetings/{id}/audio` | 支持 `Range` 请求头 | 音频字节，无音频时返回 404。音频存于 OSS 时，**302** 跳转到有效期 1 小时的签名 URL，该 URL 也支持 `Range`；若已存入 OSS 但 OSS 配置被移除，返回 503。客户端需跟随跳转，但不得向 OSS 主机发送 `Authorization` |

存储位置由 `OPENMEETING_STORAGE_PROVIDER=auto|local|minio|oss` 决定：`auto` 兼容旧行为（OSS 完整则使用，否则本地）；`local` 强制本地；`minio` 使用 `OPENMEETING_MINIO_*`；`oss` 使用原有 `OPENMEETING_OSS_*` / 管理端配置。显式选择对象存储但配置不完整时返回 503，不静默改用本地。

完整录音、导入及多人会议合成录音使用统一存储，路径位于 `<prefix>audio/<user_id>/<meeting_id>/`；直传为每次上传增加独立 ID 子目录。直传文件不经业务服务器落盘；导入解码和会后合成仍使用任务临时目录。数据库记录 `audio_storage=local|oss|minio` 和本地路径/对象键。切换只影响后续写入，旧文件按其存储类型读取，因此须保留原后端配置与数据。

MinIO 的 `OPENMEETING_MINIO_ENDPOINT` 是网关代理可访问的内部 S3 地址；`OPENMEETING_MINIO_PUBLIC_ENDPOINT` 是桌面、手机可访问的外部地址，预签名 URL 使用此外部主机签名（不可在签名后替换主机）。下载仍返回 302，支持 Range；客户端不得将业务 Authorization 转发到存储主机。版本发布安装包共用相同配置，记录 `storage=local|oss|minio`，按原后端下载及删除。

`GET /admin/api/object-storage` 保留 `oss`、`oss_ready` 兼容字段，新增 `provider`、`public_endpoint`；`GET /admin/api/storage/audio` 新增 `provider`，`stats` 包含 `local/oss/minio` 三组。管理端展示当前后端，MinIO 参数由环境变量管理；OSS 的原有保存接口保持不变。连接测试对当前后端执行写入、读回、删除。内部 `GET /internal/meeting/oss-config?backend=minio|oss` 可取得指定后端配置，只有携带内部令牌的服务可访问，不向客户端返回密钥。

<a id="client-jobs"></a>

<a id="15-background-jobs-import--retranscription"></a>

### 1.5 后台任务（导入与重新转写）

| 方法 | 路径 | 请求体 | 响应 |
|---|---|---|---|
| POST | `/api/v1/jobs/import` | 多段表单（`multipart/form-data`）：`file`、`title`、`language?` | `Job`（202）；创建会议记录、存储音频，经过语音活动检测（VAD）切段后转写 |
| POST | `/api/v1/jobs/retranscribe` | `{"meeting_id": str, "language": str\|null}` | `Job`（202）；使用已保存的音频重新转写，替换该会议的全部转写记录 |
| GET | `/api/v1/jobs/{id}` | – | `Job` |
| DELETE | `/api/v1/jobs/{id}` | – | `Job`（`status` 变为 `cancelled`） |

`Job`: `{"id","kind":"import|retranscribe|summary","status":"queued|running|completed|failed|cancelled","progress":0-100,"message":str|null,"meeting_id":str|null,"error":str|null,"segments":int|null,"created_at","updated_at"}`

任务状态 `queued` 表示排队中，`running` 表示处理中，`completed` 表示已完成，`failed` 表示失败，`cancelled` 表示已取消；`progress` 为 0–100 的进度值。受理返回 202 不代表任务完成，需查询任务状态。

<a id="client-summary"></a>

<a id="16-summary-server-picks-the-llm-and-the-template--clients-never-send-providermodelapi-keytemplate"></a>

### 1.6 会议总结（服务端选择模型与模板，客户端不发送提供商、模型、密钥或模板）

| 方法 | 路径 | 请求体 | 响应 |
|---|---|---|---|
| POST | `/api/v1/meetings/{id}/summary` | `{"custom_prompt": str\|null, "text": str\|null}`；`text` 替代已保存的转写文本；忽略旧版 `template_id` / `language` 字段 | `{"message": str, "process_id": str}`（202）；未配置 LLM 或没有启用的总结模板时返回 503 |
| GET | `/api/v1/meetings/{id}/summary` | – | `SummaryResponse`；**与既有 Rust 命令 `api_get_summary`（`frontend/src-tauri/src/summary/commands.rs`）的 JSON 返回结构完全一致**：`{"status","meetingName","meeting_id","start","end","data","error"}`；`status` 与 Rust 一致，可取 `idle\|processing\|completed\|failed\|cancelled\|error` |
| DELETE | `/api/v1/meetings/{id}/summary` | – | 204（取消正在生成的总结） |
| PUT | `/api/v1/meetings/{id}/summary` | `{"summary": <json>}` | 204（保存手动编辑，语义同 `api_save_meeting_summary`） |
| GET | `/api/v1/meetings/{id}/summary-language` | – | `{"language": str\|null, "detected_language": str\|null}` |
| PUT | `/api/v1/meetings/{id}/summary-language` | `{"language"?: str\|null, "detected_language"?: str\|null}` | 同对应 GET 接口 |

总结状态 `idle` 表示空闲，`processing` 表示生成中，`completed` 表示已完成，`failed` 表示生成失败，`cancelled` 表示已取消，`error` 表示错误；请按返回状态处理，不要与任务的 `queued` / `running` 混用。

客户端不接触模板（`/api/v1/templates*` 已移除）。每次生成时，服务端根据模板描述和会议内容，请 LLM 选择最合适的已启用模板（由管理端维护，见 §2）；选择失败时使用管理员设置的默认模板。

所选模板的 `prompt` 原样作为最终报告唯一的系统提示词。服务端不额外添加语言、格式或标题规则，也不执行翻译或规范化。转写文本与作为用户补充上下文的 `custom_prompt` 放入用户消息；转写超过模型上下文长度时，先分块压缩，并保留转写语言。总结语言接口仅保存客户端偏好，不影响生成过程。

生成的总结 `data`：`{"markdown": str, "format": "markdown"|"html"|"mixed", "reasoning_stripped": bool}`。旧版总结可能还包含 `normalization_fallback`，客户端忽略该字段。

- `markdown` 是报告正文。若报告以一级标题（`# …` / `<h1>`）开头，会移除该标题并将其设为会议标题。`format` 来自模板的 `output_format`，决定渲染方式：`markdown` 使用 GitHub 风格 Markdown；`html` 为 HTML 片段，服务端提取完整文档的 `<body>` 并保留 `<head>` 中的 `<style>`，其中只有内联 `style` 属性能在所有客户端渲染；`mixed` 为嵌入原始 HTML 的 Markdown，例如 `<span style>`、`<mark>`、`<details>` 或跨列表格。
- 缺少 `format` 时按 `markdown` 处理，例如该字段加入前生成的总结或兼容客户端手动编辑的总结。
- 客户端渲染 HTML 前必须过滤脚本、事件处理属性、iframe 和表单，禁止外部资源加载，并隔离 `<style>`，防止影响应用其他界面。
- PUT 默认保留已存储的 `format`；正文显式指定时必须为上述三个值之一，否则返回 400。桌面端编辑 Markdown 时仍附带 BlockNote 的 `summary_json`。

<a id="client-notes"></a>

<a id="17-notes"></a>

### 1.7 会议笔记

| 方法 | 路径 | 请求体 | 响应 |
|---|---|---|---|
| GET | `/api/v1/meetings/{id}/notes` | – | `{"meeting_id","notes_markdown":str\|null,"notes_json":str\|null,"updated_at":str\|null}` |
| PUT | `/api/v1/meetings/{id}/notes` | `{"notes_markdown":str\|null,"notes_json":str\|null}` | 同对应 GET 接口 |

字段对应服务端 `meeting_notes` 表，模型见 [MeetingNotes](meeting_ms/db/models.py)，建表迁移见 [0001_initial.py](meeting_ms/migrations/versions/0001_initial.py)。客户端不维护本地会议业务数据库。

<a id="客户端文件直传"></a>
### 对象存储直传（安装包与完整录音）

| 方法 | 路径 | 请求体 | 响应 |
|---|---|---|---|
| POST | `/api/v1/meetings/{id}/audio/uploads` | `UploadProof` + `duration?:float`（客户端已知秒数，须非负有限值） | `UploadOffer`；须为会议所有者 |
| POST | `/api/v1/meetings/{id}/audio/uploads/complete` | `{"ticket":str}` | 与原音频上传相同的 `{"size":int,"duration":float|null}` |
| POST | `/api/v1/jobs/import/uploads` | `UploadProof` + `title`、`language?` | `UploadOffer`；申请时不创建会议或任务 |
| POST | `/api/v1/jobs/import/uploads/complete` | `{"ticket":str}` | 202，已创建的导入任务；重复确认返回同一任务 |
| POST | `/admin/api/releases/{id}/artifacts/uploads` | `UploadProof` + `arch`、`signature?`（`.sig` 文本） | `UploadOffer`；管理员鉴权，桌面包必须提供签名 |
| POST | `/admin/api/releases/{id}/artifacts/uploads/complete` | `{"ticket":str}` | 201，版本详情；重复确认不重复创建安装包 |

`UploadProof`：`{"file_name":str,"size":int,"sha256":str,"md5":str}`，文件大小为 1 字节至 2 GiB，SHA-256 为 64 位十六进制，MD5 为 16 字节摘要的 Base64。客户端按块计算摘要，不一次读取整个文件。`UploadOffer` 在本地存储模式返回 `{"mode":"proxy"}`，继续使用原上传接口；对象存储模式返回 `{"mode":"direct","url":str,"headers":object,"ticket":str,"expires_in":int}`，OSS 为 3600 秒，MinIO 为 900 秒。客户端使用独立 HTTP 请求向该 URL 执行原始文件 PUT，携带返回的上传头（MinIO 包含专用 `AWS4-HMAC-SHA256` Authorization）；不得附加业务 Bearer、Cookie，不跟随上传重定向。确认票据有效期为 3600 秒，过期后须重新申请并上传。

上传 URL 只授权临时对象。后端确认时核对票据归属、有效期、存储后端、对象大小和摘要元数据，再通过带 ETag 条件的存储内部复制固化最终对象，提交数据库后清理临时对象。文件内容不经过业务上传接口，失败不得确认成功或删除客户端本地文件。无效票据返回 403，过期返回 410，尚未上传返回 409，核验不符返回 422，存储操作失败返回 502。只在后端明确返回 `proxy` 或旧服务器不支持申请接口（404/405）时走原上传；直传失败不得静默改为中转。会中 PCM 分片、实时转写接口和服务器合成录音保持原路径。浏览器直传须配置对象存储 CORS；待确认临时对象的清理与部署说明见[对象存储](../docs/object-storage.md)。

<a id="client-updates"></a>

<a id="18-updates-public--work-before-login-so-a-forced-upgrade-also-blocks-the-login-screen"></a>

### 1.8 客户端更新（公开接口，登录前可用，强制升级也会阻止进入登录界面）

| 方法 | 路径 | 请求体 | 响应 |
|---|---|---|---|
| GET | `/api/v1/updates/check?platform=&version=&arch=&channel=&client_id=` | – | `{"update": UpdateOffer\|null, "min_version": str\|null}` |
| GET | `/api/v1/updates/tauri/{target}/{arch}/{current_version}?client_id=` | – | 无更新时返回 204，否则返回下述 Tauri 更新 JSON |
| GET | `/api/v1/updates/download/{artifact_id}` | – | 安装包（`FileResponse`），或 302 跳转到 OSS 签名 URL；计入下载次数 |

- OSS 安装包下载可在 `user_ms` 配置 `OPENMEETING_OSS_DOWNLOAD_DOMAIN`，使用已绑定 Bucket 的 HTTPS 自定义域名生成 CNAME 签名 URL（APK 分发需要）；未配置时使用 OSS 默认域名。上传 Endpoint、MinIO、本地下载及更新接口字段不变，详见[对象存储配置](../docs/object-storage.md#oss-安装包下载域名)。
- `platform`：`windows|macos|linux|android|ios`。`version`：`1.2.3` 或 `1.2.3+45`，加号后是 Flutter 构建号。桌面端 `arch` 为 `x86_64|aarch64`，macOS 也可匹配 `universal` 安装包。Android 的 `channel` 为 `direct`（默认，直接下载 APK）或 `huawei` 等应用商店渠道；iOS 始终使用 `appstore` 链接。`client_id` 用于灰度发布。
- 可选的 `Authorization: Bearer` 用于识别灰度白名单中的用户；无效令牌会被忽略，不返回 401。
- Tauri 的 `{target}` 为 `darwin|windows|linux`；`{arch}` 和 `{current_version}` 为更新器自身的变量。

`UpdateOffer`: `{"id","version","build":int,"full_version":"1.0.1+2","notes","pub_date","force":bool,"size":int|null,"sha256":str|null,"download_url":str|null,"store_url":str|null}`
- `download_url`（桌面端、Android `direct`）与 `store_url`（Android 商店渠道、iOS）必须且只会设置一个。
- 选择规则：筛选同平台、比 `version` 新且客户端可获取的已发布版本，按版本倒序选择首个命中灰度的版本。可获取表示有对应架构的安装包（桌面包必须签名），或有对应渠道的商店链接。灰度命中条件为用户在 `rollout_users` 中，或 `sha256("{release_id}:{client_id}")` 对应的 0–99 分桶值小于 `rollout_percent`。同一设备分桶稳定，提高比例只会增加设备。
- 当前版本低于该平台 `min_version` 时忽略灰度，返回不低于 `min_version` 的版本，并设置 `force=true`。客户端跨过的版本中，若任一命中灰度的版本标记为 `force`，也会强制升级。

Tauri 更新 JSON：`{"version","notes","pub_date","url","signature","force":bool,"min_version":str|null}`。`pub_date` 为 RFC 3339 时间，`url` 为下载地址，`signature` 为 `.sig` 文件内容；`force` / `min_version` 是桌面客户端从 `Update.raw_json` 读取的扩展字段。

<a id="client-schedules"></a>

<a id="19-scheduled-meetings"></a>

### 1.9 预定会议

用户预定会议后获得全局唯一的 6 位会议号 `code`，范围为 `100000`–`999999`，与全部预定及未结束房间检查唯一性。会议号在取消前保持不变。一条预定可提前开始，也可创建多场会议；每场分别拥有独立房间、IM 群、媒体授权和会后记录。`activeRoomId` 指向当前场次，不能仅凭计划时间判断会议是否进行中或已结束。取消状态会持久化，已取消的会议号仍被保留。

| 方法 | 路径 | 请求体 / 查询参数 | 响应 |
|---|---|---|---|
| POST | `/api/v1/scheduled-meetings` | `{title?, startAt, durationMin, pwdEnabled?, pwd?, remind?, waitRoom?}` | `ScheduledMeeting` (201) |
| GET | `/api/v1/scheduled-meetings?from=&to=` | 可选的 ISO-8601 UTC 时间范围；包含 `from`，不包含 `to`；均省略时返回全部预定，含过去日期 | `[ScheduledMeeting]`；仅调用者自己的预定，按 `startAt` 升序，包含已取消项 |
| GET | `/api/v1/scheduled-meetings/{id}` | – | `ScheduledMeeting` |
| PATCH | `/api/v1/scheduled-meetings/{id}` | 与创建接口相同的完整请求体 | `ScheduledMeeting`；仅所有者可操作，会议号不变；有活动场次或预定已取消时返回 409 |
| DELETE | `/api/v1/scheduled-meetings/{id}` | – | 204；幂等软取消，保留历史记录；有活动场次时返回 409 |

`ScheduledMeeting`:
```json
{"id": "sched-<uuid4>", "code": "314159", "title": "alice的会议", "startAt": "2026-10-22T09:00:00Z",
 "durationMin": 30, "pwdEnabled": false, "pwd": null, "remind": false, "waitRoom": false, "cancelled": false,
 "host": {"id": "<user_id>", "name": "alice"}, "meetingId": null, "activeRoomId": null, "createdAt": "…", "updatedAt": "…"}
```
- `title` 默认是主持人姓名加「的会议」，最多 50 个字符；`durationMin` 为 5–720 分钟。`pwd` 为 4–6 位数字，仅在 `pwdEnabled` 为真时存储，否则清除。`remind` / `waitRoom` 默认为 `false`。`host.name` 为创建时的姓名快照。
- 下列校验失败返回 422：`startAt` 在过去（允许 60 秒时钟偏差）、`durationMin` 超范围、`pwd` 格式错误或 `title` 超过 50 个字符。
- 访问他人的预定返回 404「预定不存在」。`meetingId` 是最近场次的记录 ID（§1.10），不表示预定已使用或取消；更早记录通过各自房间关联。编辑时可以保留原来已过去的开始时间，但不能改为另一个过去时间。有活动场次时不能编辑或取消；已结束的历史场次不影响操作。

<a id="client-rooms"></a>

<a id="110-live-rooms"></a>

### 1.10 实时会议房间

实时房间使用 REST 接口和信令，并可选接入 DeepRespond RTC 媒体。RTC 需要平台应用启用频道，并在 user_ms 中配置 IM（§1.11）。RTC 不可用时降级为会控和聊天，不影响业务房间创建或准入。

通过 `api_error` 返回的业务错误除 `detail` 外还包含可供程序判断的 `code`。入会错误码为 `not_found`、`not_started`、`ended`、`wrong_pwd`、`full`；其他错误码包括 `host_required`、`not_joined`、`waiting`、`muted_by_host`、`forbidden`、`conflict`、`invalid_input`、`recording_conflict`。Pydantic 校验仍使用常规 422 结构。客户端不能将所有 403 都视为 `wrong_pwd`，也不能将所有 409 都视为 `full`。

| 方法 | 路径 | 请求体 | 响应 |
|---|---|---|---|
| POST | `/api/v1/rooms` | `{title?, scheduledMeetingId?}` | `LiveRoom`（201）；创建快速会议，或为调用者自己的预定创建房间。快速会议省略或传空标题时，使用北京时间（UTC+8）的 `用户名的快速会议 YYYY-MM-DD HH:mm:ss`，如 `张三的快速会议 2026-10-27 16:09:05`；创建者姓名最多取 20 字，无姓名时依次使用手机号或「用户」。指定标题只去除首尾空白。预定房间继承标题、会议号和开关；他人预定返回 404，已取消预定返回 409。预定已有活动场次时复用，包括并发创建或加入；上一场结束后才创建新房间。最终会后记录继承房间标题 |
| GET | `/api/v1/rooms?code=<6 digits>` | – | `LiveRoom`；入会预检查。预定所有者可获取只读的 `status:waiting` 预览，不创建房间、IM 或 RTC 资源，随后通过 POST 入会启动。房主尚未进入时，其他用户收到 404 `not_started`「会议尚未开始，请等待房主进入后重试」。未知、已结束或已取消项返回 404 |
| POST | `/api/v1/rooms/join` | `{code, name?, micOn, camOn, pwd?}` | `JoinResult` |
| POST | `/api/v1/rooms/{id}/media` | – | 新的 `RoomMediaConfig`；仅已入会成员可用，等候中或已移除时返回 403，结束后返回 404 |
| POST | `/api/v1/rooms/{id}/media/recover` | `{sessionId}` | `{released:boolean}`；仅已入会成员可恢复本账号在本频道的 `leaving` 会话。正常/替换会话或目标属于他人时 409，平台失败 503。`false` 表示仍未释放，不可据此重新连接或签发票据 |
| GET | `/api/v1/rooms/{id}` | – | `LiveRoom`；仅成员可读，否则返回 403；房间结束后返回 404 `ended` |
| POST | `/api/v1/rooms/{id}/leave` | – | 204；仅成员可用，主持人必须结束会议，不能直接离开，否则返回 403 |
| POST | `/api/v1/rooms/{id}/end` | – | `{"meetingId": str, "jobId": str\|null}`；仅主持人可操作，原子创建会后记录与录制处理任务。结束时的主持人可在结束后重试并获得相同 ID；其他用户返回 403 `host_required` |
| POST | `/api/v1/rooms/{id}/admit` | `{participantId}` | 204；仅主持人可操作；目标须在等候室，否则返回 404 |
| POST | `/api/v1/rooms/{id}/deny` | `{participantId}` | 204；仅主持人可操作，删除等候记录 |
| POST | `/api/v1/rooms/{id}/participants/me` | `{micOn?, camOn?, handRaised?, screenSharing?}` | `Participant`；被主持人禁麦时设置 `micOn: true` 返回 403；主持人举手返回 422，`code=host_cannot_raise_hand`；开始共享会清除当前共享者状态 |
| PATCH | `/api/v1/rooms/{id}` | `{title?, pwdEnabled?, pwd?, waitRoom?}` | `LiveRoom`；仅主持人可操作，用于会中修改密码、等候室等设置 |
| POST | `/api/v1/rooms/{id}/participants/{participantId}/mute` | `{muted: bool}` | 204；仅主持人可操作。`muted: true` 强制设置 `micOn=false` 并施加 `mutedByHost` 限制，主持人解除前成员不能自行开麦 |
| POST | `/api/v1/rooms/{id}/participants/{participantId}/approve-hand` | – | 204；仅主持人可操作。清除目标成员的 `handRaised` 和 `mutedByHost`，保留 `micOn`，由成员自行选择何时开麦 |
| POST | `/api/v1/rooms/{id}/participants/{participantId}/remove` | – | 204；仅主持人可操作，目标为主持人时返回 422 |
| POST | `/api/v1/rooms/{id}/participants/{participant_id}/transfer-host` | – | 204；仅主持人可操作，目标必须是已入会且已登录的成员，访客返回 422。清除新主持人的 `handRaised` 和 `mutedByHost`，保留 `micOn` |
| POST | `/api/v1/rooms/{id}/mute-all` | – | 204；仅主持人可操作，对主持人以外的成员设置 `mutedByHost` 并静音 |
| POST | `/api/v1/rooms/{id}/chat-session` | 无正文；仅已入会成员可用 | `{transport:"dr-im-group", groupId}`；创建或复用私有 IM 群并授予平台群成员资格。IM 失败时返回 503，不回退到本地存储 |

`JoinResult`:
```text
{"room": LiveRoom, "self": Participant, "state": "joined" | "waiting", "media": {"transport": "webrtc", "iceServers": [{"urls": "stun:stun.l.google.com:19302"}], "token": null}}
```
RTC 可用时，`media` 为 `{transport:"dr-rtc", channelId, ticket, expiresAt}`。凭证 `ticket` 一次性、短期有效，仅发给已认证的对应成员，不得持久化或写入日志。等候成员收到不含凭证的旧版占位结构；获准入会后请求 `/media`。重试或授权过期也使用该接口，无需重新入会或重置成员会控状态。

桌面端发现当前频道的旧会话持续 `leaving` 时提供「释放并重试」。先停止本地连接尝试，再调用 `/media/recover`；平台确认已无该账号未结束会话后，才调用 `/media` 获取新票据，连接原频道。恢复不退出业务房间，不重建聊天订阅，不关闭频道或封禁账号。请求身份由后端认证派生，客户端不能指定待移除账号。每次恢复均查询所有会话分页，拒绝观察到的 `joining/joined` 或不同会话；重复清理使用同一幂等操作 ID。平台尚未释放时最多轮询 20 秒，展示失败并允许再次手动重试，不自动抢占其他设备。

旧版占位结构可能附带 `unavailableReason:"rtc_unavailable"`。`Participant.userId` 将 SDK 轨道关联到房间成员，SDK 中的用户名为 深应会议 用户 ID。结束会议会关闭频道；拒绝或移除成员会撤销凭证并移除媒体成员。IM 应用凭证仅保存在 user_ms，由内部服务鉴权保护。

会议聊天和附件在 `/chat-session` 授予群成员资格后使用 IM SDK。消息及历史属于服务端管理的私有 IM 群；文件使用 `group_file` 和固定的 IM 文件引用。仅当前群成员可以解析群文件下载地址。旧本地聊天和附件路由已退役。

结束会议时，先幂等调用 `groups.delete(reason="Meeting ended")` 解散私有 IM 群，再提交房间结束状态。平台失败返回 503，房间保持活动状态以便重试。客户端需释放消息订阅、取消传输、清空消息、回复和未读状态，并隐藏已结束场次的会话。消息工作台排除已解散会话。IM 数据保留和最终成员清理遵循平台策略，不保证立即物理删除；之前已停用的群不会自动删除。离会、移除或成员资格过期会撤销群成员资格；IM 失败返回 `503 im_chat_unavailable`，不回退到本地存储。
`LiveRoom`:
```text
{"id": "room-<uuid4>", "title": "…", "code": "314159", "scheduledMeetingId": "sched-…"|null, "status": "active",
 "pwdEnabled": false, "waitRoom": false, "hostId": "<participantId>", "hostUserId": "<user_id>", "participants": [Participant],
 "waiting": [{"participantId", "name", "requestedAt"}], "startedAt": "…", "endedAt": null, "meetingId": null}
```
`Participant`:
```json
{"id": "user-<uuid4>", "name": "bob", "isHost": false, "isSelf": true, "micOn": true, "mutedByHost": false, "camOn": false,
 "handRaised": false, "screenSharing": false, "joinedAt": "…"}
```
`Participant.mutedByHost` 表示主持人施加的限制，与麦克风开关状态不同；房间快照和成员事件均携带此字段。全体静音后，主持人可用既有成员静音接口向受限的非主持人成员发送 `{muted:false}`，恢复其自行开麦的权限；这不会远程启动麦克风采集。

- 入会校验顺序：6 位会议号格式（失败返回 422）→ 查找房间（预定尚无房间时，仅为**所有者**自动创建并以主持人身份加入；其他用户收到 404 `not_started`「会议尚未开始，请等待房主进入后重试」）→ 密码（403 `wrong_pwd`）→ 已有成员幂等重入（返回原成员，不受容量限制）→ 容量（409 `full`，服务端默认 50 人）→ 等候室（`waitRoom` 开启时为 `state="waiting"`，主持人除外）。
- `name` 默认使用当前会话用户姓名，最多 20 个字符。离会或移除会删除成员行；聊天保留冗余存储的发送者姓名。会后记录（`meetingId`）归主持人账号所有，实际参会账号的共享读取权限见 §1.3。

**信令 WebSocket**：`GET(WS) /api/v1/rooms/{id}/ws`，经网关访问，使用 Bearer 请求头或 `?token=<session>` 鉴权。业务操作仍使用 REST。客户端每 15 秒发送 `{"type":"ping"}`，服务端以 `pong` 消息响应。连接后立即收到完整的 `room_state` 快照；重连不重放业务事件，聊天由 IM SDK 独立恢复。消息封装结构为：
`{"type": str, "ts": str, "data": {...}}`.

| 事件类型（type） | 数据（data） | 说明 |
|---|---|---|
| `participant_joined` | `{participant}` | 获准入会或直接加入 |
| `participant_left` | `{participantId}` | 离会或被移除 |
| `participant_updated` | `{participant}` | 麦克风、摄像头、举手或共享状态变化；`isSelf` 按接收者分别计算 |
| `waiting_requested` | `{participantId, name}` | 仅主持人接收 |
| `waiting_resolved` | `{participantId, admitted: bool}` | 仅受影响的连接接收；拒绝后服务端关闭该连接 |
| `active_speaker` | `{participantId: str\|null}` | 预留事件，当前尚不产生 |
| `room_ended` | `{meetingId: str}` | 随后服务端关闭所有连接 |
| `room_state` | `{room: LiveRoom}` | 连接建立、PATCH 更新、拒绝入会或转交主持人后发送 |
| `pong` | `{}` | 业务心跳响应；由 Rust 消费，不转发给会议界面 |

网关关闭码：4401 表示未认证；4403 表示不是成员，由 meeting_ms 返回；4408 表示业务心跳超时，默认 45 秒；4502 表示下游不可达。Rust 检测接收流量中断后，以带随机抖动的退避策略重连。约 90 秒内未成功获取房间快照时停止重连，当前连接尝试或退避等待可能延长该时限。随后发出 `room-connection.state=failed`，界面显示返回首页或重新入会操作。

在线状态与 SDK 媒体心跳独立。每条连接拥有自己的持久化租约，并刷新对应成员的 `last_seen_at`；旧连接不能删除替代连接的租约。最后一条有效 WS 连接确认断开后，持久化 `disconnected_at`，默认给 3 秒重连窗口，每秒扫描；窗口内重连或幂等重新入会会取消该期限。同账号仍有有效连接时不启动清退。到期后普通成员移除，主持人则结束会议并保留已确认录音处理；不自动转移主持人。此机制同时适用于桌面和移动端的业务 WS，不依赖应用正常退出回调。

未建立连接、没有收到明确断连信号或等候席位仍沿用原有活性策略：成员及等候席位 90 秒，主持人 180 秒，静默 WS 的心跳超时为 45 秒。完全断网、休眠或服务器尚未观察到 TCP 断开的情况不能保证 3 秒离会；计时从服务端确认断开开始，扫描调度与平台撤权调用也会增加实际时延。已认证的等候客户端通过轮询既有会议号预检查接口续租席位。

配置项：`OPENMEETING_ROOM_HEARTBEAT_TIMEOUT_SECONDS`、`OPENMEETING_ROOM_MEMBER_GRACE_SECONDS`、`OPENMEETING_ROOM_HOST_GRACE_SECONDS`、`OPENMEETING_ROOM_DISCONNECT_GRACE_SECONDS`、`OPENMEETING_ROOM_SWEEP_INTERVAL_SECONDS`。不发送应用层 ping 的客户端必须随协议一起升级，否则静默连接将在心跳超时后关闭。这套机制不提供多实例信令，也不保证失败的平台清理一定完成。成员断连时间保存在 `room_participants.disconnected_at`；schema 由 Alembic 管理，默认启动自动执行结构更新，禁用时需手动执行。见[会议连接恢复设计](../docs/meeting-resilience.md)。

会中设置前端通过既有 `room_patch` 调用 `PATCH /rooms/{room_id}`：主持人可更新 `title`、`pwdEnabled`、`pwd`、`waitRoom`。密码启用且省略 `pwd` 时保留现有密码，关闭时清除；密码为 4–6 位数字。更新不影响已入会成员。响应和 `room_state` 只含密码启用状态，不包含密码原文。实现说明见 [会中设置与 IM 工作台](../docs/meeting-im-workbench.md)。

发言人高亮与网络质量是客户端实际 RTC 统计的派生状态，服务端仍不产生音频 `active_speaker` 事件。丢包/RTT 不写入房间快照；无可用统计时客户端显示未知。

桌面 IM 通知策略：`notice` 账号的会议预定、提醒、会后处理及 `room_state` 内部同步消息统一以 `exclude_from_unread=true`、`push.disabled=true` 发送。业务内容与幂等投递保留，不增加未读或离线推送。桌面仅为活动会议群聊天显示 IM 提醒和角标，私聊及其他消息静默；历史非会议会话未读不纳入任务栏角标。详见 [IM 交付说明](../docs/meeting-im-capabilities.md)。

<a id="client-im"></a>

<a id="111-im-ticket"></a>

### 1.11 IM 登录凭证

| 方法 | 路径 | 请求体 | 响应 |
|---|---|---|---|
| POST | `/api/v1/im/ticket` | – (Bearer) | `{"ticket": str, "api_url": str, "app_key": str, "expires_in": int, "expires_in_sec": int, "user_created": bool}` |

- 使用 深应会议 用户会话换取 DeepRespond IM 服务的**一次性**登录凭证。服务端持有 IM App Token / Client Secret，绝不下发客户端；首次调用会创建 IM 账号，使用 深应会议 用户 ID 作为 IM `username`。
- `ticket` 一次性、短期有效，有效期见 `expires_in_sec`；`api_url` / `app_key` 标识客户端应连接的 IM 部署，也对应客户端引擎配置中的静态初始连接参数。
- 服务端未配置 IM 时返回 503；会话错误（401 / 403）按 §1 处理。
- GET 为兼容别名，响应带 `Cache-Control: private, no-store`；当前调用使用 POST。
- 桌面调试回退需要显式设置 `OPENMEETING_IM_DEV_TICKET`、`OPENMEETING_IM_API_URL` 和 `OPENMEETING_IM_APP_KEY`。全新安装会等待已认证服务端提供配置，不会隐式连接演示应用。
- Tauri 客户端通过 `im_get_ticket` 命令获取凭证，由 IM 引擎的 `ticketProvider` 在 `loginWithTicket` 前调用。

---

<a id="admin-api"></a>

<a id="2-admin-api--adminapi-session-cookie-openmeeting_admin-set-by-login-also-accepts-authorization-bearer-admin_jwt"></a>

## 2. 管理端 API — `/admin/api`（登录后设置会话 cookie `openmeeting_admin`，也接受 `Authorization: Bearer <admin_jwt>`）

**网关与部署版本**：下列 `/admin/api/update-policy` GET / PUT 已在 user_ms 实现，当前 `develop` 的网关也已配置该前缀。接入仍需确认目标环境已部署相应版本；见[实现核对说明](API_GUIDE.md#known-gaps)。

| 方法 | 路径 | 请求体 | 响应 |
|---|---|---|---|
| POST | `/admin/api/login` | `{"password": str}` | `{"token": str}`，并通过 `Set-Cookie` 设置会话 |
| POST | `/admin/api/logout` | – | 204 |
| GET | `/admin/api/me` | – | `{"ok": true}` |
| GET | `/admin/api/dashboard` | – | `{"server_version","uptime_sec","system":{"cpu_percent","mem_used","mem_total","disk_used","disk_total","gpus":[{"index","name","util_percent","mem_used","mem_total"}]},"device":"cuda\|cpu","stt":Capabilities.stt,"llm":Capabilities.llm,"stats":{"online_clients","recording_clients","running_jobs","today_requests","today_audio_sec","today_errors","avg_latency_ms"}}` |
| GET | `/admin/api/stats/timeseries?hours=24` | – | `[{"ts","transcribe_requests","audio_sec","summary_requests","errors","avg_latency_ms"}]`；按小时分桶 |
| GET | `/admin/api/stt/engines` | – | `[{"engine":"faster-whisper\|funasr\|cloud","available":bool,"reason":str\|null}]`；`available` 表示 Python 依赖可成功导入 |
| GET | `/admin/api/stt/models` | – | `[SttModel]` |
| POST | `/admin/api/stt/models/{model_id}/download` | – | `SttModel`（`status` 变为 `downloading`） |
| DELETE | `/admin/api/stt/models/{model_id}` | – | 204；删除模型文件，不能删除当前启用的模型 |
| POST | `/admin/api/stt/activate` | `{"model_id": str}` | `Capabilities.stt`；热切换，先加载新模型再释放旧模型；失败时保留旧模型，返回 500 并附原因 |
| POST | `/admin/api/stt/test` | 多段表单：`file`、`language?` | `{"text": str, "elapsed_ms": int, "engine": str, "model": str}` |
| GET | `/admin/api/stt/cloud-config` | – | `{"mode":"openai\|dashscope","base_url","model","api_key_set":bool}` |
| PUT | `/admin/api/stt/cloud-config` | `{"mode","base_url","model","api_key"?}` | 同对应 GET 接口 |
| GET | `/admin/api/llm/providers` | – | `[LlmProvider]` |
| POST | `/admin/api/llm/providers` | `LlmProviderInput` | `LlmProvider` |
| PUT | `/admin/api/llm/providers/{id}` | `LlmProviderInput`；省略 `api_key` 表示保留原值 | `LlmProvider` |
| DELETE | `/admin/api/llm/providers/{id}` | – | 204 |
| POST | `/admin/api/llm/providers/{id}/test` | – | `{"ok": bool, "elapsed_ms": int, "reply": str\|null, "error": str\|null}` |
| POST | `/admin/api/llm/providers/{id}/activate` | – | `Capabilities.llm` |
| GET | `/admin/api/llm/providers/{id}/models` | – | `[str]`；代理调用 `GET {base_url}/models`，失败时返回空列表 |
| POST | `/admin/api/llm/models-probe` | `{"base_url": str, "api_key": str\|null, "provider_id": str\|null}` | `[str]`；保存前代理调用 `GET {base_url}/models`；`api_key` 为空且提供 `provider_id` 时使用该提供商已存的密钥；失败时返回空列表 |
| GET | `/admin/api/connections` | – | `[{"client_id","user_id","user_name","user_phone","hostname","os","app_version","ip","recording":bool,"meeting_id","last_seen","online":bool,"inflight_requests":int}]`；距上次心跳不足 45 秒时视为在线 |
| GET | `/admin/api/jobs?status=` | – | `[Job & {"user_name"}]` |
| DELETE | `/admin/api/jobs/{id}` | – | `Job` |
| GET | `/admin/api/users?q=&status=&limit=&offset=` | – | `{"items":[AdminUser],"total"}`；`q` 匹配手机号或姓名；`status` 为 `active` 或 `disabled` |
| POST | `/admin/api/users` | `{"phone","name"}` | `AdminUser`；预创建用户，用户之后通过短信登录 |
| GET | `/admin/api/users/{id}` | – | `AdminUser` + `{"sessions":[Session]}` |
| PATCH | `/admin/api/users/{id}` | `{"name"?,"phone"?,"disabled"?}` | `AdminUser`；禁用时撤销所有会话 |
| DELETE | `/admin/api/users/{id}` | – | 204；级联删除会议、音频与会话 |
| DELETE | `/admin/api/users/{id}/sessions/{session_id}` | – | 204；强制一台设备退出登录 |
| DELETE | `/admin/api/users/{id}/sessions` | – | 204；强制所有设备退出登录 |
| GET | `/admin/api/auth-settings` | – | `{"registration_open": bool, "sms": {"access_key_id": str\|null, "access_key_secret_set": bool, "sign_name": str\|null, "template_code": str\|null, "template_param": str, "endpoint": str}, "sms_ready": bool}` |
| PUT | `/admin/api/auth-settings` | `{"registration_open"?, "sms"?: {"access_key_id"?, "access_key_secret"?, "sign_name"?, "template_code"?, "template_param"?, "endpoint"?}}`；省略 `access_key_secret` 表示保留；`template_param` 默认 `code`，`endpoint` 默认 `dysmsapi.aliyuncs.com` | 同对应 GET 接口 |
| POST | `/admin/api/auth-settings/sms-test` | `{"phone"}` | `{"ok": bool, "request_id": str\|null, "error": str\|null}`；会发送真实测试验证码 |
| GET | `/admin/api/object-storage` | – | 全局对象存储配置：`{"oss": {"endpoint": str\|null, "region": str\|null, "bucket": str\|null, "access_key_id": str\|null, "access_key_secret_set": bool, "prefix": str}, "oss_ready": bool, "env_overrides": [field]}`；环境变量优先；供录音和版本安装包共用，不包含业务统计 |
| PUT | `/admin/api/object-storage` | `{"endpoint"?, "region"?, "bucket"?, "access_key_id"?, "access_key_secret"?, "prefix"?}`；Secret 省略或 `null` 保留，空字符串清除；Region 留空自动推导 | 同对应 GET；沿用已有 `oss_config`，无需迁移配置 |
| POST | `/admin/api/object-storage/test` | – | `{"ok": bool, "error": str\|null}`；写入、读回并删除测试对象 |
| GET | `/admin/api/storage/audio` | – | 录音状态与统计：`{"oss_ready": bool, "stats": {"local": {"meetings": int, "bytes": int}, "oss": {...}}}` |
| GET | `/admin/api/storage` | – | 兼容旧管理端：全局对象存储配置加录音 `stats`；新页面分别调用 `/object-storage` 和 `/storage/audio` |
| PUT | `/admin/api/storage` | `{"endpoint"?, "region"?, "bucket"?, "access_key_id"?, "access_key_secret"?, "prefix"?}`；`region` 为空字符串时自动推导；`access_key_secret` 省略或为 `null` 时保留，空字符串表示清除 | 同对应 GET 接口 |
| POST | `/admin/api/storage/test` | – | `{"ok": bool, "error": str\|null}`；写入、读回并删除一个小型测试对象 |
| GET | `/admin/api/sms-logs?phone=&limit=&offset=` | – | `{"items":[{"id","phone","purpose","ip","ok","error","created_at"}],"total"}` |
| GET | `/admin/api/meetings?user_id=&q=&limit=&offset=` | – | `{"items":[{"id","title","user_name","created_at","transcript_count","has_audio","has_summary"}],"total"}` |
| GET | `/admin/api/meetings/{id}` | – | `MeetingDetails` + `{"user_name","summary":SummaryResponse}`；仅管理端可见的 `summary.data.template: {"id","name"}` 表示服务端选中的模板 |
| GET | `/admin/api/summary-templates` | – | `[SummaryTemplate]`；按创建时间升序 |
| POST | `/admin/api/summary-templates` | `SummaryTemplateInput` | `SummaryTemplate` |
| PUT | `/admin/api/summary-templates/{id}` | `SummaryTemplateInput` | `SummaryTemplate` |
| DELETE | `/admin/api/summary-templates/{id}` | – | 204 |
| GET | `/admin/api/releases?platform=` | – | `[ClientRelease]`；按版本倒序 |
| POST | `/admin/api/releases` | `ClientReleaseInput` + `{"platform"}` | 201 `ClientRelease`，状态为 `draft` |
| PUT | `/admin/api/releases/{id}` | `ClientReleaseInput` | `ClientRelease`；仅 `draft` 状态可修改版本和构建号，否则返回 400 |
| DELETE | `/admin/api/releases/{id}` | – | 204；仅限 `draft` / `archived` 状态，同时删除安装包 |
| POST | `/admin/api/releases/{id}/artifacts` | 多段表单：`arch`、`file`、`signature`；`signature` 为 `.sig` 文件，桌面端必填 | 201 `ClientRelease`；替换对应架构的安装包 |
| DELETE | `/admin/api/releases/{id}/artifacts/{artifact_id}` | – | `ClientRelease` |
| POST | `/admin/api/releases/{id}/publish` | – | `ClientRelease`；`draft` / `paused` 变为 `published`，桌面端必须已有安装包 |
| POST | `/admin/api/releases/{id}/pause` | – | `ClientRelease`；`published` 变为 `paused`，停止向客户端提供此版本 |
| POST | `/admin/api/releases/{id}/archive` | – | `ClientRelease` |
| GET | `/admin/api/releases/stats` | – | `{platform: [{"version","count"}]}`；统计最近 30 天使用过的会话的 `app_version` |
| GET | `/admin/api/update-policy` | – | `UpdatePolicy` |
| PUT | `/admin/api/update-policy` | 部分 `UpdatePolicy`，仅修改提供的平台 | `UpdatePolicy` |
| GET | `/admin/api/events` | – | 服务端推送事件（SSE）流；`connections`、`jobs`、`stt`、`llm`、`model-download` 事件携带 JSON 数据，每 15 秒另发一次 `ping` |

`SttModel`：`{"id":"faster-whisper:large-v3","engine","name","display_name","size_mb":int,"languages":"multilingual|zh|…","status":"not_downloaded|downloading|ready|error","progress":0-100,"error":str|null,"active":bool,"remote":bool}`。云模型的 `remote=true`，云配置含密钥时状态始终为 `ready`。

`AdminUser`: `{"id","phone","name","disabled","created_at","last_login_at","has_password":bool,"meeting_count","session_count","online":bool}`
- `phone` 可为 `null`，对应手机号登录上线前创建的旧用户；需通过 PATCH 分配手机号才能登录。`session_count` 为未撤销且未过期的活动会话数。
- `PATCH {"disabled": true}` 先撤销所有会话，再返回 `AdminUser`，此时 `session_count=0`、`online=false`。
`Session`: `{"id","client_id","hostname","os","app_version","ip","created_at","last_used_at","expires_at","revoked"}`
- `client_id` / `hostname` / `os` / `app_version` / `ip` / `last_used_at` 可为 `null`。
- `GET /admin/api/users/{id}` 按创建时间倒序返回用户的**全部**会话，包括已撤销和已过期会话；界面使用 `revoked` 和 `expires_at` 筛选。

`/admin/api/users` 与 `/admin/api/sms-logs` 的 `limit` 默认 20，上限 100；`/users` 按创建时间倒序。短信日志 `id` 为整数；管理端测试发送（`/auth-settings/sms-test`）以 `purpose: "test"` 记录。`/admin/api/tokens*` 接口已移除。

`SummaryTemplate`: `{"id","name","description","prompt","output_format":"markdown|html|mixed","enabled":bool,"is_default":bool,"created_at","updated_at"}`
`SummaryTemplateInput`：`{"name","description","prompt","output_format"?,"enabled"?,"is_default"?}`；`output_format` 默认 `markdown`，`enabled` 默认 `true`，`is_default` 默认 `false`。

- `description` 告诉 LLM 何时选择该模板；`prompt` 是完整报告指令，原样发送，服务端不添加其他要求。因此必须明确语言、结构、与 `output_format` 一致的格式，以及需要用于重命名会议的开头标题。
- 设置 `is_default` 会清除其他模板的默认标记，禁用模板不能为默认模板。自动选择失败时使用默认模板。更新或删除后若不再有启用模板，返回 400。
- 初始数据来自原内置 JSON 模板，默认项为 `standard_meeting`，格式均为 `markdown`；提示词以 Markdown 和标题要求开头。

`ClientRelease`: `{"id","platform","version":"1.2.3","build":int,"full_version","notes","force":bool,"status":"draft|published|paused|archived","rollout_percent":0-100,"rollout_users":[{"id","name","phone"}],"artifacts":[ReleaseArtifact],"published_at","created_at","updated_at"}`
`ClientReleaseInput`：`{"version","build"?,"notes"?,"force"?,"rollout_percent"?,"rollout_users"?}`；`build` 默认 0，桌面端忽略；`rollout_percent` 默认 100；`rollout_users` 为用户 ID 数组，未知 ID 会被丢弃。
`ReleaseArtifact`: `{"id","arch":"x86_64|aarch64|universal|any","file_name","size","sha256","signed":bool,"storage":"local|oss|minio","download_count","created_at"}`
- 管理端“版本发布”的每个安装包提供“下载”按钮，复用 `GET /api/v1/updates/download/{artifact_id}`，支持本地文件和对象存储；草稿、暂停及归档版本也可下载已上传的安装包，下载计入次数。
- 各平台架构：Windows / Linux 使用 `x86_64|aarch64`，macOS 使用 `aarch64|x86_64|universal`，Android 使用 `any`，iOS 不上传安装包，仅使用 App Store 链接。
- 平台、版本和构建号均相同时返回 409。安装包存储在 `<data_dir>/releases/`；配置 OSS 后存储在 OSS 的 `releases/…` 下。

`UpdatePolicy`：`{platform: {"min_version": "" | "1.2.3[+45]", "store_urls": {channel: url}}}`。iOS 使用 `appstore` 渠道；Android 商店渠道（`huawei`、`xiaomi` 等）与应用构建时的 `APP_CHANNEL` 对应。URL 必须以 `https://`、`http://`、`market://`、`itms-apps://` 或 `appmarket://` 开头。

`LlmProvider`: `{"id","name","base_url","model","api_key_set":bool,"max_tokens":int|null,"temperature":f|null,"top_p":f|null,"context_tokens":int,"active":bool,"created_at"}`
`LlmProviderInput`：`{"name","base_url","model","api_key"?,"max_tokens"?,"temperature"?,"top_p"?,"context_tokens"?}`。`context_tokens` 默认 32000，用于决定总结输入的分块长度。

内置模型目录至少包括：

- faster-whisper：`tiny`、`base`、`small`、`medium`、`large-v3`、`large-v3-turbo`；Hugging Face 仓库为 `Systran/faster-whisper-*`，turbo 使用 `mobiuslabsgmbh/faster-whisper-large-v3-turbo` 或 `deepdml/faster-whisper-large-v3-turbo-ct2`。
- funasr：`sensevoice-small`（`iic/SenseVoiceSmall`）、`paraformer-zh`（`iic/speech_paraformer-large-vad-punc_asr_nat-zh-cn-16k-common-vocab8404-pytorch`）。
- 云端：`cloud:default`，使用 `cloud-config` 配置。

---

<a id="tauri-api"></a>

<a id="3-tauri-command-contract-rust--nextjs"></a>

## 3. Tauri 命令契约（Rust ↔ Next.js）

<a id="31-new-commands"></a>

### 3.1 新增命令

服务地址内置于客户端。桌面端为 `src-tauri/src/server/config.rs` 中的 `SERVER_URL`，默认占位地址为 `https://meeting.example.com`，实际部署时通过编译变量 `OPENMEETING_SERVER_URL` 指定自己的网关；移动端为本地初始化生成的 `assets/config/app_config.<env>.json` 中的 `defaultServerUrl`。用户不能在界面查看或修改该地址，地址也不会发送给界面。会话与内置服务地址绑定。

| 命令 | 参数（由 TS 以小驼峰命名传入） | 返回值 |
|---|---|---|
| `server_get_config` | – | `{"loggedIn": bool, "clientId": str}` |
| `auth_send_code` | `{phone: string, purpose: "register"\|"login"\|"reset_password"}` | `{"sent","resend_after_sec","expires_in_sec","dev_code"?}` |
| `auth_register` | `{phone, code, name, password}` | `User`；保存会话令牌，刷新状态并发出 `server-status` |
| `auth_login` | `{phone, code: string\|null, password: string\|null}`；验证码与密码只能提供一个非空值 | `User`；保存会话并刷新状态，同注册命令 |
| `auth_reset_password` | `{phone, code, password}` | `User`；用于忘记密码，完成后的会话处理同登录 |
| `auth_change_password` | `{oldPassword: string\|null, password}` | `User`；首次设置或修改密码 |
| `auth_logout` | – | `null`；尽力调用服务端退出接口，清除本地会话并发出 `server-status` |
| `auth_get_user` | – | `User \| null`；上次检查缓存的用户信息 |
| `auth_update_profile` | `{name}` | `User` |
| `server_get_status` | – | `ServerStatus`；上次心跳缓存的状态，从未检查过时强制检查 |
| `update_check` | – | `{"available":bool,"currentVersion","version"\|null,"notes"\|null,"pubDate"\|null,"force":bool,"minVersion"\|null}`；请求内置服务的 `/updates/tauri/…`，登录后携带 Bearer，使用 `client_id` 匹配灰度；缓存找到的更新供 `update_install` 使用 |
| `update_install` | – | 成功时下载、验签、安装并重启，不返回调用结果；发出 **`update-download-progress`** `{downloaded, total\|null}`。录音中或会议仍在同步时，以可读信息报错 |
| `update_install_blocker` | – | `string \| null`；当前拒绝执行 `update_install` 的原因 |
| `recording_sync_pending` | `{meetingId: string}` | `bool`；该会议是否仍在执行后台工作，例如停止录音后的同步或导入文件的服务端转写 |
| `server_fetch_meeting_audio` | `{meetingId: string}` | `string \| null`；音频本地路径，允许通过资源访问范围读取；服务端无音频时为 `null`。依次查找本地索引中的录音目录、兼容缓存位置 `<app cache>/audio-cache/<id>.*`，最后从服务端下载并跟随 OSS 跳转，保存至 `<recordings folder>/<title>_<YYYY-MM-DD_HH-MM>/audio.<ext>`，登记到本地会议索引。下载时发出 **`audio-download-progress`** `{meetingId, progress: 0..100}` |

会议详情仅在用户点击**云端下载**后调用 `server_fetch_meeting_audio`。挂载播放器、切换标签页和刷新会后处理状态时，只读取元数据或转写，不下载音频。主动下载成功后使用本地文件播放；再次调用同一命令时复用缓存文件。

停止录音（`stop_recording`）仅停止采集、将录音保存到本地，然后返回。其余操作在后台执行：等待排队的语音片段处理（服务端每转写一段就保存一段）、重发录音期间失败的片段、上传录音文件（`audio-upload-progress`）及执行分析。全部完成后发出 **`meeting-sync-finished`** `{meetingId}`，会议页面据此重新加载转写，自动总结也等待该事件。点击停止后才完成的片段不会再作为实时 `transcript-update` 发出。

导入音频（`start_import_audio_command`）仅在上传期间阻塞导入弹窗。上传进度事件为 **`import-progress`** `{stage: "uploading", progress_percentage: 0..100, message}`；上传失败或取消时发出 **`import-error`** `{error}`。服务端受理任务后发出 **`import-uploaded`** `{meeting_id, title}` 并释放导入锁，此时可继续导入其他文件。已受理的任务由客户端在后台跟踪，不能再从客户端取消。最终发出 **`import-complete`** `{meeting_id, title, segments_count, duration_seconds}` 或 **`import-failed`** `{meeting_id, title, error}`；导入失败时服务端删除对应会议记录。两者之后都会发出 `meeting-sync-finished` `{meetingId}`；期间该会议的 `recording_sync_pending` 为 `true`。

`ServerStatus` 也是 **`server-status`** 事件的负载，每次心跳或状态变化时发出：
```text
{"configured": bool, "connected": bool, "loggedIn": bool, "authenticated": bool,
 "user": User|null, "authConfig": AuthConfig|null, "capabilities": Capabilities|null, "error": str|null, "lastCheck": str|null}
```
- `configured` 表示已内置服务地址，真实构建中始终为 `true`；`connected` 表示服务可达；`loggedIn` 表示本地存有会话令牌；`authenticated` 表示服务端认可该会话，收到 401 后变为 `false`，界面必须显示手机号登录页。
- 服务端返回任何 401 时，客户端均清除已存会话，设置 `loggedIn=false` 并发出 `server-status`。
- 桌面心跳中的账号数据：当 capabilities 中的身份与缓存的完整账号信息（ID、姓名、手机号）冲突时，重新请求 `GET /api/v1/auth/me`，避免用可能由网关缓存的摘要覆盖账号信息。登录、退出或资料变更会使正在进行的旧心跳失效；被丢弃的结果既不能发出旧的 `server-status`，也不能返回给命令调用方。
- `AuthConfig` 为 `GET /api/v1/auth/config` 的响应。

<a id="32-kept-commands-same-namesargsreturn-shapes-implementation-now-calls-the-server"></a>

### 3.2 保留命令（名称、参数和返回结构不变，实现改为调用服务端）

`api_get_meetings`, `api_get_meeting`, `api_get_meeting_metadata`, `api_get_meeting_transcripts`, `api_search_transcripts`,
`api_delete_meeting`、`api_save_meeting_title`、`api_save_transcript`（现在仅重命名会议，并批量插入服务端尚未保存的转写）、
`api_process_transcript`（接受但忽略 `model` / `modelName` 参数，不提供模板参数）、`api_get_summary`、`api_cancel_summary`、`api_save_meeting_summary`，
以及总结语言、会议笔记、录音、导入和重新转写相关命令。导入与重新转写现在提交服务端任务，并将轮询结果转换为既有 `import-*` / `retranscription-*` 事件。

兼容性只读适配命令，界面仍可读取：

- `api_get_model_config` → `{"provider":"server","model":<LLM 模型或空字符串>,"whisperModel":<STT 模型或空字符串>,"apiKey":null,"ollamaEndpoint":null}`。
- `api_get_transcript_config` → `{"provider":"server","model":<STT 模型或空字符串>,"apiKey":null}`。

<a id="33-removed-commands-ui-must-stop-calling-them"></a>

### 3.3 已移除命令（界面必须停止调用）

`api_list_templates`、`api_get_template_details`、`api_validate_template` 已移除，模板在服务端管理并自动选择。

`server_save_config`、`server_test_connection` 已移除，服务地址内置于客户端。
其余已移除命令包括全部 `whisper_*`、`parakeet_*`、`builtin_ai_*`，以及 `open_models_folder`、`open_parakeet_models_folder`、
`get_ollama_models`, `pull_ollama_model`, `delete_ollama_model`, `get_ollama_model_context`, `get_openai_models`, `get_anthropic_models`,
`get_groq_models`, `get_openrouter_models`, `api_save_model_config`, `api_save_transcript_config`, `api_get_api_key`, `api_delete_api_key`,
`api_get_transcript_api_key`, `api_save_custom_openai_config`, `api_get_custom_openai_config`, `api_test_custom_openai_connection`,
`initialize_parallel_processor` 和其他 `parallel_*` 命令；数据库初始化命令（`check_first_launch`、`select_legacy_database_path`、
`detect_legacy_database`, `check_default_legacy_database`, `check_homebrew_database`, `import_and_initialize_database`,
`initialize_fresh_database`、`get_database_directory`、`open_database_folder`）；`test_backend_connection`、`debug_backend_connection`；
个人资料命令（`api_get_profile`、`api_save_profile`、`api_update_profile`）。

<a id="34-live-meeting-commands-p1--thin-wrappers-over-19110"></a>

### 3.4 实时会议命令（P1，对 §1.9 / §1.10 接口的轻量封装）

前端 `RealLiveMeetingApi` 调用 `server/live.rs` 中已实现的 Rust 封装。工厂通过 `NEXT_PUBLIC_LIVE_MEETING_DATA_SOURCE=mock|real` 选择数据源，默认 `real`；`mock` 仅作为显式演示模式。会控使用业务 REST / WS，摄像头与麦克风媒体使用已认证的 RTC SDK。屏幕共享的现行 SDK 通道和独立 WebRTC 兼容接口 路径见 §3.5；会议聊天和文件在 `room_chat_session` 授权后使用已认证的 IM SDK。

| 命令 | 参数（由 TS 以小驼峰命名传入） | 调用接口或行为 |
|---|---|---|
| `sched_list` | `{from?, to?}` | `GET /api/v1/scheduled-meetings`；两项都省略时管理全部预定 |
| `sched_create` | `{title?, startAt, durationMin, pwdEnabled?, pwd?, remind?, waitRoom?}` | `POST /api/v1/scheduled-meetings` |
| `sched_update` | `{id, title?, startAt, durationMin, pwdEnabled?, pwd?, remind?, waitRoom?}` | `PATCH /api/v1/scheduled-meetings/{id}` |
| `room_recording_chunk` | `{roomId, chunk: {chunkId, participantId, startTime, pcm, epoch}}` | `POST /api/v1/rooms/{roomId}/recording/chunks` |
| `room_recording_control` | `{roomId, action, epoch, participantId?, requestId?}` | `POST /api/v1/rooms/{roomId}/recording/control` |
| `room_recording_status` | `{meetingId}` | `GET /api/v1/meetings/{meetingId}/recording` |
| `room_recording_retry` | `{meetingId}` | `POST /api/v1/meetings/{meetingId}/recording/retry` |
| `sched_get` | `{id}` | `GET /api/v1/scheduled-meetings/{id}` |
| `sched_delete` | `{id}` | `DELETE /api/v1/scheduled-meetings/{id}` |
| `room_create` | `{title?, scheduledMeetingId?}` | `POST /api/v1/rooms` |
| `room_get_code` | `{code}` | `GET /api/v1/rooms?code=`（入会预检查） |
| `room_join` | `{code, name?, micOn, camOn, pwd?}` | `POST /api/v1/rooms/join`，随后打开下述房间 WS 连接 |
| `room_get` | `{roomId}` | `GET /api/v1/rooms/{roomId}` |
| `room_update_self` | `{roomId, micOn?, camOn?, handRaised?, screenSharing?}` | `POST /api/v1/rooms/{id}/participants/me` |
| `room_leave` | `{roomId}` | `POST /api/v1/rooms/{id}/leave` |
| `room_end` | `{roomId}` | `POST /api/v1/rooms/{id}/end` |
| `room_admit` / `room_deny` | `{roomId, participantId}` | `POST /api/v1/rooms/{id}/admit` / `deny` |
| `room_patch` | `{roomId, title?, pwdEnabled?, pwd?, waitRoom?}` | `PATCH /api/v1/rooms/{id}` |
| `room_mute_participant` | `{roomId, participantId, muted}` | `POST /api/v1/rooms/{id}/participants/{pid}/mute` |
| `room_approve_hand` | `{roomId, participantId}` | `POST /api/v1/rooms/{id}/participants/{pid}/approve-hand` |
| `room_remove_participant` | `{roomId, participantId}` | `POST /api/v1/rooms/{id}/participants/{pid}/remove` |
| `room_transfer_host` | `{roomId, participantId}` | `POST /api/v1/rooms/{id}/participants/{pid}/transfer-host` |
| `room_mute_all` | `{roomId}` | `POST /api/v1/rooms/{id}/mute-all` |
| `room_chat_session` | `{roomId}` | `POST /api/v1/rooms/{id}/chat-session`；后续消息和文件使用已认证的 IM SDK |
| `room_media_ticket` | `{roomId}` | `POST /api/v1/rooms/{id}/media` |
| `room_media_recover` | `{roomId, sessionId}` | `POST /api/v1/rooms/{id}/media/recover` |
| `room_signal_connect` | `{roomId}` | 幂等打开已认证的原生房间 WS 连接 |
| `room_signal_disconnect` | `{roomId}` | 仅断开信令，不离开或结束房间 |

事件 **`room-event`**：Rust 客户端为每个已加入房间维持一条 WS 连接（`GET(WS) /api/v1/rooms/{id}/ws`，§1.10），按既有 `transcript-update` 模式将消息原样转发给界面，由 `listen('room-event')` 接收。原生桥接层添加顶层 `roomId`，供页面切换后丢弃旧房间事件。命令失败时以 `{status, detail, code?}` 拒绝；TS 适配器将入会错误码（`not_found` / `not_started` / `ended` / `wrong_pwd` / `full`，§1.10）转换为 `LiveMeetingApiError`。HTTP 鉴权失败 401 和 WS 关闭码 4401 复用既有会话过期处理。

原生 `room-connection` 事件携带 `{roomId, state}`，状态为 `connecting|connected|reconnecting|removed`。短暂断线使用有上限的指数退避重试，并获取新的 `room_state`；聊天通过既有游标接口补齐。路由卸载时断开信令，离会或结束成功后停止连接。主持人专属操作失败不会关闭仍有效的连接；会话变化时停止旧连接。

当前服务端只允许已入会成员建立 WS。等候客户端每秒轮询一次既有会议号预检查接口，获准入会后再连接；等候记录消失表示已被拒绝，不会重新触发入会。获准前也不请求聊天。用户进入自己当天的预定时走 `room_join`，由该命令启动尚未开启的预定；通用 `room_get_code` 仍是只读预检查，启动前返回 404。

<a id="35-screen-sharing-2026-10-22"></a>

### 3.5 屏幕共享

本节先列出独立 WebRTC 兼容接口 点对点连接的兼容接口，再说明当前桌面端的 RTC SDK 发布方式。`Participant` 增加可空的 `screenShareId`。所有接口均要求调用者已认证且**实际入会**，拒绝等候中或已移除的成员。屏幕画面不经这些 REST 接口传输。

| 方法 | `/api/v1/rooms/{id}/screen-share` 下的相对路径 | 请求体 | 结果 |
|---|---|---|---|
| GET | 无后缀 | — | 点对点兼容配置：`{iceServers: RTCIceServer[]}`；可能含私有 TURN 凭证，不得写入日志 |
| POST | `/start` | — | `{sessionId: UUID}`；原子替换原共享者，并发出 `room_state` |
| POST | `/stop` | `{sessionId}` | 204；过期会话 ID 按幂等空操作处理 |
| POST | `/signal` | `{sessionId,targetId,kind,payload}` | 204；发送一条定向的 `screen_signal` WS 事件 |

`kind` 为 `ready|offer|answer|candidate`；`payload` 为 JSON 编码的 SDP / ICE 字符串，最多 65536 个字符。服务端填入 `senderId`，校验双方已加入同一房间且会话为当前共享会话，并限制方向：offer 只能由发布者发给观看者，answer / ready 只能由观看者发给发布者；candidate 只能在当前发布者与观看者之间传输。过期会话返回 409，方向错误返回 403，目标无效返回 404，负载过大返回 422。信令仅临时传递，不持久化，也不广播给其他成员。

WS 消息封装为 `{type:"screen_signal",ts,data:{sessionId,senderId,kind,payload}}`。观看者获取快照或重连后发送 ready，发布者响应 offer，观看者再响应 answer；提前到达的 candidate 会被缓冲。仅当前共享者可发布画面。新共享替换旧共享者，快照变化后所有客户端停止旧采集和旧连接。发布者最后一条 WS 连接关闭时，也会清除数据库共享标记。

Tauri 命令：`room_screen_config({roomId})`、`room_screen_start({roomId})`、`room_screen_stop({roomId,sessionId})`、`room_screen_signal({roomId,sessionId,targetId,kind,payload})`。所有 REST 请求仍通过原生 `ServerClient`，使用当前 Bearer 会话。旧 `participants/me.screenSharing` 契约保留兼容，但新客户端必须使用这些带会话版本的接口，避免旧停止请求中断新共享。上述共享机制本身均不提供屏幕音频或录制。

当前桌面端仅用 `/start` 和 `/stop` 管理共享归属。屏幕视频通过已有授权的 IM RTC 频道，使用 SDK `publishScreenTrack(track, {name: "screen:<sessionId>"})` 发布；接收端匹配已授权用户名、屏幕来源和发布名称。摄像头、麦克风仍是同一 RTC 服务中的独立轨道。当前兼容实现发布第二路 CAMERA 来源的视频，以保留名称标识业务屏幕，不要求公开的 IM 来源授权参数。SDK 和接收端据此区分屏幕与摄像头，既有视频与发布者校验继续生效。验收范围见[第二路视频说明](../docs/im-rtc-second-video.md)，接入设计见[SDK 与屏幕共享设计](../docs/im-rtc-screen-share.md)。`/signal`、GET 配置接口及原生命令名称继续供兼容接口使用，当前桌面屏幕实现不调用这些兼容接口。

点对点兼容配置：在 meeting_ms 中将 `OPENMEETING_SCREEN_SHARE_ICE_SERVERS` 设置为 ICE 服务器 JSON 数组。为空时仅使用本机或局域网直连候选地址；受限网络需要可达的 TURN。每个观看者分别占用发布者的一路上行。

<a id="recording-addendum"></a>

### 3.6 多人录制与预定管理

- `PATCH /api/v1/scheduled-meetings/{id}`：所有者可在无活动场次时修改，完整请求体同创建，会议号保持不变；已取消或当前场次进行中返回409。历史场次不阻止修改/软取消。重复取消幂等，取消后不可新建或加入，已生成记录保留。预定列表不再用meetingId判断预定是否有效，activeRoomId用于显示当前场次。
- `POST /api/v1/rooms/{id}/recording/chunks`：仅当前主持人，JSON `{chunkId, participantId, startTime, pcm, epoch}`；`pcm` 为 base64 的 16kHz 单声道 PCM16，单段最多 10 秒，startTime 为相对 room.startedAt 的秒数。参与者身份由服务端核验并快照；相同 chunkId 和内容重试幂等，不同内容返回 409。最大会议时长 12 小时。空数据/越界 422，非主持人 403，已结束 409。
- 分片接口和返回结构保持不变。分片仅写入私有 MinIO / OSS 对象，提交数据库索引后才返回 201；数据库不再保留 PCM 字段。对象存储未配置 / 不完整返回 503，上传失败返回 502，客户端保留原 chunkId 重试。已确认分片用 SHA-256、大小及身份、时间和 epoch 校验幂等。部署迁移清理旧数据库分片，不兼容旧分片存储策略；已生成的完整录音、转写及纪要不受影响。
- 会后处理按索引下载、校验分片，临时文件用后删除。录音、转写和总结全部成功后，分片按 `OPENMEETING_RECORDING_CHUNK_RETENTION_DAYS`（默认 3 天）保留；失败、取消、排队及运行中的任务不按期限清理。完整录音和分片前缀分离，清理分片不删除完整录音；删除会议后下一轮维护清理对应分片。未配置对象存储时，独立录音 / 文件导入原有本地存储行为不变。
- `POST /api/v1/rooms/{id}/end`：返回 `{meetingId, jobId}`。新房间自动录音，正常结束前主持人客户端补传最后分片，再持久化 `room_recording` 任务，合成 WAV → 按参会者音轨转写 → 自动生成总结。无音频、STT/LLM 未就绪标记失败，保留已得到的音频/转写，可经原任务重试恢复。没有录制数据时 `jobId=null`。

会议录制控制：

- 房间默认 `recording.active=true, epoch=1`，页面不显示录制/停止/申请/审批按钮。快照保持原形状供兼容接口使用，`requests` 为兼容字段。
- `POST /api/v1/rooms/{id}/recording/control` 仅保留房主 `start` 幂等激活历史活动房间，`epoch` 必须匹配，否则 409 `recording_changed`。`stop/request/approve/deny` 均返回 409 `automatic_recording`。
- 同一份会议录音由当前房主客户端采集并上传，普通参会者无需申请；重连和晚加入读取同一快照。采集时只有内存分片，上传成功后移出队列，不要求先生成完整客户端文件。
- 分段上传仅接受当前房主且 active/epoch 匹配的新分段；过期轮次为 409 `recording_inactive`，正文或 epoch 不同的同 ID 分段为 409 `recording_conflict`。上传、转交、结束在房间行锁下串行化；转交前客户端先补传，失败不丢失待传分片，转交成功后新房主继续采集。
- 会议结束及后台完成/失败，经已有持久 IM outbox 通知历史实际参会账号（含提前离会成员），负载是 meetingId 入口，不传音频文件。查看/下载同一条记录的详细约定见 [共享契约](meeting_ms/api/shared-records-contract.md)。
- `GET /api/v1/meetings/{id}/recording`：所有实际参会者及所属账号查询 `{status, error, jobId, message}`；无任务时 `status=none` 且 `jobId=null`，有任务时返回任务状态。`POST /api/v1/meetings/{id}/recording/retry` 仍限所属账号，仅 failed/cancelled 任务可重试，返回 202 + `Job`；无任务 404，运行中或已完成返回 409。状态由详情页轮询；部分处理失败时已保存录音仍可下载。
- 转写返回可选 `speaker`，稳定标号与参会者姓名组合，时间戳保持会议时间轴；分页、详情、UI 与总结输入均保留说话人。身份来自独立 RTC 音轨，不对单个麦克风内多人做声纹聚类。
- 提醒在已登录客户端全局挂载，每 15 秒检查未来十分钟的预定（覆盖跨天），按用户、预定 ID 与开始时间去重；支持休眠恢复、改期和取消；应用关闭时不发送。应用内提醒始终展示，系统通知失败不阻塞。

<a id="meeting-chat-storage-boundary"></a>

### 会议聊天存储边界

聊天授权与订阅绑定正式入会生命周期：普通入会、幂等重入和等候室批准时，后端在房间行锁内准备 IM 群成员授权，成功后再广播成员入会；等候室中的成员不授权。IM 暂不可用时保留可恢复的业务房间，由 `chat-session` 显式报错并允许重试。桌面和移动端在正式入会后立即请求 `chat-session`、刷新会话并持有消息订阅，关闭聊天面板或最小化会议不释放订阅；离会/结束后释放，重入重新建立。面板可见性只控制展示及已读，不决定是否收消息。

会议消息及历史使用 IM 私有群；附件使用 IM `group_file` 和原生 SDK 下载。业务 WS 不传递聊天。会中聊天和附件使用 IM SDK，不经业务房间聊天接口。结束会议会解散群，主动离会或被移除会撤销群成员资格。IM 失败时直接展示错误，不回退到本地存储。

媒体预览使用经过鉴权的原生缓存文件，上限 30 MB；`.txt/.md/.csv/.json/.log` 以转义后的纯文本展示，上限 1 MB。其他格式需要下载。关闭预览或组件卸载时释放预览缓存。权限、保留策略及 IM 能力边界见[会议 IM 聊天说明](../docs/meeting-im-chat.md)。
