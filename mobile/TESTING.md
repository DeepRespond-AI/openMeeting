# 移动端测试与代码生成

快速退房重入的 RTC 生命周期：从仓库根目录先运行 `node tests/e2e/mobile-rtc-release-race.mjs smoke`，再运行 `checks`、`ui` 和 `analyze`；仅断言全部通过后运行 `visual`。控制器使用真实 SDK 公共接口形状与取消令牌，仓储和媒体平台为显式夹具；页面回归实际打开退出确认弹窗，验证迟到连接释放、leaving 超时和重试恢复。产物位于 `.artifacts/mobile-rtc-release-race/`，逐张查看后用 `mobile-rtc-release-race-report.mjs` 从结果生成报告，不代表 Android/iOS 真机或真实 RTC 服务验收。

日常运行与打包见[移动端指南](README.md)，测试隔离和跨端证据要求见[测试总入口](../docs/testing/README.md)。以下专项命令按改动范围选择，不把夹具或构建结果记作真机通过。

## 聊天专项回归与生成步骤

会议聊天生命周期回归：`flutter test test/features/live_meeting/room_chat_lifecycle_test.dart`。运行真实 App、房间控制器/页面/聊天弹层和 SDK 消息列表/SQLite；验证正式入会即建立订阅、等候室获准后才建立、首次 503 自动重试、未开面板/关闭面板/最小化期间收消息、重入重新订阅及后台同步不标已读。身份、业务 API、媒体和消息 HTTP 为显式夹具，不等于真实平台投递。

Android：先设置 `OPENMEETING_ANDROID_DEBUG_SUFFIX=.roomchattest`，运行 `flutter test --no-uninstall integration_test/room_chat_lifecycle_test.dart -d <device-id> --dart-define=ROOM_CHAT_CAPTURE=true`。截图位于独立测试包 `code_cache/room-chat-false.png` 和 `room-chat-true.png`，导出后卸载该测试包。此修复须部署更新后的 meeting_ms，并重新构建移动客户端；旧安装包不会自动获得新的入会订阅逻辑。

消息首屏补齐回归：`flutter test test/core/im/first_chat_message_test.dart test/core/im/snapshot_stream_test.dart test/core/im/chat_message_actions_test.dart`。覆盖部分尾部缓存、仅末条预览、空缓存、连续收消息和重开，以及历史分页、网络失败、同步等待期间显示缓存和初始化时离开。使用已安装 IM SDK 的真实消息列表、补拉逻辑与 SQLite，HTTP 响应和身份为显式夹具；不代表真实桌面到手机的 IM 传输验收。

Android 复用同一组测试：`flutter test integration_test/first_chat_message_test.dart -d <device-id>`。先设置 `OPENMEETING_ANDROID_DEBUG_SUFFIX=.firstmessage` 使用独立调试包；可加 `--dart-define=FIRST_CHAT_CAPTURE=true`，将三种缓存场景的截图写入该包的临时目录。要在结束后导出截图，加 `--no-uninstall`；Android 上可通过 `adb -s <device-id> exec-out run-as cn.deeprespond.meeting.firstmessage cat code_cache/first-chat-tail.png` 读取（另有 preview、empty 场景），导出后卸载该测试包。不会登录个人账号。

会中聊天输入区使用附件、表情、输入、发送同一行布局，无停止播放入口；表情提供与桌面相同的三组 Unicode 内容。局部页面回归：`flutter test test/acceptance/meeting_chat_composer_ui_test.dart`，已有消息操作回归：`flutter test test/core/im/chat_message_actions_test.dart`。默认产物位于根目录 `.artifacts/mobile-meeting-chat-composer-20261029/`；独立失败冒烟后执行双视口断言，再截图并逐张检查，记录 `visual-reviews.json`、历史失败与清理结果，从仓库根目录运行 `node tests/e2e/mobile-meeting-chat-composer-report.mjs` 组装报告。页面的 SDK 投递、附件选择和上传是显式夹具，键盘占位为模拟，不能替代原生真机验收。

```powershell
flutter pub get
dart run tool/init_app_config.dart --server-url https://meeting.example.com # 首次生成三份配置；已有文件会保留
flutter test
dart analyze
```

当前仓库路径含中文目录，若 `flutter analyze` 遇到分析服务器路径问题，使用 `dart analyze`。

应用配置初始化回归：

```powershell
flutter test --no-pub test/tool/init_app_config_test.dart test/core/config/app_config_test.dart
```

首次克隆需先生成三份配置，Flutter 打包测试资源时依赖 `assets/config/`。生成脚本测试另在隔离目录验证完整模型解析、资源加载、环境差异、非法地址拒绝和已有配置保留；不连接示例网关，不改本机部署地址。

Android 签名初始化脚本回归（需要可用 JDK，必要时先配置 `JAVA_HOME`）：

```powershell
flutter test --no-pub test/tool/init_android_keystores_test.dart
```

该回归在隔离临时目录调用真实 `keytool`，验证三套密钥和密码独立、Gradle 相对路径可解析，并使用 JDK 加载私钥执行签名及验签；还覆盖重复执行不修改、部分配置拒绝覆盖和失败清理。不会重新生成现有发行密钥，也不代表 APK 安装升级或真机验收。

修改 Freezed、JSON 或 Riverpod 注解后运行 `dart run build_runner build`；修改文案后运行 `dart run tool/l10n.dart`。生成代码也需要提交。架构与新增功能的约定见 [DEVELOPMENT.md](DEVELOPMENT.md)。

## 结束与离会路由

在 `mobile/` 执行以下页面回归，使用生产路由、房间组件与仓储替身，覆盖双视口结束/离会、失败重试和弹层关闭；不等于真机或生产后端验收。

```powershell
$env:MEETING_RETURN_UI = '1' # 启用返回首页专项界面采集
flutter test test/acceptance/meeting_return_home_test.dart # 运行结束与离会路由回归
```

## 音视频超时和重试入口

```powershell
flutter test test/features/live_meeting/room_controller_test.dart test/features/live_meeting/room_retry_ui_test.dart # 控制器生命周期及真实会议页面的单一重试入口
```

用例覆盖重复点击、失败后重试、迟到结果和两种视口；仓储和 SDK 接入为明确夹具，不证明真实平台的超时根因已解决。当前状态与遗留缺口见[功能状态](../docs/feature-status.md)。

## 首页与自适应网格

```powershell
# mobile 目录
flutter test --no-pub test/features/live_meeting/home_grid_test.dart test/features/live_meeting/schedule_filter_test.dart test/core/router/route_guard_test.dart
$env:HOME_GRID_CAPTURE='1'
flutter test --no-pub test/acceptance/home_grid_ui_test.dart
```

Android 使用 `integration_test/home_grid_test.dart`、`.homegridtest` 独立开发包及 loopback `39352` 结果收集器。收集器复用 `tests/e2e/mobile-core-bridge.mjs`，通过 `OPENMEETING_E2E_DEVICE`、`OPENMEETING_E2E_BRIDGE_PORT`、`OPENMEETING_E2E_PACKAGE` 指定设备/端口/测试包。报告与截图写入 `.artifacts/mobile-home-grid-20261028/`，由 `tests/e2e/mobile-home-grid-report.mjs` 从结构化步骤、日志和实际视觉检查记录组装。
