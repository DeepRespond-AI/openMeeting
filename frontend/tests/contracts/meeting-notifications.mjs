import assert from 'node:assert/strict';
import {createRequire} from 'node:module';
import {fileURLToPath} from 'node:url';
import vm from 'node:vm';

const require = createRequire(new URL('../../package.json', import.meta.url));
const {build} = require('esbuild');
const bundle = await build({
  stdin: {contents: `export {createMeetingNotifications} from './src/im/meeting-notifications';
    import './src/im/engine-entry';`, resolveDir: fileURLToPath(new URL('../../', import.meta.url)), loader: 'ts'},
  bundle: true, write: false, format: 'cjs', platform: 'node',
  plugins: [{name: 'engine-boundaries', setup(b) {
    b.onResolve({filter: /^(@tauri-apps\/api\/|@deeprespond\/im-tauri\/engine)/}, a => ({path: a.path, namespace: 'fixture'}));
    b.onLoad({filter: /.*/, namespace: 'fixture'}, ({path}) => ({contents: path.includes('/core')
      ? `export const invoke=async()=>({appKey:'test#app',apiUrl:'https://example.invalid',ticket:'fixture'});`
      : path.includes('/event') ? `export const listen=async()=>()=>{};`
      : `export function createDRTauriEngine(options){globalThis.engineOptions=options;return {client:globalThis.engineClient};}`}));
  }}],
});

function fixture() {
  const handlers = new Map(), badges = [], reads = [], warnings = [];
  let items = [], listeners = new Set(), disposals = 0;
  const views = new Map();
  const client = {
    auth: {state: {kind: 'signed_in'}, currentUser: {username: 'self'}},
    on(name, listener) {
      if (!handlers.has(name)) handlers.set(name, new Set());
      handlers.get(name).add(listener); return () => handlers.get(name).delete(listener);
    },
    groups: {list: () => ({getSnapshot: () => ({items}),
      subscribe(fn) {listeners.add(fn); return () => listeners.delete(fn);},
      dispose() {disposals++;},
    })},
    conversations: {get: async id => {reads.push(id); return views.get(id);}},
    desktop: {setBadge: async count => {badges.push(count);}},
  };
  return {client, badges, views, reads, warnings, get disposals() {return disposals;},
    emit(name) {for (const fn of [...(handlers.get(name) ?? [])]) fn();},
    groups(next) {items = next; for (const fn of [...listeners]) fn();},
    remainingListeners() {return [...handlers.values()].reduce((sum, set) => sum + set.size, listeners.size);},
  };
}
const f = fixture();
const context = vm.createContext({module: {exports: {}}, exports: {}, engineClient: f.client,
  document: {}, console: {warn: (...args) => f.warnings.push(args)}});
context.exports = context.module.exports;
vm.runInContext(bundle.outputFiles[0].text, context);
const flush = async () => {for (let i = 0; i < 20; i++) await Promise.resolve();};
await flush();
const options = context.engineOptions;
assert.equal(options.badge, 'manual');
assert.equal(options.notifications.notices, false);
assert.equal(options.notifications.calls, 'manual');
assert.deepEqual(f.badges, [null], 'old global badge is cleared on bootstrap');

const group = (id = 'meeting', patch = {}) => ({group_id: id, in_my_groups: true,
  group: {group_id: id, type: 'private', status: 'active', owner: 'openmeeting-meetings',
    attributes: {openmeeting_room_id: 'room-contract'}}, ...patch});
const conversation = (count, patch = {}) => ({conversation_type: 'group', unread_count: count,
  state: {membership: 'member', hidden: false}, muted: null, ...patch});
const message = (patch = {}) => ({conversation_id: 'meeting', conversation_type: 'group', sender: 'alice',
  sender_type: 'user', type: 'text', body: {text: 'hello'}, ...patch});
const alert = (patch = {}) => ({kind: 'message', message: message(patch), notify: {notify: true, title: 'Alice', body: 'hello'}});
const format = value => options.notifications.format(value);
const plain = value => JSON.parse(JSON.stringify(value));

