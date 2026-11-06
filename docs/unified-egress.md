# 服务统一出入网关

客户端业务入口、服务间 HTTP、外部平台回调及业务服务的外部请求均经 gateway_ms。各业务服务只连接自己的数据库容器；数据库连接不经过 HTTP 网关。客户端自身的 DeepRespond IM/RTC 媒体连接，以及经后端授权的对象存储直传/签名下载，不经过后端出站代理。

## 调用关系

| 流量 | 路径 |
| --- | --- |
| 客户端业务、管理端、IM 回调 | gateway_ms:39110 → 对应业务服务 |
| 安装包、完整录音及导入文件直传 | 经网关申请授权 → 客户端直接 PUT 到 OSS / MinIO → 经网关确认；见[对象存储](object-storage.md#客户端文件直传) |
| 服务间 HTTP | 业务服务 → gateway_ms:39110/internal/{service}/… → 目标服务 |
| IM 服务端 SDK、短信、OSS、LLM | user_ms / meeting_ms → gateway_ms:39111 → 平台 |
| MinIO S3 读写 | user_ms / meeting_ms → gateway_ms:39111 → minio:9000（精确域名、私有地址及端口白名单） |
| 云 ASR、WSS、模型下载 | stt_ms → gateway_ms:39111 → 平台 / 下载仓库 |
| 数据库 | 每个业务服务 → 自有 PostgreSQL；网关只读用户会话库 |

39111 是带认证的标准 HTTP forward proxy，支持 HTTP 和 CONNECT。HTTPS/WSS 由客户端与供应商端到端握手，网关不替换供应商 URL、不解密 TLS，SDK 签名、远端 Host 和证书验证保留。HTTPX、requests/oss2 使用显式代理；DashScope WebSocket、Hugging Face、ModelScope 使用同一认证代理环境。stt_ms 在导入下载 SDK 前设置代理，清除 NO_PROXY，并禁用不使用 Python HTTP 客户端的 Xet/hf_transfer 加速器。

Compose 中只有网关连接可出站的 `edge` 网络。user、meeting、stt 各自使用 `internal: true` 网络及独立数据库/卷，业务容器移除 NET_ADMIN 和 NET_RAW。即使新增 SDK 未接入代理，也不能直接访问外网或其他业务网络。新增非 HTTP 协议需要专门适配，不能通过增加业务容器的 edge 网络来绕过网关。Docker 管理权限不属于容器内网络限制的防护范围。

## 启动与配置

在 `server/.env` 设置原有管理密码、共享 INTERNAL_SERVICE_TOKEN、OPENMEETING_SECRET_KEY 和数据库密码，再填写实际供应商域名白名单：

```dotenv
OPENMEETING_EGRESS_ALLOWED_HOSTS='["im.example.com","llm.example.com","bucket.oss-cn-hangzhou.aliyuncs.com","huggingface.co","*.example-cdn.com"]'
OPENMEETING_EGRESS_ALLOWED_PORTS='[80,443]'
OPENMEETING_EGRESS_PRIVATE_HOSTS='[]'
```

上面是格式示例，不能作为完整生产白名单。OSS 须包含实际 bucket 域名，模型下载须包含仓库、重定向和 CDN 域名。代码默认白名单为空，所有外部目标均拒绝；根目录 `.env.example` 提供模型下载域名示例。精确主机和 `*.suffix` 受支持；后者不包含根域名。每次重定向的新连接重新校验目标。私有地址默认拒绝；确需内部 LLM 时将精确主机同时加入 allowed_hosts 与 private_hosts，端口也须允许。链路本地地址（包括云元数据）、多播和未指定地址始终拒绝。每次新建连接重新解析 DNS，校验全部结果后只在该连接内使用解析 IP，不缓存供应商 IP，也不配置固定 IP 映射。

### STT 模型下载的最小配置

不修改代理代码，不为 STT 增加直连外网网络。在现有 `OPENMEETING_EGRESS_ALLOWED_HOSTS` 中追加以下域名，保留已配置的 IM、短信、OSS、LLM 和云 ASR 域名：

```dotenv
OPENMEETING_EGRESS_ALLOWED_HOSTS='["modelscope.cn","*.modelscope.cn","huggingface.co","*.hf.co"]'
OPENMEETING_EGRESS_ALLOWED_PORTS='[80,443]'
OPENMEETING_EGRESS_PRIVATE_HOSTS='[]'
```

这些为 ModelScope、Hugging Face 和其 CDN 的域名规则，网关规则由业务服务共用，并非 STT 专属身份权限。镜像站需另加实际仓库及重定向域名。CDN 可能随地区、模型或供应商调整；以实际 SDK 重定向结果为准补充域名，不记录或固定其 IP。

如果本机 Clash 等代理的 DNS 返回 Fake-IP，原有非公网地址检查会返回 `403 Proxy Error`。仅在该开发环境中，使用已有精确域名例外，按实际下载请求确定主机：

```dotenv
OPENMEETING_EGRESS_PRIVATE_HOSTS='["modelscope.cn","www.modelscope.cn","cdn-lfs-cn-1.modelscope.cn","huggingface.co","us.aws.cdn.hf.co"]'
```

此配置不匹配通配符，且仍须命中 allowed_hosts 和 allowed_ports；它允许所列域名解析至非公网地址，不限定于 Fake-IP，生产使用正常公网 DNS 时保持空列表即可。不要增加 `extra_hosts`、改写 `/etc/hosts` 或启用全目标放开。

修改 `.env` 后，按[Docker 更新选择](../server/docker_dev.md#哪些修改需要额外操作)复用实际编排组合更新网关，保留现有数据及其他服务。STT 使用 `OPENMEETING_EGRESS_PROXY_URL=http://gateway_ms:39111`，只连接原有内部网络。

真实仓库采样检查见 [model-download-egress.py](../tests/e2e/model-download-egress.py)：在 STT 容器内使用实际代理配置，先验证确定性 403/407 失败路径，再请求模型配置和两家仓库的权重 CDN，每个响应仅读取最多 1 KiB；不保存权重、不关闭 TLS 校验。运行结果为逐步 JSON Lines，不代表完整模型下载或转写验收。

常规部署见[服务端指南](../server/README.md)，开发编排见[Docker 开发](../server/docker_dev.md)。39111 仅暴露于容器网络；不增加业务服务到网关的 Compose `depends_on`，避免网关等待服务就绪形成启动环。启动瞬间的出站失败由业务错误/重试路径处理。

裸机开发须给 gateway 设置 `OPENMEETING_EGRESS_ENABLED=true`，各业务服务默认使用 localhost:39111。只有显式 dev/test 且主动置空 EGRESS_PROXY_URL 时允许隔离契约测试直连；生产置空会报错，代理失败不会自动直连。裸机没有 Compose 网络强制隔离，应按部署环境另配防火墙。

## 认证、错误及运维

代理使用 Basic `openmeeting:<共享内部令牌>`，仅在内部网络传输；供应商 Authorization 与代理凭据分离。返回 407 表示代理认证失败，403 表示目标/端口/IP 被拒绝，502 表示 DNS/连接/超时失败，503 表示并发连接达到上限。CONNECT 建立后发生错误会断开隧道，供应商 HTTP 失败由业务服务正常处理。

网关记录方法、目标主机、端口及代理处理状态，不记录查询串、请求体和认证头。CONNECT 的 200 只说明隧道建立成功，不代表供应商业务返回成功。默认连接超时 10 秒、空闲超时 600 秒、最多 256 个已认证活跃连接；可用 gateway 的 EGRESS_CONNECT_TIMEOUT、EGRESS_IDLE_TIMEOUT、EGRESS_MAX_CONNECTIONS 配置调整。停止网关会关闭监听并取消活跃隧道。

统一网关成为出站依赖，生产 HA、负载容量及完整域名清单仍须专项验收。TLS 透传只控制目标与连接，不提供内容级审计。

## 验收

检查入口见[E2E 说明](../tests/e2e/README.md)。测试环境使用隔离数据库和明确供应商夹具；真实云端能力按目标部署单独验收。

参考：[HTTPX 代理](https://www.python-httpx.org/advanced/proxies/)、[websocket-client 代理](https://websocket-client.readthedocs.io/en/latest/url.html)、[Hugging Face 环境变量](https://huggingface.co/docs/huggingface_hub/main/package_reference/environment_variables)、[Compose internal 网络](https://docs.docker.com/reference/compose-file/networks/)。
