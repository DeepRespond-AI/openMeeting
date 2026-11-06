const fs=require('fs'),path=require('path'),assert=require('assert/strict');
const out=path.resolve(__dirname,'../../../.artifacts/mobile-desktop-parity');
const accounts=JSON.parse(fs.readFileSync(path.join(out,'accounts.private.json'),'utf8'));
const rows=[];let room,host,member;
async function api(method,route,body,token=host){const r=await fetch('http://127.0.0.1:39330/api/v1'+route,{method,headers:{'content-type':'application/json',...(token?{authorization:'Bearer '+token}:{})},body:body===undefined?undefined:JSON.stringify(body),signal:AbortSignal.timeout(20000)});const text=await r.text();return{status:r.status,body:text?JSON.parse(text):null};}
async function mode(value){await fetch('http://127.0.0.1:39330/__fixture/mode',{method:'POST',body:JSON.stringify(value)});}
async function step(action,expected,run){const row={action,expected,passed:false,at:new Date().toISOString()};try{row.actual=await run();row.passed=true;}catch(e){row.actual=e.message;throw e;}finally{rows.push(row);fs.writeFileSync(path.join(out,'api-results.json'),JSON.stringify(rows,null,2));console.log(JSON.stringify(row));}}
(async()=>{try{
 await mode({});
 await step('real isolated login','two dedicated accounts authenticate against actual gateway',async()=>{
  for(let i=0;i<2;i++){const a=accounts[i],r=await api('POST','/auth/login',{phone:a.phone,password:a.password,client:{client_id:'mobile-parity-api-'+i}},null);assert.equal(r.status,200);if(i===0)host=r.body.token;else member=r.body.token;}
  return{authenticated:2};
 });
 let hostPart,peerPart;
 await step('create and join','actual host/member business membership',async()=>{
  let r=await api('POST','/rooms',{});assert.equal(r.status,201);room=r.body;
  r=await api('POST','/rooms/join',{code:room.code,micOn:false,camOn:false});assert.equal(r.status,200);hostPart=r.body.self;
  r=await api('POST','/rooms/join',{code:room.code,micOn:false,camOn:false},member);assert.equal(r.status,200);peerPart=r.body.self;return{participants:2,defaultRecording:room.recording.active};
 });
 await step('host mute permission','host restriction can be lifted without remotely starting microphone',async()=>{
  assert.equal((await api('POST',`/rooms/${room.id}/mute-all`,{})).status,204);
  let r=await api('GET',`/rooms/${room.id}`,undefined,member);let p=r.body.participants.find(x=>x.id===peerPart.id);assert.equal(p.mutedByHost,true);
  assert.equal((await api('POST',`/rooms/${room.id}/participants/${peerPart.id}/mute`,{muted:false})).status,204);
  r=await api('GET',`/rooms/${room.id}`,undefined,member);p=r.body.participants.find(x=>x.id===peerPart.id);assert.equal(p.mutedByHost,false);assert.equal(p.micOn,false);return{restrictedThenReleased:true,micOn:p.micOn};
 });
 const control=(action,epoch,token=host,extra={})=>api('POST',`/rooms/${room.id}/recording/control`,{action,epoch,...extra},token);
 let epoch;
 await step('member request and host approval','server records pending request and starts shared epoch on approval',async()=>{
  assert.equal((await control('start',0,member)).status,403);
  const r=await control('request',0,member);assert.equal(r.status,200);const request=r.body.recording.requests.find(x=>x.participantId===peerPart.id);assert.equal(request.status,'pending');
  const approved=await control('approve',0,host,{participantId:peerPart.id,requestId:request.requestId});assert.equal(approved.status,200);assert.equal(approved.body.recording.active,true);epoch=approved.body.recording.epoch;assert.ok(epoch>0);return{request:'approved',epoch};
 });
 await step('stale epoch rejected','old epoch cannot stop a newer recording',async()=>{const r=await control('stop',epoch-1);assert.equal(r.status,409);return{status:r.status};});
 const chunk={chunkId:'api-'+Date.now(),participantId:hostPart.id,startTime:0,pcm:Buffer.alloc(16000).toString('base64'),epoch};
 await step('upload failure then idempotent retry','503 preserves the same chunk and duplicate ack stores one row',async()=>{
  await mode({upload:'error'});assert.equal((await api('POST',`/rooms/${room.id}/recording/chunks`,chunk)).status,503);await mode({});
  assert.equal((await api('POST',`/rooms/${room.id}/recording/chunks`,chunk,member)).status,403);
  for(let i=0;i<2;i++)assert.equal((await api('POST',`/rooms/${room.id}/recording/chunks`,chunk)).status,201);
  const r=await fetch('http://127.0.0.1:3167/__e2e/recording/'+encodeURIComponent(room.id));const body=await r.json();assert.equal(body.chunks,1);return{chunks:body.chunks,pcm:'explicit synthetic silence',bytes:16000};
 });
 await step('stop and restart','stop rejects new audio and restart increments epoch',async()=>{
  assert.equal((await control('stop',epoch)).status,200);
  assert.equal((await api('POST',`/rooms/${room.id}/recording/chunks`,{...chunk,chunkId:chunk.chunkId+'-stopped'})).status,409);
  const r=await control('start',epoch);assert.equal(r.status,200);const next=r.body.recording.epoch;assert.ok(next>epoch);epoch=next;
  assert.equal((await api('POST',`/rooms/${room.id}/recording/chunks`,{...chunk,chunkId:chunk.chunkId+'-second',startTime:1,epoch})).status,201);return{restartedEpoch:epoch};
 });
 await step('private meeting IM authorization','both joined users are bound to the same real private IM group',async()=>{
  const a=await api('POST',`/rooms/${room.id}/chat-session`,{}),b=await api('POST',`/rooms/${room.id}/chat-session`,{},member);assert.equal(a.status,200);assert.equal(b.status,200);assert.equal(a.body.transport,'dr-im-group');assert.equal(a.body.groupId,b.body.groupId);return{transport:a.body.transport,sameGroup:true};
 });
 let meetingId,jobId;
 await step('end failure recovery and idempotence','503 leaves room active; successful repeated end returns identical IDs',async()=>{
  await mode({end:'error'});assert.equal((await api('POST',`/rooms/${room.id}/end`,{})).status,503);await mode({});
  assert.equal((await api('GET',`/rooms/${room.id}`)).body.status,'active');assert.equal((await api('POST',`/rooms/${room.id}/end`,{},member)).status,403);
  const a=await api('POST',`/rooms/${room.id}/end`,{});assert.equal(a.status,200);meetingId=a.body.meetingId;jobId=a.body.jobId;
  const b=await api('POST',`/rooms/${room.id}/end`,{});assert.equal(b.status,200);assert.equal(b.body.meetingId,meetingId);assert.equal(b.body.jobId,jobId);return{meetingId,jobId,idempotent:true};
 });
 await step('actual WAV survives failed postprocessing','real worker saves WAV; unavailable STT is reported rather than losing audio',async()=>{
  let value;
  for(let i=0;i<60;i++){value=await api('GET',`/meetings/${meetingId}/recording`);if(['failed','completed'].includes(value.body.status))break;await new Promise(r=>setTimeout(r,100));}
  assert.ok(['failed','completed'].includes(value.body.status));const metadata=await api('GET',`/meetings/${meetingId}/metadata`);assert.equal(metadata.body.has_audio,true);
  const r=await fetch(`http://127.0.0.1:39330/api/v1/meetings/${meetingId}/audio`,{headers:{authorization:'Bearer '+host}});assert.equal(r.status,200);const bytes=Buffer.from(await r.arrayBuffer());assert.equal(bytes.toString('ascii',0,4),'RIFF');assert.ok(bytes.length>44);
  return{hasAudio:true,wavBytes:bytes.length,processing:value.body.status,error:value.body.error,syntheticInput:true,hardwareCaptureVerified:false};
 });
 }finally{await mode({});if(room&&!rows.some(x=>x.action.startsWith('end failure')&&x.passed)){try{await api('POST',`/rooms/${room.id}/end`,{});}catch{}}}
})().catch(e=>{console.error(e.message);process.exitCode=1;});
