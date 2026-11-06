# 服务端运维指南

本文维护当前 Docker 部署的巡检、备份、恢复、更新和故障处理。部署与环境变量见[服务端说明](README.md)，数据库归属见[数据库说明](../docs/database-isolation.md)，开发重载见[Docker 开发指南](docker_dev.md)。

以下命令使用 PowerShell，在 `server/` 目录执行。备份与恢复命令是操作示例，尚未完成本项目的端到端恢复演练；上线前应按本文在隔离环境完成演练并记录结果。

## 运行检查

```powershell
docker compose ls # 查看正在运行的项目及实际使用的 Compose 文件
docker compose -p openmeeting-split -f docker-compose.yml ps -a # 查看七个常驻容器及迁移任务状态
docker compose -p openmeeting-split -f docker-compose.yml logs --tail 200 --since 30m gateway_ms meeting_ms # 查看最近半小时日志
Invoke-RestMethod 'http://127.0.0.1:39110/healthz' # 检查网关进程；端口按实际部署调整
docker system df # 查看 Docker 镜像、容器及数据卷占用
```

`/healthz` 返回进程状态与版本，不会全面检查数据库、OSS、IM、短信或推理是否可用。还需检查三个 PostgreSQL 的健康状态，在管理端查看模型状态和任务队列，并使用专用验收账号验证登录、创建会议和录音读取。

日常关注磁盘剩余空间、数据卷增长、容器重启次数、请求错误、任务积压、模型加载及备份失败。默认编排没有配置备份调度、集中日志、告警或日志容量上限；生产环境需通过宿主机定时任务、日志平台及监控系统配置。不要把生产日志长期保留为无限增长的默认 Docker 日志。

## 备份范围

| 内容 | 当前位置 | 恢复用途 |
|---|---|---|
| 用户数据库 | `user-postgres` / `openmeeting_user` | 账号、会话、短信及版本发布、IM 关联和用户域配置 |
| 会议数据库 | `meeting-postgres` / `openmeeting_meeting` | 会议、房间、日程、转写、总结、任务、录音索引及供应商配置 |
| 转写数据库 | `stt-postgres` / `openmeeting_stt` | 模型及云端转写运行配置 |
| 本地用户数据 | `user_data` 卷，user_ms 的 `/data` | 本地客户端安装包、未通过环境变量配置时的密钥文件 |
| 应用数据 | `appdata` 卷，meeting_ms/stt_ms 的 `/data` | 共享数据目录、密钥文件及其他运行文件 |
| 本地录音 | `audio` 卷，meeting_ms 的 `/data/audio` | 本地保存的录音和录音分片；不包含仅存 OSS 的对象 |
| 模型文件 | `models` 卷，stt_ms 的 `/data/models` | 可选；可以重新下载，但会延长恢复时间 |
| 部署配置与密钥 | 实际 `.env`、Compose 文件、反向代理和证书配置 | 保持连接、密文解密、认证和 HTTPS 配置一致 |
| OSS 对象 | 配置的 bucket/prefix | 云端录音和安装包；应单独开启版本保护或备份策略 |
| MinIO 对象 | `minio_data` 卷，minio 的 `/data` | 本地对象存储中的录音和安装包；须另行备份，下面原有本地卷归档命令不包含此卷 |
| IM 平台数据 | IM 服务商侧 | 聊天消息与附件等不在这三个业务库的备份内，按平台能力另行备份 |

数据库中的录音和安装包索引不等于文件备份。OSS 生命周期清理、用户删除和版本发布操作也会影响可恢复性，应与对象备份保留期协调。客户端尚未上传的内存音频不能靠服务器备份恢复。

必须保留原 `OPENMEETING_SECRET_KEY`，以及实际存在的 `secret_key` 文件；换一个密钥无法解密已有供应商凭据。密钥、`.env` 和数据库备份包含敏感数据，应加密保存到受限位置，不提交 Git。客户端更新签名私钥、Android 签名证书等不在服务端卷中，应按[桌面构建与签名](../frontend/README.md)和[移动端构建与签名](../mobile/README.md)单独保管。

## 创建一组一致的备份

单个 `pg_dump` 可以在数据库在线时产生一致快照，但三个库和文件存储没有统一快照事务。下面采用维护窗口：等待会议结束、录音上传完成和后台任务完成，再暂停四个应用服务，保留数据库运行，依次导出数据库与文件。备份期间也应暂停管理端操作和其他直写数据库/OSS 的程序。

先确认项目及实际 Compose 文件组合。下面是常规部署示例；使用 GPU、本地覆盖或开发编排时，按 `docker compose ls` 的结果补齐 `$ComposeArgs`，不要凭文件名猜测运行环境。

