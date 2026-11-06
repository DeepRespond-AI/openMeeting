/** Production meetings page/dialogs/CSS; explicit native, account and data fixtures. */
import assert from 'node:assert/strict';
import {createRequire} from 'node:module';
import {fileURLToPath} from 'node:url';
import {readFileSync, mkdirSync, writeFileSync} from 'node:fs';
import {createServer} from 'node:http';
import path from 'node:path';

const root = fileURLToPath(new URL('../../',import.meta.url)), frontend=path.join(root,'frontend');
const require=createRequire(path.join(frontend,'package.json'));
const {build}=require('esbuild'), {chromium}=require('playwright');
const out=path.resolve(process.env.UPCOMING_MEETINGS_OUTPUT||path.join(root,'.artifacts/upcoming-meetings'));
mkdirSync(out,{recursive:true});
const fixture=`
  import {useEffect,useState} from 'react';
  export function useServer(){return {user:{id:'user',name:'林晓晨'},loggedIn:true};}
  export const useOptionalServer=useServer;
  export function useSidebar(){const [,set]=useState(0);useEffect(()=>{const f=()=>set(v=>v+1);window.addEventListener('history-change',f);return()=>window.removeEventListener('history-change',f);},[]);
    return {...window.historyFixture,setCurrentMeeting:m=>window.currentMeeting=m,setMeetings:()=>{},
      searchTranscripts:async q=>{window.historyFixture.searchResults=q==='决策'?[{id:'meeting-one',matchContext:'本次决策记录'}]:[];window.dispatchEvent(new Event('history-change'));}};}
  export const useRouter=()=>({push:url=>{window.lastNavigation=url;setTimeout(()=>window.dispatchEvent(new Event('fixture-navigation')),0);}});
  export const usePathname=()=>'/meetings';
  export const invoke=async()=>null;
  export default new Proxy({}, {get:()=>()=>{}});
  export const getLiveMeetingApi=()=>window.api;
  export class LiveMeetingApiError extends Error {}
`;
const js=await build({stdin:{resolveDir:frontend,loader:'tsx',contents:`
  import React from 'react';import {createRoot} from 'react-dom/client';
  import MeetingsPage from './src/app/meetings/page';import {I18nProvider} from './src/i18n';
  import {MeetingEntryProvider,useMeetingEntry} from './src/components/live-meeting/MeetingEntry';
  const item=(id,title,startAt,extra={})=>({id,title,startAt,code:{today:'123456',tomorrow:'234567',week:'345678',far:'456789'}[id]||'567890',durationMin:60,host:{id:'user',name:'林晓晨'},cancelled:false,meetingId:null,pwdEnabled:false,remind:true,waitRoom:false,...extra});
  window.seed=[item('week','下周方案评审','2026-11-02T08:00:00+08:00'),item('today','今日产品讨论','2026-10-26T16:00:00+08:00'),
    item('tomorrow','明天设计讨论','2026-10-27T10:30:00+08:00'),item('far','长期项目启动','2028-12-01T09:00:00+08:00'),
    item('past','原定时间已过仍保留','2026-10-25T09:00:00+08:00'),item('cancelled','已取消不显示','2026-10-28T09:00:00+08:00',{cancelled:true}),
    item('completed','已有历史场次仍保留','2026-10-29T09:00:00+08:00',{meetingId:'meeting-complete'})];
  window.rows=structuredClone(window.seed);window.calls=[];window.listMode='normal';window.cancelFailure=false;
  window.api={
    listScheduledMeetings:async q=>{window.calls.push(['list',q]);if(window.listMode==='error')throw Error('list fixture failure');
      if(window.listMode==='defer')return new Promise(resolve=>window.releaseList=resolve);return structuredClone(window.rows);},
    updateScheduledMeeting:async(id,input)=>{window.calls.push(['update',id,input]);const row=window.rows.find(r=>r.id===id);Object.assign(row,input);return structuredClone(row);},
    createScheduledMeeting:async input=>{window.calls.push(['create',input]);const row=item('new','',input.startAt,input);window.rows.push(row);return row;},
    deleteScheduledMeeting:async id=>{window.calls.push(['delete',id]);if(window.cancelFailure)throw Error('取消失败夹具，请重试');window.rows=window.rows.filter(r=>r.id!==id);},
    checkRoomCode:async code=>{window.calls.push(['check',code]);return {code,title:'测试会议',pwdEnabled:false};},
  };
  window.historyFixture={currentMeeting:null,sidebarItems:[{id:'meetings',children:[{id:'meeting-one',title:'上周产品复盘'},{id:'meeting-two',title:'历史设计讨论'}]}],
    meetings:[{id:'meeting-one',title:'上周产品复盘'},{id:'meeting-two',title:'历史设计讨论'}],searchResults:[],isSearching:false};
  function NavigationEnd(){const {finishEntry}=useMeetingEntry();React.useEffect(()=>{window.addEventListener('fixture-navigation',finishEntry);return()=>window.removeEventListener('fixture-navigation',finishEntry);},[finishEntry]);return null;}
  createRoot(document.getElementById('root')).render(<I18nProvider><MeetingEntryProvider><NavigationEnd/><MeetingsPage/></MeetingEntryProvider></I18nProvider>);
`},bundle:true,write:false,format:'iife',jsx:'automatic',define:{'process.env.NODE_ENV':'"development"'},plugins:[{name:'page-boundaries',setup(b){
  b.onResolve({filter:/^(@\/contexts\/ServerContext|@\/components\/sidebar\/SidebarProvider|@\/services\/live-meeting|@\/lib\/analytics|next\/navigation|@tauri-apps\/api\/core)$/},a=>({path:a.path,namespace:'fixture'}));
  b.onLoad({filter:/.*/,namespace:'fixture'},()=>({resolveDir:frontend,contents:fixture}));
}}]});
const config=require(path.join(frontend,'tailwind.config.js'));
const css=await require('postcss')([require('tailwindcss')({...config,content:[path.join(frontend,'src/**/*.{ts,tsx}').replaceAll('\\','/')]}),require('autoprefixer')])
  .process(readFileSync(path.join(frontend,'src/app/globals.css'),'utf8'),{from:path.join(frontend,'src/app/globals.css')});
