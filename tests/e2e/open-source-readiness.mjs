// Production Docker images, fresh databases and optional MinIO. Never attaches to a deployment.
import assert from 'node:assert/strict';
import { randomBytes } from 'node:crypto';
import { execFileSync, spawn, spawnSync } from 'node:child_process';
import { createRequire } from 'node:module';
import { closeSync, copyFileSync, existsSync, mkdirSync, openSync, readFileSync, writeFileSync, writeSync } from 'node:fs';
import net from 'node:net';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { initializeServer } from '../../scripts/init-server-env.mjs';
import { initializeUpdater, runTauri } from '../../frontend/scripts/init-updater.mjs';
import { verifyUpdaterSignature } from '../../frontend/scripts/verify-updater.mjs';

const root = fileURLToPath(new URL('../../', import.meta.url));
const out = path.join(root, '.artifacts/open-source-readiness');
mkdirSync(out, { recursive: true });
const project = `openmeeting-readiness-${randomBytes(5).toString('hex')}`;
const storage = process.env.OPENMEETING_TEST_STORAGE || 'local';
assert.ok(['local', 'minio'].includes(storage));
const environment = Object.fromEntries(Object.entries(process.env).filter(([key]) => !/^(OPENMEETING_|COMPOSE_|POSTGRES_|USER_POSTGRES_|MEETING_POSTGRES_|STT_POSTGRES_|INTERNAL_SERVICE_TOKEN$)/i.test(key)));
environment.COMPOSE_PROFILES = storage === 'minio' ? 'minio' : '';
const report = { source: execFileSync('git', ['rev-parse', 'HEAD'], { cwd: root, encoding: 'utf8' }).trim(), project, storage,
  workingTreeDirty: !!execFileSync('git', ['status', '--porcelain'], { cwd: root, encoding: 'utf8' }).trim(),
  scope: 'Real production images and HTTP/browser flows. Optional installer is downloaded and cryptographically verified; no OS installation, real SMS, IM/RTC or model inference is claimed.', checks: [], screenshots: [], cleanup: [] };
const composeFile = path.join(out, `${project}.compose.json`);
const envFile = path.join(out, `${project}.env`);
const log = openSync(path.join(out, `${project}.docker.log`), 'a');
let browser, nativeBrowser, nativeProcess, nativePage, started = false;

function docker(args, { capture = false, allowFailure = false } = {}) {
  const result = spawnSync('docker', args, { cwd: path.join(root, 'server'), env: environment,
    encoding: 'utf8', maxBuffer: 16 * 1024 * 1024, stdio: capture ? 'pipe' : ['ignore', log, log] });
  if (result.error) throw result.error;
  if (capture && result.stderr) writeSync(log, result.stderr);
  if (result.status !== 0 && !allowFailure) throw new Error(`Docker operation failed (${args[0]}). See the local Docker log.`);
  return capture ? result.stdout : result.status;
}
const composeArgs = ['compose', '-p', project, '-f', composeFile];
function check(name, details = true) { report.checks.push({ name, pass: true, details }); console.log(`PASS ${name}`); }
function freePort() {
  return new Promise((resolve, reject) => {
    const server = net.createServer(); server.on('error', reject);
    server.listen(0, '127.0.0.1', () => { const port = server.address().port; server.close(() => resolve(port)); });
  });
}

