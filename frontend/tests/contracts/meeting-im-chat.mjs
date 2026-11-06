import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
import vm from 'node:vm';

const require = createRequire(new URL('../../package.json', import.meta.url));
const { build } = require('esbuild');
const bundle = await build({
  stdin: { contents: `import {ImMeetingChat} from './src/services/live-meeting/chat';
    import {RealLiveMeetingApi} from './src/services/live-meeting/real';
    import {isRoomInvalidation} from './src/services/live-meeting/imEvents';
    Object.assign(globalThis, {ImMeetingChat, RealLiveMeetingApi, isRoomInvalidation});`,
    resolveDir: fileURLToPath(new URL('../../', import.meta.url)), loader: 'ts' },
  bundle: true, write: false, format: 'iife', platform: 'browser',
  plugins: [{ name: 'native-transport', setup(builder) {
    builder.onResolve({ filter: /^@tauri-apps\/api\// }, args => ({ path: args.path, namespace: 'native' }));
    builder.onLoad({ filter: /.*/, namespace: 'native' }, () => ({ contents: `export const invoke=(...args)=>globalThis.invoke(...args); export const listen=async()=>()=>{};` }));
  } }],
});
const commands = [];
const context = vm.createContext({ AbortController, console, setTimeout, clearTimeout,
  invoke: async (...args) => { commands.push(args); return { transport: 'dr-im-group', groupId: '1001' }; } });
vm.runInContext(bundle.outputFiles[0].text, context);
const { ImMeetingChat, RealLiveMeetingApi } = context;
const plain = value => JSON.parse(JSON.stringify(value));

function fixture() {
  const calls = [], reports = [];
  let listener;
  const events = new Map();
  let unread = 7;
  const snapshot = { items: [], hasOlder: true, loading: 'none' };
  const list = { getSnapshot: () => snapshot,
    subscribe: cb => { listener = cb; return () => calls.push(['unsubscribe']); },
    setViewing: value => calls.push(['viewing', value]), markRead: () => calls.push(['read']),
    loadOlder: async () => calls.push(['older']), dispose: () => calls.push(['dispose']) };
  const im = {
    config: { group_read_ack_enabled: true },
    on: (event, cb) => { events.set(event, cb); return () => events.delete(event); },
    conversations: {
      refresh: async id => { calls.push(['refresh', id]); return { conversation_key: 'group-key', conversation_id: '1001', unread_count: unread }; },
      get: async () => ({ unread_count: unread }),
    },
    messages: { open: key => { calls.push(['open', key]); return list; }, send: async (...args) => calls.push(['send', ...args]) },
    files: {
      prepare: async (file, kind) => {calls.push(['prepare',file,kind]);return {blob:file,kind,format:'mp4',duration_seconds:5,width:640,height:360};},
      upload: async (file, options) => { calls.push(['upload', file, options]); options.onProgress(50, 100);
        return { file_id: 'file-1', name: file.name, size: file.size, url: 'https://im.test/media/v1/f/1/secret' }; },
      isFileUrl: url => url.startsWith('https://im.test/media/'),
    },
    desktop: { download: async (...args) => calls.push(['download', ...args]) },
  };
  const chat = new ImMeetingChat(im, 'room-1', '1001', 'alice',
    () => [{ userId: 'alice', name: 'Alice' }, { userId: 'bob', name: 'Bob' }], state => reports.push(plain(state)));
  return { chat, im, list, snapshot, calls, reports, update: () => listener?.(),
    readElsewhere: count => { unread = count; events.get('conversations.changed')?.({upserted:['1001'], removed:[]}); } };
}

{
  const api = new RealLiveMeetingApi();
  assert.deepEqual(plain(await api.getChatSession('room-1')), { transport: 'dr-im-group', groupId: '1001' });
  assert.deepEqual(plain(commands), [['room_chat_session', { roomId: 'room-1' }]]);
  assert.equal(api.sendChat, undefined);
  assert.equal(api.sendChatAttachment, undefined);
  assert.equal(api.downloadAttachment, undefined);
}
{
  const f = fixture();
  await f.chat.connect();
  f.snapshot.items = [
    { message_id: 'm1', sender: 'bob', seq: 1, type: 'text', body: { text: 'hello' }, created_at: '2026-10-23T00:00:00Z' },
    { message_id: 'm2', sender: 'alice', seq: 2, type: 'file', body: { url: 'https://im.test/media/v1/f/1/secret', name: 'report.pdf', size: 99 }, created_at: '2026-10-23T00:00:01Z' },
    { message_id: 'm3', sender: 'bob', type: 'text', recalled: {}, body: { text: 'removed' } },
  ];
  f.update();
  const state = f.reports.at(-1);
  assert.equal(state.messages.length, 3);
  assert.equal(state.messages[0].sender.name, 'Bob');
  assert.equal(state.messages[0].sequence, 1);
  assert.equal(state.messages[1].sender.isSelf, true);
  assert.equal(state.messages[1].attachment.name, 'report.pdf');
  assert.equal(state.hasOlder, true);
  assert.equal(state.unread, 7);
  f.readElsewhere(2);
  await new Promise(resolve => setTimeout(resolve, 0));
  assert.equal(f.reports.at(-1).unread, 2);
  f.chat.setAtBottom(false);
  f.chat.setViewing(true);
  assert.equal(f.calls.some(call => call[0] === 'read'), false);
  f.chat.setAtBottom(true);
  await f.chat.loadOlder();
  f.chat.setViewing(true);
  assert.ok(f.calls.some(call => call[0] === 'older'));
  assert.ok(f.calls.some(call => call[0] === 'read'));
  f.chat.dispose();
  const before = f.reports.length;
  f.update();
  assert.equal(f.reports.length, before);
  assert.ok(f.calls.some(call => call[0] === 'unsubscribe'));
  assert.ok(f.calls.some(call => call[0] === 'dispose'));
}
{
  const f = fixture();
  await f.chat.connect();
  await f.chat.sendText('meeting text');
  const progress = [];
  await f.chat.sendFile({ name: 'report.pdf', size: 123 }, value => progress.push(value));
  const upload = f.calls.find(call => call[0] === 'upload');
  assert.equal(upload[2].purpose, 'group_file');
  assert.equal(upload[2].group_id, '1001');
  assert.deepEqual(progress, [50]);
  const sends = plain(f.calls.filter(call => call[0] === 'send'));
  assert.deepEqual(sends[0], ['send', { to_group: '1001' }, { type: 'text', body: { text: 'meeting text' } }, { waitUntil: 'sent' }]);
  assert.equal(sends[1][2].body.url, 'https://im.test/media/v1/f/1/secret');
  assert.equal(sends[1][2].body.size, 123);
  await f.chat.download({ url: 'https://im.test/media/v1/f/1/secret', name: 'report.pdf', size: 123 });
  assert.equal(f.calls.find(call => call[0] === 'download')[1], 'https://im.test/media/v1/f/1/secret');
  await assert.rejects(f.chat.download({ url: 'https://untrusted.test/file', name: 'bad', size: 1 }));
  f.chat.dispose();
}
{
  const f = fixture();
  let release;
  f.im.conversations.refresh = () => new Promise(resolve => { release = resolve; });
  const pending = f.chat.connect();
  f.chat.dispose();
  release({ conversation_key: 'stale-key' });
  await pending;
  assert.equal(f.calls.some(call => call[0] === 'open'), false);
  await assert.rejects(f.chat.sendText('stale'));
}
{
  const f = fixture();
  let began;
  const started = new Promise(resolve => { began = resolve; });
  f.im.files.upload = (_file, options) => new Promise((_resolve, reject) => {
    options.signal.addEventListener('abort', () => reject(new Error('cancelled')));
    began();
  });
  const pending = f.chat.sendFile({ name: 'cancel.txt', size: 1 }, () => {});
  await started;
  f.chat.cancelUpload();
  await assert.rejects(pending, /cancelled/);
  assert.equal(f.calls.some(call => call[0] === 'send'), false);
  f.chat.dispose();
}
{
  const f = fixture();
  f.im.config.group_read_ack_enabled = false;
  await f.chat.sendText('reply', 42);
  const options = plain(f.calls.find(call => call[0] === 'send')[3]);
  assert.equal(options.need_receipt, undefined);
  assert.deepEqual(options.reply_to, {seq:42});
  const body = {kind:'openmeeting.meeting',version:1,event:'room_state',roomId:'room-1',versionAt:'2026-10-23T00:00:00Z',reason:'host'};
  const message = {type:'custom',sender:'notice',body};
  assert.equal(context.isRoomInvalidation(message,'room-1'), true);
  assert.equal(context.isRoomInvalidation({...message,body:{...body,reason:'recording'}},'room-1'), true);
  assert.equal(context.isRoomInvalidation({...message,sender:'attacker',body:{...body,reason:'recording'}},'room-1'), false);
  assert.equal(context.isRoomInvalidation({...message,sender:'attacker'},'room-1'), false);
  assert.equal(context.isRoomInvalidation(message,'room-2'), false);
  assert.equal(context.isRoomInvalidation({...message,body:{...body,version:2}},'room-1'), false);
}
console.log('Meeting IM chat: transport, history, files, membership lifecycle and cancellation passed.');
{
  const f=fixture();
  await f.chat.sendFile({name:'test.mp4',type:'video/mp4',size:123},()=>{});
  const calls=plain(f.calls);
  assert.equal(calls[0][0],'prepare');assert.equal(calls[0][2],'video');
  const body=calls.find(c=>c[0]==='send')[2].body;
  assert.equal(body.duration_seconds,5);assert.equal(body.format,'mp4');
  assert.equal(body.width,640);assert.equal(body.height,360);
  console.log('PASS group video message retains SDK duration, format and dimensions after group-file upload');
}
