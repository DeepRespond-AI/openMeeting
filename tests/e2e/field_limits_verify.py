"""Run targeted checks and retain machine-readable results for the report."""
import json
import os
from pathlib import Path
import subprocess
import sys

root = Path(__file__).resolve().parents[2]
out = root / '.artifacts/field-limits'
out.mkdir(parents=True, exist_ok=True)
flutter = os.environ.get('FLUTTER_BIN', 'flutter')
pnpm = 'pnpm.cmd' if os.name == 'nt' else 'pnpm'
checks = [
    ('桌面 TypeScript', root / 'frontend', [pnpm, 'exec', 'tsc', '--noEmit', '--pretty', 'false'], {}),
    ('管理端 TypeScript', root / 'server/admin-web', [pnpm, 'exec', 'vue-tsc', '--noEmit'], {}),
    ('Flutter 静态分析', root / 'mobile', [flutter, 'analyze', '--no-pub'], {}),
    ('Flutter 相关回归', root / 'mobile', [flutter, 'test', '--no-pub', 'test/acceptance/text_limits_test.dart',
      'test/features/auth/phone_auth_controller_test.dart', 'test/features/auth/auth_pages_test.dart',
      'test/features/import/import_controller_test.dart', 'test/features/live_meeting/room_controller_test.dart',
      '--reporter', 'json'], {}),
]
results = []
for index, (name, cwd, command, extra_env) in enumerate(checks, 1):
    result = subprocess.run(command, cwd=cwd, env={**os.environ, **extra_env}, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    filename = 'flutter-tests.jsonl' if '回归' in name else f'verify-{index}.log'
    (out / filename).write_bytes(result.stdout)
    row = {'operation': name, 'command': subprocess.list2cmdline(command), 'cwd': str(cwd),
           'expected': 'exit 0', 'actual': result.returncode, 'pass': result.returncode == 0, 'log': filename}
    results.append(row)
    print(json.dumps(row, ensure_ascii=False), flush=True)
(out / 'verification.json').write_text(json.dumps(results, ensure_ascii=False, indent=2), encoding='utf-8')
sys.exit(0 if all(row['pass'] for row in results) else 1)
