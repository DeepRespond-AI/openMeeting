// Assemble executed results and explicit image reviews; never infer visual approval.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';

const output = path.resolve(process.env.CHAT_COMPOSER_OUTPUT ?? '.artifacts/mobile-meeting-chat-composer-20261029');
const read = name => {
  const bytes = fs.readFileSync(path.join(output, name));
  return bytes[0] === 0xff && bytes[1] === 0xfe ? bytes.subarray(2).toString('utf16le') : bytes.toString('utf8');
};
const json = name => JSON.parse(read(name));
const rows = json('results.json'), reviews = json('visual-reviews.json');
const cleanup = json('cleanup.json'), execution = json('execution-finished.json');
const historical = json('history/review.json');
const assertions = rows.filter(r => r.phase === 'assertions');
const smoke = rows.filter(r => r.phase === 'fixture-smoke');
const replay = rows.filter(r => r.phase === 'screenshots');
const pictures = replay.filter(r => r.screenshot).map(r => {
  const hash = crypto.createHash('sha256').update(fs.readFileSync(path.join(output, r.screenshot))).digest('hex');
  const review = reviews.find(item => item.screenshot === r.screenshot && item.sha256 === hash);
  return { ...r, review, pass: review?.viewed === true && review?.pass === true };
});
const count = group => ({ passed: group.filter(r => r.pass).length, failed: group.filter(r => !r.pass).length });
const actionLog = read('message-actions.log');
const messageActions = { passed: Number(actionLog.match(/\+(\d+): All tests passed!/)?.[1] ?? 0),
  runPassed: actionLog.includes('All tests passed!') };
const summary = { base: 'd196656', branch: 'feat/mobile-home-grid', assertions: count(assertions), fixture: count(smoke),
  screenshotReplay: count(replay), visual: count(pictures), messageActions,
  staticClean: read('analyze-final.log').includes('No issues found!'),
  elapsedMs: execution.elapsedMs, limitMs: execution.limitMs, cleanup };