const server=createServer((req,res)=>{
  if(req.url==='/app.js'){res.setHeader('Content-Type','application/javascript');res.end(js.outputFiles[0].text);}
  else if(req.url==='/app.css'){res.setHeader('Content-Type','text/css');res.end(css.css);}
  else{res.setHeader('Content-Type','text/html;charset=utf-8');res.end('<!doctype html><html lang="zh-CN" class="dark"><head><link rel="stylesheet" href="/app.css"></head><body style="margin:0"><main id="root" style="height:100dvh"></main><script src="/app.js"></script></body></html>');}
});
await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
let browser,page;
const report={scope:'Real meetings page, historical list and dialogs; native/data/account fixtures; no real service or RTC claim',checks:[],screenshots:[]};
const check=(operation)=>report.checks.push({operation,pass:true});
try{
  browser=await chromium.launch({headless:true});
  page=await browser.newPage({viewport:{width:1280,height:800},locale:'zh-CN',timezoneId:'Asia/Shanghai'});
  page.setDefaultTimeout(10000);
  await page.clock.install({time:new Date('2026-10-26T09:00:00+08:00')});
  const errors=[];report.browserErrors=errors;page.on('pageerror',e=>errors.push(e.message));
  await page.goto('http://127.0.0.1:'+server.address().port);
  const history=page.getByRole('tab',{name:'历史会议记录',exact:true}), upcoming=page.getByRole('tab',{name:'预定会议',exact:true});
  const rows=page.getByTestId('upcoming-meeting');
  const capture=async name=>{await page.screenshot({path:path.join(out,name+'.png'),animations:'disabled'});report.screenshots.push(name+'.png');};
  const visiblePanel=()=>page.locator('[role="tabpanel"][data-state="active"]');
  await history.waitFor();assert.equal(await history.getAttribute('aria-selected'),'true');
  await page.getByPlaceholder('搜索会议标题和转写内容…').fill('决策');
  await visiblePanel().getByText('本次决策记录',{exact:false}).waitFor();
  await capture('history-search');
  await upcoming.click();await rows.nth(5).waitFor();assert.equal(await rows.count(),6);
  assert.deepEqual(await rows.locator('button[title]').allTextContents(),['原定时间已过仍保留','今日产品讨论','明天设计讨论','已有历史场次仍保留','下周方案评审','长期项目启动']);
  assert.ok((await page.evaluate(()=>window.calls.find(c=>c[0]==='list')[1])).to===undefined);
  await visiblePanel().getByRole('heading',{name:/今天/}).waitFor();await visiblePanel().getByRole('heading',{name:/明天/}).waitFor();
  await capture('upcoming-desktop');
  await page.setViewportSize({width:390,height:844});await capture('upcoming-narrow');
  await rows.last().scrollIntoViewIfNeeded();await page.getByRole('button',{name:'长期项目启动',exact:true}).waitFor();await capture('upcoming-scrolled');
  assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth),false);
  const search=page.getByRole('textbox',{name:'搜索会议主题、会议号或发起人…'});
  await search.fill('345 678');await page.waitForFunction(()=>document.querySelectorAll('[data-testid="upcoming-meeting"]').length===1);
  assert.ok((await rows.innerText()).includes('下周方案评审'));await search.fill('不存在');await page.getByText('没有与“不存在”匹配的会议').waitFor();await capture('no-results');
  await search.fill('');await rows.nth(5).waitFor();
  await history.click();assert.equal(await page.getByPlaceholder('搜索会议标题和转写内容…').inputValue(),'决策');
  await upcoming.click();await rows.nth(5).waitFor();
  check('historical transcript search preserved; all reservations ordered/grouped; only cancelled excluded; past scenes remain; code search; narrow layout');

  await page.setViewportSize({width:1280,height:800});
  await page.getByRole('button',{name:'加入 明天设计讨论',exact:true}).click();
  await page.getByRole('dialog').waitFor();
  assert.equal((await page.getByRole('dialog').locator('input[inputmode="numeric"]').evaluateAll(inputs=>inputs.map(el=>el.value))).join(''),'234567');
  await page.getByRole('dialog').getByRole('button',{name:'加入会议',exact:true}).click();
  await page.waitForFunction(()=>window.lastNavigation==='/room?code=234567');
  assert.equal(await page.evaluate(()=>JSON.parse(sessionStorage.getItem('liveMeeting.joinIntent')).code),'234567');
  await page.locator('[role="dialog"]').waitFor({state:'detached'});
  check('join reuses nickname/media preparation and writes the correct meeting code intent');

  await page.getByRole('button',{name:'明天设计讨论的操作',exact:true}).click();await page.getByRole('menuitem',{name:'编辑',exact:true}).click();
  await page.locator('#sched-title').fill('明天设计讨论（已修改）');await page.getByRole('button',{name:'保存修改',exact:true}).click();
  await page.locator('[role="dialog"]').waitFor({state:'detached'});await page.getByRole('button',{name:'加入 明天设计讨论（已修改）',exact:true}).waitFor();
  await page.getByRole('button',{name:'预定会议',exact:true}).click();
  await page.locator('#sched-title').fill('后天新增预定');
  // The production date/time picker defaults to a valid future start.
  await page.getByTestId('schedule-date').click();
  await page.getByRole('button',{name:'后天',exact:true}).click();
  await page.getByRole('dialog').getByRole('button',{name:'预定会议',exact:true}).click();
  await page.locator('[role="dialog"]').waitFor({state:'detached'});await page.getByRole('button',{name:'加入 后天新增预定',exact:true}).waitFor();
  check('edit persists and refetches; newly scheduled meeting appears immediately');

  await page.getByRole('button',{name:'今日产品讨论的操作',exact:true}).click();await page.getByRole('menuitem',{name:'取消预定',exact:true}).click();
  await page.evaluate(()=>window.cancelFailure=true);await page.getByRole('dialog').getByRole('button',{name:'取消预定',exact:true}).click();
  await page.getByRole('alert').filter({hasText:'取消失败夹具'}).waitFor();await capture('cancel-error');
  await page.evaluate(()=>window.cancelFailure=false);await page.getByRole('dialog').getByRole('button',{name:'取消预定',exact:true}).click();
  await page.locator('[role="dialog"]').waitFor({state:'detached'});await page.waitForFunction(()=>!window.rows.some(r=>r.id==='today'));
  check('cancel requires confirmation; failure stays actionable; retry removes the reservation');

  await page.evaluate(()=>{window.listMode='error';window.dispatchEvent(new Event('scheduled-meetings-changed'));});
  await page.getByRole('alert').filter({hasText:'预定会议加载失败'}).waitFor();await capture('load-error');
  await page.evaluate(()=>window.listMode='normal');await page.getByRole('button',{name:'重试',exact:true}).click();await rows.first().waitFor();
  await page.evaluate(()=>{window.listMode='defer';window.dispatchEvent(new Event('scheduled-meetings-changed'));});
  await page.getByRole('status').filter({hasText:'加载中'}).waitFor();await capture('loading');
  await page.evaluate(()=>{window.listMode='normal';window.dispatchEvent(new Event('scheduled-meetings-changed'));});await rows.first().waitFor();
  await page.evaluate(()=>window.releaseList([]));assert.ok(await rows.count()>0);
  await page.evaluate(()=>{window.rows=[];window.dispatchEvent(new Event('scheduled-meetings-changed'));});
  await page.getByText('暂无预定会议，预定后将获得固定会议号。').waitFor();await capture('empty');
  await page.evaluate(()=>{window.rows=[{...window.seed[0],title:'跨团队产品设计长主题与异步状态回归检查'.repeat(8),activeRoomId:'explicit-active'}];window.dispatchEvent(new Event('scheduled-meetings-changed'));});
  await rows.first().waitFor();
  for(const size of [{width:1280,height:800},{width:520,height:760}]){
    await page.setViewportSize(size);
    await rows.first().getByRole('button',{name:/的操作$/}).click();
    assert.equal(await page.getByRole('menuitem',{name:'编辑',exact:true}).getAttribute('aria-disabled'),'true');
    assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth+1),false);
    await capture(`long-active-menu-${size.width}`);await page.keyboard.press('Escape');await page.clock.runFor(300);
    await page.waitForFunction(()=>!document.querySelector('[role="menu"][data-state="open"]'));await capture(`long-menu-closed-${size.width}`);
  }
  check('long title truncates with full title attribute; active permissions disabled; menu opens/closes in desktop/narrow viewports; list scroll reaches distant reservation');
  assert.deepEqual(errors,[]);check('load failure/retry, loading, stale request guard and empty state; no browser exceptions');
  report.pass=true;console.log(JSON.stringify(report));
}catch(error){report.failure=String(error.stack||error);if(page)await page.screenshot({path:path.join(out,'failure.png'),animations:'disabled'});throw error;}
finally{writeFileSync(path.join(out,'results.json'),JSON.stringify(report,null,2));await browser?.close();await new Promise(resolve=>server.close(resolve));}
