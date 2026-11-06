import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import { spawn, spawnSync } from 'node:child_process';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
import { installLayoutBridge } from './fixtures/desktop-layout-backend.mjs';
import { startSharedRecordsBackend, sharedId, sharedTitle } from './fixtures/shared-records-backend.mjs';

const root = fileURLToPath(new URL('../../', import.meta.url)), front = path.join(root, 'frontend');
const out = path.resolve(root, process.env.SHARED_RECORDS_OUTPUT || '.artifacts/meeting-shared-records');
const archive = path.join(root, 'docs/testing/archive/自动录音与全员会议记录');
const ui = 'http://localhost:3164';
fs.mkdirSync(path.join(out, 'screenshots'), { recursive: true });
const read = name => JSON.parse(fs.readFileSync(path.join(out, name), 'utf8'));
const write = (name, value) => fs.writeFileSync(path.join(out, name), JSON.stringify(value, null, 2));
const sleep = ms => new Promise(resolve => setTimeout(resolve, ms));
function report(base = out) {
  const r = read('results.json'), reviews = fs.existsSync(path.join(out, 'visual-reviews.json')) ? read('visual-reviews.json') : {};
  const checks = fs.existsSync(path.join(out, 'checks.json')) ? read('checks.json') : [];
  const smoke = read('smoke.json'), budget = read('budget.json');
  const analysis = fs.existsSync(path.join(out, 'history-analysis.json')) ? read('history-analysis.json') : {};
  const log = name => fs.existsSync(path.join(out, name)) ? fs.readFileSync(path.join(out, name), 'utf8') : '';
  const unitLog = log('check-frontend-unit.txt');
  const unitPassed = [...unitLog.matchAll(/^\s*(\d+) pass\s*$/gm)].reduce((n, m) => n + Number(m[1]), 0);
  const unitFailed = [...unitLog.matchAll(/^\s*(\d+) fail\s*$/gm)].reduce((n, m) => n + Number(m[1]), 0);
  const queuePassed = (log('check-recording-queue.txt').match(/: PASS/g) || []).length;
  const rows = r.steps.filter(s => s.phase === 'assertions'), images = r.steps.filter(s => s.screenshot);
  const history = fs.existsSync(path.join(out, 'history')) ? fs.readdirSync(path.join(out, 'history')) : [];
  const clean = value => String(value).replaceAll('|', '/').replaceAll('\n', ' ');
  const repoLink = name => path.relative(base, path.join(root, name)).replaceAll('\\', '/');
  const lines = ['# 自动录音与全员会议记录测试报告', '',
    '分级：多人会议与会后读取/下载流程变更，执行完整受影响页面流程，覆盖房主、提前离会成员、外部账号三种会话。真实 Next 开发页面、状态和组件使用显式 HTTP/IPC/IM/RTC 夹具；播放 WAV 为合成输入，不代表真实 RTC、IM 投递、原生文件落盘、系统目录弹出或生产包验收。无 in-app browser，使用 Playwright 无头 Chromium。真实后端测试另外覆盖独立 PostgreSQL/API、PCM→WAV、转写/总结供应商替身及 IM outbox 重试。', '',
    `最终页面断言 ${rows.filter(s => s.pass).length} 通过、${rows.filter(s => !s.pass).length} 失败；截图阶段复核 ${r.steps.filter(s => s.phase === 'screenshots' && s.pass).length} 项通过。`, '',
    `独立夹具冒烟 ${smoke.filter(s => s.pass).length} 通过、${smoke.filter(s => !s.pass).length} 失败；代码/后端检查 ${checks.filter(s => s.pass).length} 组通过、${checks.filter(s => !s.pass).length} 组失败；其中前端单元 ${unitPassed} 通过、${unitFailed} 失败，录音队列契约 ${queuePassed} 通过。后端用例数量见下面 JUnit 汇总，截图阶段重复执行不重复计入功能用例。`, '',
    ...(r.error ? ['运行错误（不计为通过）：' + clean(r.error), ''] : []),
    `开始 ${r.started}，E2E 累计 30 分钟预算，不重置，最后一次执行结束累计 ${(budget.usedMs / 60000).toFixed(1)} 分钟。先 --smoke 单独验证结束可见性、下载延迟/错误/恢复，再执行页面。`, '',
    '启动：`node tests/e2e/meeting-shared-records.mjs --smoke` 后不带参数执行；自动启动隔离 Next :3164（OPENMEETING_NEXT_DIST_DIR=.next-e2e-shared-records，OPENMEETING_E2E_DESKTOP_LAYOUT=1）和随机回环 HTTP 夹具。后端使用独立 PostgreSQL :55440/shared_records_test，现有 Python 环境运行 pytest；不对日常数据库执行清理。', '',
    '原服务/登录态探测：' + JSON.stringify(r.probe) + '。39110 原先运行、3118 原先未监听，均保持原状。未开放的原生 CDP 无法读取登录态，保留原客户端，使用隔离夹具账号表单登录。浏览器按三个角色切换夹具响应；真实不同账号与历史参会关系的授权由独立 API/数据库测试验证。', '',
    '| 阶段/视口 | 操作 | 预期 | 实际 | 结果 | 截图 |', '|---|---|---|---|---|---|',
    ...r.steps.map(s => `| ${s.phase}/${s.viewport} | ${s.operation} | ${s.expected} | ${clean(s.actual)} | ${s.pass ? '通过' : '失败'} | ${s.screenshot ? `[截图](${s.screenshot})` : '—'} |`), '',
    '| 检查 | 预期 | 实际 | 结果 |', '|---|---|---|---|',
    ...checks.map(s => `| ${s.operation} | ${s.expected} | ${clean(JSON.stringify(s.actual))}${s.actual.log ? ` [日志](${s.actual.log})` : ' [JUnit](backend.xml)'} | ${s.pass ? '通过' : '失败'} |`), '',
    `正式截图 ${images.length} 张，实际查看 ${images.filter(s => reviews[s.screenshot]).length} 张，视觉通过 ${images.filter(s => reviews[s.screenshot]?.pass).length} 张。`, '',
    '| 截图 | 实际检查结果 |', '|---|---|',
    ...images.map(s => `| [${path.basename(s.screenshot)}](${s.screenshot}) | ${reviews[s.screenshot] ? `${reviews[s.screenshot].pass ? '通过' : '未通过'}：${reviews[s.screenshot].notes}` : '未实际查看，不标记通过'} |`), '',
    '[逐步结果](results.json) · [独立夹具冒烟](smoke.json) · [代码/后端检查](checks.json) · [视觉记录](visual-reviews.json)', '',
    '截图 08/21 是主动注入下载 503 的错误展示，11/24 是转写供应商失败但音频保留，12/25 是无音频，13/26 是非参会账号拒绝；它们证明失败路径可处理，并非真实 IM/RTC 故障截图。真实 IM/RTC 本轮未验收。', '',
    '历史后端第一轮：42 通过、1 失败，原测试仍断言参会者 404，与新共享需求相反；修正预期后完整后端回归见 checks。初始失败保留 [JUnit](backend-initial.xml)。', '',
    '历史单元检查：初次因 Bun 不在 PATH 未执行，随后找到现有 Bun；第一轮实际执行有两个测试文件因非浏览器环境 window 未定义失败，补充监听器环境判断后 89 用例通过。见 [初始输出](unit-initial.txt) 与 [初始检查](checks-initial.json)。', '',
    '| 历史尝试 | 失败或重拍原因 | 处理与证据 |', '|---|---|---|',
    ...history.map(name => {
      const h = JSON.parse(fs.readFileSync(path.join(out, 'history', name, 'results.json'), 'utf8'));
      const failed = h.steps.filter(s => !s.pass);
      return `| [${name}](history/${name}/results.json) | ${clean(analysis[name]?.cause || (failed.length ? failed.map(s => s.operation).join('、') : '当轮功能断言通过，后续补充视觉检查'))} | ${clean(analysis[name]?.resolution || '见逐步结果')} ${failed.map(s => `[失败截图](history/${name}/${s.screenshot})`).join(' ')} |`;
    }), '',
    '[历史原因记录](history-analysis.json)。保留历史失败，最终通过不会覆盖原失败；未执行项不计通过。归档文本仅清除行尾空格，原始本地日志保留。', '',
    '关闭结果：' + JSON.stringify(r.cleanup) + '；后端专用数据库关闭见 [cleanup.json](cleanup.json)。构建缓存保留。', '',
    '风险/边界：用户要求暂不处理 RTC 服务恢复，真实采集与实际 IM 离线到达未验收；房主异常退出未上传的内存分片仍可能丢失。下载页面复用既有原生鉴权下载，本轮浏览器验证调用与错误恢复，真实 API 验证 WAV 字节；未声明新增原生文件保存成功。所有实际参会者默认可看和下载，写操作沿用原有所属账号约束。新版 Rust 透传 can_manage 字段，需要后端与桌面新构建同步更新。', '',
    `[开发文档](${repoLink('docs/development/meeting-shared-records.md')}) · [页面脚本](${repoLink('tests/e2e/meeting-shared-records.mjs')}) · [后端测试](${repoLink('server/meeting_ms/tests/test_shared_records.py')})`, ''];
  fs.mkdirSync(base, { recursive: true }); fs.writeFileSync(path.join(base, '测试报告.md'), lines.join('\n'));
  if (base === archive) {
    for (const name of ['results.json', 'smoke.json', 'checks.json', 'checks-initial.json', 'visual-reviews.json', 'history-analysis.json', 'budget.json', 'cleanup.json', 'backend.xml', 'backend-initial.xml', 'unit-initial.txt', 'check-TypeScript.txt', 'check-recording-queue.txt', 'check-IM-contract.txt', 'check-frontend-unit.txt', 'check-Rust.txt']) if (fs.existsSync(path.join(out, name))) {
      const source = path.join(out, name), target = path.join(base, name);
      if (/\.(txt|xml)$/.test(name)) fs.writeFileSync(target, fs.readFileSync(source, 'utf8').replace(/[\t ]+$/gm, ''));
      else fs.copyFileSync(source, target);
    }
    const copyShots = (source, destination, result) => {
      for (const s of result.steps.filter(s => s.screenshot)) {
        const target = path.join(destination, s.screenshot); fs.mkdirSync(path.dirname(target), { recursive: true });
        fs.copyFileSync(path.join(source, s.screenshot), target);
      }
    };
    copyShots(out, base, r);
    for (const name of history) {
      const source = path.join(out, 'history', name), destination = path.join(base, 'history', name);
      fs.mkdirSync(destination, { recursive: true });
      for (const file of ['results.json', 'visual-reviews.json']) if (fs.existsSync(path.join(source, file))) fs.copyFileSync(path.join(source, file), path.join(destination, file));
      copyShots(source, destination, JSON.parse(fs.readFileSync(path.join(source, 'results.json'), 'utf8')));
    }
  }
  console.log(JSON.stringify({ report: path.join(base, '测试报告.md'), passed: rows.filter(s => s.pass).length, failed: rows.filter(s => !s.pass).length, error: r.error || null, screenshots: images.length }));
}
if (process.argv.includes('--report') || process.argv.includes('--archive')) { report(process.argv.includes('--archive') ? archive : out); process.exit(0); }
const backend = await startSharedRecordsBackend();
const control = async (session, patch = {}, shared, role, reset = false) => {
  const response = await fetch(backend.base + '/control', { method: 'POST', body: JSON.stringify({ session, patch, shared, role, reset }) });
  assert.equal(response.status, 200); return response.json();
};
const rpc = async (session, command, args = {}) => {
  const response = await fetch(backend.base + '/invoke', { method: 'POST', body: JSON.stringify({ session, command, args }) });
  return { status: response.status, data: await response.json() };
};
if (process.argv.includes('--smoke')) {
  const rows = [];
  try {
    await control('host', {}, undefined, 'host', true); await control('member', {}, undefined, 'member');
    assert.equal((await rpc('member', 'api_get_meetings')).data.value.length, 0);
    assert.ok((await rpc('host', 'room_create')).data.value.recording.active);
    await rpc('member', 'room_join'); await rpc('member', 'room_leave'); await rpc('host', 'room_end');
    assert.equal((await rpc('member', 'api_get_meetings')).data.value[0].id, sharedId);
    rows.push({ operation: 'automatic state and early leaver gets final record', expected: 'shared id after end', actual: sharedId, pass: true, screenshot: null });
    await control('member', {}, { hasAudio: true, audioError: true });
    assert.equal((await rpc('member', 'server_fetch_meeting_audio')).status, 503);
    rows.push({ operation: 'audio failure fixture', expected: 503, actual: 503, pass: true, screenshot: null });
    await control('member', {}, { audioError: false, audioDelay: 180 }); const tick = Date.now();
    const audio = await rpc('member', 'server_fetch_meeting_audio'); assert.equal(audio.status, 200); assert.ok(Date.now() - tick >= 170);
    const bytes = Buffer.from(await (await fetch(audio.data.value)).arrayBuffer()); assert.equal(bytes.toString('ascii', 0, 4), 'RIFF');
    rows.push({ operation: 'audio recovery delayed WAV fixture', expected: '200 and RIFF', actual: bytes.length, pass: true, screenshot: null });
    await control('member', {}, { status: 'failed', hasAudio: false });
    assert.match((await rpc('member', 'room_recording_status')).data.value.error, /未收到会议音频/);
    assert.equal((await rpc('member', 'server_fetch_meeting_audio')).data.value, null);
    rows.push({ operation: 'missing audio fixture', expected: 'explicit failure and no file', actual: 'no audio', pass: true, screenshot: null });
    await control('outside', {}, undefined, 'outsider'); assert.equal((await rpc('outside', 'api_get_meeting_metadata')).status, 404);
    rows.push({ operation: 'nonparticipant fixture', expected: 404, actual: 404, pass: true, screenshot: null });
    write('smoke.json', rows); console.log(JSON.stringify(rows));
  } finally { await backend.close(); }
  process.exit(0);
}
assert.ok(read('smoke.json').every(s => s.pass));
if (fs.existsSync(path.join(out, 'results.json'))) {
  const history = path.join(out, 'history', String(Date.now())); fs.mkdirSync(history, { recursive: true });
  fs.copyFileSync(path.join(out, 'results.json'), path.join(history, 'results.json'));
  fs.cpSync(path.join(out, 'screenshots'), path.join(history, 'screenshots'), { recursive: true });
  if (fs.existsSync(path.join(out, 'visual-reviews.json'))) fs.renameSync(path.join(out, 'visual-reviews.json'), path.join(history, 'visual-reviews.json'));
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
async function dismissToasts() {
  const close = page.locator('[data-sonner-toast][data-removed="false"] [data-close-button]');
  for (let i = 0; i < 10 && await close.count(); i++) await close.first().click();
  await page.waitForFunction(() => document.querySelectorAll('[data-sonner-toast]').length === 0);
}
async function layout() {
  const issues = await page.evaluate(() => {
    const issues = []; if (document.documentElement.scrollWidth > innerWidth + 1) issues.push('document overflow');
    for (const el of document.querySelectorAll('[role=dialog], [data-testid=recording-job-status], [data-testid=room-recording-status]')) {
      if (!el.getClientRects().length) continue; const b = el.getBoundingClientRect();
      if (b.left < -1 || b.right > innerWidth + 1) issues.push('dialog/status horizontal overflow');
      if (el.getAttribute('role') === 'dialog' && (b.top < -1 || b.bottom > innerHeight + 1)) issues.push('dialog outside viewport');
    } return issues;
  }); assert.deepEqual(issues, []); return '页面与状态/弹窗未越界';
}
async function notice(target, event, seq, sender = 'notice') {
  await target.evaluate(({ event, seq, sender, sharedId, sharedTitle }) => window.__meetingFixture.control({ receive: {
    type: 'custom', sender, conversation_id: 'notice', seq, body: { kind: 'openmeeting.meeting', version: 1, event, meetingId: sharedId, title: sharedTitle },
  } }), { event, seq, sender, sharedId, sharedTitle });
}
async function makePage(size, session, role) {
  await control(session, { loggedIn: false }, undefined, role);
  const context = await browser.newContext({ viewport: size, locale: 'zh-CN' });
  await context.addInitScript(installLayoutBridge, { base: backend.base, session }); const target = await context.newPage(); target.setDefaultTimeout(12000); target.setDefaultNavigationTimeout(30000);
  await target.goto(ui, { waitUntil: 'domcontentloaded' }); await target.locator('#phone-auth-phone').fill('13800138000'); await target.locator('#phone-auth-password').fill('LayoutTest123!'); await target.locator('form button[type=submit]').click(); await target.getByRole('button', { name: /快速会议.*立即/ }).waitFor();
  page = target; await dismissToasts(); return { context, page: target, session };
}
async function flow(size) {
  const key = phase + '-' + size.width; await control(key, {}, undefined, 'host', true);
  const host = await makePage(size, key + '-host', 'host');
  const member = await makePage(size, key + '-member', 'member');
  let outside;
  try {
    page = host.page;
    await step('房主自动录音状态与移除按钮', '入会自动启用录音，等待真实音轨；无录制或审批按钮', async () => {
      await page.getByRole('button', { name: /快速会议.*立即/ }).click(); await page.getByTestId('room-recording-status').filter({ hasText: '等待会议音频' }).waitFor();
      assert.equal(await page.getByTestId('recording-control').count(), 0); assert.equal(await page.getByTestId('recording-requests').count(), 0); await dismissToasts(); return layout();
    }, '房主自动录音');
    page = member.page;
    await step('成员入会与提前离开', '成员自动获知录音，提前离开后房间仍未结束', async () => {
      await page.getByRole('button', { name: /加入会议.*入会/ }).click();
      const digits = page.getByRole('dialog').getByRole('textbox').filter({ hasNot: page.locator('textarea') });
      for (let i = 0; i < 6; i++) await page.getByRole('textbox', { name: new RegExp(`第\\s*${i + 1}\\s*位`) }).fill('654321'[i]);
      await page.getByRole('dialog').getByRole('button', { name: '加入会议', exact: true }).click();
      await page.getByTestId('room-recording-status').filter({ hasText: '录制已开启' }).waitFor(); await dismissToasts();
      await page.getByRole('button', { name: '离开会议', exact: true }).click(); await page.waitForURL(url => url.pathname === '/');
      assert.equal((await control(member.session)).shared.ended, false); await dismissToasts(); return layout();
    }, '成员提前离开');
    page = host.page;
    await step('结束确认准确说明共享', '说明后台处理及提前离开成员可查看', async () => {
      await page.getByRole('button', { name: '离开并结束', exact: true }).click(); await page.getByRole('dialog').getByText(/含提前离开的成员/).waitFor(); return layout();
    }, '结束确认');
    await step('正常结束与后台等待', '结束建立记录，音频未就绪时不显示伪下载成功', async () => {
      await page.getByRole('dialog').getByRole('button', { name: '结束会议', exact: true }).click(); await page.waitForURL(url => url.pathname === '/');
      await page.getByRole('button', { name: sharedTitle }).click(); await page.waitForURL(url => url.pathname === '/meeting-details');
      await page.getByTestId('recording-job-status').filter({ hasText: '正在等待' }).waitFor(); await dismissToasts(); return '房间结束，记录处理中';
    });
    page = member.page;
    await step('可信IM通知与记录入口', '伪造通知被忽略；早退成员收到结束入口', async () => {
      await notice(page, 'meeting_ended', 1, 'layout-peer'); assert.equal(await page.getByRole('button', { name: '查看会议记录', exact: true }).count(), 0);
      await notice(page, 'meeting_ended', 2); await page.getByRole('button', { name: '查看会议记录', exact: true }).waitFor();
      await notice(page, 'meeting_ended', 2); assert.equal(await page.getByRole('button', { name: '查看会议记录', exact: true }).count(), 1);
      await page.getByRole('button', { name: '查看会议记录', exact: true }).click(); await page.waitForURL(url => url.pathname === '/meeting-details');
      await page.getByTestId('recording-job-status').filter({ hasText: '正在等待' }).waitFor(); await dismissToasts();
      assert.equal(await page.getByTestId('download-meeting-audio').count(), 0); return layout();
    }, '成员记录处理中');
    await step('处理完成与成员回放', '音频、转写、纪要逐步就绪；成员无删除入口且可播放', async () => {
      await control(member.session, {}, { status: 'completed', hasAudio: true }); await notice(page, 'processing_completed', 3);
      await page.getByTestId('recording-job-status').filter({ hasText: '已就绪' }).waitFor();
      await page.getByText('全员可见的会议纪要', { exact: true }).waitFor();
      await page.getByRole('tab', { name: '会议信息', exact: true }).click();
      await page.getByTestId('download-meeting-audio').waitFor();
      assert.equal(await page.locator('audio').count(), 0);
      await page.getByTestId('download-meeting-audio').click();
      await page.getByRole('button', { name: '播放', exact: true }).waitFor();
      assert.equal(await page.getByRole('button', { name: '删除会议', exact: true }).count(), 0);
      await dismissToasts(); await page.getByRole('button', { name: '播放', exact: true }).click();
      await page.waitForFunction(() => { const audio = document.querySelector('audio'); return audio && audio.currentTime > .05 && audio.duration === 1; });
      await page.locator('audio').evaluate(el => el.pause()); return layout();
    }, '成员回放与下载入口');
    await step('下载加载态', '下载按钮发起原生命令并在等待时禁用', async () => {
      await control(member.session, {}, { audioDelay: 1600 }); await page.getByTestId('download-meeting-audio').click();
      await page.getByTestId('download-meeting-audio').filter({ hasText: '正在下载' }).waitFor(); assert.ok(await page.getByTestId('download-meeting-audio').isDisabled()); return layout();
    }, '录音下载中');
    await step('下载成功显示保存位置', '成功提示显示返回路径与打开目录操作', async () => {
      await page.getByText('录音已保存到录音目录', { exact: true }).waitFor();
      return layout();
    }, '录音下载成功');
    await step('打开下载位置', '保存提示的目录操作调用已有IPC', async () => {
      await page.getByRole('button', { name: '打开录音文件夹', exact: true }).click();
      assert.ok(backend.calls.some(c => c.session === member.session && c.command === 'open_meeting_folder')); return '目录操作命令已调用（显式IPC夹具）';
    });
    await step('下载失败展示', '确定性503不显示成功，错误可重试', async () => {
      await dismissToasts(); await control(member.session, {}, { audioDelay: 0, audioError: true }); await page.getByTestId('download-meeting-audio').click();
      await page.getByRole('alert').filter({ hasText: '录音下载失败' }).waitFor(); return layout();
    }, '录音下载失败');
    await step('下载失败恢复', '恢复后同一入口成功，错误清除', async () => {
      await control(member.session, {}, { audioError: false }); await page.getByTestId('download-meeting-audio').click(); await page.getByText('录音已保存到录音目录', { exact: true }).waitFor();
      assert.equal(await page.getByRole('alert').filter({ hasText: '录音下载失败' }).count(), 0); await dismissToasts(); return '失败恢复，成功与失败提示互斥';
    });
    await step('成员查看转写与滚动', '查看分段转写，真实滚动长内容', async () => {
      await page.getByRole('tab', { name: '转写', exact: true }).click(); await page.getByText(/第 1 条转写/).first().waitFor();
      assert.equal(await page.locator('#summary-context').count(), 0);
      const panel = page.locator('[role=tabpanel][data-state=active]'); await panel.hover(); await page.mouse.wheel(0, 800); return layout();
    }, '成员转写');
    await step('成员查看只读纪要', '可阅读长纪要，无编辑区域或生成按钮，滚动正常', async () => {
      await page.getByRole('tab', { name: 'AI 总结', exact: true }).click(); await page.getByText('全员可见的会议纪要', { exact: true }).waitFor();
      const panel = page.locator('[role=tabpanel][data-state=active]'); assert.equal(await panel.locator('[contenteditable=true]').count(), 0);
      await panel.hover(); await page.mouse.wheel(0, 500); return layout();
    }, '成员纪要滚动');
    await step('处理失败仍可获取已存音频', '错误不伪装成全部完成；保留音频下载', async () => {
      await control(member.session, {}, { status: 'failed', hasAudio: true }); await notice(page, 'processing_failed', 4);
      await page.getByTestId('recording-job-status').filter({ hasText: '转写服务不可用' }).waitFor(); await dismissToasts();
      await page.getByRole('tab', { name: '会议信息', exact: true }).click(); await page.getByTestId('download-meeting-audio').waitFor(); return layout();
    }, '处理失败保留录音');
    await step('没有音频时不提供下载', '缺失音频展示处理失败，下载入口不误导', async () => {
      await control(member.session, {}, { hasAudio: false }); await page.goto(ui + `/meeting-details?id=${sharedId}`, { waitUntil: 'domcontentloaded' });
      const status = page.getByTestId('recording-job-status').filter({ hasText: '未收到会议音频' }); await status.waitFor(); await status.scrollIntoViewIfNeeded();
      assert.equal(await page.getByTestId('download-meeting-audio').count(), 0); return layout();
    }, '无音频记录');
    outside = await makePage(size, key + '-outside', 'outsider'); page = outside.page;
    await step('非参会账号不可读取', '登录后仍不能访问别人的会议记录', async () => {
      await page.goto(ui + `/meeting-details?id=${sharedId}`, { waitUntil: 'domcontentloaded' }); await page.getByRole('heading', { name: '无法打开该会议', exact: true }).waitFor();
      assert.equal((await rpc(outside.session, 'api_get_meeting_metadata')).status, 404); assert.equal(await page.getByTestId('download-meeting-audio').count(), 0); return layout();
    }, '非参会账号');
  } finally { await host.context.close(); await member.context.close(); await outside?.context.close(); }
}
try {
  for (const port of [3118, 39110, 3164, 9261, 9262, 9263]) {
    const probe = await fetch(`http://127.0.0.1:${port}${port >= 9000 && port < 10000 ? '/json/version' : '/'}`, { signal: AbortSignal.timeout(1000) }).then(async response => { await response.body?.cancel(); return { port, listening: true, status: response.status }; }).catch(() => ({ port, listening: false })); r.probe.push(probe);
  }
  assert.equal(r.probe.find(p => p.port === 3164).listening, false);
  const fd = fs.openSync(path.join(out, 'next.log'), 'a');
  next = spawn(process.execPath, [path.join(front, 'node_modules/next/dist/bin/next'), 'dev', '-p', '3164'], { cwd: front, env: { ...process.env, OPENMEETING_NEXT_DIST_DIR: '.next-e2e-shared-records', OPENMEETING_E2E_DESKTOP_LAYOUT: '1', NEXT_PUBLIC_LIVE_MEETING_DATA_SOURCE: 'real' }, windowsHide: true, stdio: ['ignore', fd, fd] }); fs.closeSync(fd);
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
