// Roll back only this run's three API records; refuse broader matches.
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
const root = fileURLToPath(new URL('../../', import.meta.url));
const out = path.join(root, '.artifacts/mobile-core-parity');
const budget = JSON.parse(fs.readFileSync(path.join(out, 'budget.json')));
const result = { deleted: 0, expected: 3, success: false, note: '' };
try {
  for (const profile of ['e2ehost20261022', 'rtchostvalidation', 'dev1', 'dev2']) {
    const config = path.join(process.env.APPDATA, `com.openmeeting.ai.${profile}`, 'server-config.json');
    if (!fs.existsSync(config)) continue;
    const token = JSON.parse(fs.readFileSync(config)).sessionToken; if (!token) continue;
    const headers = { Authorization: `Bearer ${token}` };
    const response = await fetch('http://127.0.0.1:39110/api/v1/meetings', { headers, signal: AbortSignal.timeout(10000) });
    if (!response.ok) continue;
    const items = await response.json();
    const matches = items.filter(m => m.title === 'E2E mobile core settings' && m.can_manage === true &&
      Date.parse(m.created_at) >= budget.started - 1000 && Date.parse(m.created_at) < budget.started + 300000);
    if (!matches.length) continue;
    if (matches.length !== 3 || matches.some(m => !/^[\w-]{1,100}$/.test(m.id))) throw Error('Unexpected record set; no deletion performed');
    for (const m of matches) {
      const deleted = await fetch(`http://127.0.0.1:39110/api/v1/meetings/${encodeURIComponent(m.id)}`, { method: 'DELETE', headers, signal: AbortSignal.timeout(10000) });
      if (!deleted.ok) throw Error(`Temporary record cleanup HTTP ${deleted.status}`);
      result.deleted++;
    }
    result.success = result.deleted === 3; result.note = '仅删除本轮三次 API 运行生成的精确匹配记录'; break;
  }
  if (!result.success) result.note ||= '未找到完整唯一的记录集合，未扩大删除范围';
} catch (error) { result.note = error.message; }
fs.writeFileSync(path.join(out, 'test-data-cleanup.json'), JSON.stringify(result, null, 2));
console.log(JSON.stringify(result));
