import { testPython } from './local-tools.cjs';
import {renderScreenReport} from './im-rtc-screen-report.mjs';
import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import { mkdirSync, readFileSync, writeFileSync, existsSync, openSync } from 'node:fs';
import { spawn } from 'node:child_process';
import { startMeetingBackend, installMeetingBridge } from './fixtures/meeting-session-backend.mjs';
import { installLayoutBridge } from './fixtures/desktop-layout-backend.mjs';
import {withScreenFailures} from './fixtures/im-rtc-screen-failures.mjs';
import {installRtcCamera} from './fixtures/rtc-camera-capture.mjs';

const root = fileURLToPath(new URL('../../', import.meta.url)), frontend = path.join(root, 'frontend');
const require = createRequire(path.join(frontend, 'package.json')), { chromium } = require('playwright');
const out = path.resolve(process.env.IM_RTC_SCREEN_OUTPUT || path.join(root, '.artifacts/IM第二视频轨道共享'));
mkdirSync(path.join(out, 'screenshots'), { recursive: true });
const smokeOnly = process.argv.includes('--smoke'), reportOnly = process.argv.includes('--report');
const localRtc=process.argv.includes('--local-rtc');
const resultPath = path.join(out, 'results.json');
const tsconfigPath = path.join(frontend, 'tsconfig.json'), tsconfigBefore = readFileSync(tsconfigPath, 'utf8');
function report(){renderScreenReport(out,root);}

