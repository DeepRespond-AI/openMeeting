import assert from 'node:assert/strict';
import { createHash, createPublicKey, verify } from 'node:crypto';
import { existsSync, mkdirSync, mkdtempSync, readFileSync, readdirSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import test from 'node:test';
import { initializeUpdater, runTauri } from '../../scripts/init-updater.mjs';

function workspace(t) {
  const directory = mkdtempSync(path.join(tmpdir(), 'openmeeting-updater-init-'));
  t.after(() => {
    assert.equal(path.dirname(path.resolve(directory)), path.resolve(tmpdir()));
    assert.ok(path.basename(directory).startsWith('openmeeting-updater-init-'));
    rmSync(directory, { recursive: true, force: true });
  });
  // Exercise the absolute signing path with spaces and a dotenv comment marker.
  const frontendDir = path.join(directory, 'frontend with spaces # local');
  mkdirSync(frontendDir);
  return frontendDir;
}

function snapshot(directory) {
  const result = {};
  for (const entry of readdirSync(directory, { withFileTypes: true })) {
    const file = path.join(directory, entry.name);
    if (entry.isDirectory()) Object.assign(result, snapshot(file));
    else result[file] = createHash('sha256').update(readFileSync(file)).digest('hex');
  }
  return result;
}

test('initializes isolated environments, signs a real update and preserves existing files', { timeout: 180_000 }, async (t) => {
  const frontendDir = workspace(t);
  const logs = [];
  const result = await initializeUpdater({ frontendDir, serverUrl: 'https://meeting.example.com/', log: (line) => logs.push(line) });
  assert.deepEqual(result.generated, ['dev', 'test', 'prod']);
  const publicKeys = new Set();
  const passwords = new Set();
  for (const environment of result.generated) {
    const directory = path.join(frontendDir, 'src-tauri/signing/updater', environment);
    const publicKey = readFileSync(path.join(directory, `meeting-${environment}.key.pub`), 'utf8').trim();
    const config = JSON.parse(readFileSync(path.join(directory, 'tauri.updater.json'), 'utf8'));
    const password = readFileSync(path.join(directory, 'password.env'), 'utf8').trim().split('=')[1];
    assert.equal(config.plugins.updater.pubkey, publicKey);
    assert.equal(config.plugins.updater.dangerousInsecureTransportProtocol, environment === 'dev' ? true : undefined);
    assert.ok(password.length >= 40);
    assert.ok(!logs.join('\n').includes(password));
    assert.ok(!logs.join('\n').includes(readFileSync(path.join(directory, `meeting-${environment}.key`), 'utf8').trim()));
    publicKeys.add(publicKey);
    passwords.add(password);
  }
  assert.equal(publicKeys.size, 3);
  assert.equal(passwords.size, 3);

  const production = path.join(frontendDir, 'src-tauri/signing/updater/prod');
  const loaded = spawnSync(process.execPath, [
    `--env-file=${path.join(frontendDir, '.env.build.prod')}`,
    `--env-file=${path.join(production, 'password.env')}`,
    '-e', 'console.log(JSON.stringify({server:process.env.OPENMEETING_SERVER_URL,key:process.env.TAURI_SIGNING_PRIVATE_KEY,passwordLength:process.env.TAURI_SIGNING_PRIVATE_KEY_PASSWORD.length}))',
  ], {
    encoding: 'utf8',
    env: Object.fromEntries(Object.entries(process.env).filter(([key]) => !['OPENMEETING_SERVER_URL', 'TAURI_SIGNING_PRIVATE_KEY', 'TAURI_SIGNING_PRIVATE_KEY_PASSWORD'].includes(key))),
  });
  assert.equal(loaded.status, 0);
  const loadedEnvironment = JSON.parse(loaded.stdout);
  assert.equal(loadedEnvironment.server, 'https://meeting.example.com');
  assert.equal(loadedEnvironment.key, path.join(production, 'meeting-prod.key').split(path.sep).join('/'));
  assert.ok(loadedEnvironment.passwordLength >= 40);

  const payload = Buffer.from('An update artifact used only by the updater initialization test.');
  const artifact = path.join(frontendDir, 'fixture-update.bin');
  writeFileSync(artifact, payload);
  const password = readFileSync(path.join(production, 'password.env'), 'utf8').trim().split('=')[1];
  await runTauri(['signer', 'sign', '-f', path.join(production, 'meeting-prod.key'), '-p', password, artifact]);
  const publicText = Buffer.from(readFileSync(path.join(production, 'meeting-prod.key.pub'), 'utf8').trim(), 'base64').toString('utf8');
  const publicBytes = Buffer.from(publicText.split('\n')[1], 'base64');
  const signatureText = Buffer.from(readFileSync(`${artifact}.sig`, 'utf8').trim(), 'base64').toString('utf8');
  const signatureBytes = Buffer.from(signatureText.split('\n')[1], 'base64');
  assert.equal(publicBytes.length, 42);
  assert.equal(signatureBytes.length, 74);
  assert.deepEqual(signatureBytes.subarray(2, 10), publicBytes.subarray(2, 10));
  const algorithm = signatureBytes.subarray(0, 2).toString('ascii');
  assert.ok(['Ed', 'ED'].includes(algorithm));
  const signedPayload = algorithm === 'ED' ? createHash('blake2b512').update(payload).digest() : payload;
  const publicKey = createPublicKey({
    key: Buffer.concat([Buffer.from('302a300506032b6570032100', 'hex'), publicBytes.subarray(10)]),
    format: 'der',
    type: 'spki',
  });
  assert.equal(verify(null, signedPayload, publicKey, signatureBytes.subarray(10)), true);
  assert.equal(verify(null, Buffer.from('tampered update'), publicKey, signatureBytes.subarray(10)), false);

  const before = snapshot(frontendDir);
  const repeated = await initializeUpdater({ frontendDir, serverUrl: 'https://different.example.com', log: () => {} });
  assert.deepEqual(repeated.generated, []);
  assert.deepEqual(repeated.skipped, ['dev', 'test', 'prod']);
  assert.deepEqual(snapshot(frontendDir), before);
  assert.ok(!readdirSync(path.join(frontendDir, 'src-tauri/signing/updater')).some((name) => name.startsWith('.init-')));
});

test('rejects insecure production URLs before generating any files', async (t) => {
  const frontendDir = workspace(t);
  await assert.rejects(initializeUpdater({ frontendDir, serverUrl: 'http://meeting.example.com', log: () => {} }), /HTTPS/);
  assert.deepEqual(readdirSync(frontendDir), []);
  await assert.rejects(initializeUpdater({ frontendDir, serverUrl: 'https://user:password@meeting.example.com', log: () => {} }), /凭据/);
  assert.deepEqual(readdirSync(frontendDir), []);
});

test('refuses partial existing credentials without creating other environments', async (t) => {
  const frontendDir = workspace(t);
  const directory = path.join(frontendDir, 'src-tauri/signing/updater/prod');
  mkdirSync(directory, { recursive: true });
  const existing = path.join(directory, 'password.env');
  writeFileSync(existing, 'existing-secret-do-not-overwrite\n');
  const before = snapshot(frontendDir);
  await assert.rejects(initializeUpdater({ frontendDir, serverUrl: 'https://meeting.example.com', log: () => {} }), /部分/);
  assert.deepEqual(snapshot(frontendDir), before);
  assert.equal(existsSync(path.join(frontendDir, 'src-tauri/signing/updater/dev')), false);
});
