// Loopback-only Android evidence collector; no credentials or business data.
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
const root = fileURLToPath(new URL('../../', import.meta.url));
const out = path.join(root, '.artifacts/mobile-avatar-toolbar');
fs.mkdirSync(path.join(out, 'screenshots'), { recursive: true });
const port = 39341, rows = [];
let done;
const send = (res, status, body) => { res.writeHead(status, { 'content-type': 'application/json' }); res.end(JSON.stringify(body)); };
const server = http.createServer(async (req, res) => {
  try {
    const url = new URL(req.url, `http://127.0.0.1:${port}`);
    if (req.method === 'GET' && url.pathname === '/avatar.png') {
      res.writeHead(200, { 'content-type': 'image/png' });
      return res.end(fs.readFileSync(path.join(root, 'mobile/assets/brand/brand-logo.png')));
    }
    if (req.method === 'GET' && url.pathname === '/status') return send(res, 200, { rows: rows.length, done });
    if (req.method === 'GET') return send(res, 404, { error: 'fixture not found' });
    const chunks = []; for await (const chunk of req) chunks.push(chunk);
    const data = Buffer.concat(chunks);
    if (url.pathname === '/begin') {
      const budget = JSON.parse(fs.readFileSync(path.join(out, 'budget.json')));
      if (Date.now() - budget.started > 1800000) return send(res, 409, { error: 'E2E budget exhausted' });
      if (rows.length) {
        fs.mkdirSync(path.join(out, 'history'), { recursive: true });
        fs.writeFileSync(path.join(out, 'history', `android-${Date.now()}.json`), JSON.stringify(rows, null, 2));
        rows.length = 0;
      }
      done = undefined;
      return send(res, 200, { ok: true });
    }
    if (url.pathname === '/row') {
      const row = JSON.parse(data); rows.push(row);
      fs.writeFileSync(path.join(out, 'android-results.json'), JSON.stringify(rows, null, 2));
      console.log(JSON.stringify(row)); return send(res, 200, { ok: true });
    }
    if (url.pathname === '/screenshot') {
      const name = url.searchParams.get('name');
      if (!/^screenshots\/android-\d+-[\d.]+-[a-z-]+\.png$/.test(name)) return send(res, 400, { error: 'invalid image name' });
      fs.writeFileSync(path.join(out, name), data); return send(res, 200, { ok: true });
    }
    if (url.pathname === '/done') { done = JSON.parse(data); fs.writeFileSync(path.join(out, 'android-run.json'), JSON.stringify(done, null, 2)); return send(res, 200, { ok: true }); }
    if (url.pathname === '/shutdown') { send(res, 200, { stopped: true }); return server.close(); }
    return send(res, 404, { error: 'fixture not found' });
  } catch (error) { send(res, 500, { error: String(error) }); }
});
server.listen(port, '127.0.0.1', () => {
  fs.writeFileSync(path.join(out, 'android-bridge-runtime.json'), JSON.stringify({ pid: process.pid, port, started: new Date().toISOString() }));
  console.log(JSON.stringify({ ready: true, port }));
});
