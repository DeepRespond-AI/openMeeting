import { spawnSync } from 'node:child_process';
import { mkdirSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const root = fileURLToPath(new URL('../../', import.meta.url));
const out = path.resolve(process.env.MEETING_UI_OUTPUT || path.join(root, '.artifacts/会议模块配置'));
mkdirSync(out, { recursive: true });
const tasks = [
  ['TypeScript类型检查', 'frontend', ['node_modules/typescript/bin/tsc', '--noEmit', '--incremental', 'false']],
  ['屏幕共享契约', 'frontend', ['tests/contracts/screen-share.mjs']],
  ['摄像头预览契约', 'frontend', ['tests/contracts/camera-preview.mjs']],
  ['会议语音契约', 'frontend', ['tests/contracts/meeting-audio.mjs']],
  ['录音故障恢复契约', 'frontend', ['tests/contracts/room-recording.mjs']],
  ['会议聊天契约', 'frontend', ['tests/contracts/meeting-im-chat.mjs']],
  ['通用hooks和lib单测', 'frontend', ['scripts/test-unit.mjs']],
  ['文档链接检查', '.', ['scripts/check-doc-links.mjs']],
];
const results = [];
for (const [name, directory, args] of tasks) {
  const result = spawnSync(process.execPath, args, { cwd: path.join(root, directory), encoding: 'utf8', windowsHide: true });
  const log = `check-${results.length + 1}.log`;
  writeFileSync(path.join(out, log), `${result.stdout || ''}${result.stderr || ''}${result.error || ''}`);
  const item = { name, command: `node ${args.join(' ')}`, exitCode: result.status ?? 1, log };
  results.push(item); console.log(JSON.stringify(item));
}
writeFileSync(path.join(out, 'checks.json'), JSON.stringify(results, null, 2));
if (results.some(r => r.exitCode !== 0)) process.exitCode = 1;
