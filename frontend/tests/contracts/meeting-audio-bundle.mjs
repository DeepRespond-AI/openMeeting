// Check the actual dev-server output as well as the installed SDK: a patched
// node_modules directory alone does not invalidate a running webpack resolver.
import assert from 'node:assert/strict';
const base = new URL(process.argv[2] || 'http://localhost:3118');
assert.ok(['localhost', '127.0.0.1', '[::1]'].includes(base.hostname), 'Use a local development server');
const response = await fetch(new URL('/room', base), { signal: AbortSignal.timeout(60000) });
assert.equal(response.status, 200, 'The room page must compile successfully');
const html = await response.text();
const sources = [...new Set([...html.matchAll(/<script[^>]+src="([^"]+)"/g)].map(match => match[1].replaceAll('&amp;', '&')))];
assert.ok(sources.length, 'Room scripts were not found');
const scripts = await Promise.all(sources.map(async source => {
  const url = new URL(source, base);
  assert.equal(url.origin, base.origin, 'Room script must come from the local server');
  const result = await fetch(url, { signal: AbortSignal.timeout(60000) });
  assert.equal(result.status, 200, `Could not load ${url.pathname}`);
  return result.text();
}));
assert.ok(scripts.some(script => script.includes('microphone_selection_unavailable')), 'The served SDK ChannelHandle is missing setMicrophoneDevice; restart the dev server after applying the SDK patch');
assert.ok(scripts.some(script => script.includes('microphone_selection_failed')), 'The served LiveKit provider is missing physical microphone switching');
console.log('PASS served room bundles contain both the SDK device method and LiveKit microphone switching');
