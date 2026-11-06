# meeting_ms：会议域服务

会议服务使用端口 39107 和独立数据库 openmeeting_meeting，负责预定、房间、会中权限、录音、任务、转写结果、总结及记录读取。对外请求经 gateway_ms，转写推理由 stt_ms 执行。

## 运行与配置

部署、依赖和裸机配置见[服务端指南](../README.md)，开发源码自动重载见[Docker 开发指南](../docker_dev.md)。应用按 OPENMEETING_AUTO_MIGRATE 配置在启动时执行 Alembic 到 head；schema 与数据卷分别管理。

服务间 HTTP 统一通过 gateway_ms。配置 OPENMEETING_GATEWAY_MS_URL 和共享内部令牌；供应商出站经 OPENMEETING_EGRESS_PROXY_URL。数据库独占 meeting-postgres 容器及 meeting_pgdata 卷，见[数据库说明](../../docs/database-isolation.md)。

## 会议状态与媒体

业务 WS 管理房间状态和连接租约，RTC 会话由 IM 平台管理，聊天使用 IM 专属群。断连时限、清退和主持人收尾的完整规则只维护在[会议生命周期](../../docs/meeting-resilience.md#4-连接和成员生命周期)。当前信令使用进程内广播，按单实例部署。

## 录音与会后处理

房主客户端采集授权音轨，上传幂等 PCM16 分片。正常结束前补传剩余分片，服务端保存录音并处理转写、总结；失败保留可用结果，所属账号可重试。分片仅保存于 MinIO / OSS，PostgreSQL 保存对象索引、大小与 SHA-256；未配置对象存储返回 503，上传失败返回 502，不回退到数据库。本次迁移清理旧数据库分片并删除 `pcm` 字段，不保留旧策略。全部处理成功后默认保留分片 3 天；失败、取消和运行中的新任务继续保留，删除会议后下一轮维护清理分片。合成音频使用独立对象前缀，不受分片清理影响。说话人来自参会身份快照，不对单个麦克风中的多人做声纹聚类。配置及迁移边界见[对象存储指南](../../docs/object-storage.md#会中-pcm-分片)。

导入音频先落地并创建任务，转写完成后按配置转存 OSS；导入失败或取消会清理新建记录。重转写完成后整体替换转写结果。预处理在 [stt/audio.py](stt/audio.py) 中解码为 16 kHz 单声道并执行 VAD，按实现限制分段；任务编排见 [jobs/runner.py](jobs/runner.py)。

总结模板在数据库中维护，由服务端自动选择，选择失败时回退默认模板；客户端不提交提供方密钥或模板。具体参数和异步状态见[调用指南](../API_GUIDE.md#async-processing)。

## 接口入口

完整路径和返回字段见[API 契约](../API.md)，参会者读取与所属账号写权限见[共享读取契约](api/shared-records-contract.md)。内部接口包括用户会议统计、批量统计及用户数据删除，均验证内部服务令牌；管理端读取用户资料和连接状态通过内部网关调用 user_ms。
