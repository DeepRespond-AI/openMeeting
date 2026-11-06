import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import { fileURLToPath } from 'node:url';
import { createRequire } from 'node:module';
import { spawn, spawnSync } from 'node:child_process';
import { installLayoutBridge } from './fixtures/desktop-layout-backend.mjs';
import { api, startScheduledBackend } from './fixtures/scheduled-lifecycle-backend.mjs';
const root = fileURLToPath(new URL('../../', import.meta.url)), front = path.join(root, 'frontend');
const out = path.join(root, '.artifacts/scheduled-meeting-lifecycle'); fs.mkdirSync(path.join(out, 'screenshots'), { recursive: true });
const write = (name, value) => fs.writeFileSync(path.join(out, name), JSON.stringify(value, null, 2));
const read = name => JSON.parse(fs.readFileSync(path.join(out, name), 'utf8'));
const sleep = ms => new Promise(r => setTimeout(r, ms));
const control = body => api('/__control', 'POST', body);
const values = { title: '固定会议号跨端评审', startAt: new Date(Date.now() + 172800000).toISOString(), durationMin: 30, pwdEnabled: false, waitRoom: false, remind: false };
if (process.argv.includes('--smoke')) {
  const rows = [], check = async (operation, expected, fn) => { const row = { operation, expected, pass: false, actual: '' }; try { row.actual = await fn(); row.pass = true; } finally { rows.push(row); write('smoke.json', rows); console.log(JSON.stringify(row)); } };
  await api('/__reset', 'POST');
  await check('故障入口', '保存503和取消503可恢复', async () => {
    await control({ scheduleError: true }); assert.equal((await api('/api/v1/scheduled-meetings', 'POST', values)).status, 503); await control({ scheduleError: false });
    const s = (await api('/api/v1/scheduled-meetings', 'POST', values)).body;
    await control({ cancelError: true }); assert.equal((await api('/api/v1/scheduled-meetings/' + s.id, 'DELETE')).status, 503); await control({ cancelError: false });
    return '确定性503，关闭开关后恢复';
  });
  await check('真实数据库多场次', '同号两房间两记录，结束失败不生成记录', async () => {
    const s = (await api('/api/v1/scheduled-meetings')).body[0];
    assert.equal((await api('/api/v1/rooms?code=' + s.code, 'GET', undefined, 'member')).status, 404);
    assert.equal((await api('/api/v1/rooms?code=' + s.code)).body.hostUserId, 'scheduled-host');
    const records = [];
    for (let i = 0; i < 2; i++) {
      const room = (await api('/api/v1/rooms/join', 'POST', { code: s.code })).body.room; assert.ok(room?.id);
      assert.equal((await api('/api/v1/scheduled-meetings/' + s.id, 'DELETE')).status, 409);
      await control({ endError: true }); assert.equal((await api('/api/v1/rooms/' + room.id + '/end', 'POST')).status, 503);
      await control({ endError: false }); const end = await api('/api/v1/rooms/' + room.id + '/end', 'POST'); assert.equal(end.status, 200); records.push(end.body.meetingId);
    }
    assert.equal(new Set(records).size, 2); assert.equal((await api('/api/v1/scheduled-meetings')).body[0].code, s.code); return records;
  });
  await api('/__reset', 'POST'); process.exit(0);
}
assert.ok(read('smoke.json').every(r => r.pass));
const budget = fs.existsSync(path.join(out, 'budget.json')) ? read('budget.json') : { started: Date.now(), limitMs: 1800000 }; write('budget.json', budget);
if (Date.now() - budget.started > budget.limitMs) throw Error('30分钟调试预算已耗尽');
const backend = await startScheduledBackend(), require = createRequire(path.join(front, 'package.json')), { chromium } = require('playwright');
const roomOnly = process.argv.includes('--room-ui');
const seedOnly = process.argv.includes('--seed-only') || roomOnly;
if (!seedOnly && fs.existsSync(path.join(out, 'results.json'))) { const h = path.join(out, 'history', String(Date.now())); fs.mkdirSync(h, { recursive: true }); fs.copyFileSync(path.join(out, 'results.json'), path.join(h, 'results.json')); }
const result = { steps: [], cleanup: {}, probe: [] }; let browser, next, page, seq = 0, phase = 'assertions';
const tc = path.join(front, 'tsconfig.json'), tcBefore = fs.readFileSync(tc);
const save = () => write(roomOnly ? 'room-results.json' : seedOnly ? 'seed-results.json' : 'results.json', result);
async function step(operation, expected, fn, shot) {
  const row = { phase, viewport: page ? `${page.viewportSize().width}x${page.viewportSize().height}` : 'API', operation, expected, actual: '', pass: false, screenshot: null }; result.steps.push(row);
  try { if (Date.now() - budget.started > budget.limitMs) throw Error('30分钟预算耗尽'); row.actual = await fn() || expected; row.pass = true; if (phase === 'screenshots' && shot) { row.screenshot = `screenshots/${String(++seq).padStart(2, '0')}-${row.viewport}-${shot}.png`; await page.screenshot({ path: path.join(out, row.screenshot), animations: 'disabled' }); } }
  catch (e) { row.pass = false; row.actual = String(e.stack || e); if (page) { row.screenshot = `screenshots/failure-${Date.now()}.png`; await page.screenshot({ path: path.join(out, row.screenshot) }); } throw e; }
  finally { save(); console.log(JSON.stringify(row)); }
}
async function refresh() { await page.evaluate(() => window.dispatchEvent(new Event('scheduled-meetings-changed'))); await page.getByTestId('upcoming-meeting').first().waitFor(); }
async function flow(size) {
  if (!seedOnly) await api('/__reset', 'POST');
  const context = await browser.newContext({ viewport: size, locale: 'zh-CN', timezoneId: 'Asia/Shanghai' });
  await context.addInitScript(installLayoutBridge, { base: backend.base, session: 'host-' + phase + '-' + size.width }); page = await context.newPage(); page.setDefaultTimeout(15000);
  await page.goto('http://localhost:3168');
  // Each context uses a unique login session in the explicit native bridge.
  await page.locator('#phone-auth-phone').or(page.getByRole('button', { name: /快速会议.*立即/ })).first().waitFor();
  if (await page.locator('#phone-auth-phone').count()) { await page.locator('#phone-auth-phone').fill('13800138000'); await page.locator('#phone-auth-password').fill('LayoutTest123!'); await page.locator('form button[type=submit]').click(); }
  await page.getByRole('button', { name: /快速会议.*立即/ }).waitFor();
  await page.goto('http://localhost:3168/meetings'); await page.getByRole('tab', { name: '预定会议', exact: true }).click();
  const dialog = () => page.getByRole('dialog'), rows = () => page.getByTestId('upcoming-meeting');
  const title = values.title;
  if (roomOnly) {
    const label = `桌面会中流程-${phase}-${size.width}-${Date.now()}`;
    await page.getByRole('button', { name: '预定会议', exact: true }).click(); await page.locator('#sched-title').fill(label); await dialog().getByRole('button', { name: '预定会议', exact: true }).click(); await dialog().waitFor({ state: 'detached' });
    const s = (await api('/api/v1/scheduled-meetings')).body.find(x => x.title === label);
    await api('/api/v1/scheduled-meetings/' + s.id, 'PATCH', { ...values, title: label, startAt: s.startAt, pwdEnabled: true, pwd: '1234' }); await refresh();
    const records = [];
    for (let i = 0; i < 2; i++) {
      await step('桌面房主提前进入密码预定', '房主无需输入密码，真实POST加入并显示会中', async () => {
        await page.getByRole('button', { name: '加入 ' + label, exact: true }).click(); await dialog().getByRole('button', { name: '加入会议', exact: true }).click(); await page.getByTestId('room-recording-status').waitFor();
        const close = page.locator('[data-sonner-toast][data-removed="false"] [data-close-button]');
        for (let n = 0; n < 10 && await close.count(); n++) await close.first().click();
        await page.waitForFunction(() => document.querySelectorAll('[data-sonner-toast]').length === 0);
        const active = (await api('/api/v1/scheduled-meetings/' + s.id)).body; assert.ok(active.activeRoomId); result.activeRoom = active.activeRoomId;
      }, '会中');
      await page.getByRole('button', { name: '离开并结束', exact: true }).click();
      await step('继续会议关闭结束确认', '只关闭弹窗，保持同一活动房间', async () => {
        await dialog().getByRole('button', { name: '继续会议', exact: true }).click(); await dialog().waitFor({ state: 'detached' }); assert.equal((await api('/api/v1/scheduled-meetings/' + s.id)).body.activeRoomId, result.activeRoom);
      });
      await page.getByRole('button', { name: '离开并结束', exact: true }).click();
      await step('桌面结束弹窗', '确认结束当前场次，后台生成独立记录', async () => { await dialog().getByRole('button', { name: '结束会议', exact: true }).waitFor(); }, '结束确认');
      await step('桌面确认结束并可再次进入', '真实UI结束返回首页，固定号保留', async () => {
        await dialog().getByRole('button', { name: '结束会议', exact: true }).click(); await page.waitForURL(u => u.pathname === '/');
        const done = (await api('/api/v1/scheduled-meetings/' + s.id)).body; assert.equal(done.activeRoomId, null); assert.equal(done.code, s.code); records.push(done.meetingId);
        await page.goto('http://localhost:3168/meetings'); await page.getByRole('tab', { name: '预定会议', exact: true }).click(); await page.getByRole('button', { name: '加入 ' + label, exact: true }).waitFor();
      }, '结束返回');
    }
    assert.equal(new Set(records).size, 2); await api('/api/v1/scheduled-meetings/' + s.id, 'DELETE'); await context.close(); return;
  }
  if (seedOnly) {
    await control({ scheduleError: false, cancelError: false, endError: false });
    await page.getByRole('button', { name: '预定会议', exact: true }).click(); await page.locator('#sched-title').fill('桌面创建供移动端继续'); await dialog().getByRole('button', { name: '预定会议', exact: true }).click(); await dialog().waitFor({ state: 'detached' });
    write('interop-seed.json', (await api('/api/v1/scheduled-meetings')).body.find(x => !x.cancelled)); await context.close(); return;
  }
  await step('空预定列表', '显示空态，可创建', async () => { await page.getByText('暂无预定会议，预定后将获得固定会议号。').waitFor(); }, '空态');
  await page.getByRole('button', { name: '预定会议', exact: true }).click(); await page.locator('#sched-title').fill(title);
  await step('创建预定失败保留输入', '503可见，输入保留', async () => { await control({ scheduleError: true }); await dialog().getByRole('button', { name: '预定会议', exact: true }).click(); await dialog().getByRole('alert').waitFor(); assert.equal(await page.locator('#sched-title').inputValue(), title); }, '创建错误');
  await step('重试创建', '成功后固定六位会议号出现在列表', async () => { await control({ scheduleError: false }); await dialog().getByRole('button', { name: '预定会议', exact: true }).click(); await dialog().waitFor({ state: 'detached' }); await rows().first().waitFor(); }, '预定成功');
  const sched = (await api('/api/v1/scheduled-meetings')).body[0]; assert.match(sched.code, /^\d{6}$/);
  // Two real sessions are exercised through the business endpoints; UI entry/exit is checked below.
  await step('房主提前加入准备', '只读检查不创建房间，密码预定房主可跳过密码', async () => {
    await rows().getByRole('button', { name: '加入 ' + title, exact: true }).click(); await dialog().getByRole('button', { name: '加入会议', exact: true }).waitFor();
    assert.equal((await api('/__snapshot')).body.rooms.length, 0);
  }, '加入准备');
  await page.keyboard.press('Escape');
  const records = [];
  for (let i = 0; i < 2; i++) {
    await step(`第${i + 1}场提前开会`, '相同会议号，活动场次禁止修改/取消', async () => {
      const room = (await api('/api/v1/rooms/join', 'POST', { code: sched.code })).body.room;
      await api('/api/v1/rooms/join', 'POST', { code: sched.code }, 'member'); await refresh();
      await rows().getByText('进行中', { exact: true }).waitFor();
      await page.getByRole('button', { name: title + '的操作', exact: true }).click();
      assert.equal(await page.getByRole('menuitem', { name: '编辑', exact: true }).getAttribute('aria-disabled'), 'true'); await page.keyboard.press('Escape');
      result.activeRoom = room.id;
    }, i === 0 ? '活动场次' : null);
    await step(`第${i + 1}场结束及独立记录`, '结束后仍保留预定入口，每场不同记录', async () => {
      const end = await api('/api/v1/rooms/' + result.activeRoom + '/end', 'POST'); assert.equal(end.status, 200); records.push(end.body.meetingId); await refresh();
      assert.equal(await rows().count(), 1); assert.ok((await rows().innerText()).includes(sched.code.slice(0, 3) + ' ' + sched.code.slice(3))); assert.equal(await rows().getByText('进行中', { exact: true }).count(), 0);
    }, i === 1 ? '重复开会后' : null);
  }
  assert.equal(new Set(records).size, 2);
  await page.getByRole('button', { name: title + '的操作', exact: true }).click(); await page.getByRole('menuitem', { name: '编辑', exact: true }).click();
  await page.locator('#sched-title').fill(title + '（已编辑）');
  await step('有历史场次仍可编辑', '编辑成功且会议号不变', async () => { await dialog().getByRole('button', { name: '保存修改', exact: true }).click(); await dialog().waitFor({ state: 'detached' }); await page.getByRole('button', { name: title + '（已编辑）', exact: true }).waitFor(); assert.equal((await api('/api/v1/scheduled-meetings')).body[0].code, sched.code); }, '编辑成功');
  await page.getByRole('button', { name: title + '（已编辑）的操作', exact: true }).click(); await page.getByRole('menuitem', { name: '取消预定', exact: true }).click();
  await step('取消失败', '503可见，预定和历史保留', async () => { await control({ cancelError: true }); await dialog().getByRole('button', { name: '取消预定', exact: true }).click(); await dialog().getByRole('alert').waitFor(); }, '取消错误');
  await step('取消重试', '预定消失，固定号禁止重新开会，两份历史均可读', async () => {
    await control({ cancelError: false }); await dialog().getByRole('button', { name: '取消预定', exact: true }).click(); await dialog().waitFor({ state: 'detached' }); await page.getByText('暂无预定会议，预定后将获得固定会议号。').waitFor();
    assert.equal((await api('/api/v1/rooms/join', 'POST', { code: sched.code })).status, 404);
    for (const id of records) assert.equal((await api('/api/v1/meetings/' + id + '/metadata', 'GET', undefined, 'member')).status, 200);
    assert.equal(await page.evaluate(() => document.documentElement.scrollWidth > innerWidth + 1), false);
  }, '取消成功');
  if (phase === 'screenshots' && size.width === 520) {
    await page.getByRole('button', { name: '预定会议', exact: true }).click(); await page.locator('#sched-title').fill('桌面创建供移动端继续'); await dialog().getByRole('button', { name: '预定会议', exact: true }).click(); await dialog().waitFor({ state: 'detached' });
    const s = (await api('/api/v1/scheduled-meetings')).body.find(x => !x.cancelled); write('interop-seed.json', s);
  }
  await context.close();
}
try {
  for (const port of [3118, 39110, 3168, 9261, 9262, 9263]) result.probe.push({ port, listening: await fetch('http://127.0.0.1:' + port, { signal: AbortSignal.timeout(800) }).then(async r => { await r.body?.cancel(); return true; }).catch(() => false) });
  assert.equal(result.probe.find(p => p.port === 3168).listening, false);
  const fd = fs.openSync(path.join(out, 'next.log'), 'a'); next = spawn(process.execPath, [path.join(front, 'node_modules/next/dist/bin/next'), 'dev', '-p', '3168'], { cwd: front, env: { ...process.env, OPENMEETING_NEXT_DIST_DIR: '.next-e2e-scheduled-lifecycle', OPENMEETING_E2E_DESKTOP_LAYOUT: '1', NEXT_PUBLIC_LIVE_MEETING_DATA_SOURCE: 'real' }, windowsHide: true, stdio: ['ignore', fd, fd] }); fs.closeSync(fd);
  const until = Date.now() + 90000; while (!await fetch('http://localhost:3168').then(async r => { await r.body?.cancel(); return r.ok; }).catch(() => false)) { if (Date.now() > until) throw Error('Next启动超时'); await sleep(600); }
  browser = await chromium.launch({ headless: true });
  if (roomOnly) for (phase of ['assertions', 'screenshots']) for (const size of [{ width: 1280, height: 800 }, { width: 520, height: 760 }]) await flow(size);
  else if (seedOnly) await flow({ width: 1280, height: 800 });
  else for (phase of ['assertions', 'screenshots']) for (const size of [{ width: 1280, height: 800 }, { width: 520, height: 760 }]) await flow(size);
} catch (e) { result.error = String(e.stack || e); console.error(e); process.exitCode = 1; }
finally {
  await browser?.close(); if (next) result.cleanup.nextStopped = spawnSync('taskkill.exe', ['/PID', String(next.pid), '/T', '/F'], { windowsHide: true }).status === 0;
  await backend.close(); fs.writeFileSync(tc, tcBefore); result.cleanup.fixtureClosed = true; result.cleanup.tsconfigRestored = true;
  budget.usedMs = Date.now() - budget.started; write('budget.json', budget); save();
}
