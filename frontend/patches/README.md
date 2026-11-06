# IM Web SDK 补丁维护

本页记录锁定依赖的兼容补丁及升级时的移除条件，业务共享规则见[第二视频轨道设计](../../docs/im-rtc-second-video.md)。

`@deeprespond__im-web@1.0.0-alpha.patch` 增加 `ChannelHandle.setMicrophoneDevice`，
并转发到 LiveKit 的 `switchActiveDevice('audioinput', deviceId)`。
频道会话、授权及麦克风静音状态仍由 SDK 管理。不具备此能力的原生适配器会明确拒绝该操作。

补丁还会在 `setCameraEnabled` 后同步本地摄像头轨道。LiveKit 可能在保留发布对象的同时停止并替换原生视频轨道，
且不再次触发 `LocalTrackPublished`。补丁会移除已结束的轨道，并通过现有频道轨道事件转发当前有效轨道，
使重新打开摄像头时能够恢复本地预览。

切换设备时，LiveKit 会替换底层原生麦克风轨道，而不发布新轨道。补丁通过 SDK 现有的
`trackRemoved` / `track` 事件转发替换结果，使播放、录音及音量指示器始终绑定当前轨道。
切换失败时恢复原设备，并转发回滚期间创建的轨道。

补丁已注册到 `pnpm-workspace.yaml` 和 `pnpm-lock.yaml`，正常执行 pnpm 安装即可应用。
升级到提供公开设备选择 API 的 SDK 版本时，需要核对或移除此补丁。应用导入 ES 模块；
本补丁不修改 SDK 独立发布的 UMD 版本。

验证命令及夹具边界统一维护在[桌面测试说明](../TESTING.md#音频补丁与会议通知)。实体设备和 Tauri 会议仍需在目标机器上测试。

应用依赖补丁后需要重启 Next 开发服务；已打开会议中的 SDK 句柄会继续使用原来的类，直到窗口重新加载。
webpack 配置将界面和 Tauri 客户端固定到当前安装的 SDK，构建包检查会验证运行中的开发服务实际提供的脚本。

屏幕共享在同一 ES 模块补丁中扩展公开方法
`ChannelHandle.publishScreenTrack(track, {name})` 和 `stopScreenShare()`。
SDK 使用保留名称 `screen:<business-session-id>` 发布第二路 LiveKit `Camera` 来源。
该精确名称会映射为应用侧的 `source: screen`；`source` 和 `publicationName` 通过频道现有的 HTTP 成员授权关卡转发。
取消尚未完成的发布时会撤销发布；停止屏幕共享不会撤销摄像头发布。详见[第二路视频设计与验收](../../docs/im-rtc-second-video.md)。

提供方关闭 `adaptiveStream`：公开 API 向应用提供原始 MediaStreamTrack，HTML 播放不会调用
LiveKit Track.attach()，而 adaptiveStream 依赖该方法观察可见性。继续启用可能导致远端视频一直暂停。
Dynacast 保持启用；订阅带宽需单独做容量检查。共享媒体契约见[桌面测试说明](../TESTING.md#类型单元与故障契约)。

原 SCREEN_SHARE 路径被已部署平台拒绝，平台也未公开 IM 媒体来源授权配置。
此显式选择的兼容模式使用现有 video/publisher 授权，不更改权限或凭据。
它属于应用及 SDK 扩展，不代表 IM 官方提供了屏幕共享能力。
摄像头控件按名称选择非屏幕发布对象，不能直接取第一个 Camera 来源；先发布屏幕的会话不能因此静音或重启共享输入。
摄像头操作串行执行，断连后迟到的采集会被停止。RTC 完整重新发布后，停止屏幕共享时按保留名称查找替换后的发布对象，
不再持有旧发布对象中已清空的轨道。共享视频使用 maintain-resolution 策略，优先保证屏幕内容可读。
UMD 和非浏览器原生适配器不属于此 ES 模块补丁的范围。
