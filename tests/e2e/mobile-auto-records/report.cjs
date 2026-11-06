// Assemble existing evidence. This command never starts a test or upgrades a
// failed/unexecuted check to passed.
const fs=require('node:fs'),path=require('node:path'),cp=require('node:child_process'),crypto=require('node:crypto');
const root=path.resolve(__dirname,'../../..'),out=path.join(root,'.artifacts/mobile-auto-records');
const read=f=>JSON.parse(fs.readFileSync(path.join(out,f),'utf8'));
const decode=f=>{const b=fs.readFileSync(f);return b[0]===255&&b[1]===254?b.subarray(2).toString('utf16le'):b.toString('utf8').replace(/^\uFEFF/,'');};
const digest=f=>crypto.createHash('sha256').update(fs.readFileSync(path.join(out,f))).digest('hex');
const count=rows=>({passed:rows.filter(r=>r.passed===true).length,failed:rows.filter(r=>r.passed===false).length});
const link=f=>`[${f}](${encodeURI(f)})`;
const cell=x=>(typeof x==='string'?x:JSON.stringify(x)).replaceAll('|','\\|').replace(/[\r\n]+/g,' ');
const secrets=read('accounts.private.json').flatMap(a=>[a.password,a.token]).filter(x=>typeof x==='string'&&x.length>5);
for(const dir of [out,path.join(out,'logs')])for(const name of fs.readdirSync(dir).filter(n=>/\.(txt|log)$/.test(n))){
  const file=path.join(dir,name);let text=decode(file);
  for(const secret of secrets)text=text.split(secret).join('[REDACTED]');
  text=text.replace(/Bearer\s+[A-Za-z0-9._~+\/-]+=*/gi,'Bearer [REDACTED]')
    .replace(/eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+/g,'[JWT REDACTED]')
    .replace(/https?:\/\/[^\s"'<>]+\?(?=[^\s"'<>]*(?:signature|token|credential|X-Amz|jwt)=)[^\s"'<>]+/gi,url=>url.split('?')[0]+'?[SIGNED QUERY REDACTED]');
  fs.writeFileSync(file,text);
}
const ui=read('ui-results.json'),completed=read('completed-ui-results.json'),run=read('ui-run.json');
const api=read('api-results.json'),smoke=read('fixture-smoke.json'),notice=read('notice-results.json');
const visual=read('visual-reviews.json'),extra=read('supplemental-capture.json'),cleanup=read('cleanup.json');
const budget=read('budget-outcome.json'),build=read('build-final.json');
for(const row of visual)if(row.inspected!==true||digest(row.screenshot)!==row.sha256)throw Error('Uninspected/changed screenshot '+row.screenshot);
const log=f=>decode(path.join(out,'logs',f));
const unit=/\+(\d+): All tests passed!/.exec(log('units-after-race.txt'));
const apk='apk/openmeeting-auto-records-debug.apk';
const aapt=path.join(process.env.LOCALAPPDATA,'Android/Sdk/build-tools/36.0.0/aapt.exe');
const badging=cp.execFileSync(aapt,['dump','badging',path.join(out,apk)],{encoding:'utf8',maxBuffer:1000000});
const checks=[
  {action:'最终静态检查',passed:build.analyzeExit===0&&/No issues found!/.test(log('analyze-after-race.txt')),log:'logs/analyze-after-race.txt'},
  {action:'最终全量串行单元/组件测试',passed:build.unitExit===0&&!!unit,passedCount:unit?Number(unit[1]):0,log:'logs/units-after-race.txt'},
  {action:'消息快照订阅竞争回归',passed:/All tests passed!/.test(log('message-race-after.txt')),log:'logs/message-race-after.txt',regressionBefore:'logs/message-race-before.txt'},
  {action:'代码生成',passed:/Built with build_runner/.test(log('codegen-after-race.txt')),log:'logs/codegen-after-race.txt'},
  {action:'最终Android debug构建',passed:build.buildExit===0&&/Built build/.test(log('android-after-race.txt')),log:'logs/android-after-race.txt',file:apk,
    packageName:/package: name='([^']+)'/.exec(badging)?.[1],bytes:fs.statSync(path.join(out,apk)).size,sha256:digest(apk),installed:false},
  {action:'纯组件视觉补拍运行器',passed:/All tests passed!/.test(log('visual-supplement-final.txt')),log:'logs/visual-supplement-final.txt'},
];
fs.writeFileSync(path.join(out,'checks.json'),JSON.stringify(checks,null,2));
const history=fs.readdirSync(path.join(out,'logs')).filter(f=>/^ui-attempt-\d+\.txt$/.test(f)).sort().map(f=>({
  log:'logs/'+f,passed:/All tests passed!/.test(log(f)),failed:/Some tests failed|Test failed|Compilation failed/.test(log(f))}));
