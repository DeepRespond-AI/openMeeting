import http from 'node:http';
import { startLayoutBackend } from './desktop-layout-backend.mjs';
export const service = 'http://127.0.0.1:3169';
export async function api(path, method = 'GET', body, actor = 'host') {
  const r = await fetch(service + path, { method, headers: { 'Content-Type': 'application/json', 'X-Test-Actor': actor }, body: body === undefined ? undefined : JSON.stringify(body) });
  const text = await r.text(); return { status: r.status, body: text ? JSON.parse(text) : null };
}
export async function startScheduledBackend() {
  const aux = await startLayoutBackend(), calls = [];
  const server = http.createServer(async (req, res) => {
    res.setHeader('Access-Control-Allow-Origin', '*'); res.setHeader('Access-Control-Allow-Headers', '*');
    if (req.method === 'OPTIONS') return res.end();
    try {
      let raw = ''; for await (const p of req) raw += p;
      const input = raw ? JSON.parse(raw) : {}, { command: c, args: a = {}, session = 'host' } = input;
      calls.push({ session, command: c, args: a });
      let route, method = 'GET', body, actor = session.startsWith('member') ? 'member' : 'host';
      const sid = encodeURIComponent(a.id || ''), rid = encodeURIComponent(a.roomId || ''), mid = encodeURIComponent(a.meetingId || '');
      if (c === 'sched_list') route = '/scheduled-meetings' + (a.from ? '?from=' + encodeURIComponent(a.from) + (a.to ? '&to=' + encodeURIComponent(a.to) : '') : '');
      if (c === 'sched_get') route = '/scheduled-meetings/' + sid;
      if (c === 'sched_create' || c === 'sched_update') { route = '/scheduled-meetings' + (c === 'sched_update' ? '/' + sid : ''); method = c === 'sched_create' ? 'POST' : 'PATCH'; body = { ...a }; delete body.id; }
      if (c === 'sched_delete') { route = '/scheduled-meetings/' + sid; method = 'DELETE'; }
      if (c === 'room_get_code') route = '/rooms?code=' + a.code;
      if (c === 'room_create') { route = '/rooms'; method = 'POST'; body = a; }
      if (c === 'room_join') { route = '/rooms/join'; method = 'POST'; body = a; }
      if (c === 'room_get') route = '/rooms/' + rid;
      if (['room_end', 'room_leave', 'room_chat_session', 'room_media_ticket'].includes(c)) { route = '/rooms/' + rid + '/' + ({ room_end: 'end', room_leave: 'leave', room_chat_session: 'chat-session', room_media_ticket: 'media' }[c]); method = 'POST'; }
      if (c === 'room_patch') { route = '/rooms/' + rid; method = 'PATCH'; body = a; }
      if (c === 'api_get_meetings') route = '/meetings';
      if (c === 'api_get_meeting_metadata' || c === 'api_get_meeting') route = '/meetings/' + mid + '/metadata';
      if (c === 'api_get_meeting_transcripts') route = '/meetings/' + mid + '/transcripts';
      if (c === 'room_recording_status') route = '/meetings/' + mid + '/recording';
      if (route) {
        const r = await api('/api/v1' + route, method, body, actor);
        res.setHeader('Content-Type', 'application/json');
        return res.end(JSON.stringify(r.status < 400 ? { value: r.body } : { error: { status: r.status, detail: r.body.detail, code: r.body.code } }));
      }
      const fallback = await fetch(aux.base + '/invoke', { method: 'POST', body: JSON.stringify(input) });
      const data = await fallback.json();
      const user = { id: 'scheduled-' + actor, name: actor, phone: '13800138000', has_password: true };
      if (['auth_login', 'auth_get_user'].includes(c) && data.value) data.value = user;
      if (['server_get_status', 'server_test_connection'].includes(c) && data.value) { if (data.value.user) data.value.user = user; data.value.capabilities.user = user; }
      res.setHeader('Content-Type', 'application/json'); res.end(JSON.stringify(data));
    } catch (e) { res.end(JSON.stringify({ error: { detail: String(e), status: 500 } })); }
  });
  await new Promise(r => server.listen(0, '127.0.0.1', r));
  return { base: 'http://127.0.0.1:' + server.address().port, calls, close: async () => { await new Promise(r => server.close(r)); await aux.close(); } };
}
