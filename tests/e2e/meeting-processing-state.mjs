import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import { spawn, spawnSync } from 'node:child_process';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
import { installLayoutBridge } from './fixtures/desktop-layout-backend.mjs';
import { startSharedRecordsBackend, sharedId, sharedTitle } from './fixtures/shared-records-backend.mjs';

const root = fileURLToPath(new URL('../../', import.meta.url)), front = path.join(root, 'frontend');
const out = path.join(root, '.artifacts/meeting-processing-state');
const archive = path.join(root, 'docs/testing/archive/会后处理状态与转写空态');
const ui = 'http://localhost:3167';
fs.mkdirSync(path.join(out, 'screenshots'), { recursive: true });
const read = file => JSON.parse(fs.readFileSync(path.join(out, file), 'utf8').replace(/^\uFEFF/, ''));
const write = (file, value) => fs.writeFileSync(path.join(out, file), JSON.stringify(value, null, 2));
const sleep = ms => new Promise(resolve => setTimeout(resolve, ms));
function report(destination = out) {
  fs.mkdirSync(destination, { recursive: true });
  const r = read('results.json'), smoke = read('smoke.json');
  const android = fs.existsSync(path.join(out, 'android-results.json')) ? read('android-results.json') : null;
  const nativeRows = (android?.rows || []).map(s => ({ ...s, viewport: s.platform === 'android-emulator' ? 'Android 1080x2400' : 'interop 1280x800' }));
  const steps = [...r.steps, ...nativeRows];
  const cleanup = fs.existsSync(path.join(out, 'mobile-cleanup.json')) ? read('mobile-cleanup.json') : null;
  const checks = fs.existsSync(path.join(out, 'checks.json')) ? read('checks.json') : [];
  const visual = fs.existsSync(path.join(out, 'visual-reviews.json')) ? read('visual-reviews.json') : {};
  const notes = fs.existsSync(path.join(out, 'history-notes.json')) ? read('history-notes.json') : {};
  const rows = steps.filter(s => s.phase === 'assertions'), images = steps.filter(s => s.screenshot);
  const clean = value => String(value).replaceAll('|', '/').replaceAll('\n', ' ');
  const history = fs.existsSync(path.join(out, 'history')) ? fs.readdirSync(path.join(out, 'history')) : [];
  const text = ['# 多端会后转写状态与主动云下载测试报告', '',
    '分级：会后详情状态协调和主动下载交互调整，使用真实 Next 页面与项目 Playwright 验证登录→三独立会话入会→成员提前离开→房主结束→全员转写自动更新，并覆盖受影响失败路径。HTTP/IPC/IM/RTC 使用显式夹具，WAV 为合成音频；不等同于三台真实设备、原生落盘、真实 RTC 采集或模型转写验收。无 in-app browser，使用无头 Chromium。', '',
    `最终功能断言 ${rows.filter(s => s.pass).length} 通过、${rows.filter(s => !s.pass).length} 失败（桌面双视口三会话42项，Android原生页面与桌面共享会后状态8项）；截图复核 ${steps.filter(s => s.phase === 'screenshots' && s.pass).length} 通过。独立夹具冒烟 ${smoke.filter(s => s.pass).length} 通过、${smoke.filter(s => !s.pass).length} 失败。代码检查 ${checks.filter(s => s.pass).length} 通过、${checks.filter(s => !s.pass).length} 失败。`, '',
    `E2E 累计调试预算30分钟，不因失败重置；累计 ${(read('budget.json').usedMs / 60000).toFixed(1)} 分钟。运行错误：${clean(r.error || '无')}。`, '',
    '启动方式：先 `node tests/e2e/meeting-processing-state.mjs --smoke` 单独验证故障入口，再执行无参数脚本。脚本启动独立 Next :3167，OPENMEETING_E2E_DESKTOP_LAYOUT=1、OPENMEETING_NEXT_DIST_DIR=.next-e2e-meeting-processing、NEXT_PUBLIC_LIVE_MEETING_DATA_SOURCE=real，以及随机回环 HTTP 夹具。', '',
    'Android追加验收：用户授权启动虚拟机后，使用现有OpenMeeting_DEV_C_1e6c55 AVD、emulator-5580，隔离包cn.deeprespond.meeting.processingtest。先运行 `node tests/e2e/meeting-processing-android.mjs`，再在mobile运行 `flutter test --no-pub integration_test/meeting_processing_test.dart -d emulator-5580 --dart-define=APP_ENV=dev --reporter expanded`，构建时OPENMEETING_ANDROID_DEBUG_SUFFIX=.processingtest。ADB reverse :39348连接同一共享任务夹具，真实Android Flutter详情与桌面页面共同验证queued/running→completed→failed，转写页保持打开时轮询不中断。没有建立真实跨端RTC房间，原生音频落盘/播放不计本轮通过。', '',
    '原服务/登录态探测：' + clean(JSON.stringify(r.probe)) + '。保留原3118/39110和原客户端；无可复用CDP登录态，三个隔离上下文均通过登录表单建立夹具会话。在线成员收到显式room_ended事件，提前离开成员通过可信IM通知打开记录。', '',
    '| 阶段/视口 | 操作 | 预期 | 实际 | 结果 | 截图 |', '|---|---|---|---|---|---|',
    ...steps.map(s => `| ${s.phase}/${s.viewport} | ${s.operation} | ${s.expected} | ${clean(s.actual)} | ${s.pass ? '通过' : '失败'} | ${s.screenshot ? `[截图](${s.screenshot})` : '—'} |`), '',
    '| 代码检查 | 退出码 | 结果 | 日志 |', '|---|---|---|---|',
    ...checks.map(s => `| ${s.operation} | ${s.exitCode} | ${s.pass ? '通过' : '失败'} | [日志](${s.log}) |`), '',
    `正式截图 ${images.length} 张，实际查看 ${images.filter(s => visual[s.screenshot]).length} 张，视觉通过 ${images.filter(s => visual[s.screenshot]?.pass).length} 张。桌面1280×800，窄视口520×760，Android1080×2400；先断言后统一截图。`, '',
    '| 截图 | 实际查看与视觉结果 |', '|---|---|',
    ...images.map(s => `| [${path.basename(s.screenshot)}](${s.screenshot}) | ${visual[s.screenshot] ? `${visual[s.screenshot].pass ? '通过' : '失败'}：${visual[s.screenshot].notes}` : '未查看，不标记视觉通过'} |`), '',
    '错误态截图通过主动注入状态503、任务失败/取消和录音下载503产生，用于验证页面处理错误；不是生产服务故障证据。打开记录和状态刷新只读取会议数据，不得出现server_fetch_meeting_audio调用；只有云下载点击可产生一次调用。', '',
    '| 历史尝试 | 原始结果与失败证据 |', '|---|---|',
    ...history.map(name => { const h = JSON.parse(fs.readFileSync(path.join(out, 'history', name, 'results.json'), 'utf8')); return `| ${name} | [结果](history/${name}/results.json) ${h.steps.filter(s => !s.pass).map(s => `[失败截图](history/${name}/${s.screenshot})`).join(' ')} ${clean(notes[name] || h.error || '无运行错误')} |`; }), '',
    '关闭结果：' + clean(JSON.stringify(r.cleanup)) + '。保留构建缓存，不关闭原服务。', '',
    'Android协调器关闭：' + clean(JSON.stringify(android?.cleanup)) + '；模拟器与隔离包清理：' + clean(JSON.stringify(cleanup)) + '。原真机未发送操作。', '',
    '剩余边界：本轮验证三个桌面页面会话、Android原生详情及共享夹具状态，音频下载文件仍由既有原生接口负责；真实设备音轨分片上传、后端模型输出、IM真实投递、Rust文件落盘及iOS未重新验收。Android播放器打开时不再自动加载，下载后使用本地文件；此行为另由11项定向移动单元/文件测试覆盖，未宣称本轮原生播放硬件通过。interop-desktop-running截图顶部保留上一轮排队提示，属于轮询窗口；两阶段转写都显示处理中，不表示无语音，不计作实时横幅同步证明。', '',
    '历史环境检查：初次本机l10n命令遇到sqlite3下载中断，复用既有工具和缓存后生成完成；首次移动静态检查发现测试throw类型问题，已修正，最终结果见日志。首轮Android共享状态测试通过，随后补充失败提示及云下载文案并重新构建验收，旧结果保留在android-history/initial-passed，旧截图未作本轮视觉通过。', '',
    '[Android结果](android-results.json) · [Android构建/测试日志](android-flutter.log) · [移动单元](mobile-unit.log) · [移动静态检查](mobile-analyze.log) · [模拟器清理](mobile-cleanup.json)', '',
    '[逐步结果](results.json) · [夹具冒烟](smoke.json) · [代码检查](checks.json) · [视觉记录](visual-reviews.json)', ''];
  fs.writeFileSync(path.join(destination, '测试报告.md'), text.join('\n'));
  if (destination === archive) {
    for (const name of ['results.json', 'smoke.json', 'checks.json', 'budget.json', 'visual-reviews.json', 'history-notes.json', 'android-results.json', 'mobile-cleanup.json', 'android-flutter.log', 'mobile-unit.log', 'mobile-analyze.log']) if (fs.existsSync(path.join(out, name))) fs.copyFileSync(path.join(out, name), path.join(destination, name));
    for (const c of checks) fs.writeFileSync(path.join(destination, c.log), fs.readFileSync(path.join(out, c.log), 'utf8').replace(/[\t ]+$/gm, ''));
    const copyShots = (source, target, result) => {
      for (const s of result.steps.filter(s => s.screenshot)) {
        const to = path.join(target, s.screenshot); fs.mkdirSync(path.dirname(to), { recursive: true }); fs.copyFileSync(path.join(source, s.screenshot), to);
      }
    };
    copyShots(out, destination, r);
    copyShots(out, destination, { steps: nativeRows });
    if (fs.existsSync(path.join(out, 'android-history'))) fs.cpSync(path.join(out, 'android-history'), path.join(destination, 'android-history'), { recursive: true });
    for (const name of history) {
      const source = path.join(out, 'history', name), target = path.join(destination, 'history', name); fs.mkdirSync(target, { recursive: true });
      fs.copyFileSync(path.join(source, 'results.json'), path.join(target, 'results.json'));
      copyShots(source, target, JSON.parse(fs.readFileSync(path.join(source, 'results.json'), 'utf8')));
    }
  }
  console.log(JSON.stringify({ report: path.join(destination, '测试报告.md'), passed: rows.filter(s => s.pass).length, failed: rows.filter(s => !s.pass).length, screenshots: images.length }));
}
if (process.argv.includes('--report') || process.argv.includes('--archive')) { report(process.argv.includes('--archive') ? archive : out); process.exit(0); }
if (process.argv.includes('--checks')) {
  const results = [];
  for (const [operation, file, args] of [
    ['TypeScript', 'node_modules/typescript/bin/tsc', ['--noEmit']],
    ['frontend-unit', 'scripts/test-unit.mjs', []],
    ['recording-contract', 'tests/contracts/room-recording.mjs', []],
    ['audio-contract', 'tests/contracts/meeting-audio.mjs', []],
  ]) {
    const result = spawnSync(process.execPath, [file, ...args], { cwd: front, env: process.env, encoding: 'utf8', windowsHide: true });
    const log = `check-${operation}.txt`; fs.writeFileSync(path.join(out, log), (result.stdout || '') + (result.stderr || '') + (result.error || ''));
    const row = { operation, exitCode: result.status, pass: result.status === 0, log }; results.push(row); console.log(JSON.stringify(row));
  }
  write('checks.json', results); process.exit(results.every(s => s.pass) ? 0 : 1);
}
const backend = await startSharedRecordsBackend();
const control = async (session, shared, role, reset = false, patch = {}) => {
  const response = await fetch(backend.base + '/control', { method: 'POST', body: JSON.stringify({ session, shared, role, reset, patch }) });
  assert.equal(response.status, 200); return response.json();
};
const rpc = async (session, command, args = {}) => {
  const response = await fetch(backend.base + '/invoke', { method: 'POST', body: JSON.stringify({ session, command, args }) });
  return { status: response.status, data: await response.json() };
};
if (process.argv.includes('--smoke')) {
  const rows = [];
  const check = async (operation, expected, action) => {
    const row = { operation, expected, actual: '', pass: false, screenshot: null };
    try { row.actual = await action(); row.pass = true; } catch (e) { row.actual = String(e); throw e; }
    finally { rows.push(row); write('smoke.json', rows); console.log(JSON.stringify(row)); }
  };
  try {
    await control('host', { ended: true }, 'host', true); await control('host', { ended: true });
    await check('状态延迟确定性', '延迟至少180ms返回queued', async () => {
      await control('host', { statusDelay: 180 }); const start = Date.now(); const r = await rpc('host', 'room_recording_status');
      assert.equal(r.data.value.status, 'queued'); assert.ok(Date.now() - start >= 175); return 'queued + delayed';
    });
    await check('状态读取503及恢复', '503后可恢复running', async () => {
      await control('host', { statusDelay: 0, statusError: true }); assert.equal((await rpc('host', 'room_recording_status')).status, 503);
      await control('host', { statusError: false, status: 'running' }); assert.equal((await rpc('host', 'room_recording_status')).data.value.status, 'running'); return '503 → running';
    });
    await check('任务失败及重试恢复', 'failed带错误，retry恢复queued', async () => {
      await control('host', { status: 'failed', hasAudio: true }); assert.match((await rpc('host', 'room_recording_status')).data.value.error, /转写服务不可用/);
      await rpc('host', 'room_recording_retry'); assert.equal((await rpc('host', 'room_recording_status')).data.value.status, 'queued'); return 'failed → queued';
    });
    await check('完成转写与真实空结果入口', '完成65段，显式空结果0段', async () => {
      await control('host', { status: 'completed' }); assert.equal((await rpc('host', 'api_get_meeting_transcripts', { limit: 100 })).data.value.total_count, 65);
      await control('host', { emptyTranscripts: true }); assert.equal((await rpc('host', 'api_get_meeting_transcripts')).data.value.total_count, 0); return '65 → 0';
    });
    await check('音频下载503及延迟成功', '503恢复后获取合成WAV', async () => {
      await control('host', { audioError: true }); assert.equal((await rpc('host', 'server_fetch_meeting_audio')).status, 503);
      await control('host', { audioError: false, audioDelay: 180 }); const start = Date.now(); const r = await rpc('host', 'server_fetch_meeting_audio');
      assert.ok(Date.now() - start >= 175); const wav = Buffer.from(await (await fetch(r.data.value)).arrayBuffer()); assert.equal(wav.toString('ascii', 0, 4), 'RIFF'); return '503 → RIFF';
    });
  } finally { await backend.close(); }
  process.exit(0);
}
assert.ok(read('smoke.json').every(s => s.pass));
if (fs.existsSync(path.join(out, 'results.json'))) {
  const history = path.join(out, 'history', String(Date.now())); fs.mkdirSync(history, { recursive: true });
  fs.copyFileSync(path.join(out, 'results.json'), path.join(history, 'results.json'));
  fs.cpSync(path.join(out, 'screenshots'), path.join(history, 'screenshots'), { recursive: true });
}
const budget = fs.existsSync(path.join(out, 'budget.json')) ? read('budget.json') : { started: Date.now(), limitMs: 1800000 }; write('budget.json', budget);
const r = { started: new Date().toISOString(), steps: [], probe: [], cleanup: {} }, save = () => write('results.json', r);
const require = createRequire(path.join(front, 'package.json')), { chromium } = require('playwright');
const tsconfig = path.join(front, 'tsconfig.json'), tsconfigBefore = fs.readFileSync(tsconfig);
let next, browser, page, phase = 'assertions', sequence = 0;
async function step(operation, expected, action, shot) {
  if (Date.now() - budget.started > budget.limitMs) throw Error('E2E 30 minute budget exhausted; use API verification');
  const row = { phase, viewport: `${page.viewportSize().width}x${page.viewportSize().height}`, operation, expected, actual: '', pass: false, screenshot: null }; r.steps.push(row);
  try {
    row.actual = await action() || '符合预期';
    if (phase === 'screenshots' && shot) { row.screenshot = `screenshots/${String(++sequence).padStart(2, '0')}-${row.viewport}-${shot}.png`; await page.screenshot({ path: path.join(out, row.screenshot), animations: 'disabled' }); }
    row.pass = true;
  } catch (error) { row.actual = String(error.stack || error); row.screenshot = `screenshots/failure-${Date.now()}-${row.viewport}.png`; await page.screenshot({ path: path.join(out, row.screenshot) }).catch(() => {}); throw error; }
  finally { save(); console.log(JSON.stringify(row)); }
}
async function dismiss() {
  const close = page.locator('[data-sonner-toast][data-removed="false"] [data-close-button]');
  for (let i = 0; i < 10 && await close.count(); i++) await close.first().click();
  await page.waitForFunction(() => document.querySelectorAll('[data-sonner-toast]').length === 0);
}
async function layout() {
  const issues = await page.evaluate(() => {
    const issues = []; if (document.documentElement.scrollWidth > innerWidth + 1) issues.push('document overflow');
    for (const el of document.querySelectorAll('[role=dialog], [data-testid=recording-job-status], [data-testid=meeting-audio-player], [data-testid=transcript-empty-state]')) {
      if (!el.getClientRects().length) continue; const b = el.getBoundingClientRect();
      if (b.left < -1 || b.right > innerWidth + 1) issues.push('horizontal overflow');
      if (el.getAttribute('role') === 'dialog' && (b.top < -1 || b.bottom > innerHeight + 1)) issues.push('dialog outside viewport');
    } return issues;
  }); assert.deepEqual(issues, []); return '页面/状态/播放器/弹窗未越界';
}
async function makePage(size, session, role) {
  await control(session, undefined, role, false, { loggedIn: false });
  const context = await browser.newContext({ viewport: size, locale: 'zh-CN' });
  await context.addInitScript(installLayoutBridge, { base: backend.base, session }); const target = await context.newPage();
  target.setDefaultTimeout(12000); target.setDefaultNavigationTimeout(30000);
  await target.goto(ui, { waitUntil: 'domcontentloaded' }); await target.locator('#phone-auth-phone').fill('13800138000');
  await target.locator('#phone-auth-password').fill('LayoutTest123!'); await target.locator('form button[type=submit]').click();
  await target.getByRole('button', { name: /快速会议.*立即/ }).waitFor(); page = target; await dismiss();
  return { context, page: target, session };
}
const audioCalls = () => backend.calls.filter(c => c.command === 'server_fetch_meeting_audio').length;
const assertNoEmpty = async () => assert.equal(await page.getByText('该会议没有识别到语音内容。', { exact: true }).count(), 0);
async function transcript(mode) {
  await page.getByRole('tab', { name: '转写', exact: true }).click();
  await page.locator(`[data-testid=transcript-empty-state][data-state=${mode}]`).waitFor();
  if (mode !== 'empty') await assertNoEmpty(); return layout();
}
async function notice(target, seq) {
  await target.evaluate(({ seq, sharedId }) => window.__meetingFixture.control({ receive: { type: 'custom', sender: 'notice', conversation_id: 'notice', seq,
    body: { kind: 'openmeeting.meeting', version: 1, event: 'meeting_ended', meetingId: sharedId, title: '三端会议会后记录' } } }), { seq, sharedId });
}
async function flow(size) {
  const key = phase + size.width; await control(key, undefined, 'host', true);
  const host = await makePage(size, key + '-host', 'host'), online = await makePage(size, key + '-online', 'member'), early = await makePage(size, key + '-early', 'member');
  const clients = [host, online, early];
  try {
    page = host.page;
    await step('房主快速会议与三端加入', '房主自动录音，两个独立成员会话入会', async () => {
      await page.getByRole('button', { name: /快速会议.*立即/ }).click(); await page.getByTestId('room-recording-status').waitFor();
      for (const member of [online, early]) {
        page = member.page; await page.getByRole('button', { name: /加入会议.*入会/ }).click();
        for (let i = 0; i < 6; i++) await page.getByRole('textbox', { name: new RegExp(`第\\s*${i + 1}\\s*位`) }).fill('654321'[i]);
        await page.getByRole('dialog').getByRole('button', { name: '加入会议', exact: true }).click(); await page.getByTestId('room-recording-status').waitFor(); await dismiss();
      }
      return '三独立登录会话已加入（显式RTC夹具）';
    });
    page = early.page;
    await step('成员提前离开', '成员离开不结束房间', async () => {
      await page.getByRole('button', { name: '离开会议', exact: true }).click(); await page.waitForURL(url => url.pathname === '/');
      assert.equal((await control(early.session)).shared.ended, false); return layout();
    });
    page = host.page;
    await step('房主结束确认弹窗', '说明处理及提前离开成员可查看', async () => {
      await dismiss(); await page.getByRole('button', { name: '离开并结束', exact: true }).click();
      await page.getByRole('dialog').getByText(/含提前离开的成员/).waitFor(); return layout();
    }, '结束确认');
    await step('结束后三端记录等待', '房主、在线成员、早退成员均显示处理中而非无语音', async () => {
      await page.getByRole('dialog').getByRole('button', { name: '结束会议', exact: true }).click(); await page.waitForURL(url => url.pathname === '/');
      await page.getByRole('button', { name: sharedTitle }).click(); await page.waitForURL(url => url.pathname === '/meeting-details');
      await online.page.evaluate(sharedId => window.__layoutEmit('room-event', { roomId: 'room-layout', type: 'room_ended', ts: new Date().toISOString(), data: { meetingId: sharedId } }), sharedId);
      await online.page.waitForURL(url => url.pathname === '/');
      for (const member of [online, early]) { page = member.page; await notice(page, 1); await page.getByRole('button', { name: '查看会议记录', exact: true }).click(); await page.waitForURL(url => url.pathname === '/meeting-details'); }
      for (const client of clients) { page = client.page; await transcript('processing'); await dismiss(); }
      assert.equal(audioCalls(), 0); page = early.page; return layout();
    }, '早退成员处理中');
    page = host.page;
    await step('状态尚未返回', '读取状态期间不显示无语音', async () => {
      await control(host.session, { statusDelay: 2500 }); await page.reload({ waitUntil: 'domcontentloaded' });
      return transcript('checking');
    }, '确认状态中');
    await step('后台运行状态', '三端持续显示处理中，无音频下载', async () => {
      await control(host.session, { statusDelay: 0, status: 'running', hasAudio: true });
      for (const client of clients) { page = client.page; await page.getByTestId('recording-job-status').filter({ hasText: '正在处理会议录音' }).waitFor(); await transcript('processing'); }
      assert.equal(audioCalls(), 0); page = host.page; return '三会话收到running，下载IPC=0；' + await layout();
    }, '录音处理中');
    await step('后端完成且刷新有延迟', '完成信号到达后，首批转写刷新结束前不能显示无语音', async () => {
      await control(host.session, { status: 'completed', transcriptDelay: 1800 });
      await page.getByTestId('recording-job-status').filter({ hasText: '已就绪' }).waitFor();
      await transcript('processing'); return layout();
    }, '完成等待转写刷新');
    await step('三端转写自动出现', '无手工刷新，三端各显示65段，且不下载录音', async () => {
      for (const client of clients) {
        page = client.page; await page.getByRole('tab', { name: '转写', exact: true }).click(); await page.getByText(/第 1 条转写/).first().waitFor();
        await page.locator('[role=tabpanel][data-state=active]').getByText('65 段', { exact: true }).waitFor(); await assertNoEmpty();
      }
      assert.equal(audioCalls(), 0); page = online.page;
      assert.equal(await page.getByRole('button', { name: '删除会议', exact: true }).count(), 0); return '三会话各65段，下载IPC=0，成员无删除按钮；' + await layout();
    }, '在线成员转写完成');
    await step('转写长文本滚动', '真实滚动长文本，无遮挡和溢出', async () => {
      const scroller = page.locator('[role=tabpanel][data-state=active] .overflow-y-auto').first();
      await scroller.hover(); await page.mouse.wheel(0, 650); await page.waitForTimeout(150);
      assert.ok(await scroller.evaluate(el => el.scrollTop > 0)); return layout();
    }, '转写滚动');
    await control(host.session, { transcriptDelay: 0 });
    await step('打开记录及切换标签不下载', '页面只显示云下载入口，无audio元素和下载IPC', async () => {
      page = online.page; await page.getByRole('tab', { name: '会议信息', exact: true }).click();
      await page.getByRole('button', { name: '云下载', exact: true }).waitFor();
      assert.equal(await page.locator('audio').count(), 0); assert.equal(audioCalls(), 0); return 'audio元素=0，下载IPC=0；' + await layout();
    }, '云下载前');
    await step('主动云下载加载态', '点击一次触发一次IPC，下载中禁用防重复', async () => {
      await control(online.session, { audioDelay: 1600 }); await page.getByTestId('download-meeting-audio').click();
      await page.getByTestId('download-meeting-audio').filter({ hasText: '正在下载' }).waitFor();
      assert.ok(await page.getByTestId('download-meeting-audio').isDisabled()); assert.equal(audioCalls(), 1); return layout();
    }, '云下载中');
    await step('云下载完成后播放', '手动下载成功后才挂载播放器，可播放合成1秒WAV', async () => {
      await page.getByText('录音已保存到录音目录', { exact: true }).waitFor(); await page.getByRole('button', { name: '播放', exact: true }).click();
      await page.waitForFunction(() => { const a = document.querySelector('audio'); return a && a.currentTime > .05 && a.duration === 1; });
      await page.locator('audio').evaluate(el => el.pause()); assert.equal(audioCalls(), 1); await dismiss(); return layout();
    }, '云下载完成与播放');
    await step('云下载错误与恢复', '503明确展示错误，再次主动下载恢复', async () => {
      await control(online.session, { audioDelay: 0, audioError: true }); await page.getByTestId('download-meeting-audio').click();
      await page.getByRole('alert').filter({ hasText: '录音下载失败' }).waitFor(); return layout();
    }, '云下载错误');
    await step('云下载恢复', '错误清除且不会影响转写', async () => {
      await control(online.session, { audioError: false }); await page.getByTestId('download-meeting-audio').click();
      await page.getByText('录音已保存到录音目录', { exact: true }).waitFor();
      assert.equal(await page.getByRole('alert').filter({ hasText: '录音下载失败' }).count(), 0); await dismiss(); return layout();
    });
    page = host.page;
    await step('会后任务失败及成员只读', '三端显示任务错误，成员无重试按钮，不误报无语音', async () => {
      await control(host.session, { status: 'failed' });
      for (const client of clients) { page = client.page; await page.getByTestId('recording-job-status').filter({ hasText: '转写服务不可用' }).waitFor(); await transcript('failed'); }
      assert.equal(await page.getByRole('button', { name: '重试会后处理', exact: true }).count(), 0); return layout();
    }, '成员处理失败');
    page = host.page;
    await step('房主失败重试', '房主可恢复到queued，转写继续等待', async () => {
      await page.getByRole('button', { name: '重试会后处理', exact: true }).click(); return transcript('processing');
    }, '房主重试处理中');
    await step('状态读取错误', '503不被当作无语音，自动轮询重试', async () => {
      await control(host.session, { statusError: true }); return transcript('unavailable');
    }, '状态读取错误');
    await step('状态读取自动恢复', '无手工刷新恢复运行态', async () => {
      await control(host.session, { statusError: false, status: 'running' }); return transcript('processing');
    });
    await step('取消任务', '取消展示未完成，不能显示无语音', async () => {
      await control(host.session, { status: 'cancelled' }); return transcript('failed');
    }, '处理取消');
    await step('完成后的真正空结果', '仅任务已完成并读完首批转写后显示无语音', async () => {
      await control(host.session, { status: 'completed', emptyTranscripts: true }); return transcript('empty');
    }, '完成后无语音');
    await step('重新打开已完成记录仍不下载', '新挂载播放器保持idle，不获取录音', async () => {
      const before = audioCalls(); await page.reload({ waitUntil: 'domcontentloaded' });
      await page.getByRole('tab', { name: '会议信息', exact: true }).click(); await page.getByRole('button', { name: '云下载', exact: true }).waitFor();
      assert.equal(await page.locator('audio').count(), 0); assert.equal(audioCalls(), before); return layout();
    });
  } finally { for (const client of clients) await client.context.close(); }
}
try {
  for (const port of [3118, 39110, 3167, 9261, 9262, 9263]) {
    r.probe.push(await fetch(`http://127.0.0.1:${port}${port >= 9000 && port < 10000 ? '/json/version' : '/'}`, { signal: AbortSignal.timeout(1000) }).then(async response => { await response.body?.cancel(); return { port, listening: true, status: response.status }; }).catch(() => ({ port, listening: false })));
  }
  assert.equal(r.probe.find(p => p.port === 3167).listening, false);
  const fd = fs.openSync(path.join(out, 'next.log'), 'a');
  next = spawn(process.execPath, [path.join(front, 'node_modules/next/dist/bin/next'), 'dev', '-p', '3167'], { cwd: front, env: { ...process.env, OPENMEETING_NEXT_DIST_DIR: '.next-e2e-meeting-processing', OPENMEETING_E2E_DESKTOP_LAYOUT: '1', NEXT_PUBLIC_LIVE_MEETING_DATA_SOURCE: 'real' }, windowsHide: true, stdio: ['ignore', fd, fd] }); fs.closeSync(fd);
  const until = Date.now() + 90000;
  while (!await fetch(ui).then(async response => { await response.body?.cancel(); return response.ok; }).catch(() => false)) { if (Date.now() > until) throw Error('Next startup timed out'); await sleep(500); }
  browser = await chromium.launch({ headless: true });
  for (phase of ['assertions', 'screenshots']) for (const size of [{ width: 1280, height: 800 }, { width: 520, height: 760 }]) await flow(size);
} catch (error) { r.error = String(error.stack || error); process.exitCode = 1; console.error(error); }
finally {
  await browser?.close(); r.cleanup.browserClosed = true;
  if (next) r.cleanup.nextStopped = spawnSync('taskkill.exe', ['/PID', String(next.pid), '/T', '/F'], { windowsHide: true }).status === 0;
  await backend.close(); r.cleanup.fixtureClosed = true;
  r.cleanup.nextPortClosed = await fetch(ui, { signal: AbortSignal.timeout(1000) }).then(() => false).catch(() => true);
  if (!next || r.cleanup.nextPortClosed) { fs.writeFileSync(tsconfig, tsconfigBefore); r.cleanup.tsconfigRestored = fs.readFileSync(tsconfig).equals(tsconfigBefore); }
  for (const port of [3118, 39110]) r.cleanup[`daily${port}Listening`] = await fetch(`http://127.0.0.1:${port}/`, { signal: AbortSignal.timeout(1000) }).then(async response => { await response.body?.cancel(); return true; }).catch(() => false);
  budget.usedMs = Date.now() - budget.started; write('budget.json', budget); save(); report();
}
