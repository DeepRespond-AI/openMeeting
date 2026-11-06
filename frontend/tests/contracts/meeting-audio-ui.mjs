// Browser component coverage with synthetic input and an isolated room context.
import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';

const require = createRequire(new URL('../../package.json', import.meta.url));
const { build } = require('esbuild');
const { chromium } = require('playwright');
const postcss = require('postcss');
const tailwindcss = require('tailwindcss');
const root = fileURLToPath(new URL('../../', import.meta.url));
const out = new URL('../../../.artifacts/meeting-audio/', import.meta.url);
mkdirSync(out, { recursive: true });
const fixture = `
import React,{createContext,useContext,useState} from 'react';
const Context=createContext(null);
export function useRoom(){return useContext(Context);}
export function Fixture({children}){
 const [connected,setConnected]=useState(false),[micOn,setMicOn]=useState(false);
 const [preferences,setPreferences]=useState({microphoneId:'default',speakerId:'default',autoJoin:false,unmuteSound:false});
 const [mediaState,setMediaState]=useState({status:'connected',tracks:[],speakerEnabled:true});
 window.fixture={setDevice:async(kind,id)=>{window.actions.push([kind,id]);setMediaState(s=>({...s,[kind==='input'?'microphoneDeviceId':'speakerDeviceId']:id}));}};
 return <Context.Provider value={{self:{id:'self',micOn},audioLevels:{self:.4},audioConnected:connected,audioPreferences:preferences,
 setAudioPreferences:patch=>setPreferences(s=>({...s,...patch})),mediaState,mediaAvailable:true,
 connectAudio:async()=>{window.actions.push(['connect']);setConnected(true);},
 disconnectAudio:async()=>{window.actions.push(['disconnect']);setConnected(false);setMicOn(false);},
 toggleMic:()=>setMicOn(s=>!s)}}>{children}</Context.Provider>;
}`;
const bundle = await build({
  stdin: { contents: `import React from 'react'; import {createRoot} from 'react-dom/client';
    import AudioControls from './src/components/live-meeting/room/AudioControls'; import {Fixture} from 'room-fixture';
    import MediaElement from './src/components/live-meeting/room/MediaElement';
    const root=createRoot(document.getElementById('root'));window.unmount=()=>root.unmount();
    window.mountPlayback=(track,speakerId)=>{const playback=createRoot(document.getElementById('root'));window.unmountPlayback=()=>playback.unmount();playback.render(<MediaElement item={{key:'remote',track,kind:'audio',local:false}} speakerId={speakerId}/>);};
    root.render(<Fixture><div style={{position:'fixed',bottom:30,left:70,background:'#151A26',borderRadius:40,padding:12}}><AudioControls /></div></Fixture>);`,
    resolveDir: root, loader: 'tsx' },
  bundle: true, write: false, format: 'iife', platform: 'browser', jsx: 'automatic',
  plugins: [{ name: 'isolated-room', setup(builder) {
    builder.onResolve({ filter: /^(room-fixture|\.\/RoomProvider)$/ }, () => ({ path: 'room-fixture', namespace: 'fixture' }));
    builder.onLoad({ filter: /.*/, namespace: 'fixture' }, () => ({ contents: fixture, loader: 'tsx', resolveDir: root }));
    builder.onResolve({ filter: /^@\/services\/live-meeting$/ }, () => ({ path: 'media-fixture', namespace: 'media' }));
    builder.onLoad({ filter: /.*/, namespace: 'media' }, () => ({ contents: `export const getMediaClient=()=>({setMicrophoneDevice:id=>window.fixture.setDevice('input',id),setSpeakerDevice:id=>window.fixture.setDevice('output',id)});` }));
    builder.onResolve({ filter: /^@\/i18n$/ }, () => ({ path: 'i18n-fixture', namespace: 'i18n' }));
    builder.onLoad({ filter: /.*/, namespace: 'i18n' }, () => ({ contents: `import messages from './src/i18n/messages/liveMeeting';
      const t=key=>key.startsWith('liveMeeting.')?key.slice(12).split('.').reduce((obj,k)=>obj?.[k],messages['zh-CN'])??key:'关闭';export const useT=()=>t;`, resolveDir: root }));
  }}],
});
const config = require('./tailwind.config.js');
const css = await postcss([tailwindcss({ ...config, content: [{ raw: ['AudioControls', 'AudioDiagnostics', 'MicrophoneIndicator'].map(name => readFileSync(`${root}/src/components/live-meeting/room/${name}.tsx`, 'utf8')).join('\n'), extension: 'tsx' }, {raw: readFileSync(`${root}/src/components/ui/dialog.tsx`,'utf8')+readFileSync(`${root}/src/components/ui/dropdown-menu.tsx`,'utf8'),extension:'tsx'}] })]).process(readFileSync(`${root}/src/app/globals.css`, 'utf8'), { from: undefined });
const browser = await chromium.launch({ headless: true, args: ['--autoplay-policy=no-user-gesture-required'] });
const page = await browser.newPage({ viewport: { width: 900, height: 650 } });
const errors=[];page.on('pageerror',error=>errors.push(String(error)));
await page.addInitScript(() => {
  window.actions=[];window.captures=[];window.denyMicrophone=false;
  window.playbacks=[];
  const originalPlay=HTMLMediaElement.prototype.play;
  HTMLMediaElement.prototype.play=function(){window.playbacks.push({muted:this.muted,sink:this.fixtureSinkId});return originalPlay.call(this);};
  HTMLMediaElement.prototype.setSinkId=async function(id){if(id==='missing')throw new Error('Output missing');this.fixtureSinkId=id;};
  const media=new EventTarget();
  media.enumerateDevices=async()=>[
    {kind:'audioinput',deviceId:'usb',label:'USB 麦克风'}, {kind:'audioinput',deviceId:'built-in',label:'内置麦克风'},
    {kind:'audiooutput',deviceId:'headphones',label:'USB 耳机'},
  ];
  media.getUserMedia=async()=>{
    if(window.denyMicrophone)throw new DOMException('Denied','NotAllowedError');
    const context=new AudioContext(),oscillator=context.createOscillator(),gain=context.createGain(),destination=context.createMediaStreamDestination();
    gain.gain.value=.05;oscillator.connect(gain);gain.connect(destination);oscillator.start();await context.resume();
    const stream=destination.stream,track=stream.getAudioTracks()[0],stop=track.stop.bind(track);
    const capture={stopped:false};window.captures.push(capture);
    track.stop=()=>{capture.stopped=true;stop();void context.close();};
    if(window.holdCapture)await new Promise(resolve=>window.releaseCapture=resolve);
    return stream;
  };
  Object.defineProperty(navigator,'mediaDevices',{value:media,configurable:true});
});
await page.route('http://127.0.0.1:3179/**', route=>route.fulfill({ contentType: 'text/html', body: `<html><head><meta charset="utf-8"><style>${css.css}</style></head><body><div id="root"></div></body></html>` }));
try {
  await page.goto('http://127.0.0.1:3179/');
  await page.addScriptTag({ content: bundle.outputFiles[0].text });
  await page.getByRole('dialog').waitFor();
  await page.screenshot({ path: fileURLToPath(new URL('connection.png',out)), animations: 'disabled' });
  await page.getByRole('tab',{name:'电话音频'}).click();
  await page.getByText('当前会议暂未开通电话接入，请使用电脑音频加入会议。').waitFor();
  await page.getByRole('tab',{name:'电脑音频'}).click();
  await page.getByRole('button',{name:'使用电脑音频',exact:true}).click();
  await page.getByRole('dialog').waitFor({state:'hidden'});
  await page.getByRole('button',{name:'音频设备与设置'}).click();
  await page.getByRole('menuitem',{name:'USB 麦克风',exact:true}).click();
  await page.waitForFunction(()=>window.actions.some(([kind,id])=>kind==='input'&&id==='usb'));
  await page.getByRole('button',{name:'音频设备与设置'}).click();
  await page.screenshot({ path: fileURLToPath(new URL('devices.png',out)), animations: 'disabled' });
  await page.getByRole('menuitem',{name:'检测扬声器和麦克风'}).click();
  await page.getByRole('heading',{name:'扬声器检测中'}).waitFor();
  await page.waitForFunction(()=>Number(document.querySelector('[role="meter"][aria-label="输出等级"]')?.getAttribute('aria-valuenow'))>40);
  await page.screenshot({ path: fileURLToPath(new URL('speaker-test.png',out)), animations: 'disabled' });
  await page.getByRole('button',{name:'听到了',exact:true}).click();
  await page.getByRole('heading',{name:'麦克风检测中'}).waitFor();
  await page.getByRole('button',{name:'麦克风正常'}).waitFor();
  await page.waitForFunction(()=>!Array.from(document.querySelectorAll('button')).find(button=>button.textContent==='麦克风正常')?.disabled);
  await page.screenshot({ path: fileURLToPath(new URL('microphone-test.png',out)), animations: 'disabled' });
  await page.getByRole('button',{name:'麦克风正常'}).click();
  await page.getByRole('heading',{name:'音频检测完成'}).waitFor();
  assert.equal(await page.evaluate(()=>window.captures.every(capture=>capture.stopped)),true);
  await page.getByRole('button',{name:'完成',exact:true}).click();
  console.log('PASS connection choice, device menu and full speaker/microphone test with synthetic audio');
  await page.evaluate(()=>{window.denyMicrophone=true;});
  await page.getByRole('button',{name:'音频设备与设置'}).click();
  await page.getByRole('menuitem',{name:'检测扬声器和麦克风'}).click();
  await page.getByRole('button',{name:'听到了',exact:true}).click();
  await page.getByRole('alert').filter({hasText:'麦克风权限被拒绝'}).waitFor();
  assert.equal(await page.getByRole('button',{name:'麦克风正常'}).isDisabled(),true);
  await page.getByRole('button',{name:'关闭',exact:true}).click();
  console.log('PASS denied microphone permission stays visible and prevents a false success');
  await page.evaluate(()=>{window.denyMicrophone=false;window.holdCapture=true;});
  await page.getByRole('button',{name:'音频设备与设置'}).click();
  await page.getByRole('menuitem',{name:'检测扬声器和麦克风'}).click();
  await page.getByRole('button',{name:'听到了',exact:true}).click();
  await page.waitForFunction(()=>!!window.releaseCapture);
  await page.getByRole('button',{name:'关闭',exact:true}).click();
  await page.evaluate(()=>window.releaseCapture());
  await page.waitForFunction(()=>window.captures.every(capture=>capture.stopped));
  assert.deepEqual(errors,[]);
  console.log('PASS closing during an unresolved permission request stops the late microphone track');
  await page.evaluate(()=>window.unmount());
  await page.evaluate(()=>{
    const context=new AudioContext(),oscillator=context.createOscillator(),destination=context.createMediaStreamDestination();
    oscillator.connect(destination);oscillator.start();window.playbackContext=context;window.playbackTrack=destination.stream.getAudioTracks()[0];
    window.playbacks=[];window.mountPlayback(window.playbackTrack,'headphones');
  });
  await page.waitForFunction(()=>window.playbacks.some(item=>item.sink==='headphones'&&!item.muted));
  await page.evaluate(()=>window.unmountPlayback());
  assert.equal(await page.evaluate(()=>window.playbackTrack.readyState),'live');
  console.log('PASS new remote audio routes to the selected output before unmuting and keeps SDK tracks alive');
  await page.evaluate(()=>{window.playbacks=[];window.mountPlayback(window.playbackTrack,'missing');});
  await page.getByRole('alert').filter({hasText:'无法通过所选扬声器播放'}).waitFor();
  assert.equal(await page.evaluate(()=>window.playbacks.length),0);
  await page.evaluate(()=>{window.unmountPlayback();window.playbackTrack.stop();void window.playbackContext.close();});
  assert.deepEqual(errors,[]);
  console.log('PASS failed output routing remains muted and exposes an actionable error');
  writeFileSync(new URL('results.json',out),JSON.stringify({scope:'Isolated browser components with synthetic microphone; real speaker hardware and Tauri RTC were not tested',passed:5,errors},null,2));
} finally { await browser.close(); }
