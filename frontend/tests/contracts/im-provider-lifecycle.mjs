import assert from 'node:assert/strict';
import {createRequire} from 'node:module';
import {fileURLToPath} from 'node:url';
import vm from 'node:vm';
const require=createRequire(new URL('../../package.json',import.meta.url));
const React=require('react'),{act,create}=require('react-test-renderer'),{build}=require('esbuild');
const bundle=await build({stdin:{contents:"export {ImProvider,useIm} from './src/contexts/IMContext';",resolveDir:fileURLToPath(new URL('../../',import.meta.url)),loader:'ts'},bundle:true,write:false,format:'cjs',platform:'node',external:['react'],plugins:[{name:'lifecycle-boundaries',setup(b){
 b.onResolve({filter:/^(@tauri-apps\/api\/core|@deeprespond\/im-tauri|@deeprespond\/im-web-react|@\/contexts\/ServerContext)$/},a=>({path:a.path,namespace:'fixture'}));
 b.onLoad({filter:/.*/,namespace:'fixture'},({path})=>({contents:path.includes('ServerContext')?`export function useServer(){return {loggedIn:true,user:{id:'test-user'}}}`:path.includes('api/core')?`export const invoke=()=>globalThis.ticket();`:path.endsWith('im-tauri')?`export const createDRTauriClient=()=>({auth:{currentUser:{username:'test-user'}},destroy:async()=>{}});`:`import React from 'react';const Context=React.createContext(null);export function DRProvider({client,children}){return React.createElement(Context.Provider,{value:client},children);}`}));
}}]});
let resolve;
const exports={};const context=vm.createContext({module:{exports},exports,require,React,window:{__TAURI_INTERNALS__:{}},ticket:()=>new Promise(r=>resolve=r),console});
vm.runInContext(bundle.outputFiles[0].text,context);const {ImProvider,useIm}=context.module.exports;
let mounts=0,unmounts=0,relogin;
function Meeting(){const im=useIm();relogin=im.relogin;React.useEffect(()=>{mounts++;return()=>unmounts++;},[]);return React.createElement('span',null,im.status);}
let tree;
await act(async()=>{tree=create(React.createElement(ImProvider,null,React.createElement(Meeting)));});
assert.equal(mounts,1);
await act(async()=>{resolve({appKey:'test#app',ticket:'one-use',apiUrl:'https://example.invalid'});});
assert.equal(tree.root.findByType('span').children[0],'ready');assert.equal(mounts,1);assert.equal(unmounts,0);
await act(async()=>{relogin();});
await act(async()=>{resolve({appKey:'test#app',ticket:'next-one-use',apiUrl:'https://example.invalid'});});
assert.equal(mounts,1);assert.equal(unmounts,0);
await act(async()=>tree.unmount());assert.equal(unmounts,1);
console.log(JSON.stringify({operation:'IM hydration and relogin preserve active meeting component',expected:{mounts:1,unmounts:1},actual:{mounts,unmounts},pass:true}));
