import assert from 'node:assert/strict';
import vm from 'node:vm';
import {createRequire} from 'node:module';
import {fileURLToPath} from 'node:url';
const require=createRequire(new URL('../../package.json',import.meta.url));
const {build}=require('esbuild');
const source=await build({stdin:{contents:"export {saveImAvatar} from './src/services/im-avatar';",resolveDir:fileURLToPath(new URL('../../',import.meta.url)),loader:'ts'},bundle:true,write:false,format:'cjs'});
const scope={module:{exports:{}},DOMException};vm.runInNewContext(source.outputFiles[0].text,scope);
const {saveImAvatar}=scope.module.exports;
const cases=[];
async function check(operation,fn){try{await fn();cases.push({operation,pass:true});}catch(error){cases.push({operation,pass:false,actual:String(error.stack||error)});}}
const fixture=()=>{const calls=[],controller=new AbortController();let saved='old-avatar';return{calls,controller,saved:()=>saved,client:{files:{upload:async(file,options)=>{calls.push(['upload',options.purpose,options.kind,options.signal===controller.signal]);options.onProgress(1,2);return{url:'https://im.test/new-avatar.jpg'};}},users:{updateMe:async patch=>{calls.push(['save',patch.avatar_url]);saved=patch.avatar_url;}}}};};
await check('native avatar upload precedes profile publication and reports progress',async()=>{const f=fixture();await saveImAvatar(f.client,{},f.controller.signal,n=>f.calls.push(['progress',n]),()=>f.calls.push(['saving']));assert.deepEqual(f.calls,[['upload','user_avatar','image',true],['progress',50],['saving'],['save','https://im.test/new-avatar.jpg']]);});
await check('cancelling a late upload never publishes its resulting avatar',async()=>{const f=fixture();f.client.files.upload=async()=>{f.controller.abort();return{url:'https://im.test/late.jpg'};};await assert.rejects(saveImAvatar(f.client,{},f.controller.signal,()=>{},()=>{}),{name:'AbortError'});assert.equal(f.saved(),'old-avatar');});
await check('SDK upload failure preserves the existing profile',async()=>{const f=fixture();f.client.files.upload=async()=>{throw Error('native upload failed');};await assert.rejects(saveImAvatar(f.client,{},f.controller.signal,()=>{},()=>{}),/native upload failed/);assert.equal(f.saved(),'old-avatar');});
await check('profile save rejection is surfaced instead of reporting upload as success',async()=>{const f=fixture();f.client.users.updateMe=async()=>{throw Error('profile forbidden');};await assert.rejects(saveImAvatar(f.client,{},f.controller.signal,()=>{},()=>{}),/profile forbidden/);assert.equal(f.saved(),'old-avatar');});
for(const c of cases)console.log(JSON.stringify(c));if(cases.some(c=>!c.pass))process.exitCode=1;
