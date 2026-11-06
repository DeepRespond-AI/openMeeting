# 系统声音采集（内录）

「允许内录」把手机播放的声音和麦克风混在一起录音，输出与「仅麦克风」相同的 16 kHz 单声道 PCM16 流，后续 VAD、AAC、上传完全共用。

- 代码：本地插件 `packages/system_audio_capture`（Dart API + Android Kotlin + iOS 主 App 侧 Swift）、
  `ios/BroadcastExtension/`（iOS 直播扩展）、`lib/features/recording/data/system_audio_source.dart`（`AudioSource` 实现）。
- 参数全部来自 `app_config.*.json`：`systemAudio.*`（混音帧长、抖动缓冲、闪避阈值/起落时间、软削波拐点、电平下限、
  Android 采集 usage/麦克风源/回退采样率/通知、iOS 分片时长/超时/轮询/积压上限/后台保活）、`audio.*`、
  `recording.systemAudioMicGain` / `systemAudioDuckingRatio`、开关 `features.systemAudioCapture`。文案在 `l10n/fragments/system_audio_*.arb`。
- 混音规则（两个平台一致，参照桌面端 `pipeline.rs`）：`mic × micGain + system × g`，麦克风 RMS 超过阈值时 `g` 平滑降到 `duckingRatio`，
  否则回到 1；超过拐点的部分用 tanh 软削波。输出按墙钟计时，某一路没有数据（例如没有声音在播放）时补静音，所以音频时长始终等于真实时长。

### Android（10 及以上）

- 流程：`RECORD_AUDIO` 权限 → 系统「开始录制或投放」授权弹窗（Android 14+ 只提供「整个屏幕」，单个应用共享录不到其他 App 的声音）→
  插件自己的前台服务（类型 `mediaProjection|microphone`，通知栏常驻）→ `AudioPlaybackCaptureConfiguration`（USAGE_MEDIA / GAME / UNKNOWN）+ 麦克风 `AudioRecord`。
  拒绝授权 → `userCancelled`；拒绝麦克风权限 → `permissionDenied`。录音期间会同时出现录音前台服务和内录前台服务两条通知。
- Android 14 规则：授权结果只能用一次；必须先以 mediaProjection 类型进入前台再调用 `getMediaProjection`（插件已按此顺序实现）。
  用户在系统里停止共享时，插件发出 `stoppedExternally(projectionStopped)`，录音随之结束。
- 限制（界面需如实提示）：**语音通话音频**（USAGE_VOICE_COMMUNICATION，例如微信 / 腾讯会议通话中对方的声音）和声明
  `allowAudioPlaybackCapture=false` 的 App 录不到 —— 这类场景请开免提，用麦克风收音。Android 9 及以下不提供该选项。
- **模拟器测试**：插件自带调试壳 `packages/system_audio_capture/example`（不是正式 App），可以播放 440 Hz 测试音：
  ```bash
  cd packages/system_audio_capture/example && flutter run      # 选模拟器
  # 点 Start system(+mic) → 授权弹窗选「整个屏幕」→ 开始；点 Play tone；点 Stop
  adb exec-out run-as cn.deeprespond.system_audio_capture_example cat code_cache/capture.wav > capture.wav
  ```
  在正式 App 中：模拟器里用浏览器或任意播放器放一段语音，录音页选「允许内录」开始录音，确认转写里有该音频的内容；在授权弹窗点「取消」应提示并可改为仅麦克风。

### iOS（真机，ReplayKit 直播扩展）

- 结构：`BroadcastExtension` target（Bundle ID `cn.deeprespond.meeting.BroadcastExtension`，嵌入 Runner 的 PlugIns）。
  扩展收 `.audioApp` / `.audioMic` 两路采样 → 转成 16 kHz 单声道 → 混音 → 每 `iosChunkMs` 写一个分片到 App Group
  `group.cn.deeprespond.meeting` 的 `SystemAudioBroadcast/<会话>/chunk_<序号>.pcm`（先写临时文件再原子改名），用 Darwin 通知告知主 App；
  主 App 按序读取并删除分片（`BroadcastChunkReader`，有单元测试），App 太久没读时扩展会丢弃最旧的分片。
  主 App 和扩展之间的约定集中在插件的 `BroadcastProtocol.swift`，扩展 target 直接编译同一个文件。
- 流程：App 在 App Group 里写入本次会话参数 → 弹出系统直播面板（选中「深应会议」）→ 用户点「开始直播」，倒计时后开始，状态栏变红 →
  超过 `iosStartTimeoutMs` 没开始视为取消。停止：iOS 不能由 App 直接结束别人的直播，App 写停止标记并发 Darwin 通知，扩展自己结束直播，
  系统会弹出一条提示（文案来自 l10n）。用户从状态栏/控制中心停止 → `stoppedExternally`。从控制中心直接开始（没有经过 App）会被扩展拒绝并提示。
- 麦克风：直播面板里的麦克风按钮控制扩展是否收到 `.audioMic`；选择混入麦克风时面板会显示该按钮，需要用户打开。
- 后台：录音期间主 App 需要持续运行来读取分片 —— 依赖 `UIBackgroundModes: audio`，插件在内录期间播放静音保持 App 存活（`iosKeepAliveInBackground`）。
- 限制：部分 App 的通话音频和受保护内容会被系统静音；扩展内存上限约 50 MB（本实现只有两个约 1 s 的环形缓冲和一个分片）；**模拟器不支持**（`availability()` 返回 unsupported）。
- Xcode 工程由脚本维护（可重复执行）：`ruby tool/setup_ios_extension.rb`。它负责扩展 target、嵌入阶段、App Group entitlements
  （`DR_APP_GROUP_IDENTIFIER` 构建设置）、`InfoPlist.strings` 的 en / zh-Hans 本地化和 knownRegions。需要 xcodeproj gem（随 CocoaPods 安装）。
- **真机签名 / 发布前需要在 Apple Developer 后台完成**：
  1. 注册 App ID `cn.deeprespond.meeting` 和 `cn.deeprespond.meeting.BroadcastExtension`，两者都开启 **App Groups** 能力；
  2. 创建 App Group `group.cn.deeprespond.meeting` 并分配给这两个 App ID；
  3. 在 Xcode 中为 **Runner 和 BroadcastExtension 两个 target** 都选择 Team（自动签名）或各自的描述文件；
  4. 真机验证：录音页选「允许内录」→ 面板里选「深应会议」并开始直播（需要时打开麦克风）→ 用别的 App 播放语音 → 回到 App 停止，
     检查转写；再测试从状态栏红条停止、拒绝/不点开始直播（应在超时后提示并可改为仅麦克风）、录音中切到后台几分钟。
- 本工程使用 Swift Package Manager 集成插件（没有 Podfile）。permission_handler 在 SPM 下根据 Info.plist 的 `NSMicrophoneUsageDescription`
  自动打开 `PERMISSION_MICROPHONE`；如果改回 CocoaPods，需要在 Podfile 的 `post_install` 里加 `GCC_PREPROCESSOR_DEFINITIONS 'PERMISSION_MICROPHONE=1'`，
  并确认扩展 target 不链接 Pods（扩展的基础配置是 `ios/BroadcastExtension/BroadcastExtension.xcconfig`，只引入 `Generated.xcconfig`）。
