# 对象存储：MinIO 与阿里云 OSS

会议录音（上传、导入及多人会议合成音频）、会中 PCM 分片和版本安装包共用对象存储配置。头像、聊天附件由 IM 文件服务管理，不受这里的配置控制。用户、会议、转写、纪要和分片索引仍保存在 PostgreSQL。

## 使用 Docker MinIO

在 `server/.env` 中填写；完整配置见 `.env.example`：

```dotenv
OPENMEETING_STORAGE_PROVIDER=minio
COMPOSE_PROFILES=minio
OPENMEETING_MINIO_ENDPOINT=http://minio:9000
OPENMEETING_MINIO_PUBLIC_ENDPOINT=http://服务器IP:39120
OPENMEETING_MINIO_REGION=us-east-1
OPENMEETING_MINIO_BUCKET=openmeeting
OPENMEETING_MINIO_ACCESS_KEY_ID=openmeeting
OPENMEETING_MINIO_ACCESS_KEY_SECRET=替换为独立的长随机密码
OPENMEETING_MINIO_PREFIX=openmeeting
```

`ENDPOINT` 供业务服务经网关代理访问，使用容器域名；`PUBLIC_ENDPOINT` 用于客户端直传和下载签名，必须能从所有参与联调的设备访问。跨设备优先使用局域网 IP 或统一域名，不能使用容器名；`10.0.2.2` 只适用于 Android 模拟器，不适合作为多端共用的签名地址。`localhost` 的 ADB 调试例外见下节。签名绑定主机、端口和路径，不能生成后再替换域名。

在原有出站规则中追加 `minio` 和端口 `9000`，保留其他已有规则：

```dotenv
OPENMEETING_EGRESS_ALLOWED_HOSTS='["minio","其他已有域名"]'
OPENMEETING_EGRESS_PRIVATE_HOSTS='["minio","其他已允许的私有域名"]'
OPENMEETING_EGRESS_ALLOWED_PORTS='[80,443,9000]'
```

在 `server/` 执行：

```powershell
docker compose up -d --build
docker compose ps
docker compose logs minio-init
```

默认 S3 API 为宿主机 `39120`，控制台为 `http://127.0.0.1:39121`，账号和密码就是上面的访问密钥。控制台只绑定本机。`minio-init` 幂等创建私有 Bucket，成功后退出 0，不清理已有文件，不开放匿名访问；首次上传前等待其完成。