fs.writeFileSync(path.join(output, 'summary.json'), JSON.stringify(summary, null, 2));
const cell = value => String(typeof value === 'object' ? JSON.stringify(value) : value ?? '').replaceAll('|', '\\|').replaceAll('\n', ' ');
const report = `# 移动端会中聊天输入区测试报告

验证分级：局部布局和表情交互修改。使用真实 RoomChatPanel、ConversationChatPage、MeetingChatComposer、消息列表与发送控制器，执行双视口无头 Flutter 页面流程，覆盖受影响路径及发送成功冒烟；另执行已有消息复制、删除和撤回回归。本轮没有在浏览器、Android 模拟器或真机运行 App，不将页面夹具测试写为原生端到端验收。

## 改动

已 fetch 并快进同步最新 origin/develop（${summary.base}），工作分支 ${summary.branch}。会中输入区改为附件、表情、输入框、发送同一行；移除会中的停止播放与额外工具行；沿用现有深色主题、长度上限和三行输入。表情与桌面端相同，分笑脸、手势和符号三组，可按光标插入并保留原草稿，超过长度上限时拒绝额外插入。

## 启动及复现

工作目录：\`<repo>\\mobile\`。启动前已探测原有 :39110 服务及 emulator-5554；没有启动新的后端、前端服务或模拟器，没有操作原有 App 登录态。

\`\`\`powershell
$env:PUB_HOSTED_URL='https://pub.flutter-io.cn'
$env:FLUTTER_STORAGE_BASE_URL='https://storage.flutter-io.cn'
$env:Path='<flutter-sdk>\\bin;'+$env:Path
flutter test --no-pub test/acceptance/meeting_chat_composer_ui_test.dart --reporter expanded
flutter test --no-pub test/core/im/chat_message_actions_test.dart --reporter expanded
dart analyze
\`\`\`

页面由 Flutter 测试运行器启动；业务账号、SDK 消息传输和附件选择/上传为显式夹具。文字与表情发送经过生产 MessagingActions.send/perform，回显来自 SDK 消息快照边界。附件仅验证菜单派发到既有动作和错误恢复，不测试系统文件选择与真实上传。键盘通过 280px viewInsets 模拟占位，不是 Android 输入法验收。

输出默认在本目录。另起验证请将 CHAT_COMPOSER_OUTPUT 设置为新的绝对路径。E2E 调试累计预算 30 分钟，同轮不重置；独立冒烟先验证 503 连续两次且可恢复，双视口全部断言通过后才统一重放截图。最终停止 E2E 调试时累计 ${Math.round(execution.elapsedMs / 1000)} 秒。

## 最终执行结果

- 夹具独立冒烟：${summary.fixture.passed} 通过 / ${summary.fixture.failed} 失败。
- 页面功能断言：${summary.assertions.passed} 通过 / ${summary.assertions.failed} 失败。
- 截图重放断言：${summary.screenshotReplay.passed} 通过 / ${summary.screenshotReplay.failed} 失败，不重复计入功能数量。
- 已有消息操作回归：${messageActions.passed} 通过，整体通过=${messageActions.runPassed}。
- 静态分析：${summary.staticClean ? 'No issues found' : '未通过或缺少证据'}。
- 最终截图：${summary.visual.passed} 已查看并通过 / ${summary.visual.failed} 未通过，共 ${pictures.length} 张。

证据：[最终流程日志](ui-03.log)、[结构化步骤](results.json)、[消息操作回归](message-actions.log)、[静态分析](analyze-final.log)、[视觉检查与哈希](visual-reviews.json)、[清理](cleanup.json)。

| 视口 | 操作 | 预期 | 实际 | 结果 |
|---|---|---|---|---|
${[...smoke, ...assertions].map(r => `| ${cell(r.viewport)} | ${cell(r.operation)} | ${cell(r.expected)} | ${cell(r.actual)} | ${r.pass ? '通过' : '失败'} |`).join('\n')}

## 截图与视觉检查

视口：390×844 窄屏、1024×768 桌面/平板。无 in-app browser，使用无头 Flutter 截图；Windows 加载微软雅黑、MaterialIcons、Segoe UI Emoji，并仅在测试主题中指定 Emoji 字体回退。每张最终截图均通过 view_image 实际查看，再记录尺寸、SHA-256 和检查结论。检查输入行对齐、控件可见性、长文本、遮挡、层级、表情弹层打开/切换/滚动/关闭、发送异步状态及菜单。空态、加载、成功与错误均覆盖。本次无新权限或表格界面，相应状态不适用。

| 视口 | 状态 | 截图 | 检查结果 | 检查记录 |
|---|---|---|---|---|
${pictures.map(r => `| ${cell(r.viewport)} | ${cell(r.operation)} | [查看](${r.screenshot}) | ${r.pass ? '已查看，通过' : '未通过/未查看/哈希不匹配'} | ${cell(r.review?.notes)} |`).join('\n')}

## 保留的失败与修正记录

${historical.attempts.map(item => `- ${cell(item.result)} [证据](${item.evidence})。`).join('\n')}

历史截图的四张实际检查记录见 [历史视觉记录](history/review.json)，其中表情方框两张未通过，其余未查看截图不标记为视觉通过。最终采用第三轮日志和截图。

## 清理与剩余风险

${cell(cleanup.result)}

真实 Android 输入法、系统文件选择器、真实 IM 投递和附件上传未在本轮验收；原生 Emoji 字形也可能与 Windows 测试字体不同。没有修改音视频、录音或后端功能，相关能力不属于本次回归范围。实际设备需热重载或重新运行包含本次改动的 App 才能看到新布局。
`;
fs.writeFileSync(path.join(output, '测试报告.md'), report);
console.log(JSON.stringify(summary));
