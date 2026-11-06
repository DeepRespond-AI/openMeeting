import { readFileSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const out = fileURLToPath(new URL('../../.artifacts/release-download/', import.meta.url));
const data = JSON.parse(readFileSync(path.join(out, 'results.json'), 'utf8'));
const visual = JSON.parse(readFileSync(path.join(out, 'visual-review.json'), 'utf8'));
const cell = value => (typeof value === 'string' ? value : JSON.stringify(value)).replaceAll('|', '\\|').replaceAll('\n', ' ');
const lines = [
  '# 版本发布下载安装包测试报告', '',
  data.scope, '',
  '启动：复用现有 Vite 管理端 http://localhost:5173、网关 http://127.0.0.1:39110 和 Docker MinIO，未新开服务。开发启动命令为在 server/admin-web 执行 pnpm dev。', '',
  '执行：node tests/e2e/release-download.mjs。先冒烟 404 失败入口，再真实上传测试文件，通过页面点击下载并比对字节、文件名和次数，验证未上传状态和窄视口操作。未执行安装程序。', '',
  `通过 ${data.checks.filter(c => c.pass).length}，失败 ${data.checks.filter(c => !c.pass).length}。`, '',
  '| 操作 | 预期 | 实际 | 结果 |', '|---|---|---|---|',
  ...data.checks.map(c => `| ${cell(c.operation)} | ${cell(c.expected)} | ${cell(c.actual)} | ${c.pass ? '通过' : '失败'} |`), '',
  '## 截图视觉检查', '',
  ...visual.map(v => `- [${v.path}](${v.path})：${v.viewport}，${v.result}。${v.notes}`), '',
  '## 清理与边界', '',
  ...data.cleanup.map(c => `- ${JSON.stringify(c)}`), '',
  '构建与类型检查：见 [build.log](build.log)。结构化结果见 [results.json](results.json)。', '',
  '边界：本次真实验证 MinIO 下载及 Windows/Android；本地文件、OSS、macOS/Linux 包类型未逐项回归。它们复用已有下载接口。窄视口表格需横向滚动；取消固定操作列，防止遮挡下载入口。部署中的 Docker 管理端需要重新构建 gateway_ms 镜像后生效。', '',
];
writeFileSync(path.join(out, '测试报告.md'), lines.join('\n'));
