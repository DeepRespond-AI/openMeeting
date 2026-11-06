import { testAdb, testDevice } from './local-tools.cjs';
// Loopback-only evidence collector and Android system capture consent driver.
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
const root = fileURLToPath(new URL('../../', import.meta.url));
const out = process.env.OPENMEETING_CORE_ARTIFACT_DIR
  ? path.resolve(root, process.env.OPENMEETING_CORE_ARTIFACT_DIR)
  : path.join(root, '.artifacts/mobile-core-parity');
if (!out.startsWith(path.join(root, '.artifacts') + path.sep)) throw Error('Evidence directory must stay inside .artifacts');
fs.mkdirSync(path.join(out, 'screenshots'), { recursive: true });
const adb = testAdb();
const device = testDevice();
const port = Number(process.env.OPENMEETING_E2E_BRIDGE_PORT ?? 39342);
const run = (...args) => execFileSync(adb, ['-s', device, ...args], { windowsHide: true, timeout: 12000, maxBuffer: 20 * 1024 * 1024 });
const rows = []; let done;
const send = (res, status, body) => { res.writeHead(status, { 'content-type': 'application/json' }); res.end(JSON.stringify(body)); };
const server = http.createServer(async (req, res) => {
  try {
    const url = new URL(req.url, `http://127.0.0.1:${port}`);
    if (req.method === 'GET' && url.pathname === '/status') return send(res, 200, { rows: rows.length, done });
    const chunks = []; for await (const chunk of req) chunks.push(chunk); const bytes = Buffer.concat(chunks);
    if (url.pathname === '/begin') {
      const budget = JSON.parse(fs.readFileSync(path.join(out, 'budget.json')));
      if (Date.now() - budget.started > budget.limitMs) return send(res, 409, { error: 'E2E budget exhausted' });
      if (rows.length) fs.writeFileSync(path.join(out, `android-history-${Date.now()}.json`), JSON.stringify(rows, null, 2));
      rows.length = 0; done = undefined; return send(res, 200, { ok: true });
    }
    if (url.pathname === '/row') { const row = JSON.parse(bytes); rows.push(row); fs.writeFileSync(path.join(out, 'android-results.json'), JSON.stringify(rows, null, 2)); console.log(JSON.stringify(row)); return send(res, 200, { ok: true }); }
    if (url.pathname === '/screenshot') {
      const name = url.searchParams.get('name');
      if (!/^screenshots\/android-\d+-\d+-[a-z-]+\.png$/.test(name)) return send(res, 400, { error: 'Invalid image name' });
      fs.writeFileSync(path.join(out, name), bytes); return send(res, 200, { ok: true });
    }
    if (url.pathname === '/consent') {
      const { allow } = JSON.parse(bytes);
      let clicked = false;
      for (let i = 0; i < 4 && !clicked; i++) {
        const focus = run('shell', 'dumpsys', 'window').toString();
        if (/mCurrentFocus[^\r\n]*(MediaProjection|ScreenCapture)/i.test(focus)) {
          run('shell', 'uiautomator', 'dump', '/sdcard/openmeeting-core-ui.xml');
          const xml = run('shell', 'cat', '/sdcard/openmeeting-core-ui.xml').toString();
          for (const node of xml.matchAll(/<node\b[^>]*>/g)) {
            const text = /text="([^"]*)"/.exec(node[0])?.[1];
            const bounds = /bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"/.exec(node[0]);
            if (bounds && (allow ? /^(立即开始|开始录制|现在开始|Start now|START NOW)$/i : /^(取消|Cancel|CANCEL)$/i).test(text ?? '')) {
              fs.writeFileSync(path.join(out, 'screenshots', `android-${allow ? '13' : '12'}-960-system-${allow ? 'allow' : 'deny'}.png`), run('exec-out', 'screencap', '-p'));
              run('shell', 'input', 'tap', String(Math.round((+bounds[1] + +bounds[3]) / 2)), String(Math.round((+bounds[2] + +bounds[4]) / 2)));
              clicked = true; break;
            }
          }
        }
        if (!clicked) await new Promise(r => setTimeout(r, 500));
      }
      run('shell', 'rm', '-f', '/sdcard/openmeeting-core-ui.xml');
      return send(res, clicked ? 200 : 409, { clicked, allow });
    }
    if (url.pathname === '/device-screenshot') {
      const { name } = JSON.parse(bytes);
      if (!/^screenshots\/android-\d+-\d+-[a-z-]+\.png$/.test(name)) return send(res, 400, { error: 'Invalid image name' });
      const focus = run('shell', 'dumpsys', 'window').toString();
      const packageName = process.env.OPENMEETING_E2E_PACKAGE;
      const foreground = packageName
        ? focus.split('\n').some(line => line.includes('mCurrentFocus') && line.includes(`${packageName}/`))
        : /mCurrentFocus[^\r\n]*cn\.deeprespond\.meeting\.(coreretry|coreparity)/.test(focus);
      if (!foreground) return send(res, 409, { error: 'Test application not foreground' });
      fs.writeFileSync(path.join(out, name), run('exec-out', 'screencap', '-p'));
      return send(res, 200, { ok: true });
    }
    if (url.pathname === '/done') { done = JSON.parse(bytes); fs.writeFileSync(path.join(out, 'android-run.json'), JSON.stringify(done, null, 2)); return send(res, 200, { ok: true }); }
    if (url.pathname === '/shutdown') { send(res, 200, { stopped: true }); return server.close(); }
    return send(res, 404, { error: 'Unknown route' });
  } catch (error) { send(res, 500, { error: String(error) }); }
});
server.listen(port, '127.0.0.1', () => {
  fs.writeFileSync(path.join(out, 'bridge-runtime.json'), JSON.stringify({ pid: process.pid, port, started: new Date().toISOString() }));
  console.log(JSON.stringify({ ready: true, port }));
});
