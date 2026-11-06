import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import crypto from 'node:crypto';
const root=fileURLToPath(new URL('../../',import.meta.url));
const out=path.resolve(root,process.env.MEETING_READY_OUTPUT||'.artifacts/rtc-release-media-preview');
const archive=path.join(root,'docs/testing/archive/RTC释放与媒体预览');
const read=(name,fallback={})=>fs.existsSync(path.join(out,name))?JSON.parse(fs.readFileSync(path.join(out,name),'utf8')):fallback;
const reviews=read('visual-reviews.json');
const groups=[['静态与契约检查','checks.json','checks'],['故障入口冒烟','smoke-results.json','results'],['三端会议流程','native-results.json','results'],['媒体及身份验收','media-results.json','rows'],['缓存和姓名补充验收','media-extra.json','rows'],['已确认视频补验','media-confirmed.json','rows'],['真实 IM 平台探测','platform-results.json','rows']];
const visual=read('media-visual.json',{rows:[]}).rows;
const current=groups.flatMap(([scope,name,key])=>(read(name)[key]||[]).filter(r=>r.operation!=='failure evidence').map(r=>({...r,scope})));
const history=[];for(const name of fs.readdirSync(out).filter(n=>/^(native-results|media-results|media-extra|media-visual|smoke-results)-\d+\.json$/.test(n))){const data=read(name);const attempts=data.results||data.rows||[];const failures=attempts.filter(row=>row.pass===false&&row.operation!=='failure evidence');if(!failures.length&&attempts.some(r=>r.operation==='failure evidence'))failures.push({operation:'native pre-step setup failed',pass:false,actual:'setup failed before a test step; screenshots retained'});for(const row of failures)history.push({file:name,...row,screenshots:attempts.filter(r=>r.operation==='failure evidence').map(r=>r.screenshot)});}
const esc=v=>String(v??'').replaceAll('|','\\|').replaceAll('\n','<br>');
const counts={passed:current.filter(r=>r.pass).length,failed:current.filter(r=>!r.pass).length,historicalFailedAttempts:history.length,screenshots:visual.filter(r=>r.screenshot).length,visualReviewed:visual.filter(r=>r.screenshot&&reviews[r.screenshot]?.pass===true).length};
const lines=['# RTC 释放、媒体预览与聊天身份测试报告','',
'完整流程级验收：涉及 RTC 会话生命周期、真实文件传输和三端聊天身份，使用三个真实 Windows Tauri 桌面客户端。视频、语音输入为合成素材，播放器通过真实 IM、OSS、Rust 原生下载和 WebView 媒体解码；不代表摄像头/麦克风采集或人工听感验收。','',
`当前检查 **${counts.passed} 通过 / ${counts.failed} 失败**；保留 **${history.length} 次历史失败步骤**。正式截图 ${counts.screenshots} 张，已实际查看并记录视觉通过 ${counts.visualReviewed} 张。`,'',
'## 启动与测试范围','',
'工作树 `<repo>`，分支 `fix/meeting-ready-im-sync`。初期复用上一轮构建；发现未注册 fs 插件后，最终三端均重新构建当前 Rust 与前端，保留 SDK 唯一的调试端口参数补丁，不替换认证/传输逻辑。三个专用客户端标识 `com.openmeeting.ai.imready.a/b/c`，CDP 9261/9262/9263。新建三名隔离测试账号，并核对当前登录用户，未操作日常客户端。','',
'```powershell',
"$env:MEETING_READY_OUTPUT='<repo>/.artifacts/rtc-release-media-preview'",
'docker start openmeeting-im-chat-tests',
'# 独立隐藏进程运行现有 Python 服务入口，--env 仅复用 IM 部署配置',
'<repo>/server/.venv/Scripts/python.exe tests/e2e/meeting-ready-services.py --env <repo>/server/.env',
'node tests/e2e/meeting-ready-native.mjs --smoke',
"$env:MEETING_READY_NATIVE_SDK='<native-sdk-source>'",
'node tests/e2e/meeting-ready-desktops.mjs --build',
'node tests/e2e/meeting-ready-desktops.mjs --start',
"$env:RTC_SINGLE_RETRY='1'",
'node tests/e2e/meeting-ready-native.mjs',
'node tests/e2e/rtc-release-media-preview.mjs',
'node tests/e2e/rtc-release-media-preview.mjs --extra',
'node tests/e2e/rtc-release-media-preview.mjs --confirmed-video',
'node tests/e2e/rtc-release-media-preview.mjs --visual',
'node tests/e2e/meeting-ready-checks.mjs',
'node tests/e2e/rtc-release-media-report.mjs','```','',
'服务：Next 3162、真实网关 3160、用户服务 3161、会议服务 3167、独立测试 PG 55439。先单独冒烟 IM/RTC 故障入口；媒体错误注入也先单独冒烟，再在真实预览控件里验证错误和恢复。所有当前断言通过后才统一采集正式截图。','',
'## 当前结构化结果','',
'| 范围 | 操作 | 预期 | 实际 | 结果 |','|---|---|---|---|---|'];
for(const r of current)lines.push(`|${esc(r.scope)}|${esc(r.operation)}|${esc(r.expected)}|${esc(typeof r.actual==='object'?JSON.stringify(r.actual):r.actual)}|${r.pass?'通过':'失败'}|`);
lines.push('','## 失败记录与对应截图','','历史失败保留，重跑通过不覆盖原始失败，也不把故障注入产生的预期错误写成真实 IM 接口故障。','');
for(const r of history)lines.push(`- [${r.file}](${r.file})：${esc(r.operation)}；${esc(r.actual)}。对应截图：${r.screenshots.map(s=>`[${s}](${s})`).join('、')||'该步骤未产生截图（详见原始产物）'}。`);
const baseline=read('baseline-contracts.json',{results:[]});lines.push('',`旧 RTC 代码负向对照：${baseline.results.filter(r=>!r.pass).length} 个用例失败；属于预期负向对照，见 [baseline-contracts.json](baseline-contracts.json)。`);
lines.push('','## 截图与实际视觉检查','','无 in-app browser，通过三个真实桌面 WebView 的 CDP 截图。1280×800 与 520×760，逐张检查遮挡、溢出、截断、层级与响应式。','',
'失败与截图的对应关系：真实头像 403 的 HTTP 证据在 `platform-results.json`，01/19 显示首字回退；03/05/21/23 留有视频修复前的真实失败发件箱，不是新一轮发送失败；06/10/17/24/28/35 为明确的故障注入截图。其余历史失败截图在上一节逐条链接。已确认服务端发送的视频另有 `media-confirmed.json` 三端播放补验，避免把旧失败发件箱中的预览当作当前发送成功。','',
'| 截图 | 状态/视口 | 实际查看结论 |','|---|---|---|');
for(const r of visual.filter(r=>r.screenshot)){const review=reviews[r.screenshot];lines.push(`|[${path.basename(r.screenshot)}](${r.screenshot})|${esc(r.operation)} ${esc(JSON.stringify(r.actual))}|${review?esc((review.pass?'通过：':'未通过：')+review.notes):'未实际查看，待检查'}|`);}
lines.push('','## 证据边界与剩余风险','',
'- RTC 正常重入、冷加载及单次 UI 故障重试以当前结构化结果为准。服务端释放仍可能有等待，应用对 leaving 状态最多等待 15 秒，超时明确提示稍后重试；不抢占其他活跃会议。永久占用、取消和授权拒绝由契约测试确定性覆盖，不能代替实际长期故障压测。',
'- 视频为 H.264/AAC MP4，语音为无文件名 PCM WAV；不宣称验证所有编码、超大文件、移动端、macOS、物理设备或生产安装包。播放测试静音，只断言解码和时间推进。会议界面尚无语音录制按钮，本轮语音输入通过 SDK 公开发送 API，接收和预览使用实际产品 UI。',
'- 预览错误截图为显式拦截本地原生媒体协议，真实 IM 上传流程独立验证。成员无头像和头像失败时显示首字；真实头像测试只使用专用测试头像。',
'- Windows 原生系统通知注册及 STT 隔离令牌问题不属于本轮媒体预览验收；没有将通知或语音转写标为通过。',
'- 当前 IM 系统成员事件仍显示 `[tip]`，需 IM SDK 提供系统消息文案契约。','',
'- **真实头像访问未通过**：IM 返回的公开头像 URL 被 OSS 返回 HTTP 403，`AccessDenied` 明确说明 bucket ACL 不允许访问。上传和用户资料更新成功，不代表头像展示成功。本轮只确认姓名及首字回退；需 IM 修正公开头像存储策略或提供可访问的签名 URL，客户端未另造头像服务。见 [platform-results.json](platform-results.json)。',
'- 历史冷加载失败中捕获到 `429 rate_limited`；调试脚本原先每 100ms 查询真实 IM，会造成额外限流。后改为只轮询 SDK 本地快照，不替换 SDK/服务端状态。一次早期冷加载错误未捕获失败码，不把推测原因写成已证实。安全诊断及状态时序见 [rtc-diagnostics.jsonl](rtc-diagnostics.jsonl)、[rtc-state-timeline.jsonl](rtc-state-timeline.jsonl)。',
'- 发现并修复会议视频消息缺少 `duration_seconds` 的真实失败。保留此前发送失败截图和原始结果；最终通过范围以最新三端接收与播放断言为准。','',
'- 发现并修复 Rust 未注册 fs 插件导致预览缓存不删除。最终重新构建三端，并单独检查新一轮六个预览缓存文件关闭后不存在。历史失败保留；检查结果见媒体补充验收。','',
'- 文件列表本轮只有五项，全部可见。13/31 是执行滚动请求后的画面，未产生实际位移，不宣称已验证超长文件列表滚动。','',
'## 调试预算与清理','',
`累计 E2E 墙钟预算：[budget.json](budget.json)，已用 ${(read('budget.json').usedMs/1000).toFixed(1)} 秒 / 1800 秒。跨重跑沿用同一开始时间，未清零。`,'',
`清理记录：[cleanup.json](cleanup.json)。${esc(JSON.stringify(read('cleanup.json',{status:'尚未清理'})))}`,'',
'活动产物 `.artifacts/rtc-release-media-preview/`；本报告和精简证据归档 `docs/testing/archive/RTC释放与媒体预览/`。原始结构化行包含操作、预期、实际、通过与否及截图路径。');
fs.writeFileSync(path.join(out,'测试报告.md'),lines.join('\n')+'\n');
fs.writeFileSync(path.join(out,'summary.json'),JSON.stringify(counts,null,2));
fs.mkdirSync(archive,{recursive:true});
const names=new Set(['测试报告.md','summary.json','checks.json','smoke-results.json','native-results.json','media-results.json','media-extra.json','media-confirmed.json','media-visual.json','visual-reviews.json','baseline-contracts.json','budget.json','cleanup.json','platform-results.json','platform-cleanup.json','service-cleanup.json','processes.json','native-build.json','rtc-diagnostics.jsonl','rtc-state-timeline.jsonl',...history.map(r=>r.file),...history.flatMap(r=>r.screenshots||[])]);
for(const name of names)if(fs.existsSync(path.join(out,name)))fs.copyFileSync(path.join(out,name),path.join(archive,name));
for(const r of visual.filter(r=>r.screenshot)){const dest=path.join(archive,r.screenshot);fs.mkdirSync(path.dirname(dest),{recursive:true});fs.copyFileSync(path.join(out,r.screenshot),dest);}
for(const r of read('checks.json',{checks:[]}).checks)if(r.log&&fs.existsSync(path.join(out,r.log)))fs.copyFileSync(path.join(out,r.log),path.join(archive,r.log.replace(/\.log$/,'.txt')));
const archivedChecks=read('checks.json',{checks:[]});for(const r of archivedChecks.checks)if(r.log)r.log=r.log.replace(/\.log$/,'.txt');fs.writeFileSync(path.join(archive,'checks.json'),JSON.stringify(archivedChecks,null,2));
const logs=read('checks.json',{checks:[]}).checks.filter(r=>r.log).map(r=>r.log.replace(/\.log$/,'.txt'));
const manifest=[];for(const name of [...new Set([...names,...logs,...visual.filter(r=>r.screenshot).map(r=>r.screenshot)])].sort()){const file=path.join(archive,name);if(fs.existsSync(file))manifest.push({file:name,sha256:crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex')});}
fs.writeFileSync(path.join(archive,'manifest.json'),JSON.stringify(manifest,null,2));console.log(JSON.stringify(counts));
