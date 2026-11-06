import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const root=fileURLToPath(new URL('../../',import.meta.url));
const out=path.resolve(root,process.env.MEETING_READY_OUTPUT||'.artifacts/chat-sender-avatar-settings');
const archive=path.join(root,'docs/testing/archive/聊天身份与头像设置');
const read=name=>JSON.parse(fs.readFileSync(path.join(out,name),'utf8').replace(/^\uFEFF/,''));
const inputs=['checks.json','avatar-smoke.json','avatar-results.json','visual-results.json'];
const groups=inputs.map(file=>({file,rows:read(file).rows.filter(r=>!r.operation.startsWith('capture '))}));
const rows=groups.flatMap(g=>g.rows),passed=rows.filter(r=>r.pass).length,failed=rows.length-passed;
const visual=read('visual-results.json').rows.filter(r=>r.screenshot),reviews=read('visual-reviews.json');
const histories=fs.readdirSync(out).filter(f=>/^avatar-results-\d+\.json$/.test(f)).sort();
const budget=read('avatar-budget.json'),cleanup=read('platform-cleanup.json'),probe=read('final-probe.json');
const md=value=>String(value??'').replaceAll('|','\\|').replaceAll('\n',' ');
const names=[
 'TypeScript 类型检查','头像上传/取消/保存失败契约（4 个断言）','IM Provider 生命周期回归','会议 IM 聊天回归',
 '三端真实登录并就绪','坏图片失败入口单独冒烟','设置入口与无头像初始态','格式及 5 MB 限制',
 '真实头像上传与公开 URL HTTP 200','刷新后头像持久化','坏图片失败保留旧头像','实际上传取消且不晚到覆盖',
 '二次替换头像并持久化','三人会议 9 次消息接收与身份位置','私聊双端头像和姓名位置','重开聊天刷新对方新头像',
 '本地化错误提示与真实上传重试','独立图片下载错误夹具冒烟',
];
const lines=[
 '# 聊天身份与头像设置测试报告','',
 '分级：涉及 IM 资料读写和聊天消息布局，采用完整真实三端用户流程；使用 Tauri 开发版与实际 Rust IPC / IM SDK / RTC，不以 API 验证替代页面验收。报告由结构化结果自动组装。','',
 `本轮功能及相关代码检查 **${passed} 通过 / ${failed} 失败**；另有 ${visual.length} 张截图，其中 ${visual.filter(r=>reviews[r.screenshot]?.pass===true).length} 张已实际查看并通过布局检查。历史调试失败与附加文档检查另列，不改写为通过。`,'',
 '## 版本与启动','',
 '- 工作树：`<repo>`，分支 `fix/meeting-ready-im-sync`；已获取最新 `origin/develop` 并快进到 `fa310ad` 后开发。原工作树未提交修改及日常三端登录态保留。',
 '- 先读项目规则/启动说明并探测现有服务；保留日常 `:3118`，启动隔离 PostgreSQL `:55439`、真实 gateway/user/meeting `:3160/:3161/:3167`、出网代理 `:3163`。',
 '- `meeting-ready-services.py --env <本地服务配置>` 启动隔离后端；`meeting-ready-desktops.mjs --start` 启动当前工作树 Next `:3162` 与三份专用 Tauri 客户端，CDP `:9261/:9262/:9263`。所有命令先设 `MEETING_READY_OUTPUT=.artifacts/chat-sender-avatar-settings`。',
 '- 复用已缓存的 SDK 调试原生二进制，加载本次最新前端及 IM engine；未重新构建最新 Rust 安装包。无 in-app browser，使用 Playwright 连接真实 Tauri WebView 截图。',
 '- 执行顺序：`chat-avatar-checks.mjs` → `chat-avatar-settings.mjs --smoke` → 无参数流程 → 修复后 `--resume` → `--visual`。累计 E2E 用时约 '+(budget.usedMs/60000).toFixed(1)+' 分钟，预算 30 分钟，未重置。','',
 '## 功能与关键失败路径','',
 '成功上传使用真实 IM `user_avatar` 存储与 `users.updateMe`，公开图片 HTTP 200 且三端实际解码；本地未另建头像存储。确定性失败入口为损坏的 PNG 字节，在 UI E2E 前已单独验证 SDK 拒绝且旧资料不变。大小/格式错误为本地校验；截图中的坏图片错误来自该受控输入，不能称为真实 IM 服务故障。','',
 '| 检查 | 操作/预期与实际证据 | 结果 |','|---|---|---|',
 ...rows.map((r,i)=>`| ${names[i]||md(r.operation)} | ${md(r.operation)}；预期：${md(r.expected)}；实际：${md(JSON.stringify(r.actual))}${r.reusedEvidence?'；沿用本轮前次通过证据':''} | ${r.pass?'通过':'失败'} |`),'',
 '前 9 个功能步骤在同一轮已通过；修复返回会议的资料刷新后，`--resume` 保留这些证据并重跑第 10 步。最终文案在视觉阶段前单独重新断言并真实重试成功，未声称全流程均在最后一次修复后重跑。各步骤原始结果：',
 ...groups.map(g=>`- [${g.file}](${g.file})`),'',
 '## 截图与实际视觉检查','',
 '先完成断言，再统一采集 1280×800 和 520×760。逐张检查头像、姓名、气泡、加载进度、错误、无头像回退及长姓名，查看正常与滚动后的聊天区域；窄窗口设置侧栏可横向滚动，内容可纵向滚动。未为不存在的头像裁剪弹窗、表格或权限流程编造截图。','',
 '| 截图 | 视口 | 实际查看结果 |','|---|---|---|',
 ...visual.map(r=>`| [${path.basename(r.screenshot)}](${r.screenshot}) | ${r.actual.viewport.width}×${r.actual.viewport.height} | ${reviews[r.screenshot]?.pass===true?'通过：'+md(reviews[r.screenshot].notes):'待实际查看'} |`),'',
 '## 历史失败及对应截图','',
 '本轮发生 3 次调试失败：文件选择器与按钮同名导致可访问定位冲突；测试在 SDK 资料完成水合前读取 me；返回会议时常驻聊天面板未重新刷新对方资料。分别修复标签、等待条件、路由返回刷新，保留原失败结果和截图。失败截图只作为诊断证据，未标成视觉通过。','',
 ...histories.flatMap(file=>{
  const failedRows=read(file).rows.filter(r=>!r.pass);
  return [`- [${file}](${file})：${failedRows.filter(r=>!r.screenshot).map(r=>md(r.operation)).join('；')}`, ...failedRows.filter(r=>r.screenshot).map(r=>`  - [${r.screenshot}](${r.screenshot})`)];
 }),'',
 '## 清理与验证边界','',
 `- 结束会议并退出三端登录；删除测试群 ${cleanup.groupsDeleted} 个、测试 IM 用户 ${cleanup.usersDeleted} 个、已登记且元数据确认归属的头像文件 ${cleanup.avatarFilesDeleted} 个。清理错误 ${cleanup.errors.length} 个，见 [清理结果](platform-cleanup.json)。`,
 `- 专用 Next/三端/后端/出网服务与本次启动的 PostgreSQL 已停止；日常 :3118 与原三端均保留，见 [最终探测](final-probe.json)、[客户端停止](processes.json)、[服务停止](service-stop.json)、[结束会议](meeting-end-cleanup.json)。专用端口仍监听：${probe.ports.filter(p=>p.port!==3118&&p.listening).length}。`,
 '- 他人头像通过 SDK 缓存管理，在重开聊天或返回会议时主动刷新；未实现头像变更的跨用户即时推送。长姓名两行截断，完整名称保留在 title。',
 '- 旧头像及未登记的中间上传对象回收由 IM 存储生命周期负责，本轮仅确认清理登记的 3 个对象，未声称云端零残留。',
 '- 文件选择通过 Playwright 设置真实 File 输入；系统文件选择对话框、生产安装包、跨操作系统和真实硬件音视频质量未验收。截图时主持人沿用了开发客户端麦克风/录制偏好，随后主动关闭媒体并结束会议；未将该状态作为音频质量通过证据。测试脚本事后加入合成采集保护，新增保护本轮仅做语法检查，未冒充已重新执行。',
 '- 本轮只覆盖头像和身份展示；群共享文件、历史文件上传故障及其他媒体控制不在该结论范围。','',
 '## 附加文档检查','',
 '当前文档链接检查（不含历史档案）通过。全档案链接检查失败 1 项：另一份历史会议异常处理报告引用的 native.log 与 Rust.log 缺失；已核对本次修改前 HEAD 即存在该缺失。未为使检查通过而补造日志。详见 [结构化结果](docs-links.json) 和 [实际输出](docs-links.txt)。','',
 '## 可复跑入口','',
 '- [测试脚本](../../../../tests/e2e/chat-avatar-settings.mjs)、[代码检查](../../../../tests/e2e/chat-avatar-checks.mjs)、[报告生成器](../../../../tests/e2e/chat-avatar-report.mjs)。',
 '- 活动产物 `.artifacts/chat-sender-avatar-settings/`；精选归档为当前目录。账号密码、服务器配置、二进制与录制原始文件不归档。',
];
fs.writeFileSync(path.join(out,'测试报告.md'),lines.join('\n')+'\n');
fs.mkdirSync(archive,{recursive:true});
const extras=['visual-reviews.json','avatar-budget.json','platform-cleanup.json','final-probe.json','processes.json','service-stop.json','meeting-end-cleanup.json','capture-disabled.json','docs-links.json','docs-links.txt'];
for(const file of [...inputs,...extras,...histories,'测试报告.md',...fs.readdirSync(out).filter(f=>/^checks-.*\.txt$/.test(f))])fs.copyFileSync(path.join(out,file),path.join(archive,file));
for(const file of fs.readdirSync(out).filter(f=>/^failure-.*\.png$/.test(f)))fs.copyFileSync(path.join(out,file),path.join(archive,file));
fs.mkdirSync(path.join(archive,'screenshots'),{recursive:true});
for(const r of visual)fs.copyFileSync(path.join(out,r.screenshot),path.join(archive,r.screenshot));
console.log(JSON.stringify({passed,failed,visualReviewed:visual.filter(r=>reviews[r.screenshot]?.pass===true).length,archive}));
if(failed||visual.some(r=>reviews[r.screenshot]?.pass!==true)||cleanup.errors.length)process.exitCode=1;
