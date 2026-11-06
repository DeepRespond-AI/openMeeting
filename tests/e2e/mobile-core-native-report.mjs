// Generate the explicit native retry report without overwriting prior failures.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';
const root = fileURLToPath(new URL('../../', import.meta.url));
const out = JSON.parse(fs.readFileSync(path.join(root, '.artifacts/native-retry-current.json'))).out;
if (!path.resolve(out).startsWith(path.join(root, '.artifacts') + path.sep)) throw Error('Invalid artifact directory');
const read = name => {
  const b = fs.readFileSync(path.join(out, name));
  return b.toString(b[0] === 255 && b[1] === 254 ? 'utf16le' : 'utf8').replace(/^\uFEFF/, '');
};
const json = name => JSON.parse(read(name));
const rows = json('android-results.json'), desktop = json('desktop/results.json');
const runner = json('runner-exit-04.json'), run = json('android-run.json');
const log = read('logs/android-attempt-04.txt');
const reviews = json('visual-notes.json').map(r => {
  const bytes = fs.readFileSync(path.join(out, r.file));
  return { ...r, width: bytes.readUInt32BE(16), height: bytes.readUInt32BE(20), sha256: crypto.createHash('sha256').update(bytes).digest('hex') };
});
const index = new Map(reviews.map(r => [r.file, r]));
const nativeImages = fs.readdirSync(path.join(out, 'screenshots')).filter(n => n.endsWith('.png')).map(n => `screenshots/${n}`);
const desktopImages = desktop.filter(r => r.screenshot).map(r => `desktop/${r.screenshot}`);
for (const file of [...nativeImages, ...desktopImages]) if (!index.has(file)) throw Error(`Unreviewed screenshot: ${file}`);
const power = read('logs/power-during-stall.txt');
const budget = json('budget-outcome.json'), cleanup = json('device-cleanup.json');
const result = {
  generatedAt: new Date().toISOString(),
  runnerExitCode: runner.exitCode,
  suitePassed: runner.exitCode === 0 && run.passed === true && log.includes('All tests passed!') && rows.every(r => r.pass),
  nativeAssertionsPassed: rows.filter(r => r.phase === 'assertions' && r.pass).length,
  screenshotReplayPassed: rows.filter(r => r.phase === 'screenshots' && r.pass).length,
  failedSteps: rows.filter(r => !r.pass).length,
  nativeCapturePassed: rows.some(r => r.platform === 'android-native-capture' && r.operation.includes('允许') && r.pass),
  desktopAssertionsPassed: desktop.filter(r => r.phase === 'assertions' && r.pass).length,
  nativeImages: nativeImages.length, desktopImages: desktopImages.length,
  visualFailed: reviews.filter(r => !r.pass).length,
  observedSleep: /mWakefulness=Asleep/.test(power) && /state=OFF/.test(power),
  screenTimeoutRestored: json('screen-timeout-original.json').restored,
  bridgeClosed: json('bridge-cleanup.json').closed,
  staticClean: read('logs/analyze-final.txt').trim() === '', budget,
};
fs.writeFileSync(path.join(out, 'summary.json'), JSON.stringify(result, null, 2));
fs.writeFileSync(path.join(out, 'visual-reviews.json'), JSON.stringify(reviews, null, 2));
const cell = v => String(v ?? '').replaceAll('|', '\\|').replaceAll('\n', ' ');
let md = `# Android 真机再次验证报告\n\n自动生成：${result.generatedAt}。本次是用户明确要求的新增重试，原失败报告和计时保留。分级：核心流程与真实系统采集，执行页面成功/失败流程、原生授权拒绝/允许、实际视频首帧和像素验证；非文案级测试。\n\n最终测试进程退出码 ${result.runnerExitCode}，套件通过 ${result.suitePassed}；真机断言 ${result.nativeAssertionsPassed} 项通过、截图复演 ${result.screenshotReplayPassed} 项通过、当前步骤失败 ${result.failedSteps} 项。桌面/窄视口回归断言 ${result.desktopAssertionsPassed} 项通过。\n\n`;
md += `## 失败原因与本次处理\n\n- 原轮次在 Flutter VM 调试 WebSocket 建连时提前断开，尚不能仅凭旧日志确定单一根因；旧记录不改写为通过。\n- 本次直接观测到平板 mWakefulness=Asleep、Display Power OFF，且唤醒后原停住的页面流程立即继续。系统息屏超时原值 600000ms，自动 Flutter 点击不刷新 Android 用户活动；临时延长后恢复原值。证据：[停住时电源状态](logs/power-during-stall.txt)、[唤醒后](logs/power-after-wake.txt)、[设置恢复](screen-timeout-original.json)。\n- 诊断尝试 01 关闭 DDS 后虽连上 VM，却触发当前 Flutter 工具对 DDS 扩展事件流的 streamListen Invalid params；恢复正常 DDS 后消失。\n- 尝试 01 的原生采集已生成 video 轨道，但 Android 插件 getSettings 没有宽高，原测试断言错误。改为验证真实渲染器首帧、尺寸及采集帧非均匀像素。\n- 尝试 02 功能断言通过，但截图实际检查发现横屏共享成员姓名被裁剪，且纹理预览截图空白。调整共享区域比例与头像缩放；原生像素测试独立于 Flutter ImageView 截图测试，采集原始帧并用 ADB 保存真实合成画面。\n- 尝试 03 已取得有效原始帧，但本地预览仍空白，保留视觉失败记录；等待真实视频视图就绪并延长画面稳定时间后，最终尝试 04 完成验收。使用正常 DDS，调试服务实际端口以日志为准。\n\n`;
md += `## 启动与测试流程\n\n设备：华为 AGS3-W00E，<device-id>。复用既有 ADB 和 39110 服务，保留原包 cn.deeprespond.meeting 与登录数据；独立测试包后缀 .coreretry，loopback 收集器 39342。先单独冒烟失败夹具 18 项通过，再执行真机；未修改安装的 Flutter/IM SDK。\n\n\`\`\`powershell\n# mobile 目录，子进程清除 HTTP_PROXY/HTTPS_PROXY/ALL_PROXY，设置 NO_PROXY 回环地址\n$env:OPENMEETING_ANDROID_DEBUG_SUFFIX='.coreretry'\nadb -s <device-id> reverse tcp:39342 tcp:39342\nflutter test --no-pub integration_test/core_parity_test.dart -d <device-id> --dart-define=APP_ENV=dev --dart-define=OPENMEETING_SERVER_URL=http://127.0.0.1:39110 --reporter expanded -v\n\`\`\`\n\n收集器用 OPENMEETING_CORE_ARTIFACT_DIR 指向本目录，node tests/e2e/mobile-core-bridge.mjs；报告生成 node tests/e2e/mobile-core-native-report.mjs。本次耗时 ${Math.round(budget.elapsedMs / 1000)} / 1800 秒，预算内 ${budget.withinBudget}，未覆盖前次预算文件。\n\n`;
md += `## 步骤产物\n\n| 阶段 | 操作 | 预期 | 实际 | 通过 | 截图/采集帧 |\n|---|---|---|---|---|---|\n`;
for (const r of rows) md += `| ${cell(r.phase)} | ${cell(r.operation)} | ${cell(r.expected)} | ${cell(r.actual)} | ${r.pass ? '是' : '否'} | ${r.screenshot ? `[截图](${r.screenshot})` : '—'} ${r.frame ? `[原始帧](${r.frame})` : ''} |\n`;
md += `\n## 实际截图检查\n\n真机逻辑视口 960×600，PNG 1920×1200；本轮布局修复同时回归 390×844 与 1024×768。无 in-app browser，使用 integration_test 与 ADB 截图。先通过对应流程断言，再统一截图复演；实际逐张查看新增/变化图像，字节 SHA-256 完全相同的图片复用此前实际查看记录，不把未查看的新图片标记通过。\n\n最终真机图 ${nativeImages.length} 张，双视口图 ${desktopImages.length} 张；视觉未通过 ${result.visualFailed} 张。范围含正常、加载、错误、权限、共享业务成功等待、原生真实帧、弹窗打开关闭、成员只读、滚动和结束首页。\n\n| 图片 | 尺寸 | 视觉通过 | 检查 |\n|---|---|---|---|\n`;
for (const r of reviews) md += `| [${path.basename(r.file)}](${r.file}) | ${r.width}×${r.height} | ${r.pass ? '是' : '否'} | ${cell(r.note)} |\n`;
md += `\n## 范围与剩余风险\n\n真机实际运行生产页面/路由/控制器，会议身份、业务仓库、SDK 发布和网络采样 UI 值为显式夹具；系统 MediaProjection 授权、前台服务、采集首帧、原始像素和原生预览是真实 Android 路径。**没有向真实远端发布共享像素，未完成移动端与桌面端实时画面互通验收，也不宣称硬件收音、真实模型和所有功能全量联调通过。**\n\n## 保留证据与关闭\n\n- [最终日志](logs/android-attempt-04.txt)、[逐步结果](android-results.json)、[最终返回值](runner-exit-04.json)、[夹具冒烟](logs/fixture-smoke.txt)、[双视口日志](logs/desktop-narrow-regression.txt)。\n- [诊断尝试 01](logs/android-attempt-01.txt)、[尝试 01 产物](history/attempt-01/)、[尝试 02 日志](logs/android-attempt-02.txt)、[尝试 02 视觉失败](history/attempt-02/visual-attempt-02.json) 均保留。\n- 静态检查无问题：${result.staticClean}，见 [日志](logs/analyze-final.txt)。\n- 息屏设置恢复：${result.screenTimeoutRestored}；收集服务关闭：${result.bridgeClosed}；设备/映射/原应用检查：[清理日志](device-cleanup.json)。Gradle 停止：[日志](logs/gradle-stop.txt)。没有清除原应用数据。\n`;
fs.writeFileSync(path.join(out, '测试报告.md'), md);
console.log(JSON.stringify(result));
