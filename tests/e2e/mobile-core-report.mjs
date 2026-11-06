// Assemble only observed steps, runner outcomes, image reviews and cleanup.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';
const root = fileURLToPath(new URL('../../', import.meta.url));
const out = path.join(root, '.artifacts/mobile-core-parity');
const read = file => {
  const bytes = fs.readFileSync(path.join(out, file));
  return bytes.toString(bytes[0] === 0xff && bytes[1] === 0xfe ? 'utf16le' : 'utf8').replace(/^\uFEFF/, '');
};
const json = file => JSON.parse(read(file));
const exists = file => fs.existsSync(path.join(out, file));
const unitCount = file => { const log = read(file); const count = [...log.matchAll(/\+(\d+): All tests passed!/g)].at(-1); if (!count) throw Error(`Runner did not pass: ${file}`); return +count[1]; };
const units = unitCount('logs/units-final.txt') + unitCount('logs/channel-adapter-unit-03.txt');
const groups = [
  { name: '核心双视口页面', rows: json('vm-results.json'), log: 'logs/ui-attempt-09.txt' },
  { name: '头像与聊天双视口回归', rows: json('avatar-regression/vm-results.json'), log: 'logs/avatar-regression-01.txt' },
  { name: '真实后端 API', rows: json('api-results.json'), log: 'logs/api-attempt-03.txt' },
];
for (const group of groups.slice(0, 2)) {
  if (!read(group.log).includes('All tests passed!')) throw Error(`${group.name} runner failed`);
  const firstReplay = group.rows.findIndex(r => r.phase === 'screenshots');
  if (firstReplay < 0 || group.rows.slice(0, firstReplay).some(r => !r.pass || r.phase !== 'assertions')) throw Error('Screenshots preceded passing assertions');
}
const reviews = json('reviews-notes.json').map(review => {
  const data = fs.readFileSync(path.join(out, review.file));
  return { ...review, width: data.readUInt32BE(16), height: data.readUInt32BE(20), sha256: crypto.createHash('sha256').update(data).digest('hex') };
});
const byFile = new Map(reviews.map(r => [r.file, r]));
const allRows = groups.flatMap(g => g.rows);
const screenshots = groups.flatMap(g => g.rows.filter(r => r.screenshot).map(r => g.name.startsWith('头像') ? `avatar-regression/${r.screenshot}` : r.screenshot));
for (const file of screenshots) if (!byFile.has(file)) throw Error(`Screenshot not actually reviewed: ${file}`);
const native = [1, 2].map(attempt => {
  const log = `logs/android-attempt-0${attempt}.txt`, text = read(log);
  return { attempt, log, built: text.includes('Built build'), failed: text.includes('Failed to load') && text.includes('WebSocketChannelException'), stepsExecuted: 0 };
});
const cleanup = {
  bridge: json('bridge-cleanup.json'), device: json('device-cleanup.json'), apiRooms: json('api-cleanup.json'), data: json('test-data-cleanup.json'),
  gradleStopped: read('logs/gradle-stop.txt').includes('Daemon stopped'), environment: json('final-environment.json'),
};
const budget = json('budget-outcome.json');
const lint = read('logs/analyze-clean.txt').trim();
const asserted = allRows.filter(r => r.phase === 'assertions');
const summary = {
  generatedAt: new Date().toISOString(), unitPassed: units,
  assertionPassed: asserted.filter(r => r.pass).length, assertionFailed: asserted.filter(r => !r.pass).length,
  screenshotReplayPassed: allRows.filter(r => r.phase === 'screenshots' && r.pass).length,
  reviewedFinalScreenshots: screenshots.length, visualPassed: screenshots.filter(f => byFile.get(f).pass).length,
  nativeStartupFailures: native.filter(r => r.failed).length, nativeStepsExecuted: 0,
  nativeCaptureVerified: false, realCrossClientScreenPixelsVerified: false,
  totalPassed: units + asserted.filter(r => r.pass).length,
  staticClean: lint === '', budget, cleanup,
};
fs.writeFileSync(path.join(out, 'summary.json'), JSON.stringify(summary, null, 2));
fs.writeFileSync(path.join(out, 'visual-reviews.json'), JSON.stringify(reviews, null, 2));
fs.writeFileSync(path.join(out, 'native-summary.json'), JSON.stringify(native, null, 2));
const cell = value => String(value ?? '').replaceAll('|', '\\|').replaceAll('\n', ' ');
let md = `# 移动端核心功能对齐测试报告\n\n自动生成：${summary.generatedAt}，生成器 [mobile-core-report.mjs](../../tests/e2e/mobile-core-report.mjs)。\n\n分级：核心媒体与持续会话变更，采用完整流程验证；非文案级小改动。范围覆盖新增持续会话、共享、遥测及头像回归。原有登录、预定、录音、导入、记录、纪要和设置采用核心单元回归，**不声称所有功能均已通过真实硬件/模型全链路 E2E**。\n\n当前结果：${summary.totalPassed} 项通过（单元 ${units}，页面/API 断言 ${summary.assertionPassed}），当前页面/API 断言失败 ${summary.assertionFailed}。Android 启动尝试失败 ${summary.nativeStartupFailures} 次，原生步骤执行 0 项。真实共享像素互通尚未验证。\n\n`;
md += `## 启动方式与复用\n\n- 先读 mobile/DESIGN.md、README 和核心功能对照，复用已有 39110 服务及两个有效测试身份；未创建账号、未改原应用登录态。\n- 测试收集器：node tests/e2e/mobile-core-bridge.mjs（127.0.0.1:39342）；adb reverse tcp:39342 tcp:39342。\n- 开发包：OPENMEETING_ANDROID_DEBUG_SUFFIX=.coreparity，GRADLE_USER_HOME=<gradle-cache>，JDK 使用 Android Studio jbr；Flutter 使用既有工具链和 pub.flutter-io.cn 镜像。\n- 日常启动：先 adb -s <device-id> reverse tcp:39110 tcp:39110；mobile 目录 flutter run -d <device-id> --dart-define=APP_ENV=dev --dart-define=OPENMEETING_SERVER_URL=http://127.0.0.1:39110；三客户端脚本 mobile/dev-multi.ps1 详见 README。\n\n\`\`\`powershell\nflutter test --no-pub test/core test/features test/app_test.dart --reporter expanded\nflutter test --no-pub test/core/im/channel_media_test.dart --reporter expanded\nflutter test --no-pub test/acceptance/core_parity_ui_test.dart --reporter expanded\n$env:MOBILE_AVATAR_UI='1'\nflutter test --no-pub test/acceptance/avatar_toolbar_ui_test.dart --dart-define=E2E_AVATAR_OUT=../.artifacts/mobile-core-parity/avatar-regression --reporter expanded\nflutter test --no-pub integration_test/core_parity_test.dart -d <device-id> --dart-define=APP_ENV=dev --reporter expanded\nnode tests/e2e/mobile-core-api.mjs\nnode tests/e2e/mobile-core-report.mjs\n\`\`\`\n\n`;
md += `## 先夹具、后页面与预算\n\n先单独跑屏幕共享取消/拒绝/业务拒绝/发布失败/接管/退出/迟到结果及网络指标夹具，18 项通过，见 [夹具日志](../core-media-fixture-smoke-02.txt)。页面再执行成功和关键失败路径，全部断言通过后统一截图复演。SDK、身份、选图、发布像素和遥测 UI 数据有明确夹具边界；真实 REST API 单列，不以夹具替代真实互通结论。\n\n保留前阶段计时 ${Math.round(budget.previousActiveMs / 1000)} 秒，本阶段 ${Math.round(budget.elapsedMs / 1000)} 秒，累计 ${Math.round(budget.combinedMs / 1000)} / 1800 秒；预算内：${budget.withinBudget}。Android 调试连接失败后降级 API 验证，不重置预算。见 [预算](budget-outcome.json)。\n\n`;
md += `## 当前运行汇总\n\n| 类别 | 通过 | 失败 | 证据 |\n|---|---:|---:|---|\n| 核心单元 | ${units} | 0 | [主回归](logs/units-final.txt)、[RTC 适配](logs/channel-adapter-unit-03.txt) |\n`;
for (const g of groups) { const rows = g.rows.filter(r => r.phase === 'assertions'); md += `| ${g.name} | ${rows.filter(r => r.pass).length} | ${rows.filter(r => !r.pass).length} | [日志](${g.log}) |\n`; }
md += `| 截图复演断言（不重复累计） | ${summary.screenshotReplayPassed} | 0 | [步骤](vm-results.json)、[头像步骤](avatar-regression/vm-results.json) |\n| Android 启动尝试 | 0 | ${summary.nativeStartupFailures} | [第一次](logs/android-attempt-01.txt)、[第二次](logs/android-attempt-02.txt) |\n| 原生采集/远端真实共享像素 | 0 | 未执行 | 调试服务连接前失败，不标记通过 |\n\n静态检查：${summary.staticClean ? '无问题' : '存在输出，需查看日志'}，见 [分析日志](logs/analyze-clean.txt)、[代码生成](logs/generate-final.txt)。\n\n`;
md += `## 逐步结果\n\n| 流程/视口 | 操作 | 预期 | 实际 | 通过 | 截图 |\n|---|---|---|---|---|---|\n`;
for (const g of groups) for (const r of g.rows.filter(r => r.phase === 'assertions')) md += `| ${cell(g.name)} ${cell(r.viewport)} | ${cell(r.operation)} | ${cell(r.expected)} | ${cell(r.actual)} | ${r.pass ? '是' : '否'} | — |\n`;
md += `\n## 最终截图与实际视觉检查\n\n无 in-app browser，使用 Flutter 无头渲染。视口 390×844 与 1024×768；先断言后截图，逐张实际查看最终引用的 ${screenshots.length} 张图片。目录 [screenshots](screenshots/) 和 [头像截图](avatar-regression/screenshots/)。旧调试编号图片未计为最终截图。\n\n覆盖正常、加载、错误、权限、成功业务状态、共享等待、空态、长主题/昵称、弹层打开关闭和真实页面滚动。共享舞台等待表示夹具未提供像素，不能称为远端视频接收成功。没有新增表格，未虚构表格截图。\n\n| 截图 | 尺寸 | 视觉通过 | 实际检查 |\n|---|---|---|---|\n`;
for (const file of screenshots) { const r = byFile.get(file); md += `| [${path.basename(file)}](${file}) | ${r.width}×${r.height} | ${r.pass ? '是' : '否'} | ${cell(r.note)} |\n`; }
md += `\nAndroid 诊断截图已实际查看为黑屏，**不能视觉通过**：[诊断](device-diagnostic.png)。截图 SHA-256 与检查记录见 [visual-reviews.json](visual-reviews.json)。\n\n`;
md += `## 失败历史与限制\n\n- Android 两次均为 WebSocketChannelException / connection closed before full header，未进入业务测试。第二次去除测试进程代理后仍失败；设备诊断黑屏，唤醒命令未完成。不是通过的原生屏幕采集/系统授权/完整真机流程。\n- UI 01–03 修正流刷新帧和弹层后方同文案选择器；04 出现点到后方关闭按钮的警告，05 后改用最上层目标；视觉复查修正共享缩略图高度，最终采用 09 运行。原始日志全部保留。\n- API 01–02 对结束读取状态的测试预期错误，实际契约为 HTTP 404/code=ended；03 按真实契约验证通过。\n- 补充适配单元首次为 mock 返回类型编译失败，第二次测试套件连接中断，第三次排除代理后 2 项通过；没有将失败尝试抹成通过。\n- 屏幕共享兼容 alpha SDK 的内部会话入口及具名 camera-source publication，SDK 升级需回归。iOS 跨应用 Broadcast Extension 本轮未实现/验收。\n- 真实远端像素、现场发言/网络采样、原生相册和文件选择器、硬件录音、长时间后台及真实模型转写/纪要全链路仍需后续现场验收。\n\n`;
md += `## 关闭与清理\n\n- 收集器关闭：${cleanup.bridge.closed}；新增 ADB reverse 和两个本次 forward 已移除：${cleanup.device.reverseRemoved.ok && cleanup.device.forward1Removed.ok && cleanup.device.forward2Removed.ok}。\n- 独立测试包移除：${cleanup.device.uninstall.ok}；设备只保留原应用：${cleanup.device.packages.result === 'package:cn.deeprespond.meeting'}。未清除原应用数据。\n- 本次 Gradle daemon 停止：${cleanup.gradleStopped}；既有 39110 服务保留：${cleanup.environment.gatewayPreserved}；39342 已无监听：${cleanup.environment.bridgeAbsent}。\n- API 临时房间已结束；本轮生成记录删除 ${cleanup.data.deleted}/${cleanup.data.expected}，成功 ${cleanup.data.success}。\n- 证据：[设备清理](device-cleanup.json)、[服务清理](bridge-cleanup.json)、[测试数据清理](test-data-cleanup.json)、[最终环境](final-environment.json)。\n`;
fs.writeFileSync(path.join(out, '测试报告.md'), md);
console.log(JSON.stringify({ totalPassed: summary.totalPassed, nativeStartupFailures: summary.nativeStartupFailures, screenshots: screenshots.length, staticClean: summary.staticClean }));
