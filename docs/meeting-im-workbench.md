# 会中设置、RTC 状态和 IM 工作台

当前工作台与会中设置分别使用业务接口和 IM SDK，验收范围见[功能状态](feature-status.md)。

## 会中设置

入口为会议工具栏「更多 → 会中设置」。主持人可修改主题、开启或关闭入会密码、替换密码、开启或关闭等候室；所有成员可设置本机是否播放会议声音。非主持人的房间设置只读。

调用链为 `RoomSettings → RoomProvider.updateSettings → LiveMeetingApi.updateRoom → room_patch → PATCH /rooms/{id}`。密码保持 4–6 位 ASCII 数字；已启用密码时留空表示保留当前密码。关闭密码会清除服务端密码。房间快照始终只包含 `pwdEnabled`，不回传或广播密码原文。修改只影响之后的新入会，不驱逐现有成员，也不自动放行已在等候室的成员。

后端修改前锁住房间行并校验当前主持人权限，成功后广播按接收者生成的 `room_state`。前端在保存失败时保留输入并展示服务端错误。Mock 提供相同设置入口，其密码仅保存在演示内存中。

## 发言人和媒体网络状态

当前安装的 `@deeprespond/im-web@1.0.0-alpha` 的 `ChannelHandle` 公开轨道与连接事件，但没有公开发言人或 `getStats` 接口。因此通过 `RtcTelemetry` 在媒体频道生命周期内观察原生 `RTCPeerConnection` 的创建，只对包含该频道实际音视频轨道的连接读取标准 `getStats()`。兼容层保留原生构造器原型和静态属性，离开频道时恢复构造器并清理定时器、引用和统计基线；不改动 SDK 包或私有字段。

- 每 500 ms 采样，利用 `trackIdentifier` / `mediaSourceId` 关联 RTC 轨道与 IM 用户。轨道或统计不公开时降级为未知。
- 发言人由实际 `audioLevel` 或相邻采样的音频能量/时长差计算，门限 0.025、保持 900 ms；静音、结束或被移除的轨道不能继续高亮。真实模式不依赖 Mock 的 `active_speaker` 事件。
- RTT 使用选中的 ICE candidate pair 或媒体接收反馈；丢包率使用相邻 RTP 计数差。上行按发送包数，下行按接收包数加丢包数计算；上行计数基线随新的 RTCP 接收反馈更新，避免将跨多个采样周期的丢包量除以单个周期的发包量。缺失计数不推断为零。
- RTT > 500 ms 或丢包 > 5% 为较差，RTT > 200 ms 或丢包 > 2% 为一般，其余有效测量为良好。无数据、连接断开或数据超过 5 s 显示未知；具体缺失指标显示 `—`。
- 角标支持点击打开 RTT/丢包详情。数据反映本机到媒体服务的发送/接收链路，不能宣称为远端成员自身的上网质量。共享传输见[第二路视频设计](im-rtc-second-video.md)，网络角标不能单独证明共享画面可读或流畅。

将来 SDK 提供正式统计接口后应移除构造器观察兼容层。是否能采到各项指标取决于 WebView/WebRTC 实现；这些指标的真实 RTC 采样需要单独验收。

## IM 工作台

所有 IM 操作通过已认证的 `IMContext` 客户端及 SDK 公共接口进行，由原有隐藏引擎维护鉴权和连接。不会新增保存 App Secret 的配置，也不会新增绕过引擎的服务端请求。

| 功能 | 接口与交互 |
|---|---|
| 新建单聊 | `conversations.openSingle(username)`，接收 IM 用户 ID；首次发送后跟随正式会话 key |
| 新建群聊 | `groups.create`，填写群名和成员 ID；每个邀请的失败保留可见，群已创建时禁止重复提交 |
| 联系人 | `friends.list/update/remove`，支持搜索、备注、删除、打开聊天 |
| 好友申请 | `friends.requests.send/received/accept/decline`，支持分页和变更通知刷新 |
| 群目录与邀请 | `groups.list`、`groups.invitations.received/accept/decline`，支持分页和变更通知刷新 |
| 群管理 | `groups.get/update/invite/removeMembers/setRole/transferOwner/mute/unmute/setMuteAll/leave/dismiss`；编辑群名、简介、公告，按角色展示操作，最终由服务端鉴权 |
| 会话管理 | 置顶/取消置顶、免打扰/恢复、移除会话（保留历史）、全部已读 |
| 富消息 | `messages.send` 的 image/video/file/voice/location；文件选择、语音录制与取消、坐标输入校验 |
| 附件 | `files.fetchBlob` 按需预览，`desktop.download({message})` 下载，显示进度并支持取消；预览使用受控 Blob URL，关闭页面释放资源 |
| 消息操作 | 重试、丢弃待发送消息、撤回、转发、点赞，失败信息保留在操作区域 |
| 布局与历史 | 窄视口在列表/聊天间切换；历史分页保留滚动位置；输入草稿在离开会话时保存 |

录音上限 120 s，达到上限取消采集，不自动发送。前端文件选择上限 100 MB、内存预览上限 30 MB，服务端和平台限制仍可进一步收紧。群成员批量操作的逐项结果单独展示，不将部分失败当作全部成功。权限变化、禁言或退出后的发送权限仍以 IM 服务端返回为准。

这些入口覆盖当前列出的工作台缺口，并不表示 SDK 的全部可选模块（例如通话、举报、公开群发现、入群审批工作流等）均已提供页面。真实 IM 服务必须启用对应模块和权限，媒体格式支持由 WebView 决定。这些入口的真实平台运行和视觉行为需要分别验收。
