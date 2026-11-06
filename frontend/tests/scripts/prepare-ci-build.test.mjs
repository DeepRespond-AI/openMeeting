import assert from 'node:assert/strict';
import { mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import test from 'node:test';
import { prepareCiBuild, verifyCiSigningPair } from '../../scripts/prepare-ci-build.mjs';
import { initializeUpdater } from '../../scripts/init-updater.mjs';

function fixture(t) {
  const root = mkdtempSync(path.join(tmpdir(), 'openmeeting-ci-build-'));
  t.after(() => {
    assert.equal(path.dirname(path.resolve(root)), path.resolve(tmpdir()));
    assert.ok(path.basename(root).startsWith('openmeeting-ci-build-'));
    rmSync(root, { recursive: true, force: true });
  });
  mkdirSync(path.join(root, 'src-tauri'));
  writeFileSync(path.join(root, 'src-tauri/tauri.conf.json'), JSON.stringify({ bundle: { windows: { signCommand: 'fixture-sign %1' } } }));
  return root;
}

test('unsigned builds use no deployment signing key or OS signing command', (t) => {
  const root = fixture(t);
  const result = prepareCiBuild({ frontendDir: root, environment: { OPENMEETING_SERVER_URL: 'http://127.0.0.1:39110/' } });
  const config = JSON.parse(readFileSync(result.output, 'utf8'));
  assert.equal(config.bundle.createUpdaterArtifacts, false);
  assert.equal(config.bundle.windows.signCommand, null);
  assert.equal(config.plugins.updater.pubkey, '');
  assert.equal(result.serverUrl, 'http://127.0.0.1:39110');
});

test('signed builds embed the public key and never write private material', (t) => {
  const root = fixture(t);
  const bytes = Buffer.alloc(42, 3); bytes.write('Ed');
  const pubkey = Buffer.from(`untrusted comment: fixture public key\n${bytes.toString('base64')}\n`).toString('base64');
  const result = prepareCiBuild({ frontendDir: root, environment: {
    OPENMEETING_SERVER_URL: 'https://meeting.example.com', OPENMEETING_SIGN_UPDATER: 'true', OPENMEETING_SIGN_BINARIES: 'true',
    TAURI_SIGNING_PUBLIC_KEY: pubkey, TAURI_SIGNING_PRIVATE_KEY: 'private-fixture-never-written', TAURI_SIGNING_PRIVATE_KEY_PASSWORD: 'password-never-written',
  } });
  const raw = readFileSync(result.output, 'utf8');
  const config = JSON.parse(raw);
  assert.equal(config.plugins.updater.pubkey, pubkey);
  assert.equal(config.bundle.createUpdaterArtifacts, true);
  assert.equal(config.bundle.windows.signCommand, 'fixture-sign %1');
  assert.ok(!raw.includes('never-written'));
});

test('release configuration rejects missing signing material and insecure gateways', (t) => {
  const root = fixture(t);
  for (const environment of [
    {}, { OPENMEETING_SERVER_URL: 'https://user:password@example.com' },
    { OPENMEETING_SERVER_URL: 'http://example.com', OPENMEETING_SIGN_UPDATER: 'true' },
    { OPENMEETING_SERVER_URL: 'https://example.com', OPENMEETING_SIGN_UPDATER: 'true' },
    { OPENMEETING_SERVER_URL: 'https://example.com', OPENMEETING_SIGN_UPDATER: 'true', TAURI_SIGNING_PRIVATE_KEY: 'fixture', TAURI_SIGNING_PUBLIC_KEY: 'invalid' },
  ]) assert.throws(() => prepareCiBuild({ frontendDir: root, environment }));
});

test('real signing probe rejects an otherwise well-formed mismatched public key', async (t) => {
  const root = fixture(t);
  await initializeUpdater({ frontendDir: root, environments: ['test', 'prod'], serverUrl: 'https://meeting.example.com', log: () => {} });
  const prod = path.join(root, 'src-tauri/signing/updater/prod');
  const passwordText = readFileSync(path.join(prod, 'password.env'), 'utf8').trim().split('=').slice(1).join('=');
  const environment = {
    TAURI_SIGNING_PRIVATE_KEY: path.join(prod, 'meeting-prod.key'),
    TAURI_SIGNING_PRIVATE_KEY_PASSWORD: passwordText.startsWith('"') ? JSON.parse(passwordText) : passwordText,
    TAURI_SIGNING_PUBLIC_KEY: readFileSync(path.join(prod, 'meeting-prod.key.pub'), 'utf8'),
  };
  await verifyCiSigningPair(environment);
  environment.TAURI_SIGNING_PUBLIC_KEY = readFileSync(path.join(root, 'src-tauri/signing/updater/test/meeting-test.key.pub'), 'utf8');
  await assert.rejects(verifyCiSigningPair(environment), /mismatch/);
});
