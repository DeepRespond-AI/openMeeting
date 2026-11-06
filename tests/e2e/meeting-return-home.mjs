// Focused full-page browser regression. Real Next pages, RoomProvider and toolbar;
// explicit HTTP/Tauri/IM/media fixtures. Does not prove native capture or a live backend.
import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import { mkdirSync, readFileSync, writeFileSync, existsSync, openSync, statSync } from 'node:fs';
import { spawn } from 'node:child_process';
import { startMeetingBackend, installMeetingBridge } from './fixtures/meeting-session-backend.mjs';
import { installLayoutBridge } from './fixtures/desktop-layout-backend.mjs';

const root = fileURLToPath(new URL('../../', import.meta.url));
const frontend = path.join(root, 'frontend');
const require = createRequire(path.join(frontend, 'package.json'));
const { chromium } = require('playwright');
const out = path.resolve(root, process.env.OPENMEETING_RETURN_HOME_OUTPUT || '.artifacts/meeting-return-home');
mkdirSync(path.join(out, 'screenshots'), { recursive: true });
mkdirSync(path.join(out, 'logs'), { recursive: true });
const budgetPath = path.join(out, 'budget.json');
if (!existsSync(budgetPath)) {
  const firstLog = path.join(out, 'logs/mobile-assertions-01.txt');
  writeFileSync(budgetPath, JSON.stringify({ started: existsSync(firstLog) ? statSync(firstLog).birthtimeMs : Date.now(), limitMinutes: 30 }));
}
const { started } = JSON.parse(readFileSync(budgetPath));
const backend = await startMeetingBackend();
const data = { startup: 'node tests/e2e/meeting-return-home.mjs; isolated Next 3196 + random localhost HTTP fixture; existing gateway39110 preserved', steps: [], cleanup: {}, pageErrors: [] };
const smokeOnly = process.argv.includes('--smoke');
let phase = 'fixture-smoke', viewport = '', page, browser, server, number = 0;
const tsconfig = path.join(frontend, 'tsconfig.json'), original = readFileSync(tsconfig);
const save = () => writeFileSync(path.join(out, smokeOnly ? 'desktop-smoke.json' : 'desktop-results.json'), JSON.stringify(data, null, 2));
const control = (session, patch) => fetch(backend.base + '/control', { method: 'POST', body: JSON.stringify({ session, patch }) }).then(r => r.json());
const rpc = async (session, command) => {
  const r = await fetch(backend.base + '/invoke', { method: 'POST', body: JSON.stringify({ session, command, args: { code: '654321' } }) });
  return { status: r.status, body: await r.json() };
};
async function wait(fn, ms = 15000) {
  const until = Date.now() + ms;
  while (Date.now() < until) { if (await fn()) return; await new Promise(r => setTimeout(r, 150)); }
  throw Error('Timed out waiting for expected state');
}
async function shot(label) {
  if (phase !== 'screenshots') return null;
  const file = `screenshots/desktop-${String(++number).padStart(2, '0')}-${viewport}-${label}.png`;
  await page.screenshot({ path: path.join(out, file), animations: 'disabled' });
  return file;
}
async function step(operation, expected, fn) {
  if (Date.now() - started > 1800000) throw Error('Cumulative 30-minute E2E budget exhausted');
  const item = { platform: 'desktop', phase, viewport, operation, expected, actual: '', pass: false, screenshots: [] };
  data.steps.push(item);
  try { await fn(item); item.actual = '全部断言通过'; item.pass = true; }
  catch (e) { item.actual = String(e.stack || e); if (page) { const file = `screenshots/failure-${Date.now()}.png`; await page.screenshot({ path: path.join(out, file) }).catch(() => {}); item.screenshots.push(file); } throw e; }
  finally { console.log(JSON.stringify(item)); save(); }
}
async function boot(session, width, height) {
  await page?.context().close();
  const context = await browser.newContext({ viewport: { width, height }, locale: 'zh-CN' });
  await context.addInitScript(installLayoutBridge, { base: backend.base, session });
  await context.addInitScript(installMeetingBridge, { base: backend.base, session });
  page = await context.newPage(); page.setDefaultTimeout(15000);
  page.on('pageerror', error => data.pageErrors.push(String(error)));
  await page.goto('http://127.0.0.1:3196/room?code=654321');
  await page.getByTestId('room-toolbar-region').getByRole('button', { name: session === 'host' ? '离开并结束' : '离开会议', exact: true }).waitFor();
}
async function home() {
  await page.waitForURL('http://127.0.0.1:3196/');
  await page.getByRole('button', { name: '快速会议 立即发起一场会议', exact: true }).waitFor();
  assert.equal(await page.getByTestId('persistent-meeting').count(), 0);
  assert.equal(await page.getByRole('dialog').count(), 0);
}
async function exercise(width, height) {
  viewport = `${width}x${height}`;
  await step('主持人结束，已有会议记录ID也回首页', '确认后首页，关闭确认窗和房间，无额外leave请求', async row => {
    await control('host', { reset: true, endError: false, meetingId: 'record-existing' });
    await boot('host', width, height);
    await page.getByTestId('room-toolbar-region').getByRole('button', { name: '离开并结束', exact: true }).click();
    await page.getByRole('dialog').waitFor();
    const confirm = await shot('end-confirm'); if (confirm) row.screenshots.push(confirm);
    const before = backend.calls.filter(x => x.command === 'room_leave').length;
    await page.getByRole('dialog').getByRole('button', { name: '结束会议', exact: true }).click();
    await home(); assert.equal(backend.calls.filter(x => x.command === 'room_leave').length, before);
    const file = await shot('home'); if (file) row.screenshots.push(file);
  });
  await step('成员离会失败重试', '失败停留房间，恢复后直接首页', async row => {
    await control('peer', { reset: true, leaveError: true });
    await boot('peer', width, height);
    await page.getByTestId('room-toolbar-region').getByRole('button', { name: '离开会议', exact: true }).click();
    await page.getByText('夹具：离会失败，请重试', { exact: true }).waitFor();
    assert.equal(new URL(page.url()).pathname, '/room');
    const file = await shot('leave-error'); if (file) row.screenshots.push(file);
    await control('peer', { leaveError: false });
    await page.getByTestId('room-toolbar-region').getByRole('button', { name: '离开会议', exact: true }).click();
    await home();
  });
  await step('主持人结束失败重试', '失败仍在房间，重试成功首页', async row => {
    await control('host', { reset: true, endError: true });
    await boot('host', width, height);
    const end = async () => {
      await page.getByTestId('room-toolbar-region').getByRole('button', { name: '离开并结束', exact: true }).click();
      await page.getByRole('dialog').getByRole('button', { name: '结束会议', exact: true }).click();
    };
    await end(); await page.getByText('夹具：结束会议失败，请重试', { exact: true }).waitFor();
    assert.equal(new URL(page.url()).pathname, '/room');
    const file = await shot('end-error'); if (file) row.screenshots.push(file);
    await control('host', { endError: false }); await end(); await home();
  });
  await step('收到远端结束且弹窗打开', '自动首页、弹窗和会话卸载，无重复leave', async row => {
    await control('host', { reset: true }); await boot('host', width, height);
    await page.getByTestId('room-toolbar-region').getByRole('button', { name: '离开并结束', exact: true }).click();
    await page.getByRole('dialog').waitFor();
    const before = backend.calls.filter(x => x.command === 'room_leave').length;
    await control('host', { ended: true }); await home();
    assert.equal(backend.calls.filter(x => x.command === 'room_leave').length, before);
  });
}
try {
  await step('失败夹具独立冒烟', '结束/离开503连续三次稳定触发，恢复后200和记录ID', async () => {
    await control('host', { reset: true, endError: true, leaveError: true, meetingId: 'record-existing' });
    assert.equal((await rpc('host', 'room_join')).status, 200);
    for (let i = 0; i < 3; i++) { assert.equal((await rpc('host', 'room_end')).status, 503); assert.equal((await rpc('host', 'room_leave')).status, 503); }
    await control('host', { endError: false, leaveError: false });
    assert.equal((await rpc('host', 'room_end')).body.value.meetingId, 'record-existing');
    assert.equal((await rpc('host', 'room_leave')).status, 200);
  });
  if (!smokeOnly) {
    const log = openSync(path.join(out, 'logs/desktop-dev.log'), 'a');
    server = spawn(process.execPath, ['-e', `process.on('message',()=>process.exit(0));require(${JSON.stringify(require.resolve('next/dist/server/lib/start-server'))}).startServer({dir:${JSON.stringify(frontend)},isDev:true,hostname:'127.0.0.1',port:3196,allowRetry:false})`], {
      cwd: frontend, windowsHide: true, stdio: ['ignore', log, log, 'ipc'],
      env: { ...process.env, OPENMEETING_NEXT_DIST_DIR: `.next-e2e-return-${Date.now()}`, OPENMEETING_E2E_DESKTOP_LAYOUT: '1', NEXT_PUBLIC_LIVE_MEETING_DATA_SOURCE: 'real' },
    });
    await wait(() => fetch('http://127.0.0.1:3196/brand-logo.png').then(r => r.ok).catch(() => false), 60000);
    await fetch('http://127.0.0.1:3196/');
    browser = await chromium.launch({ headless: true });
    phase = 'assertions'; for (const size of [[1280, 800], [390, 844]]) await exercise(...size);
    phase = 'screenshots'; for (const size of [[1280, 800], [390, 844]]) await exercise(...size);
    assert.deepEqual(data.pageErrors, []);
    data.runnerPassed = true;
  }
} catch (e) { data.error = String(e.stack || e); data.runnerPassed = false; process.exitCode = 1; }
finally {
  await browser?.close(); data.cleanup.browser = 'closed';
  if (server) {
    if (server.connected) server.send('shutdown');
    await wait(() => server.exitCode !== null || server.signalCode !== null, 10000).catch(() => server.kill());
    data.cleanup.nextClosed = await fetch('http://127.0.0.1:3196/brand-logo.png', { signal: AbortSignal.timeout(1000) }).then(() => false).catch(() => true);
  }
  await backend.close(); data.cleanup.fixture = 'closed';
  writeFileSync(tsconfig, original); save();
  console.log(JSON.stringify({ runnerPassed: data.runnerPassed, error: data.error, cleanup: data.cleanup }));
}
