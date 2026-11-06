# 每个业务服务独立 PostgreSQL

`server/docker-compose.yml` 启动三个 PostgreSQL 16 容器，各服务独占数据库实例及数据卷：

| 服务 | 数据库容器 | 数据库 | 独立数据卷 |
| --- | --- | --- | --- |
| user_ms | user-postgres | openmeeting_user | user_pgdata |
| meeting_ms | meeting-postgres | openmeeting_meeting | meeting_pgdata |
| stt_ms | stt-postgres | openmeeting_stt | stt_pgdata |

gateway_ms 沿用 user-postgres 校验会话，没有额外的业务数据库。各数据库不发布宿主端口。网关独占下游服务地址；user_ms、meeting_ms 配置 `OPENMEETING_GATEWAY_MS_URL=http://gateway_ms:39110`，服务间 HTTP 统一走网关。平台 SDK、OSS、短信、LLM、云 ASR 和模型下载通过 gateway_ms:39111 出站；三个业务服务各自处于内部网络，仅网关连接 edge。配置及白名单见[统一出入网关](unified-egress.md)。

全新部署沿用 [quickstart](../quickstart.md)。`POSTGRES_PASSWORD` 是兼容默认值，`USER_POSTGRES_PASSWORD`、`MEETING_POSTGRES_PASSWORD`、`STT_POSTGRES_PASSWORD` 可分别覆盖。连接串中的密码需符合 URL 编码要求。修改已有 PostgreSQL 卷的环境变量不会自动修改数据库密码，需要单独变更数据库角色密码。

## 隔离验收

日常数据备份、三个库的配套导出与恢复演练见[服务端运维指南](../server/OPERATIONS.md)。下面的验收数据库用于自动化测试，不是生产备份或灾备副本。

使用 `docker-compose.gateway-test.yml` 只给验收数据库发布回环端口 55451、55452、55453。必须加独立项目名，避免重建日常服务：

```powershell
$env:INTERNAL_SERVICE_TOKEN='compose-validation-only'
$env:OPENMEETING_ADMIN_PASSWORD='compose-validation-only'
$env:POSTGRES_PASSWORD='gateway-test-db'
docker compose -p openmeeting-gateway-acceptance -f docker-compose.yml -f docker-compose.gateway-test.yml up -d --wait user-postgres meeting-postgres stt-postgres
```

验收脚本见 [E2E 说明](../tests/e2e/README.md)。结束后仅停止此测试项目的三个数据库，不停止业务项目，不删除卷。
