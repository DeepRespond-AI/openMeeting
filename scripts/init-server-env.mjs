import { randomBytes } from 'node:crypto';
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = fileURLToPath(new URL('../', import.meta.url));
export function initializeServer({ directory = path.join(root, 'server'), mode = 'dev', storage = 'minio', output, publicEndpoint = 'http://localhost:39120' } = {}) {
  if (!['dev', 'production'].includes(mode)) throw new Error('--env must be dev or production.');
  if (!['minio', 'local'].includes(storage)) throw new Error('--storage must be minio or local.');
  output = path.resolve(output || path.join(directory, mode === 'dev' ? '.env.dev' : '.env.prod'));
  if (existsSync(output)) return { output, created: false };
  const endpoint = new URL(publicEndpoint);
  if (!['http:', 'https:'].includes(endpoint.protocol) || endpoint.username || endpoint.password || endpoint.search || endpoint.hash) throw new Error('Storage endpoint must be an HTTP(S) URL without credentials, query or fragment.');
  if (mode === 'production' && storage === 'minio' && endpoint.protocol !== 'https:') throw new Error('Production MinIO needs --storage-public-url with HTTPS.');
  const random = () => randomBytes(32).toString('hex');
  const values = {
    OPENMEETING_ENV: mode,
    OPENMEETING_STT_RUNTIME: mode === 'dev' ? 'stt-cloud' : 'stt-cpu',
    OPENMEETING_ADMIN_PASSWORD: random(), INTERNAL_SERVICE_TOKEN: random(), OPENMEETING_SECRET_KEY: random(),
    POSTGRES_PASSWORD: random(), USER_POSTGRES_PASSWORD: random(), MEETING_POSTGRES_PASSWORD: random(), STT_POSTGRES_PASSWORD: random(),
    OPENMEETING_MINIO_ACCESS_KEY_SECRET: random(),
    OPENMEETING_STORAGE_PROVIDER: storage, COMPOSE_PROFILES: storage === 'minio' ? 'minio' : '',
    OPENMEETING_MINIO_PUBLIC_ENDPOINT: endpoint.href.replace(/\/+$/, ''),
  };
  let text = readFileSync(path.join(directory, '.env.example'), 'utf8');
  for (const [key, value] of Object.entries(values)) {
    const line = new RegExp(`^${key}=.*$`, 'm');
    text = line.test(text) ? text.replace(line, `${key}=${value}`) : `${text.trimEnd()}\n${key}=${value}\n`;
  }
  mkdirSync(path.dirname(output), { recursive: true });
  writeFileSync(output, text, { flag: 'wx', mode: 0o600 });
  return { output, created: true };
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try {
    const args = process.argv.slice(2), options = {};
    const names = { '--env': 'mode', '--storage': 'storage', '--output': 'output', '--storage-public-url': 'publicEndpoint' };
    for (let i = 0; i < args.length; i += 2) {
      if (!names[args[i]] || !args[i + 1]) throw new Error('Usage: node scripts/init-server-env.mjs [--env dev|production] [--storage minio|local] [--output path] [--storage-public-url URL]');
      options[names[args[i]]] = args[i + 1];
    }
    const result = initializeServer(options);
    console.log(`${result.created ? 'Created' : 'Preserved existing'} ${result.output}. Read the file locally for credentials; keep it out of Git.`);
  } catch (error) { console.error(error.message); process.exitCode = 1; }
}