if (reportOnly) { report(); process.exit(0); }
const backend = await startMeetingBackend();
const rpc = async (session, command, args = {}) => {
  const response = await fetch(backend.base + '/invoke', { method: 'POST', body: JSON.stringify({ session, command, args }) });
  return { status: response.status, data: await response.json() };
};
const control = async (session, patch) => fetch(backend.base + '/control', { method: 'POST', body: JSON.stringify({ session, patch }) }).then(r => r.json());
const started = Date.now(), budgetFile = path.join(out, 'budget.json');
const budgetStarted = existsSync(budgetFile) ? JSON.parse(readFileSync(budgetFile, 'utf8')).started : started;
if (!smokeOnly && !existsSync(budgetFile)) writeFileSync(budgetFile, JSON.stringify({ started }));
const data = { started: new Date().toISOString(), budgetStarted, startup: 'node tests/e2e/im-rtc-screen-share.mjs --smoke，然后 node tests/e2e/im-rtc-screen-share.mjs；隔离 Next dev :3188，OPENMEETING_NEXT_DIST_DIR=.next-e2e-meeting-session，OPENMEETING_E2E_DESKTOP_LAYOUT=1，OPENMEETING_E2E_IM_RTC_SCREEN=1；随机端口 HTTP 夹具。', steps: [], probe: [], cleanup: {}, elapsedSeconds: 0 };
let rtcServer,localServer;
let phase = smokeOnly ? 'fixture-smoke' : 'assertions', viewport = '', next, browser, page, contexts = [], number = 0;
const save = () => writeFileSync(path.join(out, smokeOnly ? 'smoke-results.json' : 'results.json'), JSON.stringify(data, null, 2));
async function step(operation, expected, fn, screenshot) {
  if (!smokeOnly && Date.now() - budgetStarted > 1800000) throw Error('E2E 30 minute budget exhausted: use API-level fallback');
  const item = { phase, viewport, operation, expected, actual: '', pass: false, screenshot: null }; data.steps.push(item);
  try {
    item.actual = await fn() || '全部断言符合预期'; item.pass = true;
    if (phase === 'screenshots' && screenshot) {
      item.screenshot = `screenshots/${String(++number).padStart(2, '0')}-${viewport}-${screenshot}.png`;
      await page.screenshot({ path: path.join(out, item.screenshot), animations: 'disabled' });
    }
  } catch (error) {
    item.actual = String(error.stack || error);
    if (page) { item.screenshot = `screenshots/${Date.now()}-失败.png`; await page.screenshot({ path: path.join(out, item.screenshot) }).catch(() => {}); }
    throw error;
  } finally { console.log(JSON.stringify(item)); writeFileSync(path.join(out, smokeOnly ? 'smoke-steps.jsonl' : 'steps.jsonl'), JSON.stringify(item) + '\n', { flag: 'a' }); save(); }
}
async function smoke() {
  await step('SDK失败夹具独立冒烟','发布与刷新错误可重复触发，解除后恢复透传',async()=>{
    const fixture={publishError:true,refreshError:true};let published=0,refreshed=0;
    const handle=withScreenFailures({publishScreenTrack:async()=>published++,refresh:async()=>refreshed++},fixture);
    for(let i=0;i<3;i++){await assert.rejects(handle.publishScreenTrack(),/Fixture SDK publish failure/);await assert.rejects(handle.refresh(),/Fixture SDK refresh failure/);}
    assert.equal(published,0);assert.equal(refreshed,0);fixture.publishError=false;fixture.refreshError=false;fixture.publishDenied=true;await assert.rejects(handle.publishScreenTrack(),e=>e.name==='PublishTrackError'&&e.status===403);fixture.publishDenied=false;
    await handle.publishScreenTrack();await handle.refresh();assert.equal(published,1);assert.equal(refreshed,1);
  });
  await step('夹具入会与延迟配置', '配置延迟可单独触发且字段有效', async () => {
    assert.equal((await rpc('smoke', 'room_join')).status, 200); await control('smoke', { configDelay: 120 }); const time = Date.now();
    assert.deepEqual((await rpc('smoke', 'room_screen_config')).data.value, { iceServers: [] }); assert.ok(Date.now() - time >= 100);
  });
  await step('夹具权限与共享失败', 'ICE配置503、共享信令503、无成员403、离会503', async () => {
    await control('smoke', { configError: true, denySignal: true, leaveError: true });
    for (const [command, status] of [['room_screen_config', 503], ['room_screen_signal', 503], ['room_leave', 503]]) assert.equal((await rpc('smoke', command)).status, status);
    assert.equal((await rpc('outsider', 'room_screen_config')).status, 403);
  });
  await step('夹具信令与终态', '共享版本有效、定向事件、移除和结束均可稳定产出', async () => {
    await rpc('peer', 'room_join'); await control('smoke', { configError: false, denySignal: false });
    const sessionId = (await rpc('smoke', 'room_screen_start')).data.value.sessionId;
    assert.equal((await rpc('peer', 'room_screen_signal', { sessionId, targetId: 'smoke', kind: 'ready', payload: '' })).status, 200);
    const batch = await fetch(backend.base + '/events?session=smoke').then(r => r.json()); assert.ok(batch.some(e => e.type === 'screen_signal'));
    await control('peer', { removed: true }); assert.ok((await fetch(backend.base + '/events?session=peer').then(r => r.json())).some(e => e.type === 'connection_state'));
    await control('smoke', { ended: true }); assert.ok((await fetch(backend.base + '/events?session=smoke').then(r => r.json())).some(e => e.type === 'room_ended'));
  });
  await control('host', { reset: true });
}
const ui = 'http://127.0.0.1:3188';
async function wait(fn, ms = 18000) { const end = Date.now() + ms; while (Date.now() < end) { if (await fn()) return; await new Promise(resolve => setTimeout(resolve, 100)); } throw Error('Expected state timed out'); }
async function newPage(session, width, height) {
  const context = await browser.newContext({ viewport: { width, height }, locale: 'zh-CN',permissions:['camera','microphone'] }); contexts.push(context);
  await context.addInitScript(installLayoutBridge, { base: backend.base, session }); await context.addInitScript(installMeetingBridge, { base: backend.base, session });
  await context.addInitScript(installRtcCamera);
  await context.addInitScript(({base})=>{window.__rtcBackend=base;},{base:backend.base});
  const p = await context.newPage(); p.setDefaultTimeout(30000);
  p.on('response',async response=>{
    if(response.status()<400||!response.url().includes('/rtc/'))return;
    const body=await response.json().catch(()=>({}));
    writeFileSync(path.join(out,'rtc-http-errors.jsonl'),JSON.stringify({session,status:response.status(),path:new URL(response.url()).pathname,code:body.code,message:body.message,reason:body.details?.reason})+'\n',{flag:'a'});
  });
  const cdp = await context.newCDPSession(p); await cdp.send('Runtime.enable');
  await cdp.send('Debugger.enable');
  cdp.on('Debugger.scriptFailedToParse', details => {
    void cdp.send('Debugger.getScriptSource', { scriptId: details.scriptId }).then(source => writeFileSync(path.join(out, `failed-script-${Date.now()}.js`), source.scriptSource)).catch(() => {});
  });
  cdp.on('Runtime.exceptionThrown', details => writeFileSync(path.join(out, 'runtime-exceptions.jsonl'), JSON.stringify({ session, ...details }) + '\n', { flag: 'a' }));
  p.on('console', msg => { if (['error', 'warning'].includes(msg.type())) writeFileSync(path.join(out, 'browser-console.jsonl'), JSON.stringify({ session, type: msg.type(), message: msg.text(), location: msg.location() }) + '\n', { flag: 'a' }); });
  p.on('pageerror', error => data.steps.push({ phase: 'runtime', operation: '未捕获浏览器异常', expected: '无异常', actual: String(error.stack || error), pass: false, viewport }));
  return p;
}
const share = p => p.getByRole('button', { name: '共享屏幕', exact: true });
const stop = p => p.getByRole('button', { name: '停止共享', exact: true });
async function video(p) {
  const selector = '[data-testid="screen-stage"] video';
  try {
    // A takeover can still show the previous publisher's local preview briefly.
    // Prove this is a remote track before comparing its playback clock.
    const sample = () => p.locator(selector).evaluateAll(items => {
      if(items.length!==1)return null;
      const v=items[0],track=v.srcObject?.getVideoTracks()[0];
      if(!track||window.__shareFixture.captures.includes(track)||track.readyState!=='live'||v.videoWidth<=0||v.currentTime<=0)return null;
      return {id:track.id,time:v.currentTime};
    });
    let baseline;
    await wait(async()=>Boolean(baseline=await sample()),24000);
    await wait(async()=>{
      const current=await sample();if(!current)return false;
      if(current.id!==baseline.id){baseline=current;return false;}
      return current.time>baseline.time+0.1;
    });
    const first=baseline.time;
    let pixel;
    await wait(async()=>{pixel=await p.locator(selector).evaluate(v => { const c = document.createElement('canvas'); c.width = 960; c.height = 540; c.getContext('2d').drawImage(v, 0, 0); return [...c.getContext('2d').getImageData(5, 5, 1, 1).data]; });return pixel[0]>75&&pixel[1]<70&&pixel[2]>100&&pixel[3]===255;});
    return `远端动态视频（实际尺寸已非零），currentTime从${first.toFixed(2)}继续前进，共享专属紫色像素${pixel.join(',')}`;
  } catch (error) {
    const diagnostic = await Promise.all(contexts.flatMap(c=>c.pages()).map(active=>active.evaluate(async () => ({
      session:window.__shareFixture?.session,frames:window.__shareFixture?.frames,visibility:document.visibilityState,
      videos: [...document.querySelectorAll('[data-testid="screen-stage"] video')].map(v => ({width:v.videoWidth,height:v.videoHeight,time:v.currentTime,paused:v.paused,readyState:v.readyState,tracks:v.srcObject?.getTracks().map(t=>({id:t.id,state:t.readyState,muted:t.muted}))})),
      peers: await Promise.all((window.__shareFixture?.peers||[]).map(async pc => ({connection:pc.connectionState,ice:pc.iceConnectionState,signaling:pc.signalingState,stats:pc.connectionState==='closed'?[]:[...(await pc.getStats()).values()].filter(s=>['inbound-rtp','outbound-rtp'].includes(s.type))}))),
    }))));
    writeFileSync(path.join(out, `video-failure-${Date.now()}.json`), JSON.stringify(diagnostic,null,2));
    throw error;
  }
}
async function layout(p = page) {
  const issues = await p.evaluate(() => {
    const issues = []; if (document.documentElement.scrollWidth > innerWidth + 1) issues.push('横向溢出');
    for (const el of document.querySelectorAll('[role="dialog"],[data-testid="return-meeting"],[data-testid="room-side-panel"],[data-testid="room-toolbar-region"]')) {
      if (!el.getClientRects().length) continue; const rect = el.getBoundingClientRect();
      if (rect.x < -1 || rect.right > innerWidth + 1 || rect.top < -1 || rect.bottom > innerHeight + 1) issues.push(el.getAttribute('data-testid') || 'dialog');
    } return issues;
  }); assert.deepEqual(issues, []);
}
async function join(p) {
  page = p;
  await p.goto(ui, { waitUntil: 'domcontentloaded', timeout: 60000 });
  await p.getByRole('button', { name: /加入会议/ }).first().click();
  const dialog = p.getByRole('dialog');
  for (let i = 0; i < 6; i++) await dialog.getByRole('textbox', { name: `第 ${i + 1} 位` }).fill('654321'[i]);
  for (const box of await dialog.getByRole('switch').all()) if (await box.getAttribute('aria-checked') === 'true') await box.click();
  await dialog.getByRole('button', { name: '加入会议', exact: true }).click();
  await p.getByTestId('minimize-meeting').waitFor(); await share(p).waitFor();
}
async function exercise(width, height) {
  viewport = `${width}×${height}`; await control('host', { reset: true });
  const startCalls = backend.calls.length;
  page = await newPage('host', width, height); const host = page;
  await step('真实页面入会并显示空共享态', '通过首页加入弹窗进入会议，尚无共享舞台', async () => { await join(host); assert.equal(await host.getByTestId('screen-stage').count(), 0); await layout(); }, '入会成功无共享');
  const peer = await newPage('peer', width, height);

  await step('第二位用户加入', '两个成员可见且加入接口每人仅一次', async () => { await join(peer); await wait(() => host.getByTestId('participant-tile').count().then(n => n === 2)); });
  await step('SDK媒体连接前置检查','两端SDK均确认频道媒体已连接',async()=>{
    for(const p of [host,peer])await wait(async()=>{const state=await p.evaluate(()=>window.__shareFixture.mediaState);if(state?.status==='error')throw Error('RTC SDK: '+JSON.stringify(state));return state?.status==='connected';},20000);
  });
  await step('权限拒绝确定性路径', '取消采集提示可见，无共享所有权、无视频', async () => {
    await host.evaluate(() => window.__shareFixture.denied = true); await share(host).click(); await host.getByTestId('screen-status').filter({ hasText: '取消' }).waitFor();
    assert.ok(!(await rpc('host', 'room_get')).data.value.participants.some(p => p.screenSharing)); await layout();
  }, '共享权限拒绝');
  await step('采集选择异步状态', '选择中有提示与取消入口', async () => {
    await host.evaluate(() => { window.__shareFixture.denied = false; window.__shareFixture.choosing = true; }); await share(host).click();
    await host.getByRole('button', { name: '取消共享', exact: true }).waitFor(); await layout();
  }, '共享选择加载');
  await step('SDK视频通道共享发布与接收', '补丁SDK发布屏幕轨道，经本轮RTC服务接收动态画面', async () => {
    await host.evaluate(() => { window.__shareFixture.choosing = false; window.__shareFixture.release(); }); await stop(host).waitFor(); const actual = await video(peer); await layout(peer); return actual;
  });
  await step('摄像头与屏幕同时发布','远端同时解码摄像头和屏幕，停止共享后摄像头继续',async()=>{
    await host.getByRole('button',{name:'已关闭',exact:true}).click();
    await wait(async()=>{const error=await host.evaluate(()=>window.__shareFixture.cameraError);if(error)throw Error('Camera fixture: '+JSON.stringify(error));return peer.locator('[data-testid="participant-tile"] video').evaluateAll(v=>v.some(x=>x.videoWidth>0&&x.currentTime>0));},18000);
    await video(peer);await layout(peer);
  });
  await step('摄像头独立开关不影响第二视频共享','摄像头关闭及恢复时，共享保持远端动态画面',async()=>{
    await host.getByRole('button',{name:'摄像头',exact:true}).click();await host.getByRole('button',{name:'已关闭',exact:true}).waitFor();await video(peer);
    await host.getByRole('button',{name:'已关闭',exact:true}).click();await host.getByRole('button',{name:'摄像头',exact:true}).waitFor();await video(peer);
    await wait(()=>peer.locator('[data-testid="participant-tile"] video').evaluateAll(v=>v.some(x=>x.videoWidth>0&&x.currentTime>0)));
  });
  page = peer;
  await step('接收端共享画面' , '观看者显示动态屏幕', async () => video(peer), '远端接收成功');
  await step('取消接管保留观看','取消自己的选屏后仍接收原共享，无新共享所有权',async()=>{
    await peer.evaluate(()=>window.__shareFixture.denied=true);await share(peer).click();
    await peer.getByTestId('screen-status').filter({hasText:'取消'}).waitFor();await video(peer);
    assert.equal((await rpc('peer','room_get')).data.value.participants.find(p=>p.screenSharing)?.id,'host');
    await peer.evaluate(()=>window.__shareFixture.denied=false);
  },'取消接管继续观看');
  await step('共享者回首页后继续发布', '发布者导航不停止采集，接收端视频仍前进', async () => {
    const id = await host.locator('[data-testid="screen-stage"] video').evaluate(v => v.srcObject.getVideoTracks()[0].id);
    await host.getByTestId('minimize-meeting').click(); await host.getByTestId('return-meeting').waitFor(); await video(peer);
    await host.getByTestId('return-meeting').click(); await stop(host).waitFor();
    assert.equal(await host.locator('[data-testid="screen-stage"] video').evaluate(v => v.srcObject.getVideoTracks()[0].id), id);
  });
  await step('回首页并保留共享', '横幅出现，媒体未离开，track保持live，join不增加', async () => {
    await peer.getByTestId('minimize-meeting').click(); await peer.getByTestId('return-meeting').waitFor(); await layout(peer);
    const content = await peer.getByTestId('desktop-content').boundingBox(), banner = await peer.getByTestId('return-meeting').boundingBox();
    assert.ok(content.y + content.height <= banner.y, '会议入口必须位于内容区域之外');
    assert.equal(backend.calls.slice(startCalls).filter(c => c.session === 'peer' && c.command === 'room_join').length, 1);
    assert.equal(backend.calls.slice(startCalls).filter(c => c.session === 'peer' && ['room_leave', 'room_signal_disconnect'].includes(c.command)).length, 0);
    await video(peer);
  }, '首页返回会议入口');
  await step('另一会议入会保护', '尝试新会议号回到原会议且不再次join', async () => {
    await peer.getByRole('button', { name: /加入会议/ }).first().click();
    const dialog = peer.getByRole('dialog'); for (let i = 0; i < 6; i++) await dialog.getByRole('textbox', { name: `第 ${i + 1} 位` }).fill('123456'[i]);
    await dialog.getByRole('button', { name: '加入会议', exact: true }).click();
    await peer.getByText('你已在会议中，请先离开当前会议再加入其他会议。', { exact: true }).waitFor(); await peer.waitForURL('**/room?code=654321');
    assert.equal(backend.calls.slice(startCalls).filter(c => c.session === 'peer' && c.command === 'room_join').length, 1);
    await peer.getByTestId('minimize-meeting').click(); await peer.getByTestId('return-meeting').waitFor();
    await peer.locator('button[data-close-button]').evaluateAll(buttons => buttons.forEach(b => b.click()));
  });
  await step('打开设置后返回会议', '真实路由切换后保留原始接收轨道', async () => {
    const track = await peer.locator('[data-testid="screen-stage"] video').evaluate(v => v.srcObject.getVideoTracks()[0].id);
    await peer.getByRole('button', { name: '设置', exact: true }).click(); await peer.waitForURL('**/settings'); await peer.getByTestId('return-meeting').click(); await peer.waitForURL('**/room?code=654321');
    await video(peer); assert.equal(await peer.locator('[data-testid="screen-stage"] video').evaluate(v => v.srcObject.getVideoTracks()[0].id), track); await layout(peer);
  }, '跨页返回共享继续');
  await step('成员抽屉打开滚动', '打开真实成员面板，长姓名可访问，侧栏无越界', async () => {
    for (let i = 0; i < 14; i++) await rpc('member-' + i, 'room_join');
    await wait(() => peer.getByTestId('participant-tile').count().then(n => n === 16));
    await peer.getByRole('button', { name: '成员', exact: true }).click(); const panel = peer.getByTestId('room-side-panel'); await panel.waitFor();
    const list = panel.locator('.overflow-y-auto'); await list.hover(); await peer.mouse.wheel(0, 900);
    await wait(() => list.evaluate(el => el.scrollTop > 0)); await layout(peer);
  }, '成员抽屉');
  await step('抽屉关闭后长消息真实滚动', '关闭成员抽屉，聊天长文本可滚动，无横向溢出', async () => {
    await peer.getByTestId('room-side-panel').getByRole('button', { name: '关闭', exact: true }).click();
    for (let i = 0; i < 14; i++) await rpc('member-' + i, 'room_leave');
    await peer.getByRole('button', { name: '聊天', exact: true }).click();
    const input = peer.getByPlaceholder('发送消息，全体成员可见');
    for (let i = 0; i < 8; i++) {
      await input.fill(`消息${i}：` + '长文本LongContent0123456789'.repeat(8));
      await peer.getByTestId('room-side-panel').getByRole('button', { name: '发送', exact: true }).click();
      await wait(() => input.inputValue().then(value => value === ''));
    }
    const list = peer.getByTestId('room-side-panel').locator('.overflow-y-auto');
    await wait(() => list.evaluate(el => el.scrollHeight > el.clientHeight && el.scrollTop > 0));
    const before = await list.evaluate(el => el.scrollTop); await list.hover(); await peer.mouse.wheel(0, -500); await wait(() => list.evaluate(el => el.scrollTop).then(top => top < before)); await layout(peer);
  }, '长消息抽屉滚动');
  await step('会中聊天返回首页停止已读', '会议保持连接，隐藏的聊天面板不再标记已读', async () => {
    await peer.getByTestId('minimize-meeting').click(); await peer.getByTestId('return-meeting').waitFor();
    await wait(()=>peer.evaluate(()=>window.__layoutIm.chatCalls.filter(c=>c.operation==='viewing').at(-1)?.visible===false));
    const readCount=()=>peer.evaluate(()=>window.__layoutIm.chatCalls.filter(c=>c.operation==='read').length);
    const before=await readCount(); await peer.evaluate(()=>window.__meetingFixture.control({unread:3}));
    await wait(()=>peer.evaluate(()=>window.__layoutIm.unread===3)); assert.equal(await readCount(),before);
    await peer.getByTestId('return-meeting').click(); await peer.waitForURL('**/room?code=654321');
    assert.equal(backend.calls.slice(startCalls).filter(c => c.session === 'peer' && c.command === 'room_join').length,1);
  });
  await step('关闭抽屉并打开只读设置', '成员会中设置为只读，无保存权限', async () => {
    await peer.getByTestId('room-side-panel').getByRole('button', { name: '关闭', exact: true }).click();
    await peer.getByRole('button', { name: '更多', exact: true }).click(); await peer.getByRole('menuitem', { name: '设置', exact: true }).click();
    await peer.getByRole('dialog').getByText('仅主持人可以修改会议设置。', { exact: true }).waitFor(); await layout(peer);
  }, '会中设置权限弹窗');
  await peer.keyboard.press('Escape');
  await step('关闭弹窗与停止共享', '生产画面关闭浮层，停止后两端舞台移除、采集结束', async () => {
    await peer.getByRole('dialog').waitFor({ state: 'hidden' });
    await host.evaluate(()=>window.__shareFixture.media.screen.setConnection(false));
    await stop(host).click(); await peer.getByTestId('screen-stage').waitFor({ state: 'hidden' });
    await host.evaluate(()=>window.__shareFixture.media.screen.setConnection(true));
    assert.equal(await host.evaluate(() => window.__shareFixture.captures.every(t => t.readyState === 'ended')), true); await layout(peer);
  }, '共享停止空态');
  page=host;
  await step('平台屏幕来源权限拒绝','权限拒绝明确展示，回滚共享且摄像头仍可播放',async()=>{
    await host.evaluate(()=>window.__shareFixture.publishDenied=true);await share(host).click();
    await host.getByText('会议服务未授予屏幕发布权限，请联系管理员。',{exact:true}).waitFor();
    await wait(async()=>!(await rpc('host','room_get')).data.value.participants.some(p=>p.screenSharing));
    await share(host).waitFor();
    await wait(()=>peer.locator('[data-testid="participant-tile"] video').evaluateAll(v=>v.some(x=>x.videoWidth>0&&x.currentTime>0)));
    await host.evaluate(()=>window.__shareFixture.publishDenied=false);
  },'平台屏幕发布权限拒绝');
  await step('SDK发布失败回滚', '发布接口确定性拒绝，采集停止且共享所有权回滚', async()=>{
    await host.evaluate(()=>window.__shareFixture.publishError=true);await share(host).click();
    await host.getByTestId('screen-status').waitFor();
    await wait(async()=>!(await rpc('host','room_get')).data.value.participants.some(p=>p.screenSharing));
    await share(host).waitFor();
    assert.equal(await host.evaluate(()=>window.__shareFixture.captures.every(t=>t.readyState==='ended')),true);
  },'发布失败回滚');
  await step('发布失败后重新共享', '解除故障可重新发布，摄像头与共享相互独立',async()=>{
    await host.evaluate(()=>window.__shareFixture.publishError=false);await share(host).click();await stop(host).waitFor();await video(peer);
  });
  page=peer;
  await step('接收连接失败确定性路径', '真实RTC会话保留，连接错误和重试入口可见',async()=>{
    await peer.evaluate(()=>{const f=window.__shareFixture;f.media.screen.setConnection(false);f.refreshError=true;});
    await peer.getByRole('button',{name:'重试共享',exact:true}).waitFor({timeout:16000});await layout(peer);
  },'共享连接失败');
  await step('重试失败明确展示', '刷新失败保持错误提示，不伪装接收成功',async()=>{
    await peer.getByRole('button',{name:'重试共享',exact:true}).click();await peer.getByRole('button',{name:'重试共享',exact:true}).waitFor();
  });
  await step('重试恢复共享', '恢复SDK连接状态后实际接收动态视频',async()=>{
    await peer.evaluate(()=>{const f=window.__shareFixture;f.refreshError=false;f.media.screen.setConnection(true);});await video(peer);
  },'共享重试恢复');
  await step('共享中晚加入', '第三端实际接收当前屏幕', async () => {
    const before=await host.evaluate(()=>window.__shareFixture.peers.length);
    const late = await newPage('late', width, height); await join(late); await video(late);assert.equal(await host.evaluate(()=>window.__shareFixture.peers.length),before,'新增观看者不得增加发布者PeerConnection'); await late.getByRole('button', { name: '离开会议', exact: true }).click(); await late.getByTestId('return-meeting').waitFor({ state: 'hidden' });
  });
  await step('共享替换与旧采集清理', '成员接管后主持人旧采集停止；反向动态视频可解码', async () => {
    await share(peer).click(); await stop(peer).waitFor(); await video(host);
    assert.equal(await host.evaluate(() => window.__shareFixture.captures.every(t => t.readyState === 'ended')), true);
    await stop(peer).click(); await host.getByTestId('screen-stage').waitFor({ state: 'hidden' });
    await share(host).click(); await stop(host).waitFor(); await video(peer);
  });
  await step('离会失败保留当前会话', '显示真实错误并保持可重试', async () => {
    await control('peer', { leaveError: true }); await peer.getByRole('button', { name: '离开会议', exact: true }).click(); await peer.getByText('夹具：离会失败，请重试', { exact: true }).waitFor(); await video(peer);
  }, '离会失败保留');
  await step('离会成功释放返回入口', '离会成功回首页，入口移除，不自动重新join', async () => {
    await control('peer', { leaveError: false }); await peer.getByRole('button', { name: '离开会议', exact: true }).click(); await peer.waitForURL(ui + '/');
    await peer.getByTestId('persistent-meeting').waitFor({ state: 'detached' }); assert.equal(await peer.getByTestId('return-meeting').count(), 0);
    assert.equal(backend.calls.slice(startCalls).filter(c => c.session === 'peer' && c.command === 'room_join').length, 1); await layout(peer);
  }, '离会成功');
  await step('被移除错误态清理', '重新入会后被移除，停止接收且返回首页无残留入口', async () => {
    await join(peer); await video(peer); await control('peer', { removed: true }); await peer.getByText('你已无权访问此会议', { exact: true }).waitFor();
    await peer.getByRole('button', { name: '返回', exact: true }).click(); await peer.waitForURL(ui + '/');
    await peer.getByTestId('persistent-meeting').waitFor({ state: 'detached' }); assert.equal(await peer.getByTestId('return-meeting').count(), 0);
  });
  page = host;
  await step('后台会议结束清理', '离开会议页时收到结束事件，入口和采集均释放', async () => {
    await host.getByTestId('minimize-meeting').click(); await host.getByTestId('return-meeting').waitFor(); await control('host', { ended: true });
    await host.getByTestId('persistent-meeting').waitFor({ state: 'detached' }); assert.equal(await host.getByTestId('return-meeting').count(), 0);
    assert.equal(await host.evaluate(() => window.__shareFixture.captures.every(t => t.readyState === 'ended')), true);
  });
  assert.equal(backend.calls.slice(startCalls).filter(c=>['room_screen_config','room_screen_signal'].includes(c.command)).length,0,'新客户端不能调用旧P2P信令');
  for (const context of contexts) await context.close(); contexts = []; page = null;
}
try {
  if (!smokeOnly && existsSync(resultPath)) {
    const old = JSON.parse(readFileSync(resultPath, 'utf8')), history = existsSync(path.join(out, 'attempts.json')) ? JSON.parse(readFileSync(path.join(out, 'attempts.json'), 'utf8')) : [];
    history.push(old); writeFileSync(path.join(out, 'attempts.json'), JSON.stringify(history, null, 2));
  }
  await smoke();
  if (!smokeOnly) {
    for (const port of [3118, 39110, 9256, 9257, 3188, 3177]) data.probe.push({ port, status: await fetch(`http://127.0.0.1:${port}/${port === 9256 || port === 9257 ? 'json/version' : ''}`, { signal: AbortSignal.timeout(2000) }).then(r => r.status).catch(() => '不可连接') });
    assert.equal(data.probe.find(x => x.port === 3188).status, '不可连接');
    assert.equal(data.probe.find(x => x.port === 3177).status, '不可连接');
    data.transport=localRtc?'本地LiveKit SFU + 真实补丁SDK media provider；IM频道控制面替代':'已部署IM RTC + 真实补丁SDK';
    const rtcLog=openSync(path.join(out,'rtc-server.log'),'a');
    const python=process.env.OPENMEETING_TEST_PYTHON||testPython();
    if(localRtc){
      assert.equal(await fetch('http://127.0.0.1:7880',{signal:AbortSignal.timeout(1000)}).then(()=>true).catch(()=>false),false);
      localServer=spawn(process.env.OPENMEETING_TEST_LIVEKIT||path.join(root,'.artifacts/tools/livekit/livekit-server.exe'),['--dev','--bind','127.0.0.1'],{cwd:root,windowsHide:true,stdio:['ignore',rtcLog,rtcLog]});
      await wait(()=>fetch('http://127.0.0.1:7880').then(r=>r.ok).catch(()=>false),15000);
    }else{
      rtcServer=spawn(python,[path.join(root,'tests/e2e/fixtures/im-rtc-screen-server.py')],{cwd:root,env:{...process.env,OPENMEETING_RTC_TEST_ENV:process.env.OPENMEETING_RTC_TEST_ENV||path.join(root,'server/.env')},windowsHide:true,stdio:['ignore',rtcLog,rtcLog]});
      await wait(()=>fetch('http://127.0.0.1:3177/health').then(r=>r.ok).catch(()=>false),20000);
    }
    const log = openSync(path.join(out, 'dev-server.log'), 'a');
    const distDir = `.next-e2e-meeting-session-${started}`;
    data.startup += ` 本轮独立缓存：${distDir}。`;
    next = spawn(process.execPath, ['-e', `process.on('message',()=>process.exit(0));require(${JSON.stringify(require.resolve('next/dist/server/lib/start-server'))}).startServer({dir:${JSON.stringify(frontend)},isDev:true,hostname:'127.0.0.1',port:3188,allowRetry:false})`], { cwd: frontend, env: { ...process.env, OPENMEETING_NEXT_DIST_DIR: distDir, OPENMEETING_E2E_DESKTOP_LAYOUT: '1', OPENMEETING_E2E_IM_RTC_SCREEN: localRtc?'local':'1', NEXT_PUBLIC_LIVE_MEETING_DATA_SOURCE: 'real' }, windowsHide: true, stdio: ['ignore', log, log, 'ipc'] });
    await wait(() => fetch(ui + '/brand-logo.png').then(r => r.ok).catch(() => false), 60000);
    // Finish initial compilation before the first browser loads shared chunks.
    await fetch(ui + '/');
    browser = await chromium.launch({ headless: true, args: ['--use-fake-device-for-media-stream','--autoplay-policy=no-user-gesture-required', '--disable-background-timer-throttling', '--disable-backgrounding-occluded-windows', '--disable-renderer-backgrounding'] });
    phase = 'assertions'; for (const size of [[1280, 800], [640, 600]]) await exercise(...size);
    assert.equal(data.steps.filter(x => !x.pass).length, 0);
    phase = 'screenshots'; for (const size of [[1280, 800], [640, 600]]) await exercise(...size);
  }
} catch (error) { data.error = String(error.stack || error); console.error(data.error); process.exitCode = 1; }
finally {
  for (const context of contexts) await context.close().catch(() => {});
  if (browser) await browser.close(); data.cleanup.browser = '本次无头浏览器已关闭';
  if (next) { if (next.connected) next.send('shutdown'); await wait(() => next.exitCode !== null || next.signalCode !== null, 10000).catch(()=>next.kill()); data.cleanup.next = await fetch(ui, { signal: AbortSignal.timeout(1000) }).then(() => '端口仍在监听，需检查').catch(() => '本次3188开发服务已关闭'); }
  if(rtcServer){data.cleanup.im=await fetch('http://127.0.0.1:3177/cleanup',{method:'POST'}).then(r=>r.json()).catch(()=>({errors:['cleanup unavailable']}));await fetch('http://127.0.0.1:3177/shutdown',{method:'POST'}).catch(()=>{});await wait(()=>rtcServer.exitCode!==null||rtcServer.signalCode!==null,10000).catch(()=>{rtcServer.kill();});data.cleanup.rtcBroker=rtcServer.exitCode;}
  if(localServer){localServer.kill();await wait(()=>localServer.exitCode!==null||localServer.signalCode!==null,5000).catch(()=>{});data.cleanup.localRtc='本次本地RTC已关闭';}
  await backend.close(); data.cleanup.fixture = '本次HTTP夹具和其回退夹具已关闭'; data.cleanup.existing = '未关闭原有3118/39110或开发客户端';
  writeFileSync(tsconfigPath, tsconfigBefore);
  data.elapsedSeconds = Math.round((Date.now() - started) / 1000); save(); if (!smokeOnly) report(); console.log('Artifacts: ' + out);
}
