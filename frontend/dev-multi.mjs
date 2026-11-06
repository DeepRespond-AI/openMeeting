#!/usr/bin/env node
// One Next.js server, three native clients with separate Tauri profiles (Windows).
import { spawn, execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const frontend = path.dirname(fileURLToPath(import.meta.url));
const root = path.dirname(frontend);
const native = path.join(frontend, 'src-tauri');
const work = path.join(root, '.artifacts', 'dev-multi');
const statePath = path.join(work, 'state.json');
const devUrl = 'http://localhost:3118';
const args = process.argv.slice(2);
const command = args[0] && !args[0].startsWith('-') ? args.shift() : 'start';
const options = {};
while (args.length) {
  const key = args.shift();
  if (['--help', '--rebuild'].includes(key)) options[key] = true;
  else if (['--server-url', '--target-dir'].includes(key) && args[0] && !args[0].startsWith('--')) options[key] = args.shift();
  else throw new Error(`Unknown or incomplete option: ${key}`);
}
if (options['--help'] || command === 'help') {
  console.log(`Usage (in frontend):
  pnpm dev:multi                          Start/reuse three clients + shared Next.js :3118
  pnpm dev:multi --rebuild                Rebuild native clients
  pnpm dev:multi --server-url URL         Backend (default http://127.0.0.1:39110)
  pnpm dev:multi --target-dir PATH        Reuse a Cargo build cache
  pnpm dev:multi:status                   Show managed processes and profile paths
  pnpm dev:multi:stop                     Stop managed processes; keep profiles/cache

Windows only. Frontend UI changes hot reload in all three clients.
Native changes are rebuilt on the next start. Log in with three different accounts.`);
  process.exit(0);
}
if (process.platform !== 'win32') throw new Error('dev-multi currently supports Windows only.');
if (!['start', 'stop', 'status'].includes(command)) throw new Error(`Unknown command: ${command}`);

function readJson(file, fallback) {
  return fs.existsSync(file) ? JSON.parse(fs.readFileSync(file, 'utf8')) : fallback;
}
let state = readJson(statePath, { clients: [] });
function save() {
  fs.writeFileSync(`${statePath}.tmp`, JSON.stringify(state, null, 2));
  fs.renameSync(`${statePath}.tmp`, statePath);
}
function ps(script) {
  const source = "$ProgressPreference='SilentlyContinue'; [Console]::OutputEncoding=[System.Text.UTF8Encoding]::new(); " + script;
  return execFileSync('powershell.exe', ['-NoProfile', '-NonInteractive', '-EncodedCommand', Buffer.from(source, 'utf16le').toString('base64')], { encoding: 'utf8', windowsHide: true }).trim();
}
function processes() {
  const data = JSON.parse(ps(`$ErrorActionPreference='Stop'; @(Get-CimInstance Win32_Process | Select-Object ProcessId,ParentProcessId,ExecutablePath,CommandLine,@{n='Created';e={$_.CreationDate.ToUniversalTime().Ticks.ToString()}}) | ConvertTo-Json -Compress`));
  return Array.isArray(data) ? data : [data];
}
function samePath(a, b) {
  return typeof a === 'string' && typeof b === 'string' && path.resolve(a).toLowerCase() === path.resolve(b).toLowerCase();
}
function alive(record, list) {
  return record && list.some(p => p.ProcessId === record.pid && p.Created === record.created && samePath(p.ExecutablePath, record.exe));
}
const delay = ms => new Promise(resolve => setTimeout(resolve, ms));
async function run(exe, argv, env = process.env) {
  await new Promise((resolve, reject) => {
    const child = spawn(exe, argv, { cwd: frontend, env, stdio: 'inherit', windowsHide: true });
    child.on('error', reject);
    child.on('exit', code => code === 0 ? resolve() : reject(new Error(`${exe} exited with code ${code}`)));
  });
}
async function launch(exe, argv, log, env = process.env) {
  const fd = fs.openSync(path.join(work, log), 'a');
  let child;
  try {
    child = spawn(exe, argv, { cwd: frontend, env, detached: true, windowsHide: true, stdio: ['ignore', fd, fd] });
    await new Promise((resolve, reject) => { child.once('spawn', resolve); child.once('error', reject); });
  } finally { fs.closeSync(fd); }
  child.unref();
  for (let i = 0; i < 20; i++) {
    const p = processes().find(p => p.ProcessId === child.pid);
    if (p) return { pid: child.pid, created: p.Created, exe: p.ExecutablePath };
    await delay(200);
  }
  throw new Error(`Process failed to start. See ${path.join(work, log)}`);
}
async function stop(record) {
  if (!alive(record, processes())) return;
  execFileSync('taskkill.exe', ['/PID', String(record.pid), '/T', '/F'], { windowsHide: true, stdio: 'ignore' });
  for (let i = 0; i < 30 && alive(record, processes()); i++) await delay(100);
  if (alive(record, processes())) throw new Error(`Could not stop managed PID ${record.pid}`);
}
function listener() {
  const raw = ps(`@(Get-NetTCPConnection -LocalPort 3118 -State Listen -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess -Unique) | ConvertTo-Json -Compress`);
  const ids = raw ? JSON.parse(raw) : [];
  const list = processes();
  const owners = (Array.isArray(ids) ? ids : [ids]).map(id => list.find(p => p.ProcessId === id));
  if (!owners.length) return null;
  const project = frontend.replaceAll('\\', '/').toLowerCase();
  // Only reuse a Next worker whose command line points into this checkout.
  if (owners.some(p => {
    const cmd = p?.CommandLine?.replaceAll('\\', '/').toLowerCase() || '';
    return !cmd.includes(`${project}/node_modules/`) || !cmd.includes('/next/dist/server/lib/start-server.js');
  })) {
    throw new Error('Port 3118 is occupied by an unrecognized service. Free the port before starting dev:multi.');
  }
  return owners[0];
}
async function ready() {
  const deadline = Date.now() + 120_000;
  while (Date.now() < deadline) {
    try {
      const response = await fetch(devUrl, { signal: AbortSignal.timeout(5000) });
      await response.body?.cancel();
      if (response.ok) return;
    } catch { /* Next may still be compiling. */ }
    await delay(500);
  }
  throw new Error(`Next.js did not become ready at ${devUrl}. See ${path.join(work, 'next.log')}`);
}
function show() {
  const list = processes();
  const serving = listener();
  console.log(`Frontend: ${devUrl} (${serving ? 'listening' : 'stopped'}; ${state.next?.owned ? 'managed by this script' : 'reused/not managed'})`);
  for (const c of state.clients ?? []) {
    console.log(`DEV ${c.name}: ${alive(c.process, list) ? `running PID ${c.process.pid}` : 'stopped'} | ${c.identifier}`);
    console.log(`  Profile: ${path.join(process.env.APPDATA, c.identifier)}`);
  }
  console.log(`Logs / build cache metadata: ${work}`);
}
function digestNative(config, serverUrl, rustVersion) {
  const hash = createHash('sha256');
  hash.update(JSON.stringify({ buildVersion: 1, config, serverUrl, rustVersion, env: ['RUSTFLAGS', 'CARGO_ENCODED_RUSTFLAGS', 'RUSTUP_TOOLCHAIN', 'CARGO_BUILD_TARGET'].map(k => [k, process.env[k]]) }));
  function visit(file) {
    if (!fs.existsSync(file)) return;
    if (fs.statSync(file).isDirectory()) {
      for (const entry of fs.readdirSync(file).sort()) visit(path.join(file, entry));
    } else { hash.update(path.relative(root, file)); hash.update(fs.readFileSync(file)); }
  }
  for (const file of ['Cargo.toml', 'Cargo.lock', '.cargo']) visit(path.join(root, file));
  for (const file of ['Cargo.toml', 'build.rs', 'tauri.conf.json', 'tauri.windows.conf.json', '.cargo', 'src', 'icons', 'capabilities', 'build']) visit(path.join(native, file));
  return hash.digest('hex');
}
function serverUrl() {
  const line = fs.existsSync(path.join(frontend, '.env')) ? fs.readFileSync(path.join(frontend, '.env'), 'utf8').split(/\r?\n/).find(s => /^\s*OPENMEETING_SERVER_URL\s*=/.test(s)) : undefined;
  const fromFile = line?.slice(line.indexOf('=') + 1).trim().replace(/^(['"])(.*)\1$/, '$2');
  const value = options['--server-url'] || process.env.OPENMEETING_SERVER_URL || fromFile || 'http://127.0.0.1:39110';
  const url = new URL(value);
  if (!['http:', 'https:'].includes(url.protocol) || url.username || url.password) throw new Error('Backend must be an HTTP(S) URL without credentials.');
  return value.replace(/\/$/, '');
}

fs.mkdirSync(work, { recursive: true });
if (command === 'status') { show(); process.exit(0); }
const lockPath = path.join(work, 'operation.lock');
try {
  if (fs.existsSync(lockPath)) {
    const lock = readJson(lockPath, {});
    if (alive(lock, processes())) throw new Error('Another dev-multi operation is running.');
    fs.unlinkSync(lockPath);
  }
  const own = processes().find(p => p.ProcessId === process.pid);
  fs.writeFileSync(lockPath, JSON.stringify({ pid: process.pid, exe: own.ExecutablePath, created: own.Created }), { flag: 'wx' });
} catch (error) { console.error(error.message); process.exit(1); }

try {
  if (command === 'stop') {
    for (const client of state.clients ?? []) await stop(client.process);
    if (state.next?.owned) await stop(state.next.process);
    console.log('Managed clients/server stopped. Reused servers, profiles and build cache were kept.');
  } else {
    const existingNext = listener(); // Check before doing any builds or stopping clients.
    const config = readJson(path.join(native, 'tauri.conf.json'));
    const backend = serverUrl();
    const rustVersion = execFileSync('rustc', ['-vV'], { encoding: 'utf8', windowsHide: true });
    const triple = rustVersion.match(/^host: (.+)$/m)?.[1].trim();
    if (process.env.CARGO_BUILD_TARGET && process.env.CARGO_BUILD_TARGET !== triple) throw new Error('Cross compilation is not supported by dev-multi.');
    const targetDir = path.resolve(options['--target-dir'] || state.targetDir || path.join(root, 'target', 'dev-multi-native'));
    const sourceExe = path.join(targetDir, 'debug', 'openmeeting.exe');
    const clients = ['A', 'B', 'C'].map((name, index) => {
      const identifier = `${config.identifier}.dev${index + 1}`;
      const override = { identifier, build: { devUrl, beforeDevCommand: '' }, app: { windows: config.app.windows.map((w, i) => ({ ...w, label: w.label || (i === 0 ? 'main' : `window-${i}`), title: `${w.title} · DEV ${name}` })) } };
      const dir = path.join(work, 'clients', name);
      return { name, identifier, dir, override, key: digestNative(override, backend, rustVersion), process: state.clients?.find(c => c.identifier === identifier)?.process };
    });
    state.targetDir = targetDir;
    state.serverUrl = backend;
    state.clients = clients;
    save();
    console.log(`Backend: ${backend}\nShared frontend: ${devUrl}`);
    for (const c of clients) {
      const marker = path.join(c.dir, 'build.json');
      const exe = path.join(c.dir, 'openmeeting.exe');
      const cached = !options['--rebuild'] && readJson(marker, {})?.key === c.key && fs.existsSync(exe) && fs.existsSync(path.join(c.dir, 'app_lib.dll')) && fs.existsSync(path.join(c.dir, 'ffmpeg.exe'));
      if (cached) { console.log(`DEV ${c.name}: using cached native build`); continue; }
      await stop(c.process);
      if (processes().some(p => samePath(p.ExecutablePath, sourceExe))) throw new Error(`Cargo output is running: ${sourceExe}. Close that app or select another --target-dir.`);
      console.log(`DEV ${c.name}: building native client (first build can take several minutes)...`);
      const env = { ...process.env, CARGO_TARGET_DIR: targetDir, OPENMEETING_SERVER_URL: backend, TAURI_CONFIG: JSON.stringify(c.override) };
      await run('cargo', ['build', '-p', 'openmeeting', '--bin', 'openmeeting', '--locked'], env);
      fs.mkdirSync(c.dir, { recursive: true });
      for (const name of ['openmeeting.exe', 'app_lib.dll']) fs.copyFileSync(path.join(targetDir, 'debug', name), path.join(c.dir, name));
      for (const binary of config.bundle.externalBin ?? []) {
        const source = path.join(native, `${binary}-${triple}.exe`);
        fs.copyFileSync(source, path.join(c.dir, `${path.basename(binary)}.exe`));
        fs.copyFileSync(source, path.join(c.dir, path.basename(source)));
      }
      fs.writeFileSync(marker, JSON.stringify({ key: c.key, backend, override: c.override }, null, 2));
    }
    await run(process.execPath, [path.join(frontend, 'scripts', 'build-im-engine.mjs')]);
    if (existingNext) {
      console.log('Reusing the Next.js server from this checkout on :3118.');
      if (!state.next?.owned || !alive(state.next.process, processes())) state.next = { owned: false };
    } else {
      const env = { ...process.env, NEXT_PUBLIC_LIVE_MEETING_DATA_SOURCE: 'real', OPENMEETING_E2E_SYNTHETIC: '0' };
      state.next = { owned: true, process: await launch(process.execPath, [path.join(frontend, 'node_modules', 'next', 'dist', 'bin', 'next'), 'dev', '-p', '3118'], 'next.log', env) };
    }
    save();
    await ready();
    for (const c of clients) {
      if (!alive(c.process, processes())) {
        c.process = await launch(path.join(c.dir, 'openmeeting.exe'), [], `client-${c.name}.log`);
        save();
      }
    }
    await delay(3000);
    if (clients.some(c => !alive(c.process, processes()))) throw new Error('A client exited during startup. Inspect client-A/B/C.log.');
    show();
    console.log('Ready. Log in with a different test account in each window.');
  }
} catch (error) {
  console.error(`dev-multi: ${error.message}\nRun pnpm dev:multi:status or pnpm dev:multi:stop to inspect/stop managed processes.`);
  process.exitCode = 1;
} finally { fs.unlinkSync(lockPath); }
