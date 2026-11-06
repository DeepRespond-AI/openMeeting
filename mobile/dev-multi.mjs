#!/usr/bin/env node
// Windows / Android: one debug APK, three persistent AVDs, three hot-reload sessions.
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import http from 'node:http';
import net from 'node:net';
import { spawn, execFileSync } from 'node:child_process';
import { createHash, randomBytes } from 'node:crypto';
import { fileURLToPath } from 'node:url';
import { createInterface } from 'node:readline';
import { SerialOperations, machineRpc } from './tool/dev-multi-runtime.mjs';

const mobile = path.dirname(fileURLToPath(import.meta.url));
const root = path.dirname(mobile);
const work = path.join(root, '.artifacts', 'mobile-dev-multi');
const stateFile = path.join(work, 'state.json');
const packageId = 'cn.deeprespond.meeting';
const argv = process.argv.slice(2);
const action = argv[0] && !argv[0].startsWith('-') ? argv.shift() : 'start';
const options = {};
while (argv.length) {
  const key = argv.shift();
  if (['--help', '--rebuild', '--no-watch', '--no-mirror'].includes(key)) options[key] = true;
  else if (['--flutter-sdk', '--android-sdk', '--java-home', '--server-url', '--template-avd'].includes(key)
    && argv[0] && !argv[0].startsWith('--')) options[key] = argv.shift();
  else throw new Error(`Unknown or incomplete option: ${key}`);
}
if (action === 'help' || options['--help']) {
  console.log(`Usage (mobile/, Windows, Node.js 20+):
  node dev-multi.mjs start [--template-avd Pixel_7] [--server-url http://10.0.2.2:39110]
  node dev-multi.mjs status
  node dev-multi.mjs reload             Hot reload all three clients
  node dev-multi.mjs restart            Hot restart all three clients
  node dev-multi.mjs stop               Keep login data and build cache
  node dev-multi.mjs start --rebuild    Stop sessions, rebuild, start again

Optional: --flutter-sdk PATH --android-sdk PATH --java-home PATH --no-watch --no-mirror
Creates three dedicated AVDs from an installed template (configuration only; no login data copied).
Requires an already running development backend. Dart/assets changes reload automatically.
Stop/restart after native/plugin/config changes. Logs: ${work}`);
  process.exit(0);
}
if (process.platform !== 'win32') throw new Error('This launcher currently supports Windows / Android only.');
if (!['start', 'serve', 'status', 'reload', 'restart', 'stop'].includes(action)) throw new Error(`Unknown action: ${action}`);
const sleep = ms => new Promise(resolve => setTimeout(resolve, ms));
const readJson = (file, fallback = null) => fs.existsSync(file) ? JSON.parse(fs.readFileSync(file, 'utf8').replace(/^\uFEFF/, '')) : fallback;
let state = readJson(stateFile, { clients: [] });
function save() {
  fs.mkdirSync(work, { recursive: true });
  fs.writeFileSync(`${stateFile}.tmp`, JSON.stringify(state, null, 2));
  fs.renameSync(`${stateFile}.tmp`, stateFile);
}
function ps(source) {
  return execFileSync('powershell.exe', ['-NoProfile', '-NonInteractive', '-EncodedCommand', Buffer.from(
    "$ErrorActionPreference='Stop'; $ProgressPreference='SilentlyContinue'; [Console]::OutputEncoding=[Text.UTF8Encoding]::new(); " + source, 'utf16le').toString('base64')],
  { encoding: 'utf8', windowsHide: true }).trim();
}
function identity(pid) {
  const raw = ps(`Get-CimInstance Win32_Process -Filter 'ProcessId=${Number(pid)}' | Select-Object ProcessId,ExecutablePath,@{n='Created';e={$_.CreationDate.ToUniversalTime().Ticks.ToString()}} | ConvertTo-Json -Compress`);
  if (!raw) return null;
  const p = JSON.parse(raw);
  return { pid: p.ProcessId, exe: p.ExecutablePath, created: p.Created };
}
function alive(record) {
  if (!record) return false;
  const p = identity(record.pid);
  return p && p.created === record.created && p.exe?.toLowerCase() === record.exe?.toLowerCase();
}
function qemuIdentity(parentPid, avd) {
  const raw = ps(`@(Get-CimInstance Win32_Process -Filter 'ParentProcessId=${Number(parentPid)}' | Where-Object {$_.Name -like 'qemu-system-*'} | Select-Object ProcessId,ExecutablePath,CommandLine,@{n='Created';e={$_.CreationDate.ToUniversalTime().Ticks.ToString()}}) | ConvertTo-Json -Compress`);
  const parsed = raw ? JSON.parse(raw) : [];
  const p = (Array.isArray(parsed) ? parsed : [parsed]).find(p => p.CommandLine?.includes(`-avd ${avd} `));
  return p ? { pid: p.ProcessId, exe: p.ExecutablePath, created: p.Created } : null;
}
function kill(record) {
  if (alive(record)) execFileSync('taskkill.exe', ['/PID', String(record.pid), '/T', '/F'], { windowsHide: true, stdio: 'ignore' });
}
async function control(command, timeout = 120_000) {
  if (!state.port || !state.token) throw new Error('No managed session. Run start first.');
  const res = await fetch(`http://127.0.0.1:${state.port}/${command}`, {
    method: 'POST', headers: { Authorization: `Bearer ${state.token}` }, signal: AbortSignal.timeout(timeout),
  });
  const result = await res.json();
  if (!res.ok) throw new Error(result.error || `Control failed (${res.status})`);
  return result;
}
function properties(file) {
  return Object.fromEntries(fs.existsSync(file) ? fs.readFileSync(file, 'utf8').split(/\r?\n/).filter(l => l.includes('=') && !l.startsWith('#'))
    .map(l => [l.slice(0, l.indexOf('=')), l.slice(l.indexOf('=') + 1).replaceAll('\\\\', '\\').replaceAll('\\:', ':')]) : []);
}
function resolveTools() {
  const local = properties(path.join(mobile, 'android', 'local.properties'));
  const onPath = (process.env.PATH || '').split(path.delimiter).map(p => path.dirname(p)).find(p => fs.existsSync(path.join(p, 'bin', 'flutter.bat')));
  const flutter = options['--flutter-sdk'] || process.env.FLUTTER_ROOT || local['flutter.sdk'] || onPath
    || path.join(path.dirname(root), 'flutter-toolchain', 'flutter');
  const sdk = options['--android-sdk'] || process.env.ANDROID_HOME || process.env.ANDROID_SDK_ROOT || local['sdk.dir']
    || path.join(process.env.LOCALAPPDATA, 'Android', 'Sdk');
  const java = options['--java-home'] || process.env.JAVA_HOME || [
    path.join(process.env.ProgramFiles, 'Android', 'Android Studio', 'jbr'),
    'D:\\Program Files\\Android\\Android Studio\\jbr',
  ].find(p => fs.existsSync(path.join(p, 'bin', 'java.exe')));
  const dart = path.join(flutter, 'bin', 'cache', 'dart-sdk', 'bin', 'dart.exe');
  const snapshot = path.join(flutter, 'bin', 'cache', 'flutter_tools.snapshot');
  const adb = path.join(sdk, 'platform-tools', 'adb.exe');
  const emulator = path.join(sdk, 'emulator', 'emulator.exe');
  for (const file of [dart, snapshot, adb, emulator]) if (!fs.existsSync(file)) throw new Error(`Missing tool: ${file}. Set SDK options; run flutter doctor first.`);
  if (!java || !fs.existsSync(path.join(java, 'bin', 'java.exe'))) throw new Error('JDK not found. Use --java-home (Android Studio jbr directory).');
  const env = { ...process.env, FLUTTER_ROOT: flutter, ANDROID_HOME: sdk, ANDROID_SDK_ROOT: sdk, JAVA_HOME: java,
    PATH: `${path.join(java, 'bin')}${path.delimiter}${process.env.PATH}`,
    PUB_HOSTED_URL: process.env.PUB_HOSTED_URL || 'https://pub.flutter-io.cn',
    FLUTTER_STORAGE_BASE_URL: process.env.FLUTTER_STORAGE_BASE_URL || 'https://storage.flutter-io.cn',
    NO_PROXY: [process.env.NO_PROXY, 'localhost,127.0.0.1,::1,10.0.2.2'].filter(Boolean).join(','),
  };
  // Host debugger traffic must not go through a global HTTP proxy. Java/Pub can be configured separately.
  for (const key of Object.keys(env)) if (['http_proxy', 'https_proxy', 'all_proxy'].includes(key.toLowerCase())) delete env[key];
  return { flutter, dart, snapshot, adb, emulator, sdk, env };
}
function urlValue() {
  const url = new URL(options['--server-url'] || process.env.OPENMEETING_SERVER_URL || 'http://10.0.2.2:39110');
  if (!['http:', 'https:'].includes(url.protocol) || url.username || url.password || url.search || url.hash) throw new Error('Backend must be an HTTP(S) URL without credentials, query or fragment.');
  if (['localhost', '127.0.0.1', '[::1]'].includes(url.hostname)) throw new Error('Android localhost points to the emulator. Use http://10.0.2.2:39110 for the host backend.');
  return url.toString().replace(/\/$/, '');
}
async function backendReady(url) {
  const probe = new URL(`${url}/api/v1/auth/config`);
  if (probe.hostname === '10.0.2.2') probe.hostname = '127.0.0.1';
  const response = await fetch(probe, { signal: AbortSignal.timeout(8000) });
  if (!response.ok) throw new Error(`Backend probe ${probe} returned ${response.status}; start the development gateway first.`);
}
function avdHome() {
  return process.env.ANDROID_AVD_HOME || path.join(process.env.ANDROID_USER_HOME || path.join(os.homedir(), '.android'), 'avd');
}
function profiles(tools) {
  const home = avdHome();
  const available = execFileSync(tools.emulator, ['-list-avds'], { env: tools.env, encoding: 'utf8', windowsHide: true }).trim().split(/\r?\n/).filter(Boolean);
  const template = options['--template-avd'] || (available.includes('Pixel_7') ? 'Pixel_7' : available.find(n => !n.startsWith('OpenMeeting_DEV_')));
  if (!template || !available.includes(template)) throw new Error(`Installed template AVD not found. Available: ${available.join(', ')}. Create one in Android Studio Device Manager.`);
  const sourceIni = properties(path.join(home, `${template}.ini`));
  const source = properties(path.join(sourceIni.path || path.join(home, `${template}.avd`), 'config.ini'));
  const image = source['image.sysdir.1'];
  if (!image || !fs.existsSync(path.resolve(tools.sdk, image))) throw new Error('Template system image is not installed in the selected Android SDK.');
  const suffix = createHash('sha256').update(root.toLowerCase()).digest('hex').slice(0, 6);
  return ['A', 'B', 'C'].map(name => {
    const avd = `OpenMeeting_DEV_${name}_${suffix}`;
    const directory = path.join(home, `${avd}.avd`);
    const marker = path.join(directory, 'openmeeting-profile.json');
    const prior = readJson(marker);
    if ((fs.existsSync(directory) || fs.existsSync(path.join(home, `${avd}.ini`))) && prior?.root !== root) throw new Error(`Unrecognized AVD ${avd}; refusing to overwrite it.`);
    if (!prior) {
      fs.mkdirSync(directory, { recursive: true });
      // Copy small hardware settings only. Never copy userdata, snapshots, SD cards or secrets.
      const config = { ...source, AvdId: avd, 'avd.ini.displayname': `OpenMeeting DEV ${name}`, 'hw.ramSize': '2048',
        'hw.cpu.ncore': '2', 'disk.dataPartition.size': '4G', 'hw.sdCard': 'no',
        'fastboot.forceColdBoot': 'yes', 'fastboot.forceFastBoot': 'no', 'fastboot.chosenSnapshotFile': '' };
      for (const key of Object.keys(config)) if (/^(sdcard\.|disk\..*\.path|snapshot\.)/.test(key)) delete config[key];
      fs.writeFileSync(path.join(directory, 'config.ini'), Object.entries(config).map(([k, v]) => `${k}=${v}`).join('\n') + '\n');
      fs.writeFileSync(path.join(home, `${avd}.ini`), `avd.ini.encoding=UTF-8\npath=${directory}\ntarget=${source.target}\n`);
      fs.writeFileSync(marker, JSON.stringify({ root, template, createdAt: new Date().toISOString() }, null, 2));
    }
    return { ...state.clients.find(c => c.avd === avd), name, avd, directory, abi: source['abi.type'] };
  });
}
function adb(tools, args) {
  return execFileSync(tools.adb, args, { encoding: 'utf8', windowsHide: true, timeout: 15_000 }).trim();
}
function stopGradle(tools) {
  const gradleHome = path.join(work, 'gradle-home');
  if (!fs.existsSync(gradleHome)) return;
  // Daemon registry is private (only caches/wrapper are junctions). Preserve other builds.
  execFileSync(path.join(tools.env.JAVA_HOME, 'bin', 'java.exe'), [
    '-classpath', path.join(mobile, 'android', 'gradle', 'wrapper', 'gradle-wrapper.jar'),
    'org.gradle.wrapper.GradleWrapperMain', '--stop',
  ], { cwd: path.join(mobile, 'android'), env: { ...tools.env, GRADLE_USER_HOME: gradleHome }, windowsHide: true, timeout: 30_000, stdio: 'ignore' });
}
async function freePort(port) {
  return new Promise(resolve => {
    const server = net.createServer();
    server.once('error', () => resolve(false));
    server.listen(port, '127.0.0.1', () => server.close(() => resolve(true)));
  });
}
const reservedPorts = new Set();
async function launchEmulator(tools, client) {
  if (client.owned && alive(client.emulatorProcess)) {
    reservedPorts.add(Number(client.serial?.replace('emulator-', '')));
    return; // An owned AVD can still be booting/offline after supervisor recovery.
  }
  const connected = adb(tools, ['devices']).split(/\r?\n/).map(l => l.trim()).filter(l => /^emulator-\d+\s+device$/.test(l)).map(l => l.split(/\s/)[0]);
  for (const serial of connected) {
    if (adb(tools, ['-s', serial, 'emu', 'avd', 'name']).split(/\r?\n/)[0].trim() === client.avd) {
      client.serial = serial;
      client.owned = Boolean(client.owned && alive(client.emulatorProcess));
      reservedPorts.add(Number(serial.replace('emulator-', '')));
      return;
    }
  }
  let port = 5560;
  while (reservedPorts.has(port) || !(await freePort(port)) || !(await freePort(port + 1))) {
    port += 2;
    if (port > 5680) throw new Error('No free Android emulator port pair.');
  }
  reservedPorts.add(port); // The emulator may not bind until several seconds after spawn.
  const log = fs.openSync(path.join(work, `emulator-${client.name}.log`), 'a');
  let child;
  try {
    child = spawn(tools.emulator, ['-avd', client.avd, '-port', String(port), '-no-snapshot', '-no-boot-anim', '-no-metrics',
      '-gpu', 'swiftshader', '-feature', '-Vulkan', '-crash-report-mode', 'disabled'],
      { env: tools.env, stdio: ['ignore', log, log], windowsHide: true });
    await new Promise((resolve, reject) => { child.once('spawn', resolve); child.once('error', reject); });
  } finally { fs.closeSync(log); }
  client.serial = `emulator-${port}`;
  client.owned = true;
  client.emulatorProcess = identity(child.pid);
  save();
  // emulator.exe is only a Windows launcher; its QEMU child owns the actual AVD.
  let qemu;
  for (let i = 0; i < 20 && !qemu; i++) { qemu = qemuIdentity(child.pid, client.avd); if (!qemu) await sleep(300); }
  if (!qemu) throw new Error(`No QEMU process for DEV ${client.name}. See emulator-${client.name}.log.`);
  client.emulatorProcess = qemu; save();
}
async function booted(tools, client) {
  const deadline = Date.now() + 180_000;
  while (Date.now() < deadline) {
    try { if (adb(tools, ['-s', client.serial, 'shell', 'getprop', 'sys.boot_completed']) === '1') return; } catch { /* booting */ }
    if (client.owned && !alive(client.emulatorProcess)) throw new Error(`Emulator ${client.name} exited. See emulator-${client.name}.log.`);
    await sleep(1500);
  }
  throw new Error(`Emulator ${client.name} boot timed out. See emulator-${client.name}.log.`);
}
async function flutterBuild(tools, url) {
  // Use a private Gradle home for this launcher's init script. Cache junctions reuse
  // already downloaded artifacts without writing init scripts into the user's home.
  const gradleHome = path.join(work, 'gradle-home');
  const globalHome = process.env.GRADLE_USER_HOME || path.join(os.homedir(), '.gradle');
  fs.mkdirSync(path.join(gradleHome, 'init.d'), { recursive: true });
  for (const name of ['caches', 'wrapper']) {
    const target = path.join(globalHome, name);
    if (fs.existsSync(target) && !fs.existsSync(path.join(gradleHome, name))) fs.symlinkSync(target, path.join(gradleHome, name), 'junction');
  }
  const init = path.join(gradleHome, 'init.d', 'openmeeting-mirrors.gradle');
  if (options['--no-mirror']) { if (fs.existsSync(init)) fs.unlinkSync(init); }
  else fs.copyFileSync(path.join(mobile, 'tool', 'dev-multi-repositories.gradle'), init);
  tools.env.GRADLE_USER_HOME = gradleHome;
  console.log('Building one shared debug APK (native build may take several minutes)...');
  const log = fs.openSync(path.join(work, 'build.log'), 'a');
  const target = { x86_64: 'android-x64', 'arm64-v8a': 'android-arm64' }[state.clients[0]?.abi];
  const child = spawn(tools.dart, [tools.snapshot, 'build', 'apk', '--debug', ...(target ? [`--target-platform=${target}`] : []),
    '--dart-define=APP_ENV=dev', `--dart-define=OPENMEETING_SERVER_URL=${url}`],
    { cwd: mobile, env: tools.env, windowsHide: true, stdio: ['ignore', log, log] });
  fs.closeSync(log);
  child.once('spawn', () => { state.buildProcess = identity(child.pid); save(); });
  await new Promise((resolve, reject) => { child.once('error', reject); child.once('exit', code => code === 0 ? resolve() : reject(new Error(`APK build failed (${code}). See ${path.join(work, 'build.log')}`))); });
  state.buildProcess = null; save();
  stopGradle(tools); // Release the native compiler heap before booting three emulators.
  return path.join(mobile, 'build', 'app', 'outputs', 'flutter-apk', 'app-debug.apk');
}
const sessions = new Map();
const reloadQueue = new SerialOperations();
let stopping = false;
async function launchClient(tools, client, apk, url) {
  await booted(tools, client);
  adb(tools, ['-s', client.serial, 'shell', 'svc', 'wifi', 'enable']);
  if (new URL(url).hostname === '127.0.0.1') {
    const port = new URL(url).port || (new URL(url).protocol === 'https:' ? '443' : '80');
    const endpoint = `tcp:${port}`;
    const existing = adb(tools, ['-s', client.serial, 'reverse', '--list']).split(/\r?\n/).map(l => l.trim().split(/\s+/)).find(parts => parts[1] === endpoint);
    if (existing && existing[2] !== endpoint) throw new Error(`DEV ${client.name}: conflicting ADB reverse ${endpoint}; existing mapping preserved.`);
    if (!existing) {
      adb(tools, ['-s', client.serial, 'reverse', '--no-rebind', endpoint, endpoint]);
      client.reverse = endpoint; save();
    }
  }
  console.log(`Starting DEV ${client.name} on ${client.serial}...`);
  const child = spawn(tools.dart, [tools.snapshot, 'run', '--machine', '--no-dds', '--no-pub', '-d', client.serial,
    `--use-application-binary=${apk}`, '--dart-define=APP_ENV=dev', `--dart-define=OPENMEETING_SERVER_URL=${url}`],
  { cwd: mobile, env: tools.env, stdio: ['pipe', 'pipe', 'pipe'], windowsHide: true });
  const log = fs.createWriteStream(path.join(work, `client-${client.name}.log`), { flags: 'a' });
  child.stdout.pipe(log, { end: false });
  child.stderr.pipe(log, { end: false });
  const session = { child, channel: machineRpc(child.stdin), client };
  sessions.set(client.name, session);
  client.ready = false;
  client.process = null;
  save();
  await new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error(`DEV ${client.name} debugger timeout. See client-${client.name}.log.`)), 120_000);
    child.once('spawn', () => { client.process = identity(child.pid); save(); });
    child.once('error', error => { clearTimeout(timer); reject(error); });
    child.once('exit', code => {
      clearTimeout(timer); client.ready = false; save();
      session.channel.fail(new Error(`DEV ${client.name} exited (${code})`));
      reject(new Error(`DEV ${client.name} exited (${code}). See client-${client.name}.log.`));
    });
    child.once('close', () => log.end()); // stdout/stderr can still drain after exit.
    createInterface({ input: child.stdout }).on('line', line => {
      let messages;
      try { messages = JSON.parse(line); } catch { return; }
      if (!Array.isArray(messages)) return;
      for (const message of messages) {
        if (message.event === 'app.start') { client.appId = message.params.appId; save(); }
        if (message.event === 'app.started') { clearTimeout(timer); client.ready = true; save(); resolve(); }
        if (message.event === 'app.stop') { client.ready = false; save(); }
        session.channel.accept(message);
      }
    });
  });
}
function rpc(session, method, params) {
  return session.channel.call(method, params);
}
let reloading = false;
async function reload(fullRestart = false) {
  return reloadQueue.run(async () => {
  if (stopping) throw new Error('Development session is stopping.');
  reloading = true;
  try {
    const results = [];
    // Sequential compilers avoid racing over shared incremental build output.
    for (const client of state.clients) {
      if (stopping) throw new Error('Development session is stopping.');
      const session = sessions.get(client.name);
      if (!client.ready || !session) throw new Error(`DEV ${client.name} is disconnected. Run start to recover.`);
      const result = await rpc(session, 'app.restart', { appId: client.appId, fullRestart, pause: false });
      if (result?.code !== 0) throw new Error(`DEV ${client.name}: ${JSON.stringify(result)}`);
      results.push({ client: client.name, ...result });
    }
    state.lastReload = { at: new Date().toISOString(), fullRestart, results }; save();
    return results;
  } finally { reloading = false; }
  });
}
async function cleanup(tools) {
  stopping = true;
  reloadQueue.stop();
  kill(state.buildProcess);
  try { stopGradle(tools); } catch (error) { console.error(`Gradle cleanup: ${error.message}`); }
  for (const client of state.clients) {
    const session = sessions.get(client.name);
    if (session && client.ready) {
      try { await rpc(session, 'app.stop', { appId: client.appId }); } catch (error) { console.error(error.message); }
    }
    kill(client.process);
    if (client.reverse) {
      try { adb(tools, ['-s', client.serial, 'reverse', '--remove', client.reverse]); } catch { /* Device may already be closed. */ }
      client.reverse = null;
    }
    if (client.owned && alive(client.emulatorProcess)) {
      // Verify both the process identity and AVD name before closing a device.
      try {
        if (adb(tools, ['-s', client.serial, 'emu', 'avd', 'name']).split(/\r?\n/)[0].trim() === client.avd) adb(tools, ['-s', client.serial, 'emu', 'kill']);
        else kill(client.emulatorProcess);
      } catch { kill(client.emulatorProcess); }
      const deadline = Date.now() + 15_000;
      while (alive(client.emulatorProcess) && Date.now() < deadline) await sleep(300);
      if (alive(client.emulatorProcess)) kill(client.emulatorProcess);
    }
    client.ready = false;
  }
  state.phase = 'stopped'; state.stoppedAt = new Date().toISOString(); save();
}
async function serve() {
  const tools = resolveTools();
  const url = urlValue();
  await backendReady(url);
  const runtime = new URL(url);
  if (runtime.hostname === '10.0.2.2') runtime.hostname = '127.0.0.1';
  const runtimeUrl = runtime.toString().replace(/\/$/, '');
  state = { ...state, supervisor: identity(process.pid), token: randomBytes(24).toString('hex'),
    serverUrl: url, runtimeServerUrl: runtimeUrl, phase: 'starting', startedAt: new Date().toISOString(), error: null };
  const server = http.createServer(async (request, response) => {
    response.setHeader('Content-Type', 'application/json; charset=utf-8');
    if (request.method !== 'POST' || request.headers.authorization !== `Bearer ${state.token}`) { response.writeHead(403); response.end('{}'); return; }
    const command = request.url.slice(1);
    try {
      if (command === 'status') response.end(JSON.stringify({ ...state, token: undefined }));
      else if (command === 'stop' && !stopping) {
        await cleanup(tools); response.end(JSON.stringify({ phase: 'stopped' }));
        server.close(); setTimeout(() => process.exit(0), 300);
      } else if (['reload', 'restart'].includes(command) && state.phase === 'ready') response.end(JSON.stringify(await reload(command === 'restart')));
      else { response.writeHead(409); response.end(JSON.stringify({ error: `Not ready (${state.phase}) or invalid command.` })); }
    } catch (error) { response.writeHead(500); response.end(JSON.stringify({ error: error.message })); }
  });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  state.port = server.address().port; save();
  try {
    state.clients = profiles(tools); save();
    const apk = await flutterBuild(tools, runtimeUrl);
    // Build before booting three emulators, keeping native compiler memory available.
    for (const client of state.clients) await launchEmulator(tools, client);
    for (const client of state.clients) await launchClient(tools, client, apk, runtimeUrl);
    state.phase = 'ready'; save();
    console.log('Three Android clients ready. Dart/assets changes automatically reload all clients.');
    if (!options['--no-watch']) {
      let timer;
      const fingerprints = new Map();
      const digest = file => {
        try { return fs.statSync(file).isFile() ? createHash('sha256').update(fs.readFileSync(file)).digest('hex') : null; }
        catch (error) { if (error.code === 'ENOENT') return null; throw error; }
      };
      const scan = directory => {
        for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
          const file = path.join(directory, entry.name);
          if (entry.isDirectory()) scan(file); else fingerprints.set(file, digest(file));
        }
      };
      for (const directory of ['lib', 'assets']) scan(path.join(mobile, directory));
      const watchReload = () => {
        if (stopping) return;
        if (reloading) { timer = setTimeout(watchReload, 500); return; }
        reload().then(result => console.log(JSON.stringify({ reload: result }))).catch(e => console.error(`Reload: ${e.message}`));
      };
      for (const directory of ['lib', 'assets']) fs.watch(path.join(mobile, directory), { recursive: true }, (_, file) => {
        if (!file || /(?:\.tmp|~)$/.test(file)) return;
        const fullPath = path.join(mobile, directory, file);
        const current = digest(fullPath);
        if ((fingerprints.get(fullPath) ?? null) === current) return;
        fingerprints.set(fullPath, current);
        clearTimeout(timer);
        timer = setTimeout(watchReload, 700);
      });
    }
  } catch (error) {
    if (stopping) return;
    console.error(error.stack); state.error = error.message;
    await cleanup(tools); state.phase = 'failed'; save(); server.close(); process.exitCode = 1;
  }
}
async function main() {
  if (action === 'serve') return serve();
  if (action === 'status') {
    let actual;
    try { actual = await control('status', 5000); } catch { actual = { ...state, token: undefined, phase: alive(state.supervisor) ? 'unresponsive' : 'stopped' }; }
    console.log(JSON.stringify(actual, null, 2)); return;
  }
  if (['reload', 'restart'].includes(action)) { console.log(JSON.stringify(await control(action, 300_000), null, 2)); return; }
  if (action === 'stop') {
    try { console.log(JSON.stringify(await control('stop'))); }
    catch (error) {
      // The PID can be reused. Always verify its executable and creation time.
      if (alive(state.supervisor)) { kill(state.supervisor); await cleanup(resolveTools()); console.log('Stopped verified supervisor, sessions and owned emulators.'); }
      else if (state.clients?.length) { await cleanup(resolveTools()); console.log('Cleaned verified orphan sessions; retained AVD data.'); }
      else { console.log('No live managed supervisor.'); }
    }
    return;
  }
  fs.mkdirSync(work, { recursive: true });
  const lock = path.join(work, 'start.lock');
  if (fs.existsSync(lock)) {
    if (alive(readJson(lock))) throw new Error('Another mobile start operation is running.');
    fs.unlinkSync(lock);
  }
  fs.writeFileSync(lock, JSON.stringify(identity(process.pid)), { flag: 'wx' });
  try {
    if (alive(state.supervisor)) {
      const actual = await control('status', 5000);
      const wantedUrl = urlValue();
      if (!options['--rebuild'] && actual.serverUrl !== wantedUrl) throw new Error('Backend URL changed. Use start --rebuild.');
      if (!options['--rebuild'] && actual.phase === 'ready' && actual.clients.every(c => c.ready)) {
        console.log('Reusing three running clients.'); console.log(JSON.stringify(actual.clients, null, 2)); return;
      }
      await control('stop');
      for (let i = 0; i < 30 && alive(state.supervisor); i++) await sleep(200);
      if (alive(state.supervisor)) throw new Error('Previous supervisor did not stop.');
    }
    // Detect configuration/backend errors before creating profiles or starting services.
    resolveTools(); await backendReady(urlValue());
    if (os.freemem() < 8 * 1024 ** 3) console.warn('Less than 8 GiB free RAM; three 2 GiB emulators plus Flutter may be slow.');
    const log = fs.openSync(path.join(work, 'supervisor.log'), 'a');
    const args = [fileURLToPath(import.meta.url), 'serve', ...process.argv.slice(2).filter((value, index) => !(index === 0 && value === 'start'))];
    let child;
    try {
      child = spawn(process.execPath, args, { cwd: mobile, env: process.env, detached: true, windowsHide: true, stdio: ['ignore', log, log] });
      await new Promise((resolve, reject) => { child.once('spawn', resolve); child.once('error', reject); });
    } finally { fs.closeSync(log); }
    child.unref();
    const processRecord = identity(child.pid);
    console.log(`Starting three clients. Logs: ${work}`);
    console.log('First build/AVD boot may take several minutes. Use status or stop in another terminal.');
    const deadline = Date.now() + 15 * 60_000;
    let lastPhase;
    while (Date.now() < deadline) {
      state = readJson(stateFile, {});
      if (state.supervisor?.pid === child.pid) {
        if (state.phase !== lastPhase) { console.log(`Phase: ${state.phase}`); lastPhase = state.phase; }
        if (state.phase === 'failed') throw new Error(state.error || 'Startup failed; inspect supervisor.log.');
        if (state.phase === 'ready') { console.log(state.clients.map(c => `DEV ${c.name}: ${c.serial} / ${c.avd}`).join('\n')); return; }
      }
      if (!alive(processRecord)) throw new Error('Supervisor exited. See supervisor.log.');
      await sleep(2000);
    }
    throw new Error('Startup still in progress after 15 minutes; inspect status/build.log. Use stop to cancel.');
  } finally { fs.unlinkSync(lock); }
}
main().catch(error => { console.error(error.message); process.exitCode = 1; });
