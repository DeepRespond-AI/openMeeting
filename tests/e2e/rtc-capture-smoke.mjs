import {createRequire} from 'node:module';
import http from 'node:http';
import {installRtcCamera} from './fixtures/rtc-camera-capture.mjs';
const require=createRequire(new URL('../../frontend/package.json',import.meta.url));
const {chromium}=require('playwright');
const server=http.createServer((q,r)=>r.end('<html><title>Capture smoke</title></html>'));
await new Promise(r=>server.listen(0,'127.0.0.1',r));
const browser=await chromium.launch({headless:true,args:['--use-fake-device-for-media-stream']});
try{
  const context=await browser.newContext({permissions:['camera','microphone']});
  await context.addInitScript(installRtcCamera);
  const page=await context.newPage();await page.goto(`http://127.0.0.1:${server.address().port}`);
  const result=await page.evaluate(async()=>{try{const s=await navigator.mediaDevices.getUserMedia({video:true});const tracks=s.getTracks().map(t=>({kind:t.kind,state:t.readyState}));s.getTracks().forEach(t=>t.stop());return {operation:'synthetic camera fixture',expected:'live camera video track then stop',actual:tracks,pass:true,screenshot:null};}catch(e){return {operation:'synthetic camera fixture',pass:false,error:e.name+': '+e.message};}});
  console.log(JSON.stringify(result));if(!result.pass)process.exitCode=1;
}finally{await browser.close();await new Promise(r=>server.close(r));}
