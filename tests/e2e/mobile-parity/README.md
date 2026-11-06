# 移动端桌面功能对齐验收

> 文档类型：开发过程或验收记录。保留当时的设计、环境和执行边界；当前能力以[功能状态](../../../docs/feature-status.md)为准，不作为当前启动或升级指南。

本文对应 `357a499` 的首轮手动录制基线，相关显式 opt-in 脚本保留历史用途。最新 develop 已取消手动录制；当前自动录音、共享记录及消息入口隐藏请使用 [新版 E2E](../mobile-auto-records/README.md)，不要将本文脚本结果套用到新版。

基线 `origin/develop@357a499`。产品实现与边界见 [当前功能与限制](../../../docs/feature-status.md)。结果只输出根目录 `.artifacts/mobile-desktop-parity/`，APK、缓存、凭证及数据库不提交。

## 本轮已执行

1. 阅读 `mobile/DEVELOPMENT.md`、`mobile/README.md`、当前测试目录规则；探测现有网关 39110、Docker 和无线平板，保留原应用和登录态。
2. 启动专用数据库及 `meeting-ready-services.py` 隔离业务后端（3160/3161/3167/3163），复用已有 IM 平台配置。过期的桌面测试会话不复用，测试账号单独生成。
3. 启动 loopback 故障代理 39330、测试桥接 39331。页面前独立冒烟，验证 503 日程/会议群/上传/结束、403 录制控制及恢复；重复故障三次，结果保存在 fixture-smoke.json。
4. Flutter 无头渲染器连接真实 REST/WS/IM，执行生产 App、路由与页面流程；先断言，再统一宽窄截图。VM 适配安全存储和平台宿主，播放器明确为测试适配器，PCM 明确为合成输入。
5. 30 分钟内主断言未全部完成，停止业务 E2E 重试，降级 API 验证。最后一轮已运行任务随后完成 64 步，仅作补充证据。追加 6 张纯组件视觉补拍，未重跑业务 E2E。
6. 逐图检查、静态/单元/Android 编译，生成报告并关闭本次服务。原生 integration_test 未执行，新 APK 未安装。

## 复现前提与命令

这组脚本需要本地开发后端和专用测试账号。它不自动创建生产账号或复用个人凭证。先按 [通用 E2E 说明](../README.md) 配置 Python、Docker、Flutter、Android SDK 与 IM 环境；Windows 本机 Flutter 在 `C:/tools/flutter`，JDK 为 Android Studio 自带 JBR。

独立数据库容器使用 postgres:16，端口 55439；给 `meeting-ready-services.py` 指定本轮私有 env 和 `MEETING_READY_OUTPUT=<本轮产物绝对目录>`。其服务端口约定为 3160/3161/3167/3163；账户在产物目录 accounts.private.json，内容不进报告。不要将隔离测试服务指向日常业务库。

```powershell
# 从仓库根目录启动本轮转发器；先保持专用后端运行
$env:OPENMEETING_GATEWAY='http://127.0.0.1:3160'
$env:OPENMEETING_FIXTURE_PORT='39330'
node tests/e2e/mobile-parity/fixture.cjs
# 另一个终端
node tests/e2e/mobile-parity/bridge.cjs
```

fixture.cjs 的 `/__fixture/mode` 只绑定 loopback。空对象恢复转发；`schedules:error`、`chat:error`、`recording:forbidden`、`upload:error`、`end:error` 分别触发确定性故障。本轮的独立冒烟结果在 fixture-smoke.json。正式页面运行前应单独重复冒烟，不能在页面超时里调夹具。

```powershell
# 根目录：真实 API 降级验证，每步输出并保存操作/预期/实际/结果
node tests/e2e/mobile-parity/api.cjs

# mobile 目录：本轮最终执行过的回归命令
flutter test --concurrency=1 --reporter expanded
dart analyze lib test integration_test/desktop_parity_test.dart

# 页面：连接上述隔离服务，使用实际 Flutter 渲染，显式 opt-in
$env:MOBILE_PARITY_UI='1'
flutter test test/acceptance/desktop_parity_ui_test.dart --reporter expanded

# 纯视觉弹窗补拍：不连接后端、不等同于完整用户流程
$env:MOBILE_PARITY_CAPTURE='1'
flutter test test/acceptance/desktop_parity_capture_test.dart --reporter expanded
```

上面的页面命令是复现入口，**本轮已超过预算，不能直接再运行**。每轮必须从第一次 Android 构建/页面调试起累计 30 分钟，记录 e2e-budget.json；过期后只做 API 验证和证据整理，不删除或重写时间以延长预算。页面脚本依赖 Windows `C:/Windows/Fonts/msyh.ttc`，其他系统需提供等效字体。UI 适配器不证明原生 RTC/插件与音频播放成功。

`mobile/integration_test/desktop_parity_test.dart` 与 run-native.ps1 是待执行的原生验收入口，本轮仅静态检查。run-native.ps1 使用已记录预算、`.parity` 独立 debug 包及 39330/39331 ADB 映射，过期会拒绝运行；不会重装原包。不要把旧分支原生验收结果套用到本轮录制代码。桥接脚本原生 `/viewport` 会修改设备显示/旋转，需要在正式原生复验前记录并在结束时恢复；本轮未调用该入口。

## 截图、报告与清理

`ui-results.json` 持久化主断言及截图回放；supplemental-capture.json 记录纯组件补拍。截图在 screenshots/，按步骤编号。contact-sheets.ps1 生成联系表供实际看图。视觉检查记录 visual-reviews.json，含方法、视口、结论、备注及原图 SHA-256；未实际查看的图片不填写通过。原 6 张弹窗采集不足的图必须保留失败，补拍不覆盖原证据。

```powershell
# 根目录；只组装已有证据，不启动测试
node tests/e2e/mobile-parity/report.cjs
```

report.cjs 校验看图 SHA-256、读取真实日志与结构化步骤，输出 测试报告.md 和 summary.json；将 PowerShell 日志转为 UTF-8 并脱敏凭证。checks.json 保存 APK 的包名、体积、SHA-256 和构建日志关联，不记录安装成功。历史失败日志与预算降级分别呈现。

平台资源先用 `tests/e2e/meeting-ready-cleanup.py` 按本轮所有权账本删除；再运行 cleanup.cjs 关闭确认归属本次的服务树、代理、桥接和数据库，保留日常 39110。cleanup.cjs 中容器 ID 检查固定为本轮身份，另一次执行必须核实新容器，不能删掉保护判断直接复用。Gradle 使用本次独立 `C:/temp/meeting-gradle` 缓存并已 `--stop`；旧缓存中本次启动的守护进程也按 PID/创建时间核实后关闭。结果记录在 cleanup.json/platform-cleanup.json。平板原应用未替换，结束时已恢复 `adb reverse tcp:39110 tcp:39110`。
