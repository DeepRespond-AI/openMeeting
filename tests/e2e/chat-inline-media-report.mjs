import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {createHash} from 'node:crypto';
const root=fileURLToPath(new URL('../../',import.meta.url));
const out=path.resolve(root,process.env.CHAT_INLINE_MEDIA_OUTPUT||'.artifacts/聊天图片视频直接展示');
const read=(file,fallback)=>fs.existsSync(path.join(out,file))?JSON.parse(fs.readFileSync(path.join(out,file),'utf8')):fallback;
const data=read('browser/results.json',{steps:[]}),checks=read('checks.json',[]),smoke=read('browser/smoke.json',[]),reviews=read('visual-reviews.json',{}),cleanup=read('cleanup.json',{});
const assertions=data.steps.filter(s=>s.phase==='assertions'),captures=data.steps.filter(s=>s.phase==='screenshots'),shots=data.steps.filter(s=>s.screenshot);
const count=rows=>`${rows.filter(r=>r.pass).length}通过 / ${rows.filter(r=>!r.pass).length}失败`;
const cell=v=>String(typeof v==='object'?JSON.stringify(v):v??'').replaceAll('|','/').replaceAll('\n',' ');
const review=shot=>{const file='browser/'+shot.screenshot,r=reviews[file];return r&&r.sha256===createHash('sha256').update(fs.readFileSync(path.join(out,file))).digest('hex')?r:null;};
const history=fs.readdirSync(path.join(out,'browser')).filter(f=>/^attempt-.*\.json$/.test(f)).map(f=>({file:'browser/'+f,data:read('browser/'+f,{steps:[]})}));
const budget=read('browser/budget.json',{}),browserSeconds=budget.started?Math.round((fs.statSync(path.join(out,'browser/results.json')).mtimeMs-budget.started)/1000):null;
const lines=['# 聊天图片视频直接展示测试报告','',
 '分级：组件行为调整，验证受影响路径，加一条登录→发起会议→聊天发送成功流程。覆盖图片自动显示、视频行内点击播放、放大关闭、加载取消、错误重试与资源清理；未重跑RTC传输、后端群生命周期及原生设备全链路。使用修改后的真实Next产品页面和项目Playwright无头Chromium，IPC/IM/本地文件操作为显式夹具，合成图片与实际可解码MP4，不代替真实对象存储或Tauri本地协议验收。','',
 `worktree：${root}；运行上下文：${cell(read('run-context.json',{}))}。先阅读CLAUDE.md、quickstart.md、frontend/DESIGN.md，保留主工作区已有修改和服务。既有3118、39110探测：${cell(data.probe)}。确定性故障需要显式IPC/IM夹具，使用隔离测试登录身份；没有注销或覆盖现有登录态。原生CDP探测另见运行上下文。`,'',
 `当前结果：页面功能断言${count(assertions)}；截图阶段复核${count(captures)}；单独夹具冒烟${count(smoke)}。最终截图${shots.length}张，已实际查看且SHA-256匹配并视觉通过${shots.filter(s=>review(s)?.pass).length}张。${data.error?'本轮未完成：'+data.error:'本轮计划完成。'}`,'',
 '## 启动与执行','',
 '```powershell','pnpm --dir frontend install --frozen-lockfile --prefer-offline','node tests/e2e/chat-inline-media.mjs --smoke','node tests/e2e/chat-inline-media.mjs','node tests/e2e/chat-inline-media-checks.mjs','# 实际查看截图并记录visual-reviews.json后','node tests/e2e/chat-inline-media-report.mjs','```','',
 '页面脚本自动启动本worktree的Next :3144，使用OPENMEETING_NEXT_DIST_DIR=.next-chat-ui、OPENMEETING_E2E_DESKTOP_LAYOUT=1，启动随机本地端口业务夹具。正常构建不启用夹具替换。Bun复用现有可执行文件，OPENMEETING_BUN_BIN可覆盖；未升级SDK版本或改变依赖锁文件。','',
 `浏览器开始：${data.started}。budget.json记录同一30分钟调试预算，历史失败重跑共用，不重置；截至最终浏览器结束累计${browserSeconds}s；先通过两个视口全部功能断言，再统一采集。${cell(budget)}。使用非阻塞play触发、有超时的currentTime推进断言，每步60秒上限。历史失败仅从本产物目录的结构化结果读取，不沿用来源分支调试结论。`,'',
 '## 逐步结果','',
 '| 阶段/视口 | 操作 | 预期 | 实际 | 结果 | 截图 |','|---|---|---|---|---|---|',
 ...data.steps.map(s=>`| ${s.phase}/${s.viewport} | ${s.operation} | ${s.expected} | ${cell(s.actual)} | ${s.pass?'通过':'失败'} | ${s.screenshot?`[查看](browser/${s.screenshot})`:'—'} |`),'',
 '## 独立夹具与构建','',
 ...smoke.map(s=>`- ${s.operation}：${s.pass?'通过':'失败'}，预期${s.expected}，实际${cell(s.actual)}。`),'',
 ...checks.map(c=>`- ${c.operation}：${c.pass?'通过':'失败'}；${cell(c.actual)}；[日志](${c.log})。`),'',
 '单元通过数量及启动结果以checks.json和原始日志为准；未执行或失败的检查不计通过。','',
 '## 截图视觉检查','',
 '桌面1440×900，窄窗口390×844。每张图均用view_image实际打开；未查看或文件哈希变化时不计视觉通过。检查媒体比例、文件名截断、按钮可达、错误换行、遮挡、溢出、模态层级和响应式。覆盖聊天抽屉打开/关闭、图片与视频弹窗打开/关闭、长文本滚动及异步状态；本次不涉及表格。桌面文本完整放下，窄窗口已滚动到文末。','',
 ...shots.map(s=>{const r=review(s);return `- [${s.screenshot}](browser/${s.screenshot})：${r?`${r.pass?'已查看，通过':'已查看，失败'}；${r.notes}`:'未实际查看或哈希不匹配，不计视觉通过'}`;}),'',
 '## 历史失败与关闭结果','',
 ...history.map(h=>`- [历史轮次](${h.file})：${h.data.error||'参见原始步骤'}；失败步骤${h.data.steps.filter(s=>!s.pass).length}项，保留而不覆盖为通过。`),'',
 `本轮脚本关闭结果：${cell(data.cleanup)}；结束后端口检查：[cleanup.json](cleanup.json)，${cell(cleanup)}。仅关闭本次启动的测试进程，原有服务保留。`,'',
 '## 实现与剩余边界','',
 '- 图片和视频不再显示重复“预览 / 播放”。图片点击放大；视频点击在气泡内播放，另有放大按钮，保留下载图标。没有自动播放声音。',
 '- 自动加载仍经过SDK鉴权下载和受限本地协议；媒体进入可见区域才加载，保持30MB限制。行内缓存保留至消息卸载，关闭图片放大不会删掉仍在展示的缩略图。关闭聊天时暂停视频并释放缓存已通过夹具断言。',
 '- 用户图一是浏览器共享提示，页面不能用CSS改成自定义菜单。本次保留浏览器自带“隐藏/停止共享”，没有改原生采集路径。参见[W3C采集反馈规范](https://www.w3.org/TR/2026/WD-screen-capture-20260716/#feedback-and-interface-during-capture)。',
 '- 尚未完成本轮Tauri真实对象存储加载、实际硬件与生产包验收。只验证现有MP4在本机Chromium的解码，不承诺所有MOV/HEVC等格式；超限附件仍需下载后打开。',
 '- 本次图片/视频现行专项入口为chat-inline-media.mjs；旧验收快照按旧界面留存，不计为当前UI通过证据。','',
 '[结构化结果](browser/results.json) · [夹具冒烟](browser/smoke.json) · [开发日志](browser/next.log) · [视觉记录](visual-reviews.json) · [桌面trace](browser/trace-screenshots-1440.zip) · [窄窗口trace](browser/trace-screenshots-390.zip)',''];
fs.writeFileSync(path.join(out,'测试报告.md'),lines.join('\n'));
console.log(JSON.stringify({assertions:count(assertions),screenshotChecks:count(captures),screenshots:shots.length,reviewed:shots.filter(s=>review(s)?.pass).length}));
