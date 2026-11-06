/** Production bubbles/actions, SDK and clipboard boundaries are explicit fixtures. */
import assert from 'node:assert/strict';
import {createRequire} from 'node:module';
import {fileURLToPath} from 'node:url';
import {readFileSync,mkdirSync,writeFileSync} from 'node:fs';
import {createServer} from 'node:http';
import path from 'node:path';
const root=fileURLToPath(new URL('../../',import.meta.url)),front=path.join(root,'frontend');
const require=createRequire(path.join(front,'package.json')),{build}=require('esbuild'),{chromium}=require('playwright');
const out=path.resolve(process.env.CHAT_ACTIONS_OUTPUT||path.join(root,'.artifacts/chat-message-actions/desktop'));
mkdirSync(out,{recursive:true});
const bundle=await build({stdin:{resolveDir:front,loader:'tsx',contents:`
 import React,{useState,useEffect} from 'react';import{createRoot}from'react-dom/client';
 import ChatMessage,{showMessageTime}from'./src/components/im/ChatMessage';import{I18nProvider}from'./src/i18n';import{Toaster}from'sonner';
 window.calls=[];window.failDelete=false;window.failRecall=false;window.expired=false;
 window.update=()=>window.dispatchEvent(new Event('fixture-change'));
 window.messages=[
  {seq:1,sender:'peer',body:{text:'收到，会议资料已更新。'},created_at:new Date(Date.now()-600000).toISOString()},
  {seq:2,sender:'self',body:{text:'2'},created_at:new Date(Date.now()-30000).toISOString()},
  {seq:3,sender:'self',body:{text:'test'},created_at:new Date().toISOString()},
 ].map(m=>({...m,conversation_id:'room-group',conversation_type:'group',sender_type:'user',type:'text',need_receipt:true,client_msg_id:'c'+m.seq,_local:{status:'sent'}}));
 window.client={config:{recall_window_seconds:120},auth:{currentUser:{username:'self'}},messages:{
  canRecall:m=>!window.expired,
  recall:async(id,seq)=>{window.calls.push(['recall',id,seq]);if(window.failRecall)throw Object.assign(Error('server fixture error'),{reason:'recall_window_expired'});
   window.messages=window.messages.map(m=>m.seq===seq?{...m,recalled:{by:'self'}}:m);window.update();},
  deleteForMe:async(id,seqs)=>{window.calls.push(['delete',id,seqs]);if(window.failDelete)throw Error('删除失败，请重试');
   window.messages=window.messages.filter(m=>!seqs.includes(m.seq));window.update();},
  discard:async id=>{window.calls.push(['discard',id]);window.messages=window.messages.filter(m=>m.client_msg_id!==id);window.update();},
  resend:async id=>window.calls.push(['retry',id]),
 }};
 function App(){const[,set]=useState(0);useEffect(()=>{const f=()=>set(v=>v+1);window.addEventListener('fixture-change',f);return()=>window.removeEventListener('fixture-change',f);},[]);
 return <I18nProvider><main style={{height:'100dvh',overflowY:'auto',padding:16}}>{window.messages.map((m,i)=><ChatMessage key={m.client_msg_id} message={m} own={m.sender==='self'} showTime={showMessageTime(m,window.messages[i-1])}/>)}</main><Toaster/></I18nProvider>}
 createRoot(document.getElementById('root')).render(<App/>);
`},bundle:true,write:false,format:'iife',jsx:'automatic',define:{'process.env.NODE_ENV':'"development"','process.env':'{}'},plugins:[{name:'sdk-fixture',setup(b){
 b.onResolve({filter:/^(@deeprespond\/im-web-react|@\/contexts\/IMContext)$/},a=>({path:a.path,namespace:'fixture'}));
 b.onLoad({filter:/.*/,namespace:'fixture'},()=>({contents:`export const useIm=()=>({client:window.client});export const useDRClient=()=>window.client;export const useMe=()=>({username:'self',nickname:'135****3130'});export const useUser=name=>({nickname:name==='self'?'135****3130':'林晓晨'});`}));
}}]});
const config=require(path.join(front,'tailwind.config.js'));
const css=await require('postcss')([require('tailwindcss')({...config,content:[path.join(front,'src/**/*.{ts,tsx}').replaceAll('\\','/')]}),require('autoprefixer')])
 .process(readFileSync(path.join(front,'src/app/globals.css'),'utf8'),{from:path.join(front,'src/app/globals.css')});
const server=createServer((req,res)=>{if(req.url==='/app.js'){res.setHeader('Content-Type','application/javascript');res.end(bundle.outputFiles[0].text);}
 else if(req.url==='/app.css'){res.setHeader('Content-Type','text/css');res.end(css.css);}
 else{res.setHeader('Content-Type','text/html;charset=utf-8');res.end('<!doctype html><html class="dark" lang="zh-CN"><link rel="stylesheet" href="/app.css"><body><div id="root"></div><script src="/app.js"></script></body></html>');}});
