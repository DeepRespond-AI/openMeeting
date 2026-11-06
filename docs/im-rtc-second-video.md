# IM 第二视频轨道共享

## 范围与依据

屏幕使用 IM RTC 频道中的第二条普通 Camera 视频轨道传输，并由业务共享会话决定归属。底层来源名称不改变屏幕的业务语义；实现和补丁维护见[SDK 补丁](../frontend/patches/README.md)。这属于应用兼容扩展，不代表 IM 官方屏幕共享接口或共享音频已交付。

## 设计

- 保留公开 `ChannelHandle.publishScreenTrack(track,{name})` 和 `stopScreenShare()` 的业务语义。通过频道本身的 video/publisher 校验，使用平台原有授权和媒体连接，不放宽 subscriber/audio 频道权限。
- 线上媒体 source 为 `Camera`，名称严格为 `screen:<当前共享sessionId>`。SDK 将精确符合保留名的第二视频轨道归类成业务 `source: screen`，透传 publicationName；原生 ScreenShare 来源仍可识别，但当前实现不再用它发布。
- 接收端必须同时匹配已授权 IM 用户、最新业务共享 sessionId、轨道业务来源及远端标记。业务所有权未到、旧共享、其他用户伪造的名称都不能进入共享舞台。普通摄像头不进入该舞台。
- 摄像头独立按 publication 名称管理。不能直接调用仅按 Camera 来源选择第一条轨道的开关：屏幕先开时，第一条 Camera 来源实际上是屏幕。摄像头开关串行执行，只创建/静音/恢复真正摄像头，不动共享；停止共享只取消对应屏幕 publication。
- 屏幕停止、接管、迟到发布、取消选屏、发布失败、频道关闭及离会均清理采集与发布。RTC 重新发布会替换 publication，所以停止时按受控名称查找当前对象；晚加入订阅后也须匹配业务所有权。
- 不采集系统声音，不改变 IM 平台配置或存储 ACL。不将普通视频发布扩展成无授权跨频道传播。

## 验证入口

当前测试方法见[桌面媒体契约](../frontend/TESTING.md)和[E2E 脚本](../tests/e2e/README.md)。历史真实平台探测、页面夹具、截图及失败记录见本地验收记录（不随源码分发），不代替当前设备、系统选屏和公网容量验收。
