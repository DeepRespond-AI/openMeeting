import assert from 'node:assert/strict';
import {createRequire} from 'node:module';
import {fileURLToPath} from 'node:url';
import vm from 'node:vm';
const require=createRequire(new URL('../../package.json',import.meta.url));
const React=require('react'),{renderToStaticMarkup}=require('react-dom/server'),{build}=require('esbuild');
const bundle=await build({stdin:{contents:"export {default as RoomScreen} from './src/components/live-meeting/room/RoomScreen';",resolveDir:fileURLToPath(new URL('../../',import.meta.url)),loader:'ts'},bundle:true,write:false,format:'cjs',platform:'node',external:['react'],plugins:[{name:'room-screen-boundaries',setup(b){
 b.onResolve({filter:/^(lucide-react|@\/config\/meeting-ui|@\/i18n|@\/components\/ui\/dialog|\.\/(ImInvite|RoomProvider|RoomHeader|VideoGrid|Toolbar|SidePanel|RecordingBanner))$/},a=>({path:a.path,namespace:'fixture'}));
 b.onLoad({filter:/.*/,namespace:'fixture'},({path})=>({contents:path.includes('meeting-ui')?'export const meetingUi=globalThis.flags;':path.endsWith('i18n')?'export const useT=()=>key=>key;':path.includes('RoomProvider')?'export const useRoom=()=>globalThis.room;':path==='lucide-react'?"export const AlertCircle=()=>null,ArrowLeft=()=>null,Loader2=()=>null;":path.includes('/dialog')?'export const Dialog=()=>null,DialogContent=()=>null,DialogTitle=()=>null;':'export default ()=>null;'}));
}}]});
function render(flags,room){
 const exports={},context=vm.createContext({module:{exports},exports,require,React,flags,room});
 vm.runInContext(bundle.outputFiles[0].text,context);
 return renderToStaticMarkup(React.createElement(context.module.exports.RoomScreen));
}
const off={audio:false,video:false,chat:false,recording:false,screenShare:false};
const base={phase:'joined',entryStatus:'loading',room:null,mediaAvailable:true,mediaState:{status:'idle'},screenState:{status:'idle'},chatStatus:'connecting'};
const cases=[
 ['all disabled modules reveal the ready room',off,{...base,entryStatus:'ready'},false],
 ['chat-only pending state waits behind the entry screen',{...off,chat:true},base,true],
 ['audio-only pending state waits behind the entry screen',{...off,audio:true},base,true],
 ['video-only pending state waits behind the entry screen',{...off,video:true},base,true],
 ['ready chat and media reveal the room',{...off,chat:true,audio:true},{...base,entryStatus:'ready',chatStatus:'ready',mediaState:{status:'connected'}},false],
];
for(const [operation,flags,room,expected]of cases){const html=render(flags,room);assert.equal(html.includes('aria-busy="true"'),expected);assert.ok(!html.includes('data-testid="meeting-connecting"'));assert.ok(!html.includes('animate-spin'));console.log(JSON.stringify({operation,expected:{entryPending:expected},actual:{entryPending:html.includes('aria-busy="true"')},pass:true}));}
const html=render(off,{...base,screenState:{status:'choosing'}});assert.ok(!html.includes('data-testid="screen-status"'));console.log(JSON.stringify({operation:'disabled screen sharing hides its choosing status',expected:'hidden',actual:'hidden',pass:true}));
assert.ok(render(off,{...base,entryStatus:'error'}).includes('data-testid="meeting-entry-error"'));
