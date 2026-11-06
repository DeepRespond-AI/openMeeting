import { existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { runTauri } from './init-updater.mjs';
import { verifyUpdaterSignature } from './verify-updater.mjs';

const frontendRoot = fileURLToPath(new URL('../', import.meta.url));

export function prepareCiBuild({ frontendDir = frontendRoot, environment = process.env } = {}) {
  let server;
  try { server = new URL(environment.OPENMEETING_SERVER_URL); }
  catch { throw new Error('Set OPENMEETING_SERVER_URL to the client-accessible HTTP(S) gateway.'); }
  if (!['http:', 'https:'].includes(server.protocol) || server.username || server.password || server.search || server.hash) {
    throw new Error('Gateway must use HTTP(S), without credentials, a query or a fragment.');
  }
  const signed = environment.OPENMEETING_SIGN_UPDATER === 'true';
  if (signed && server.protocol !== 'https:') throw new Error('Signed release builds require an HTTPS gateway.');
  const pubkey = environment.TAURI_SIGNING_PUBLIC_KEY?.trim() || '';
  if (signed) {
    if (!environment.TAURI_SIGNING_PRIVATE_KEY) throw new Error('Signed updates require TAURI_SIGNING_PRIVATE_KEY.');
    const lines = Buffer.from(pubkey, 'base64').toString('utf8').trim().split(/\r?\n/);
    const bytes = Buffer.from(lines.at(-1) || '', 'base64');
    if (lines.length !== 2 || !lines[0].startsWith('untrusted comment:') || bytes.length !== 42 || bytes.subarray(0, 2).toString() !== 'Ed') {
      throw new Error('Set TAURI_SIGNING_PUBLIC_KEY to the matching complete Tauri public key content.');
    }
  }
  const base = JSON.parse(readFileSync(path.join(frontendDir, 'src-tauri/tauri.conf.json'), 'utf8'));
  const config = {
    bundle: {
      createUpdaterArtifacts: signed,
      windows: { signCommand: environment.OPENMEETING_SIGN_BINARIES === 'true' ? base.bundle?.windows?.signCommand ?? null : null },
    },
    plugins: { updater: { pubkey: signed ? pubkey : '' } },
  };
  const output = path.join(frontendDir, 'src-tauri/tauri.ci.json');
  mkdirSync(path.dirname(output), { recursive: true });
  writeFileSync(output, JSON.stringify(config, null, 2) + '\n', { mode: 0o600 });
  return { output, signed, serverUrl: server.href.replace(/\/+$/, '') };
}

export async function verifyCiSigningPair(environment = process.env) {
  const directory = mkdtempSync(path.join(tmpdir(), 'openmeeting-signing-probe-'));
  try {
    const artifact = path.join(directory, 'probe.bin');
    writeFileSync(artifact, 'OpenMeeting signing key correspondence check.');
    let key = environment.TAURI_SIGNING_PRIVATE_KEY;
    if (!existsSync(key)) {
      const privateFile = path.join(directory, 'key');
      writeFileSync(privateFile, key, { mode: 0o600 });
      key = privateFile;
    }
    await runTauri(['signer', 'sign', '-f', key, '-p', environment.TAURI_SIGNING_PRIVATE_KEY_PASSWORD || '', artifact]);
    if (!verifyUpdaterSignature(readFileSync(artifact), readFileSync(`${artifact}.sig`, 'utf8'), environment.TAURI_SIGNING_PUBLIC_KEY)) throw new Error('Updater public/private key mismatch. No release binary was built.');
  } finally {
    if (path.dirname(path.resolve(directory)) !== path.resolve(tmpdir()) || !path.basename(directory).startsWith('openmeeting-signing-probe-')) throw new Error('Unexpected signing probe directory.');
    rmSync(directory, { recursive: true, force: true });
  }
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try {
    const result = prepareCiBuild();
    if (result.signed && !process.argv.includes('--validate-only')) {
      await verifyCiSigningPair();
    }
    console.log(`CI build configuration ready; updater signing: ${result.signed ? 'enabled' : 'disabled'}.`);
  } catch (error) {
    console.error(error.message);
    process.exitCode = 1;
  }
}