```powershell
$ComposeArgs = @('-p', 'openmeeting-split', '-f', 'docker-compose.yml') # 实际项目名及完整编排组合
$BackupDir = Join-Path 'E:\openmeeting-backups' (Get-Date -Format 'yyyyMMdd-HHmmss') # 仓库以外的备份目录；替换为实际磁盘
New-Item -ItemType Directory -Path $BackupDir -ErrorAction Stop | Out-Null # 每组备份使用新目录

function Invoke-Compose {
    & docker compose @ComposeArgs @args
    if ($LASTEXITCODE -ne 0) { throw "Compose 操作失败：$($args -join ' ')" }
} # PowerShell 5.1 也会在 Docker 命令失败时中止后续步骤

Invoke-Compose ps -a # 核对服务和项目；未完成核对前不要执行下面的停止操作
Copy-Item -LiteralPath '.env' -Destination (Join-Path $BackupDir '.env') -ErrorAction Stop # 保存实际配置和原密钥；不要输出内容
Copy-Item -LiteralPath 'docker-compose.yml' -Destination $BackupDir -ErrorAction Stop # 同时保存实际使用的其他覆盖文件
git rev-parse HEAD | Set-Content (Join-Path $BackupDir 'commit.txt') # 记录代码版本；未提交改动须另存补丁或发布源码
Invoke-Compose images --format json | Set-Content (Join-Path $BackupDir 'images.json') # 记录实际镜像；自建镜像应另存镜像制品

$Databases = @(
    @{ Service = 'user-postgres'; Database = 'openmeeting_user' },
    @{ Service = 'meeting-postgres'; Database = 'openmeeting_meeting' },
    @{ Service = 'stt-postgres'; Database = 'openmeeting_stt' }
) # 三个库必须一起备份
$AppServices = @('gateway_ms', 'user_ms', 'meeting_ms', 'stt_ms')
$RunningApps = @(Invoke-Compose ps --services --filter status=running | Where-Object { $_ -in $AppServices }) # 仅恢复原本运行的应用

try {
    if ($RunningApps.Count -gt 0) { Invoke-Compose stop -t 60 @RunningApps } # 进入维护窗口；确认已无写入
    foreach ($Item in $Databases) {
        Invoke-Compose exec -T $Item.Service pg_dump -U openmeeting -d $Item.Database -Fc -f /tmp/openmeeting-backup.dump # 在容器内生成二进制归档
        Invoke-Compose exec -T $Item.Service pg_restore --list /tmp/openmeeting-backup.dump | Out-Null # 检查归档目录可读，不等于恢复演练
        Invoke-Compose cp "$($Item.Service):/tmp/openmeeting-backup.dump" (Join-Path $BackupDir "$($Item.Database).dump") # 原样复制，避免 PowerShell 二进制重定向损坏
        Invoke-Compose exec -T $Item.Service rm -f /tmp/openmeeting-backup.dump # 仅删除本次生成的容器内临时归档
    }
    Invoke-Compose run --rm --no-deps -T --volume "${BackupDir}:/backup" --entrypoint tar user_ms -czf /backup/user_data.tar.gz -C /data . # 备份本地安装包及用户数据
    Invoke-Compose run --rm --no-deps -T --volume "${BackupDir}:/backup" --entrypoint tar meeting_ms --exclude=./audio --exclude=./models -czf /backup/appdata.tar.gz -C /data . # 备份共享应用数据，不重复包含子挂载
    Invoke-Compose run --rm --no-deps -T --volume "${BackupDir}:/backup" --entrypoint tar meeting_ms -czf /backup/audio.tar.gz -C /data/audio . # 备份本地录音卷
    # 可选：为缩短模型恢复时间，执行下一条；大模型会显著增加备份体积。
    # Invoke-Compose run --rm --no-deps -T --volume "${BackupDir}:/backup" --entrypoint tar stt_ms -czf /backup/models.tar.gz -C /data/models .
    Get-ChildItem -LiteralPath $BackupDir -File | Get-FileHash -Algorithm SHA256 | Select-Object @{Name='File';Expression={Split-Path $_.Path -Leaf}}, Hash | ConvertTo-Json | Set-Content (Join-Path $BackupDir 'sha256.json') # 记录完整性校验值
    '数据库与本地文件导出完成；OSS、IM 和异地副本仍需单独核对。' | Set-Content (Join-Path $BackupDir 'export-complete.txt') # 任一步失败则不会生成此标记
} finally {
    if ($RunningApps.Count -gt 0) { Invoke-Compose start @RunningApps } # 成功或失败都尝试恢复原本运行的应用，并检查启动结果
}
Invoke-Compose ps -a # 检查服务恢复情况；如停止失败或任务被中断，保留日志并人工处理
```

