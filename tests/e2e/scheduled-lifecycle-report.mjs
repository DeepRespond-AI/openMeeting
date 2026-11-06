import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
const root = fileURLToPath(new URL('../../', import.meta.url)), out = path.join(root, '.artifacts/scheduled-meeting-lifecycle');
const archive = path.join(root, 'docs/testing/archive/预定会议固定会议号与多场次');
const decode = p => { const b = fs.readFileSync(p); return (b[0] === 255 && b[1] === 254 ? b.subarray(2).toString('utf16le') : b.toString('utf8')).replace(/^\uFEFF/, ''); };
const read = name => JSON.parse(decode(path.join(out, name)));
const optional = (name, fallback) => fs.existsSync(path.join(out, name)) ? read(name) : fallback;
const result = read('results.json'), android = optional('android-results.json', { rows: [] }), smoke = read('smoke.json');
const component = optional('component/results.json', { checks: [], screenshots: [] });
const extra = optional('room-results.json', { steps: [] });
const checks = [
  ['后端生命周期', 'backend.xml', /failures="0"/, 34], ['后端录音回归', 'backend-regression.xml', /failures="0"/, 8],
  ['前端单元', 'frontend-unit.log', /24 test files, 0 failed/, null], ['移动端单元', 'mobile-unit.log', /All tests passed!/, 2],
  ['TypeScript', 'typescript.log', /^\s*$/, null], ['移动端静态检查', 'mobile-analyze-final.log', /No issues found!/, null],
  ['Rust编译', 'rust-check-retry.log', /Finished `dev` profile/, null],
  ['Android原生整套', 'android-flutter.log', /All tests passed!/, 1],
].map(([operation, log, pattern, count]) => {
  const text = decode(path.join(out, log));
  if (operation === '前端单元') count = [...text.matchAll(/^\s*(\d+) pass\s*$/gm)].reduce((sum, m) => sum + Number(m[1]), 0);
  return { operation, log, count, pass: pattern.test(text) };
});
fs.writeFileSync(path.join(out, 'checks.json'), JSON.stringify(checks, null, 2));
const visual = optional('visual-reviews.json', {}), cleanup = optional('cleanup.json', { pending: true });
const steps = [...result.steps, ...android.rows, ...extra.steps], assertions = steps.filter(x => x.phase === 'assertions'), shots = steps.filter(x => x.screenshot);
const supplemental = component.screenshots.map(name => 'component/' + name);
const images = [...shots.map(x => x.screenshot), ...supplemental];
const clean = x => String(x ?? '').replaceAll('|', '/').replaceAll('\n', ' ');
const budget = read('budget.json');
const history = [];
for (const group of ['history', 'android-history', 'component-history', 'room-history']) {
  const dir = path.join(out, group); if (!fs.existsSync(dir)) continue;
  for (const name of fs.readdirSync(dir)) {
    const base = group + '/' + name;
    const json = fs.existsSync(path.join(out, base, 'results.json')) ? 'results.json' : fs.existsSync(path.join(out, base, 'room-results.json')) ? 'room-results.json' : 'android-results.json';
    if (!fs.existsSync(path.join(out, base, json))) continue;
    const data = read(base + '/' + json), failed = (data.steps || data.rows || []).filter(s => !s.pass || /Exception|AssertionError/.test(s.actual || ''));
    history.push(`| ${base} | [原始结果](${base}/${json}) ${fs.existsSync(path.join(out, base, 'android-flutter.log')) ? `[失败日志](${base}/android-flutter.log)` : ''} | ${clean(data.error || data.failure || (name === 'initial' && group === 'room-history' ? '功能通过；短暂通知遮挡标题，最终重采' : failed.map(s => s.actual).join('; ') || '整套失败原因见保留日志'))} | ${failed.filter(s => s.screenshot).map(s => `[失败截图](${s.screenshot})`).join(' ') || (fs.existsSync(path.join(out, base, 'failure.png')) ? `[失败截图](${base}/failure.png)` : '该次没有失败截图，不能将邻近成功图当作失败图')} |`);
  }
}
const lines = ['# 预定会议固定会议号与多场次测试报告', '',
  '分级：跨后端、桌面和移动端的生命周期改动，执行完整预定流程与关键失败路径。真实 meeting_ms 源码、隔离 PostgreSQL、生产 Next 页面和 Android Flutter 页面/控制器；身份、IM、RTC、模型调度为显式测试夹具。桌面主流程中开会/结束由真实业务API驱动，另有--room-ui完整验证生产入会、继续会议、确认结束和同号再次进入；移动端通过生产按钮进入/结束。无 in-app browser，使用无头 Chromium 与 ADB 原生截图。', '',
  `最终功能步骤：${assertions.filter(x => x.pass).length} 通过，${assertions.filter(x => !x.pass).length} 失败；截图复核步骤：${steps.filter(x => x.phase === 'screenshots' && x.pass).length} 通过；独立冒烟：${smoke.filter(x => x.pass).length} 通过、${smoke.filter(x => !x.pass).length} 失败；补充组件回归：${component.checks.filter(x => x.pass).length} 通过。代码检查 ${checks.filter(x => x.pass).length} 通过、${checks.filter(x => !x.pass).length} 失败。`, '',
  `累计 E2E 调试预算 30 分钟，当前消耗 ${(budget.usedMs / 60000).toFixed(1)} 分钟，失败未重置。桌面错误：${clean(result.error || '无')}；Android最终整套结果以 [Flutter日志](android-flutter.log) 的通过/失败为准，步骤成功不替代整套成功。`, '',
  '启动：先运行隔离 PostgreSQL 16（127.0.0.1:55442），创建 scheduled_lifecycle_test 与 scheduled_lifecycle_e2e 数据库。设置 OPENMEETING_SCHEDULED_TEST_DATABASE=postgresql+asyncpg://openmeeting:openmeeting@localhost:55442/scheduled_lifecycle_e2e、OPENMEETING_SCHEDULED_OUTPUT=产物绝对路径、PYTHONPATH=项目/server，执行 server/.venv 对应 Python 的 `tests/e2e/fixtures/scheduled-lifecycle-service.py`（:3169）。先 `node tests/e2e/scheduled-lifecycle.mjs --smoke`，再无参数执行同脚本。自动启动 Next :3168，OPENMEETING_E2E_DESKTOP_LAYOUT=1、NEXT_PUBLIC_LIVE_MEETING_DATA_SOURCE=real、独立 .next-e2e-scheduled-lifecycle。', '',
  'Android：用户已授权使用模拟器；复用 OpenMeeting_DEV_C_1e6c55，emulator-5580，无擦除启动；ADB reverse 3169/39349。执行 `node tests/e2e/scheduled-lifecycle-android.mjs`，mobile 目录设置 OPENMEETING_ANDROID_DEBUG_SUFFIX=.scheduledtest，执行 `flutter test --no-pub integration_test/scheduled_lifecycle_test.dart -d emulator-5580 --dart-define=APP_ENV=dev --reporter expanded`。桌面最后通过表单创建的固定号由 Android 读取、修改、重复开会、取消；媒体 activate 为显式替身，真实加入/结束/持久化仍走生产控制器和真实 HTTP。', '',
  'Android首轮assertions使用桌面创建的预定；screenshots复验使用移动端新建预定，沿用相同功能步骤。Android模拟器时区为UTC，桌面为Asia/Shanghai，各端以设备本地时间显示。结束失败的原生UI步骤实际断言错误展示和保持会中；不把步骤文案中的“记录数不增加”单独视为原生计数断言，记录持久化/场次数量由独立真实数据库测试覆盖。', '',
  '环境与登录：' + clean(JSON.stringify(result.probe)) + '。保留原3118/39110；未开放CDP登录态，因此采用隔离测试身份和桌面登录表单，不改日常账号。原真机未操作。', '',
  '| 阶段/视口 | 操作 | 预期 | 实际 | 结果 | 截图 |', '|---|---|---|---|---|---|',
  ...steps.map(s => `| ${s.phase}/${s.viewport || s.platform} | ${clean(s.operation)} | ${clean(s.expected)} | ${clean(s.actual)} | ${s.pass ? '通过' : '失败'} | ${s.screenshot ? `[截图](${s.screenshot})` : '—'} |`), '',
  '| 检查 | 用例数 | 结果 | 证据 |', '|---|---|---|---|',
  ...checks.map(c => `| ${c.operation} | ${c.count ?? '编译/静态'} | ${c.pass ? '通过' : '失败'} | [日志](${c.log}) |`), '',
  `截图 ${images.length} 张，实际查看 ${images.filter(p => visual[p]).length} 张，视觉通过 ${images.filter(p => visual[p]?.pass).length} 张。桌面1280×800、窄视口520×760，补充组件窄视口390×844，Android1080×2400。正式主流程先完成断言后统一截图；补充组件图仅作为额外状态证据。`, '',
  '| 截图 | 实际查看结果 |', '|---|---|', ...images.map(p => `| [${path.basename(p)}](${p}) | ${visual[p] ? `${visual[p].pass ? '通过' : '失败'}：${clean(visual[p].notes)}` : '未查看，不能标记视觉通过'} |`), '',
  '故障截图是主动触发的确定性503，用于证明错误展示、输入保留、重试有效，不代表生产 IM 故障。活动场次无法编辑/取消由真实409与按钮禁用共同验证。两次场次不同Room/Meeting/Job、结束幂等、房主预览无写入、并发复用、非房主不能启动、历史记录保留均有真实数据库测试。', '',
  '历史失败保留：history/ 为桌面早期登录等待和空态文案选择器失败；android-history/initial/ 为九步骤通过后，截图准备创建点到同名页签导致整套失败；android-history/screenshot-path/ 为截图桥拒绝带数字文件名导致整套失败（旧版将功能断言通过误留为pass:true，该次整套明确失败，不计为通过）。component-history/initial/ 保留缺少 MeetingEntry 测试边界；后续还修正旧日期按钮定位与关闭动画DOM计数。room-history/clean-capture-failed/ 保留补采时查到同名旧已取消预定的选择器错误，已改唯一测试标题；初次会中功能通过但通知遮住部分标题的截图保留于room-history/initial/，不计最终视觉通过。首次Rust编译因FFmpeg下载中断，复用已有可信缓存后重试成功；移动端初次Provider缺少扩展导入已修复。所有历史失败均不计通过。', '',
  '| 历史尝试 | 原始证据 | 原因/结果 | 对应失败图 |', '|---|---|---|---|', ...history, '',
  '补充组件脚本的旧日期按钮和关闭动画计数两次调试没有单独留存完整日志，不能复原每次运行；最终对应断言已修正并重新执行通过。Rust首次失败见[rust-check.log](rust-check.log)。', '',
  '关闭结果：' + clean(JSON.stringify(cleanup)) + '。Next内部桥已自动关闭并恢复tsconfig：' + clean(JSON.stringify(result.cleanup)) + '。', '',
  '剩余风险：未重验真实IM建群/授权、真实RTC传输、设备录音、STT/纪要模型及iOS；记录测试验证独立记录/任务持久化和可访问性，不声明本轮真实音频转写成功。客户端与服务端应同步升级 activeRoomId/hostUserId 语义。房主退出通过结束当前场次完成；继续会议仅关闭确认，不新增无房主持续采集机制。', '',
  '[逐步结果](results.json) · [Android结果](android-results.json) · [故障冒烟](smoke.json) · [代码检查](checks.json) · [视觉检查](visual-reviews.json) · [清理](cleanup.json)', ''];
