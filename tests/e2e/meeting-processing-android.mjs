import { testAdb } from './local-tools.cjs';
import fs from 'node:fs';
import path from 'node:path';
import http from 'node:http';
import assert from 'node:assert/strict';
import { spawn, spawnSync, execFileSync } from 'node:child_process';
import { createRequire } from 'node:module';
import { startSharedRecordsBackend, sharedId } from './fixtures/shared-records-backend.mjs';
import { installLayoutBridge } from './fixtures/desktop-layout-backend.mjs';
const root = path.resolve(import.meta.dirname, '../..'), front = path.join(root, 'frontend');
const out = path.join(root, '.artifacts/meeting-processing-state');
const budget = JSON.parse(fs.readFileSync(path.join(out, 'budget.json')));
const adb = testAdb();
const backend = await startSharedRecordsBackend(), rows = [], state = { phase: 'starting', rows, cleanup: {} };
const save = () => fs.writeFileSync(path.join(out, 'android-results.json'), JSON.stringify(state, null, 2));
const command = async (session, command, args = {}) => {
  const r = await fetch(backend.base + '/invoke', { method: 'POST', body: JSON.stringify({ session, command, args }) }); return { status: r.status, data: await r.json() };
};
const control = async shared => fetch(backend.base + '/control', { method: 'POST', body: JSON.stringify({ session: 'android-host', role: 'host', patch: { loggedIn: true }, shared }) });
const require = createRequire(path.join(front, 'package.json')), { chromium } = require('playwright');
const before = fs.readFileSync(path.join(front, 'tsconfig.json'));
let browser, page, next, ready = false, done, server;
const finished = new Promise(resolve => { done = resolve; });
try {
  assert.ok(Date.now() - budget.started < budget.limitMs, 'same 30 minute budget exhausted');
  await control({ ended: true, status: 'queued', hasAudio: true });
  const fd = fs.openSync(path.join(out, 'android-next.log'), 'a');
  next = spawn(process.execPath, [path.join(front, 'node_modules/next/dist/bin/next'), 'dev', '-p', '3167'], { cwd: front, windowsHide: true, env: { ...process.env, OPENMEETING_NEXT_DIST_DIR: '.next-e2e-meeting-processing', OPENMEETING_E2E_DESKTOP_LAYOUT: '1', NEXT_PUBLIC_LIVE_MEETING_DATA_SOURCE: 'real' }, stdio: ['ignore', fd, fd] }); fs.closeSync(fd);
  const started = Date.now();
  while (!await fetch('http://localhost:3167').then(async r => { await r.body?.cancel(); return r.ok; }).catch(() => false)) { assert.ok(Date.now() - started < 90000); await new Promise(r => setTimeout(r, 500)); }
  browser = await chromium.launch({ headless: true }); const context = await browser.newContext({ viewport: { width: 1280, height: 800 }, locale: 'zh-CN' });
  await context.addInitScript(installLayoutBridge, { base: backend.base, session: 'android-host' }); page = await context.newPage(); page.setDefaultTimeout(12000);
  await page.goto(`http://localhost:3167/meeting-details?id=${sharedId}`, { waitUntil: 'domcontentloaded', timeout: 45000 });
  await page.getByRole('tab', { name: '转写', exact: true }).click(); await page.locator('[data-testid=transcript-empty-state][data-state=processing]').waitFor();
  ready = true; state.phase = 'ready'; save();
  server = http.createServer(async (req, res) => {
    const reply = (code, data) => { res.writeHead(code, { 'content-type': 'application/json' }); res.end(JSON.stringify(data)); };
    try {
      const chunks = []; for await (const c of req) chunks.push(c); const input = chunks.length ? JSON.parse(Buffer.concat(chunks)) : {};
      if (req.url === '/ready') return reply(ready ? 200 : 503, { ready });
      if (req.url === '/rpc') {
        const route = input.path, args = { meetingId: sharedId, offset: input.query?.offset || 0, limit: input.query?.limit || 100 };
        const rpc = route.endsWith('/metadata') ? 'api_get_meeting_metadata' : route.endsWith('/transcripts') ? 'api_get_meeting_transcripts' : route.endsWith('/recording') ? 'room_recording_status' : route.endsWith('/summary') ? 'api_get_summary' : null;
        if (!rpc) return reply(200, { status: 200, body: {} });
        const value = await command('android-host', rpc, args); return reply(200, { status: value.status, body: value.data.value || value.data.error });
      }
      if (req.url === '/advance') {
        if (Date.now() - budget.started >= budget.limitMs) throw Error('Cumulative 30 minute E2E budget exhausted');
        await control({ status: input.status });
        await page.getByRole('tab', { name: '转写', exact: true }).click();
        if (input.status === 'completed') await page.getByText(/第 1 条转写/).first().waitFor();
        else await page.locator(`[data-testid=transcript-empty-state][data-state=${input.status === 'failed' ? 'failed' : 'processing'}]`).waitFor();
        assert.equal(backend.calls.filter(c => c.command === 'server_fetch_meeting_audio').length, 0);
        const row = { platform: 'desktop-shared-fixture', phase: input.capture ? 'screenshots' : 'assertions', operation: input.status, expected: '共享任务状态与零自动下载', actual: `${input.status}; downloadIPC=0`, pass: true, screenshot: null };
        if (input.capture) { row.screenshot = `screenshots/interop-desktop-${input.status}.png`; await page.screenshot({ path: path.join(out, row.screenshot) }); }
        rows.push(row); save(); console.log(JSON.stringify(row)); return reply(200, {});
      }
      if (req.url === '/shot') { assert.match(input.name, /^android-(queued|running|completed|failed)$/); fs.writeFileSync(path.join(out, `screenshots/${input.name}.png`), execFileSync(adb, ['-s', 'emulator-5580', 'exec-out', 'screencap', '-p'], { windowsHide: true })); return reply(200, {}); }
      if (req.url === '/row') { rows.push(input); save(); console.log(JSON.stringify(input)); return reply(200, {}); }
      if (req.url === '/done') { state.phase = 'completed'; save(); reply(200, {}); done(); return; }
      reply(404, {});
    } catch (error) { state.error = String(error); save(); reply(500, { error: String(error) }); }
  });
  await new Promise(resolve => server.listen(39348, '127.0.0.1', resolve));
  execFileSync(adb, ['-s', 'emulator-5580', 'reverse', 'tcp:39348', 'tcp:39348'], { windowsHide: true });
  const remaining = Math.max(1, budget.limitMs - Date.now() + budget.started);
  let timer; await Promise.race([finished, new Promise((_, reject) => { timer = setTimeout(() => reject(Error('E2E budget exhausted before Android completed')), remaining); })]); clearTimeout(timer);
} catch (e) { state.error = String(e); state.phase = 'failed'; process.exitCode = 1; }
finally {
  await browser?.close(); state.cleanup.browserClosed = true;
  if (next) state.cleanup.nextStopped = spawnSync('taskkill.exe', ['/PID', String(next.pid), '/T', '/F'], { windowsHide: true }).status === 0;
  await backend.close(); if (server) await new Promise(resolve => server.close(resolve));
  state.cleanup.fixtureClosed = true; fs.writeFileSync(path.join(front, 'tsconfig.json'), before);
  state.cleanup.tsconfigRestored = true; budget.usedMs = Date.now() - budget.started; fs.writeFileSync(path.join(out, 'budget.json'), JSON.stringify(budget, null, 2)); save();
}
