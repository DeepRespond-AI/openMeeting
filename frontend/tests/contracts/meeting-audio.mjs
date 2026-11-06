import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
import vm from 'node:vm';

const require = createRequire(new URL('../../package.json', import.meta.url));
const { build } = require('esbuild');
const bundle = await build({
  stdin: { contents: `import * as devices from './src/services/live-meeting/media/audioDevices';
    import {ImChannelMediaClient} from './src/services/live-meeting/media/imChannel';
    import {livekitProvider} from '@deeprespond/im-web';
    Object.assign(globalThis,{devices,ImChannelMediaClient,livekitProvider});`,
    resolveDir: fileURLToPath(new URL('../../', import.meta.url)), loader: 'ts' },
  bundle: true, write: false, format: 'iife', platform: 'browser',
  plugins: [{ name: 'isolate-rtc', setup(builder) {
    builder.onResolve({filter:/^(\.\/screenShare|\.\/rtcTelemetry)$/}, args => ({path:args.path,namespace:'stub'}));
    builder.onLoad({filter:/.*/,namespace:'stub'}, () => ({contents:'export class ScreenShareClient {async stop(){} async close(){} setChannel(){} setConnection(){} acceptTrack(){}} export class RtcTelemetry { start(){} stop(){} }',loader:'js'}));
  }}],
});
let storage = new Map();
const calls = [];
let failDevice = null;
let room;
const oldTrack = { id: 'old' };
class Room {
  constructor() {
    room = this;
    this.publication = { track: { mediaStreamTrack: oldTrack } };
    this.localParticipant = { identity: 'self', audioTrackPublications: new Map([['mic',this.publication]]), setMicrophoneEnabled: async on => calls.push(['enabled',on]) };
  }
  on() { return this; }
  async connect() {}
  async disconnect() {}
  async switchActiveDevice(kind, id) {
    calls.push(['switch',kind,id]);
    if (id === failDevice) throw new Error('Device unplugged');
    if (this.localParticipant.audioTrackPublications.size) this.publication.track.mediaStreamTrack = {id};
    return true;
  }
}
const context = vm.createContext({
  AbortController, setTimeout, clearTimeout, console,
  localStorage: {getItem:key=>storage.get(key)??null,setItem:(key,value)=>storage.set(key,value)},
  LivekitClient: {Room,RoomEvent:{},Track:{Kind:{Video:'video'}},DisconnectReason:{}},
});
vm.runInContext(bundle.outputFiles[0].text,context);
const {devices,ImChannelMediaClient,livekitProvider}=context;
let count = 0;
async function test(name, run) { await run(); count++; console.log(`PASS ${name}`); }
const plain = value => JSON.parse(JSON.stringify(value));
await test('preferences tolerate invalid storage and preserve independently changed values', () => {
  storage.set('openmeeting:meeting-audio','{broken');
  assert.equal(devices.readAudioPreferences().microphoneId,'default');
  storage.set('openmeeting:meeting-audio','null');
  assert.equal(devices.readAudioPreferences().autoJoin,false);
  devices.saveAudioPreferences({speakerId:'headphones'});
  devices.saveAudioPreferences({autoJoin:true});
  assert.equal(devices.readAudioPreferences().speakerId,'headphones');
  assert.equal(devices.readAudioPreferences().autoJoin,true);
  storage.clear();
});
await test('output routing normalizes default and rejects unsupported device routing', async () => {
  const ids=[];
  await devices.routeAudio({setSinkId:async id=>ids.push(id)},'default');
  await devices.routeAudio({setSinkId:async id=>ids.push(id)},'headphones');
  assert.deepEqual(ids,['','headphones']);
  await devices.routeAudio({},'default');
  await assert.rejects(devices.routeAudio({},'headphones'),/speakerUnsupported/);
});
await test('microphone errors distinguish outdated SDK, device permissions, and disconnected hardware', () => {
  const message = devices.microphoneErrorMessage;
  assert.equal(message(new devices.AudioDeviceError('sdkReloadRequired')), 'sdkReloadRequired');
  assert.equal(message({code:'unsupported',details:{reason:'microphone_selection_unavailable'}}), 'inputUnsupported');
  assert.equal(message({name:'NotAllowedError'}), 'permissionDenied');
  assert.equal(message({name:'NotFoundError'}), 'inputMissing');
  assert.equal(message({name:'OverconstrainedError'}), 'inputMissing');
  assert.equal(message({name:'NotReadableError'}), 'inputBusy');
  assert.equal(message({code:'invalid_state',details:{reason:'media_not_connected'}}), 'mediaNotReady');
});
await test('SDK switches the physical microphone and replaces native tracks in channel events', async () => {
  calls.length=0;
  const session=await livekitProvider().connect({url:'wss://fixture',token:'fixture'},{media:'audio'});
  const events=[];
  session.on('track',track=>events.push(['added',track.track.id]));
  session.on('trackRemoved',track=>events.push(['removed',track.track.id]));
  await session.setMicrophoneDevice('usb-mic');
  assert.deepEqual(calls,[['switch','audioinput','usb-mic']]);
  assert.deepEqual(plain(events),[['removed','old'],['added','usb-mic']]);
  await session.setMicrophoneDevice('usb-mic');
  assert.equal(calls.length,1);
});
await test('failed SDK switching restores the previous device and emits its replacement track', async () => {
  calls.length=0;
  const session=await livekitProvider().connect({url:'wss://fixture',token:'fixture'},{media:'audio'});
  await session.setMicrophoneDevice('usb-mic');
  failDevice='missing';
  await assert.rejects(session.setMicrophoneDevice('missing'),/unplugged/);
  assert.deepEqual(calls.slice(-2),[['switch','audioinput','missing'],['switch','audioinput','usb-mic']]);
  assert.equal(room.publication.track.mediaStreamTrack.id,'usb-mic');
  failDevice=null;
});
await test('selecting a device while muted never enables microphone capture', async () => {
  calls.length=0;
  const session=await livekitProvider().connect({url:'wss://fixture',token:'fixture'},{media:'audio'});
  room.localParticipant.audioTrackPublications.clear();
  await session.setMicrophoneDevice('usb-mic');
  assert.deepEqual(calls,[['switch','audioinput','usb-mic']]);
});
function platform() {
  const operations=[];
  let state;
  let fail=false;
  const handle={leave:async()=>{},on:()=>()=>{},getSnapshot:()=>({media_state:'connected'}),
    setMicrophoneEnabled:async on=>operations.push(['mic',on]),
    setMicrophoneDevice:async id=>{operations.push(['device',id]);if(fail)throw new Error('unplugged');}};
  const channels={supported:true,getCurrentSession:async()=>null,join:async()=>handle};
  const client=new ImChannelMediaClient();client.subscribe(next=>state=next);
  return {client,channels,handle,operations,state:()=>state,fail:()=>{fail=true;}};
}
const config={transport:'dr-rtc',channelId:'room',ticket:'fixture',expiresAt:new Date(Date.now()+60000).toISOString()};
await test('old live SDK handles produce a refresh instruction without opening devices', async () => {
  const p=platform();delete p.handle.setMicrophoneDevice;
  await p.client.connect(config,p.channels);
  await p.client.setMicrophoneDevice('default');
  assert.deepEqual(p.operations,[]);
  await assert.rejects(p.client.setMicrophoneDevice('usb'), error => devices.microphoneErrorMessage(error) === 'sdkReloadRequired');
  assert.deepEqual(p.operations,[]);
  await p.client.leave();
});
await test('adapter applies the selected microphone before unmuting and keeps mute independent', async () => {
  const p=platform();await p.client.connect(config,p.channels);
  await p.client.setMicrophoneDevice('usb');
  assert.equal(p.state().microphoneDeviceId,'usb');
  assert.deepEqual(p.operations,[['device','usb']]);
  await p.client.setMicEnabled(true);
  assert.deepEqual(p.operations.slice(-2),[['device','usb'],['mic',true]]);
  p.fail();await assert.rejects(p.client.setMicrophoneDevice('missing'));
  assert.equal(p.state().microphoneDeviceId,'usb');
  await p.client.leave();
});
await test('speaker switching rolls every playing element back after a partial failure', async () => {
  const p=platform(), routes=[];
  context.document={querySelectorAll:()=>[
    {setSinkId:async id=>routes.push(['a',id])},
    {setSinkId:async id=>{routes.push(['b',id]);if(id==='missing')throw new Error('unplugged');}},
  ]};
  await p.client.setSpeakerDevice('headphones');
  assert.equal(p.state().speakerDeviceId,'headphones');
  await assert.rejects(p.client.setSpeakerDevice('missing'));
  assert.equal(p.state().speakerDeviceId,'headphones');
  assert.deepEqual(routes.slice(-2),[['a','headphones'],['b','headphones']]);
});
console.log(`${count} meeting audio contracts passed (substituted SDK transport and audio devices; no hardware verification).`);
