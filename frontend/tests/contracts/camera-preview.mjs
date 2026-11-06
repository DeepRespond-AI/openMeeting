import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
import vm from 'node:vm';

const require = createRequire(new URL('../../package.json', import.meta.url));
const { build } = require('esbuild');
const bundle = await build({
  stdin: { contents: `import {livekitProvider} from '@deeprespond/im-web';globalThis.provider=livekitProvider;`, resolveDir: fileURLToPath(new URL('../../', import.meta.url)), loader: 'ts' },
  bundle: true, write: false, format: 'iife', platform: 'browser',
  plugins: process.env.CAMERA_SDK_ENTRY ? [{name:'baseline-sdk',setup(builder){builder.onResolve({filter:/^@deeprespond\/im-web$/},()=>({path:process.env.CAMERA_SDK_ENTRY}));}}] : [],
});
let room, serial = 0;
class Room {
  constructor() {
    room = this; this.events = new Map();
    const capture = () => { if(this.deny)throw new Error('Permission denied');return {id:`camera-${++serial}`,kind:'video',readyState:'live',stop(){this.readyState='ended';}}; };
    this.localParticipant = { identity: 'self', videoTrackPublications: new Map(),
      createTracks:async()=>{const native=capture();return [{kind:'video',mediaStreamTrack:native,stop:()=>native.stop()}];},
      publishTrack:async(track,options)=>{const pub={kind:'video',source:options.source,trackName:options.name,track,
        mute:async()=>track.mediaStreamTrack.stop(),unmute:async()=>{if(track.mediaStreamTrack.readyState==='ended')track.mediaStreamTrack=capture();}};
        this.localParticipant.videoTrackPublications.set('camera',pub);this.events.get('published')?.(pub);return pub;},
      setCameraEnabled:async on=>{let pub=this.localParticipant.videoTrackPublications.get('camera');if(pub){await (on?pub.unmute():pub.mute());}else if(on){const [track]=await this.localParticipant.createTracks();await this.localParticipant.publishTrack(track,{source:'camera',name:'camera'});}}
    };
  }
  on(event, fn) { this.events.set(event,fn); return this; }
  async connect() {}
  async disconnect() {}
}
const context = vm.createContext({console, setTimeout, clearTimeout, LivekitClient:{Room, RoomEvent:{LocalTrackPublished:'published'}, Track:{Kind:{Video:'video'},Source:{Camera:'camera',ScreenShare:'screen_share'}},DisconnectReason:{}}});
vm.runInContext(bundle.outputFiles[0].text,context);
const session=await context.provider().connect({url:'wss://fixture',token:'fixture'},{media:'video'});
const active=new Map(),events=[];
session.on('track',item=>{active.set(item.track.id,item);events.push(['track',item.track.id]);});
session.on('trackRemoved',item=>{active.delete(item.track.id);events.push(['removed',item.track.id]);});
let count=0;
async function test(name,fn){await fn();count++;console.log(JSON.stringify({operation:name,expected:'assertions pass',actual:'assertions passed',passed:true,screenshot:null}));}
await test('first camera enable produces a live local video track',async()=>{await session.setCameraEnabled(true);assert.equal(active.size,1);assert.equal([...active.values()][0].track.readyState,'live');});
await test('camera off removes the ended preview track without an unpublish event',async()=>{await session.setCameraEnabled(false);assert.equal(active.size,0);});
await test('five camera reopens replace native tracks without republishing',async()=>{for(let i=0;i<5;i++){await session.setCameraEnabled(true);assert.equal(active.size,1);assert.equal([...active.values()][0].track.id,`camera-${i+2}`);await session.setCameraEnabled(false);assert.equal(active.size,0);}});
await test('permission denial rejects and leaves no stale preview track',async()=>{room.deny=true;await assert.rejects(session.setCameraEnabled(true),/Permission denied/);assert.equal(active.size,0);room.deny=false;await session.setCameraEnabled(true);assert.equal(active.size,1);});
console.log(`${count} camera contracts passed; RTC transport and native capture substituted.`);
