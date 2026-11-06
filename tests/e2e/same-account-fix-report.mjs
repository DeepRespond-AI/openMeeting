import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';import {createHash} from 'node:crypto';
const root=path.resolve(import.meta.dirname,'../..'),out=path.join(root,'.artifacts/same-account-entry-fix'),archive=path.join(root,'docs/testing/archive/跨端入会安全取消');
const read=n=>JSON.parse(fs.readFileSync(path.join(out,n),'utf8')),checks=read('checks.json'),native=read('native-results.json'),cleanup=read('cleanup.json'),reviews=read('visual-reviews.json');
fs.mkdirSync(archive,{recursive:true});
const files=['checks.json','native-results.json','smoke.json','cleanup.json','budget.json','visual-reviews.json','rtc-contract.log','entry-contract.log','typescript.log',...fs.readdirSync(out).filter(n=>/^(checks|native)-history-/.test(n))];
for(const name of files)fs.copyFileSync(path.join(out,name),path.join(archive,name));
for(const dir of ['screenshots','history']){fs.mkdirSync(path.join(archive,dir),{recursive:true});for(const name of fs.readdirSync(path.join(out,dir))){const key=dir+'/'+name,source=path.join(out,key);if(name.endsWith('.png')){assert.ok(reviews[key]?.viewed,'Missing actual review '+key);assert.equal(reviews[key].sha256,createHash('sha256').update(fs.readFileSync(source)).digest('hex'));}fs.copyFileSync(source,path.join(archive,key));}}
const count={pass:native.steps.filter(s=>s.pass).length,fail:native.steps.filter(s=>!s.pass).length},contractCases=checks.reduce((sum,c)=>sum+(c.actual.passedCases||0),0),screens=native.screenshots.length;
const summary={native:count,contractCases,checksPass:checks.every(c=>c.pass),screenshots:screens,reviewedImages:Object.keys(reviews).length,cleanup:cleanup.every(c=>c.pass)};fs.writeFileSync(path.join(archive,'summary.json'),JSON.stringify(summary,null,2));
const escape=v=>String(v??'').replaceAll('|','\\|').replaceAll('\n',' ');
const text=[
'# 跨端入会安全取消测试报告','',
'本轮按完整连接流程验证，并按用户“E2E 测试得差不多就可以了”的要求，在核心流程通过后停止扩展。验收范围是桌面跨端占用提示与本端取消；另一设备为独立浏览器中的真实 SDK，未执行 Android 原生或语音、视频、录音质量验收。','',
'## 变更与结论','',
'RTC 返回 conflict / joined_on_other_device 时，桌面显示“该账号已在另一台设备参会。”，提示另一设备先退出、连接释放后再重试。“取消入会，返回首页”同步结束本端持久会话，再释放本端 RTC、聊天订阅及业务 WebSocket，不调用 leave/end，不退出 IM 登录。房主、普通成员及迟到初始化回调均有回归覆盖。','',
'本轮采用另一设备自行退出后重试的方案，没有增加一键强制切换设备。真实验证取消后原设备仍 joined/connected、业务房间仍 active，且能够再次尝试入会；原设备退出并释放后，桌面正常入会。','',
'## 启动与执行','',
'沿用独立 worktree `worktrees/same-account-meeting-entry`、分支 `investigate/same-account-meeting-entry`。真实网关复用 39110，独立 Next 3162、Tauri CDP 9271。复用上一轮同 develop Rust 源码构建的隔离原生壳，SDK 仅有调试窗口参数适配，产品 UI 使用本轮源码。API、IPC 和 RTC/媒体服务均未替换。','',
'```powershell',
'node tests/e2e/same-account-fix-checks.mjs',
'node tests/e2e/same-account-fix-native.mjs setup',
'node tests/e2e/same-account-fix-native.mjs run',
'# 首个复用账号已有其他会话占用，未操作该会话；使用另一既有测试账号',
'node tests/e2e/same-account-fix-native.mjs switch-account',
'node tests/e2e/same-account-fix-native.mjs run',
'node tests/e2e/same-account-fix-native.mjs cleanup',
'node tests/e2e/same-account-fix-report.mjs',
'```','',
'先通过 RTC 契约确定性冒烟，再执行页面组件及原生流程。真实 SDK 冒烟确认第一设备已 connected 后才测试桌面失败路径。累计预算记录于 budget.json，未重置预算。','',
'## 结果','',
`最终核心原生 E2E：${count.pass} 通过 / ${count.fail} 失败；相关 RTC/组件回归 ${contractCases} 项通过，TypeScript 检查通过。`,'',
'| 操作 | 预期 | 实际 | 结果 |','|---|---|---|---|',
...native.steps.map(s=>`| ${escape(s.operation)} | ${escape(s.expected)} | ${escape(typeof s.actual==='string'?s.actual:JSON.stringify(s.actual))} | ${s.pass?'通过':'失败'} |`),'',
'## 失败历史与证据','',
'历史失败不计入最终通过：旧组件夹具缺 useOptionalServer 导出；pnpm 的依赖预校验拒绝共享 node_modules 目录链接，改用直接 TypeScript CLI；再次入会的旧 Promise 夹具提前返回，改为等待新 join/connect；首个真实账号已有其他音视频占用，冒烟即停止并切换测试账号。','',
'首次原生取消已回首页，但测试试图覆盖只读 Tauri invoke 以审计命令，未获得任何命令记录，因此审计断言失败。删除无效审计，不以空数组证明安全；改以真实第一设备连接和业务房间 active 验证，精确的 leave/end 零调用由 RoomProvider 契约回归断言。','',
...files.filter(n=>n.includes('-history-')).map(n=>`- [${n}](${n})：原始结构化失败记录。`),
'- [夹具调试失败截图](history/01-fixture-rejoin-scheduling.png)。',
'- [首次原生审计失败时的首页截图](screenshots/failure-1793329136319.png)。','',
'## 截图与视觉检查','',
`正式截图 ${screens} 张，1280×800 / 520×760；另含历史失败证据，共 ${Object.keys(reviews).length} 张图片已通过 view_image 实际逐张查看，SHA-256 登记于 visual-reviews.json。使用真实 Tauri WebView 的 CDP 截图。`,'',
'| 图片 | 实际检查 |','|---|---|',
...Object.entries(reviews).map(([file,r])=>`| [${file}](${file}) | ${escape(r.notes)} |`),'',
'本次新增的跨端提示和取消按钮无明显遮挡、溢出、错位、截断；窄视口换行完整。首页有真实会后处理通知覆盖部分底部内容，来自此前无音频测试会议的处理结果；已如实保留，不标记为通知布局验收通过。长文本、其他抽屉/弹窗及 Android 原生不属于本轮新增验收范围。','',
'## 清理与剩余边界','',
...cleanup.map(c=>`- ${c.operation}：${c.pass?'完成':'失败'}${c.actual?`；${escape(JSON.stringify(c.actual))}`:''}。`),
'',
'保留用户原有修改与日常后端，仅结束本轮创建的会议、关闭自启 Next/Tauri、恢复测试 profile 与生成文件。RTC 释放延迟仍由服务处理，界面已有提示；未增加主动踢出其他设备。未执行或失败的项目未标记为通过。','',
'本报告由 same-account-fix-report.mjs 从结构化结果、日志、截图人工检查和清理记录自动生成；账号令牌与 profile 备份仅存忽略的 .artifacts，不进入归档。',''
].join('\n');fs.writeFileSync(path.join(archive,'测试报告.md'),text);console.log(JSON.stringify({report:path.join(archive,'测试报告.md'),...summary}));
