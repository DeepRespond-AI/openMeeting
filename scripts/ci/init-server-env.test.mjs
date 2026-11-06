import assert from 'node:assert/strict';
import { copyFileSync, mkdtempSync, readFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import test from 'node:test';
import { initializeServer } from '../init-server-env.mjs';

test('fresh deployment gets distinct URL-safe secrets and existing files are preserved', (t) => {
  const directory = mkdtempSync(path.join(tmpdir(), 'openmeeting-env-'));
  t.after(() => {
    assert.equal(path.dirname(path.resolve(directory)), path.resolve(tmpdir()));
    assert.ok(path.basename(directory).startsWith('openmeeting-env-'));
    rmSync(directory, { recursive: true, force: true });
  });
  copyFileSync(new URL('../../server/.env.example', import.meta.url), path.join(directory, '.env.example'));
  const result = initializeServer({ directory });
  const text = readFileSync(result.output, 'utf8');
  const secrets = [...text.matchAll(/^(?:OPENMEETING_ADMIN_PASSWORD|INTERNAL_SERVICE_TOKEN|OPENMEETING_SECRET_KEY|POSTGRES_PASSWORD|USER_POSTGRES_PASSWORD|MEETING_POSTGRES_PASSWORD|STT_POSTGRES_PASSWORD|OPENMEETING_MINIO_ACCESS_KEY_SECRET)=([a-f0-9]{64})$/gm)].map(m => m[1]);
  assert.equal(secrets.length, 8); assert.equal(new Set(secrets).size, 8);
  assert.match(text, /^OPENMEETING_ENV=dev$/m);
  assert.match(text, /^OPENMEETING_STT_RUNTIME=stt-cloud$/m);
  assert.equal(initializeServer({ directory }).created, false);
  assert.equal(readFileSync(result.output, 'utf8'), text);
  assert.throws(() => initializeServer({ directory, mode: 'production' }), /HTTPS/);
});
