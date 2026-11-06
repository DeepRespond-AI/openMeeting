import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
const root = fileURLToPath(new URL('../../', import.meta.url));
const out = path.resolve(root, process.env.MEETING_READY_OUTPUT || '.artifacts/shared-records-native-e2e');
const read = name => JSON.parse(fs.readFileSync(path.join(out, name), 'utf8'));
const accounts = read('accounts.private.json'), rows = [], browsers = [], pages = [];
const { chromium } = createRequire(path.join(root, 'frontend/package.json'))('playwright');
const invoke = (p, command, args = {}) => p.evaluate(({ command, args }) => window.__TAURI_INTERNALS__.invoke(command, args), { command, args });
try {
  for (let i = 0; i < 3; i++) {
    const b = await chromium.connectOverCDP(`http://127.0.0.1:${9261 + i}`); browsers.push(b);
    const p = b.contexts()[0].pages().find(p => p.url().startsWith('http://localhost:3162') && !p.url().includes('/im/')); pages.push(p);
    assert.equal((await invoke(p, 'auth_get_user')).id, accounts[i].id);
    await p.locator('audio').evaluateAll(elements => elements.forEach(el => { el.pause(); el.removeAttribute('src'); el.load(); }));
  }
  for (const roomId of read('rooms.json')) {
    // end is host-authorized and idempotent; GET intentionally rejects former
    // participants after end, so it cannot be the cleanup precondition.
    await invoke(pages[0], 'room_end', { roomId });
    rows.push({ operation: 'end owned test room', roomId, pass: true });
  }
  const records = await invoke(pages[0], 'api_get_meetings');
  const removed = new Set();
  for (let i = 0; i < 3; i++) {
    for (const { id: meetingId } of records) {
      let metadata; try { metadata = await invoke(pages[i], 'api_get_meeting_metadata', { meetingId }); } catch { continue; }
      if (!metadata.folder_path) continue;
      const file = path.resolve(metadata.folder_path, 'audio.wav');
      if (removed.has(file) || !fs.existsSync(file)) continue;
      const base = path.resolve(process.env.USERPROFILE, 'Music', 'openmeeting-recordings') + path.sep;
      assert.ok(file.toLowerCase().startsWith(base.toLowerCase())); assert.ok(fs.lstatSync(file).isFile());
      const bytes = fs.readFileSync(file); assert.equal(bytes.toString('ascii', 0, 4), 'RIFF');
      fs.unlinkSync(file); removed.add(file);
      rows.push({ operation: 'remove only owned downloaded WAV', meetingId, bytes: bytes.length, sha256: crypto.createHash('sha256').update(bytes).digest('hex'), pass: true });
    }
    await invoke(pages[i], 'auth_logout'); rows.push({ operation: 'logout dedicated native client', client: i, pass: true });
  }
} catch (error) { rows.push({ operation: 'cleanup failure', pass: false, actual: String(error.stack || error) }); process.exitCode = 1; }
finally { for (const b of browsers) await b.close(); fs.writeFileSync(path.join(out, 'native-cleanup.json'), JSON.stringify({ rows }, null, 2)); console.log(JSON.stringify({ rows })); }