`run --entrypoint tar` 只启动一次性文件归档进程，挂载对应服务的数据卷，不启动应用或执行迁移。先确认这些服务镜像已存在，并为备份磁盘预留容量。不要直接复制运行中的 PostgreSQL 数据目录作为逻辑备份。

OSS 的版本、对象备份及 IM 平台数据需另行记录覆盖范围与时间点。完整备份还应保存部署覆盖文件、反向代理配置、对应镜像或可复现的源码与依赖，以及必要的镜像仓库访问方式。校验完成后再加密复制到另一台机器或对象存储；同一磁盘上的副本无法覆盖磁盘故障。

## 在隔离环境验证恢复

恢复应先在隔离宿主机或独立 Compose 项目中验证。下面只恢复到全新项目 `openmeeting-restorecheck`，不清空或覆盖 `openmeeting-split`。准备与备份相同代码版本及对应镜像，使用原配置和密钥；不要先启动业务服务创建表或运行迁移。

隔离项目只分离本地网络和命名卷。备份的 `.env` 仍可能指向生产 OSS、IM、短信或 LLM；启动应用前应通过网络限制、专用供应商资源及隔离配置阻止对生产外部系统的写入，关闭对外入口和真实短信发送。不能把恢复后的生产数据直接放进日常测试环境。

在新的 PowerShell 窗口重新定义 `Invoke-Compose`（与上一节相同），并设置以下变量。`$Databases` 也使用上一节的三项列表。

```powershell
$BackupDir = 'E:\openmeeting-backups\20261102-020000' # 替换为已经完成校验的一组备份
$ComposeArgs = @('-p', 'openmeeting-restorecheck', '--env-file', (Join-Path $BackupDir '.env'), '-f', 'docker-compose.yml') # 全新目标项目，使用匹配版本编排
Invoke-Compose ps -a # 确认目标项目不存在已有业务容器
docker volume ls --filter 'label=com.docker.compose.project=openmeeting-restorecheck' # 必须确认目标卷也是全新空卷；已有内容时换新项目名

$Manifest = Get-Content -LiteralPath (Join-Path $BackupDir 'sha256.json') -Raw | ConvertFrom-Json
foreach ($Entry in $Manifest) {
    if ((Get-FileHash -LiteralPath (Join-Path $BackupDir $Entry.File) -Algorithm SHA256).Hash -ne $Entry.Hash) { throw "备份校验失败：$($Entry.File)" }
} # 校验不通过就停止，不能继续恢复

Invoke-Compose up -d --wait user-postgres meeting-postgres stt-postgres # 只创建三个空数据库，不启动应用和迁移
foreach ($Item in $Databases) {
    Invoke-Compose cp (Join-Path $BackupDir "$($Item.Database).dump") "$($Item.Service):/tmp/openmeeting-restore.dump" # 将归档复制到目标数据库容器
    Invoke-Compose exec -T $Item.Service pg_restore -U openmeeting -d $Item.Database --no-owner --no-privileges --exit-on-error --single-transaction /tmp/openmeeting-restore.dump # 每个库在单事务中恢复，任一错误立即退出
    Invoke-Compose exec -T $Item.Service psql -U openmeeting -d $Item.Database -v ON_ERROR_STOP=1 -c 'SELECT version_num FROM alembic_version;' # 核对恢复的迁移版本
    Invoke-Compose exec -T $Item.Service rm -f /tmp/openmeeting-restore.dump # 删除目标容器中的本次临时归档
}
Invoke-Compose run --rm --no-deps -T --volume "${BackupDir}:/backup:ro" --entrypoint tar user_ms -xzf /backup/user_data.tar.gz -C /data # 恢复用户文件到新项目卷
Invoke-Compose run --rm --no-deps -T --volume "${BackupDir}:/backup:ro" --entrypoint tar meeting_ms -xzf /backup/appdata.tar.gz -C /data # 恢复应用数据与密钥文件
Invoke-Compose run --rm --no-deps -T --volume "${BackupDir}:/backup:ro" --entrypoint tar meeting_ms -xzf /backup/audio.tar.gz -C /data/audio # 恢复本地录音
# 如果备份包含模型，执行下一条；否则后续从已放行的模型仓库重新下载。
# Invoke-Compose run --rm --no-deps -T --volume "${BackupDir}:/backup:ro" --entrypoint tar stt_ms -xzf /backup/models.tar.gz -C /data/models
```

`pg_restore` 示例只适用于空库，未提供覆盖现有库的删除命令。当前 Compose 创建 `openmeeting` 角色；若额外创建了数据库角色、权限或扩展，须另外备份其定义并评估恢复，不能默认包含在单库归档中。