fs.writeFileSync(path.join(out, '测试报告.md'), lines.join('\n'));
if (process.argv.includes('--archive')) {
  fs.mkdirSync(archive, { recursive: true });
  for (const name of ['results.json', 'android-results.json', 'android-database.json', 'smoke.json', 'budget.json', 'checks.json', 'visual-reviews.json', 'cleanup.json', 'mobile-cleanup.json', 'interop-seed.json', 'seed-results.json', 'room-results.json', '测试报告.md', ...checks.map(x => x.log), 'rust-check.log', 'backend.log', 'backend-regression.log', 'mobile-integration-analyze.log', 'android-flutter.log', 'desktop-e2e.log', 'room-ui.log', 'component.log']) {
    const source = path.join(out, name); if (fs.existsSync(source)) fs.writeFileSync(path.join(archive, name), decode(source).replace(/[\t ]+$/gm, ''));
  }
  for (const dir of ['screenshots', 'component', 'history', 'android-history', 'component-history', 'room-history']) if (fs.existsSync(path.join(out, dir))) fs.cpSync(path.join(out, dir), path.join(archive, dir), { recursive: true });
  const normalize = dir => { for (const entry of fs.readdirSync(dir, { withFileTypes: true })) { const file = path.join(dir, entry.name); if (entry.isDirectory()) normalize(file); else if (/\.(log|json|md|txt|xml)$/.test(entry.name)) fs.writeFileSync(file, decode(file).replace(/[\t ]+$/gm, '')); } }; normalize(archive);
}
console.log(JSON.stringify({ assertions: { passed: assertions.filter(x => x.pass).length, failed: assertions.filter(x => !x.pass).length }, images: images.length, checks, report: process.argv.includes('--archive') ? archive : out }));
