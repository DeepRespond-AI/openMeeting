import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const root=fileURLToPath(new URL('../../',import.meta.url));
const out=path.resolve(root,process.env.MEETING_READY_OUTPUT||'.artifacts/meeting-recording-controls');
const archive=path.join(root,'docs/testing/archive/会议录制控制');
const read=file=>JSON.parse(fs.readFileSync(path.join(out,file),'utf8').replace(/^\uFEFF/,''));
const textFile=file=>{const b=fs.readFileSync(path.join(out,file));return b.toString(b[0]===255&&b[1]===254?'utf16le':'utf8').replace(/^\uFEFF/,'');};
const inputs=['checks.json','smoke.json','controls-results.json','api-audio.json'];
const groups=inputs.map(file=>({file,rows:read(file).rows}));
const rows=groups.flatMap(g=>g.rows),passed=rows.filter(r=>r.pass).length,failed=rows.filter(r=>!r.pass).length;
const blocked=read('results.json').rows.filter(r=>!r.pass&&!r.screenshot);
const visual=read('visual.json').rows.filter(r=>r.screenshot),reviews=read('visual-reviews.json');
const reviewed=visual.filter(r=>reviews[r.screenshot]?.pass===true).length;
const budget=read('budget.json'),diag=read('rtc-diagnostic.json'),cleanup=read('platform-cleanup.json'),probe=read('final-probe.json');
const histories=fs.readdirSync(out).filter(f=>/^(controls-results|visual)-\d+\.json$/.test(f)).sort();
const history=histories.map(file=>({file,rows:read(file).rows.filter(r=>!r.pass)})).filter(h=>h.rows.length);
const md=v=>String(v??'').replaceAll('|','\\|').replaceAll('\n',' ');
const lines=[
 '# 会议录制控制测试报告','',
 '分级：新增录制权限与跨端状态，原计划进行完整三端 E2E。实际 IM 应用创建 RTC 频道返回 403 rtc_disabled；用户明确要求暂不处理 RTC，等待 IM 团队恢复。因此本轮以真实三端验证控制流程，以生成的 PCM 经真实 Rust IPC / 后端验证保存及 WAV 播放；真实 RTC 音轨采集失败/未验收，不能用这些结果替代。','',
 `当前分层检查 **${passed} 通过 / ${failed} 失败**；另保留 **${blocked.length} 项真实 RTC 集成失败（按用户要求暂缓）**。后端含 53 个测试用例全部通过，录音契约含 6 个用例全部通过，二者各计为一项检查；${visual.length} 张最终截图中 ${reviewed} 张已逐张实际查看。历史脚本与构建问题另列。`,'',
 '## 版本、功能与文件归属','',
 '- 2026-10-26 已拉取 origin/develop，基线 a090235；工作树 `<repo>`，分支 `feat/meeting-recording-controls`。保留日常 develop 工作树的未提交配置。',
 '- 文档提交 2484e4b；后端状态/权限/迁移提交 20cbe77；原生命令、按钮及审批 UI 提交 65f49cb。',
 '- 入会默认不录制；房主手动开始/停止，房客先申请，房主允许或拒绝。统一会议音频由房主客户端采集，上传业务后端，沿用当前房主账号的会议记录归属。房客查看会后录音仍需另加访问授权，本轮不扩大可见范围。',
 '- 全员持续展示状态；后加入和重连读快照。WS 即时广播与既有 IM 持久通知/失效通道复用；后端业务权限不交给客户端消息决定。录制期间转交主持人须先停止保存。','',
 '## 启动与测试流程','',
 '- 阅读 CLAUDE.md、设计、启动与测试说明，先探测日常 :3118 与三份日常客户端。仅启动原先停止的独立 PostgreSQL :55439，测试使用独立 recording_controls_tests 库，页面使用隔离 meeting_ready_user/meeting_ready_meeting 库。',
 '- 后端通过 `meeting-ready-services.py --env <已有服务配置>` 启动 gateway/user/meeting :3160/:3161/:3167 与出网代理 :3163；本地测试 DNS 映射仅更改解析，真实网关出站校验保留。',
 '- 使用已有前端依赖，`meeting-ready-desktops.mjs --build` 从当前 Rust 源码编译三份专用 Tauri 客户端；SDK 调试副本仅增加 WebView CDP 参数。复用有效 FFmpeg 缓存后构建通过，生产安装包未验收。',
 '- `meeting-ready-desktops.mjs --start` 启动当前 Next :3162、IM engine 和三端，CDP :9261/:9262/:9263。没有 in-app browser，使用 Playwright 连接实际 Tauri WebView。',
 '- 页面前单独运行 `meeting-recording-controls.mjs --smoke`：真实登录、录制控制 503 故障入口与 403 越权/拒绝路径；随后完整流程在 RTC 采集处失败。按用户指示停止处理 RTC，执行 `--controls-only`、`--api-audio`，最后统一 `--visual`。',
 `- E2E 累计约 ${(budget.usedMs/60000).toFixed(1)} 分钟，30 分钟预算跨重跑未重置。提前降级的原因为明确的 RTC 禁用响应和用户暂缓指令，并未声称耗尽预算后恢复成功。`,'',
 '## 当前检查结果','',
 '| 操作 | 预期 | 实际 | 结果 |','|---|---|---|---|',
 ...rows.map(r=>`| ${md(r.operation)} | ${md(r.expected)} | ${md(JSON.stringify(r.actual))} | ${r.pass?'通过':'失败'} |`),'',
 ...groups.map(g=>`- [${g.file}](${g.file})`),'',
 '## RTC 未完成验收与对应失败截图','',
 `真实 SDK 返回 HTTP ${diag.status}，code=${diag.code}，reason=${diag.reason}。IM 登录、消息与通知可用；RTC 频道创建被拒绝。未改动 IM 应用全局开关，也未替换成功响应。`,'',
 ...blocked.map(r=>`- 未通过：[完整流程结果](results.json)，步骤 ${md(r.operation)}，实际 ${md(r.actual)}。`),
 ...read('results.json').rows.filter(r=>r.screenshot&&!r.pass).map(r=>`- [${r.screenshot}](${r.screenshot})`),'',
 '初次完整流程中“关闭状态零分段”的检查尚未建立活动 RTC 音频；其预期文字过宽，实际仅证明状态关闭和零分段。本轮不把该旧检查计入 19 项通过，也不声称已经证明活动音频下的停止采集。','',
 'API 降级使用明确生成的 16 kHz PCM，不来自 RTC。真实后端合成 3 秒 WAV，原生下载与播放器时间推进成功；下载文件进一步核对声道/采样率/帧数及确切 PCM 内容后删除，见 [文件验证](audio-file-check.json)。真实麦克风、摄像头、RTC 采集、长会、STT/LLM 效果和生产安装包均未通过本轮验收。','',
 '## 最终双视口截图与实际检查','',
 '控制流程断言通过后统一截图；后续补充了独立 API 保存播放验证，再完成最终统一截图。等待临时 toast 自然消失再检查稳定布局，加载截图保留真实异步处理中状态。请求失败/加载使用独立后端测试中间件，不是实际 IM 故障；所有画面的音视频不可用警告对应实际 RTC 禁用。仅对界面布局作通过判断，不对音频采集作通过判断。','',
 '| 截图 | 视口 | 实际查看结论 |','|---|---|---|',
 ...visual.map(r=>`| [${path.basename(r.screenshot)}](${r.screenshot}) | ${r.actual.viewport.width}×${r.actual.viewport.height} | ${reviews[r.screenshot]?.pass===true?'通过：'+md(reviews[r.screenshot].notes):'未实际查看'} |`),'',
 '审批弹窗实际打开、处理后清空和关闭；窄窗口工具栏实际换行。当前一名申请者列表无滚动溢出，大量并发申请的列表滚动未实测。未添加或伪造本次不存在的表格/抽屉验收。','',
 '## 历史调试失败','',
 '保留原始失败。权限断言第一次在 Playwright 外捕获原生错误导致 status 丢失，改为页面内捕获；截图第一次点击 toast 关闭控件触发了模态外部点击，第二次命中离屏 toast，改为等待通知自然消失。它们属于测试脚本问题，未改写成原生权限通过。首次 FFmpeg 下载中断已通过复用有效缓存解决；构建日志为 PowerShell UTF-16，首次汇总未正确解码，修正读取后确认三份构建均成功。','',
 ...history.flatMap(h=>[`- [${h.file}](${h.file})：${h.rows.filter(r=>!r.screenshot).map(r=>md(r.operation)).join('；')}`,...h.rows.filter(r=>r.screenshot).map(r=>`  - [${r.screenshot}](${r.screenshot})`)]),
 '- [首次 FFmpeg 构建失败](build-failed-ffmpeg-download.txt)、[实际成功构建](build.txt)、[日志解码失败记录](checks-build-decoding-failed.json)。','',
 '## 清理、风险与后续','',
 `- 测试会议结束，三端退出登录；清理测试群 ${cleanup.groupsDeleted} 个、IM 用户 ${cleanup.usersDeleted} 个，平台清理错误 ${cleanup.errors.length} 个。见 [平台清理](platform-cleanup.json) 和 [结束/退出](meeting-end-cleanup.json)。`,
 `- 本轮 Next/三端/后端/出网代理均已停止，独立 PostgreSQL 恢复停止；专用端口仍监听 ${probe.ports.filter(p=>p.port!==3118&&p.listening).length} 个。日常 :3118 与原三端保留。见 [停止客户端](processes.json)、[服务关闭](service-cleanup.json)、[最终探测](final-probe.json)。`,
 '- 本轮完成控制与权限实现；RTC 恢复后需要新产物目录重验真实音轨采集、尾段保存、停止/再次开始和完整会后录音。未来完整脚本补强了 RTC 连接/合成麦克风就绪断言；该补强因用户暂缓 RTC 未在本轮重新执行，只做语法检查。',
 '- 录制仍是会议音频，文件上传业务后端；不是会议视频合成。授权房客申请不等于授权其读取房主会后记录。主持人异常退出的末段补传/录制接管仍有原有边界。',
 '- 依赖迁移和新原生命令，部署须同时更新后端与桌面端；旧客户端自动上传且缺少 epoch 将被新后端拒绝。真实 IM 通知投递已从 SDK/RPC 日志观察到成功，断开 WS 后仅靠 IM 恢复的专项未单独验收。','',
 '## 复跑与产物','',
 '- [E2E 脚本](../../../../tests/e2e/meeting-recording-controls.mjs)、[检查脚本](../../../../tests/e2e/recording-controls-checks.mjs)、[报告生成器](../../../../tests/e2e/recording-controls-report.mjs)、[开发文档](../../../development/meeting-recording-controls.md)。',
 '- 活动目录 `.artifacts/meeting-recording-controls/`，当前目录为精选归档；报告由上述 JSON/XML/日志与实际视觉复核结果组装。账号、令牌、配置、二进制和原始音频不提交；旧试拍图仅随历史 JSON 保留，不具有最终视觉通过结论。',
];
fs.writeFileSync(path.join(out,'测试报告.md'),lines.join('\n')+'\n');
fs.mkdirSync(archive,{recursive:true});
const files=[...inputs,'results.json','visual.json','visual-reviews.json','budget.json','scope.json','rtc-diagnostic.json','audio-file-check.json','platform-cleanup.json','final-probe.json','processes.json','service-cleanup.json','meeting-end-cleanup.json','backend-regression.xml','checks-build-decoding-failed.json',...histories,'测试报告.md'];
for(const file of files)fs.copyFileSync(path.join(out,file),path.join(archive,file));
for(const file of ['typescript.txt','recording-contract.txt','im-contract.txt','backend-regression.txt','build.txt','build-failed-ffmpeg-download.txt'])fs.writeFileSync(path.join(archive,file),textFile(file).replaceAll('\r\n','\n').split('\n').map(line=>line.trimEnd()).join('\n'));
for(const r of visual){fs.mkdirSync(path.dirname(path.join(archive,r.screenshot)),{recursive:true});fs.copyFileSync(path.join(out,r.screenshot),path.join(archive,r.screenshot));}
// Keep partial draft captures referenced by historical JSON, without marking
// their visual checks passed. This preserves evidence instead of broken links.
for(const file of histories)for(const r of read(file).rows.filter(r=>r.screenshot)){
 const source=path.join(out,r.screenshot);if(fs.existsSync(source)){const dest=path.join(archive,r.screenshot);fs.mkdirSync(path.dirname(dest),{recursive:true});fs.copyFileSync(source,dest);}
}
for(const file of fs.readdirSync(out).filter(f=>/^failure-.*\.png$/.test(f)))fs.copyFileSync(path.join(out,file),path.join(archive,file));
console.log(JSON.stringify({passed,failed,rtcDeferredFailures:blocked.length,visualReviewed:reviewed,archive}));
if(failed||reviewed!==visual.length||cleanup.errors.length)process.exitCode=1;