恢复后按以下顺序验收，并保存真实结果：

1. 对照备份记录核对三个库的关键表数量、抽样数据、迁移版本和本地文件校验值；不能只看 `pg_restore` 退出码。
2. 核对 OSS 的录音及安装包对象仍存在、能通过恢复后的索引读取；如需恢复对象版本，应对应同一备份时间点。
3. 保留原加密密钥，在限制外部写入的隔离环境中核验供应商配置可解密。供应商资源替换为验收配置后再检查外部连接。
4. 给隔离项目配置不同的宿主端口和正确覆盖文件，再启动匹配备份版本的应用；检查登录、历史会议、转写和总结读取、录音播放、安装包下载。模型未备份时记录重新下载与加载耗时。
5. 完成验证后停止隔离项目，保留测试结果与必要证据；不要执行针对生产项目的 `down -v`。真实灾难恢复需在业务入口切换前完成这些检查。

备份应记录导出起止时间、可恢复时间点、代码和镜像版本、文件范围、校验结果、异地复制及恢复耗时。根据可接受的数据丢失量确定备份频率，根据可接受的恢复时长确定模型和镜像保留策略。建议至少每日一组、发布前额外一组，定期恢复演练；这只是运维建议，仓库没有自动执行这些任务。若需要分钟级恢复，应另行建设 PostgreSQL WAL 归档及对象存储版本恢复体系，本文的定时逻辑备份不提供该能力。

## 发布更新与回退

本机构建并上传镜像、服务器只替换某个服务的操作顺序，见[单服务镜像更新流程](../docs/service-image-update.md)。

1. 确认待发布版本、客户端兼容性、实际 Compose 文件和外部服务配置；完成一组备份并核对恢复能力。
2. 安排维护窗口，先完成当前会议和上传，暂停新请求。保留原镜像及对应配置，使用发布版本源码/制品构建并更新应用，保留数据库与数据卷。
3. 使用与实际部署一致的 `-p`、`-f` 参数执行 `docker compose ... up -d --build`；应用服务启动时按 `OPENMEETING_AUTO_MIGRATE` 配置运行自己的 Alembic 迁移。`restart` 不会加载新镜像或新的 Compose 环境变量。
4. 检查数据库迁移、容器健康、日志与真实业务流程，通过后恢复入口；STT 首次加载模型可能需要额外时间。
5. 回退前评估新数据库结构是否兼容旧代码。仅切换镜像不保证能回退；不能兼容时需恢复整组备份和匹配的文件/对象版本，明确备份之后的数据处理方式。不要默认执行 `alembic downgrade` 或删除卷。

正式运行不附加 `docker-compose.dev.yml`。只修改某个服务时可按[开发指南的更新选择](docker_dev.md#哪些修改需要额外操作)判断是否需要构建，但正式发布仍需验证受影响的服务调用。

## 故障定位

| 现象 | 检查顺序 |
|---|---|
| 客户端连不上 | 网关容器及健康接口 → 实际端口、HTTPS/证书、防火墙 → 客户端构建内的网关地址 |
| 登录或供应商凭据解密失败 | 三个库健康及连接密码 → 原共享密钥是否一致、文件是否恢复 → 日志中的认证或解密错误 |
| 创建会议或会中状态异常 | meeting_ms 日志和数据库迁移 → 业务 WS → IM/RTC 平台连接；健康接口正常不代表媒体连接正常 |
| 模型下载 403、推理不可用 | 网关出站日志、模型仓库/CDN 域名白名单 → STT 模型目录容量、下载与加载状态 → GPU 驱动/显存 |
| 录音或安装包无法下载 | 数据库索引 → 本地文件/OSS 对象存在性 → OSS 凭据和权限 → 签名 URL/存储服务响应 |
| 磁盘持续增长 | 数据库卷、本地录音、安装包、模型、日志和备份分别统计；不要通过删除 PostgreSQL 卷或活跃录音腾空间 |

出站故障按[网关配置说明](../docs/unified-egress.md)处理，不固定供应商 IP。采集日志时记录时间、服务、版本及请求/会议标识，避免附带登录令牌、供应商密钥、完整录音或用户隐私。日志平台保留期和访问权限应与数据保留策略一致。

参考：[PostgreSQL 16 逻辑备份](https://www.postgresql.org/docs/16/backup-dump.html)、[pg_restore](https://www.postgresql.org/docs/16/app-pgrestore.html)、[Docker Compose 文件复制](https://docs.docker.com/reference/cli/docker/compose/cp/)。归档目录可读和哈希一致只能验证部分完整性，实际恢复及业务验证才能证明可用。
