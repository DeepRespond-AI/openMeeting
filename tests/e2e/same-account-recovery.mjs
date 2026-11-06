// Follow-up after the deliberately retained immediate-retry failure. Records
// actual service session states and one later retry; no synthetic media/delay.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';import {createRequire} from 'node:module';
const root=path.resolve(import.meta.dirname,'../..'),out=path.join(root,'.artifacts/same-account-meeting-entry'),require=createRequire(path.join(root,'frontend/package.json')),{chromium}=require('playwright');
const room=JSON.parse(fs.readFileSync(path.join(out,'owned-room.json'))),budget=JSON.parse(fs.readFileSync(path.join(out,'budget.json')));if(Date.now()-budget.started>budget.limitMs)throw Error('30 minute E2E budget exhausted');
const data={steps:[],screenshots:[]};const save=()=>fs.writeFileSync(path.join(out,'recovery.json'),JSON.stringify(data,null,2));
const b=await chromium.connectOverCDP('http://127.0.0.1:9271'),p=b.contexts()[0].pages().find(p=>!p.url().includes('/im/'));p.setDefaultTimeout(15000);
async function sessions(){return p.evaluate(async id=>{let root;for(const el of document.querySelectorAll('*')){const k=Object.keys(el).find(k=>k.startsWith('__reactFiber'));if(k){root=el[k];while(root.return)root=root.return;break}}const stack=[root];while(stack.length){const f=stack.pop();if(!f)continue;const v=f.memoizedProps?.value;if(v?.client?.channels){try{const r=await v.client.channels.listParticipants(id);return r.items?.map(s=>({status:s.status,mediaConnected:s.media_connected}))??{keys:Object.keys(r)}}catch(e){return{error:e.code,reason:e.reason,status:e.status}}}if(f.child)stack.push(f.child);if(f.sibling)stack.push(f.sibling)}return null},room.id);}
async function capture(file,width,height){await p.setViewportSize({width,height});await p.screenshot({path:path.join(out,'screenshots',file),animations:'disabled'});data.screenshots.push({file:'screenshots/'+file,viewport:{width,height},body:(await p.locator('body').innerText()).slice(0,2000)});save();}
try{
 data.sessionStatesBefore=await sessions();save();await p.setViewportSize({width:1280,height:800});await p.getByRole('button',{name:'重试',exact:true}).click();
 if(await p.getByTestId('meeting-entry-loading').isVisible())await capture('13-current-native-loading-1280x800.png',1280,800);
 if(await p.getByTestId('meeting-entry-loading').isVisible())await capture('14-current-native-loading-520x760.png',520,760);
 await p.getByRole('button',{name:'离开并结束',exact:true,includeHidden:true}).waitFor({state:'attached',timeout:60000});const close=p.getByRole('dialog').getByRole('button',{name:'关闭',exact:true});if(await close.isVisible())await close.click();assert.equal(await p.getByTestId('meeting-entry-error').count(),0);
 data.steps.push({operation:'later retry after service release delay',expected:'Native room connects after first device exits and release completes',actual:{recovered:true,sessions:await sessions()},pass:true,screenshot:null});save();
 await capture('11-current-native-recovered-1280x800.png',1280,800);await capture('12-current-native-recovered-520x760.png',520,760);
}catch(e){data.steps.push({operation:'later retry after service release delay',expected:'Native room connects',actual:String(e.stack||e),pass:false,screenshot:null});process.exitCode=1;}finally{save();console.log(JSON.stringify(data));await b.close();}
