import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';import {createHash} from 'node:crypto';
const root=path.resolve(import.meta.dirname,'../..'),out=path.join(root,'.artifacts/mobile-rtc-release-race'),archive=path.join(root,'docs/testing/archive/移动端快速退房重入');
const read=n=>JSON.parse(fs.readFileSync(path.join(out,n),'utf8').replace(/^\uFEFF/,'')),checks=read('checks-summary.json'),ui=read('ui-results.json'),visual=read('visual-results.json'),analyze=read('analyze-summary.json'),reviews=read('visual-reviews.json'),cleanup=read('cleanup.json');
const counts={testsPassed:checks.actual.passed,testsFailed:checks.actual.failed,uiPassed:ui.filter(r=>r.pass).length,uiFailed:ui.filter(r=>!r.pass).length,analyze:analyze.pass,screenshots:visual.filter(r=>r.screenshot).length};
fs.mkdirSync(archive,{recursive:true});
const files=['checks-summary.json','ui-summary.json','visual-summary.json','analyze-summary.json','smoke-summary.json','checks.log','ui.log','visual.log','analyze.log','smoke.log','ui-results.json','visual-results.json','visual-reviews.json','cleanup.json','budget.json',...fs.readdirSync(out).filter(n=>/history-/.test(n)&&/\.(json|log)$/.test(n))];
for(const name of files)fs.copyFileSync(path.join(out,name),path.join(archive,name));
fs.mkdirSync(path.join(archive,'history'),{recursive:true});for(const name of fs.readdirSync(path.join(out,'history')).filter(n=>n.endsWith('.json')))fs.copyFileSync(path.join(out,'history',name),path.join(archive,'history',name));
for(const [file,r]of Object.entries(reviews)){assert.ok(r.viewed,'Not viewed: '+file);assert.equal(r.sha256,createHash('sha256').update(fs.readFileSync(path.join(out,file))).digest('hex'));fs.mkdirSync(path.dirname(path.join(archive,file)),{recursive:true});fs.copyFileSync(path.join(out,file),path.join(archive,file));}
fs.writeFileSync(path.join(archive,'summary.json'),JSON.stringify(counts,null,2));
const esc=v=>String(v??'').replaceAll('|','\\|').replaceAll('\n',' ');
const text=[
'# 移动端快速退房重入测试报告','',
'本轮按完整用户流程验证，核心流程通过后停止扩展 E2E。使用真实 Flutter 控制器、房间页面、工具栏、退出确认及错误组件，业务仓储和 IM/RTC 公共接口为确定性夹具。未连接真实 RTC、未在 Android/iOS 原生设备验收，不把夹具连接状态当作真实媒体验收。','',
'## 修复结果','',
'在 develop 上修复旧连接与新房间争用：业务离会后立即结束本端页面，新业务房间创建不等待旧 RTC 清理。旧请求被取消并按代次隔离，迟到 handle 仅释放自己；只有新 RTC 接入等待串行释放链。若 SDK 查询到 leaving，则后台轮询至释放，超时给出明确错误和重试入口。没有固定强制等待，每次普通重入不额外等待 15 秒。','',
'已明确校正首次实现与桌面差异：桌面 RoomProvider.leave 异步调用 media.leave，新业务 join 不等待；ImChannelMediaClient.connect 才等待旧 releaseTask。移动 leave/join 最终同样使用后台 cleanup，仅 _connectMedia 等释放链。','',
'## 启动方式与边界','',
'基线 develop 1746dd7；fetch 后本地领先远端一提交，未覆盖本地提交或用户配置。未新建 worktree。先读取项目、移动开发、启动与测试说明，探测到既有 3118/39110 服务与 emulator-5554，未启动、停止或修改这些服务/设备及其登录态。','',
'运行方式（仓库根目录）：','',
'```powershell',
'node tests/e2e/mobile-rtc-release-race.mjs smoke',
'node tests/e2e/mobile-rtc-release-race.mjs checks',
'node tests/e2e/mobile-rtc-release-race.mjs ui',
'node tests/e2e/mobile-rtc-release-race.mjs visual',
'node tests/e2e/mobile-rtc-release-race.mjs analyze',
'node tests/e2e/mobile-rtc-release-race-report.mjs',
'```','',
'runner 调用已有 Flutter 工具，在无头 Flutter 测试进程中加载生产移动页面，无独立 HTTP 开发服务。先冒烟 SDK/仓储故障夹具，再执行成功及关键失败流程；ui 断言通过后 visual 统一截图。累计 30 分钟预算由 budget.json 持久化，调试未重置。','',
'## 最终验证','',
`定向测试 ${counts.testsPassed} 通过 / ${counts.testsFailed} 失败；双视口页面 ${counts.uiPassed} 步通过 / ${counts.uiFailed} 步失败；静态分析${counts.analyze?'通过':'失败'}。截图复跑不重复计入功能通过数量。`,'',
'- 控制器回归包含：旧 SDK attach 未返回时立即离会并创建下一间业务房间；旧结果返回和 close 完成前禁止第二次 SDK attach；迟到查询、重复清理、同房 resume、其他房间会话保护、取消及总超时。',
'- UI 覆盖实际退出弹窗、立即开启下一房间、平台 leaving 等待、超时、重试恢复和正常离会。业务/媒体 fixture 的状态通过 Completer、明确 leaving 分支及独立超时参数稳定触发，不在 E2E 中猜测故障。','',
'| 视口 | 操作 | 预期 | 实际 | 结果 |','|---|---|---|---|---|',
...ui.map(r=>`| ${r.viewport} | ${r.operation} | ${esc(r.expected)} | ${esc(r.actual)} | ${r.pass?'通过':'失败'} |`),'',
'## 视觉检查','',
'无 in-app browser，使用 Flutter RenderRepaintBoundary 原始截图替代。视口 390×800、1200×800，后者为移动 Flutter 宽屏布局，不能作为桌面 Tauri 验收。所有归档图片均逐张实际查看并记录 SHA-256。','',
'| 图片 | 检查结果 |','|---|---|',
...Object.entries(reviews).map(([file,r])=>`| [${file}](${file}) | ${esc(r.notes)} |`),'',
'稳定帧中的等待/超时文案、重试按钮及退出确认弹窗在两个视口中完整，无明显溢出或截断。第 3、10 张专门记录快速切房的过渡帧：新房间已打开，旧离会弹层仍在淡出；该过渡画面不标为稳定布局通过。截图中的“进入测试会议”是测试入口夹具，不是产品首页。长文本换行由真实超时提示及离会说明覆盖；其他文件表格/抽屉与音视频预览不在本轮范围。','',
'## 历史失败保留','',
'首次定向测试 26 通过、1 失败：Stopwatch 与 fakeAsync 时钟不一致，改为可取消的总截止计时器后回归通过。页面脚本缺少模型导入、重复离开图标定位及在假时间 teardown 等待 Future 的问题均保留在历史日志；未把中途通过步骤当整套通过。两次页面中间失败截图见 failure 图片。','',
'首轮截图范围未包含 Navigator 弹层，另有只推进一帧导致弹窗尚未绘制；视觉复查发现后，改用 MaterialApp builder 外层截图并推进完整弹窗动画，原缺失弹窗截图保留于 history，最终正式截图含真实弹窗。','',
'用户指出初版不应阻塞新业务房间后，已去掉 leave/join 对 cleanup 的等待，并新增旧 RTC 未完成但下一业务房间已 active 的显式断言。旧版测试日志仅供追溯，不代表最终行为。','',
'## 清理与剩余风险','',
...cleanup.map(r=>`- ${r.operation}：${r.pass?'完成':'未通过'}${r.actual?`；${esc(JSON.stringify(r.actual))}`:''}。`),'',
'未创建真实业务会议或修改个人数据，无测试录音下载。仅终止本轮卡住的 Flutter 测试进程，最终测试进程均已结束；复用的日常后端/前端与模拟器未被本任务关闭。','',
'平台自身的清理耗时仍取决于 IM/RTC；本轮修复客户端竞态，没有声称平台立刻释放。桌面已有按本人同房 leaving 会话调用服务端 recover 的显式能力，本轮不扩展到移动端；不同房间的正常会话不会自动被踢出。真实 Android/iOS 快速切房与音视频质量仍需联调，现有证据限于真实控制器与页面、显式 SDK/业务夹具。','',
'报告由 mobile-rtc-release-race-report.mjs 从结构化步骤、日志、图片实际查看记录及清理结果自动生成。',''
].join('\n');fs.writeFileSync(path.join(archive,'测试报告.md'),text);console.log(JSON.stringify({report:path.join(archive,'测试报告.md'),...counts}));