const summary={generatedAt:new Date().toISOString(),branch:'feat/mobile-desktop-parity',base:'ae00f96',
  primaryValidation:'API fallback',allFeaturesVerified:false,latestE2e:{attempt:run.attempt,runnerPassed:run.passed,...count(ui)},
  previousCompletedE2e:{attempt:8,runnerPassed:/All tests passed!/.test(log('ui-attempt-08.txt')),...count(completed)},
  unit:{passed:unit?Number(unit[1]):0,failed:build.unitExit===0?0:null},api:count(api),fixture:count(smoke),realImNotice:count(notice),
  visual:{inspected:visual.length,...count(visual)},supplementalCapture:count(extra),checks:count(checks),cleanup:count(cleanup),
  finalOwnedResourcesClosed:cleanup.some(r=>r.action.startsWith('端口复核补查')&&r.passed)&&cleanup.at(-1).passed,
  postRaceFixE2eRevalidated:false,nativeExecuted:false,syntheticPcm:true,realModelsVerified:false};
fs.writeFileSync(path.join(out,'summary.json'),JSON.stringify(summary,null,2));
const lines=[
 '# 移动端自动录音、共享记录与消息入口隐藏测试报告','',
 '> 由 `node tests/e2e/mobile-auto-records/report.cjs` 读取结构化步骤、实际日志、预算与看图记录生成。','',
 '**本轮为完整功能集成；最终按约定降级为 API 验证为主，不能认定所有功能均无问题。** 第08轮真实网络 Flutter 页面曾完整完成116步，但后续复跑会中消息更新间歇超时，最新第10轮失败。定位到快照先发送、后订阅广播存在丢失确认窗口，已用可重复单测验证修复；累计30分钟预算耗尽后没有继续业务E2E，所以修复后的完整页面仍待复验。','',
 '工作分支 `feat/mobile-desktop-parity`，worktree `<repo>`，本轮基于本地最新 `develop@ae00f96`。fetch时远程仍为357a499。本轮没有提交或推送，也没有覆盖主工作区未提交改动。','',
 '## 结果与证据边界','',
 '| 层级 | 通过 | 失败 | 结论 |','|---|---:|---:|---|',
 `| 最终单元/组件 | ${summary.unit.passed} | ${summary.unit.failed} | 显式opt-in在线测试不包含在此数量中 |`,
 `| API回归 | ${summary.api.passed} | ${summary.api.failed} | 真实隔离服务/数据库；PCM为合成静音 |`,
 `| 失败夹具页面前冒烟 | ${summary.fixture.passed} | ${summary.fixture.failed} | 503下载/结束/聊天、403设置、延迟和恢复 |`,
 `| 真实IM通知 | ${summary.realImNotice.passed} | ${summary.realImNotice.failed} | 真实outbox→平台→SDK→生产过滤器，结束/处理失败事件均到达 |`,
 `| 第08轮完整页面（历史成功） | ${count(completed).passed} | ${count(completed).failed} | 58条主断言后58条截图回放，运行器通过；不代表修复后复验 |`,
 `| 最新第${run.attempt}轮页面 | ${count(ui).passed} | ${count(ui).failed} | 运行器${run.passed?'通过':'失败'}；保留失败 |`,
 `| 纯视觉组件补拍 | ${count(extra).passed} | ${count(extra).failed} | 生产组件+静态数据，不计作业务E2E |`,
 `| 实际看图 | ${count(visual).passed} | ${count(visual).failed} | ${visual.length}张；12张原图采集不足保留失败，另补拍12张 |`,
 `| 静态/生成/竞争回归/构建/补拍运行器 | ${count(checks).passed} | ${count(checks).failed} | APK仅编译，未安装 |`,
 `| 清理步骤 | ${count(cleanup).passed} | ${count(cleanup).failed} | 保留首次端口脚本类型错误，最终补查和Gradle关闭均有证据 |`,'',
 '分层分别计数，不相加为全部能力通过数。最新页面失败、原图采集不足、真实模型未就绪及未执行项目均未改写为通过。','',
 '## 启动与环境','',
 '先阅读 mobile/DESIGN.md、README、自动录音方案、共享读取契约与现有产物规则。发现日常39110和另一组3160/3161/3163/3167及55439在运行，保留它们；探测平板无线ADB为offline。使用独立postgres容器55441、真实网关3260/用户3261/出站3263/会议3267，失败代理39330、桥接39331；专用业务数据库及三个专用账号，IM复用已有平台配置。','',
 '启动：设置 MEETING_READY_OUTPUT、MEETING_READY_PG_PORT=55441、MEETING_READY_PORT_OFFSET=100，运行 meeting-ready-services.py；设置转发器上游3260及桥接目录，启动fixture/bridge；独立冒烟通过后执行 run-ui.ps1。详细命令见[复现说明](../../tests/e2e/mobile-auto-records/README.md)。','',
 '页面采用实际Flutter无头渲染，生产App/路由/组件连接真实REST/WS/IM，视口390×844、1024×768。安全存储、平台宿主、录音可用性和播放器为明确VM适配；下载使用真实鉴权请求及文件写入，仅系统导出回调为替身。不能用页面或API证据声称原生摄像头/麦克风/音频输出/系统分享通过。','',
 '日常启动新分支开发版（本轮只完成APK编译，未在离线平板执行）：','',
 '```powershell','cd <repo>\\mobile','adb connect <device-id>','adb reverse tcp:39110 tcp:39110','flutter run -d <device-id> --dart-define=APP_ENV=dev --dart-define=OPENMEETING_SERVER_URL=http://127.0.0.1:39110','```','',
 '确保终端PATH包含Flutter和Android platform-tools，且业务后端也部署了最新develop共享读取契约。测试包使用独立 .parity debug applicationId；没有替换平板原应用或登录态。','',
 '## 累计预算及历史','',
 `首次E2E调试：${budget.firstAttempt}；截止：${budget.deadline}（UTC）。第08轮完成于${budget.lastCompletedFinishedAt}；之后为修正截图采集复跑，第10轮会中消息超时。预算耗尽后停止所有业务页面重试，保留最新失败；只继续API/单元/静态/编译及纯组件视觉补拍，没有重置起始时间。${link('budget-outcome.json')}。`,'',
 '| 运行日志 | 运行器结果 |','|---|---|',...history.map(h=>`| ${link(h.log)} | ${h.passed?'通过':'失败（保留）'} |`),'',
 '01：新建预定等待条件误匹配表单输入；02：滚动后未等待布局导致点击未命中；03：重试入口有多个，定位不唯一；04及10：会中消息UI更新超时；05：真实会后提示遮挡保存按钮；06：新增通知回调编译错误；07：步骤完成但测试容器定时器未释放；08完整通过；09截图增强时测试滚动定位放错步骤。历史文件没有被最后成功记录覆盖。','',
 '修复实际通知遮挡：根导航/Shell导航分别跟踪弹层，弹层期间仅刷新记录，导航和账号切换清理旧提示。消息订阅修复：先监听广播，再推初始快照；同步发送确认丢失可由单元测试稳定复现，修复前失败、修复后3项通过。它修复了已发现的竞争窗口，但缺少最后一次完整E2E确认，不宣称间歇超时已彻底消失。','',
 '初次全量测试曾有5个编译加载失败（provider select扩展缺少import），已修复；通知传输首次也因缺少Riverpod扩展import而未执行，第二次真实传输通过。首个补拍运行器因真实just_audio在VM销毁异常失败，改用明确VmPlayback后补拍运行器通过。首次冒烟恢复请求缺少日程参数返回422，改为鉴权探针后重复通过。首次启动端口冲突已保留，未关闭占用服务。','',
 '## 修复后检查','',
 '| 检查 | 结果 | 证据 |','|---|---|---|',...checks.map(r=>`| ${r.action} | ${r.passed?'通过':'失败'} | ${link(r.log)} |`),'',
 `最终APK：\`${checks.find(r=>r.file).packageName}\`，${checks.find(r=>r.file).bytes}字节；SHA256见checks.json。APK与凭证、数据库、缓存均在忽略目录，未纳入Git。`,'',
 '## 独立夹具冒烟','',
];
function table(rows){lines.push('| 操作 | 预期 | 实际 | 结果 | 截图 |','|---|---|---|---|---|');for(const r of rows)lines.push(`| ${cell(r.action)} | ${cell(r.expected??'')} | ${cell(r.actual??r.error??'')} | ${r.passed?'通过':'失败'} | ${r.screenshot?link(r.screenshot):'无'} |`);lines.push('');}
table(smoke);lines.push('## API与真实通知','');table(api);table(notice);
lines.push('真实worker保存32,044字节RIFF/WAV，主持人及提前离会成员下载字节一致；普通成员can_manage=false、写操作拒绝，非参会账号404，独立个人记录仍为私人范围。输入是明确合成PCM，隔离模型未就绪，实际处理状态failed；验证音频保留和错误展示，不是语音识别/纪要成功。','',
 '## 已完成第08轮页面步骤（历史证据）','',
 '主断言全部完成后统一回放截图。覆盖消息入口隐藏、独立录音/导入入口、设置滚动、预定CRUD/日期时间/校验、未来搜索/空态、真实发起会议、自动录音、会中设置/密码/等候室、接纳、会议IM故障重试/发送、结束失败恢复、下载错误/加载/成功、早退成员记录及只读、非参会者拒绝。独立录音/导入仅入口冒烟，不等于完整原生流程。','');table(completed);
