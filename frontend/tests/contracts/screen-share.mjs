// Retain only the explicit historical negative baseline. Current contracts use IM RTC.
if(!process.argv.includes('--before-fix')){await import('./im-rtc-screen.mjs');process.exit(process.exitCode||0);}
import assert from 'node:assert/strict';
import { build } from 'esbuild';
import { execFileSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
const before = process.argv.includes('--before-fix');
const filename = 'src/services/live-meeting/media/screenShare.ts';
const source = before ? execFileSync('git', ['show', `4bb4e64:frontend/${filename}`], { encoding: 'utf8' }) : readFileSync(filename, 'utf8');
const result = await build({ stdin: { contents: source, loader: 'ts', resolveDir: process.cwd() }, write: false, format: 'esm', bundle: true, platform: 'node' });
const { ScreenShareClient } = await import('data:text/javascript;base64,' + Buffer.from(result.outputFiles[0].text).toString('base64'));
let states = [], pcs = [], configResolve, signals = [], claims = 0;
class Peer {
  constructor(config) { this.config = config; this.connectionState = 'new'; this.remoteDescription = null; pcs.push(this); }
  addTrack() {} async createOffer() { return { type: 'offer', sdp: 'offer' }; } async createAnswer() { return { type: 'answer', sdp: 'answer' }; }
  async setLocalDescription(value) { this.localDescription = value; } async setRemoteDescription(value) { this.remoteDescription = value; }
  async addIceCandidate() {} close() { this.connectionState = 'closed'; }
}
globalThis.RTCPeerConnection = Peer;
const track = () => ({ id: String(Math.random()), readyState: 'live', stop() { this.readyState = 'ended'; }, addEventListener() {} });
let capture = track(), captureResolve;
Object.defineProperty(globalThis, 'navigator', { configurable: true, value: { mediaDevices: { getDisplayMedia: async () => ({ getTracks: () => [capture], getVideoTracks: () => [capture] }) } } });
const owner = { id: 'owner', name: 'Owner', screenSharing: true, screenShareId: 'share-1' }, viewer = { id: 'viewer', name: 'Viewer', screenSharing: false };
const room = () => ({ id: 'room', participants: [owner, viewer] });
const api = {
  getScreenConfig: () => new Promise(resolve => { configResolve = resolve; }),
  sendScreenSignal: async (_room, targetId, signal) => { signals.push({ targetId, ...signal }); },
  startScreenShare: async () => { claims++; return { sessionId: 'share-1' }; }, getRoom: async () => room(), stopScreenShare: async () => {},
};
const tick = () => new Promise(resolve => setTimeout(resolve, 0));
let pass = 0, fail = 0;
async function test(name, fn) {
  states = []; pcs = []; signals = []; claims = 0;
  const client = new ScreenShareClient(); client.subscribe(s => states.push(s));
  try { await fn(client); console.log(JSON.stringify({ operation: name, expected: '符合共享生命周期约定', actual: '断言通过', pass: true })); pass++; }
  catch (error) { console.log(JSON.stringify({ operation: name, expected: '符合共享生命周期约定', actual: String(error), pass: false })); fail++; }
  finally { await client.close(); }
}
await test('配置未就绪不能提前发送ready或建立无ICE配置的peer', async client => {
  client.bind(api, 'room', 'viewer'); client.sync(room()); await tick(); assert.equal(signals.length, 0);
  configResolve({ iceServers: [{ urls: 'stun:fixture.invalid' }] }); await tick(); assert.equal(signals[0].kind, 'ready');
  await client.signal({ sessionId: 'share-1', senderId: 'owner', kind: 'offer', payload: '{"type":"offer","sdp":"fixture"}' });
  assert.deepEqual(pcs[0].config.iceServers, [{ urls: 'stun:fixture.invalid' }]);
});
await test('ontrack不能提前宣称连接成功；实际connected后才viewing', async client => {
  client.bind(api, 'room', 'viewer'); configResolve({ iceServers: [] }); client.sync(room()); await tick();
  await client.signal({ sessionId: 'share-1', senderId: 'owner', kind: 'offer', payload: '{"type":"offer","sdp":"fixture"}' });
  pcs[0].ontrack({ track: track() }); assert.equal(states.at(-1).status, 'connecting');
  pcs[0].connectionState = 'connected'; pcs[0].onconnectionstatechange(); assert.equal(states.at(-1).status, 'viewing');
  pcs[0].connectionState = 'disconnected'; pcs[0].onconnectionstatechange(); assert.equal(states.at(-1).status, 'connecting');
});
await test('重复ready保留正在协商的发布端连接', async client => {
  capture = track(); client.bind(api, 'room', 'owner'); configResolve({ iceServers: [] }); client.sync(room()); await client.start();
  const ready = { sessionId: 'share-1', senderId: 'viewer', kind: 'ready', payload: '' };
  await client.signal(ready); const first = pcs[0]; await client.signal(ready);
  assert.equal(pcs.length, 1); assert.notEqual(first.connectionState, 'closed'); assert.equal(claims, 1);
});
await test('发布端配置加载失败后可重新点击共享恢复', async client => {
  capture = track(); let attempt = 0;
  const recoveringApi = { ...api, getScreenConfig: async () => { if (++attempt === 1) throw Error('Unavailable'); return { iceServers: [] }; } };
  client.bind(recoveringApi, 'room', 'owner'); client.sync(room()); await client.start();
  assert.equal(states.at(-1).status, 'error'); capture = track(); await client.start();
  assert.equal(states.at(-1).status, 'sharing'); assert.equal(claims, 1);
});
await test('旧peer的晚到失败不能销毁重试后的新连接', async client => {
  client.bind({ ...api, getScreenConfig: async () => ({ iceServers: [] }) }, 'room', 'viewer'); client.sync(room()); await tick();
  const offer = { sessionId: 'share-1', senderId: 'owner', kind: 'offer', payload: '{"type":"offer","sdp":"fixture"}' };
  await client.signal(offer); const old = pcs[0]; let reject;
  old.addIceCandidate = () => new Promise((_resolve, fail) => { reject = fail; });
  const pending = client.signal({ ...offer, kind: 'candidate', payload: '{}' }); await tick();
  await client.retry(); await client.signal(offer); const replacement = pcs.at(-1);
  reject(Error('Old peer closed')); await pending;
  assert.notEqual(replacement, old); assert.notEqual(replacement.connectionState, 'closed'); assert.notEqual(states.at(-1).status, 'error');
});
await test('取消仍在等待的采集不会晚到复活共享', async client => {
  capture = track(); navigator.mediaDevices.getDisplayMedia = () => new Promise(resolve => { captureResolve = resolve; });
  client.bind(api, 'room', 'owner'); configResolve({ iceServers: [] }); client.sync(room());
  const starting = client.start(); await client.stop(); captureResolve({ getTracks: () => [capture], getVideoTracks: () => [capture] }); await starting;
  assert.equal(capture.readyState, 'ended'); assert.equal(claims, 0); assert.equal(states.at(-1).tracks.length, 0);
});
console.log(JSON.stringify({ beforeFix: before, passed: pass, failed: fail }));
if (fail) process.exitCode = 1;
