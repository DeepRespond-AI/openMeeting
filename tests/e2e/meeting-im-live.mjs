// Real meeting API + real IM Web SDK. Gateway identity and native desktop bridge are outside this scope.
import assert from 'node:assert/strict';
import {createRequire} from 'node:module';
import {fileURLToPath} from 'node:url';
import {mkdirSync,readFileSync,writeFileSync,existsSync,unlinkSync} from 'node:fs';
import http from 'node:http';
import path from 'node:path';
const root=fileURLToPath(new URL('../../',import.meta.url));
const require=createRequire(path.join(root,'frontend/package.json'));
const {build}=require('esbuild'),{chromium}=require('playwright');
const output=path.join(root,'.artifacts/meeting-im-integration');mkdirSync(output,{recursive:true});
const previousFile=path.join(output,'live-results.json');
const previous=existsSync(previousFile)?JSON.parse(readFileSync(previousFile,'utf8')):null;
const results={started:new Date().toISOString(),scope:'Real IM Web SDK + modified meeting/user APIs on isolated test DB; gateway identity injected for dedicated temporary users; no native/RTC hardware claim',steps:[],cleanup:{},network:[],history:previous?[...(previous.history||[]),previous.steps]:[]};
let config,browser;
const step=async(operation,expected,action)=>{
  const row={operation,expected,actual:'',pass:false,screenshot:null};results.steps.push(row);
  try{row.actual=await action()||'Confirmed';row.pass=true;}
  catch(e){row.actual=String(e.message||e);throw e;}
  finally{writeFileSync(path.join(output,'live-results.json'),JSON.stringify(results,null,2));console.log(JSON.stringify(row));}
};
const bundle=await build({stdin:{contents:`import {createDRClient} from '@deeprespond/im-web'; import {ImMeetingChat} from './src/services/live-meeting/chat'; Object.assign(window,{createDRClient,ImMeetingChat});`,resolveDir:path.join(root,'frontend'),loader:'ts'},bundle:true,write:false,format:'iife',platform:'browser'});
const server=http.createServer((req,res)=>{res.setHeader('Content-Type',req.url==='/sdk.js'?'application/javascript':'text/html');res.end(req.url==='/sdk.js'?bundle.outputFiles[0].text:'<html><title>Live IM validation</title><script src="/sdk.js"></script></html>');});
await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
try{
  await step('real room admission and IM group grant','Two business members receive the same private group',async()=>{
    const privateSetup=path.join(output,'live-setup-private.json');
    if(existsSync(privateSetup)){config=JSON.parse(readFileSync(privateSetup,'utf8'));unlinkSync(privateSetup);}
    else {const response=await fetch('http://127.0.0.1:3147/test/setup',{method:'POST'});assert.equal(response.status,200);config=await response.json();}
    assert.equal(config.groups[0],config.groups[1]);return 'Business room created/joined; private group mapping confirmed';
  });
  browser=await chromium.launch({headless:true});
  const pages=[];
  await step('two real IM ticket logins','Separate memory sessions connect through the deployed IM service',async()=>{
    for(let i=0;i<2;i++){
      const context=await browser.newContext(),page=await context.newPage();pages.push(page);
      page.on('requestfailed',req=>{const url=new URL(req.url());results.network.push({origin:url.origin,path:url.pathname,error:req.failure()?.errorText});});
      page.on('console',message=>{if(message.type()==='error')results.network.push({console:message.text().replace(/https?:\/\/[^\s)]+/g,match=>{try{const u=new URL(match);return u.origin+u.pathname;}catch{return '[URL]';}})});});
      await page.goto(`http://127.0.0.1:${server.address().port}`);
      await page.evaluate(async ({apiUrl,appKey,ticket,user,group})=>{
        window.im=window.createDRClient({apiUrl,appKey,storage:'memory',tokenStorage:'memory',sessionScope:'tab'});
        await window.im.auth.loginWithTicket({ticket});
        await window.im.connection.waitUntilReady({timeoutMs:15000});
        window.chat=new window.ImMeetingChat(window.im,'live-room',group,user,()=>[],state=>window.chatState=state);
        await window.chat.connect();
      },{apiUrl:config.apiUrl,appKey:config.appKey,ticket:config.tickets[i],user:config.users[i],group:config.groups[i]});
      await page.waitForFunction(()=>window.chatState?.status==='ready',null,{timeout:15000});
    }return 'Two independent Web SDK sessions ready';
  });
  await step('real bidirectional group chat','Each user receives the other user text through the production adapter',async()=>{
    for(const [from,to,text] of [[0,1,'live host message'],[1,0,'live member message']]){
      await pages[from].evaluate(text=>window.chat.sendText(text),text);
      await pages[to].waitForFunction(text=>window.chatState?.messages.some(m=>m.text===text),text,{timeout:20000});
    }
  }).catch(async()=>{results.deliveryDiagnostics=await Promise.all(pages.map(p=>p.evaluate(()=>({connection:window.im.connection.state,status:window.chatState?.status,count:window.chatState?.messages.length,texts:window.chatState?.messages.map(m=>m.text)}))));});
  await step('real group file upload and download','IM group file list and authenticated blob match uploaded bytes',async()=>{
    await pages[0].evaluate(()=>window.chat.sendFile(new File(['live IM file payload'],'live-im-test.txt',{type:'text/plain'}),()=>{}));
    await pages[1].waitForFunction(()=>window.chatState?.messages.some(m=>m.attachment?.name==='live-im-test.txt'),null,{timeout:20000});
    const text=await pages[1].evaluate(async group=>{
      const page=await window.im.files.groupFiles(group);
      const file=page.items.find(f=>f.name==='live-im-test.txt');if(!file)throw Error('Group file missing');
      return (await window.im.files.fetchBlob(file.url)).text();
    },config.groups[0]);assert.equal(text,'live IM file payload');
  }).catch(()=>{});
  await step('real own recall and membership revocation','Recall synchronizes; a removed member cannot enumerate group files',async()=>{
    const seq=await pages[0].evaluate(async ()=>{const message=window.chatState.messages.find(m=>m.text==='live host message').sdk;await window.im.messages.recall(message.conversation_id,message.seq);return message.seq;});
    await pages[1].waitForFunction(seq=>Boolean(window.chatState?.messages.find(m=>m.sequence===seq)?.sdk?.recalled),seq,{timeout:15000});
    const response=await fetch(`http://127.0.0.1:3147/api/v1/rooms/${config.room.id}/leave`,{method:'POST',headers:{'X-Internal-Token':'meeting-im-live-validation-only','X-User-ID':config.users[1],'X-Session-ID':config.users[1]}});assert.equal(response.status,204);
    const denied=await pages[1].evaluate(async group=>{try{await window.im.files.groupFiles(group);return false;}catch{return true;}},config.groups[0]);assert.equal(denied,true);
  }).catch(()=>{});
  await step('real durable scheduled notification','Committed schedule reaches the IM notice conversation',async()=>{
    await pages[0].evaluate(()=>{window.notices=[];window.im.on('message.received',({message})=>window.notices.push(message));});
    const response=await fetch('http://127.0.0.1:3147/api/v1/scheduled-meetings',{method:'POST',headers:{'Content-Type':'application/json','X-Internal-Token':'meeting-im-live-validation-only','X-User-ID':config.users[0],'X-User-Name':'validation'},body:JSON.stringify({title:'Live IM scheduled notification',startAt:new Date(Date.now()+30*60000).toISOString(),durationMin:30})});
    assert.equal(response.status,201);
    await pages[0].waitForFunction(()=>window.notices.some(m=>m.sender==='notice'&&m.body?.event==='scheduled_created'&&m.body?.title==='Live IM scheduled notification'),null,{timeout:25000});
  });
}catch(e){results.error=String(e.message||e);process.exitCode=1;}
finally{
  await browser?.close();await new Promise(resolve=>server.close(resolve));
  if(config){const response=await fetch('http://127.0.0.1:3147/test/cleanup',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({users:config.users,groups:config.groups,roomId:config.room.id})}).catch(()=>null);results.cleanup=response?await response.json():{errors:['cleanup request failed']};}
  results.passed=results.steps.filter(s=>s.pass).length;results.failed=results.steps.filter(s=>!s.pass).length;
  if(results.failed)process.exitCode=1;
  writeFileSync(path.join(output,'live-results.json'),JSON.stringify(results,null,2));console.log(JSON.stringify({passed:results.passed,failed:results.failed,error:results.error,cleanup:results.cleanup}));
}
