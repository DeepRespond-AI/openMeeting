import { randomBytes, randomUUID } from 'node:crypto';
import { fork } from 'node:child_process';
import { existsSync, mkdirSync, readFileSync, rmSync, unlinkSync, writeFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const scriptPath = fileURLToPath(import.meta.url);
const defaultFrontendDir = path.resolve(path.dirname(scriptPath), '..');
const supportedEnvironments = ['dev', 'test', 'prod'];

// Native CLI output can contain signing material. Keep it off the terminal and
// send passwords over IPC, rather than putting them in child-process arguments.
export function runTauri(args) {
  return new Promise((resolve, reject) => {
    const child = fork(scriptPath, ['--tauri-worker'], {
      cwd: defaultFrontendDir,
      stdio: ['ignore', 'ignore', 'ignore', 'ipc'],
    });
    let succeeded = false;
    const timer = setTimeout(() => {
      child.kill();
      reject(new Error('Tauri 签名操作超时。'));
    }, 120_000);
    child.on('message', (message) => { succeeded = message?.ok === true; });
    child.once('error', () => {
      clearTimeout(timer);
      reject(new Error('无法启动本地 Tauri CLI，请先安装 frontend 的锁定依赖。'));
    });
    child.once('exit', (code) => {
      clearTimeout(timer);
      if (code === 0 && succeeded) resolve();
      else reject(new Error('Tauri 签名操作失败，请检查本地 CLI 依赖和文件权限。'));
    });
    child.send({ args });
  });
}

function outputPaths(frontendDir, environment) {
  const directory = path.join(frontendDir, 'src-tauri/signing/updater', environment);
  return {
    key: path.join(directory, `meeting-${environment}.key`),
    publicKey: path.join(directory, `meeting-${environment}.key.pub`),
    password: path.join(directory, 'password.env'),
    config: path.join(directory, 'tauri.updater.json'),
    buildEnv: path.join(frontendDir, `.env.build.${environment}`),
  };
}

function gatewayUrl(value, environments) {
  if (!value) throw new Error('首次初始化需要 --server-url，填写客户端可访问的网关地址。');
  let url;
  try { url = new URL(value); } catch { throw new Error('--server-url 必须是完整的 HTTP(S) 网关地址。'); }
  if (!['http:', 'https:'].includes(url.protocol) || url.username || url.password || url.search || url.hash) {
    throw new Error('网关地址必须使用 HTTP(S)，不能包含凭据、查询参数或片段。');
  }
  if (url.protocol !== 'https:' && environments.some((environment) => environment !== 'dev')) {
    throw new Error('test/prod 必须使用 HTTPS 网关；HTTP 仅支持 --env dev。');
  }
  return url.href.replace(/\/+$/, '');
}

export async function initializeUpdater({
  frontendDir = defaultFrontendDir,
  environments = supportedEnvironments,
  serverUrl,
  log = console.log,
} = {}) {
  frontendDir = path.resolve(frontendDir);
  if (!environments.length || environments.some((environment) => !supportedEnvironments.includes(environment))) {
    throw new Error('--env 只支持 dev、test、prod 或 all。');
  }
  environments = [...new Set(environments)];
  const pending = [];
  const skipped = [];
  for (const environment of environments) {
    const outputs = outputPaths(frontendDir, environment);
    const present = Object.values(outputs).filter(existsSync);
    if (present.length === Object.keys(outputs).length) {
      skipped.push(environment);
    } else if (present.length) {
      throw new Error(`${environment} 已有部分签名或构建配置，拒绝覆盖或混用。请恢复完整备份，或先将现有文件移到其他安全位置。`);
    } else {
      pending.push({ environment, outputs });
    }
  }
  if (!pending.length) {
    log(`已存在完整配置，保留原文件：${skipped.join(', ')}。`);
    return { generated: [], skipped };
  }
  const server = gatewayUrl(serverUrl, pending.map(({ environment }) => environment));
  const updaterDirectory = path.join(frontendDir, 'src-tauri/signing/updater');
  const staging = path.join(updaterDirectory, `.init-${randomUUID()}`);
  mkdirSync(staging, { recursive: true, mode: 0o700 });
  const writes = [];
  const created = [];
  try {
    // Prepare every selected environment before publishing any output files.
    for (const { environment, outputs } of pending) {
      const temporaryKey = path.join(staging, `meeting-${environment}.key`);
      const password = randomBytes(32).toString('base64url');
      await runTauri(['signer', 'generate', '--ci', '--password', password, '--write-keys', temporaryKey]);
      const publicKey = readFileSync(`${temporaryKey}.pub`, 'utf8').trim();
      if (!Buffer.from(publicKey, 'base64').toString('utf8').includes('public key')) {
        throw new Error('Tauri CLI 没有生成有效的公钥，未写入构建配置。');
      }
      const updater = { pubkey: publicKey };
      if (environment === 'dev') updater.dangerousInsecureTransportProtocol = true;
      const privateKeyPath = outputs.key.split(path.sep).join('/');
      writes.push(
        { file: outputs.key, content: readFileSync(temporaryKey), mode: 0o600 },
        { file: outputs.publicKey, content: `${publicKey}\n`, mode: 0o644 },
        { file: outputs.password, content: `TAURI_SIGNING_PRIVATE_KEY_PASSWORD=${password}\n`, mode: 0o600 },
        { file: outputs.config, content: `${JSON.stringify({ plugins: { updater } }, null, 2)}\n`, mode: 0o644 },
        { file: outputs.buildEnv, content: `# Generated by pnpm updater:init; local only.\nOPENMEETING_SERVER_URL=${JSON.stringify(server)}\nTAURI_SIGNING_PRIVATE_KEY=${JSON.stringify(privateKeyPath)}\n`, mode: 0o600 },
      );
    }
    for (const { file, content, mode } of writes) {
      mkdirSync(path.dirname(file), { recursive: true, mode: 0o700 });
      // Exclusive creation also protects against files appearing after preflight.
      writeFileSync(file, content, { flag: 'wx', mode });
      created.push(file);
    }
  } catch (error) {
    for (const file of created.reverse()) unlinkSync(file);
    throw error;
  } finally {
    // This directory is generated above beneath the explicit updater directory.
    if (path.dirname(staging) !== updaterDirectory || !path.basename(staging).startsWith('.init-')) {
      throw new Error('临时目录边界校验失败。');
    }
    rmSync(staging, { recursive: true, force: true });
  }
  const generated = pending.map(({ environment }) => environment);
  log(`已初始化：${generated.join(', ')}。每个环境使用独立密钥和随机密码。`);
  if (skipped.length) log(`已有完整配置，未修改：${skipped.join(', ')}。`);
  log('输出：src-tauri/signing/updater/<环境>/ 和 .env.build.<环境>，均不提交 Git。');
  log('请安全备份私钥和 password.env；终端不会输出密码或私钥。');
  return { generated, skipped };
}

function parseArguments(args) {
  const options = {};
  for (let index = 0; index < args.length; index++) {
    const arg = args[index];
    if (arg === '--help' || arg === '-h') return { help: true };
    if (!['--env', '--server-url'].includes(arg) || !args[index + 1] || args[index + 1].startsWith('--')) {
      throw new Error(`无效参数：${arg}。使用 --help 查看用法。`);
    }
    const value = args[++index];
    if (arg === '--env') options.environments = value === 'all' ? supportedEnvironments : [value];
    else options.serverUrl = value;
  }
  return options;
}

if (process.argv[2] === '--tauri-worker' && process.send) {
  process.once('message', async ({ args }) => {
    try {
      const { run } = createRequire(import.meta.url)('@tauri-apps/cli');
      const result = await run(args, 'tauri');
      process.send({ ok: result !== false });
    } catch {
      process.send({ ok: false });
      process.exitCode = 1;
    } finally {
      process.disconnect();
    }
  });
} else if (process.argv[1] && path.resolve(process.argv[1]) === scriptPath) {
  try {
    const options = parseArguments(process.argv.slice(2));
    if (options.help) {
      console.log('用法：pnpm updater:init [--env dev|test|prod|all] --server-url <网关地址>');
      console.log('默认初始化 dev/test/prod；完整配置会保留，部分配置会拒绝覆盖。');
      console.log('test/prod 要求 HTTPS。已有配置的网关地址请直接编辑 .env.build.<环境>。');
    } else {
      await initializeUpdater(options);
    }
  } catch (error) {
    console.error(`Updater 初始化失败：${error.message}`);
    process.exitCode = 1;
  }
}
