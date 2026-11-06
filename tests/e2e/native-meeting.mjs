import assert from 'node:assert/strict';
import {createRequire} from 'node:module';
import {mkdirSync,writeFileSync} from 'node:fs';
import {fileURLToPath} from 'node:url';
import {installMediaProbe} from './media-input.mjs';

if(process.argv.includes('--help')){
  console.log('Dedicated native clients required. See tests/e2e/README.md. Options: --synthetic (Oscillator/Canvas input), --screen (real window capture). Environment: OPENMEETING_E2E_HOST_CDP, OPENMEETING_E2E_MEMBER_CDP, OPENMEETING_E2E_UI_URL, OPENMEETING_PLAYWRIGHT_PACKAGE.');
  process.exit(0);
}
// CDP endpoints and the dedicated dev server are local, independent of shell proxy settings.
for(const key of ['HTTP_PROXY','HTTPS_PROXY','ALL_PROXY','http_proxy','https_proxy','all_proxy'])delete process.env[key];
const require=createRequire(process.env.OPENMEETING_PLAYWRIGHT_PACKAGE||new URL('../../frontend/package.json',import.meta.url));
const {chromium}=require('playwright');
const synthetic=process.argv.includes('--synthetic'),screen=process.argv.includes('--screen');
const ui=new URL(process.env.OPENMEETING_E2E_UI_URL||'http://localhost:3138/');
const endpoints=[process.env.OPENMEETING_E2E_HOST_CDP||'http://127.0.0.1:9256',process.env.OPENMEETING_E2E_MEMBER_CDP||'http://127.0.0.1:9257'];
assert.equal(new Set(endpoints.map(value=>new URL(value).href)).size,2,'Use two distinct dedicated CDP endpoints');
const output=new URL(`../../.artifacts/e2e/native-${new Date().toISOString().replace(/[:.]/g,'-')}/`,import.meta.url);
mkdirSync(output,{recursive:true});
const results=[],browsers=[],pages=[];let room,meetingId,sourceBrowser;
const invoke=(page,command,args={})=>page.evaluate(({command,args})=>window.__TAURI_INTERNALS__.invoke(command,args),{command,args});
const sleep=ms=>new Promise(resolve=>setTimeout(resolve,ms));
async function until(fn,ms=60000){const end=Date.now()+ms;while(Date.now()<end){const value=await fn();if(value)return value;await sleep(250);}throw Error('Expected state timed out');}
function save(){writeFileSync(new URL('results.json',output),JSON.stringify({synthetic,screen,roomId:room?.id,meetingId,results},null,2)+'\n');}
async function step(name,fn){const row={name,passed:false};try{Object.assign(row,await fn());row.passed=true;}catch(error){row.error=String(error.message||error);throw error;}finally{results.push(row);console.log(JSON.stringify(row));save();}}
async function mediaStats(page){return page.evaluate(async()=>{
  const rows=[];for(const peer of window.__meetingE2E.peers)if(peer.connectionState==='connected')for(const row of(await peer.getStats()).values())if(row.type==='inbound-rtp')rows.push({kind:row.kind,bytesReceived:row.bytesReceived,totalAudioEnergy:row.totalAudioEnergy,framesDecoded:row.framesDecoded});return rows;
});}
try{
 await step('connect_dedicated_native_clients',async()=>{
  for(const endpoint of endpoints){
   const browser=await chromium.connectOverCDP(endpoint);browsers.push(browser);
   const context=browser.contexts()[0],page=context.pages().find(p=>p.url().startsWith(ui.origin)&&!p.url().includes('/im/'));
   assert.ok(page,'Dedicated client UI not found; check OPENMEETING_E2E_UI_URL');
   assert.ok(!new URL(page.url()).pathname.startsWith('/room'),'Refusing to navigate a client already in a meeting');
   assert.equal((await invoke(page,'server_get_config')).loggedIn,true,'Log into a dedicated test profile first');
   pages.push(page);page.setDefaultTimeout(30000);
   await context.addInitScript(installMediaProbe,{synthetic});
   await page.goto(ui.href,{waitUntil:'domcontentloaded'});
   await page.getByRole('button',{name:'快速会议 立即发起一场会议',exact:true}).waitFor();
  }
  return{clients:2,input:synthetic?'Oscillator/Canvas':'physical getUserMedia'};
 });
 const[host,member]=pages;
 await step('quick_meeting_and_member_join',async()=>{
  await host.getByRole('button',{name:'快速会议 立即发起一场会议',exact:true}).click();
  const code=await until(()=>new URL(host.url()).searchParams.get('code'));room=await invoke(host,'room_get_code',{code});
  await member.getByRole('button',{name:'加入会议 输入会议号入会',exact:true}).click();const dialog=member.getByRole('dialog');
  for(let i=0;i<6;i++)await dialog.locator('input[inputmode="numeric"]').nth(i).fill(code[i]);
  await dialog.locator('#join-name').fill('Native E2E Member');
  for(const item of await dialog.getByRole('switch').all())if(await item.getAttribute('aria-checked')==='true')await item.click();
  await dialog.getByRole('button',{name:'加入会议',exact:true}).click();await member.getByRole('button',{name:'聊天',exact:true}).waitFor();
  await until(async()=>(await invoke(host,'room_get',{roomId:room.id})).participants.length===2);return{code};
 });
 await step('bidirectional_chat',async()=>{
  for(const page of pages)await page.getByRole('button',{name:'聊天',exact:true}).click();
  for(const[sender,receiver,text]of[[host,member,'E2E host to member'],[member,host,'E2E member to host']]){
   await sender.getByPlaceholder('发送消息，全体成员可见').fill(text);await sender.getByRole('button',{name:'发送',exact:true}).click();await receiver.getByText(text,{exact:true}).waitFor();
  }return{};
 });
 await step('real_rtc_bidirectional_audio_video',async()=>{
  for(const page of pages){
   await until(()=>page.evaluate(()=>!(document.querySelector('[data-testid="media-status"]')?.textContent||'').includes('正在连接')));
   const retry=page.getByRole('button',{name:'重试音视频',exact:true});if(await retry.isVisible())await retry.click();
   for(const[off,on]of[['已静音','麦克风'],['已关闭','摄像头']]){const button=page.getByRole('button',{name:off,exact:true});if(await button.isVisible())await button.click();await page.getByRole('button',{name:on,exact:true}).waitFor();}
  }
  const media=await until(async()=>{const snapshots=await Promise.all(pages.map(mediaStats));return snapshots.every(rows=>rows.some(r=>r.kind==='audio'&&r.totalAudioEnergy>0)&&rows.some(r=>r.kind==='video'&&r.framesDecoded>0))&&snapshots;});
  await host.getByTestId('room-recording-status').filter({hasText:'正在录制会议'}).waitFor();await sleep(6000);return{media};
 });
 if(screen)await step('native_screen_capture_and_remote_display',async()=>{
  sourceBrowser=await chromium.launch({channel:'chrome',headless:false,args:['--window-size=900,650']});const source=await sourceBrowser.newPage();
  await source.setContent('<html><head><title>OpenMeeting E2E capture source</title></head><body style="background:#1664df;color:white;font:36px sans-serif">OpenMeeting E2E capture source<p id="clock"></p><script>setInterval(()=>document.querySelector("#clock").textContent=new Date().toISOString(),100)</script></body></html>');
  await host.getByRole('button',{name:'共享屏幕',exact:true}).click();
  await until(()=>member.locator('[data-testid="screen-stage"] video').evaluateAll(elements=>elements.some(el=>el.videoWidth>0&&el.currentTime>0)));
  const capture=await host.evaluate(()=>window.__meetingE2E.captures);assert.ok(capture.length);
  for(const[page,name]of[[host,'screen-host'],[member,'screen-member']])await page.screenshot({path:fileURLToPath(new URL(name+'.png',output))});
  await sourceBrowser.close();sourceBrowser=null;
  for(const page of pages)await page.getByTestId('screen-stage').waitFor({state:'detached'});return{capture};
 });
 await step('end_meeting_preserves_audio_and_releases_peers',async()=>{
  await host.getByRole('button',{name:'离开并结束',exact:true}).click();await host.getByRole('dialog').getByRole('button',{name:'结束会议',exact:true}).click();
  await host.waitForURL('**/meeting-details?id=*',{timeout:60000});meetingId=new URL(host.url()).searchParams.get('id');
  const metadata=await until(async()=>{const value=await invoke(host,'api_get_meeting_metadata',{meetingId});return value.has_audio&&value;});assert.ok(metadata.audio_duration>1);
  await until(async()=>(await member.locator('body').innerText()).includes('会议已结束'));
  const connections=await member.evaluate(()=>window.__meetingE2E.peers.map(p=>p.connectionState));assert.ok(connections.every(state=>state==='closed'));
  const audio=host.locator('audio').first();await until(()=>audio.evaluate(el=>el.readyState>=1));
  await audio.evaluate(async el=>{el.muted=true;await el.play();});await until(()=>audio.evaluate(el=>el.currentTime>0));await audio.evaluate(el=>el.pause());
  await host.screenshot({path:fileURLToPath(new URL('saved-recording.png',output))});return{metadata,connections,postprocessing:await host.getByTestId('recording-job-status').innerText()};
 });
}catch(error){console.error(error.message||error);process.exitCode=1;
 for(const[client,page]of pages.entries())await page.screenshot({path:fileURLToPath(new URL(`failed-${client}.png`,output))}).catch(()=>{});
}finally{save();if(sourceBrowser)await sourceBrowser.close();for(const browser of browsers)await browser.close();console.log('Artifacts: '+fileURLToPath(output));}
