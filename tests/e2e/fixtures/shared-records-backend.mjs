import http from 'node:http';
import { startLayoutBackend } from './desktop-layout-backend.mjs';

export const sharedTitle = '全员共享会议记录：提前离开、录音下载与后台处理的完整流程';
export const sharedId = 'meeting-shared-record';
const initial = () => ({ ended: false, status: 'queued', hasAudio: false, audioError: false, audioDelay: 0, statusDelay: 0, statusError: false, transcriptDelay: 0, emptyTranscripts: false, retryError: false });

/** Explicit acceptance branch; real pages/commands, isolated shared business state. */
export async function startSharedRecordsBackend() {
  const layout = await startLayoutBackend();
  const sessions = new Map(), calls = [];
  let shared = initial(), base;
  const state = name => { if (!sessions.has(name)) sessions.set(name, { role: 'host', attended: false }); return sessions.get(name); };
  const reply = (res, status, data) => { res.writeHead(status, { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Headers': '*' }); res.end(JSON.stringify(data)); };
  const wav = Buffer.alloc(44 + 32000);
  wav.write('RIFF', 0); wav.writeUInt32LE(wav.length - 8, 4); wav.write('WAVEfmt ', 8);
  wav.writeUInt32LE(16, 16); wav.writeUInt16LE(1, 20); wav.writeUInt16LE(1, 22); wav.writeUInt32LE(16000, 24); wav.writeUInt32LE(32000, 28); wav.writeUInt16LE(2, 32); wav.writeUInt16LE(16, 34); wav.write('data', 36); wav.writeUInt32LE(32000, 40);
  for (let i = 0; i < 16000; i++) wav.writeInt16LE(Math.round(Math.sin(i * .1) * 1000), 44 + i * 2);
  async function delegate(input) {
    const response = await fetch(layout.base + '/invoke', { method: 'POST', body: JSON.stringify(input) });
    return { status: response.status, body: await response.json() };
  }
  async function room(input, role) {
    const result = await delegate({ ...input, command: 'room_get' });
    const value = result.body.value;
    value.title = sharedTitle; value.startedAt = new Date().toISOString();
    value.recording = { active: true, epoch: 1, startedAt: value.startedAt, requests: [] };
    value.hostId = role === 'host' ? 'layout-self' : 'member-1';
    value.participants = value.participants.map((p, i) => ({ ...p, isHost: role === 'host' ? i === 0 : i === 1 }));
    return value;
  }
  const server = http.createServer(async (req, res) => {
    if (req.method === 'OPTIONS') return reply(res, 200, {});
    if (req.url === '/audio.wav') { res.writeHead(200, { 'Content-Type': 'audio/wav', 'Access-Control-Allow-Origin': '*', 'Content-Length': wav.length }); res.end(wav); return; }
    try {
      let text = ''; for await (const part of req) text += part;
      const input = text ? JSON.parse(text) : {}, s = state(input.session || 'default');
      if (req.url === '/control') {
        if (input.reset) { shared = initial(); sessions.clear(); calls.length = 0; }
        Object.assign(state(input.session || 'default'), { ...(input.role ? { role: input.role } : {}) });
        if (input.shared) Object.assign(shared, input.shared);
        const response = await fetch(layout.base + '/control', { method: 'POST', body: JSON.stringify(input) });
        return reply(res, response.status, { ...(await response.json()), shared, role: state(input.session || 'default').role });
      }
      if (req.url === '/health') return reply(res, 200, { fixture: 'shared-records', shared });
      const { command, args = {} } = input;
      calls.push({ session: input.session, command, args, at: Date.now() });
      const allowed = s.role === 'host' || (s.role === 'member' && s.attended);
      const recordCommand = ['api_get_meeting', 'api_get_meeting_metadata', 'api_get_meeting_transcripts', 'api_get_summary', 'api_get_meeting_notes', 'api_get_summary_language', 'server_fetch_meeting_audio', 'room_recording_status'].includes(command);
      if (recordCommand && (!allowed || !shared.ended)) return reply(res, 404, { error: { status: 404, detail: '会议不存在或当前账号未参加会议' } });
      let value;
      if (['room_create', 'room_get', 'room_get_code'].includes(command)) value = await room(input, s.role);
      else if (command === 'room_join') { s.attended = true; const joined = await room(input, s.role); value = { room: joined, self: joined.participants[0], state: 'joined', media: { transport: 'dr-rtc', channelId: 'layout', ticket: 'fixture', expiresAt: '2099-01-01T00:00:00Z' } }; }
      else if (command === 'room_leave') value = null;
      else if (command === 'room_end') { shared.ended = true; value = { meetingId: sharedId, jobId: 'job-shared' }; }
      else if (command === 'api_get_meetings') value = shared.ended && allowed ? [{ id: sharedId, title: sharedTitle, can_manage: s.role === 'host' }] : [];
      else if (command === 'api_get_meeting_metadata') value = { id: sharedId, title: sharedTitle, created_at: '2026-10-26T08:00:00Z', updated_at: '2026-10-26T08:00:00Z', folder_path: null, has_audio: shared.hasAudio, audio_duration: shared.hasAudio ? 1 : null, can_manage: s.role === 'host' };
      else if (command === 'room_recording_status') {
        const captured = { ...shared };
        if (captured.statusDelay) await new Promise(resolve => setTimeout(resolve, captured.statusDelay));
        if (captured.statusError) return reply(res, 503, { error: { status: 503, detail: '测试夹具：状态读取失败，请稍后重试。' } });
        value = { status: captured.status, error: captured.status === 'failed' ? captured.hasAudio ? '测试夹具：转写服务不可用，录音已保存。' : '测试夹具：未收到会议音频，无法生成转写和纪要。' : null, message: captured.status === 'queued' ? '正在等待会议音频处理' : null, jobId: 'job-shared' };
      } else if (command === 'room_recording_retry') {
        if (s.role !== 'host') return reply(res, 403, { error: { status: 403, detail: '房主可重试' } });
        if (shared.retryError) return reply(res, 503, { error: { status: 503, detail: '测试夹具：重试服务暂不可用。' } });
        shared.status = 'queued'; value = { jobId: 'job-shared' };
      }
      else if (command === 'server_fetch_meeting_audio') {
        if (shared.audioDelay) await new Promise(resolve => setTimeout(resolve, shared.audioDelay));
        if (shared.audioError) return reply(res, 503, { error: { status: 503, detail: '测试夹具：录音下载失败，请重试。' } });
        value = shared.hasAudio ? base + '/audio.wav' : null;
      } else if (command === 'api_get_summary') value = shared.status === 'completed' ? { status: 'completed', data: { markdown: '# 全员可见的会议纪要\n\n提前离开的成员仍可查看会议记录和下载录音。\n\n' + '会议讨论与后续行动已记录。'.repeat(150) }, error: null } : { status: 'idle', data: null, error: null };
      else if (command === 'api_get_meeting_transcripts') {
        const captured = { ...shared };
        if (captured.transcriptDelay) await new Promise(resolve => setTimeout(resolve, captured.transcriptDelay));
        const result = await delegate(input); value = captured.status === 'completed' && !captured.emptyTranscripts ? result.body.value : { transcripts: [], total_count: 0, has_more: false };
      } else if (command === 'api_get_summary_language') value = { language: null, detected_language: null };
      else { const result = await delegate(input); return reply(res, result.status, result.body); }
      return reply(res, 200, { value });
    } catch (error) { reply(res, 500, { error: { status: 500, detail: String(error) } }); }
  });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve)); base = `http://127.0.0.1:${server.address().port}`;
  return { base, calls, close: async () => { await new Promise(resolve => server.close(resolve)); await layout.close(); } };
}
