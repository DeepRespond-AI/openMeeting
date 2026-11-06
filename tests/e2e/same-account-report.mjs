import fs from 'node:fs';import path from 'node:path';import {createHash} from 'node:crypto';import assert from 'node:assert/strict';
const root=path.resolve(import.meta.dirname,'../..'),out=path.join(root,'.artifacts/same-account-meeting-entry');
const read=name=>JSON.parse(fs.readFileSync(path.join(out,name),'utf8'));
const sdk=read('sdk-probe.json'),native=read('current-native.json'),recovery=read('recovery.json'),cleanup=read('cleanup.json'),visual=read('visual-reviews.json');
const duplicate=sdk.steps.find(r=>r.actual?.reason==='joined_on_other_device');assert.equal(duplicate.actual.status,409);
assert.ok(native.console.some(r=>r.args.some(a=>a?.status===409&&a?.reason==='joined_on_other_device')));
const count=rows=>({pass:rows.filter(r=>r.pass===true).length,fail:rows.filter(r=>r.pass===false).length});
const nativeCounts=count([...native.steps,...recovery.steps]),sdkCounts=count(sdk.steps);
const archive=path.join(root,'docs/testing/archive/同账号跨端入会排查');fs.mkdirSync(path.join(archive,'screenshots'),{recursive:true});
const screenshots=fs.readdirSync(path.join(out,'screenshots')).filter(n=>n.endsWith('.png'));
for(const name of screenshots){const file='screenshots/'+name;assert.ok(visual[file]?.viewed,'Screenshot must actually be viewed: '+file);assert.equal(visual[file].sha256,createHash('sha256').update(fs.readFileSync(path.join(out,file))).digest('hex'));fs.copyFileSync(path.join(out,file),path.join(archive,file));}
const rawNames=['sdk-probe.json','current-native.json','recovery.json','cleanup.json','visual-reviews.json','smoke.json','fresh-build.json','budget.json',...fs.readdirSync(out).filter(n=>/^current-native-history-|^sdk-probe-history-/.test(n)&&n.endsWith('.json'))];
if(fs.existsSync(path.join(out,'cleanup-history.json')))rawNames.push('cleanup-history.json');
for(const name of rawNames)fs.copyFileSync(path.join(out,name),path.join(archive,name));
// The exploratory cached-shell file originally logged observations as successful
// collection. Re-evaluate connection readiness from recorded page states rather
// than presenting failed baseline/control connections as passing tests.
const exploratory=read('results.json');
const observed=exploratory.steps.map(r=>({...r,pass:r.operation==='host quick meeting'?!r.actual?.settled?.entryError:r.operation==='different-account control'?!r.actual?.entryError:r.pass}));
fs.writeFileSync(path.join(archive,'cached-shell-observations.json'),JSON.stringify({boundary:exploratory.boundary,note:'Readiness criteria re-evaluated from captured states; original collection flags are not acceptance.',steps:observed},null,2));
const history=rawNames.filter(n=>n.includes('-history-')).map(file=>({file,...count(read(file).steps||[])}));
const esc=x=>String(x??'').replaceAll('|','\\|').replaceAll('\n',' ');
const rows=[...native.steps.map(r=>({...r,source:'当前原生'})),...recovery.steps.map(r=>({...r,source:'延后恢复'})),...sdk.steps.map(r=>({...r,source:'真实SDK探测'}))];
const text=[
'# 同账号跨端入会排查测试报告','',
'本轮为连接故障排查，按完整流程验证：真实原生桌面、Rust IPC、现有业务网关、IM/RTC；另一设备使用独立浏览器中的真实 SDK。未执行 Android 原生流程或真实语音、视频、录音质量验收。未注入 SDK/API/媒体替身。','',
'## 结论','',
'已确认同账号第二设备被 RTC 服务拒绝：HTTP 409，code=conflict，reason=joined_on_other_device。第一设备和不同账号对照均连接成功；第二设备被拒时第一设备仍保持 joined/connected。当前 develop 构建的原生桌面也记录到相同错误并进入用户截图对应的失败页。','',
'业务入会按 room_id + user_id 幂等复用同一参与者，因此房主账号的第二设备仍被识别为房主。失败页调用普通 leave，后端返回“主持人请使用「离开并结束会议」离场”。这解释了连接失败后又无法从该按钮离开的现象。','',
'第一设备退出后立即重试仍收到 409，此项按失败保留；稍后再次重试已成功。未测量精确释放耗时，不能承诺固定等待时长。','',
'## 启动与边界','',
'develop 已执行 git fetch / git pull --ff-only origin develop，远端无新增提交；基线 621fea8，保留本地主工作区的已有修改。排查分支 investigate/same-account-meeting-entry，独立 worktree worktrees/same-account-meeting-entry。','',
'依次运行：','',
'```powershell',
'node tests/e2e/same-account-entry.mjs setup',
'node tests/e2e/same-account-entry.mjs run',
'node tests/e2e/same-account-sdk-probe.mjs',
'node tests/e2e/same-account-fresh-native.mjs',
'node tests/e2e/same-account-current-native.mjs',
'node tests/e2e/same-account-recovery.mjs',
'node tests/e2e/same-account-entry.mjs cleanup',
'node tests/e2e/same-account-report.mjs',
'```','',
'复用日常网关 39110 及已登录测试账号；独立 Next 3162、透明网关转发 3160，原生 CDP 9261–9263/9271。当前原生壳从本轮 develop 源码构建；仅为自动化给 SDK 隐藏窗口增加调试参数读取，使其与主窗口 WebView 参数一致，未改变 SDK 登录/RTC 行为。测试 profile 与用户正在运行的应用隔离。','',
'## 数量与结果','',
`当前原生及后续恢复：${nativeCounts.pass} 通过 / ${nativeCounts.fail} 失败。真实 SDK 探测：${sdkCounts.pass} 成功 / ${sdkCounts.fail} 连接拒绝（同账号第二设备的 409，是本次定位结果）。`,'',
'原生失败项为“第一设备退出后立即重试”；后续独立恢复步骤成功，不覆盖或删除原失败。截图采集步骤单独列于下表，不等同于媒体质量验收。','',
'| 来源 | 操作 | 预期 | 实际 | 结果 |','|---|---|---|---|---|',
...rows.map(r=>`| ${r.source} | ${esc(r.operation)} | ${esc(r.expected||'SDK 认证成功')} | ${esc(typeof r.actual==='string'?r.actual:JSON.stringify(r.actual))} | ${r.pass?'通过':'失败/拒绝'} |`),'',
'## 截图与逐张检查','',
'使用真实 Tauri WebView 的 CDP 截图，替代 in-app browser。桌面 1280×800、窄视口 520×760；历史测试壳失败截图另含 1100×700。全部逐张实际查看，并登记 SHA-256，未将故障功能标记为产品通过。','',
'| 截图 | 检查结果 |','|---|---|',
...screenshots.map(name=>`| [${name}](screenshots/${name}) | ${esc(visual['screenshots/'+name].notes)} |`),'',
'09、10 是当前原生客户端收到真实 409 后点击退出的画面；11、12 是稍后重试成功的正常会议；13、14 是真实加载阶段。14 的 DOM 文本采集时页面已继续切换，但已实际查看图片确认截图仍为加载画面。01–06 属于旧调试配置失败证据，不作为 409 的证明。current-native-failure-1793326039614.png 对应立即重试未成功的断言失败。','',
'## 历史调试失败','',
'未删除历史错误：初始 SDK 探测把 HTTP snake_case 字段当成 camelCase 导致三次 local_validation，校正字段后真实 SDK 认证通过；调试 WebView 参数不一致导致隐藏 IM 引擎创建失败；首次复现步骤返回首页时保留了持续会议，导致等待新入会失败页超时，改为清理本端媒体并重新载入页面后完成复现。','',
...history.map(h=>`- [${h.file}](${h.file})：${h.pass} 通过 / ${h.fail} 失败。`),
'- [cleanup-history.json](cleanup-history.json)：首次清理发生 ECONNRESET，补充幂等重试后完成；原始中断单独保留。',
'- [cached-shell-observations.json](cached-shell-observations.json)：旧壳单端就绪和异账号对照均失败，已按真实页面状态评估，未作为通过。','',
'## 代码依据与建议','',
'- server/meeting_ms/db/models.py：uq_participants_room_user；api/v1/rooms.py：重复入会复用成员及房主身份；普通 leave 拒绝房主。',
'- frontend/src/services/live-meeting/media/imChannel.ts：conflict / joined_on_other_device 被归为 connectionFailed。',
'- frontend/src/components/live-meeting/room/RoomProvider.tsx：首次等待 RTC、设备和聊天就绪，45 秒超时；RoomScreen.tsx 失败页显示通用文案并调用 leave。',
'- 建议识别 409 并明确提示“该账号已在另一台设备参会，请先退出后重试”；失败页取消本端入会并返回首页，避免直接结束另一设备正在主持的会议。',
'- 同账号双端同时参会需要 RTC 服务支持，并同步设计业务成员的设备身份与录音采集端归属。本轮保留现有策略，仅提交排查脚本、文档及证据。','',
'## 清理','',
...cleanup.map(c=>`- ${c.operation}：${c.pass?'完成':'失败'}${c.status?`，HTTP ${c.status}`:''}。`),
'',
'仅结束本轮创建的测试房间，关闭本轮进程并恢复测试 profile；日常业务 Docker、原有桌面客户端和 Android 设备不属于清理对象。测试录音未作为验收输入，未下载会议录音。','',
'## 产物','',
'本报告由 tests/e2e/same-account-report.mjs 读取结构化 JSON、截图检查和清理结果生成。原始私有账号、profile 备份和构建缓存仅保留于忽略的 .artifacts/same-account-meeting-entry，不归档登录令牌。',
''
].join('\n');
fs.writeFileSync(path.join(archive,'测试报告.md'),text);fs.writeFileSync(path.join(archive,'summary.json'),JSON.stringify({native:nativeCounts,sdk:sdkCounts,screenshots:screenshots.length,reviewed:screenshots.length,cleanup:cleanup.every(r=>r.pass)},null,2));console.log(JSON.stringify({report:path.join(archive,'测试报告.md'),native:nativeCounts,sdk:sdkCounts,screenshots:screenshots.length}));
