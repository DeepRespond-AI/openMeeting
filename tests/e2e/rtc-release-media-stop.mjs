import fs from 'node:fs';
import path from 'node:path';
import {createRequire} from 'node:module';
import {fileURLToPath} from 'node:url';
import assert from 'node:assert/strict';
const root=fileURLToPath(new URL('../../',import.meta.url)),out=path.resolve(root,process.env.MEETING_READY_OUTPUT||'.artifacts/rtc-release-media-preview');
const require=createRequire(new URL('../../frontend/package.json',import.meta.url)),{chromium}=require('playwright');
const accounts=JSON.parse(fs.readFileSync(path.join(out,'accounts.private.json'),'utf8')),state=JSON.parse(fs.readFileSync(path.join(out,'success-state.json'),'utf8'));
const rows=[];
for(let i=0;i<3;i++){
 const b=await chromium.connectOverCDP(`http://127.0.0.1:${9261+i}`);
 try{
  const p=b.contexts()[0].pages().find(p=>p.url().startsWith('http://localhost:3162')&&!p.url().includes('/im/'));assert.ok(p);
  const invoke=(command,args={})=>p.evaluate(({command,args})=>window.__TAURI_INTERNALS__.invoke(command,args),{command,args});
  assert.equal((await invoke('auth_get_user')).id,accounts[i].id);
  if(i===0)await invoke('room_end',{roomId:state.room.id});
  await p.evaluate(async()=>{
   const el=[...document.querySelectorAll('*')].find(e=>Object.keys(e).some(k=>k.startsWith('__reactFiber')));if(!el)return;
   let f=el[Object.keys(el).find(k=>k.startsWith('__reactFiber'))];while(f.return)f=f.return;
   const todo=[f],seen=new Set();while(todo.length){const n=todo.pop();if(!n||seen.has(n))continue;seen.add(n);const c=n.memoizedProps?.client||n.memoizedProps?.value?.client;if(c?.channels&&c?.messages){await c.channels.current?.leave();return;}todo.push(n.child,n.sibling);}
  });
  await invoke('auth_logout');rows.push({client:i,endedMeeting:i===0,loggedOut:true,pass:true});
 }catch(error){rows.push({client:i,pass:false,error:String(error)});process.exitCode=1;}
 finally{await b.close();}
}
fs.writeFileSync(path.join(out,'meeting-end-cleanup.json'),JSON.stringify({rows},null,2));console.log(JSON.stringify({rows}));
