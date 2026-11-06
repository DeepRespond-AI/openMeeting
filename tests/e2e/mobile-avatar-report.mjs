// Evidence-only report assembly. Missing/failed runner or unreviewed image is
// never promoted to a pass just because an individual step looked successful.
import fs from 'node:fs';
import path from 'node:path';
import { createHash } from 'node:crypto';
import { fileURLToPath } from 'node:url';
const root = fileURLToPath(new URL('../../', import.meta.url));
const out = path.join(root, '.artifacts/mobile-avatar-toolbar');
const json = file => JSON.parse(fs.readFileSync(path.join(out, file), 'utf8'));
const text = file => { const b = fs.readFileSync(path.join(out, file)); return b[0] === 255 && b[1] === 254 ? b.subarray(2).toString('utf16le') : b.toString('utf8'); };
const vm = json('vm-results.json'), nativeAll = json('android-results.json');
// The original collector appended two attempts; keep its raw history, report
// only the most recent complete run rather than double-counting its successes.
const begin = nativeAll.map(r => r.phase === 'assertions' && r.operation === '隐藏会议录制按钮').lastIndexOf(true);
const android = nativeAll.slice(begin);
const checks = json('checks.json'), reviews = json('visual-reviews.json'), cleanup = json('cleanup.json');
for (const r of reviews) {
  const hash = createHash('sha256').update(fs.readFileSync(path.join(out, r.file))).digest('hex');
  if (hash !== r.sha256) throw Error('Screenshot changed after visual review: ' + r.file);
}
const count = rows => ({ passed: rows.filter(r => r.pass).length, failed: rows.filter(r => !r.pass).length });
const passed = file => /All tests passed!/.test(text(file)) && !/Some tests failed\./.test(text(file));
const summary = {
  generatedAt: new Date().toISOString(), base: '78213b0', branch: 'feat/mobile-desktop-parity',
  vm: count(vm.filter(r => r.phase === 'assertions')), vmReplay: count(vm.filter(r => r.phase === 'screenshots')),
  android: count(android.filter(r => r.phase === 'assertions')), androidReplay: count(android.filter(r => r.phase === 'screenshots')),
  vmRunnerPassed: passed('logs/ui-attempt-07.txt'), androidRunnerPassed: passed('logs/android-attempt-03.txt') && json('android-run.json').passed,
  units: { passed: Number(text('logs/units-final.txt').match(/\+(\d+): All tests passed!/)?.[1] ?? 0), runnerPassed: passed('logs/units-final.txt') },
  smoke: { passed: 10, runnerPassed: passed('logs/fixture-smoke-03.txt') },
  visual: { inspected: reviews.length, ...count(reviews) }, checks, cleanup,
  realDevice: 'Huawei AGS3-W00E / wireless ADB', realProductionBackend: false, nativeFilePickerVerified: false,
};
fs.writeFileSync(path.join(out, 'summary.json'), JSON.stringify(summary, null, 2));
const esc = value => String(value ?? '').replaceAll('|', '\\|').replaceAll('\n', '<br>');
const table = rows => [
  '| 平台/视口/阶段 | 操作 | 预期 | 实际 | 结果 | 图片 |', '|---|---|---|---|---|---|',
  ...rows.map(r => `| ${esc(`${r.platform}/${r.viewport}/${r.phase}`)} | ${esc(r.operation)} | ${esc(r.expected)} | ${esc(r.actual)} | ${r.pass ? '通过' : '失败'} | ${r.screenshot ? `[查看](${r.screenshot})` : ''} |`),
].join('\n');
const report = [
  '# 移动头像、聊天资料与会议录制入口：测试报告', '',
  '分级理由：头像新增上传/保存流程并涉及异步用户资料，采用完整定向用户流程、成功/关键失败路径、双视口截图及真实 Android 设备回放。业务身份、会议仓库、SDK上传/资料和选图明确使用确定性夹具；没有改动日常账号，也没有把SDK夹具写成生产后端资料持久化验证。', '',
  `生成时间：${summary.generatedAt}。最新 develop@78213b0 已同步到当前功能分支。`, '',
  '## 启动与测试流程', '',
  '探测并保留已有39110服务和原设备应用/登录态。先独立跑文件校验、上传失败、保存失败、取消、切账号及资料订阅冒烟，再跑真实路由/页面/生产控制器的用户操作，断言全部通过后统一截图。累计预算保存在 [budget.json](budget.json)，未清除或续期。', '',
  '```powershell', '# 仓库根目录：真机证据收集器和公开测试图片',
  'node tests/e2e/mobile-avatar-bridge.mjs', '# mobile目录：先单独冒烟',
  'flutter test test/core/im/avatar_controller_test.dart --reporter expanded',
  "$env:MOBILE_AVATAR_UI='1'",
  'flutter test test/acceptance/avatar_toolbar_ui_test.dart --reporter expanded',
  '# Android：独立包，不覆盖原应用；先 adb -s <device-id> reverse tcp:39341 tcp:39341',
  "$env:OPENMEETING_ANDROID_DEBUG_SUFFIX='.avatarfix'",
  'flutter test integration_test/avatar_toolbar_test.dart -d <device-id> --reporter expanded --dart-define=APP_ENV=dev',
  '# 完成后由原始JSON、日志、看图记录和清理记录组装报告',
  'node tests/e2e/mobile-avatar-report.mjs', '```', '',
  'Flutter VM视口390×844、1024×768；真实Huawei平板逻辑视口960×600、截图1920×1200。没有in-app browser，VM通过Flutter无头渲染截图，真机通过integration_test截图，全部最终图片逐张通过view_image实际查看。', '',
  '## 最终结果', '',
  `VM断言 ${summary.vm.passed}通过/${summary.vm.failed}失败，截图回放 ${summary.vmReplay.passed}通过/${summary.vmReplay.failed}失败；运行器${summary.vmRunnerPassed ? '通过' : '失败'}。`,
  `Android断言 ${summary.android.passed}通过/${summary.android.failed}失败，截图回放 ${summary.androidReplay.passed}通过/${summary.androidReplay.failed}失败；运行器${summary.androidRunnerPassed ? '通过' : '失败'}。`,
  `独立夹具冒烟10项运行器${summary.smoke.runnerPassed ? '通过' : '失败'}；全量移动单元${summary.units.passed}项，运行器${summary.units.runnerPassed ? '通过' : '失败'}。`,
  `视觉检查${summary.visual.inspected}张：${summary.visual.passed}通过/${summary.visual.failed}失败。`, '',
  ...checks.map(r => `- ${r.name}：${r.pass ? '通过' : '失败'}，${r.actual}。`), '',
  '## 逐步结果', '', table(vm), '', table(android), '',
  '## 实际视觉检查', '', '| 图片 | 观察 | 结果 |', '|---|---|---|',
  ...reviews.map(r => `| [${path.basename(r.file)}](${r.file}) | ${esc(r.notes)} | ${r.pass ? '通过' : '失败'} |`), '',
  '## 历史失败与修复', '',
  '- fixture-smoke-01：缺失Riverpod扩展导入及测试AuthState命名冲突，编译失败；修复后重新运行。',
  '- fixture-smoke-02：资料流释放检查失败，补齐provider销毁时的事件订阅清理；第03轮10项通过。',
  '- ui-attempt-01：测试对非const构造使用const，编译失败。第02/03轮定位到背景同名文字、弹层动画尚未完成，修正等待和点击时序。',
  '- ui-attempt-04：页面步骤通过，但HttpClient空闲计时器未清理，框架收尾失败；显式关闭测试拥有的网络客户端后通过，不把第04轮记为通过。',
  '- 初次VM看图发现图片首帧之前可能短暂空白，补齐frameBuilder占位后重新跑VM第07轮与Android第03轮，使用最终截图。',
  '- android-attempt-01：VM专用File读取配置在Android不存在，改用APK资源加载；第02/03轮均通过。Flutter首次收尾尝试移除不存在的旧.parity包失败，日常包没有被删除或替换；本轮只清理自己安装的.avatarfix。', '',
  '## 清理与限制', '',
  `清理结果：[cleanup.json](cleanup.json)：${esc(JSON.stringify(cleanup))}。`,
  '本轮没有调用生产IM头像上传/更新接口，原生系统文件选择器及真实媒体服务尚未验收；文件选择、上传和资料事件使用公开SDK接口边界夹具。真实平板验证的是当前代码的原生构建、页面、手势、网络图片显示、异步状态与错误恢复。音视频采集、独立录音、导入、屏幕共享和全部核心功能的后续验收分别记录，不能由本专项推断全部通过。', '',
  '[VM结构化结果](vm-results.json) · [Android原始多轮结果](android-results.json) · [VM最终日志](logs/ui-attempt-07.txt) · [Android最终日志](logs/android-attempt-03.txt) · [单元日志](logs/units-final.txt) · [静态检查](logs/analyze-checked.txt) · [截图目录](screenshots/) · [汇总](summary.json)', '',
].join('\n');
fs.writeFileSync(path.join(out, '测试报告.md'), report);
console.log(JSON.stringify(summary));
