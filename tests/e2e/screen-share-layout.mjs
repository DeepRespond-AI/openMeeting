/** Real VideoGrid/CSS, explicit room/track fixtures; no native or RTC acceptance. */
import assert from 'node:assert/strict';
import {createRequire} from 'node:module';
import {fileURLToPath} from 'node:url';
import {readFileSync, mkdirSync, writeFileSync} from 'node:fs';
import {createServer} from 'node:http';
import path from 'node:path';

const root = fileURLToPath(new URL('../../', import.meta.url));
const frontend = path.join(root, 'frontend');
const require = createRequire(path.join(frontend, 'package.json'));
const {build} = require('esbuild'), {chromium} = require('playwright');
const postcss = require('postcss'), tailwind = require('tailwindcss');
const out = path.resolve(process.env.SCREEN_SHARE_LAYOUT_OUTPUT || path.join(root, '.artifacts/screen-share-layout'));
mkdirSync(out, {recursive: true});

const js = await build({
  stdin: {resolveDir: frontend, loader: 'tsx', contents: `
    import React from 'react';
    import {createRoot} from 'react-dom/client';
    import VideoGrid from './src/components/live-meeting/room/VideoGrid';
    import {I18nProvider} from './src/i18n';
    const names=['林晓晨','陈思远','王嘉宁','张亦然 · 设计讨论负责人','周予安','赵可欣'];
    window.people=count=>Array.from({length:count},(_,i)=>({id:'p'+i,userId:'u'+i,name:names[i%names.length],
      isSelf:i===0,isHost:i===0,micOn:i%3!==1,camOn:i===1,handRaised:i===2,screenSharing:i===0}));
    function canvasTrack(screen){
      const canvas=document.createElement('canvas');canvas.width=1280;canvas.height=720;
      const c=canvas.getContext('2d');c.fillStyle=screen?'#f5f7fb':'#1b3644';c.fillRect(0,0,1280,720);
      if(screen){
        c.fillStyle='#15243b';c.font='bold 44px Microsoft YaHei';c.fillText('产品周会 · 设计方案',64,100);
        c.font='22px Microsoft YaHei';c.fillStyle='#6c7a90';c.fillText('屏幕共享布局预览 / 合成画面',64,144);
        ['需求梳理','体验设计','开发交付'].forEach((title,i)=>{const x=64+i*392;
          c.fillStyle=['#e8edff','#ddf4f5','#e9f3e9'][i];c.fillRect(x,208,368,380);
          c.fillStyle='#243958';c.font='bold 30px Microsoft YaHei';c.fillText(title,x+26,264);
          c.font='21px Microsoft YaHei';c.fillStyle='#60728b';c.fillText('本周重点与进度',x+26,314);
          for(let j=0;j<4;j++){c.fillStyle='#ffffff';c.fillRect(x+26,354+j*48,316,28);}
        });
      }else{c.fillStyle='#8bb8b5';c.beginPath();c.arc(640,300,140,0,Math.PI*2);c.fill();
        c.font='bold 110px Microsoft YaHei';c.fillStyle='#18333d';c.fillText('陈',585,340);}
      const track=canvas.captureStream(2).getVideoTracks()[0];return track;
    }
    window.screenTrack={key:'fixture-screen',kind:'video',source:'screen',local:true,track:canvasTrack(true)};
    const camera={key:'fixture-camera',kind:'video',local:false,username:'u1',track:canvasTrack(false)};
    window.__roomFixture={room:{id:'room-layout',title:'产品周会',code:'123456',participants:window.people(6)},
      self:window.people(6)[0],isHost:true,activeSpeakerId:'p1',audioLevels:{p1:0.7},audioConnected:true,
      mediaState:{status:'connected',tracks:[camera],speakerEnabled:true},
      screenState:{status:'sharing',tracks:[window.screenTrack],ownerName:'林晓晨',viewers:5},
      setParticipantMuted:async()=>true,removeParticipant:async()=>true,transferHost:async()=>true};
    window.updateLayout=patch=>{Object.assign(window.__roomFixture,patch);window.dispatchEvent(new Event('layout-change'));};
    createRoot(document.getElementById('root')).render(<I18nProvider><VideoGrid/></I18nProvider>);
  `},
  bundle: true, write: false, format: 'iife', jsx: 'automatic',
  define: {'process.env.NODE_ENV': '"development"'},
  plugins: [{name: 'room-fixture', setup(b) {
    b.onResolve({filter: /^\.\/RoomProvider$/}, a => a.importer.endsWith('VideoGrid.tsx') ? {path: a.path, namespace: 'fixture'} : undefined);
    b.onLoad({filter: /.*/, namespace: 'fixture'}, () => ({resolveDir: frontend, contents: `
      import {useEffect,useState} from 'react';export function useRoom(){const [,set]=useState(0);
        useEffect(()=>{const change=()=>set(v=>v+1);window.addEventListener('layout-change',change);
          return()=>window.removeEventListener('layout-change',change);},[]);return window.__roomFixture;}`}));
  }}],
});
const config = require(path.join(frontend, 'tailwind.config.js'));
const css = await postcss([tailwind({...config, content: [path.join(frontend, 'src/**/*.{ts,tsx}').replaceAll('\\', '/')]}), require('autoprefixer')])
  .process(readFileSync(path.join(frontend, 'src/app/globals.css'), 'utf8'), {from: path.join(frontend, 'src/app/globals.css')});
