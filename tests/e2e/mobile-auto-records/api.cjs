const fs = require('node:fs'), path = require('node:path'), assert = require('node:assert/strict'), crypto = require('node:crypto');
const out = path.resolve(__dirname, '../../../.artifacts/mobile-auto-records');
const accounts = JSON.parse(fs.readFileSync(path.join(out, 'accounts.private.json'), 'utf8'));
const smoke = process.argv.includes('--smoke'), rows = [], tokens = [];
const resultName = smoke ? 'fixture-smoke.json' : 'api-results.json';
if (fs.existsSync(path.join(out,resultName))) {
  fs.mkdirSync(path.join(out,'history'),{recursive:true});
  fs.copyFileSync(path.join(out,resultName),path.join(out,'history',Date.now()+'-'+resultName));
}
let room, ended = false;
async function mode(value) { const r = await fetch('http://127.0.0.1:39330/__fixture/mode', {method:'POST', body:JSON.stringify(value)}); assert.equal(r.status,200); }
async function api(method, route, body, token=tokens[0]) {
  const r=await fetch('http://127.0.0.1:39330/api/v1'+route,{method,headers:{'content-type':'application/json',...(token?{authorization:'Bearer '+token}:{})},body:body===undefined?undefined:JSON.stringify(body),signal:AbortSignal.timeout(15000)});
  const bytes=Buffer.from(await r.arrayBuffer()); let value;try{value=JSON.parse(bytes.toString());}catch{value=null;}return{status:r.status,body:value,bytes};
}
async function step(action,expected,run){const row={action,expected,passed:false,at:new Date().toISOString()};try{row.actual=await run();row.passed=true;}catch(e){row.actual=e.message;throw e;}finally{rows.push(row);fs.writeFileSync(path.join(out,smoke?'fixture-smoke.json':'api-results.json'),JSON.stringify(rows,null,2));console.log(JSON.stringify(row));}}
(async()=>{try{
  await mode({});
  await step('真实隔离账号登录','三个专用账号成功，不覆盖个人登录态',async()=>{for(let i=0;i<3;i++){const a=accounts[i];const r=await api('POST','/auth/login',{phone:a.phone,password:a.password,client:{client_id:'auto-records-api-'+i}},null);assert.equal(r.status,200);tokens.push(r.body.token);}return{authenticated:tokens.length};});
  if(smoke){
    for(let i=0;i<3;i++)await step('故障夹具重复冒烟 '+(i+1),'下载/结束/聊天503，设置403，清除后真实服务200',async()=>{
      await mode({download:'error',end:'error',chat:'error',settings:'forbidden'});assert.equal((await api('GET','/meetings/not-a-record/audio')).status,503);assert.equal((await api('POST','/rooms/not-a-room/end',{})).status,503);
      assert.equal((await api('POST','/rooms/not-a-room/chat-session',{})).status,503);assert.equal((await api('PATCH','/rooms/not-a-room',{})).status,403);
      await mode({});assert.equal((await api('GET','/auth/me')).status,200);return{download:503,end:503,chat:503,settings:403,recovered:200};});
    await step('下载加载夹具','真实404之前稳定延迟至少1.8秒',async()=>{await mode({download:'delay'});const start=Date.now(),r=await api('GET','/meetings/not-a-record/audio');assert.equal(r.status,404);assert.ok(Date.now()-start>=1800);await mode({});return{delayedMs:Date.now()-start,status:r.status};});return;
  }
  await step('自动录音与旧手动入口拒绝','创建即启用epoch；停止/申请/审批返回409',async()=>{
    const r=await api('POST','/rooms',{title:'移动自动录音 API 验证'});assert.equal(r.status,201);room=r.body;assert.equal(room.recording.active,true);assert.ok(room.recording.epoch>=1);
    for(const action of ['stop','request','approve','deny'])assert.equal((await api('POST',`/rooms/${room.id}/recording/control`,{action,epoch:room.recording.epoch})).status,409);
    return{active:true,epoch:room.recording.epoch,rejectedManualActions:4};});
  await step('实际参会成员提前离开','加入后离开，不立即生成最终记录',async()=>{
    assert.equal((await api('POST','/rooms/join',{code:room.code,micOn:false,camOn:false},tokens[1])).status,200);
    assert.equal((await api('POST',`/rooms/${room.id}/leave`,{},tokens[1])).status,204);
    assert.equal((await api('GET','/meetings',undefined,tokens[1])).body.some(x=>x.id===room.meetingId),false);return{earlyLeaver:true};});
  await step('合成PCM幂等上传','同一分片重复确认仅落库一次',async()=>{
    const chunk={chunkId:'auto-'+Date.now(),participantId:room.hostId,startTime:0,pcm:Buffer.alloc(32000).toString('base64'),epoch:room.recording.epoch};
    for(let i=0;i<2;i++)assert.equal((await api('POST',`/rooms/${room.id}/recording/chunks`,chunk)).status,201);
    const p=await fetch('http://127.0.0.1:3267/__e2e/recording/'+room.id),v=await p.json();assert.equal(v.chunks,1);return{chunks:1,syntheticInput:true,bytes:32000};});
  let meetingId;
  await step('结束失败恢复与幂等','503后保持活动，再次结束返回相同记录',async()=>{
    await mode({end:'error'});assert.equal((await api('POST',`/rooms/${room.id}/end`,{})).status,503);await mode({});assert.equal((await api('GET',`/rooms/${room.id}`)).body.status,'active');
    const a=await api('POST',`/rooms/${room.id}/end`,{}),b=await api('POST',`/rooms/${room.id}/end`,{});assert.equal(a.status,200);assert.equal(b.status,200);assert.equal(a.body.meetingId,b.body.meetingId);meetingId=a.body.meetingId;ended=true;return{meetingId,idempotent:true};});
  await step('早退成员共享读取与只读权限','同一记录可读、can_manage=false、修改删除被拒绝',async()=>{
    const list=await api('GET','/meetings',undefined,tokens[1]);assert.equal(list.status,200);assert.ok(list.body.some(x=>x.id===meetingId&&x.can_manage===false));
    const meta=await api('GET',`/meetings/${meetingId}/metadata`,undefined,tokens[1]);assert.equal(meta.status,200);assert.equal(meta.body.can_manage,false);
    for(const suffix of ['', '/transcripts','/summary','/recording'])assert.equal((await api('GET',`/meetings/${meetingId}${suffix}`,undefined,tokens[1])).status,200);
    assert.equal((await api('PATCH',`/meetings/${meetingId}`,{title:'not permitted'},tokens[1])).status,404);assert.equal((await api('DELETE',`/meetings/${meetingId}`,undefined,tokens[1])).status,404);return{canManage:false,sharedRead:true,writesRejected:true};});
  await step('未参会账号拒绝','列表不可见，详情和音频404',async()=>{
    const list=await api('GET','/meetings',undefined,tokens[2]);assert.equal(list.body.some(x=>x.id===meetingId),false);
    for(const suffix of ['/metadata','/audio'])assert.equal((await api('GET',`/meetings/${meetingId}${suffix}`,undefined,tokens[2])).status,404);return{outsiderDenied:true};});
  await step('同一WAV共享下载、失败恢复','主持人及早退成员下载字节一致，模型失败仍保留音频',async()=>{
    let status;
    for(let i=0;i<90;i++){status=await api('GET',`/meetings/${meetingId}/recording`);if(['failed','completed'].includes(status.body.status))break;await new Promise(r=>setTimeout(r,100));}
    await mode({download:'error'});assert.equal((await api('GET',`/meetings/${meetingId}/audio`,undefined,tokens[1])).status,503);await mode({});
    const owner=await api('GET',`/meetings/${meetingId}/audio`),member=await api('GET',`/meetings/${meetingId}/audio`,undefined,tokens[1]);assert.equal(owner.status,200);assert.equal(member.status,200);assert.deepEqual(owner.bytes,member.bytes);assert.equal(member.bytes.toString('ascii',0,4),'RIFF');
    const meta=await api('GET',`/meetings/${meetingId}/metadata`,undefined,tokens[1]);assert.equal(meta.body.has_audio,true);
    return{bytes:member.bytes.length,sha256:crypto.createHash('sha256').update(member.bytes).digest('hex'),processing:status.body.status,error:status.body.error,syntheticInput:true,hardwareCaptureVerified:false};});
  await step('独立录音记录维持私人范围','个人记录不因会议共享而对其他参会者开放',async()=>{
    const created=await api('POST','/meetings',{title:'个人录音权限验证'});assert.equal(created.status,201);
    const privateId=created.body.id;assert.equal((await api('GET',`/meetings/${privateId}/metadata`)).body.can_manage,true);
    assert.equal((await api('GET',`/meetings/${privateId}/metadata`,undefined,tokens[1])).status,404);
    assert.equal((await api('DELETE',`/meetings/${privateId}`)).status,204);return{personalRecordPrivate:true};});
  fs.writeFileSync(path.join(out,'api-fixtures.json'),JSON.stringify({meetingId},null,2));
}finally{await mode({});if(room&&!ended)try{await api('POST',`/rooms/${room.id}/end`,{});}catch{}}})().catch(e=>{console.error(e.message);process.exitCode=1;});
