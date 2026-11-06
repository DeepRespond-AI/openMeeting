# 原生系统通知验证

本页维护 Tauri 原生通知的人工检查，主要覆盖 macOS。IM 会议群提醒的筛选和角标策略见[通知策略](../../docs/meeting-im-capabilities.md)，自动化命令统一见[桌面测试](../TESTING.md#音频补丁与会议通知)。两者的触发条件不同，不能互相替代验收。

在实际桌面开发应用中执行以下 IPC；普通浏览器无法验证原生通知：

```javascript
import { invoke } from '@tauri-apps/api/core';
await invoke('test_notification_with_auto_consent'); // 初始化管理器、设置应用同意状态、请求系统权限并发送测试通知
await invoke('is_notification_system_ready'); // 检查管理器是否就绪
await invoke('get_notification_settings'); // 查看应用通知设置
await invoke('get_notification_stats'); // 查看通知统计
```

测试命令会修改应用内通知同意状态，应使用隔离开发身份。它会请求系统权限，不能自动绕过 OS 拒绝、免打扰、声音或系统通知设置。命令返回成功也不等于用户实际收到弹窗。

人工核验通知是否真实出现、应用名称和正文是否正确、声音与免打扰是否符合预期。拒绝权限后应能明确识别失败，再按系统支持的方式恢复权限；记录应用版本、macOS 版本、权限状态及可见结果，不预写“已通过”。

未显示时先检查系统设置中的应用通知权限和免打扰，再看应用日志、`get_system_dnd_status` 和上述管理器状态。手动请求权限可调用 `request_notification_permission`；需要分步初始化时调用 `initialize_notification_manager_manual`，再调用 `show_test_notification`。

命令实现见 [commands.rs](src/notifications/commands.rs)，录音通知仍需从真实录音入口触发。Windows/Linux 的 OS 展示及任务栏行为必须在各自系统单独验收。