const server = createServer((req, res) => {
  if (req.url === '/app.js') {res.setHeader('Content-Type', 'application/javascript'); res.end(js.outputFiles[0].text);}
  else if (req.url === '/app.css') {res.setHeader('Content-Type', 'text/css'); res.end(css.css);}
  else {res.setHeader('Content-Type', 'text/html; charset=utf-8');res.end(`<!doctype html><html class="dark" lang="zh-CN"><head><link rel="stylesheet" href="/app.css"></head>
    <body style="margin:0;background:#0b0d13"><main id="root" style="height:100dvh;padding:16px;min-width:0"></main><script src="/app.js"></script></body></html>`);}
});
await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
let browser;
const report = {scope: 'Real VideoGrid and CSS; room state and canvas media are fixtures', checks: [], screenshots: []};
try {
  browser = await chromium.launch({headless: true});
  const page = await browser.newPage({viewport: {width: 1280, height: 800}, locale: 'zh-CN'});
  page.setDefaultTimeout(10000);
  const errors = [];page.on('pageerror', e => errors.push(e.message));
  await page.goto(`http://127.0.0.1:${server.address().port}`);
  const screen = page.getByTestId('screen-stage'), rail = page.getByTestId('video-stage');
  const tiles = page.getByTestId('participant-tile');
  await screen.locator('video').waitFor();
  for (const [name, width, height, panel] of [['desktop',1280,800,0],['with-panel',1280,800,340],['narrow',390,760,0],['short',1024,420,0]]) {
    await page.setViewportSize({width,height});
    await page.locator('#root').evaluate((el, reserved) => {el.style.width=reserved ? 'calc(100% - '+reserved+'px)' : '100%';}, panel);
    await page.waitForFunction(() => document.querySelector('[data-testid="participant-grid"]').dataset.columns === '1');
    const geometry = await page.evaluate(() => {
      const rect=el=>{const r=el.getBoundingClientRect();return {x:r.x,y:r.y,width:r.width,height:r.height,right:r.right,bottom:r.bottom};};
      const rail=document.querySelector('[data-testid="video-stage"]'), stage=document.querySelector('[data-testid="screen-stage"]');
      return {rail:rect(rail),stage:rect(stage),tiles:[...document.querySelectorAll('[data-testid="participant-tile"]')].map(rect),
        overflow:document.documentElement.scrollWidth>innerWidth||document.documentElement.scrollHeight>innerHeight};
    });
    assert.ok(geometry.rail.right < geometry.stage.x);
    assert.ok(geometry.stage.width > geometry.rail.width * 2);
    assert.equal(geometry.overflow, false);
    for (const tile of geometry.tiles) {assert.ok(Math.abs(tile.width-tile.height)<1);assert.ok(Math.abs(tile.x-geometry.tiles[0].x)<1);}
    assert.equal(await page.getByTestId('invite-tile').count(), 0);
    await page.screenshot({path:path.join(out, name+'.png'),animations:'disabled'});report.screenshots.push(name+'.png');
    report.checks.push({operation:name+' left square rail and main share, no page overflow',pass:true,geometry});
  }
  await page.setViewportSize({width:1280,height:800});
  await tiles.first().click();await page.getByRole('dialog').waitFor();
  assert.ok(await screen.isVisible());await page.getByRole('button',{name:'关闭',exact:true}).first().click();
  await page.locator('[role="dialog"]').waitFor({state:'detached'});
  await tiles.nth(1).locator('button[aria-haspopup="menu"]').click();
  await page.getByRole('menuitem').first().click();await page.getByRole('dialog').waitFor();
  await page.getByRole('button',{name:'关闭',exact:true}).first().click();
  await page.locator('[role="dialog"]').waitFor({state:'detached'});
  await tiles.first().focus();await page.keyboard.press('Space');await page.getByRole('dialog').waitFor();
  await page.getByRole('button',{name:'关闭',exact:true}).first().click();
  await page.locator('[role="dialog"]').waitFor({state:'detached'});
  report.checks.push({operation:'click/keyboard and member menu open info without replacing share',pass:true});

  await page.evaluate(() => window.updateLayout({room:{...window.__roomFixture.room,participants:window.people(18)}}));
  await tiles.nth(17).scrollIntoViewIfNeeded();
  assert.ok(await rail.evaluate(el=>el.scrollTop>0&&el.scrollHeight>el.clientHeight));
  assert.ok(await screen.isVisible());
  await page.screenshot({path:path.join(out,'many-participants.png'),animations:'disabled'});report.screenshots.push('many-participants.png');
  report.checks.push({operation:'18 participants scroll independently of screen',pass:true});

  await page.evaluate(() => {window.cameraElement=document.querySelector('[data-media-track="fixture-camera"]');
    window.updateLayout({room:{...window.__roomFixture.room,participants:window.people(6).map(p=>({...p,screenSharing:false}))},screenState:{status:'idle',tracks:[],viewers:0}});});
  await screen.waitFor({state:'detached'});
  await page.waitForFunction(()=>Number(document.querySelector('[data-testid="participant-grid"]').dataset.columns)>1);
  assert.equal(await page.evaluate(()=>window.cameraElement===document.querySelector('[data-media-track="fixture-camera"]')),true);
  await page.screenshot({path:path.join(out,'gallery-restored.png'),animations:'disabled'});report.screenshots.push('gallery-restored.png');
  for (const status of ['connecting','error','viewing','sharing']) {
    await page.evaluate(status=>window.updateLayout({screenState:{status,tracks:status==='viewing'||status==='sharing'?[window.screenTrack]:[],ownerName:'陈思远',viewers:5}}),status);
    await screen.waitFor();assert.equal(await page.getByTestId('participant-grid').getAttribute('data-columns'),'1');
  }
  assert.equal(await page.evaluate(()=>window.cameraElement===document.querySelector('[data-media-track="fixture-camera"]')),true);
  assert.deepEqual(errors, []);
  report.checks.push({operation:'stop restores gallery; local/remote/connecting/error use rail; camera element persists; no runtime errors',pass:true});
  report.pass=true;console.log(JSON.stringify(report));
} finally {
  writeFileSync(path.join(out,'results.json'),JSON.stringify(report,null,2));
  await browser?.close();await new Promise(resolve=>server.close(resolve));
}
