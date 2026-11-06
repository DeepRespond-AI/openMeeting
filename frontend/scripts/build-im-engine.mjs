/**
 * Bundle the IM engine page entry (src/im/engine-entry.ts) into a self-contained
 * ESM file at public/im/engine.js. Run before `next build`/`next dev` — see the
 * `build:im-engine` npm script.
 */
import { build } from 'esbuild';

await build({
  entryPoints: ['src/im/engine-entry.ts'],
  outfile: 'public/im/engine.js',
  bundle: true,
  format: 'esm',
  minify: true,
  target: 'chrome100', // Tauri WebView2 / WKWebView 16.4+ baseline per the SDK docs
  logLevel: 'info',
});
