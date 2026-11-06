import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
import vm from 'node:vm';

const require = createRequire(new URL('../../package.json', import.meta.url));
const React = require('react');
const { renderToStaticMarkup } = require('react-dom/server');
const { build } = require('esbuild');
const bundle = await build({
  stdin: {contents:"export {default} from './src/components/live-meeting/room/Toolbar';",resolveDir:fileURLToPath(new URL('../../',import.meta.url)),loader:'ts'},
  bundle:true,write:false,format:'cjs',platform:'node',external:['react'],
  plugins:[{name:'toolbar-boundaries',setup(b){
    b.onResolve({filter:/^(sonner|\.\/RoomProvider|\.\/RoomSettings|\.\/AudioControls|@\/i18n|@\/config\/meeting-ui|@\/components\/ui\/(dropdown-menu|dialog))$/},a=>({path:a.path,namespace:'fixture'}));
    b.onLoad({filter:/.*/,namespace:'fixture'},({path})=>({loader:'jsx',contents:
      path.endsWith('RoomProvider')?'export const useRoom=()=>globalThis.room;':
      path.endsWith('meeting-ui')?'export const meetingUi={handRaise:true};':
      path.endsWith('i18n')?'export const useT=()=>key=>key;':
      path==='sonner'?'export const toast={success:()=>{},error:()=>{}};':
      path.endsWith('dropdown-menu')?`import React from 'react';export const DropdownMenu=({children})=><div>{children}</div>,DropdownMenuTrigger=DropdownMenu,DropdownMenuContent=DropdownMenu,DropdownMenuItem=DropdownMenu;`:
      path.endsWith('dialog')?'export const Dialog=()=>null,DialogContent=()=>null,DialogDescription=()=>null,DialogTitle=()=>null;':
      'export default ()=>null;'
    }));
  }}],
});
for(const [name,isHost,handRaised,expected] of [
  ['host has no hand request',true,false,null],
  ['guest can raise a hand',false,false,'raise'],
  ['guest can lower a hand',false,true,'lower'],
  ['promoted host hides even a stale raised hand',true,true,null],
]){
  const room={room:{waiting:[]},self:{handRaised},isHost,screenState:{status:'idle'}};
  const exports={},context=vm.createContext({module:{exports},exports,require,React,room,console});
  vm.runInContext(bundle.outputFiles[0].text,context);
  const html=renderToStaticMarkup(React.createElement(context.module.exports.default,{onShowInfo:()=>{}}));
  for(const action of ['raise','lower'])assert.equal(html.includes(`liveMeeting.room.hand.${action}`),expected===action);
  assert.ok(html.includes('liveMeeting.room.info.title'));
  console.log(JSON.stringify({name,pass:true}));
}
