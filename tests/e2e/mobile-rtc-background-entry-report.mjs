import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';import {createHash} from 'node:crypto';
const root=path.resolve(import.meta.dirname,'../..'),out=path.join(root,'.artifacts/mobile-rtc-background-entry'),archive=path.join(root,'docs/testing/archive/移动端后台连接不遮挡房间');
const read=n=>JSON.parse(fs.readFileSync(path.join(out,n),'utf8').replace(/^\uFEFF/,''));
const checks=read('checks-summary.json'),ui=read('ui-results.json'),visual=read('visual-results.json'),analyze=read('analyze-summary.json'),reviews=read('visual-reviews.json'),cleanup=read('cleanup.json');
fs.mkdirSync(path.join(archive,'screenshots'),{recursive:true});
for(const name of fs.readdirSync(out).filter(n=>/\.(json|log)$/.test(n))){
  if(name.endsWith('.log'))fs.writeFileSync(path.join(archive,name),fs.readFileSync(path.join(out,name),'utf8').replace(/[ \t]+$/gm,''));
  else fs.copyFileSync(path.join(out,name),path.join(archive,name));
}
for(const row of visual){const file=row.screenshot;assert.ok(file&&reviews[file]?.viewed,'Screenshot not viewed: '+file);const bytes=fs.readFileSync(path.join(out,file));assert.equal(reviews[file].sha256,createHash('sha256').update(bytes).digest('hex'));fs.copyFileSync(path.join(out,file),path.join(archive,file));}
const summary={testsPassed:checks.actual.passed,testsFailed:checks.actual.failed,uiPassed:ui.filter(r=>r.pass).length,uiFailed:ui.filter(r=>!r.pass).length,analyze:analyze.pass,screenshots:visual.length,cleanup:cleanup.every(r=>r.pass)};fs.writeFileSync(path.join(archive,'summary.json'),JSON.stringify(summary,null,2));
const esc=v=>String(v??'').replaceAll('|','\\|').replaceAll('\n',' ');
const text=[
'# 移动端后台连接不遮挡房间测试报告','',
'分级理由：本次只修改已入会页面的连接状态展示，复用现有快速切房完整流程验证受影响路径及成功冒烟。真实 Flutter RoomController、RoomPage、成员网格和操作栏参与执行；业务仓储、SDK 通道为明确夹具。未执行真实 IM/RTC、Android/iOS 原生或音视频质量验收。','',
'## 变更','',
'此前业务房间已创建，但 ActiveRoom 仍把 RTC idle/connecting/releasing 显示为整页加载，用户仍看到“等待上一次音视频”。现在 RoomActive 立即展示会议号、成员网格和操作栏；媒体准备只显示非阻塞文字，无旋转等待及伪错误。真正释放超时、连接失败保留错误和重试；初始业务 RoomJoining 仍允许加载。麦克风/摄像头开启条件不变。','',
'桌面实际顺序是业务切房不等待媒体 leave，新的 RTC connect 内部等待 releaseTask；桌面首次入会本身也有加载页。移动后台释放顺序保持上一提交不变，本轮单独移除已入会后的整页遮挡，不能描述为平台无需清理或桌面从不等待。','',
'## 执行方式','',
'develop 上开发；保留并行 AppSwitchListTile 等用户修改。既有服务 3118/39110 和登录态未动。本轮使用无头 Flutter 页面，不启动额外开发服务。','',
'```powershell',
"$env:MOBILE_RTC_RELEASE_OUTPUT='.artifacts/mobile-rtc-background-entry'",
'node tests/e2e/mobile-rtc-release-race.mjs smoke',
'node tests/e2e/mobile-rtc-release-race.mjs checks',
'node tests/e2e/mobile-rtc-release-race.mjs ui',
'node tests/e2e/mobile-rtc-release-race.mjs visual',
'node tests/e2e/mobile-rtc-release-race.mjs analyze',
'node tests/e2e/mobile-rtc-background-entry-report.mjs',
'```','',
'先单独冒烟确定性 SDK/仓储夹具，再验证 UI；断言通过后截图。SDK pending 与 leaving 使用既有 Completer 和明确分支，超时以测试配置触发。E2E 累计预算 30 分钟，budget.json 未在重跑中重置。','',
'## 最终结果','',
`定向回归 ${summary.testsPassed} 通过 / ${summary.testsFailed} 失败；双视口页面 ${summary.uiPassed} 步通过 / ${summary.uiFailed} 步失败；静态分析${summary.analyze?'通过':'失败'}。`,'',
'断言包括：SDK 仍 pending 时正常房间已显示；无 CircularProgressIndicator；成员网格存在；正常连接不显示错误/重试或误称重连；leaving 时房间仍可见；真实离会弹窗正常打开；快速切房、超时提示、重试恢复及正常离会保持可用。','',
'| 视口 | 操作 | 预期 | 实际 | 结果 |','|---|---|---|---|---|',
...ui.map(r=>`| ${r.viewport} | ${r.operation} | ${esc(r.expected)} | ${esc(r.actual)} | ${r.pass?'通过':'失败'} |`),'',
'## 截图实际检查','',
'使用 Flutter RenderRepaintBoundary 替代 in-app browser，覆盖 390×800、1200×800。后者为移动页面宽屏布局，不代表桌面 Tauri 验收。截图全部逐张实际查看，并记录 SHA-256。','',
'| 截图 | 检查 |','|---|---|',
...visual.map(r=>`| [${r.screenshot}](${r.screenshot}) | ${esc(reviews[r.screenshot].notes)} |`),'',
'稳定帧的背景连接提示、会议号、网格和工具栏未发现明显遮挡/溢出，窄屏文案完整换行。第 3、10 张记录退出弹窗淡出的过渡帧，只作异步转场证据，不判稳定布局通过。测试“进入测试会议”按钮为夹具入口，不是产品首页。文件表格、无关抽屉及真实设备权限不在本轮范围。','',
'## 清理与限制','',
...cleanup.map(r=>`- ${r.operation}：${r.pass?'完成':'未完成'}${r.actual?`；${esc(JSON.stringify(r.actual))}`:''}。`),'',
'没有创建真实会议、下载录音或修改个人登录态；所有本轮 Flutter 测试进程结束。未把未执行的真机/平台验证记为通过。RTC 平台若尚未释放，音视频仍需后台等待或重试；本轮解决的是房间界面被整页加载遮挡。修改源码后需重新构建安装包或重启/更新开发客户端，旧 APK 不会自行获得变化。','',
'本报告由 mobile-rtc-background-entry-report.mjs 从结构化结果、日志、截图检查与清理记录自动生成。归档日志仅去除终端行尾空白，原始输出保存在 .artifacts。',''
].join('\n');fs.writeFileSync(path.join(archive,'测试报告.md'),text);console.log(JSON.stringify({report:path.join(archive,'测试报告.md'),...summary}));
