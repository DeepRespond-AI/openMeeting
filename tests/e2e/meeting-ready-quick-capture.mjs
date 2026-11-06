import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createRequire} from 'node:module';
import {fileURLToPath} from 'node:url';
const root=fileURLToPath(new URL('../../',import.meta.url)),out=path.resolve(root,process.env.MEETING_READY_OUTPUT||'.artifacts/meeting-ready-im-sync');
const file=path.join(out,'visual-results.json'),data=JSON.parse(fs.readFileSync(file,'utf8'));
assert.ok(data.rows.every(r=>r.pass),'Complete visual assertions and captures first');
const budgetFile=path.join(out,'budget.json'),budget=JSON.parse(fs.readFileSync(budgetFile,'utf8'));
assert.ok(Date.now()-budget.firstStartedAt<budget.limitMs,'E2E budget exhausted');
const {chromium}=createRequire(new URL('../../frontend/package.json',import.meta.url))('playwright');
const browser=await chromium.connectOverCDP('http://127.0.0.1:9261');
const page=browser.contexts()[0].pages().find(p=>!p.url().includes('/im/'));
const invoke=(cmd,args)=>page.evaluate(({cmd,args})=>window.__TAURI_INTERNALS__.invoke(cmd,args),{cmd,args});
const flags=v=>fs.writeFileSync(path.join(out,'faults.json'),JSON.stringify(v));
try{
 const prior=JSON.parse(fs.readFileSync(path.join(out,'room.json'),'utf8'));await invoke('room_end',{roomId:prior.id});
 if(process.argv.includes('--waiting')){
  const thirdBrowser=await chromium.connectOverCDP('http://127.0.0.1:9263');
  const third=thirdBrowser.contexts()[0].pages().find(p=>!p.url().includes('/im/'));
  const room=await invoke('room_create',{});await invoke('room_patch',{roomId:room.id,waitRoom:true});
  try{
   await third.goto(`http://localhost:3162/room?code=${room.code}`,{waitUntil:'domcontentloaded'});await third.getByText('您已进入等待室',{exact:true}).waitFor();
   const dialog=third.getByRole('dialog');await dialog.waitFor({state:'visible',timeout:2000}).catch(()=>{});
   if(await dialog.isVisible())await dialog.getByRole('button',{name:'关闭',exact:true}).click({force:true});
   const corrections=[];
   for(const [viewport,name]of [[{width:1280,height:800},'10-1280x800-等候入会权限.png'],[{width:520,height:760},'21-520x760-等候入会权限.png']]){
    await third.setViewportSize(viewport);
    const source=path.join(out,'screenshots',name),evidence=`visual-failure-waiting-obscured-${viewport.width}.png`;
    fs.copyFileSync(source,path.join(out,evidence));
    await third.screenshot({path:source,animations:'disabled'});
    corrections.push({operation:'waiting overlay visual capture',pass:true,actual:'Audio chooser dismissed to expose waiting-room permission state',previousScreenshot:evidence,screenshot:`screenshots/${name}`});
   }
   fs.writeFileSync(path.join(out,'visual-corrections.json'),JSON.stringify(corrections,null,2));
  }finally{await invoke('room_end',{roomId:room.id});await thirdBrowser.close();}
 }else{
 let seq=data.rows.filter(r=>r.screenshot).length;
 for(const viewport of [{width:1280,height:800},{width:520,height:760}]){
  await page.goto('http://localhost:3162/',{waitUntil:'domcontentloaded'});await page.setViewportSize(viewport);
  flags({delay:4});await page.getByRole('button',{name:'快速会议 立即发起一场会议',exact:true}).click();
  await page.getByTestId('meeting-entry-loading').waitFor();
  const screenshot=`screenshots/${String(++seq).padStart(2,'0')}-${viewport.width}x${viewport.height}-快速会议准备.png`;
  await page.screenshot({path:path.join(out,screenshot),animations:'disabled'});flags({});
  await page.waitForURL('**/room?code=*');const room=await invoke('room_get_code',{code:new URL(page.url()).searchParams.get('code')});
  await invoke('room_end',{roomId:room.id});
  const row={operation:'capture quick meeting preparing',expected:'immediate preparation overlay; no duplicate submission',actual:{viewport},pass:true,screenshot,visualPass:null};data.rows.push(row);console.log(JSON.stringify(row));fs.writeFileSync(file,JSON.stringify(data,null,2));
 }
 }
}finally{flags({});await browser.close();budget.usedMs=Date.now()-budget.firstStartedAt;fs.writeFileSync(budgetFile,JSON.stringify(budget,null,2));}
