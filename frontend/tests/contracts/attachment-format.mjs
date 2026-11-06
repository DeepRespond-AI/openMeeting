import assert from 'node:assert/strict';
import {createRequire} from 'node:module';
import {fileURLToPath} from 'node:url';
import vm from 'node:vm';
const require=createRequire(new URL('../../package.json',import.meta.url));
const {build}=require('esbuild');
const bundle=await build({stdin:{contents:"export {previewExtension} from './src/services/im-attachment-preview'",resolveDir:fileURLToPath(new URL('../../',import.meta.url)),loader:'ts'},bundle:true,write:false,format:'cjs',platform:'node',external:['@tauri-apps/*']});
const sandbox={module:{exports:{}},require:()=>({})};vm.runInNewContext(bundle.outputFiles[0].text,sandbox);
const {previewExtension}=sandbox.module.exports;
for(const [type,body,expected] of [
 ['voice',{format:'wav'},'wav'],['voice',{format:'mp3'},'mp3'],['voice',{format:'ogg'},'ogg'],
 ['voice',{format:'webm'},'webm'],['video',{format:'webm'},'webm'],['video',{format:'mp4'},'mp4'],
 ['video',{name:'input.webm',format:'MP4'},'mp4'],['image',{name:'photo.PNG'},'png'],
 ['voice',{name:'audio.M4A'},'m4a'],['voice',{format:'../../exe',name:'bad.exe'},'webm'],
 ['image',{},'png'],['video',{},'mp4'],
]){assert.equal(previewExtension({type,body}),expected);console.log(JSON.stringify({type,body,expected,pass:true}));}
