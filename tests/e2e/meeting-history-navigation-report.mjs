// Assemble navigation evidence; screenshots require explicit human/model review records.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';

const root = fileURLToPath(new URL('../../', import.meta.url));
const out = path.resolve(root, process.argv[2] ?? '.artifacts/mobile-meeting-history-20261027');
if (!out.startsWith(path.join(root, '.artifacts') + path.sep)) throw Error('Invalid evidence directory');
const json = (name, fallback) => fs.existsSync(path.join(out, name))
  ? JSON.parse(fs.readFileSync(path.join(out, name), 'utf8').replace(/^\uFEFF/, '')) : fallback;
const log = name => {
  const bytes = fs.readFileSync(path.join(out, name));
  return bytes.toString(bytes[0] === 255 && bytes[1] === 254 ? 'utf16le' : 'utf8').replace(/^\uFEFF/, '');
};
const vm = json('vm-results.json', []), android = json('android-results.json', []);
const rows = [...vm, ...android], assertions = rows.filter(r => r.phase === 'assertions');
const reviews = json('visual-reviews.json', []), cleanup = json('cleanup.json', {});
const images = fs.readdirSync(path.join(out, 'screenshots')).filter(f => f.endsWith('.png'));
for (const file of images) {
  const name = `screenshots/${file}`, review = reviews.find(r => r.file === name);
  const sha256 = crypto.createHash('sha256').update(fs.readFileSync(path.join(out, name))).digest('hex');
  if (!review?.viewed || review.sha256 !== sha256) throw Error(`Screenshot requires review: ${name}`);
}
const units = Number(/\+(\d+): All tests passed!/.exec(log('units.log'))?.[1] ?? 0);
const budget = json('budget.json', {}), nativeRun = json('android-run.json', {});
const summary = {
  generatedAt: new Date().toISOString(),
  unitPassed: units,
  assertionPassed: assertions.filter(r => r.pass).length,
  assertionFailed: assertions.filter(r => !r.pass).length,
  screenshotReplayPassed: rows.filter(r => r.phase === 'screenshots' && r.pass).length,
  nativePassed: nativeRun.passed === true,
  screenshots: images.length,
  visualPassed: reviews.filter(r => r.viewed && r.pass).length,
  staticClean: /No issues found/.test(log('analyze.log')),
  e2eElapsedMs: (json('execution-finished.json', {}).finished ?? Date.now()) - budget.started,
  budgetLimitMs: budget.limitMs,
};
fs.writeFileSync(path.join(out, 'summary.json'), JSON.stringify(summary, null, 2));
const cell = value => String(value ?? '').replaceAll('|', '\\|').replaceAll('\n', ' ');
let md = `# 会议结束后打开记录：导航回归报告\n\n自动生成于 ${summary.generatedAt}，生成器：tests/e2e/meeting-history-navigation-report.mjs。\n\n分级：导航小修复，验证受影响流程及成功冒烟；不属于本轮完整 RTC/录音验收。使用实际首页、会中、历史页面和生产路由；登录、加入结果、结束仓库和历史空态为确定性夹具，结束/清理方法为真实 RoomController。\n\n`;
md += `结果：单元 ${units} 通过；页面断言 ${summary.assertionPassed} 通过 / ${summary.assertionFailed} 失败；Android 原生集成 ${summary.nativePassed ? '通过' : '未通过'}；截图复演 ${summary.screenshotReplayPassed} 项通过（不重复计入）；${images.length} 张截图已实际查看，视觉通过 ${summary.visualPassed} 张。静态分析：${summary.staticClean ? '通过' : '查看日志'}。\n\n`;
md += `## 启动与环境\n\n先阅读 CONTRIBUTING.md、mobile/README.md、mobile/DESIGN.md。已有 39110 后端、3118 前端及桌面客户端保留；原 Android 包和登录数据保留，测试使用 .coreretry 独立包。平板通过 ADB <device-id> 连接。\n\n`;
md += '```powershell\n# mobile 目录，使用既有 Flutter 工具链\n$env:MEETING_HISTORY_OUTPUT="<repo>\\.artifacts\\mobile-meeting-history-20261027"\n$env:MEETING_HISTORY_CAPTURE="1"\nflutter test --no-pub test/acceptance/meeting_history_navigation_test.dart --reporter expanded\nflutter test --no-pub test/core/router/route_guard_test.dart test/features/live_meeting/room_controller_test.dart --reporter expanded\n# 根目录：本轮 loopback 收集器复用已有工具\n$env:OPENMEETING_CORE_ARTIFACT_DIR=".artifacts/mobile-meeting-history-20261027"\nnode tests/e2e/mobile-core-bridge.mjs\nadb -s <device-id> reverse tcp:39342 tcp:39342\n# mobile 目录；JDK=Android Studio jbr，GRADLE_USER_HOME=<gradle-cache>\n$env:OPENMEETING_ANDROID_DEBUG_SUFFIX=".coreretry"\nflutter test --no-pub integration_test/meeting_history_navigation_test.dart -d <device-id> --dart-define=APP_ENV=dev --reporter expanded\n```\n\n运行子进程移除 HTTP(S)/ALL_PROXY，保留 NO_PROXY；ADB reverse 在 Flutter 启动期间恢复。测试前独立两次触发结束故障，再解除故障验证结果，随后才进入页面。每个平台先完整断言，再复演截图。\n\n';
md += `## 流程与逐步结果\n\n首页快速会议 → 结束确认 → 直接首页 → 底部会议/历史空态 → 嵌套弹窗打开关闭 → 返回首页；连续两轮，第二轮覆盖结束失败、留在会中及成功重试。截图尺寸为 PNG 实际尺寸，Android 逻辑视口以步骤记录为准。\n\n| 平台 / 视口 / 阶段 | 操作 | 预期 | 实际 | 通过 | 截图 |\n|---|---|---|---|---|---|\n`;
for (const r of rows) md += `| ${cell(r.platform)} ${cell(r.viewport)} ${cell(r.phase)} | ${cell(r.operation)} | ${cell(r.expected)} | ${cell(r.actual)} | ${r.pass ? '是' : '否'} | ${r.screenshot ? `[截图](${r.screenshot})` : '—'} |\n`;
md += '\n## 截图实际检查\n\n无 in-app browser，采用 Flutter 无头截图（390×844 / 1024×768）及 ADB 原生截图。检查正常、结束成功、历史空态、失败提示、弹层打开/关闭、底部切换与响应式；本次未修改加载、权限、抽屉、表格、长文本或滚动行为，不声明这些路径已验证。\n\n| 截图 | 实际尺寸 | 视觉通过 | 检查结果 |\n|---|---|---|---|\n';
for (const r of reviews) md += `| [${path.basename(r.file)}](${r.file}) | ${r.width}×${r.height} | ${r.pass ? '是' : '否'} | ${cell(r.note)} |\n`;
md += `\n## 原始证据、失败历史及限制\n\n- [修复前基线](baseline.log)：发现结束后 LiveRoomPage 仍留在导航栈，断言失败，未继续到用户截图中的 observer 断言；不能声称基线完整复现了该断言。\n- [首次修复](fixed-first.log)、[调试 02](fixed-02.log)、[调试 03](fixed-03.log) 仍失败；03 证据显示 URL=/meetings，而顶部匹配仍为 ImperativeRouteMatch(/live-room)。最终改用实际栈顶匹配判断，go() 重建首页栈，保留通知观察器和模态保护。\n- [最终无头日志](vm-final.log)、[Android 日志](android.log)、[Android 完成标志](android-run.json)、[单元日志](units.log)、[分析日志](analyze.log)、[结构化无头步骤](vm-results.json)、[Android 步骤](android-results.json)。\n- 历史失败尝试单列保留，不计入最终通过。E2E 累计 ${Math.round(summary.e2eElapsedMs / 1000)} / ${Math.round(summary.budgetLimitMs / 1000)} 秒。\n- 导航夹具不连接真实会议服务器/媒体设备，不代表新录音生成、网络、消息及跨端 RTC 全链路通过。Android 构建插件兼容性警告见日志。\n\n## 关闭与恢复\n\n[清理证据](cleanup.json)：\n\n\`\`\`json\n${JSON.stringify(cleanup, null, 2)}\n\`\`\`\n`;
fs.writeFileSync(path.join(out, '测试报告.md'), md);
console.log(JSON.stringify(summary));