MinIO 官方最新发布要求自行构建镜像。项目固定源码版本 `RELEASE.2025-10-15T17-29-55Z`，所需 Go 1.24.8 从官方获取并核验 SHA-256，见 [MinIO 发布说明](https://github.com/minio/minio/releases/tag/RELEASE.2025-10-15T17-29-55Z)。首次构建需要下载 Go 模块；网络失败时可重试，或使用实际网络允许的模块代理：

```powershell
docker compose build --build-arg GOPROXY=https://goproxy.cn,direct minio
docker compose up -d
```

Go 模块保留默认校验机制，不关闭 TLS 或校验数据库。管理端「对象存储」显示当前后端、环境变量锁定的参数和客户端下载地址；「测试连接」写入、读取并删除小对象。「音频存储」分别统计本地、MinIO、OSS 中的录音。

### 客户端联调地址

业务网关 39110 和 MinIO 文件入口 39120 是两条独立连接。业务登录正常不代表对象存储可达；完整录音、导入和安装包直传，以及签名下载都需要客户端能访问 `OPENMEETING_MINIO_PUBLIC_ENDPOINT`。

- 电脑与 Android 模拟器、真机共同联调时，将公网入口设为 `http://<开发电脑局域网IP>:39120`，确认各设备可达，并放行对应端口。业务地址仍可分别使用局域网网关、`10.0.2.2:39110` 或 ADB 映射。
- 仅通过 USB / ADB 调试时，可以保留模板的 `http://localhost:39120`。对每台目标设备（也包括采用此方案的模拟器）执行 `adb -s '<设备ID>' reverse tcp:39120 tcp:39120`；网关另需映射 `39110`。设备重启或 ADB 连接中断后重新执行映射。具体命令见[设备开发指南](../mobile/DEVICE_DEVELOPMENT.md#usb-真机开发与热重载)。

修改 `server/.env` 后按原 Compose 文件组合再次执行 `up -d`，让服务加载新入口，再重新申请上传授权或下载链接。不要修改已有签名 URL 的主机名来绕过地址配置；服务端内部 `OPENMEETING_MINIO_ENDPOINT` 保持 `http://minio:9000`。

## 阿里云就绪后切换

保留原有 `OPENMEETING_MINIO_*` 和 `COMPOSE_PROFILES=minio`，补齐阿里云配置：

```dotenv
OPENMEETING_STORAGE_PROVIDER=oss
OPENMEETING_OSS_ENDPOINT=oss-cn-hangzhou.aliyuncs.com
OPENMEETING_OSS_REGION=cn-hangzhou
OPENMEETING_OSS_BUCKET=实际Bucket
OPENMEETING_OSS_ACCESS_KEY_ID=实际访问密钥ID
OPENMEETING_OSS_ACCESS_KEY_SECRET=实际访问密钥Secret
OPENMEETING_OSS_PREFIX=openmeeting
```

把实际 `Bucket.oss-地域.aliyuncs.com` 域名追加到出站白名单，再应用环境变量：

```powershell
docker compose up -d --no-deps gateway_ms meeting_ms user_ms
```

切换只影响后续写入。已有文件按数据库记录的 `storage/audio_storage=local|oss|minio` 读取，旧配置和旧数据仍需保留。不会自动搬迁历史文件；完全下线 MinIO 前须先迁移对象并更新数据库引用。

### OSS 安装包下载域名

阿里云 OSS 默认公网域名会拒绝 APK 下载（`ApkDownloadForbidden`）。先为 Bucket 绑定自定义域名，完成 CNAME 解析并配置 HTTPS 证书，再在服务器 `.env` 添加：

```dotenv
OPENMEETING_OSS_DOWNLOAD_DOMAIN=https://download.example.com
```

替换为实际绑定的域名，只填写 HTTPS 源地址，不带对象路径、查询参数或账号密码。该配置由 `user_ms` 使用，SDK 通过 `is_cname=True` 生成 OSS 安装包的直传与下载链接，不对已签名 URL 替换主机；服务端读写和会议录音继续使用原 OSS Endpoint。未设置时保持默认域名行为，MinIO 和本地存储不受影响。

首次启用需构建包含该功能的 `user_ms` 镜像；后续修改域名只需重新创建 `user_ms` 容器。离线部署需重新打包，使用新包生成的 `docker-compose.offline.json`，使这个环境变量能够传入容器；只编辑旧部署包的 `.env` 不会自动新增变量映射。无需数据库迁移，也无需重新上传已有安装包。

绑定步骤见[阿里云自定义域名说明](https://help.aliyun.com/zh/oss/user-guide/access-buckets-via-custom-domain-names)。直接访问私有对象需要有效签名，域名根路径返回 AccessDenied 不能单独作为下载失败的判断依据。

| 存储类型 | 后续写入行为 |
|---|---|
| `minio` | MinIO；配置不完整返回 503，不静默改用本地 |
| `oss` | 阿里云 OSS；配置不完整返回 503 |
| `local` | 原有服务器数据卷，旧对象仍按原后端读取 |
| `auto` | 兼容旧行为：OSS 完整则使用，否则本地 |

`user_ms` 经认证内部接口取得配置，缓存最多 30 秒；重建应用容器立即应用新配置。旧 `oss`、`oss_ready` 字段和模块名为兼容调用保留，实际类型以 `provider` 为准。

## 客户端文件直传

| 文件 | 当前上传路径 |
|---|---|
| 管理端发布的安装包 | 管理端申请授权 → 浏览器直接 PUT 到 OSS / MinIO → 后端确认入库 |
| 桌面、移动端的完整录音与导入文件 | 客户端申请授权 → 直接 PUT 到 OSS / MinIO → 后端登记音频或创建导入任务 |
| 会中 PCM 分片、实时转写片段 | 客户端 → 网关 → meeting_ms；保留原实时处理路径 |
| 服务端合成的录音 | meeting_ms 合成后经网关出站代理上传对象存储 |

直传文件内容不经过业务服务，不产生业务服务的上传临时副本。后端仍检查登录态和资源所有权，为单个临时对象签发授权；客户端流式计算 SHA-256、MD5，存储校验 Content-MD5，MinIO 同时校验签名的 SHA-256。确认时后端核对对象大小和已签名摘要元数据，按 ETag 条件在同一 Bucket 内复制到独立最终对象，再提交数据库并删除临时对象。文件内容的复制发生在存储内部。后端不会为计算摘要重新下载整个文件；SHA-256 来自客户端，不能代替安装包发布者的可信签名。

上传授权不包含 AccessKeySecret。OSS 使用签名 URL；MinIO 使用 SDK 生成的 `AWS4-HMAC-SHA256` 单请求签名头，不能把它替换成业务 Bearer。客户端上传使用独立连接，不带业务 Bearer / Cookie、不跟随上传重定向；确认成功后才报告 100%。失败保留客户端源文件供重试。客户端本地录音的保留与清理仍由原录音队列策略管理。

单文件支持 1 字节至 2 GiB；OSS 上传授权为 1 小时，MinIO 单请求签名须在 15 分钟内发起，`expires_in` 以接口实际返回为准。确认票据有效期为 1 小时。当前使用整文件 PUT，不提供分片续传；超时或授权过期需重新申请上传。本地存储明确返回 `mode=proxy`，旧服务没有直传接口时兼容原上传方式；对象存储直传失败不自动把大文件重新中转到业务服务器。

导入任务需要解码和转写，会在处理阶段下载音频到任务临时目录，结束时按原任务逻辑清理；服务端合成录音仍需要合成空间。完整录音由客户端随授权请求提交已知采集时长，确认后登记；未提供时沿用已登记时长，不再为探测时长下载整个文件。导入任务解码后更新时长。

### 浏览器跨域与对象清理

OSS Bucket 为管理端的实际源地址添加 CORS 规则，例如 `https://www.example.com`；开发管理端再单独添加实际开发源地址（协议、域名、端口必须一致）。允许方法 `PUT`，允许请求头 `Content-Type`、`Content-MD5`、`x-oss-*`。如另有浏览器读取对象的功能，按需保留 `GET/HEAD` 规则，不要覆盖已有规则。HTTPS 管理端必须使用 HTTPS 存储地址。规则设置参见 [OSS CORS](https://www.alibabacloud.com/help/en/oss/user-guide/configure-cross-origin-resource-sharing/)；对象内容校验参见 [PutObject](https://www.alibabacloud.com/help/en/oss/developer-reference/putobject)。

MinIO 的公网入口也须允许管理端源地址的 PUT 预检与 `Content-Type`、`Content-MD5`、`Authorization`、`x-amz-*` 请求头。项目镜像使用 MinIO 的 CORS 行为；经过 Nginx 等反代时须透传这些请求头，并允许大文件 PUT，不能重写已签名的 Host / 路径。桌面原生和移动原生上传不受浏览器 CORS 限制，仍须能够访问公网存储入口。

给 `<prefix>/.pending-uploads/` 单独设置生命周期过期规则，例如 2 天后清理未完成确认的上传；前缀需包含实际配置值。正常确认后立即删除临时对象，异常中断留下的对象由此规则兜底。不要把该规则应用到 `audio/`、`releases/`、`room-recordings/`。确认复制后、数据库提交前进程崩溃可能留下最终孤立对象，需对照数据库引用后清理。Bucket 开启版本控制时，还须配置该临时前缀的历史版本清理，避免历史版本继续占用空间。

### 应用代码

重建并更新 `user_ms`、`meeting_ms`、`gateway_ms`（包含管理网页），桌面和移动端需构建包含直传调用的新版。配置存储公网入口、跨域与临时前缀生命周期后再做目标环境验收。没有新增数据库表或迁移。接口见 [API 直传契约](../server/API.md#客户端文件直传)。

## 会中 PCM 分片

- 分片仅保存到私有对象前缀 `<prefix>/room-recordings/<room_id>/`。数据库记录对象后端、key、大小、SHA-256 和参会者时间信息，不再保留 `pcm` 字段。写入对象成功且数据库提交后才向客户端确认；失败不会静默写回数据库。
- 这里的 `local` / 未配置 OSS 的 `auto` 仅适用于完整录音和安装包；多人会议新分片要求 MinIO / OSS，否则接口返回 503。上传失败返回 502，客户端使用原 `chunkId` 重试。
- 会后按分片下载并校验，单片最多 320KB。合成从临时磁盘文件按时间窗口读取，不把整场 PCM 装入内存；临时目录在成功或失败退出时删除。仍需预留容纳各音轨原始分片及合成 WAV 的临时磁盘空间。
- 数据库迁移 `0012_recording_chunk_objects.py` 按当前部署约定清理全部旧 PCM 分片、删除 `pcm` 字段、添加必填对象索引；不保留旧分片读取、回退和自动搬迁代码。仅依赖旧分片的未完成处理任务标记为失败，已有完整录音可用原有重新转写流程处理。已生成的完整录音、转写、纪要不删除。升级前应结束旧会议，尚未合成的旧分片无法在升级后恢复。数据库物理体积不一定立即缩小，常规 VACUUM 会回收可复用空间。
- `OPENMEETING_RECORDING_CHUNK_RETENTION_DAYS=3`：录音、转写及总结全部完成后，默认保留源分片 3 天。设为 0 时，下一轮维护即可清理。失败、取消、排队或运行中的任务继续保留源分片，不能简单按上传时间统一删除。
- `OPENMEETING_RECORDING_CHUNK_MAINTENANCE_INTERVAL_SECONDS=60`：维护间隔。每轮最多处理 100 个到期 / 已删除会议的分片；对象删除成功后标记 `purged_at`，保留轻量索引供追溯。删除失败保留索引，后续重试。任务与文件读取使用记录中的后端，切换到 OSS 后仍须保留历史 MinIO 配置。
- 完整录音位于独立的 `audio/` 前缀；清理 `room-recordings/` 不影响完整录音、转写或纪要。删除会议后，分片在下一轮维护清理。
- 极端情况下，对象上传成功、数据库提交前进程崩溃可能留下无引用对象；同分片同内容重试复用同一 key。不要给整个分片前缀设置短期统一过期规则，以免删除失败任务唯一的恢复源；孤立对象应先对照数据库引用排查再清理。

应用此次代码：在 `server/` 执行 `docker compose up -d --build meeting_ms`，服务启动会自动应用数据库迁移。不要删除数据库卷。此迁移不可逆，回退需要恢复部署前的数据库备份。

## 数据、网络与备份

- Bucket 私有，客户端使用限时签名 URL 下载，支持 Range；业务 Authorization 不转发到存储服务。
- 业务容器没有加入存储网络，SDK 继续经 `gateway_ms:39111`。网关连接内部存储网络；MinIO 另有供预签名下载的基础设施网络和发布端口。
- 本地录音转存成功且数据库提交后才删除本地文件。多人会议转存失败保留本地录音和 PCM 分片，后台处理可重试；导入的后台转存失败保留本地副本并记录错误。
- MinIO 数据在 `minio_data` 卷中，物理上仍占 Docker 宿主机磁盘，不是异地备份。须备份 PostgreSQL、MinIO 卷、原有本地卷和 `.env` 密钥；OSS 对象另行备份。
- 更新配置不需要 `down`，不要用 `docker compose down -v` 更新，它会删除数据卷。
- 本地录音迁移先运行 `docker compose exec meeting_ms python -m meeting_ms.scripts.migrate_audio_to_oss --dry-run`，确认后去掉 `--dry-run`。兼容命令迁往当前后端，不迁移安装包，也不执行 MinIO → OSS 历史对象迁移。

## 验证入口

`uv run pytest tests/test_minio_storage.py tests/test_object_storage.py` 检查适配及配置契约；需要数据库的会议、录音和版本测试必须使用隔离数据库。

`tests/e2e/minio-roundtrip.py` 使用临时私有 Bucket、真实出站代理、服务路由和独立 PostgreSQL，验证录音、Range、EXE、错误凭据、缺失配置、多人合成录音及切换后的读取和删除。音频、EXE 为合成夹具，只证明存储能力，不代表真实 RTC、模型或自动更新安装验收。
