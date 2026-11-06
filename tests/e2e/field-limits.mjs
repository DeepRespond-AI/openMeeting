import assert from 'node:assert/strict';
import {createRequire} from 'node:module';
import {fileURLToPath} from 'node:url';
import {readFileSync, mkdirSync, writeFileSync} from 'node:fs';
import {createServer} from 'node:http';
import path from 'node:path';

const root=fileURLToPath(new URL('../../',import.meta.url));
const frontend=path.join(root,'frontend'), out=path.join(root,'.artifacts/field-limits');
const require=createRequire(path.join(frontend,'package.json'));
const {build}=require('esbuild'), {chromium}=require('playwright');
const backend=process.env.FIELD_LIMITS_API || 'http://127.0.0.1:43271';
mkdirSync(path.join(out,'screenshots'),{recursive:true});
const report={scope:'真实 React 页面组件 → 真实 FastAPI 路由/Pydantic → 独立 PostgreSQL；网关身份、IM/头像、确定性故障由夹具提供；本次仅字段交互，按受影响路径验证。',checks:[],screenshots:[],cleanup:[]};
function record(operation,expected,actual,pass=true,screenshot=null){
  const row={operation,expected,actual,pass,screenshot};report.checks.push(row);console.log(JSON.stringify(row));
}
const headers={'X-User-ID':'field-user','X-User-Name':'field-user','X-Session-ID':'field-session','Content-Type':'application/json'};
async function request(service, route, method='GET', body){
  const r=await fetch(`${backend}/${service}/api/v1/${route}`,{method,headers,body:body===undefined?undefined:JSON.stringify(body)});
  return {status:r.status,body:await r.json()};
}
async function mode(value){await fetch(`${backend}/fixture/mode/${value}`,{method:'POST'});}
const fixture=`
import {useEffect,useState} from 'react';
function refresh(){window.dispatchEvent(new Event('fixture-refresh'));}
function subscribe(){const [,set]=useState(0);useEffect(()=>{const f=()=>set(v=>v+1);window.addEventListener('fixture-refresh',f);return()=>window.removeEventListener('fixture-refresh',f);},[]);}
export function useServer(){subscribe();return {user:window.store.user,loggedIn:true,updateProfile:async name=>{const r=await fetch('/api/user/auth/me',{method:'PATCH',headers:{'Content-Type':'application/json'},body:JSON.stringify({name})});const body=await r.json();if(!r.ok)throw Error(body.detail);window.store.user=body;refresh();}};}
export function useSidebar(){subscribe();return {currentMeeting:null,meetings:window.store.meetings,sidebarItems:[{id:'meetings',children:window.store.meetings}],searchResults:[],isSearching:false,searchTranscripts:async()=>{},setCurrentMeeting:()=>{},setMeetings:value=>{window.store.meetings=value;refresh();}};}
export const useRouter=()=>({push:()=>{}});
export async function invoke(command,args){if(command!=='api_save_meeting_title')throw Error('unexpected command '+command);const r=await fetch('/api/meeting/meetings/'+args.meetingId,{method:'PATCH',headers:{'Content-Type':'application/json'},body:JSON.stringify({title:args.title})});const body=await r.json();if(!r.ok)throw Error(typeof body.detail==='string'?body.detail:JSON.stringify(body.detail));return body;}
export function ImUserAvatar({name}){return <span className="rounded-full bg-primary/20 p-3">{Array.from(name||'用')[0]}</span>;}
export function AvatarEditor(){return null;} export function LogoutDialog(){return null;} export function PasswordDialog(){return null;}
export default new Proxy({}, {get:()=>()=>{}});
`;
let browser, server, context, page;
try {
  // Smoke all fixture branches separately before any page/E2E is opened.
  const seeded=await request('meeting','meetings','POST',{title:'字段限制验证会议'});
  assert.equal(seeded.status,201);const meeting=seeded.body;
  await mode('error');const failed=await request('meeting',`meetings/${meeting.id}`,'PATCH',{title:'不应保存'});
  assert.equal(failed.status,503);assert.equal((await request('meeting',`meetings/${meeting.id}/metadata`)).body.title,meeting.title);
  record('独立冒烟：保存失败夹具','503 且数据库原值不变',failed.status);
  await mode('loading');let settled=false;
  const pending=request('meeting',`meetings/${meeting.id}`,'PATCH',{title:'加载后保存'}).then(v=>{settled=true;return v;});
  await new Promise(resolve=>setTimeout(resolve,300));assert.equal(settled,false);
  await mode('normal');assert.equal((await pending).status,200);
  record('独立冒烟：加载夹具','先等待，释放后 200','pending → 200');
  const long=await request('meeting',`meetings/${meeting.id}`,'PATCH',{title:'会'.repeat(51)});
  assert.equal(long.status,422);record('绕过界面发送 51 字标题','422，定位 title',long.body.detail[0].loc);
  const longName=await request('user','auth/me','PATCH',{name:'名'.repeat(33)});
  assert.equal(longName.status,422);record('绕过界面发送 33 字昵称','422，定位 name',longName.body.detail[0].loc);
  await request('meeting',`meetings/${meeting.id}`,'PATCH',{title:meeting.title});
  await request('user','auth/me','PATCH',{name:'测试用户'});

  const blocked=/^(@\/contexts\/ServerContext|@\/components\/sidebar\/SidebarProvider|@\/lib\/analytics|next\/navigation|@tauri-apps\/api\/core|@\/components\/im\/ImUserAvatar|\.\/AvatarEditor|\.\/LogoutDialog|\.\/PasswordDialog)$/;
  const js=await build({absWorkingDir:frontend,stdin:{resolveDir:frontend,sourcefile:'field-limits-preview.tsx',loader:'tsx',contents:`
    import React,{useState} from 'react';import {createRoot} from 'react-dom/client';
    import {MeetingList} from './src/components/MeetingList';import {AccountCard} from './src/components/auth/AccountCard';
    import {I18nProvider} from './src/i18n';import {Toaster,toast} from 'sonner';window.clearToasts=()=>toast.dismiss();
    async function main(){window.store={meetings:[${JSON.stringify(meeting)}],user:await (await fetch('/api/user/auth/me')).json()};
      function App(){const [section,setSection]=useState('meetings');return <I18nProvider><div className="min-h-screen bg-background text-foreground"><nav className="flex gap-3 border-b border-border p-4"><button onClick={()=>setSection('meetings')}>会议记录</button><button onClick={()=>setSection('account')}>账号设置</button></nav><main className="mx-auto max-w-5xl p-3">{section==='meetings'?<div className="h-[650px]"><MeetingList/></div>:<AccountCard/>}</main><Toaster richColors theme="dark"/></div></I18nProvider>;}createRoot(document.getElementById('root')).render(<App/>);}
    main();`},bundle:true,write:false,format:'iife',jsx:'automatic',define:{'process.env.NODE_ENV':'"development"'},plugins:[{name:'boundaries',setup(b){b.onResolve({filter:blocked},a=>({path:a.path,namespace:'fixture'}));b.onLoad({filter:/.*/,namespace:'fixture'},()=>({resolveDir:frontend,contents:fixture,loader:'tsx'}));}}]});
  const config=require(path.join(frontend,'tailwind.config.js'));
  const css=await require('postcss')([require('tailwindcss')({...config,content:[path.join(frontend,'src/**/*.{ts,tsx}').replaceAll('\\','/')]}),require('autoprefixer')])
    .process(readFileSync(path.join(frontend,'src/app/globals.css'),'utf8'),{from:path.join(frontend,'src/app/globals.css')});
  server=createServer(async(req,res)=>{
    try{
      if(req.url.startsWith('/api/')){
        const chunks=[];for await(const chunk of req)chunks.push(chunk);
        const [, ,service,...rest]=req.url.split('/');
        const response=await fetch(`${backend}/${service}/api/v1/${rest.join('/')}`,{method:req.method,headers,body:['GET','HEAD'].includes(req.method)?undefined:Buffer.concat(chunks)});
        res.writeHead(response.status,{'Content-Type':'application/json'});res.end(await response.text());
      }else if(req.url==='/app.js'){res.setHeader('Content-Type','text/javascript');res.end(js.outputFiles[0].text);}
      else if(req.url==='/app.css'){res.setHeader('Content-Type','text/css');res.end(css.css);}
      else{res.setHeader('Content-Type','text/html;charset=utf-8');res.end('<!doctype html><html lang="zh-CN" class="dark"><head><meta name="viewport" content="width=device-width,initial-scale=1"><link rel="stylesheet" href="/app.css"></head><body style="margin:0"><div id="root"></div><script src="/app.js"></script></body></html>');}
    }catch(error){res.writeHead(500);res.end(String(error));}
  });
  await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
  const url=`http://127.0.0.1:${server.address().port}`;
  browser=await chromium.launch({headless:true});
  context=await browser.newContext({locale:'zh-CN',viewport:{width:1440,height:960}});
  await context.addInitScript(()=>{try{localStorage.setItem('dr.locale','zh-CN');}catch{}});
  await context.tracing.start({screenshots:true,snapshots:true,sources:true});
  page=await context.newPage();page.setDefaultTimeout(7000);
  const pageErrors=[];page.on('pageerror',e=>pageErrors.push(e.message));
  const save=()=>page.getByRole('button',{name:'保存',exact:true});
  async function openRename(){await page.getByRole('button',{name:'更多操作',exact:true}).click();await page.getByRole('menuitem',{name:'重命名',exact:true}).click();await page.locator('#meeting-title').waitFor();}
  await page.goto(url);await openRename();
  const input=page.locator('#meeting-title');
  await input.fill('');assert.equal(await save().isDisabled(),true);assert.equal(await page.getByRole('status').filter({hasText:'0/50'}).count(),1);
  record('会议重命名空值','0/50，保存禁用','一致');
  for(const character of ['会','a','😀']){
    await input.fill(character.repeat(51));assert.equal(await input.inputValue(),character.repeat(50));
    assert.equal(await page.getByRole('status').filter({hasText:'50/50'}).count(),1);
    record(`标题边界 ${character}`,'粘贴 51 个码点限制为 50，显示 50/50',Array.from(await input.inputValue()).length);
  }
  await mode('loading');await save().click();await page.waitForFunction(()=>document.querySelector('#meeting-title')?.disabled===true);
  assert.equal(await save().isDisabled(),true);record('标题异步保存','加载中禁用输入和保存按钮','一致');
  await mode('normal');await input.waitFor({state:'hidden'});
  assert.equal((await request('meeting',`meetings/${meeting.id}/metadata`)).body.title,'😀'.repeat(50));
  record('标题成功路径','新标题保存到独立数据库并关闭弹窗','数据库一致');
  await openRename();await input.fill('保存失败后可重试');await mode('error');await save().click();
  await page.getByText('测试夹具：保存失败，请重试',{exact:true}).last().waitFor();
  assert.equal(await input.inputValue(),'保存失败后可重试');assert.equal(await save().isEnabled(),true);
  record('标题失败路径','显示错误，保留草稿，允许重试','一致');
  await mode('normal');await save().click();await input.waitFor({state:'hidden'});record('标题失败后重试','成功保存并关闭弹窗','一致');
  await page.getByRole('button',{name:'账号设置',exact:true}).click();
  const editName=()=>page.getByRole('button',{name:'修改昵称'});
  await editName().click();const nickname=page.getByRole('textbox',{name:'修改昵称'});
  for(const character of ['名','a','😀']){await nickname.fill(character.repeat(33));assert.equal(await nickname.inputValue(),character.repeat(32));record(`昵称边界 ${character}`,'33 个码点限制为 32，显示 32/32',Array.from(await nickname.inputValue()).length);}
  await save().click();await nickname.waitFor({state:'hidden'});
  assert.equal((await request('user','auth/me')).body.name,'😀'.repeat(32));record('账号昵称成功路径','32 字昵称保存到真实用户接口和数据库','一致');
  await editName().click();await nickname.fill('失败后保留昵称');await mode('error');await save().click();
  await page.getByText('测试夹具：保存失败，请重试',{exact:true}).last().waitFor();assert.equal(await nickname.inputValue(),'失败后保留昵称');
  record('账号昵称失败路径','显示错误并保留昵称草稿','一致');await mode('normal');await save().click();await nickname.waitFor({state:'hidden'});
  assert.deepEqual(pageErrors,[]);record('浏览器运行时异常','0',pageErrors.length);

  // All assertions above pass before screenshot replay. Visual verdicts are added only after inspection.
  let step=0;
  async function clearToasts(){await page.evaluate(()=>window.clearToasts());await page.waitForFunction(()=>!document.querySelector('[data-sonner-toast]'));}
  async function shot(label,viewport){
    await page.evaluate(async()=>{await Promise.all(document.getAnimations().filter(a=>a.effect?.getTiming().iterations!==Infinity).map(a=>a.finished.catch(()=>{})));});
    const file=`${String(++step).padStart(2,'0')}-${viewport}-${label}.png`;await page.screenshot({path:path.join(out,'screenshots',file),fullPage:true});report.screenshots.push({path:`screenshots/${file}`,viewport:page.viewportSize(),state:label,inspected:false});
  }
  for(const [label,viewport] of [['desktop',{width:1440,height:960}],['narrow',{width:390,height:844}]]){
    await clearToasts();await page.setViewportSize(viewport);await page.getByRole('button',{name:'会议记录',exact:true}).click();await shot('正常',label);
    await openRename();await input.fill('');await shot('空标题',label);
    await input.fill('本次迭代会议标题'.repeat(8));await shot('50字上限',label);
    await mode('loading');await save().click();await page.waitForFunction(()=>document.querySelector('#meeting-title')?.disabled===true);await shot('保存中',label);
    await mode('normal');await input.waitFor({state:'hidden'});await shot('成功',label);
    await clearToasts();await openRename();await input.fill('保存失败后可重试');await mode('error');await save().click();await page.getByText('测试夹具：保存失败，请重试',{exact:true}).last().waitFor();await shot('保存错误',label);
    await mode('normal');await page.getByRole('button',{name:'取消',exact:true}).click();
    await clearToasts();await page.getByRole('button',{name:'账号设置',exact:true}).click();await editName().click();await nickname.fill('移动端和桌面端统一昵称边界'.repeat(3));await shot('昵称32字',label);
    await page.getByRole('button',{name:'取消',exact:true}).click();await shot('昵称取消',label);
    assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),true);record(`${label} 页面横向溢出`,'无',false);
  }
  await context.tracing.stop({path:path.join(out,'trace.zip')});
  await context.close();
}catch(error){
  record('执行异常','断言通过',String(error.stack||error),false);process.exitCode=1;
  if(page){writeFileSync(path.join(out,'failure.html'),await page.content());writeFileSync(path.join(out,'failure-text.txt'),await page.locator('body').innerText());await page.screenshot({path:path.join(out,'failure.png'),fullPage:true});}
  if(context)await context.tracing.stop({path:path.join(out,'failure-trace.zip')}).catch(()=>{});
}
finally{
  await mode('normal').catch(()=>{});
  if(browser){await browser.close();report.cleanup.push({service:'headless Chromium',stopped:true});}
  if(server){await new Promise(resolve=>server.close(resolve));report.cleanup.push({service:'React preview HTTP server',stopped:true});}
  writeFileSync(path.join(out,'e2e-results.json'),JSON.stringify(report,null,2));
}
