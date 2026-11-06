# 移动端开发指南

本规范适用于 `mobile/` 中的全部代码。服务端契约以 `../server/API.md` 为准；功能行为与桌面客户端
（`../frontend/`）保持一致，桌面视觉规范见 `../frontend/UI_design.md`。

## 1. 架构

```
lib/
  core/        公共能力：配置、API、鉴权/会话、路由、主题、国际化、心跳、工具
  features/<feature>/
    data/          远程数据源（dio）、本地存储、仓储实现
    domain/        freezed 实体、仓储接口（抽象类）
    presentation/  页面、组件、Notifier（@riverpod）
```
- 组件只通过 Notifier/provider 交互，不直接调用 dio、存储或平台通道。
- 所有依赖都通过 provider（`@riverpod`）提供，以便测试使用 `ProviderContainer(overrides: [...])` 替换依赖。
- 功能模块只能导入其他功能模块的 `domain/`；共享能力放入 `core/`。

## 2. 状态管理（Riverpod 3 + riverpod_generator 代码生成）
- riverpod_lint 作为原生分析器插件运行（`analysis_options.yaml` 中的 `plugins:`），由 `dart analyze` 报告检查结果，无需单独执行 custom_lint。
- 只使用 `@riverpod` / `@Riverpod(keepAlive: true)` 注解，不手写 `StateNotifierProvider`/`ChangeNotifier`。
- 请求与响应型数据使用 `AsyncNotifier`，包括会议列表、详情、总结及能力配置。
- 实时数据使用 `StreamNotifier` / `Stream` provider，包括音量、实时转写和上传队列。
- 状态对象使用 `freezed`（不可变及 `copyWith`）；多阶段状态使用 freezed 联合类型（sealed），通过 `switch` 处理。
- 全局控制器（keepAlive）：
  - `SessionController`：使用 `AuthState` 联合类型，包含 `unconfigured`（构建时未提供服务端 URL）、`signedOut`、`signedIn(User)` 和 `expired`。
    dio 对已鉴权请求收到的 401 调用 `expire()`，由 `go_router` 的 `redirect` 监听状态变化。
  - `SettingsController`：持久化用户设置，见第 3 节。
  - `RecordingController`：录音状态机为 `idle → preparing → recording ⇄ paused → stopping → done | error`。
    停止时只完成本地保存，服务端同步（分段及完整音频上传）在后台执行。
  - `UpdateController`（`core/update/`）：负责应用更新（server/API.md 第 1.8 节），在启动、恢复前台及定时检查时检测更新。
    Android `direct` 渠道通过 APK 下载、SHA-256 校验及 `packages/app_installer` 安装；商店渠道和 iOS 跳转商店链接。
    强制更新时，路由守卫将页面重定向到 `/update`，录音期间除外。
  - `MeetingSync`（`core/data/background_work.dart`）：管理会议后台工作，包括停止后的同步，以及由 `BackgroundImports` 跟踪的导入转写。
    `BackgroundNotices` 将执行结果交给应用外壳，以 SnackBar 展示。
- 重命名、删除等乐观更新必须在失败时回滚。
- 需要 `BuildContext` 的副作用（提示、导航）在组件内通过 `ref.listen` 执行，不放在 Notifier 中。

## 3. 配置：禁止在业务代码中硬编码
优先级：**用户设置 > 服务端下发 > 应用配置默认值**。
1. `tool/templates/app_config.json` 维护不含部署地址的公共默认参数；`dart run tool/init_app_config.dart --server-url <HTTPS网关>` 生成本地 `assets/config/app_config.<env>.json`（整个生成目录不提交 Git）→ freezed `AppConfig` → `appConfigProvider`，通过 `--dart-define=APP_ENV=dev|test|prod` 选择环境，默认 `prod`。三个配置文件的字段必须保持一致；`test` 为内部测试配置，默认关闭开发验证码展示。新增字段时同步修改公共模板、模型和已有本地配置，脚本不会覆盖旧文件。
   集中维护超时、心跳间隔、轮询间隔与上限、分页大小、重试次数与退避、VAD 参数、音频参数、默认录音源、功能开关及服务端 URL。
   `defaultServerUrl` 在构建时固定，用户不能编辑，也不在界面显示。
   构建参数：`APP_ENV` 选择配置文件；`APP_CHANNEL` 为 `direct` 时使用应用内 APK 更新，其他值对应 Android 商店渠道的更新链接。
