// Reuse validated local desktop sessions, never print/store bearer credentials.
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
const root = fileURLToPath(new URL('../../', import.meta.url));
const out = path.join(root, '.artifacts/mobile-core-parity');
fs.mkdirSync(out, { recursive: true });
const base = 'http://127.0.0.1:39110', rows = [], accounts = [], rooms = [];
async function call(account, method, url, body) {
  const res = await fetch(base + '/api/v1' + url, { method, headers: { ...(account ? { Authorization: `Bearer ${account.token}` } : {}), ...(body ? { 'content-type': 'application/json' } : {}) }, body: body ? JSON.stringify(body) : undefined, signal: AbortSignal.timeout(12000) });
  const value = await res.text(); let data; try { data = JSON.parse(value); } catch { data = null; }
  return { status: res.status, data };
}
async function step(operation, expected, run) {
  const row = { platform: 'real-backend-api', phase: 'assertions', operation, expected, actual: '', pass: false };
  try { row.actual = await run(); row.pass = true; } catch (error) { row.actual = error.message; throw error; }
  finally { rows.push(row); fs.writeFileSync(path.join(out, 'api-results.json'), JSON.stringify(rows, null, 2)); console.log(JSON.stringify(row)); }
}
const check = (value, message) => { if (!value) throw Error(message); };
try {
  await step('复用本地服务和既有登录态', '不创建账号，找到两个可用的既有测试身份', async () => {
    for (const profile of ['e2ehost20261022', 'e2emember20261022', 'rtchostvalidation', 'rtcmembervalidation', 'dev1', 'dev2']) {
      const p = path.join(process.env.APPDATA, `com.openmeeting.ai.${profile}`, 'server-config.json');
      if (!fs.existsSync(p)) continue;
      const cfg = JSON.parse(fs.readFileSync(p)); if (!cfg.sessionToken) continue;
      const candidate = { token: cfg.sessionToken };
      const response = await call(candidate, 'GET', '/auth/me');
      if (response.status === 200 && !accounts.some(a => a.id === response.data.id)) accounts.push({ ...candidate, id: response.data.id });
      if (accounts.length === 2) break;
    }
    check(accounts.length === 2, '未找到两个有效的已有测试身份'); return '2 个已有身份有效；39110 服务复用';
  });
  const [host, member] = accounts;
  await step('未认证失败路径', '会议列表拒绝未登录请求', async () => { const r = await call(null, 'GET', '/meetings'); check([401,403].includes(r.status), `HTTP ${r.status}`); return `HTTP ${r.status}`; });
  await step('记录与预定读取', '移动端同一 API 能读取记录和预定', async () => {
    const r = await call(host, 'GET', '/meetings'), s = await call(host, 'GET', `/scheduled-meetings?from=${encodeURIComponent(new Date().toISOString())}`);
    check(r.status === 200 && s.status === 200, `HTTP ${r.status}/${s.status}`); return '记录/预定 HTTP 200';
  });
  let room, first, second;
  await step('真实快速会议与两人入会', '主持人和成员入会成功', async () => {
    const r = await call(host, 'POST', '/rooms', { title: `E2E-mobile-core-${Date.now()}` }); check(r.status === 200 || r.status === 201, `create HTTP ${r.status}`);
    room = r.data; rooms.push(room.id);
    for (const [i, account] of accounts.entries()) { const j = await call(account, 'POST', '/rooms/join', { code: room.code, name: i ? 'E2E Member' : 'E2E Host', micOn: false, camOn: false }); check(j.status === 200 && j.data.state !== 'waiting', `join HTTP ${j.status}`); }
    return '独立临时房间，两名成员已入会';
  });
  await step('主持人修改入会设置', '4 位密码和等候室可保存', async () => {
    const r = await call(host, 'PATCH', `/rooms/${room.id}`, { title: 'E2E mobile core settings', pwdEnabled: true, pwd: '2468', waitRoom: true });
    check(r.status === 200 && r.data.pwdEnabled && r.data.waitRoom, `HTTP ${r.status}`); return '4 位密码/等候室已保存';
  });
  await step('成员设置权限', '非主持人不能修改设置', async () => { const r = await call(member, 'PATCH', `/rooms/${room.id}`, { pwdEnabled: false }); check(r.status === 403, `HTTP ${r.status}`); return 'HTTP 403'; });
  await step('真实共享开始', '后端分配共享标识并写入房间状态', async () => {
    const r = await call(host, 'POST', `/rooms/${room.id}/screen-share/start`); first = r.data?.sessionId;
    check(r.status === 200 && /^[a-f0-9-]{36}$/i.test(first), `HTTP ${r.status}`);
    const state = await call(host, 'GET', `/rooms/${room.id}`); check(state.data.participants.some(p => p.screenSharing && p.screenShareId === first), '共享标识未写入'); return '真实共享业务标识与状态一致';
  });
  await step('共享替换与旧会话停止', '成员接管，旧标识停止不能关闭新共享', async () => {
    const r = await call(member, 'POST', `/rooms/${room.id}/screen-share/start`); second = r.data?.sessionId; check(r.status === 200 && second !== first, '接管失败');
    const stop = await call(host, 'POST', `/rooms/${room.id}/screen-share/stop`, { sessionId: first }); check(stop.status === 204, `HTTP ${stop.status}`);
    const state = await call(host, 'GET', `/rooms/${room.id}`); check(state.data.participants.filter(p => p.screenSharing).length === 1 && state.data.participants.some(p => p.screenShareId === second), '旧停止影响了新共享'); return '单一新共享保留，旧停止 HTTP 204';
  });
  await step('共享停止', '真实业务状态归零', async () => { const r = await call(member, 'POST', `/rooms/${room.id}/screen-share/stop`, { sessionId: second }); const state = await call(host, 'GET', `/rooms/${room.id}`); check(r.status === 204 && !state.data.participants.some(p => p.screenSharing), '停止后仍共享'); return 'HTTP 204，共享已清空'; });
  await step('真实专属会中 IM 与 RTC 契约', '返回 IM 群绑定和 dr-rtc 媒体入口', async () => {
    const chat = await call(host, 'POST', `/rooms/${room.id}/chat-session`), media = await call(host, 'POST', `/rooms/${room.id}/media`);
    check(chat.status === 200 && chat.data.transport === 'dr-im-group', `chat HTTP ${chat.status}`);
    check(media.status === 200 && media.data.transport === 'dr-rtc', `media HTTP ${media.status}`);
    return '真实群绑定和 RTC 授权入口存在；未把票据写入产物';
  });
  await step('真实结束会议', '主持人结束，状态结束', async () => {
    const r = await call(host, 'POST', `/rooms/${room.id}/end`); check(r.status === 200, `HTTP ${r.status}`);
    const state = await call(host, 'GET', `/rooms/${room.id}`); check(state.status === 404 && JSON.stringify(state.data).includes('ended'), `结束后读取 HTTP ${state.status}`); return '结束 HTTP 200，结束后读取 HTTP 404/code=ended；不声称无音频会议已转写';
  });
} catch { process.exitCode = 1; }
finally {
  const cleanup = [];
  for (const id of rooms) {
    try {
      const r = await call(accounts[0], 'POST', `/rooms/${id}/end`);
      const meetingId = r.status === 200 ? r.data?.meetingId : null;
      const deleted = meetingId ? await call(accounts[0], 'DELETE', `/meetings/${encodeURIComponent(meetingId)}`) : null;
      cleanup.push({ type: 'temporary-room', ended: r.status === 200, status: r.status, generatedRecordDeleted: deleted != null && [200,204].includes(deleted.status) });
    } catch { cleanup.push({ type: 'temporary-room', ended: false }); }
  }
  fs.writeFileSync(path.join(out, 'api-cleanup.json'), JSON.stringify(cleanup, null, 2));
}