f.groups([group()]);
f.views.set('meeting', conversation(2));
f.emit('conversations.changed'); await flush();
for (const type of ['text', 'image', 'video', 'voice', 'file', 'location']) {
  assert.deepEqual(plain(format(alert({type}))), {title: 'Alice', body: 'hello'}, type);
}
assert.equal(f.badges.at(-1), 2, 'meeting chat retains its taskbar unread');
for (const patch of [
  {conversation_type: 'single'}, {conversation_id: 'ordinary-group'}, {sender: 'notice'},
  {sender: 'openmeeting-meetings'}, {sender: 'self'}, {sender_type: 'system'}, {sender: null},
  {type: 'tip'}, {type: 'custom', body: {kind: 'openmeeting.meeting', event: 'room_state'}},
  {type: 'call'}, {exclude_from_unread: true}, {recalled: {}}, {erased: true},
]) assert.equal(format(alert(patch)), null, JSON.stringify(patch));
assert.equal(format({...alert(), notify: {notify: false, reason: 'muted'}}), null);
assert.equal(format({kind: 'notice', type: 'friend_request'}), null);

// Historical notice/private/group unread must never use the SDK global total.
f.views.set('private', conversation(100, {conversation_type: 'single'}));
f.views.set('ordinary-group', conversation(50));
f.groups([group(), group('ordinary-group', {group: {status: 'active', owner: 'alice'}})]);
f.emit('conversations.unreadChanged'); await flush();
assert.equal(f.badges.at(-1), 2);
assert.ok(!f.reads.includes('private') && !f.reads.includes('ordinary-group'));

for (const patch of [{in_my_groups: false}, {group: {...group().group, status: 'dismissed'}},
  {group: {...group().group, owner: 'alice'}}, {group: {...group().group, attributes: {openmeeting_room_id: 'forged'}}}]) {
  f.groups([group('meeting', patch)]); await flush();
  assert.equal(format(alert()), null); assert.equal(f.badges.at(-1), null);
}
f.groups([group()]); await flush();
for (const patch of [{muted: {mode: 'none'}}, {state: {membership: 'dismissed'}},
  {state: {membership: 'removed'}}, {state: {membership: 'left'}}, {state: {membership: 'member', hidden: true}}]) {
  f.views.set('meeting', conversation(2, patch)); f.emit('conversations.changed'); await flush();
  assert.equal(f.badges.at(-1), null);
}
f.views.set('meeting', conversation(0)); f.emit('conversations.changed'); await flush();
assert.equal(f.badges.at(-1), null, 'reading chat clears the badge');
f.views.set('meeting', conversation(3)); f.emit('conversations.changed'); await flush();
assert.equal(f.badges.at(-1), 3);
f.groups([]); await flush(); assert.equal(f.badges.at(-1), null, 'ended meeting no longer contributes');

// A late read of the previous account must not restore its badge after logout.
f.groups([group()]); await flush();
let release;
f.client.conversations.get = () => new Promise(resolve => {release = resolve;});
f.emit('conversations.changed');
f.client.auth.state = {kind: 'signed_out'}; f.client.auth.currentUser = null;
f.emit('auth.stateChanged');
assert.equal(format(alert()), null);
release(conversation(99)); await flush();
assert.equal(f.badges.at(-1), null); assert.ok(!f.badges.includes(99));

const other = fixture();
const policy = context.module.exports.createMeetingNotifications(other.client);
await flush(); policy.dispose(); await flush();
assert.equal(other.remainingListeners(), 0);
assert.equal(other.disposals, 1);

// Serialize native writes too: a delayed old write cannot beat the logout clear.
const slow = fixture();
const slowPolicy = context.module.exports.createMeetingNotifications(slow.client);
await flush();
slow.views.set('meeting', conversation(4));
let releaseNative;
slow.client.desktop.setBadge = count => new Promise(resolve => {
  releaseNative = () => {slow.badges.push(count); resolve();};
});
slow.groups([group()]); await flush();
slow.client.auth.state = {kind: 'signed_out'}; slow.client.auth.currentUser = null;
slow.emit('auth.stateChanged');
slow.client.desktop.setBadge = async count => {slow.badges.push(count);};
releaseNative(); await flush();
assert.deepEqual(slow.badges, [null, 4, null]);
slowPolicy.dispose(); await flush();

// Starting signed out and subsequent login hydrate policy without remounts.
const hydration = fixture();
hydration.client.auth.state = {kind: 'signed_out'};
const hydrationPolicy = context.module.exports.createMeetingNotifications(hydration.client);
await flush();
hydration.groups([group()]); hydration.views.set('meeting', conversation(5));
hydration.client.auth.state = {kind: 'signed_in'}; hydration.emit('auth.stateChanged'); await flush();
assert.equal(hydration.badges.at(-1), 5);
assert.ok(hydrationPolicy.format(alert()));
hydrationPolicy.dispose(); await flush();
assert.equal(hydration.badges.at(-1), null);
assert.deepEqual(f.warnings, []);
console.log('PASS: engine wiring, meeting-only alerts/badges, silent legacy unread, reading/end/logout and disposal');