try {
  // Deterministic failure paths run before creating any containers.
  assert.throws(() => initializeServer({ mode: 'production', output: path.join(out, `${project}.invalid.env`) }), /HTTPS/);
  check('production initialization rejects an insecure object-storage endpoint');
  const port = process.env.OPENMEETING_E2E_PORT ? Number(process.env.OPENMEETING_E2E_PORT) : await freePort(), storagePort = await freePort();
  assert.ok(Number.isInteger(port) && port > 1024 && port < 65536);
  initializeServer({ directory: path.join(root, 'server'), output: envFile, storage, publicEndpoint: `http://127.0.0.1:${storagePort}` });
  const text = readFileSync(envFile, 'utf8');
  const adminPassword = text.match(/^OPENMEETING_ADMIN_PASSWORD=(.+)$/m)[1].trim();
  const config = JSON.parse(docker(['compose', '--env-file', envFile, '-p', project, '-f', 'docker-compose.yml', 'config', '--format', 'json'], { capture: true }));
  config.name = project;
  for (const name of Object.keys(config.services)) if (name.endsWith('-migrate')) delete config.services[name];
  if (storage === 'local') { delete config.services.minio; delete config.services['minio-init']; }
  for (const service of Object.values(config.services)) {
    for (const dependency of Object.keys(service.depends_on || {})) {
      if (!config.services[dependency] && service.depends_on[dependency].required === false) delete service.depends_on[dependency];
    }
  }
  config.services.gateway_ms.ports = [{ target: 39110, published: String(port), host_ip: '127.0.0.1', protocol: 'tcp' }];
  config.services.stt_ms.build.args.STT_EXTRA = 'stt-cloud';
  for (const [name, service] of Object.entries(config.services)) {
    if (service.build) service.image = `${project}-${name}:test`;
  }
  if (storage === 'minio') {
    config.services.minio.ports = [{ target: 9000, published: String(storagePort), host_ip: '127.0.0.1', protocol: 'tcp' }];
    if (process.env.OPENMEETING_TEST_MINIO_IMAGE) {
      config.services.minio.image = process.env.OPENMEETING_TEST_MINIO_IMAGE;
      delete config.services.minio.build;
      report.minioImage = 'Explicit cached image of the unchanged MinIO source build';
    }
  }
  writeFileSync(composeFile, JSON.stringify(config), { mode: 0o600 });
  const deploymentStart = Date.now();
  started = true;
  docker([...composeArgs, 'up', '-d', '--build', '--wait', '--wait-timeout', '180']);
  report.buildAndStartupSeconds = Math.round((Date.now() - deploymentStart) / 1000);
  const base = `http://127.0.0.1:${port}`;
  let cookie = '';
  async function api(route, { method = 'GET', body, admin = false, status = 200 } = {}) {
    const headers = admin && cookie ? { Cookie: cookie } : {};
    if (body && !(body instanceof FormData)) headers['Content-Type'] = 'application/json';
    const response = await fetch(base + route, { method, headers, body: body instanceof FormData ? body : body ? JSON.stringify(body) : undefined, signal: AbortSignal.timeout(20_000), redirect: 'manual' });
    assert.equal(response.status, status, `${method} ${route}`);
    return response;
  }
  assert.equal((await (await api('/healthz')).json()).ok, true);
  check('fresh production images and migrations become healthy');
  await api('/admin/api/releases', { status: 401 });
  await api('/admin/api/login', { method: 'POST', body: { password: 'deliberately-invalid-password' }, status: 401 });
  await api('/api/v1/updates/download/missing-readiness-artifact', { status: 404 });
  check('unauthorized admin, invalid login and missing download fail predictably');
  const loggedIn = await api('/admin/api/login', { method: 'POST', body: { password: adminPassword } });
  cookie = loggedIn.headers.get('set-cookie')?.split(';')[0];
  assert.ok(cookie);
  await api('/admin/api/releases', { admin: true });
  check('admin authentication and authenticated gateway routing');

  const sms = await (await api('/api/v1/auth/sms/send', { method: 'POST', body: { phone: '19900000001', purpose: 'register' } })).json();
  assert.match(sms.dev_code, /^\d+$/);
  const registered = await (await api('/api/v1/auth/register', { method: 'POST', status: 201, body: {
    phone: '19900000001', code: sms.dev_code, name: 'Readiness Fixture', password: 'Readiness-Fixture-Password9!',
    client: { client_id: 'readiness-fixture', os: 'test', app_version: '0.1.1' },
  } })).json();
  assert.ok(registered.user?.id);
  check('development account registration works without real SMS credentials');

  const version = JSON.parse(readFileSync(path.join(root, 'frontend/package.json'), 'utf8')).version;
  const release = await (await api('/admin/api/releases', { method: 'POST', admin: true, status: 201,
    body: { platform: 'windows', version, notes: 'Isolated source-version signing and download verification.' } })).json();
  await api(`/admin/api/releases/${release.id}/publish`, { method: 'POST', admin: true, status: 400 });
  check('release without an artifact cannot be published');

  const artifact = path.join(out, `${project}.exe`);
  if (process.env.OPENMEETING_E2E_INSTALLER) {
    copyFileSync(path.resolve(process.env.OPENMEETING_E2E_INSTALLER), artifact);
    assert.equal(readFileSync(artifact).subarray(0, 2).toString(), 'MZ');
    report.artifactKind = 'Windows installer from the separately recorded native build';
  } else {
    writeFileSync(artifact, 'Explicit download/signature test payload; not an executable installer.\n');
    report.artifactKind = 'Explicit test payload, not an executable installer';
  }
  const signingRoot = path.join(out, `${project}-signing`);
  await initializeUpdater({ frontendDir: signingRoot, environments: ['prod'], serverUrl: 'https://meeting.example.com', log: () => {} });
  const keys = path.join(signingRoot, 'src-tauri/signing/updater/prod');
  const rawPassword = readFileSync(path.join(keys, 'password.env'), 'utf8').trim().split('=').slice(1).join('=');
  const password = rawPassword.startsWith('"') ? JSON.parse(rawPassword) : rawPassword;
  await runTauri(['signer', 'sign', '-f', path.join(keys, 'meeting-prod.key'), '-p', password, artifact]);
  const signature = readFileSync(`${artifact}.sig`, 'utf8'), publicKey = readFileSync(path.join(keys, 'meeting-prod.key.pub'), 'utf8');
  const payload = readFileSync(artifact);
  assert.equal(verifyUpdaterSignature(Buffer.concat([payload, Buffer.from('tampered')]), signature, publicKey), false);
  assert.equal(verifyUpdaterSignature(payload, signature, publicKey), true);
  check('real Tauri signature rejects tampering before publishing');
  const form = new FormData(); form.append('arch', 'x86_64');
  form.append('file', new Blob([payload], { type: 'application/octet-stream' }), 'openmeeting-readiness.exe');
  form.append('signature', new Blob([signature], { type: 'text/plain' }), 'openmeeting-readiness.exe.sig');
  const uploaded = await (await api(`/admin/api/releases/${release.id}/artifacts`, { method: 'POST', body: form, admin: true, status: 201 })).json();
  assert.ok(uploaded.artifacts?.length);
  await api(`/admin/api/releases/${release.id}/publish`, { method: 'POST', admin: true });
  const offer = await (await api('/api/v1/updates/tauri/windows/x86_64/0.0.0')).json();
  assert.equal(offer.version, version);
  assert.equal(offer.signature.trim(), signature.trim());
  const download = await fetch(offer.url, { signal: AbortSignal.timeout(60_000) });
  assert.equal(download.status, 200);
  const downloaded = Buffer.from(await download.arrayBuffer());
  assert.deepEqual(downloaded, payload);
  assert.equal(verifyUpdaterSignature(downloaded, offer.signature, publicKey), true);
  await api(`/api/v1/updates/tauri/windows/x86_64/${version}`, { status: 204 });
  check('publish, update offer, download bytes and signature agree with the source version');

  if (process.env.OPENMEETING_E2E_BROWSER !== '0') {
    const require = createRequire(path.join(root, 'frontend/package.json'));
    const { chromium } = require('playwright');
    browser = await chromium.launch({ headless: true });
    const context = await browser.newContext({ viewport: { width: 1440, height: 960 }, locale: 'zh-CN', acceptDownloads: true });
    assert.equal((await context.request.post(base + '/admin/api/login', { data: { password: adminPassword } })).status(), 200);
    const page = await context.newPage(), errors = [];
    page.on('pageerror', error => errors.push(error.message));
    await page.goto(base + '/admin/releases');
    await page.getByRole('heading', { name: '版本发布', exact: true }).waitFor();
    const [file] = await Promise.all([page.waitForEvent('download'), page.getByRole('link', { name: '下载 openmeeting-readiness.exe', exact: true }).click()]);
    assert.equal(await file.failure(), null);
    assert.deepEqual(readFileSync(await file.path()), payload);
    assert.equal(new URL(page.url()).pathname, '/admin/releases');
    assert.deepEqual(errors, []);
    check('real embedded admin UI downloads the signed artifact without navigating away');
    for (const width of [1440, 390]) {
      await page.setViewportSize({ width, height: 960 });
      if (width < 900) {
        await page.waitForFunction(() => document.querySelector('.el-aside').getBoundingClientRect().width <= 65);
        await page.waitForFunction(() => document.querySelector('.el-menu').getBoundingClientRect().width <= 65);
        await page.waitForFunction(() => [...document.querySelectorAll('.el-menu-item span')].every(element => getComputedStyle(element).visibility === 'hidden'));
        assert.ok(await page.locator('.main').evaluate(element => element.getBoundingClientRect().width >= window.innerWidth - 80));
      }
      const screenshot = path.join(out, `admin-release-${width}.png`);
      await page.screenshot({ path: screenshot, fullPage: true });
      report.screenshots.push(path.basename(screenshot));
    }
  }
  if (process.env.OPENMEETING_E2E_NATIVE_EXE) {
    assert.equal(process.platform, 'win32');
    const debugPort = process.env.OPENMEETING_E2E_CDP_PORT ? Number(process.env.OPENMEETING_E2E_CDP_PORT) : await freePort();
    const require = createRequire(path.join(root, 'frontend/package.json'));
    const { chromium } = require('playwright');
    nativeProcess = spawn(path.resolve(process.env.OPENMEETING_E2E_NATIVE_EXE), [], {
      cwd: root, windowsHide: true, stdio: ['ignore', log, log],
      env: { ...process.env,
        OPENMEETING_E2E_BROWSER_ARGS: `--remote-debugging-port=${debugPort} --remote-allow-origins=*`,
        WEBVIEW2_ADDITIONAL_BROWSER_ARGUMENTS: `--remote-debugging-port=${debugPort} --remote-allow-origins=*` },
    });
    const deadline = Date.now() + 60_000;
    while (Date.now() < deadline && !nativeBrowser) {
      try { nativeBrowser = await chromium.connectOverCDP(`http://127.0.0.1:${debugPort}`); }
      catch (error) {
        report.nativeDebuggerError = error.message.split('\n')[0];
        if (nativeProcess.exitCode !== null) throw new Error(`Native client exited before debugger initialization (${nativeProcess.exitCode})`);
        await new Promise(resolve => setTimeout(resolve, 500));
      }
    }
    assert.ok(nativeBrowser, 'Native WebView2 debugger must become reachable');
    delete report.nativeDebuggerError;
    const context = nativeBrowser.contexts()[0];
    let page;
    while (Date.now() < deadline && !page) {
      page = context.pages().find(item => /^(tauri:|https?:\/\/tauri\.localhost)/.test(item.url()) && !item.url().includes('/im/'));
      if (!page) await new Promise(resolve => setTimeout(resolve, 200));
    }
    assert.ok(page);
    const appIdentifier = await page.evaluate(() => window.__TAURI_INTERNALS__.invoke('plugin:app|identifier'));
    assert.match(appIdentifier, /^org\.example\.openmeeting\.readiness(?:\.|$)/, 'Native E2E requires its own readiness application identifier');
    nativePage = page;
    const welcome = page.getByRole('button', { name: /开始设置|开始使用|Get started/i });
    await welcome.or(page.locator('input[type="tel"]')).first().waitFor({ state: 'visible', timeout: 30_000 });
    if (await welcome.isVisible()) await welcome.click();
    await page.locator('input[type="tel"]').fill('19900000001');
    await page.locator('input[type="password"]').first().fill('Readiness-Fixture-Password9!');
    await page.locator('form button[type="submit"]').click();
    await page.getByRole('button', { name: /加入会议|Join meeting/i }).first().waitFor({ timeout: 30_000 });
    await page.getByText(/Readiness Fixture/, { exact: false }).first().waitFor({ timeout: 20_000 });
    check('real native client completes onboarding and signs in to the isolated production gateway');
    assert.equal(await page.evaluate(() => window.__TAURI_INTERNALS__.invoke('is_analytics_configured')), false);
    check('unconfigured native build disables analytics without an upstream project key');
    const screenshot = path.join(out, 'native-signed-in.png');
    await page.screenshot({ path: screenshot, animations: 'disabled' }); report.screenshots.push(path.basename(screenshot));
  }
  const timings = [];
  for (let i = 0; i < 20; i++) { const begin = performance.now(); await api('/healthz'); timings.push(performance.now() - begin); }
  timings.sort((a, b) => a - b);
  report.healthLatencyMs = { median: Math.round(timings[10]), p95: Math.round(timings[18]), samples: 20, scope: 'Local health endpoint; not a meeting-capacity benchmark' };
  report.dockerResources = JSON.parse(docker(['info', '--format', '{"cpus":{{.NCPU}},"memoryBytes":{{.MemTotal}},"architecture":"{{.Architecture}}"}'], { capture: true }));
} catch (error) {
  if (nativePage) {
    report.nativePage = { url: nativePage.url(), text: await nativePage.locator('body').innerText().then(text => text.slice(0, 1500)).catch(() => '') };
    await nativePage.screenshot({ path: path.join(out, 'native-error.png') }).catch(() => {});
  }
  report.error = error.message;
  process.exitCode = 1;
  console.error(error.message);
} finally {
  await nativeBrowser?.close();
  nativeProcess?.kill();
  await browser?.close();
  if (started && existsSync(composeFile)) {
    assert.ok(project.startsWith('openmeeting-readiness-'));
    assert.equal(JSON.parse(readFileSync(composeFile, 'utf8')).name, project);
    const result = docker([...composeArgs, 'down', '-v', '--remove-orphans'], { allowFailure: true });
    report.cleanup.push({ resource: 'isolated containers, networks and volumes', pass: result === 0 });
    if (result !== 0) process.exitCode = 1;
  }
  closeSync(log);
  report.pass = !report.error && report.checks.length >= 8 && report.cleanup.every(item => item.pass);
  writeFileSync(path.join(out, 'report.json'), JSON.stringify(report, null, 2) + '\n');
  writeFileSync(path.join(out, `${project}.report.json`), JSON.stringify(report, null, 2) + '\n');
}
