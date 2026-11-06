# 深应会议 API 中文接入指南

本文解释“调用哪一层、按什么顺序调用、怎样理解返回值”。完整接口、字段简写和事件仍以 [API 契约](API.md) 为准；本文不引入新接口或新响应格式。

## 目录

- [接口入口与鉴权](#entry-points)
- [登录并读取会议记录](#quick-start)
- [历史记录、分页和部分匹配搜索](#history-search)
- [创建、加入和结束多人会议](#live-meetings)
- [录音、导入、转写和异步处理](#async-processing)
- [错误识别与恢复](#errors)
- [排查搜索 404 等联调问题](#troubleshooting)
- [按实现定位接口](#source-map)

<a id="entry-points"></a>

## 1. 接口入口与鉴权

### 1.1 先确定自己调用哪一层

| 调用方 | 使用的接口 | 凭证 / 说明 |
|---|---|---|
| Flutter、HTTP 调试工具 | 网关 `/api/v1/...` | 登录取得的 `Authorization: Bearer <token>`；公开接口除外 |
| Next.js 桌面 UI | Tauri `invoke(...)` 与原生事件 | Rust 保存会话并代发 HTTP；例如 `auth_login` 返回 `User`，不是 HTTP 的整个 `AuthResult` |
| 管理端 | 网关 `/admin/api/...` | 管理员登录产生的 `openmeeting_admin` cookie 或管理员 Bearer JWT |
| 后端微服务 | 网关 `/internal/{service}/...` | 内部令牌；不是客户端功能接口 |
| 聊天 / 音视频模块 | IM / RTC SDK | 先由业务 API 取得相应 ticket；不能直接使用业务 Bearer 当 ticket |

客户端只配置网关地址，例如 `http://127.0.0.1:39110`。完整请求是：

```text
http://127.0.0.1:39110 + /api/v1/meetings
```

不要把 `/api/v1` 同时放入 base URL 和接口路径。真机、模拟器与电脑上的 `127.0.0.1` 各自指向本机，联调地址必须能从运行客户端的设备到达；这影响连通性，不改变 API 路径或参数。

`X-User-ID` 等身份头由网关认证后注入，客户端不能用自行填写的身份头代替 Bearer。内部令牌、管理员 JWT、业务会话、IM ticket、RTC ticket 各有用途，不能混用。

### 1.2 请求和响应约定

| 项目 | 约定 |
|---|---|
| 普通 JSON 请求 | `Content-Type: application/json`；字段大小写完全按契约 |
| 音频分段 | 原始 PCM 字节，`application/octet-stream`，不是 JSON 或 multipart |
| 文件直传 | 先用业务 JSON 接口取得授权，再向对象存储发送原始文件 PUT，最后用业务接口确认；不得混用两种鉴权 |
| 代理导入文件 | 后端返回 `mode=proxy` 或旧服务不支持授权接口时，使用 `multipart/form-data`，字段 `file`、`title`、可选 `language` |
| 200 / 201 | 按接口解析对象或数组，没有统一的 `data` 包装层 |
| 202 | 请求已受理，后续需要查询任务或处理状态 |
| 204 | 没有响应正文，不再调用 JSON 解析 |
| 时间 | 通常为 UTC ISO-8601，界面显示时转本地时区；音频时间偏移以秒计 |
| 字段命名 | 例如记录的 `created_at` 与房间的 `startedAt` 都是原有契约，不做统一改名 |
| 可省略与可空 | `字段?` 表示可以不传，`null` 表示显式空值；两者语义按具体接口处理 |

<a id="quick-start"></a>

## 2. 登录并读取会议记录

以下为 API 联调示例，账号与密码是示意值，执行前替换为已注册的测试账号。密码登录不需要发送短信；验证码登录则先调用 `/api/v1/auth/sms/send`，并使用 `purpose=login`。

### 2.1 登录请求和字段

`POST /api/v1/auth/login`，公开接口。合法 JSON 请求示例：

```json
{
  "phone": "13800138000",
  "password": "ExamplePass123",
  "client": {
    "client_id": "api-guide-client",
    "hostname": "开发电脑",
    "os": "windows",
    "app_version": "2.0.0"
  }
}
```

密码与短信 `code` 二选一；建议用 `client` 提供稳定的实例标识及设备信息。完整字段、长度与认证响应定义见[鉴权契约](API.md#client-auth)，本节示例用于串联请求。

成功返回 `AuthResult`，包含 `token`、`expires_at`、`user`、`im_ticket`。后续业务 HTTP 请求使用 `token`；`im_ticket` 可能为 `null`，不代表账号登录失败。需要 IM 时通过 `POST /api/v1/im/ticket` 获取配置与一次性凭证。

### 2.2 PowerShell：登录、列表、搜索

适用于 Windows 终端。账号先替换成测试账号；不要将 `$auth` 整个打印到日志，因为其中含会话凭证。

```powershell
$baseUrl = 'http://127.0.0.1:39110'
$loginBody = @{
  phone = '13800138000'
  password = 'ExamplePass123'
  client = @{
    client_id = 'api-guide-client'
    hostname = '开发电脑'
    os = 'windows'
    app_version = '2.0.0'
  }
} | ConvertTo-Json -Depth 3
$auth = Invoke-RestMethod -Method Post -Uri "$baseUrl/api/v1/auth/login" `
  -ContentType 'application/json; charset=utf-8' `
  -Body ([System.Text.Encoding]::UTF8.GetBytes($loginBody))
$headers = @{ Authorization = "Bearer $($auth.token)" }
$meetings = Invoke-RestMethod -Uri "$baseUrl/api/v1/meetings" -Headers $headers
$query = [Uri]::EscapeDataString('预算')
$hits = Invoke-RestMethod -Uri "$baseUrl/api/v1/transcripts/search?q=$query" -Headers $headers
```

### 2.3 cURL：读取与搜索

以下是 Bash / Git Bash 写法；`TOKEN` 使用登录响应里的业务 `token`。Windows PowerShell 中的 `curl` 可能是别名，执行原生工具时使用 `curl.exe` 并采用对应的变量、换行语法。

```bash
BASE_URL='http://127.0.0.1:39110'
TOKEN='<填入登录响应中的 token>'
curl --fail-with-body "$BASE_URL/api/v1/meetings" \
  -H "Authorization: Bearer $TOKEN"
curl --fail-with-body --get "$BASE_URL/api/v1/transcripts/search" \
  -H "Authorization: Bearer $TOKEN" --data-urlencode 'q=预算'
```

<a id="history-search"></a>

## 3. 历史记录、分页和部分匹配搜索

### 3.1 记录列表与权限

`GET /api/v1/meetings` 返回当前用户可读取的记录数组，按创建时间倒序，**没有 limit/offset 分页参数**。示例：

```json
[
  {
    "id": "meeting-11111111-1111-4111-8111-111111111111",
    "title": "移动端预算评审",
    "created_at": "2026-10-29T02:00:00Z",
    "updated_at": "2026-10-29T02:30:00Z",
    "can_manage": false
  }
]
```

| 字段 | 类型 | 说明 |
|---|---|---|
| `id` | string | 会后记录 ID，详情、音频、转写、总结等接口使用它 |
| `title` | string | 记录当前标题，可能因用户改名或总结生成而更新 |
| `created_at` / `updated_at` | string | UTC ISO-8601 |
| `can_manage` | boolean | 是否为所属账号、拥有既有写权限；`false` 的实际参会者仍可读取和下载 |

只有实际入会身份才获得共享记录读取权限；单纯等候或其他账号不会获得权限。提前离会不撤销已经持久化的实际参会身份。单人录音仍是所属账号的私人记录。详情读取不可见记录返回 404；写操作仍校验所属账号，不能因为读得到就显示修改入口。详细规则见[共享记录契约](meeting_ms/api/shared-records-contract.md)。

### 3.2 转写片段分页

`GET /api/v1/meetings/{id}/transcripts?limit=100&offset=0`：

每次以本页实际返回数量累加 `offset`，按 `has_more` 判断是否继续，不能仅按本次页长推断结束。参数默认值及范围见[记录契约](API.md#client-records)。

分页结构示例：

```json
{
  "transcripts": [
    {
      "id": "22222222-2222-4222-8222-222222222222",
      "text": "我们讨论一下本季度预算。",
      "timestamp": "2026-10-29T02:01:00Z",
      "audio_start_time": 60.0,
      "audio_end_time": 64.5,
      "duration": 4.5,
      "speaker": "发言人1（张三）"
    }
  ],
  "total_count": 1,
  "has_more": false
}
```

`speaker`、`confidence` 等可选输出可能缺失，不应视为响应错误。音频起止时间相对录音时间轴，不能当作 UTC 日期。

### 3.3 搜索接口究竟搜索什么

`GET /api/v1/transcripts/search?q=预算` **只搜索转写正文**，不会在服务端搜索会议标题。

| 行为 | 实际约定 |
|---|---|
| `q` | 可省略；空字符串或全空白返回 200 + `[]`；客户端调用前应 trim |
| 匹配 | 不区分大小写的任意位置子串；非空查询保留传入空格，服务端不再自动 trim |
| `%` / `_` | 普通字符，不是 SQL 通配符；不支持正则或拼音检索 |
| 返回数量 | 最多 500 条片段命中，没有全局搜索分页或 `has_more` |
| 顺序 | 记录创建时间倒序，同一记录内按转写顺序 |
| 重复记录 | 多条片段可以属于同一场会议，需要调用方去重 |

搜索响应示例：

```json
[
  {
    "id": "meeting-11111111-1111-4111-8111-111111111111",
    "title": "移动端预算评审",
    "matchContext": "我们讨论一下本季度预算。",
    "timestamp": "2026-10-29T02:01:00Z"
  }
]
```

这里的 `id` 是**会议记录 ID**；片段分页响应的 `transcripts[].id` 才是转写片段 ID。`matchContext` 是命中附近的上下文，不是完整正文。

桌面和移动端的“历史会议搜索”还要合并标题：先对列表标题做 `trim + 不区分大小写的包含匹配`，再合并搜索接口命中的会议 ID，按照原列表顺序展示，每场会议一条。只有标题、没有转写的记录也应被找到。

接口成功返回 `[]` 表示内容没有命中；请求失败表示内容搜索未完成。已有标题结果时可继续展示，并说明搜索范围受限；不要把请求失败当作“没有记录”或“会议已被删除”。

<a id="live-meetings"></a>

## 4. 创建、加入和结束多人会议

### 4.1 四类标识不能混用

| 标识 | 来源与用途 |
|---|---|
| `ScheduledMeeting.id` | 预定管理 ID，传给预定详情 / 修改 / 取消 |
| `code` | 6 位字符串会议号，用于用户输入和入会预检 |
| `LiveRoom.id` / `roomId` | 一次实际活动场次，供会中 REST、WS、录制上传等使用 |
| `meetingId` | 结束后生成的记录 ID，供历史详情、转写、音频和总结使用 |

同一预定可以先后产生多个场次，每次场次有独立房间、IM 群、媒体授权和会后记录。`activeRoomId` 表示当前场次；`meetingId` 表示最近场次的记录。不要用“预定有 meetingId”判断它已经失效，也不要仅按日历时间推断房间正在进行。

### 4.2 推荐调用顺序

1. **创建或选择会议**：快速会议用 `POST /api/v1/rooms`；预定用 `POST /api/v1/scheduled-meetings`。创建预定不等于已经开始会议。
2. **入会预检**：`GET /api/v1/rooms?code=314159`。预定房主可收到只读 waiting 预览；其他人在房主启动前收到 `not_started`。
3. **实际加入**：`POST /api/v1/rooms/join`。检查 `JoinResult.state`，等候中的成员不应开始发布音视频。
4. **同步会中状态**：连接业务房间 WS。收到准入后通过 `POST /api/v1/rooms/{id}/media` 取得新媒体配置，再使用相应 SDK。
5. **聊天**：已加入成员调用 `POST /api/v1/rooms/{id}/chat-session` 获取私有群 `groupId`，之后的消息、表情文字、文件均走 IM SDK。
6. **结束或离开**：房主用 `POST /api/v1/rooms/{id}/end`，其他成员用 `POST /api/v1/rooms/{id}/leave`。结束返回 `meetingId` 和可空 `jobId`，后续按记录 ID 查询处理状态。

实际加入的请求体示例（JSON 字段使用 camelCase）：

```json
{
  "code": "314159",
  "name": "张三",
  "micOn": false,
  "camOn": false,
  "pwd": "1234"
}
```

`name` 可省略，默认使用登录用户名称；`micOn` / `camOn` 默认 false；不需要密码时省略 `pwd`。密码由会议配置决定，不是用户登录密码。错误分支应识别 `wrong_pwd`、`not_started`、`full` 等业务 `code`，不能仅凭 403 / 409 推断。

### 4.3 各通道的职责

| 通道 | 负责内容 | 不代表什么 |
|---|---|---|
| 业务 REST / 房间 WS | 准入、成员、静音、举手、房间设置、结束、状态快照 | 房间创建成功不等于音视频媒体已经连接 |
| IM SDK | 聊天消息、附件、群成员权限 | 业务房间 WS 不传聊天历史 |
| RTC SDK | 音视频和共享画面；发言人 / 网络质量由实际 RTC 事件或统计派生 | 仅改变 REST 的共享状态不能证明画面已送达 |

房间 WS 地址、心跳、事件和关闭码见 [§1.10](API.md#client-rooms)。IM 私有群在会议结束时解散；会中聊天和附件通过 IM SDK 接入。

房间设置 PATCH 支持局部更新；预定 PATCH 的请求体与创建结构一致，`startAt`、`durationMin` 必填。房间密码启用后，省略新密码保留当前密码；关闭 `pwdEnabled` 清除密码。活动房间快照不返回密码原文。

<a id="async-processing"></a>

## 5. 录音、导入、转写和异步处理

### 5.1 选择正确的上传接口

| 场景 | 接口和数据 | 后续 |
|---|---|---|
| 单人实时录音转写 | `POST /api/v1/meetings/{id}/segments`；16 kHz 单声道、PCM16 小端原始字节；query 为 `seq`、`start`、`end`、可选 `language` | 返回当段识别结果；空语音的 `id=null`，不新增片段 |
| 导入已有音频文件 | 先 `POST /api/v1/jobs/import/uploads` 申请直传授权，上传后调用同路径的 `/complete` | 确认成功返回 202 + `Job`，查询任务直到终态 |
| 保存完整音频 | 先 `POST /api/v1/meetings/{id}/audio/uploads` 申请直传授权，上传后调用同路径的 `/complete` | 登记完整音频，不等于触发导入转写任务 |
| 多人会议自动录音 | `POST /api/v1/rooms/{id}/recording/chunks`；base64 PCM 与 `chunkId`、`participantId`、`startTime`、`epoch` | 当前房主按音轨上传，结束后合成 / 转写 / 总结 |

完整文件的直传顺序如下，客户端和服务端均需要包含对应接口实现：

1. 流式计算源文件大小、SHA-256 和 MD5。向上表的 `/uploads` 业务接口提交 `file_name`、`size`、`sha256`、`md5`；导入另传 `title`、可选 `language`，完整录音可传已知 `duration`。业务请求携带登录 Bearer。
2. 若返回 `mode=direct`，使用独立 HTTP 连接向返回的 `url` 发送原始文件 PUT，携带返回的 `headers`。不附加业务 Bearer 或 Cookie，不跟随上传重定向；MinIO 返回的专用签名 Authorization 必须保留。
3. PUT 成功后，用业务 Bearer 向对应 `/uploads/complete` 提交 `{"ticket":"申请接口返回的票据"}`。只有确认接口成功后才报告上传完成；导入任务在确认阶段创建，申请授权和 PUT 本身不会启动转写。

仅当申请接口明确返回 `mode=proxy`，或旧服务的申请接口返回 404/405 时，改用原接口：导入为 `POST /api/v1/jobs/import` multipart，完整音频为 `PUT /api/v1/meetings/{id}/audio?filename=...` 原始字节。对象存储直传失败不得自动改为后端中转；保留本地文件供重试。文件上限、摘要格式、授权期限、确认错误及临时对象清理见[直传契约](API.md#客户端文件直传)和[对象存储指南](../docs/object-storage.md#客户端文件直传)。

实时分段 `seq` 与 `start` / `end` 都必须非负；`start` / `end` 以秒计。分段接口和会议录制分片的正文、时长上限、幂等键不同，不能互换：前者以 `(meeting_id, seq)` 去重；后者按 `chunkId` 和内容校验，并要求当前录制 epoch。完整约束见 [§1.2](API.md#client-transcription) 与[录制补充](API.md#recording-addendum)。

多人会议 PCM 分片需要 MinIO / OSS；收到 201 才能移除客户端待传队列。503 表示对象存储尚未配置，502 表示上传失败，应使用相同 `chunkId` 重试。会后任务全部成功后默认保留分片 3 天，再由后台清理；失败任务保留源分片供重试，完整录音独立保留。

### 5.2 “会议已结束”不等于“处理已完成”

新房间默认自动录音，但仍需要主持人客户端采集并上传音轨。正常结束前先补传剩余分片，再调用 end；服务端创建记录并返回可查询入口。没有收到音频、音频尚未就绪或处理失败，都不能展示为录音下载成功。

| 要跟踪的工作 | 查询接口 | 主要状态 / 行为 |
|---|---|---|
| 导入 / 重转写等 `Job` | `GET /api/v1/jobs/{id}` | `queued` / `running` / `completed` / `failed` / `cancelled`；可结合 progress / error |
| 会后录音处理 | `GET /api/v1/meetings/{id}/recording` | 返回 `status`、`error`、`jobId`、`message`；无任务为 `none`，否则是任务状态 |
| 总结生成 | `GET /api/v1/meetings/{id}/summary` | 独立状态，包含 `idle` / `processing` / `completed` / `failed` / `cancelled` / `error`；不能用 Job 状态枚举直接解析 |

录音任务失败或取消后，所属账号可调用 `POST /api/v1/meetings/{id}/recording/retry`，成功返回 **202 + Job**。任务不存在是 404；正在运行或已经完成时是 409。一次流程部分失败时，已经保存的音频或转写仍可能可以读取。

### 5.3 下载音频

`GET /api/v1/meetings/{id}/audio` 可能直接返回字节，也可能返回 302 到 OSS 签名 URL。跳转后的 OSS 请求**不携带业务 Authorization**；不要手工复制原始 Bearer 到另一个主机。支持 Range 的播放器需要保留相应请求语义。404 在该接口可能表示音频尚未产生或不存在，应结合 metadata / recording 状态展示，不直接判定会议记录不存在。

<a id="errors"></a>

## 6. 错误识别与恢复

先检查 HTTP 状态，再读取 `detail` 与可选 `code`。错误没有统一的成功包装；反向代理也可能产生非 JSON 正文，解析失败不应覆盖原始 HTTP 状态。

普通业务错误示例：

```json
{"detail": "会议不存在"}
```

会议域错误示例：

```json
{"detail": "入会密码错误", "code": "wrong_pwd"}
```

框架校验错误的典型结构（还可能有 `input`、`ctx` 等字段）：

```json
{
  "detail": [
    {"type": "greater_than_equal", "loc": ["query", "limit"], "msg": "Input should be greater than or equal to 1"}
  ]
}
```

| 状态 | 常见含义 | 调用方处理 |
|---|---|---|
| 400 | 密码 / 验证码错误、音频格式错误等 | 展示 detail；不要当作会话失效 |
| 401 | 受保护接口未登录、会话过期或被撤销 | 恢复登录；公开接口按自身约定处理 |
| 403 | 账号禁用、主持人权限不足、入会密码错误等 | 结合路径及 code；不是全部都要弹入会密码框 |
| 404 | 资源不可见、不存在、会议尚未开始、音频暂缺，或网关路由漏配 | 按请求路径和 code 区分，见下一节 |
| 409 | 已有活动任务、会议阶段冲突、录制 epoch 或幂等内容冲突等 | 刷新状态后决定恢复动作；不能一概解释为人数已满 |
| 413 | 音频分段或附件过大 | 调整数据大小，不重传相同超限正文 |
| 422 | 字段、范围、格式或业务参数校验失败 | 处理 detail 字符串或数组，修正请求 |
| 429 | 频率限制、密码临时锁定等 | 遵循 detail / 接口约定等待，不连续自动重试 |
| 502 / 503 | 下游不可达、STT / LLM / IM / 存储等能力暂不可用 | 区分依赖，保留草稿或已获得数据，允许合适的重试 |

GET 读请求可按客户端网络策略重试；写请求只有在契约明确幂等、且重用原始标识和内容时才应自动重试。不要给创建会议、发送短信、发起导入等操作统一套用无条件重试。`204` 是成功，不是“空响应错误”。

<a id="troubleshooting"></a>
<a id="known-gaps"></a>

## 7. 联调排查

| 现象 | 优先检查 |
|---|---|
| 列表能加载，搜索却返回“资源不存在” | 查看实际 URL；网关必须把 `/api/v1/transcripts` 转发到 meeting_ms。确认运行的网关已更新，单独热重载前端不会改变服务端路由 |
| 标题能搜到，内容没搜到 | 分别看标题本地过滤与内容接口状态；桌面控制台中的搜索错误不一定显示在页面上 |
| 桌面正常、移动端异常 | 核对两端实际连接的服务器、部署版本、登录账号和请求 URL；同一路由不会因 Flutter / Tauri 自动改变归属 |
| 所有受保护接口 401 | 检查业务 token 是否来自同一个服务环境，以及是否误用管理员 JWT / IM ticket |
| 预定显示有记录，但找不到当前活动会议 | 区分 `meetingId` 和 `activeRoomId`；历史记录不等于有活动场次 |
| 结束会议后没有可播放音频 | 查录制任务状态、是否收到分片、metadata.has_audio，再看音频接口，避免只凭结束请求成功判断 |
| 202 后页面立即显示成功 | 修正为已受理状态并查询具体任务；总结和录音状态不要混用 |

不带登录凭证对同一网关做只读诊断：

```bash
curl -i 'http://127.0.0.1:39110/api/v1/meetings'
curl -i 'http://127.0.0.1:39110/api/v1/transcripts/search?q=m'
```

在当前鉴权路由实现中，这两个受保护路径都应先要求登录，通常返回 401。若列表是 401、搜索却在鉴权前返回 404，应检查网关路由 / 部署版本，而不是解释为“搜索结果为空”。该诊断不证明账号权限和带凭证的搜索已经通过，后续仍需在测试账号下验证。

<a id="source-map"></a>

## 8. 按实现定位接口

| 主题 | 实现 / 契约 |
|---|---|
| 网关路由与身份注入 | [gateway.py](gateway_ms/api/gateway.py)、[鉴权](gateway_ms/auth/core.py) |
| 登录模型与返回字段 | [auth.py](user_ms/api/v1/auth.py) |
| 记录、分页、正文搜索 | [meetings.py](meeting_ms/api/v1/meetings.py) |
| 读写权限区分 | [deps.py](meeting_ms/api/deps.py)、[共享契约](meeting_ms/api/shared-records-contract.md) |
| 预定和会中 REST | [scheduled.py](meeting_ms/api/v1/scheduled.py)、[rooms.py](meeting_ms/api/v1/rooms.py) |
| 分段上传、录制与导入 | [transcribe.py](meeting_ms/api/v1/transcribe.py)、[recording.py](meeting_ms/api/v1/recording.py)、[jobs.py](meeting_ms/api/v1/jobs.py) |
| 客户端、管理端完整索引 | [API.md](API.md) |
| 原生调用参数和事件 | [Tauri 命令契约](API.md#tauri-api) |

各 FastAPI 服务默认提供 OpenAPI，但网关使用通用代理路由，其 `/openapi.json` 不会自动展开下游所有业务模型。不要将网关 Swagger 中只出现代理入口理解为业务接口不存在；下游模型可用于辅助核对，网关路由、权限、SDK 流程与异步行为仍需结合本指南及完整契约。
