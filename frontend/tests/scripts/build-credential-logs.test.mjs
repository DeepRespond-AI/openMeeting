import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import test from 'node:test';

const repository = fileURLToPath(new URL('../../../', import.meta.url));
const powershell = process.platform === 'win32' ? 'powershell.exe' : 'pwsh';
const available = !spawnSync(powershell, ['-NoProfile', '-NonInteractive', '-Command', 'exit 0']).error;
const quote = (value) => `'${value.replaceAll("'", "''")}'`;

function workspace(t) {
  const directory = mkdtempSync(path.join(tmpdir(), 'openmeeting-log-test-'));
  t.after(() => {
    assert.equal(path.dirname(path.resolve(directory)), path.resolve(tmpdir()));
    assert.ok(path.basename(directory).startsWith('openmeeting-log-test-'));
    rmSync(directory, { recursive: true, force: true });
  });
  return directory;
}

function run(directory, script, environment = {}) {
  const runner = path.join(directory, 'runner.ps1');
  writeFileSync(runner, `$ErrorActionPreference = 'Stop'\n${script}\n`);
  const result = spawnSync(powershell, [
    '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-File', runner,
  ], { encoding: 'utf8', env: { ...process.env, ...environment }, timeout: 30_000 });
  assert.ifError(result.error);
  assert.equal(result.status, 0, `${result.stdout}\n${result.stderr}`);
  return `${result.stdout}\n${result.stderr}`;
}

test('dotenv verbose output hides every value while preserving loaded values', { skip: !available }, (t) => {
  const directory = workspace(t);
  const file = path.join(directory, 'local [config] #.env');
  const values = {
    AUDIT_TOKEN: 'test-token-should-never-be-logged',
    AUDIT_PASSWORD: 'test-password-with=equals',
    AUDIT_SETTING: 'test-sensitive-value-with-ordinary-name',
    AUDIT_URL: 'https://example.com/?token=test-private-query',
  };
  const invalid = 'invalid secret content must never be logged';
  writeFileSync(file, [
    '# local test fixture', '',
    ...Object.entries(values).map(([key, value]) => `${key} = "${value}"`),
    'AUDIT_EMPTY=', invalid,
  ].join('\n'));
  const output = run(directory, [
    `. ${quote(path.join(repository, 'frontend/scripts/load-env.ps1'))}`,
    `$loaded = Load-EnvFile -EnvFilePath ${quote(file)} -Verbose`,
    "if ($loaded -ne $true) { throw 'Loading failed' }",
    ...Object.entries(values).map(([key, value]) =>
      `if ($env:${key} -cne ${quote(value)}) { throw 'Loaded value mismatch' }`),
    "if ($env:AUDIT_EMPTY) { throw 'Expected empty variable' }",
  ].join('\n'));
  for (const [key, value] of Object.entries(values)) {
    assert.ok(!output.includes(value), `Value leaked for ${key}`);
    assert.ok(output.includes(`Loaded: ${key} (SET)`));
  }
  assert.ok(!output.includes(invalid));
  assert.ok(output.includes('AUDIT_EMPTY (EMPTY)'));
  assert.ok(output.includes('Skipping invalid line 8'));
});

test('dotenv handles a missing file without breaking dot-sourced builds', { skip: !available }, (t) => {
  const directory = workspace(t);
  const output = run(directory, [
    `. ${quote(path.join(repository, 'frontend/scripts/load-env.ps1'))}`,
    `$loaded = Load-EnvFile -EnvFilePath ${quote(path.join(directory, 'missing.env'))} -Verbose`,
    "if ($loaded -ne $false) { throw 'Expected missing-file result' }",
  ].join('\n'));
  assert.ok(output.includes('No .env file found'));
});

test('dotenv errors do not repeat credentials from exception messages', { skip: !available }, (t) => {
  const directory = workspace(t);
  const file = path.join(directory, 'error.env');
  const secret = 'test-credential-in-an-internal-exception';
  writeFileSync(file, `AUDIT_TOKEN=${secret}\n`);
  const output = run(directory, [
    `. ${quote(path.join(repository, 'frontend/scripts/load-env.ps1'))}`,
    // Simulate a provider failure that includes the value it could not assign.
    `function Set-Item { throw ${quote(secret)} }`,
    "$ErrorActionPreference = 'Continue'",
    `$loaded = Load-EnvFile -EnvFilePath ${quote(file)} -Verbose`,
    "if ($loaded -ne $false) { throw 'Expected failure result' }",
  ].join('\n'));
  assert.ok(!output.includes(secret));
  assert.ok(output.includes('Failed to load .env file'));
});

test('actual Windows workflow diagnostics reveal no API key or prefix', { skip: !available }, (t) => {
  const directory = workspace(t);
  const lines = ['build.yml', 'build-windows.yml'].flatMap((name) =>
    readFileSync(path.join(repository, '.github/workflows', name), 'utf8')
      .split(/\r?\n/).filter((line) => /Write-Host "  SM_API_KEY:/.test(line)).map((line) => line.trim()));
  assert.equal(lines.length, 3);
  for (const key of ['test-signing-key-prefix-that-was-previously-exposed', 'short', '']) {
    const output = run(directory, lines.join('\n'), { SM_API_KEY: key });
    assert.equal(output.match(/SM_API_KEY: (?:SET|NOT SET)/g)?.length, 3);
    if (key) {
      assert.ok(!output.includes(key));
      assert.ok(!output.includes(key.slice(0, 20)));
      assert.ok(!output.includes('NOT SET'));
    } else {
      assert.equal(output.match(/SM_API_KEY: NOT SET/g)?.length, 3);
    }
  }
});
