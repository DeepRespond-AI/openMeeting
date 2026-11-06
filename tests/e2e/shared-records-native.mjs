import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
import { prepareNativeInput } from './meeting-ready-input.mjs';

const root = fileURLToPath(new URL('../../', import.meta.url));
const out = path.resolve(root, process.env.MEETING_READY_OUTPUT || '.artifacts/shared-records-native-e2e');
const smoke = process.argv.includes('--smoke'), visual = process.argv.includes('--visual'), failurePaths = process.argv.includes('--failure-paths'), offlineVisual = process.argv.includes('--offline-visual'), offline = process.argv.includes('--offline') || offlineVisual;
const mode = smoke ? 'smoke' : visual ? 'visual' : failurePaths ? 'failure-paths' : offlineVisual ? 'offline-visual' : offline ? 'offline' : 'native';
const accounts = JSON.parse(fs.readFileSync(path.join(out, 'accounts.private.json'), 'utf8'));
const write = (name, value) => fs.writeFileSync(path.join(out, name), JSON.stringify(value, null, 2));
const read = name => JSON.parse(fs.readFileSync(path.join(out, name), 'utf8'));
const flags = value => write('faults.json', value);
const rows = [], browsers = [], pages = [], tokens = [];
const shotDirectory = `screenshots/${mode}-${Date.now()}`;
let currentPage, room, meetingId, sequence = 0;
const budget = fs.existsSync(path.join(out, 'budget.json')) ? read('budget.json') : { firstStartedAt: Date.now(), limitMs: 1800000 };
write('budget.json', budget);
const save = () => write(`${mode}.json`, { rows });
if (fs.existsSync(path.join(out, `${mode}.json`))) fs.copyFileSync(path.join(out, `${mode}.json`), path.join(out, `${mode}-${Date.now()}.json`));
const pause = ms => new Promise(resolve => setTimeout(resolve, ms));
async function until(fn, ms = 20000) { const end = Date.now() + ms; while (Date.now() < end) { const result = await fn(); if (result) return result; await pause(200); } throw Error('Expected native state timed out'); }
async function step(operation, expected, fn, optional = false) {
  assert.ok(Date.now() - budget.firstStartedAt < budget.limitMs, 'Cumulative 30 minute E2E budget exhausted');
  const row = { operation, expected, actual: null, pass: false, screenshot: null };
  try { row.actual = await fn(); row.pass = true; }
  catch (e) {
    row.actual = String(e.stack || e);
    if (currentPage) { row.screenshot = `screenshots/failure-${Date.now()}.png`; await currentPage.screenshot({ path: path.join(out, row.screenshot) }).catch(() => {}); }
    if (!optional) throw e;
  } finally { rows.push(row); save(); console.log(JSON.stringify(row)); }
}
async function api(method, route, body, index = 0) {
  const response = await fetch('http://127.0.0.1:3160/api/v1' + route, { method, headers: { 'content-type': 'application/json', ...(tokens[index] ? { authorization: 'Bearer ' + tokens[index] } : {}) }, body: body === undefined ? undefined : JSON.stringify(body), signal: AbortSignal.timeout(20000) });
  const text = await response.text(); return { status: response.status, body: text ? JSON.parse(text) : null };
}
const invoke = (p, command, args = {}) => p.evaluate(({ command, args }) => window.__TAURI_INTERNALS__.invoke(command, args), { command, args });
async function attempt(p, command, args = {}) { try { return { status: 200, body: await invoke(p, command, args) }; } catch (e) { let error = e; if (typeof e === 'string') { try { error = JSON.parse(e); } catch {} } return { status: error.status || 0, error }; } }
function ledger(id) { const name = 'rooms.json'; const ids = fs.existsSync(path.join(out, name)) ? read(name) : []; if (!ids.includes(id)) ids.push(id); write(name, ids); }
function pcm() { const bytes = Buffer.alloc(64000); for (let i = 0; i < bytes.length / 2; i++) bytes.writeInt16LE(Math.round(Math.sin(i / 16000 * 440 * Math.PI * 2) * 5000), i * 2); return bytes.toString('base64'); }
const chunk = (snapshot, participantId) => ({ chunkId: 'explicit-native-pcm-' + Date.now(), participantId, startTime: 0, pcm: pcm(), epoch: snapshot.recording.epoch });
async function logins() { for (const a of accounts) { const response = await api('POST', '/auth/login', { phone: a.phone, password: a.password, client: { client_id: `shared-smoke-${a.id}` } }, 99); assert.equal(response.status, 200); tokens.push(response.body.token); } }
async function clearToasts(p) {
  const close = p.locator('[data-sonner-toast][data-removed="false"] [data-close-button]');
  for (let i = 0; i < 10 && await close.count(); i++) await close.first().click();
  await p.waitForFunction(() => document.querySelectorAll('[data-sonner-toast]').length === 0);
}
async function connect() {
  const require = createRequire(path.join(root, 'frontend/package.json')), { chromium } = require('playwright');
  process.env.MEETING_READY_SYNTHETIC = '1';
  for (let i = 0; i < 3; i++) {
    const b = await chromium.connectOverCDP(`http://127.0.0.1:${9261 + i}`); browsers.push(b);
    await prepareNativeInput(b.contexts()[0]);
    const p = b.contexts()[0].pages().find(p => p.url().startsWith('http://localhost:3162') && !p.url().includes('/im/')); assert.ok(p);
    p.setDefaultTimeout(15000); pages.push(p);
  }
}
async function join(p) {
  currentPage = p;
  await p.getByRole('button', { name: '加入会议 输入会议号入会', exact: true }).click(); const dialog = p.getByRole('dialog');
  for (let i = 0; i < 6; i++) await dialog.locator('input[inputmode="numeric"]').nth(i).fill(room.code[i]);
  for (const toggle of await dialog.getByRole('switch').all()) if (await toggle.getAttribute('aria-checked') === 'true') await toggle.click();
  await dialog.getByRole('button', { name: '加入会议', exact: true }).click();
  await p.getByTestId('room-recording-status').waitFor({ timeout: 45000 });
}
async function shot(p, label, size) {
  const screenshot = `${shotDirectory}/${String(++sequence).padStart(2, '0')}-${size.width}x${size.height}-${label}.png`;
  await p.screenshot({ path: path.join(out, screenshot), animations: 'disabled' });
  const row = { operation: '截图：' + label, expected: '实际查看后记录视觉结论', actual: { viewport: size }, pass: true, visualPass: null, screenshot };
  rows.push(row); save(); console.log(JSON.stringify(row));
}
async function removeOwnedAudio(p) {
  const owned = read('owned-audio.private.json'); assert.equal(owned.meetingId, meetingId);
  assert.equal(path.basename(owned.audio), 'audio.wav'); assert.ok(fs.lstatSync(owned.audio).isFile());
  const bytes = fs.readFileSync(owned.audio); assert.equal(bytes.length, owned.bytes); assert.equal(bytes.toString('ascii', 0, 4), 'RIFF');
  await p.locator('audio').evaluate(el => { el.pause(); el.removeAttribute('src'); el.load(); });
  fs.unlinkSync(owned.audio); // Only the single WAV created by this run, never a shared directory.
}
async function nativeDownloadFault(p, size) {
  currentPage = p; await clearToasts(p); await removeOwnedAudio(p); flags({ audioDownload: true });
  try {
    await p.getByTestId('download-meeting-audio').click(); await p.getByRole('alert').filter({ hasText: 'Deterministic recording download outage' }).waitFor();
    if (size) await shot(p, '原生下载503错误', size);
  } finally { flags({}); }
  flags({ audioDelay: 2 });
  try {
    await p.getByTestId('download-meeting-audio').click(); await p.getByTestId('download-meeting-audio').filter({ hasText: '正在下载' }).waitFor(); assert.ok(await p.getByTestId('download-meeting-audio').isDisabled());
    if (size) await shot(p, '原生下载等待', size);
    await p.getByText('录音已保存到录音目录', { exact: true }).waitFor();
    assert.equal(await p.getByRole('alert').filter({ hasText: 'Deterministic recording download outage' }).count(), 0);
    const owned = read('owned-audio.private.json'); assert.ok(fs.existsSync(owned.audio)); assert.equal(fs.readFileSync(owned.audio).toString('ascii', 0, 4), 'RIFF');
    if (size) await shot(p, '原生下载恢复与保存位置', size);
  } finally { flags({}); }
  await clearToasts(p);
  await p.goto(`http://localhost:3162/meeting-details?id=${meetingId}`, { waitUntil: 'domcontentloaded' });
  await p.getByRole('tab', { name: '会议信息', exact: true }).click(); await p.getByTestId('download-meeting-audio').waitFor();
}
async function imLifecycle(p, action) {
  return p.evaluate(async action => {
    const el = [...document.querySelectorAll('*')].find(e => Object.keys(e).some(k => k.startsWith('__reactFiber')));
    let fiber = el?.[Object.keys(el).find(k => k.startsWith('__reactFiber'))]; while (fiber?.return) fiber = fiber.return;
    const todo = [fiber], seen = new Set();
    while (todo.length) {
      const n = todo.pop(); if (!n || seen.has(n)) continue; seen.add(n);
      const v = n.memoizedProps?.value;
      if (v?.relogin && v.client?.auth) {
        if (action === 'logout') await v.client.auth.logout(); else if (action === 'relogin') v.relogin(); return true;
      }
      todo.push(n.child, n.sibling);
    } return false;
  }, action);
}
fs.mkdirSync(path.join(out, 'screenshots'), { recursive: true });
try {
  if (smoke) {
    await step('真实鉴权与自动录音默认值', '三账号真实登录，房间自动active/epoch1', async () => {
      await logins(); const r = await api('POST', '/rooms', {}); assert.equal(r.status, 201); room = r.body; ledger(room.id);
      assert.equal(room.recording.active, true); assert.equal(room.recording.epoch, 1);
      assert.equal((await api('POST', '/rooms/join', { code: room.code, micOn: false, camOn: false }, 1)).status, 200);
      return { authenticated: 3, active: true, epoch: 1 };
    });
    await step('先独立冒烟原生下载故障入口', '真实PCM上传/结束后，夹具503与恢复200稳定', async () => {
      assert.equal((await api('POST', `/rooms/${room.id}/recording/chunks`, chunk(room, room.hostId))).status, 201);
      assert.equal((await api('POST', `/rooms/${room.id}/leave`, {}, 1)).status, 204);
      const ended = await api('POST', `/rooms/${room.id}/end`, {}); assert.equal(ended.status, 200); meetingId = ended.body.meetingId;
      await until(async () => (await api('GET', `/meetings/${meetingId}/metadata`, undefined, 1)).body?.has_audio, 45000);
      flags({ audioDownload: true });
      try { assert.equal((await api('GET', `/meetings/${meetingId}/audio`, undefined, 1)).status, 503); } finally { flags({}); }
      const r = await fetch(`http://127.0.0.1:3160/api/v1/meetings/${meetingId}/audio`, { headers: { authorization: 'Bearer ' + tokens[1] } });
      assert.equal(r.status, 200); assert.equal(Buffer.from(await r.arrayBuffer()).toString('ascii', 0, 4), 'RIFF');
      assert.equal((await api('GET', `/meetings/${meetingId}/metadata`, undefined, 2)).status, 404);
      return { pcmSaved: true, earlyLeaverDownload: 200, failure: 503, outsider: 404 };
    });
  } else {
    assert.ok(read('smoke.json').rows.every(r => r.pass)); await connect(); const [host, member, outside] = pages;
    if (offline) {
      assert.ok(read('native.json').rows.every(r => r.pass)); currentPage = member;
      if (offlineVisual) assert.ok(read('offline.json').rows.every(r => r.pass));
      const title = `离线会后通知验收-${Date.now()}`;
      await step('IM离线前创建实际参会关系', '真实原生命令入会并提前离开，业务登录保持有效', async () => {
        await member.goto('http://localhost:3162/', { waitUntil: 'domcontentloaded' }); await member.getByRole('button', { name: '快速会议 立即发起一场会议', exact: true }).waitFor();
        room = await invoke(host, 'room_create', { title }); ledger(room.id);
        await invoke(member, 'room_join', { code: room.code, micOn: false, camOn: false }); await invoke(member, 'room_leave', { roomId: room.id });
        await until(() => imLifecycle(member, 'ready'));
        assert.ok(await imLifecycle(member, 'logout')); await clearToasts(member); return { memberLeft: true, IM: 'SDK auth.logout (real connection)', businessLoggedIn: (await invoke(member, 'server_get_config')).loggedIn };
      });
      await step('IM离线期间结束并积压通知', 'IM离线时不展示实时通知，后端建立共享记录', async () => {
        const ended = await invoke(host, 'room_end', { roomId: room.id }); meetingId = ended.meetingId; write('offline-state.json', { room, meetingId, title });
        await pause(17000); assert.equal(await member.locator('[data-sonner-toast]').filter({ hasText: title }).count(), 0); return { meetingId, noRealtimeToast: true };
      });
      await step('IM恢复后收到离线会后入口', '复用真实SDK重新登录，通知入口指向正确记录', async () => {
        assert.ok(await imLifecycle(member, 'relogin'));
        const notice = member.locator('[data-sonner-toast]').filter({ hasText: title }); await notice.getByRole('button', { name: '查看会议记录', exact: true }).first().waitFor({ timeout: 25000 });
        if (offlineVisual) for (const size of [{width:1280,height:800},{width:520,height:760}]) { await member.setViewportSize(size); await shot(member, 'IM离线恢复补显通知', size); }
        await notice.getByRole('button', { name: '查看会议记录', exact: true }).first().click(); await member.waitForURL(url => url.pathname === '/meeting-details' && url.searchParams.get('id') === meetingId);
        return { offlineDelivery: true, injected: false, meetingId };
      }, true);
      await step('IM离线成员仍可通过列表访问记录', '真实会后列表与元数据保留早退成员访问', async () => {
        assert.ok((await invoke(member, 'api_get_meetings')).some(m => m.id === meetingId)); assert.equal((await invoke(member, 'api_get_meeting_metadata', { meetingId })).can_manage, false); return { recordAccess: true };
      });
    } else if (!visual && !failurePaths) {
      await step('新编译Windows三端登录', '复用专用登录态或登录隔离账号，真实Rust/业务接口', async () => {
        for (let i = 0; i < 3; i++) {
          const p = pages[i]; currentPage = p; await invoke(p, 'complete_onboarding', { model: '' });
          const previous = await invoke(p, 'auth_get_user'); if (previous && previous.id !== accounts[i].id) { assert.ok(previous.id.startsWith('im-ready-')); await invoke(p, 'auth_logout'); }
          if (i === 0 && previous?.id === accounts[0].id && fs.existsSync(path.join(out, 'state.json'))) {
            const old = read('state.json'); if (old.room) await attempt(p, 'room_end', { roomId: old.room.id });
          }
          await p.goto('http://localhost:3162/', { waitUntil: 'domcontentloaded' });
          await p.evaluate(() => { localStorage.setItem('dr.locale', 'zh-CN'); localStorage.setItem('openmeeting:meeting-audio', JSON.stringify({ autoJoin: true, microphoneId: 'default', speakerId: 'default', unmuteSound: false })); });
          await p.reload({ waitUntil: 'domcontentloaded' });
          if (!(await invoke(p, 'server_get_config')).loggedIn) { await p.locator('#phone-auth-phone').fill(accounts[i].phone); await p.locator('#phone-auth-password').fill(accounts[i].password); await p.locator('form button[type=submit]').click(); }
          await p.getByRole('button', { name: '快速会议 立即发起一场会议', exact: true }).waitFor({ timeout: 45000 }); assert.equal((await invoke(p, 'auth_get_user')).id, accounts[i].id);
        } return { nativeClients: 3, identities: 'isolated', backend: 'real' };
      });
      currentPage = host;
      await step('快速会议自动启用录音', '无手动按钮，真实后端active且成员收到状态', async () => {
        await host.getByRole('button', { name: '快速会议 立即发起一场会议', exact: true }).click();
        await until(() => new URL(host.url()).searchParams.get('code'), 45000);
        room = await invoke(host, 'room_get_code', { code: new URL(host.url()).searchParams.get('code') }); ledger(room.id); write('state.json', { room });
        await host.getByTestId('room-recording-status').waitFor(); assert.equal(room.recording.active, true);
        assert.equal(await host.getByTestId('recording-control').count(), 0); await join(member);
        assert.equal((await invoke(member, 'room_get', { roomId: room.id })).recording.active, true);
        return { active: true, members: 2, manualButton: false };
      });
      await step('RTC真实自动采集验收', '真实RTC可用并自动保存音频分片；不可用如实失败', async () => {
        const ticket = await attempt(host, 'room_media_ticket', { roomId: room.id });
        write('rtc-diagnostic.json', { status: ticket.status, transport: ticket.body?.transport, error: ticket.error }); assert.equal(ticket.status, 200, 'RTC ticket request failed');
        assert.equal(ticket.body.transport, 'dr-rtc');
        await until(async () => (await (await fetch(`http://127.0.0.1:3167/__e2e/recording/${room.id}`)).json()).chunks > 0, 20000);
        return { actualRtcChunks: true };
      }, true);
      currentPage = member;
      await step('成员提前离开保留历史身份', '离开后房间仍在进行，成员返回首页', async () => {
        await member.getByRole('button', { name: '离开会议', exact: true }).click(); await member.waitForURL(url => url.pathname === '/');
        assert.equal((await invoke(host, 'room_get', { roomId: room.id })).status, 'active'); return { earlyLeave: true };
      });
      currentPage = host;
      await step('核验音频分片持久化或明确降级', 'RTC通过则只用自动采集，阻断时标明显式PCM降级', async () => {
        if (rows.find(r => r.operation === 'RTC真实自动采集验收')?.pass) {
          const saved = await (await fetch(`http://127.0.0.1:3167/__e2e/recording/${room.id}`)).json(); assert.ok(saved.chunks > 0); return { input: 'synthetic microphone through real RTC + automatic recorder', savedChunks: saved.chunks, injectedChunks: false };
        }
        const snapshot = await invoke(host, 'room_get', { roomId: room.id }); await invoke(host, 'room_recording_chunk', { roomId: room.id, chunk: chunk(snapshot, snapshot.hostId) }); return { input: 'explicit synthetic PCM fallback', transport: 'real Tauri IPC + API' };
      });
      await step('房主UI结束并建立会后记录', '结束弹窗说明成员可见，记录保留音频', async () => {
        await host.getByRole('button', { name: '离开并结束', exact: true }).click(); const dialog = host.getByRole('dialog'); await dialog.getByText(/含提前离开的成员/).waitFor(); await dialog.getByRole('button', { name: '结束会议', exact: true }).click();
        await host.waitForURL(url => url.pathname === '/meeting-details', { timeout: 45000 }); meetingId = new URL(host.url()).searchParams.get('id');
        await until(async () => (await invoke(host, 'api_get_meeting_metadata', { meetingId })).has_audio, 45000);
        write('state.json', { room, meetingId }); return { meetingId, hasAudio: true };
      });
      currentPage = member;
      await step('真实IM会后通知送达早退成员', '不注入IM消息，真实通知出现记录入口', async () => {
        await member.getByRole('button', { name: '查看会议记录', exact: true }).first().waitFor({ timeout: 35000 });
        await member.getByRole('button', { name: '查看会议记录', exact: true }).first().click(); await member.waitForURL(url => url.pathname === '/meeting-details'); return { delivered: true, injected: false };
      }, true);
      await step('成员重新进入可读取共享记录', '列表含记录且can_manage=false，实际成员详情只读', async () => {
        const list = await invoke(member, 'api_get_meetings'); const item = list.find(m => m.id === meetingId); assert.ok(item); assert.equal(item.can_manage, false);
        const meta = await invoke(member, 'api_get_meeting_metadata', { meetingId }); assert.equal(meta.can_manage, false);
        await member.goto(`http://localhost:3162/meeting-details?id=${meetingId}`, { waitUntil: 'domcontentloaded' }); await member.getByRole('tab', { name: '会议信息', exact: true }).click(); await member.getByTestId('download-meeting-audio').waitFor();
        assert.equal(await member.getByRole('button', { name: '删除会议', exact: true }).count(), 0); return { listed: true, canManage: meta.can_manage, hasAudio: meta.has_audio };
      });
      await step('真实原生录音下载与播放', '下载为磁盘WAV并真实解码播放，文件内容可核验', async () => {
        await clearToasts(member); await member.getByTestId('download-meeting-audio').click(); await member.getByText('录音已保存到录音目录', { exact: true }).waitFor();
        const audio = await invoke(member, 'server_fetch_meeting_audio', { meetingId }); assert.ok(fs.existsSync(audio)); const bytes = fs.readFileSync(audio); assert.equal(bytes.toString('ascii', 0, 4), 'RIFF');
        write('owned-audio.private.json', { meetingId, audio, bytes: bytes.length });
        await member.getByRole('button', { name: '播放', exact: true }).click(); await member.waitForFunction(() => document.querySelector('audio')?.currentTime > .1); await member.locator('audio').evaluate(el => el.pause());
        return { diskFile: true, bytes: bytes.length, header: 'RIFF', playback: true };
      });
      currentPage = outside;
      await step('第三端非参会者拒绝读取下载', '真实原生命令均404，页面没有内容和下载入口', async () => {
        const meta = await attempt(outside, 'api_get_meeting_metadata', { meetingId }); assert.notEqual(meta.status, 200, JSON.stringify(meta));
        const audio = await attempt(outside, 'server_fetch_meeting_audio', { meetingId }); assert.notEqual(audio.status, 200, JSON.stringify(audio));
        const a = accounts[2], auth = await api('POST', '/auth/login', { phone: a.phone, password: a.password, client: { client_id: 'outsider-native-check' } }, 99); assert.equal(auth.status, 200); tokens[2] = auth.body.token;
        assert.equal((await api('GET', `/meetings/${meetingId}/metadata`, undefined, 2)).status, 404);
        assert.equal((await api('GET', `/meetings/${meetingId}/audio`, undefined, 2)).status, 404);
        await outside.goto(`http://localhost:3162/meeting-details?id=${meetingId}`, { waitUntil: 'domcontentloaded' }); await outside.getByRole('heading', { name: '无法打开该会议', exact: true }).waitFor(); assert.equal(await outside.getByTestId('download-meeting-audio').count(), 0); return { nativeCommands: 'rejected (legacy string errors)', API: 404 };
      });
      write('functional-state.json', { room, meetingId });
    } else if (failurePaths) {
      assert.ok(read('native.json').rows.every(r => r.pass)); ({ room, meetingId } = read('functional-state.json'));
      currentPage = member;
      await step('原生下载503、等待和恢复', '只移除本轮测试WAV，真实Rust下载失败可见且恢复后无旧错误', async () => {
        await member.getByRole('tab', { name: '会议信息', exact: true }).click(); await nativeDownloadFault(member);
        await member.getByRole('button', { name: '播放', exact: true }).click(); await member.waitForFunction(() => document.querySelector('audio')?.currentTime > .1); await member.locator('audio').evaluate(el => el.pause());
        return { failure: 503, loadingDisabled: true, restoredFile: true, playbackAfterRecovery: true };
      });
    } else {
      const functional = read('native.json').rows;
      assert.ok(functional.filter(r => !r.operation.includes('RTC真实') && !r.operation.includes('真实IM')).every(r => r.pass));
      assert.ok(read('failure-paths.json').rows.every(r => r.pass));
      ({ room, meetingId } = read('functional-state.json'));
      await host.goto('http://localhost:3162/', { waitUntil: 'domcontentloaded' });
      await host.getByRole('button', { name: '快速会议 立即发起一场会议', exact: true }).click();
      await host.getByTestId('room-recording-status').waitFor({ timeout: 45000 });
      const visualRoom = await invoke(host, 'room_get_code', { code: new URL(host.url()).searchParams.get('code') }); ledger(visualRoom.id);
      write('visual-room.json', { id: visualRoom.id });
      for (const size of [{ width: 1280, height: 800 }, { width: 520, height: 760 }]) {
        for (const p of pages) await p.setViewportSize(size);
        await clearToasts(host); await shot(host, '房主真实自动录音', size);
        await host.getByRole('button', { name: '离开并结束', exact: true }).click(); await host.getByRole('dialog').waitFor(); await shot(host, '结束弹窗打开', size); await host.keyboard.press('Escape'); await until(() => host.getByRole('dialog').count().then(n => n === 0));
        await clearToasts(member); await member.getByRole('tab', { name: '会议信息', exact: true }).click();
        await shot(member, '成员真实录音与处理状态', size);
        await nativeDownloadFault(member, size);
        await member.getByRole('tab', { name: '转写', exact: true }).click(); await shot(member, '转写空态', size);
        await member.getByRole('tab', { name: 'AI 总结', exact: true }).click(); await shot(member, '成员纪要只读等待', size);
        await shot(outside, '非参会账号拒绝', size);
      }
      await host.getByRole('button', { name: '离开并结束', exact: true }).click(); await host.getByRole('dialog').getByRole('button', { name: '结束会议', exact: true }).click();
      await host.waitForURL(url => url.pathname === '/meeting-details', { timeout: 45000 });
    }
  }
} catch (e) { console.error(e); process.exitCode = 1; if (!rows.some(r => !r.pass)) rows.push({ operation: 'setup failure', expected: 'complete phase', actual: String(e.stack || e), pass: false, screenshot: null }); }
finally {
  flags({}); budget.usedMs = Date.now() - budget.firstStartedAt; write('budget.json', budget); save();
  for (const b of browsers) await b.close();
}