await new Promise(r=>server.listen(0,'127.0.0.1',r));
let browser,page;const report={scope:'Production shared desktop messages and menus; SDK/clipboard fixtures',checks:[],screenshots:[]};
const check=operation=>report.checks.push({operation,pass:true});
try{
 browser=await chromium.launch({headless:true});page=await browser.newPage({viewport:{width:390,height:780},locale:'zh-CN'});page.setDefaultTimeout(10000);
 const errors=[];report.errors=errors;page.on('pageerror',e=>{errors.push(e.message);console.error('Browser:',e.message);});
 await page.addInitScript(()=>Object.defineProperty(navigator,'clipboard',{value:{writeText:async text=>window.copied=text}}));
 await page.goto('http://127.0.0.1:'+server.address().port);const row=seq=>page.getByTestId('im-meeting-message').nth(seq-1);
 const shot=async name=>{await page.screenshot({path:path.join(out,name+'.png'),animations:'disabled'});report.screenshots.push(name+'.png');};
 await row(3).waitFor();assert.equal(await page.locator('[aria-label="已发送"]').count(),0);
 const incoming=await row(1).getByTestId('message-bubble').boundingBox(),own=await row(2).getByTestId('message-bubble').boundingBox();
 assert.ok(own.x>incoming.x);assert.equal(await row(2).getByTestId('message-bubble').innerText(),'2');
 await shot('bubbles-narrow');
 await page.setViewportSize({width:1280,height:800});await shot('bubbles-desktop');await page.setViewportSize({width:390,height:780});
 await row(2).getByRole('button',{name:'消息操作'}).click();
 assert.deepEqual(await page.getByRole('menuitem').allTextContents(),['复制','删除','撤回']);await shot('menu');
 await page.getByRole('menuitem',{name:'复制',exact:true}).click();assert.equal(await page.evaluate(()=>window.copied),'2');
 await row(1).getByRole('button',{name:'消息操作'}).click();assert.deepEqual(await page.getByRole('menuitem').allTextContents(),['复制','删除']);await page.getByRole('menuitem',{name:'复制',exact:true}).click();await page.getByRole('menu').waitFor({state:'detached'});
 check('blue own bubble/right avatar and name; no delivery/read tick; exact menus; clipboard copies plain message text');
 await page.evaluate(()=>window.expired=true);await row(2).getByRole('button',{name:'消息操作'}).click();await page.getByRole('menuitem',{name:'撤回',exact:true}).click();
 await page.getByText('无法撤回2分钟前发送的消息',{exact:true}).waitFor();await shot('recall-expired');assert.equal(await page.evaluate(()=>window.calls.length),0);
 await page.evaluate(()=>{window.expired=false;window.failRecall=true;});await row(2).getByRole('button',{name:'消息操作'}).click();await page.getByRole('menuitem',{name:'撤回',exact:true}).click();
 assert.equal(await row(2).getByTestId('message-bubble').innerText(),'2');
 await page.evaluate(()=>window.failRecall=false);await row(3).getByRole('button',{name:'消息操作'}).click();await page.getByRole('menuitem',{name:'撤回',exact:true}).click();
 await page.getByText('你撤回了一条消息',{exact:true}).waitFor();assert.equal(await row(3).getByTestId('message-bubble').count(),0);assert.equal(await row(3).getByRole('button').count(),0);await shot('recalled');
 check('expired recall gives configured two-minute feedback; server expiry does not mutate; successful recall becomes a centered notice without avatar/actions');
 await row(2).getByRole('button',{name:'消息操作'}).click();await page.getByRole('menuitem',{name:'删除',exact:true}).click();await page.getByRole('dialog').waitFor();await shot('delete-confirm');
 await page.getByRole('button',{name:'取消',exact:true}).click();await page.locator('[role="dialog"]').waitFor({state:'detached'});assert.equal(await row(2).getByTestId('message-bubble').innerText(),'2');
 await row(2).getByRole('button',{name:'消息操作'}).click();await page.getByRole('menuitem',{name:'删除',exact:true}).click();await page.evaluate(()=>window.failDelete=true);
 await page.getByRole('button',{name:'确认',exact:true}).click();await page.getByRole('alert').filter({hasText:'删除失败'}).waitFor();await shot('delete-error');
 await page.evaluate(()=>window.failDelete=false);await page.getByRole('button',{name:'确认',exact:true}).click();await page.locator('[role="dialog"]').waitFor({state:'detached'});
 assert.equal(await page.getByTestId('im-meeting-message').count(),2);assert.ok(await page.getByText('你撤回了一条消息',{exact:true}).isVisible());await shot('deleted');
 check('delete confirmation supports cancel, failure/retry and local SDK deletion without empty ghost bubble');
 await page.evaluate(()=>{window.messages=[{...window.messages[0],sender:'self',body:{text:'长消息'+ 'LongTextWithoutSpaces'.repeat(40)}}];window.update();});
 await page.setViewportSize({width:1280,height:800});await shot('long-text-desktop');await page.setViewportSize({width:320,height:700});
 assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth),false);await shot('long-text-320');assert.deepEqual(errors,[]);
 check('long text wraps at desktop and 320px; no browser exceptions');report.pass=true;console.log(JSON.stringify(report));
}catch(e){report.failure=String(e.stack||e);if(page)await page.screenshot({path:path.join(out,'failure.png')});throw e;}
finally{writeFileSync(path.join(out,'results.json'),JSON.stringify(report,null,2));await browser?.close();await new Promise(r=>server.close(r));}