2. 服务端下发：`GET /auth/config`（验证码长度、重发间隔、注册及短信状态）和 `capabilities`。总结模板保留在服务端并自动选择，不向应用下发。
3. `SettingsController`（shared_preferences）：界面语言（`system|zh|en`）、默认录音源、转写语言、自动总结及是否保留本地音频。

业务代码中禁止硬编码行为参数、URL/路径（使用 `core/api/endpoints.dart`）、界面文案（使用 l10n）以及颜色和尺寸（使用主题扩展）。
属于组件自身几何布局的常量，例如图标容器尺寸，统一放入 `AppSpacing`/`AppSizes`。

## 4. 网络请求
- 统一使用 `apiClientProvider` 提供的 `Dio`；基础 URL 为 `AppConfig.defaultServerUrl`（`effectiveServerUrlProvider`）。
- 拦截器负责鉴权（从 `flutter_secure_storage` 获取 Bearer 会话令牌）和错误映射，统一生成 `ApiException`，包含 `statusCode`、`message`（服务端中文 `detail`）及 `kind`。
  已鉴权请求收到 401 时调用 `SessionController.expire()`；422 列表型错误转换为本地化的“输入无效”提示。
- 网络错误、5xx、408 和 429 可重试，重试及退避参数来自 `AppConfig`。
- 模型使用 `freezed` + `json_serializable`，字段名与 `server/API.md` 完全一致，必要时使用 `@JsonKey(name: ...)`。

## 5. 主题（取值参照 `frontend/tailwind.config.js` / `globals.css`）
- 基于 `AppColors`（ThemeExtension）构建 Material 3 `ThemeData`：
  主色为 `#0052D9`（移动端 V2 原型）；保留品牌渐变标记（`brand600 #1F55F0`、`brand500 #2F6BFF`、`brand50 #EEF4FF`、青色 `#22A8FF`）。
  背景为 `#F5F7FA`，正文为 `#0F172A`，次要文字为 `#6B7280`，边框为 `#E2E6EE`；
  危险操作为 `#DC2626`，成功为 `#29A36A`，警告为 `#F59E0B`；品牌渐变为 `#1F55F0 → #22A8FF`（135°）。
- `AppSpacing` (4/8/12/16/20/24/32), `AppRadius` (sm 8, md 12, lg 16, pill 999), `AppShadows`.
- 通过扩展属性 `context.colors`、`context.spacing`、`context.radius` 访问主题。
- 使用系统字体：iOS 为 PingFang SC，Android 为 Noto Sans CJK。
- 标志通过 `BrandLogo` 组件加载 `assets/brand/brand-logo.png`。

## 6. 国际化（i18n）
- 使用 Flutter gen-l10n，通过 `context.l10n` 访问。**只编辑按功能拆分的片段** `l10n/fragments/<feature>_{zh,en}.arb`
  （core、auth、meetings、recording、system_audio；新功能增加一对片段），然后执行 `dart run tool/l10n.dart`。
  该脚本会合并生成 `lib/core/l10n/app_{zh,en}.arb`（禁止手工编辑），检查重复及缺失键，并执行 `flutter gen-l10n`。
- 所有界面文案通过 l10n 提供，动态值使用占位符（`{count}`），不拼接字符串。
- 键名使用 `<feature><Thing>` 的 camelCase 格式，例如 `recordingStart`、`meetingDeleteConfirm`。
- 不翻译服务端数据（标题、转写、总结），也不翻译已经是中文的服务端 `detail` 消息。

## 7. 测试
- Notifier 和仓储的单元测试使用 provider 替换及模拟数据源。
- 通过替换 `appConfigProvider` 验证依赖配置的行为。
- 平台通道通过接口（`AudioSource`、`AacWriter`）隔离，测试使用替身实现。
