import fs from 'node:fs';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
const root = fileURLToPath(new URL('../../', import.meta.url));
const out = path.resolve(root, process.env.SHARED_RECORDS_OUTPUT || '.artifacts/meeting-shared-records');
fs.mkdirSync(out, { recursive: true });
const rows = [];
for (const [name, binary, args, cwd] of [
  ['TypeScript', process.execPath, ['node_modules/typescript/bin/tsc', '--noEmit'], path.join(root, 'frontend')],
  ['recording-queue', process.execPath, ['tests/contracts/room-recording.mjs'], path.join(root, 'frontend')],
  ['IM-contract', process.execPath, ['tests/contracts/meeting-im-chat.mjs'], path.join(root, 'frontend')],
  ['frontend-unit', process.execPath, ['scripts/test-unit.mjs'], path.join(root, 'frontend')],
  ['Rust', 'cargo', ['check', '--offline', '--locked', '--lib', '-p', 'openmeeting'], root],
]) {
  const result = spawnSync(binary, args, { cwd, env: process.env, encoding: 'utf8', windowsHide: true, maxBuffer: 10 * 1024 * 1024 });
  fs.writeFileSync(path.join(out, `check-${name}.txt`), (result.stdout || '') + (result.stderr || '') + (result.error ? String(result.error) : ''));
  const row = { operation: name, expected: 'exit 0', actual: { exitCode: result.status, log: `check-${name}.txt` }, pass: result.status === 0 };
  rows.push(row); fs.writeFileSync(path.join(out, 'checks.json'), JSON.stringify(rows, null, 2)); console.log(JSON.stringify(row));
}
const xml = fs.readFileSync(path.join(out, 'backend.xml'), 'utf8');
const suite = xml.match(/<testsuite\s[^>]*>/)?.[0] || '';
const stats = Object.fromEntries(['tests', 'errors', 'failures', 'skipped'].map(k => [k, Number(suite.match(new RegExp(`${k}="(\\d+)"`))?.[1] ?? -1)]));
rows.push({ operation: 'real-isolated-API-and-DB', expected: 'all tests pass', actual: stats, pass: stats.tests > 0 && stats.errors === 0 && stats.failures === 0 });
fs.writeFileSync(path.join(out, 'checks.json'), JSON.stringify(rows, null, 2)); console.log(JSON.stringify(rows.at(-1)));
if (rows.some(r => !r.pass)) process.exitCode = 1;
