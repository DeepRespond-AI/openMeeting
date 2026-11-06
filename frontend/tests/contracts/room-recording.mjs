// Failure injection contracts for the production recorder; native E2E is reported separately.
import assert from 'node:assert/strict';
import {createRequire} from 'node:module';
import {fileURLToPath} from 'node:url';
import {writeFileSync,mkdirSync} from 'node:fs';
import {webcrypto} from 'node:crypto';
import vm from 'node:vm';
const require=createRequire(new URL('../../package.json',import.meta.url));
const {build}=require('esbuild');
const built=await build({entryPoints:[fileURLToPath(new URL('../../src/services/live-meeting/recording.ts',import.meta.url))],bundle:true,write:false,format:'iife',globalName:'RecorderModule',platform:'browser'});
function harness(){
 const nodes=[],calls=[],reports=[],timers=new Map();let nextTimer=0;
 const h={fail:null,hold:null};
 class AudioContext{
  state='running';destination={};
  resume(){return Promise.resolve();}close(){this.state='closed';return Promise.resolve();}
  createMediaStreamSource(){return{connect(){},disconnect(){}};}
  createGain(){return{gain:{value:0},connect(){},disconnect(){}};}
  createScriptProcessor(){const node={onaudioprocess:null,connect(){},disconnect(){}};nodes.push(node);return node;}
 }
 const context=vm.createContext({console,Date,crypto:webcrypto,Uint8Array,Int16Array,DataView,AudioContext,MediaStream:class{},btoa:s=>Buffer.from(s,'binary').toString('base64'),setTimeout:(fn,delay)=>{const id=++nextTimer;timers.set(id,{fn,delay});return id;},clearTimeout:id=>timers.delete(id),window:{__TAURI_INTERNALS__:{invoke:async(command,args)=>{calls.push({command,chunk:args.chunk});if(h.hold)await h.hold;if(h.fail)throw h.fail;}}}});
 vm.runInContext(built.outputFiles[0].text,context);
 const recorder=new context.RecorderModule.RoomRecorder('room-contract',new Date(Date.now()-60000).toISOString(),(state,error)=>reports.push({state,error}),2);
 const tracks=[{key:'a',kind:'audio',local:true,track:{readyState:'live'}},{key:'b',kind:'audio',username:'member',track:{readyState:'live'}}];
 const participants=[{id:'host',isSelf:true},{id:'member',userId:'member'}];
 const tick=()=>new Promise(r=>setImmediate(r));
 const emit=(node,size=80000)=>node.onaudioprocess?.({inputBuffer:{sampleRate:16000,getChannelData:()=>new Float32Array(size).fill(.25)}});
 return Object.assign(h,{recorder,nodes,calls,reports,timers,tracks,participants,tick,emit});
}
const results=[];
async function test(name,fn){await fn();results.push({name,passed:true});console.log(name+': PASS');}
await test('missing backend interface preserves cause and manual retry retains chunk identity',async()=>{
 const h=harness();h.fail={status:404,detail:'Not Found'};h.recorder.sync(h.tracks.slice(0,1),h.participants);h.emit(h.nodes[0]);await h.tick();
 assert.match(h.reports.at(-1).error,/更新后端服务/);assert.equal(h.timers.size,0);const id=h.calls[0].chunk.chunkId;assert.equal(h.calls[0].chunk.epoch,2);
 h.fail=null;await h.recorder.retryUploads();assert.equal(h.calls[1].chunk.chunkId,id);assert.equal(h.reports.at(-1).state,'recording');h.recorder.dispose();
});
await test('outdated native command is diagnosed',async()=>{
 const h=harness();h.fail='Command room_recording_chunk not found';h.recorder.sync(h.tracks.slice(0,1),h.participants);h.emit(h.nodes[0]);await h.tick();assert.match(h.reports.at(-1).error,/客户端录音组件版本过旧/);h.recorder.dispose();assert.equal(h.timers.size,0);
});
await test('transient upload failure retries automatically without new audio',async()=>{
 const h=harness();h.fail={status:503,detail:'service unavailable'};h.recorder.sync(h.tracks.slice(0,1),h.participants);h.emit(h.nodes[0]);await h.tick();const [id,timer]=[...h.timers][0];assert.equal(timer.delay,1000);h.timers.delete(id);h.fail=null;timer.fn();await h.tick();assert.equal(h.calls.length,2);assert.equal(h.reports.at(-1).state,'recording');h.recorder.dispose();
});
await test('backlog pauses every track, retains partial audio, and resumes after retry',async()=>{
 const h=harness();h.fail={status:404,detail:'Not Found'};h.recorder.sync(h.tracks,h.participants);h.emit(h.nodes[1],1000);
 for(let i=0;i<120;i++){h.emit(h.nodes[0]);await h.tick();}
 assert.ok(h.nodes.every(n=>n.onaudioprocess===null));assert.match(h.reports.at(-1).error,/更新后端服务/);
 h.calls.length=0;h.fail=null;await h.recorder.retryUploads();assert.equal(h.calls.length,121);assert.equal(new Set(h.calls.map(c=>c.chunk.chunkId)).size,121);assert.ok(h.calls.some(c=>c.chunk.participantId==='member'));assert.equal(h.nodes.length,4);assert.equal(h.reports.at(-1).state,'recording');h.recorder.dispose();
});
await test('finish freezes capture before network completion and flushes partial audio',async()=>{
 const h=harness();h.recorder.sync(h.tracks,h.participants);for(const node of h.nodes)h.emit(node,1000);let release;h.hold=new Promise(r=>release=r);const finishing=h.recorder.finish();assert.ok(h.nodes.every(n=>n.onaudioprocess===null));release();await finishing;assert.equal(h.calls.length,2);assert.equal(h.reports.at(-1).state,'stopped');h.recorder.dispose();
});
await test('failed finish is retryable without losing the final chunk',async()=>{
 const h=harness();h.fail={status:503,detail:'temporary'};h.recorder.sync(h.tracks.slice(0,1),h.participants);h.emit(h.nodes[0],1000);await assert.rejects(h.recorder.finish());const id=h.calls.at(-1).chunk.chunkId;assert.equal(h.timers.size,0);h.fail=null;await h.recorder.finish();assert.equal(h.calls.at(-1).chunk.chunkId,id);assert.equal(h.reports.at(-1).state,'stopped');h.recorder.dispose();
});
const output=new URL('../../../.artifacts/contracts/',import.meta.url);
mkdirSync(output,{recursive:true});
writeFileSync(new URL('recording-results.json',output),JSON.stringify({results},null,2)+'\n');
