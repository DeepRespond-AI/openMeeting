import { appendFileSync, existsSync, readdirSync } from 'node:fs';
import path from 'node:path';

const profile = process.env.BUILD_PROFILE || 'release';
const target = process.env.BUILD_TARGET || '';
const directory = path.join('target', target, profile, 'bundle');
function files(root) {
  return existsSync(root) ? readdirSync(root, { withFileTypes: true }).flatMap(entry => {
    const file = path.join(root, entry.name); return entry.isDirectory() ? files(file) : [file];
  }) : [];
}
const lines = [`Build profile: ${profile}`, '', ...files(directory).map(file => `- ${file.split(path.sep).join('/')}`)];
if (process.env.GITHUB_STEP_SUMMARY) appendFileSync(process.env.GITHUB_STEP_SUMMARY, lines.join('\n') + '\n');
else console.log(lines.join('\n'));
