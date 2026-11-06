import http from 'node:http';
import { randomUUID, createHmac } from 'node:crypto';
import { startLayoutBackend } from './desktop-layout-backend.mjs';

/** Explicit HTTP/IPC boundary: shared roster, targeted signals, controllable failures. */
export async function startMeetingBackend() {
  const fallback = await startLayoutBackend();
  const states = new Map(), members = new Map(), events = new Map(), calls = [];
  let ended = false;
  const state = id => { if (!states.has(id)) states.set(id, { denySignal: false, configError: false, configDelay: 0, joinDelay: 0, leaveError: false }); return states.get(id); };
  const participant = id => ({ id, userId: id, name: id === 'host' ? '共享测试主持人' : `参会成员 ${id}（用于验证长姓名显示与截断）`, isHost: id === 'host', micOn: false, camOn: false, handRaised: false, screenSharing: false, screenShareId: null, joinedAt: new Date().toISOString() });
  const room = id => ({ id: 'share-room', code: '654321', title: '跨页面会议与多人屏幕共享：长标题、连接恢复和成员协作验收', hostId: 'host', status: ended ? 'ended' : 'active', participants: [...members.values()].map(p => ({ ...p, isSelf: p.id === id })), waiting: [], startedAt: null, pwdEnabled: false, waitRoom: false });
  const emit = (id, type, data) => { if (!events.has(id)) events.set(id, []); events.get(id).push({ type, data, roomId: 'share-room', ts: new Date().toISOString() }); };
  const broadcast = () => { for (const id of members.keys()) emit(id, 'room_state', { room: room(id) }); };
  const respond = (res, status, data) => { res.writeHead(status, { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Headers': '*' }); res.end(JSON.stringify(data)); };
  const fail = (detail, status = 503) => { throw { detail, status }; };
  const server = http.createServer(async (req, res) => {
    if (req.method === 'OPTIONS') return respond(res, 200, {});
    try {
      const url = new URL(req.url, 'http://localhost');
      if(url.pathname==='/local-rtc'){
        const session=url.searchParams.get('session');if(!['host','peer','late'].includes(session))return respond(res,403,{});
        const encode=value=>Buffer.from(JSON.stringify(value)).toString('base64url');
        const payload=encode({iss:'devkey',sub:`rtcchs_${session}`,nbf:Math.floor(Date.now()/1000)-10,exp:Math.floor(Date.now()/1000)+3600,video:{roomJoin:true,room:'openmeeting-screen-fixture',canPublish:true,canSubscribe:true,canPublishData:true}});
        const unsigned=encode({alg:'HS256',typ:'JWT'})+'.'+payload;
        return respond(res,200,{url:'ws://127.0.0.1:7880',token:unsigned+'.'+createHmac('sha256','secret').update(unsigned).digest('base64url')});
      }
      if (url.pathname === '/events') { const id = url.searchParams.get('session'); const batch = events.get(id) || []; events.set(id, []); return respond(res, 200, batch); }
      let raw = ''; for await (const chunk of req) raw += chunk;
      const input = raw ? JSON.parse(raw) : {}, id = input.session || 'host', s = state(id), { command, args = {} } = input;
      if (url.pathname === '/health') return respond(res, 200, { fixture: 'meeting-session' });
      if (url.pathname === '/control') {
        if (input.patch?.reset) { members.clear(); events.clear(); states.clear(); ended = false; }
        // Reset clears the map; apply controls to the replacement state rather
        // than the detached pre-reset object.
        const controlled = state(id);
        Object.assign(controlled, input.patch);
        if(input.patch?.username&&members.has(id)){members.get(id).userId=input.patch.username;broadcast();}
        if (input.patch?.removed) { members.delete(id); emit(id, 'connection_state', { state: 'removed' }); broadcast(); }
        if (input.patch?.ended) { ended = true; for (const who of members.keys()) emit(who, 'room_ended', { meetingId: null }); }
        return respond(res, 200, controlled);
      }
      calls.push({ session: id, command, kind: args.kind, time: Date.now(), ...(['room_join','room_update_self'].includes(command) ? { args } : {}) });
      let value;
      const member = () => { if (!members.has(id)) fail('未加入会议', 403); return members.get(id); };
      switch (command) {
        case 'room_create': case 'room_get': value = room(id); break;
        case 'room_get_code': value = { ...room(id), code: args.code || '654321' }; break;
        case 'room_join':
          if (s.joinDelay) await new Promise(resolve => setTimeout(resolve, s.joinDelay));
          if (s.joinError) fail('夹具：会议不存在', 404);
          if (ended) fail('会议已结束', 410);
          if (!members.has(id)) members.set(id, {...participant(id),userId:s.username||id});
          value = { state: 'joined', room: room(id), self: { ...member(), isSelf: true }, media: { transport: 'dr-rtc', channelId: 'fixture', ticket: 'fixture', expiresAt: '2099-01-01T00:00:00Z' } }; broadcast(); break;
        case 'room_signal_connect': broadcast(); value = null; break;
        case 'room_signal_disconnect': value = null; break;
        case 'room_chat_session':
          if (s.chatError) fail('夹具：聊天初始化失败，请重试');
          value = { transport: 'dr-im-group', groupId: 'meeting-layout-group' }; break;
        case 'room_patch':
          member(); if (id !== 'host') fail('仅主持人可修改会议设置', 403);
          if (s.settingsError) fail('夹具：保存失败，请重试');
          Object.assign(s, { title: args.title }); value = { ...room(id), ...args, id: 'share-room' }; break;
        case 'room_screen_config':
          member(); if (s.configDelay) await new Promise(resolve => setTimeout(resolve, s.configDelay));
          if (s.configError) fail('夹具：ICE 配置加载失败'); value = { iceServers: [] }; break;
        case 'room_screen_start':
          member(); for (const p of members.values()) { p.screenSharing = false; p.screenShareId = null; }
          Object.assign(member(), { screenSharing: true, screenShareId: randomUUID() }); value = { sessionId: member().screenShareId }; broadcast(); break;
        case 'room_screen_stop':
          if (member().screenShareId === args.sessionId) { Object.assign(member(), { screenSharing: false, screenShareId: null }); broadcast(); } value = null; break;
        case 'room_screen_signal': {
          member(); if (s.denySignal) fail('夹具：共享信令失败');
          const owner = [...members.values()].find(p => p.screenShareId === args.sessionId);
          if (!owner) fail('共享会话已结束或已被替换', 409);
          if (![id, args.targetId].includes(owner.id)) fail('无效共享方向', 403);
          if (!members.has(args.targetId)) fail('成员不存在', 404);
          // Deliberately slow answers beyond the old ready interval. Real peer objects must survive.
          if (args.kind === 'answer' && s.answerDelay) await new Promise(resolve => setTimeout(resolve, s.answerDelay));
          emit(args.targetId, 'screen_signal', { senderId: id, sessionId: args.sessionId, kind: args.kind, payload: args.payload }); value = null; break;
        }
        case 'room_update_self': Object.assign(member(), args); broadcast(); value = null; break;
        case 'room_leave': if (s.leaveError) fail('夹具：离会失败，请重试'); members.delete(id); broadcast(); value = null; break;
        case 'room_end':
          if (s.endError) fail('夹具：结束会议失败，请重试');
          ended = true;
          for (const who of members.keys()) emit(who, 'room_ended', { meetingId: s.meetingId ?? null });
          value = { meetingId: s.meetingId ?? null }; break;
        default: {
          await fetch(fallback.base + '/control', { method: 'POST', body: JSON.stringify({ session: id, patch: { loggedIn: true } }) });
          const result = await fetch(fallback.base + '/invoke', { method: 'POST', body: JSON.stringify(input) });
          const data = await result.json();
          if (command === 'auth_get_user' && data.value) Object.assign(data.value, { id, name: participant(id).name });
          if (['server_get_status', 'server_test_connection'].includes(command) && data.value?.user) Object.assign(data.value.user, { id, name: participant(id).name });
          return respond(res, result.status, data);
        }
      }
      respond(res, 200, { value });
    } catch (error) { respond(res, error.status || 500, { error: { detail: error.detail || String(error), status: error.status || 500 } }); }
  });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  return { base: `http://127.0.0.1:${server.address().port}`, calls, close: async () => { await new Promise(resolve => server.close(resolve)); await fallback.close(); } };
}

export function installMeetingBridge({ base, session }) {
  // installLayoutBridge runs first and supplies the project's usual Tauri seams.
  let polling = false;
  const poll = async () => {
    if (polling) return; polling = true;
    try { const events = await fetch(`${base}/events?session=${encodeURIComponent(session)}`).then(r => r.json()); for (const event of events) window.__layoutEmit('room-event', event); } catch {} finally { polling = false; }
  };
  setInterval(poll, 80);
  window.__shareFixture = { session, denied: false, choosing: false, captures: [], release: null, frames:0 };
  // Keep the browser's actual transport, with diagnostics for failed video checks.
  const NativePeer = window.RTCPeerConnection;
  window.__shareFixture.peers = [];
  window.RTCPeerConnection = class extends NativePeer {
    constructor(...args) { super(...args); window.__shareFixture.peers.push(this); }
  };
  Object.defineProperty(navigator.mediaDevices, 'getDisplayMedia', { configurable: true, value: async () => {
    if (window.__shareFixture.denied) throw new DOMException('Fixture capture denied', 'NotAllowedError');
    if (window.__shareFixture.choosing) await new Promise(resolve => { window.__shareFixture.release = resolve; });
    const canvas = document.createElement('canvas'); canvas.width = 960; canvas.height = 540;
    const ctx = canvas.getContext('2d'); let frame = 0;
    const draw = () => { ctx.fillStyle = '#7521a0'; ctx.fillRect(0, 0, 960, 540); ctx.fillStyle = '#22d3ee'; ctx.fillRect((frame * 7) % 840, 280, 120, 100); ctx.fillStyle = '#fff'; ctx.font = '36px sans-serif'; ctx.fillText(`SCREEN ${session} / frame ${++frame}`, 40, 130); };
    draw(); const timer = setInterval(() => { draw(); window.__shareFixture.frames=frame; }, 50), stream = canvas.captureStream(20), track = stream.getVideoTracks()[0], stop = track.stop.bind(track);
    track.stop = () => { clearInterval(timer); stop(); };
    window.__shareFixture.captures.push(track); return stream;
  } });
}
