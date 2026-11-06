import {existsSync,readFileSync,writeFileSync} from 'node:fs';
import path from 'node:path';
import {createHash} from 'node:crypto';

export function renderScreenReport(out,root){
  const read=(name,fallback)=>existsSync(path.join(out,name))?JSON.parse(readFileSync(path.join(out,name),'utf8')):fallback;
  const data=read('results.json',{steps:[]}),reviews=read('visual-reviews.json',{}),checks=read('checks.json',[]),attempts=read('attempts.json',[]),platform=read('platform-acceptance.json',null),smoke=read('smoke-results.json',{steps:[]});
  const assertions=data.steps.filter(s=>s.phase==='assertions'),captures=data.steps.filter(s=>s.phase==='screenshots'),shots=data.steps.filter(s=>s.screenshot),local=data.transport?.includes('本地');
  const reviewed=file=>{const row=reviews[file];return row&&existsSync(path.join(out,file))&&row.sha256===createHash('sha256').update(readFileSync(path.join(out,file))).digest('hex')?row:null;};
  const platformShots=platform?.steps.filter(s=>s.screenshot)??[];
  const passed=rows=>rows.filter(s=>s.pass).length,failed=rows=>rows.filter(s=>!s.pass).length;
  const pageAssertions=assertions.filter(s=>s.viewport),preflightAssertions=assertions.filter(s=>!s.viewport);
  const escape=value=>String(typeof value==='object'?JSON.stringify(value):value??'').split('\n')[0].replaceAll('|','/');
  const table=rows=>rows.map(s=>`| ${s.phase||'真实平台'} / ${s.viewport||'服务'} | ${s.operation} | ${s.expected} | ${escape(s.actual)} | ${s.pass?'通过':'失败'} | ${s.screenshot?`[截图](${s.screenshot})`:'—'} |`);
  const elapsed=data.budgetStarted&&data.started?Math.round((Date.parse(data.started)-data.budgetStarted)/1000)+(data.elapsedSeconds||0):null;
  const lines=['# IM 第二视频轨道共享测试报告','',
    '分级：完整流程回归。涉及 SDK 多轨道发布、摄像头独立控制、接管和跨页会话，不按文案小改动降级。使用 Playwright 无头 Chromium；真实运行修改后的 Next 产品页面、生产 ImChannelMediaClient 和补丁后的 IM SDK。业务 IPC、名单和聊天为显式夹具，摄像头和屏幕输入为合成画布，不作为原生硬件验收。','',
    `分支 feat/im-rtc-second-video；worktree ${root}。基于最新 develop 接入上一轮 IM 共享生命周期，保留近期聊天、音频设备与 RTC 释放修复。`,'',
    `本轮媒体环境：${data.transport||'尚未运行'}。${local?'本地模式不能证明真实 IM 平台通过。':'临时 IM 用户和独立平台频道，认证、发布和远端传输使用真实平台。'} 屏幕以第二条 Camera 来源视频发布，用 screen:<共享sessionId> 名称保持独立身份，没有修改 IM 平台授权或存储 ACL。`,'',
    `当前结果：流程断言 ${passed(assertions)} 通过 / ${failed(assertions)} 失败（页面${passed(pageAssertions)}通过/${failed(pageAssertions)}失败，前置夹具${passed(preflightAssertions)}通过/${failed(preflightAssertions)}失败）；截图复核步骤 ${passed(captures)} 通过 / ${failed(captures)} 失败；另行独立失败夹具 ${passed(smoke.steps)} 通过 / ${failed(smoke.steps)} 失败。${data.error?'本轮未完成全部计划：'+data.error.split('\n')[0]:'本轮页面计划执行完毕。'} 真实平台独立探测 ${platform?`${passed(platform.steps)} 通过 / ${failed(platform.steps)} 失败`:'未执行'}。`,'',
    '## 启动与服务探测','',
    '在此 worktree 根目录运行：','','```powershell',
    'node tests/e2e/rtc-capture-smoke.mjs',
    'node tests/e2e/im-rtc-screen-share.mjs --smoke',
    'node tests/e2e/im-rtc-second-video-probe.mjs',
    'node tests/e2e/im-rtc-screen-share.mjs',
    'node tests/e2e/im-rtc-screen-checks.mjs',
    '# 逐张实际查看截图、写入 visual-reviews.json 后',
    'node tests/e2e/im-rtc-screen-share.mjs --report','```','',
    '产物默认为 .artifacts/IM第二视频轨道共享/；IM_RTC_SCREEN_OUTPUT 可指定新独立验收目录。先读 CLAUDE.md、quickstart.md、DESIGN.md和启动说明，复用锁定依赖与现有IM配置。既有原生CDP不可用时保留其服务及登录态，以新临时身份执行真实SDK。Next :3188加载本worktree；:3177只在内存交付临时用户/频道票据，OPENMEETING_TEST_PYTHON和OPENMEETING_RTC_TEST_ENV可覆盖Python与配置路径。代理在显式test环境直连平台，不声称验证生产统一出站网关。','',
    `本轮启动详情：${data.startup||'未记录'}。现有服务探测：${JSON.stringify(data.probe||[])}。`,'',
    `平台探测与页面共用budget.json，累计30分钟，不因失败重置。${elapsed===null?'页面尚未执行。':`截至本轮页面结束累计${elapsed}s。`}超时停止页面调试并如实降级，未执行或失败不写成通过。`,'',
    '## 真实平台双轨能力','',platform?.conclusion||'真实平台尚未执行。','',
    '验证两种发布顺序，直接读取远端尺寸、播放时间和已知输入颜色像素，避免将摄像头或接收器旧帧误认作共享。摄像头允许SDK动态分辨率层，共享明确设置maintain-resolution。晚加入须看到两路，subscriber发布拒绝保持有效。','',
    '| 阶段 / 视口 | 操作 | 预期 | 实际 | 结果 | 截图 |','|---|---|---|---|---|---|',...table(platform?.steps||[]),'',
    '## 产品页面逐步结果','',
    '[失败夹具独立冒烟](smoke-results.json)在页面前重复验证SDK发布失败、权限拒绝和刷新错误；HTTP夹具单独验证加载、成员权限和终态。业务错误夹具不冒充真实云端故障。','',
    '| 阶段 / 视口 | 操作 | 预期 | 实际 | 结果 | 截图 |','|---|---|---|---|---|---|',...table(data.steps),'',
    '## 类型、契约与构建','',...checks.map(c=>`- ${c.name}：${c.exitCode===0?'通过':'失败'}；${c.count??'不按用例计数'}；[日志](${c.log})。`),'',
    '## 截图及实际查看','',
    '产品页面桌面1280×800、窄视口640×600，先完成所有断言再统一采集。覆盖正常、空态、选屏加载、取消权限、发布错误、刷新错误与恢复、接管、返回会议、成员抽屉、长聊天实际滚动、只读设置弹窗打开和关闭、离会失败及成功。没有新增表格。平台诊断截图另列，不能替代产品界面。只有实际查看且SHA-256与当前文件一致的截图才计视觉通过。','',
    `产品截图${shots.length}张，已实际查看且视觉通过${shots.filter(s=>reviewed(s.screenshot)?.pass).length}张；平台诊断截图${platformShots.length}张，已实际查看且视觉通过${platformShots.filter(s=>reviewed(s.screenshot)?.pass).length}张。`,'',
    ...[...shots,...platformShots].map(s=>{const r=reviewed(s.screenshot);return `- [${s.screenshot}](${s.screenshot})：${r?`${r.pass?'已查看，通过':'已查看，失败'}；${r.notes}`:'未实际查看或截图已变化，不计视觉通过'}`;}),'',
    '## 历史失败与清理','',
    ...(existsSync(path.join(out,'screen-before-republish-fix.log'))?['- 代码复核发现完整RTC重新发布会清空旧publication.track。新增针对性回归在修复前失败，旧引用无法停止重发轨道；修复后按受控发布名解析最新对象。见[修复前失败](screen-before-republish-fix.log)及最终screen.log，完整页面随后重新执行。']:[]),
    ...(existsSync(path.join(out,'checks-before-republish-fix.json'))?['- 初次检查的旧摄像头替身缺少SDK已有的createTracks/publication mute/unmute接口，测试启动失败；补齐替身后保留原4项预览断言。见[原检查结果](checks-before-republish-fix.json)、[原失败日志](camera-before-fixture-update.log)及最终camera.log。']:[]),
    ...(platform?.history||[]).flatMap((a,i)=>a.steps.filter(s=>!s.pass).map(s=>`- 平台探测历史${i+1}：${s.operation}失败，${escape(s.actual)}${s.screenshot?`；[原证据](${s.screenshot})`:''}。`)),
    ...attempts.flatMap((a,i)=>[...a.steps.filter(s=>!s.pass).map(s=>`- 页面历史${i+1}：${s.operation}失败，${escape(s.actual)}${s.screenshot?`；[证据](${s.screenshot})`:''}。`),...(a.error&&!a.steps.some(s=>!s.pass)?[`- 页面历史${i+1}：${a.error.split('\n')[0]}。`]:[])]),'',
    `页面清理：${JSON.stringify(data.cleanup||{})}。平台探测资源清理：${JSON.stringify(platform?.cleanup||{})}。`,'',
    '[结束后端口探测](cleanup-probe.json)：以结构化记录确认本次3188/3177等服务关闭、原有3118/39110保留。','',
    '## 剩余风险与范围','',
    '- 本方案扩展应用及补丁SDK，IM官方频道契约仍未承诺屏幕共享。普通Camera多轨道只对本次部署环境真实验证，平台升级、套餐或配额变化仍须复验。',
    '- 未完成本轮Windows Tauri原生IPC、手动系统选屏、真实摄像头/麦克风、跨公网/弱网、容量及生产包验收。系统声音不在本次范围。',
    '- SDK用原始轨道交付应用播放，adaptiveStream关闭以避免未调用LiveKit attach时远端暂停，带宽容量需专项验证。摄像头开关不按Camera来源选第一条，避免误控制共享。',
    '- 历史失败原样保留；合成采集与业务夹具不替代系统采集和真实业务后端全链路。','',
    '[结果](results.json)、[平台结果及历史](platform-acceptance.json)、[页面历史](attempts.json)、[逐步日志](steps.jsonl)、[开发日志](dev-server.log)、[RTC日志](rtc-server.log)、[视觉记录](visual-reviews.json)。',''];
  writeFileSync(path.join(out,'测试报告.md'),lines.join('\n'));
}
