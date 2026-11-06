# 多人会议会后共享读取契约

会议开始自动启用录音（recording.active=true、epoch>=1）。房主采集音轨并按原有 recording/chunks 契约上传；客户端确认剩余分片上传后调用 end。兼容旧活动房间的 start 为幂等激活，stop/request/approve/deny 返回 409 automatic_recording，不再使用手动录制和审批。

`GET /meetings`、`GET /meetings/{id}`、metadata、transcripts、summary、notes、summary-language、recording、audio，以及 `/transcripts/search`，默认允许记录所属账号或持久实际参会身份读取。实际参会身份使用 RoomRecordingSpeaker，与当前是否仍在房间无关；等候室未获准成员及外部账号不可读取。单人录音没有房间参会身份，维持私人记录。无登录为 401，不可见记录为 404。

列表和 metadata 增加可选字段 `can_manage`，仅描述既有写权限；所有实际参会者的查看和音频下载能力相同，不增加共享配置。修改/删除/上传/重处理仍使用原有所属账号校验。

房间结束时创建同一条 Meeting，所有成员读取同一个 meetingId、同一份音频，不为成员复制录音。已上传的 PCM 分片由后端合成 WAV，`GET /meetings/{id}/audio` 复用本地文件响应或 OSS 签名跳转。未就绪/未收到音频为 404；客户端不得伪报下载成功。

复用 IM outbox 的 `openmeeting.meeting` version=1 通知：`meeting_ended` 表示记录已建立、后台可能仍在处理；`processing_completed` 表示全部处理成功；`processing_failed` 表示部分或全部处理失败，已有音频和转写仍可能可用。负载含 meetingId、roomId、title，不携带录音内容或下载签名。收件人为历史实际参会账号及记录所属账号，逐账号去重、事务落库并沿用原有失败重试。离开应用的成员重新登录后由 IM 恢复通知；记录列表也可重新请求，不以推送到达作为访问前提。

桌面在 IM 就绪时同时订阅 SDK 的实时事件与 notice 会话历史，弥补离线同步早于页面订阅的情况。使用 IM 的 `read_seq` 过滤已确认通知（服务通知不增加 `unread_count`）；每次补显最近最多三个会议的最新状态。点击记录入口将对应序号标记已读；仅在内存去重，不另建本地通知存储。
