# 深应会议 — 移动端（Flutter）

Android 和 iOS 客户端，业务 API 由 `../server` 提供。项目架构与代码规范见 [DEVELOPMENT.md](DEVELOPMENT.md)，多人会议和 IM 见 [Flutter 开发文档](LIVE_MEETING_DEVELOPMENT.md)。

- Dart 包名：`meeting`
- Android applicationId / iOS Bundle ID：`cn.deeprespond.meeting`
- 技术栈：Flutter、Riverpod、go_router、Dio

## 环境准备与开发运行

使用与[持续集成](../docs/continuous-integration.md#检查范围)一致的 Flutter 3.47.7（Dart 3.13.5）和 JDK 17。`pubspec.yaml` 要求 Dart `^3.13.5`；先确认 `flutter --version`，再安装锁定依赖。

Android SDK/JDK 准备、设备连接、网关地址、Flutter 启动与热重载命令统一见[设备开发指南](DEVICE_DEVELOPMENT.md)；Windows 三个独立模拟器联调见[三客户端开发](DEV_MULTI.md)。iOS 开发需要 macOS 和 Xcode，内录扩展的真机签名要求见[内录说明](SYSTEM_AUDIO_CAPTURE.md#ios真机replaykit-直播扩展)。

首次克隆后，在运行、测试或打包 Flutter 前先按下方[构建准备](#构建)生成 `assets/config/`。整个目录为本机部署配置，不提交 Git。

首次原生构建时，SQLite 的构建钩子也可能从 GitHub Releases 下载对应平台的原生库；`flutter pub get` 成功不代表这些原生依赖已经下载完成。下载中断时检查开发终端的网络与代理后重试，可以复用同一锁定依赖版本的已校验缓存。

## 测试与代码生成

完整命令、专项回归及代码生成步骤统一维护在[移动端测试说明](TESTING.md)。测试使用的 SDK/仓储夹具和原生设备边界分别记录，修改生成代码后需一并提交。

## 构建

以下命令在 `mobile/` 目录执行。首次生成本地应用配置，将示例地址换成设备可访问的实际 HTTPS 网关：

```powershell
dart run tool/init_app_config.dart --server-url https://meeting.example.com
```

默认从不含部署地址的[公共参数模板](tool/templates/app_config.json)生成 dev/test/prod 三份 JSON，初始网关均设为传入地址。也可分别生成：

```powershell
dart run tool/init_app_config.dart --env dev --server-url http://10.0.2.2:39110
dart run tool/init_app_config.dart --env test --server-url https://test-meeting.example.com
dart run tool/init_app_config.dart --env prod --server-url https://meeting.example.com
```

只有 dev 支持 HTTP 网关；test/prod 要求 HTTPS。已有文件会跳过且不覆盖，后续修改对应本地 JSON 的 `defaultServerUrl` 或其他参数即可。不同环境的选择与默认差异：

| 构建参数 | 本机配置文件 | 默认差异 |
|---|---|---|
| `APP_ENV=dev` | `assets/config/app_config.dev.json` | 显示开发验证码，每 5 分钟检查更新 |
| `APP_ENV=test` | `assets/config/app_config.test.json` | 关闭开发验证码展示，每 5 分钟检查更新 |
| `APP_ENV=prod` | `assets/config/app_config.prod.json` | 关闭开发验证码展示，每 240 分钟检查更新 |

`assets/config/` 整个目录（含个人备份）均被 Git 忽略，现有本机配置可继续使用。公共模板维护通用参数，不包含部署域名和凭据；JSON 会打包进客户端，不要在其中存放服务端密钥或访问令牌。

配置随安装包打包，修改后需要重新构建并安装。若命令额外传入 `--dart-define=OPENMEETING_SERVER_URL=...`，该地址优先于配置文件。

首次创建自己的 Android release 发行版时，先初始化本地签名文件（默认生成 dev/test/prod 三套）：

release 构建缺少所选环境的签名配置时会明确失败，不会使用 debug 密钥代替；普通 debug 开发和 CI 构建不需要生产密钥。

```powershell
dart run tool/init_android_keystores.dart
```

脚本生成 `android/keystores/<环境>/meeting-<环境>.jks` 和 `key.properties`，均已被 Git 忽略。已有完整签名配置会保留，部分配置会拒绝覆盖。已有发行版应恢复原密钥以保持覆盖升级；JDK 路径、单环境生成及证书主体设置见 [Android 签名说明](android/keystores/README.md#一条命令初始化)。debug 包继续使用 Android 默认调试签名，不依赖此初始化步骤。

发布新版供用户升级前，递增 [pubspec.yaml](pubspec.yaml) 中的版本号和构建号。当前版本为：

```yaml
version: 0.1.1+2
```

`0.1.1` 是显示版本，`2` 是构建号，对应 Android 的 `versionCode`。dev、test 和 prod 构建共用这份版本配置；管理端发布时填写与安装包一致的版本号和构建号。日常重复构建无需为复用编译缓存修改版本。

### 开发版

本机调试或临时安装用 debug APK：

```powershell
flutter build apk --debug --dart-define=APP_ENV=dev # 使用 dev 配置生成调试包
```

需要使用 dev 签名覆盖安装时，用 dev 签名构建 release APK：

```powershell
flutter build apk --release --dart-define=APP_ENV=dev -P signingEnv=dev # 使用 dev 配置和 dev 签名
```

### 测试版

在已连接设备上调试测试环境，或生成与桌面 test 环境用途一致的内部测试包：

```powershell
flutter run -d '<设备ID>' --dart-define=APP_ENV=test # 使用 test 配置运行调试版
flutter build apk --release --dart-define=APP_ENV=test -P signingEnv=test # 使用 test 配置和 test 签名
```

### 生产版

```powershell
flutter build apk --release --dart-define=APP_ENV=prod -P signingEnv=prod # 使用 prod 配置和 prod 签名
```

商店渠道包还需设置对应的 `APP_CHANNEL`，例如华为：

```powershell
flutter build apk --release --dart-define=APP_ENV=prod --dart-define=APP_CHANNEL=huawei -P signingEnv=prod # 构建华为商店渠道包
```

`APP_ENV` 决定应用连接的服务环境，`signingEnv` 决定 Android 签名密钥；它们是独立设置。密钥准备和对应的 `android/keystores/<环境>/key.properties` 配置见 [Android 签名密钥说明](android/keystores/README.md)。release APK 默认输出到 `build/app/outputs/flutter-apk/app-release.apk`，debug 包位于同目录的 `app-debug.apk`。

Windows 不能构建 iOS；iOS 模拟器构建需在 macOS 和 Xcode 环境执行：

```bash
flutter build ios --simulator --no-codesign
```

应用内更新和发布流程见[移动端更新说明](UPDATES.md)及管理端「版本发布」。系统声音采集的实现与平台限制见[内录说明](SYSTEM_AUDIO_CAPTURE.md)。首页布局见[UI 布局设计](UI_design.md)。


## 专题与开发记录

| 主题 | 文档 |
|---|---|
| 会议架构、状态与平台限制 | [会议开发](LIVE_MEETING_DEVELOPMENT.md) |
| 首页、自适应布局 | [UI 布局设计](UI_design.md) |
| 自动录音与共享记录阶段 | [录音与共享记录](AUTOMATIC_RECORDING_PARITY.md) |

带“对齐记录”或“阶段”的文档保留开发过程及当时验收范围；当前全局状态以[功能状态](../docs/feature-status.md)为准。其他开发入口见[文档导航](../docs/README.md)。
