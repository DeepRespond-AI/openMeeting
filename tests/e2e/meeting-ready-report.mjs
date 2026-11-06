import fs from 'node:fs';
import path from 'node:path';
import {createHash} from 'node:crypto';
import {fileURLToPath} from 'node:url';
const root=fileURLToPath(new URL('../../',import.meta.url)),out=path.join(root,'.artifacts/meeting-ready-im-sync');
const read=(file,fallback={})=>fs.existsSync(path.join(out,file))?JSON.parse(fs.readFileSync(path.join(out,file),'utf8')):fallback;
const native=read('native-results.json',{results:[]}),smoke=read('smoke-results.json',{results:[]}),visual=read('visual-results.json',{rows:[]}),checks=read('checks.json',{checks:[]}),reviews=read('visual-reviews.json',[]),budget=read('budget.json');
const xml=fs.existsSync(path.join(out,'backend.xml'))?fs.readFileSync(path.join(out,'backend.xml'),'utf8'):'';
const tests=[...xml.matchAll(/<testcase\b[\s\S]*?<\/testcase>|<testcase\b[^>]*\/>/g)];
const backend={pass:tests.filter(x=>!/<failure|<error/.test(x[0])).length,fail:tests.filter(x=>/<failure|<error/.test(x[0])).length};
const count=rows=>({pass:rows.filter(r=>r.pass).length,fail:rows.filter(r=>!r.pass&&r.operation!=='failure evidence').length});
const shots=visual.rows.filter(r=>r.screenshot&&r.operation!=='failure evidence');
const visualPass=shots.filter(s=>reviews.some(r=>r.screenshot===s.screenshot&&r.pass)).length;
const escape=v=>String(typeof v==='string'?v:JSON.stringify(v)).replaceAll('|','\\|').replaceAll('\n',' ');
const table=rows=>['|操作|预期|实际|结果|截图|','|---|---|---|---|---|',...rows.filter(r=>r.operation!=='failure evidence').map(r=>`|${escape(r.operation)}|${escape(r.expected)}|${escape(r.actual)}|${r.pass?'通过':'失败'}|${r.screenshot?`[截图](${r.screenshot})`:'—'}|`)].join('\n');
const histories=fs.readdirSync(out).filter(n=>/^(native-results|smoke-results|visual-results)-\d+\.json$/.test(n));
const failures=[];
for(const file of histories){const data=read(file);const rows=data.results||data.rows||[];const evidence=rows.find(r=>r.operation==='failure evidence')?.screenshot;for(const row of rows.filter(r=>!r.pass&&r.operation!=='failure evidence'))failures.push({file,operation:row.operation,actual:row.actual,screenshot:evidence});}
const cleanup=read('cleanup.json',{status:'未执行'});
const lines=[
 '# 会议准备与消息同步测试报告',
 '',
 '分级：完整三端桌面集成验收。涉及会议资源准备、消息持续显示、登录生命周期与原生附件预览，不能按单组件小改动验收。本文由结构化结果生成；未执行、历史失败及未查看截图分别列示。',
 '',
 `后端：${backend.pass} 通过 / ${backend.fail} 失败。原生流程：${count(native.results).pass} 通过 / ${count(native.results).fail} 失败。故障入口冒烟：${count(smoke.results).pass} 通过 / ${count(smoke.results).fail} 失败。前端与负面对照检查：${count(checks.checks).pass} 通过 / ${count(checks.checks).fail} 失败。`,
 `扩展断言：${count(visual.rows.filter(r=>!r.screenshot)).pass} 通过 / ${count(visual.rows.filter(r=>!r.screenshot)).fail} 失败。截图：${shots.length} 张；已实际查看并通过 ${visualPass} 张，其余 ${shots.length-visualPass} 张待检查或未通过。`,
 '',
 '## 启动与真实链路',
 '',
 '`meeting-ready-services.py --env <原服务 .env>` 仅复用 IM 部署配置，在专用 PostgreSQL :55439 上启动真实 gateway :3160、user :3161、meeting :3167；密码登录、原生 IPC、IM/RTC SDK 与 OSS 均为真实调用。测试用户仅在隔离用户库创建，无短信发送。原 :3118 / :39110 等服务及日常桌面窗口未用于操作。',
 '',
 '`MEETING_READY_NATIVE_SDK=<已安装 Rust SDK 目录> node tests/e2e/meeting-ready-desktops.mjs --build --start` 构建三个独立 identifier 的 Windows Tauri 客户端，Next :3162，CDP :9261–9263。Rust SDK 的隔离调试副本仅添加隐藏引擎的调试参数，与主窗口参数一致；不修改消息、文件、RTC 业务逻辑，不作为发布依赖。源码依赖及 Cargo.lock 保持原 SDK。',
 '',
 '先运行 `meeting-ready-native.mjs --smoke`，再运行原生流程及 `meeting-ready-visual.mjs`。三端验证即时群聊、私聊、发送确认后可见、原生截图上传和 640×360 实际解码、刷新历史、跨页返回、故障重试、成员权限、文件列表、长文本和空会话。`reusedEvidence` 是分阶段继续执行时保留的已通过步骤，原始失败保留在历史结果中。',
 '',
 'RTC 仅验证三个原生客户端建立频道连接及重试，不宣称真实摄像头/麦克风媒体传输、屏幕共享、STT/LLM、系统文件选择器或生产安装包已验收。测试未开启真实录音；隔离服务对现有 STT 的内部认证不匹配日志不计为转写通过。',
 '',
 '## 故障入口与截图含义',
 '',
 '“错误夹具”表示测试脚本主动制造的可重复错误：`faults.json` 让隔离业务服务返回聊天 503 / RTC 不可用；CDP 拦截本地图片协议制造图片解码失败。它们先单独冒烟，再验证页面错误与恢复；不是声称真实 IM/OSS 当时出故障。原生正常预览截图来自真实上传与原生下载。',
 '',
 '## 当前结果', '', table(smoke.results), '', table(native.results), '', table(checks.checks), '', table(visual.rows),
 '', '## 逐图视觉检查', '', '|截图|视口|实际查看结果|', '|---|---|---|',
 ...shots.map(s=>{const review=reviews.find(r=>r.screenshot===s.screenshot);return`|[${path.basename(s.screenshot)}](${s.screenshot})|${escape(s.actual?.viewport)}|${review?`${review.pass?'通过':'未通过'}：${escape(review.notes)}`:'待实际查看'}|`;}),
 '', '逐图“通过”仅表示已实际检查布局、遮挡、溢出、弹窗层级与响应式，不表示该图音视频已全部连接。09 / 20 是聊天恢复后 RTC 仍待再次重试的状态；13 保留上一轮主动触发的附件错误，15 / 16 展示随后预览重试成功和错误消除。等待室原图被音频选择框遮挡，关闭该框后重拍，原图与修正记录保存在 visual-corrections.json。',
 '', '## 历史失败与对应截图', '',
 '|原始结果|失败步骤|实际原因|截图|','|---|---|---|---|',
 ...failures.map(f=>`|[${f.file}](${f.file})|${escape(f.operation)}|${escape(f.actual).slice(0,280)}|${f.screenshot?`[失败现场](${f.screenshot})`:'未生成截图；见结果日志'}|`),
 '', '历史包括调试端口未就绪、测试定位重复/弹窗关闭竞态、原生错误对象在 CDP 外被序列化为 Object、IM Provider 重挂载导致迟到离会，以及 RTC 退出占用延迟。失败不能因后续修复而改写为通过。旧 SDK 负面对照在 `sdk-before-fix.jsonl` 中有三个预期失败与两个原本正常的用例。',
 '', '## 仍需 IM/RTC SDK 补齐', '',
 '- IM SDK：空历史或消息序号有间隔时，确认消息未加入可见范围；已通过可重复安装的 pnpm 补丁修复，建议同步到 SDK 正式版本。',
 '- 桌面 SDK：`files.fetchBlob` 仍用 WebView fetch；本项目预览改用 SDK 原生下载与受限本地协议。建议 SDK 提供原生预览/缓存释放 API，减少应用层对缓存目录约定的依赖。',
 '- RTC：退出完成到服务端释放占用存在延迟；真实故障恢复记录需要两次重试。保留明确提示和重试，未重写平台会话收尾机制。',
 '- 群成员系统消息目前仍显示 `[tip]`，需要 SDK/服务端给出可消费的系统消息正文或渲染契约；本轮未扩展系统消息模板。',
 '- 附件真实解码验收覆盖 PNG 截图；视频、语音格式及超限大文件取消未进行真实端到端验收。原生缓存保留常见媒体扩展名，不能据 PNG 通过推断其他格式通过。',
 '', '## 预算与关闭', '',
 `E2E 累计预算：${Math.round((budget.usedMs||0)/1000)} / ${Math.round((budget.limitMs||1800000)/1000)} 秒，首次启动时间不因重试重置。`,
 '', '```json', JSON.stringify(cleanup,null,2), '```',
 '', '本地产物：`.artifacts/meeting-ready-im-sync/`；归档目录：`docs/testing/archive/会议准备与消息同步/`；截图：各目录下 `screenshots/`。凭据、账户密码、本地数据库与调试 SDK 副本不归档。', '',
];
fs.writeFileSync(path.join(out,'测试报告.md'),lines.join('\n'));
if(process.argv.includes('--archive')){
 const archive=path.join(root,'docs/testing/archive/会议准备与消息同步');fs.mkdirSync(archive,{recursive:true});
 const names=fs.readdirSync(out).filter(n=>/^(native-results|smoke-results|visual-results)(-\d+)?\.json$/.test(n)||/^(failure-|visual-failure-).*\.png$/.test(n)||['测试报告.md','checks.json','backend.xml','visual-reviews.json','visual-corrections.json','budget.json','cleanup.json','sdk-before-fix.jsonl'].includes(n)||/^check-\d+\.log$/.test(n));
 const manifest=[];
 for(const name of names){fs.copyFileSync(path.join(out,name),path.join(archive,name));const data=fs.readFileSync(path.join(out,name));manifest.push({path:name,sha256:createHash('sha256').update(data).digest('hex')});}
 fs.cpSync(path.join(out,'screenshots'),path.join(archive,'screenshots'),{recursive:true});
 for(const shot of shots){const data=fs.readFileSync(path.join(out,shot.screenshot));manifest.push({path:shot.screenshot,sha256:createHash('sha256').update(data).digest('hex')});}
 for(const dir of fs.readdirSync(out).filter(n=>n.startsWith('checks-history-')))fs.cpSync(path.join(out,dir),path.join(archive,dir),{recursive:true});
 fs.writeFileSync(path.join(archive,'manifest.json'),JSON.stringify(manifest,null,2));
}
console.log(JSON.stringify({backend,native:count(native.results),smoke:count(smoke.results),checks:count(checks.checks),screenshots:shots.length,visualPass,report:path.join(out,'测试报告.md')}));
