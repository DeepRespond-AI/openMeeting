"""记录类型检查、Compose 校验和移动端音频兼容回归，供测试报告组装。"""
import json
import os
from pathlib import Path
import subprocess

root = Path(__file__).resolve().parents[2]
out = root / '.artifacts/minio-object-storage'
out.mkdir(parents=True, exist_ok=True)
rows = []
checks = [
    ('管理端类型检查', root / 'server/admin-web', ['pnpm.cmd' if os.name == 'nt' else 'pnpm', 'exec', 'vue-tsc', '--noEmit'], 'typescript.log'),
    ('Compose 配置校验', root / 'server', ['docker', 'compose', '--profile', 'minio', 'config', '--quiet'], 'compose.log'),
    ('移动端播放与下载回归', root / 'mobile', [os.environ.get('FLUTTER_BIN', 'flutter'), 'test', '--no-pub',
        'test/features/meetings/meetings_repository_impl_test.dart', 'test/features/meetings/recording_download_test.dart',
        '--reporter', 'json'], 'flutter-tests.jsonl'),
]
for name, cwd, command, log in checks:
    result = subprocess.run(command, cwd=cwd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    (out / log).write_bytes(result.stdout)
    row = {'operation': name, 'expected': 'exit 0', 'actual': result.returncode, 'pass': result.returncode == 0,
           'command': subprocess.list2cmdline(command), 'log': log}
    rows.append(row)
    print(json.dumps(row, ensure_ascii=True), flush=True)
(out / 'verification.json').write_text(json.dumps(rows, ensure_ascii=False, indent=2), encoding='utf-8')
raise SystemExit(0 if all(row['pass'] for row in rows) else 1)
