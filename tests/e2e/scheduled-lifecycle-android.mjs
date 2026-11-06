import { testAdb } from './local-tools.cjs';
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';
const root = fileURLToPath(new URL('../../', import.meta.url)), out = path.join(root, '.artifacts/scheduled-meeting-lifecycle');
const adb = testAdb(), rows = [];
const budget = JSON.parse(fs.readFileSync(path.join(out, 'budget.json'), 'utf8'));
const server = http.createServer(async (req, res) => {
  try {
    if (Date.now() - budget.started > budget.limitMs) throw Error('30分钟E2E预算耗尽');
    let raw = ''; for await (const chunk of req) raw += chunk; const body = raw ? JSON.parse(raw) : {};
    if (req.url === '/row') { rows.push(body); fs.writeFileSync(path.join(out, 'android-results.json'), JSON.stringify({ rows }, null, 2)); console.log(JSON.stringify(body)); }
    if (req.url === '/shot') {
      if (!/^screenshots\/android-\d+-[a-z0-9-]+\.png$/.test(body.path)) throw Error('Invalid screenshot path');
      const r = spawnSync(adb, ['-s', 'emulator-5580', 'exec-out', 'screencap', '-p'], { windowsHide: true, maxBuffer: 16e6 });
      if (r.status !== 0 || r.stdout.length < 1000) throw Error('ADB screenshot failed'); fs.writeFileSync(path.join(out, body.path), r.stdout);
    }
    if (req.url === '/done') {
      const snapshot = await (await fetch('http://127.0.0.1:3169/__snapshot')).json(); fs.writeFileSync(path.join(out, 'android-database.json'), JSON.stringify(snapshot, null, 2));
      budget.usedMs = Date.now() - budget.started; fs.writeFileSync(path.join(out, 'budget.json'), JSON.stringify(budget, null, 2));
    }
    res.setHeader('Content-Type', 'application/json'); res.end('{}');
    if (req.url === '/done') server.close();
  } catch (e) { res.statusCode = 500; res.end(JSON.stringify({ error: String(e) })); }
});
await new Promise(r => server.listen(39349, '127.0.0.1', r)); console.log('Android evidence bridge :39349');
process.on('SIGINT', () => server.close());