lines.push('## 最新失败页面步骤','');table(ui);
lines.push('## 纯视觉补拍','',
 '原58张截图均实际查看，12张没有拍到目标弹窗/菜单或新建卡片；保留采集不足，另以静态数据打开生产组件、等待绘制、截图并关闭。补拍不含网络，不重跑业务E2E，不证明修复后的消息更新或真实新建操作成功。','');table(extra);
lines.push('## 逐图检查','',
 '原58张通过16张2×2联系表逐张查看，补拍12张逐张查看完整原图；检查遮挡、溢出、长文本、层级、响应式、加载/错误/空态。SHA256保证文件对应已查看版本。Flutter测试禁用阴影造成的黑描边不是生产设计变更；补拍只读菜单背景为静态无音频夹具的加载失败，不用于播放器验收。','',
 '| 图片 | 视口 | 查看方法 | 结果 | 观察 |','|---|---|---|---|---|',
 ...visual.map(r=>`| ${link(r.screenshot)} | ${r.viewport.join('×')} | ${cell(r.method)} | ${r.passed?'通过':'采集不足/保留失败'} | ${cell(r.notes)} |`),'',
 '## 清理','', '| 操作 | 结果 | 实际 |','|---|---|---|',
 ...cleanup.map(r=>`| ${cell(r.action)} | ${r.passed?'通过':'失败（保留）'} | ${cell(r.actual)} |`),'',
 '按本轮专用账号和数据库归属删除18个测试群及3个测试用户；本轮后端、代理、桥接、数据库及最终构建Gradle均已关闭。首次端口复核脚本把单个端口数值当数组，保留失败并补查成功。39110始终保留；另一组3160结束时已不监听，本轮未关闭它。平板始终offline，本轮未改显示/旋转或安装应用。','',
 '## 剩余风险及未执行','',
 '- **消息最终E2E复验尚未完成**：最后页面失败保留。订阅竞争已单测修复，最终241项与编译通过，不能据此替代页面确认。',
 '- 无线真机离线，未验证新增原生PCM回调、摄像头/麦克风/扬声器、权限拒绝恢复、播放、导出/导入系统选择器；不复用旧分支真机结论。',
 '- 独立录音/导入本轮只做入口冒烟及既有单元回归，不是其完整硬件E2E。iOS、长会、多机音画、后台及真实STT/LLM效果未执行。',
 '- 主持人异常退出可能丢失尚未确认的内存分片。移动独立屏幕共享、完整发言人/网络质量、后台推送和系统来电仍未实现。',
 '- 图片/视频/语音附件、完整联系人/群管理本轮未做完整E2E；独立消息入口已隐藏，会中聊天保留。','',
 '## 结构化产物','',...['summary.json','checks.json','api-results.json','fixture-smoke.json','notice-results.json','ui-run.json','ui-results.json','completed-ui-results.json','budget-outcome.json','supplemental-capture.json','visual-reviews.json','cleanup.json','platform-cleanup.json'].map(link),'',
 '竞争复现：'+link('logs/message-race-before.txt')+'；修复后：'+link('logs/message-race-after.txt')+'。',
);
fs.writeFileSync(path.join(out,'测试报告.md'),lines.join('\n'));console.log(JSON.stringify(summary,null,2));
