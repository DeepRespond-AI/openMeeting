import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

const root = new URL('../../', import.meta.url);
const packageVersion = JSON.parse(readFileSync(new URL('frontend/package.json', root), 'utf8')).version;
const tauriVersion = JSON.parse(readFileSync(new URL('frontend/src-tauri/tauri.conf.json', root), 'utf8')).version;
const manifest = readFileSync(new URL('frontend/src-tauri/Cargo.toml', root), 'utf8');
const rustVersion = manifest.match(/^version\s*=\s*"([^"]+)"/m)?.[1];

assert.match(packageVersion, /^\d+\.\d+\.\d+$/, 'Desktop version must use X.Y.Z');
assert.equal(tauriVersion, packageVersion, 'tauri.conf.json and package.json versions must match');
assert.equal(rustVersion, packageVersion, 'Cargo.toml and package.json versions must match');
console.log(`Desktop version is consistent: ${packageVersion}`);
