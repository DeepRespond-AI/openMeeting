# 移动端自动录音、共享记录及主要功能回归

> 文档类型：开发过程或验收记录。保留当时的设计、环境和执行边界；当前能力以[功能状态](../../../docs/feature-status.md)为准，不作为当前启动或升级指南。

基线为本地最新 `develop@ae00f96`，分支 `feat/mobile-desktop-parity`。遵循 [移动规范](../../../mobile/DEVELOPMENT.md)、[实现说明](../../../mobile/AUTOMATIC_RECORDING_PARITY.md) 和根目录 `.artifacts/` 产物规则。不同基线的报告独立保存。

## 运行环境

先探测既有 39110 网关、Docker、登录态和设备。本轮无线 ADB 平板 offline；保留原应用及登录态。已有另一组测试占用 3160/3161/3163/3167、55439，不停止它们。专用数据库容器 `openmeeting-mobile-auto-records-postgres` 在 55441；独立真实服务使用 3260 网关、3261 用户、3263 出站代理、3267 会议，复用本机 IM 平台配置，使用专用业务库和专用账号。

```powershell
# 根目录；先创建专用 postgres:16，端口55441、账号openmeeting/openmeeting
$env:MEETING_READY_OUTPUT="$PWD/.artifacts/mobile-auto-records"
$env:MEETING_READY_PG_PORT='55441'
$env:MEETING_READY_PORT_OFFSET='100'
C:/projects/meeting/server/.venv/Scripts/python.exe tests/e2e/meeting-ready-services.py --env C:/projects/meeting/server/.env

# 另一个终端：正常请求到真实服务，仅指定分支注入故障
$env:OPENMEETING_GATEWAY='http://127.0.0.1:3260'
$env:OPENMEETING_FIXTURE_PORT='39330'
node tests/e2e/mobile-parity/fixture.cjs

# 另一个终端：只绑定loopback，不打印凭证
$env:OPENMEETING_PARITY_ARTIFACTS="$PWD/.artifacts/mobile-auto-records"
$env:OPENMEETING_GATEWAY='http://127.0.0.1:3260'
$env:OPENMEETING_MEETING_MS='http://127.0.0.1:3267'
node tests/e2e/mobile-parity/bridge.cjs
```

按本机路径配置 Flutter/Android SDK/JDK；本轮 Flutter 为 `C:/tools/flutter`。私有 accounts.private.json 自动生成，不进入报告和 Git。不要将测试库清理指向日常数据库。

## 顺序与累计预算

```powershell
# 必须先独立冒烟失败路径；不在页面超时里调夹具
node tests/e2e/mobile-auto-records/api.cjs --smoke
node tests/e2e/mobile-auto-records/api.cjs

# 从首次页面调试起记录累计30分钟；过期脚本拒绝重跑，不删除时间续期
powershell -NoProfile -ExecutionPolicy Bypass -File tests/e2e/mobile-auto-records/run-ui.ps1

# mobile目录：真实 IM outbox → SDK → 生产通知过滤器
$env:MOBILE_AUTO_RECORDS_NOTICES='1'
flutter test test/acceptance/meeting_notice_transport_test.dart --reporter expanded

# 单元/组件和静态检查
flutter test --concurrency=1 --reporter expanded
dart analyze lib test integration_test/desktop_parity_test.dart
```

运行普通单元测试前移除上述 opt-in 环境变量，避免误启动在线验收。run-ui.ps1 自动写 e2e-budget.json，不重置已有时间，保留每次 ui-attempt 日志及结构化历史。通知传输用例也检查同一预算。主功能断言全部通过后，才统一执行两套视口截图回放。脚本每步输出操作、预期、实际、结果及截图路径，测试框架最终是否通过也必须单独核对，不能以步骤全绿掩盖收尾失败。

页面以生产 Flutter App、路由和组件连接真实 REST/WS/IM，视口390×844、1024×768。VM 适配安全存储、系统宿主、麦克风可用性与播放器；PCM为明确合成数据，下载使用真实鉴权网络和文件写入，仅导出回调替代系统分享面板。不能据此宣称原生硬件、系统权限、播放或导出通过。

## 覆盖与限制

完整回归：消息入口隐藏、预定日期/时间/校验/新建/编辑/取消、未来搜索/空态、真实发起入会、自动录音状态及说明、会中主题/密码/等候室、设置403恢复、主持人接纳、会议IM授权503及文字发送、结束失败恢复和确认、会后处理状态、下载503/加载/成功、早退成员列表/只读详情/只读纪要/下载、非参会账号404。会后通知另验证真实平台传输；纯函数测试验证可信发送者、事件、ID、撤回/擦除及去重。

独立录音、导入和个人设置有页面入口冒烟；文件选择、导入提交、独立录音硬件采集、摄像头、音频输出、真实RTC多端质量、原生导出、后台和iOS未执行，不属于“全部功能均无问题”。隔离STT/LLM不可用，验证真实失败展示和音频保留，不虚报转写/纪要成功。

## 看图、报告和清理

```powershell
$env:OPENMEETING_PARITY_ARTIFACTS="$PWD/.artifacts/mobile-auto-records"
$env:OPENMEETING_PARITY_RESULTS='completed-ui-results.json' # 明确查看第08轮历史完整结果，最新失败仍在ui-results.json
powershell -NoProfile -ExecutionPolicy Bypass -File tests/e2e/mobile-parity/contact-sheets.ps1
# 实际逐张查看后记录visual-reviews.json（含方法、视口、SHA256和观察）
node tests/e2e/mobile-auto-records/report.cjs
```

报告从 JSON、日志、累计预算、运行器退出状态和实际看图记录生成，保留历史失败。平台资源按专用账号/业务库归属清理，再关闭本轮监督进程、fixture、bridge 和专用数据库；验证本轮端口关闭并保留39110及另一组测试服务。Gradle只停止本轮启动的守护进程。清理结果写 cleanup.json/platform-cleanup.json。

本轮最终以 API 级结论为主：第08轮116步及运行器曾通过，后续截图复跑发生消息更新超时，未把历史成功覆盖到最新结果。快照订阅竞争修复前的稳定失败和修复后通过分别在 message-race-before/after 日志中；修复后完整E2E未执行。预算耗尽后的12张补拍仅运行 `MOBILE_AUTO_RECORDS_CAPTURE=1 flutter test test/acceptance/automatic_recording_capture_test.dart`，使用生产组件与静态数据，不能计为业务E2E。原58张加补拍12张共70张实际查看，12张原图采集不足保留失败。清理脚本首次遇到单个端口JSON类型错误，补查由 verify-cleanup.cjs 执行；保留原失败而不改写为通过。
