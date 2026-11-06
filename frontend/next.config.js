const path = require('path');
const tiptapPmResolveBase = path.dirname(require.resolve('@tiptap/pm/model'));
const resolveFromTiptapPm = (pkg) =>
  require.resolve(pkg, { paths: [tiptapPmResolveBase] });
// These SDKs expose an import-only entry; resolve the installed file directly
// so loading this CommonJS Next config does not require a "require" export.
const resolveImSdk = (pkg) => require.resolve(path.join(__dirname, 'node_modules', '@deeprespond', pkg, 'dist', 'index.js'));

/** @type {import('next').NextConfig} */
const nextConfig = {
  // Isolate an E2E dev server from the user's running .next cache.
  distDir: process.env.OPENMEETING_NEXT_DIST_DIR || '.next',
  reactStrictMode: false, // Disabled for BlockNote compatibility
  output: 'export',
  images: {
    unoptimized: true,
  },
  // Add basePath configuration
  basePath: '',
  assetPrefix: '/',

  // Add webpack configuration for Tauri
  webpack: (config, { isServer }) => {
    // Explicit UI configuration acceptance fixture; never enabled in builds.
    if (process.env.NODE_ENV === 'development' && process.env.OPENMEETING_E2E_MEETING_UI === '1') {
      const webpack = require('webpack');
      config.plugins.push(new webpack.NormalModuleReplacementPlugin(/^@\/config\/meeting-ui$/, resource => {
        resource.request = path.resolve(__dirname, '../tests/e2e/fixtures/meeting-ui-config.ts');
      }));
    }
    // Isolated full-page layout E2E only; normal desktop and production builds
    // keep the authenticated IM/RTC adapters.
    if (process.env.NODE_ENV === 'development' && process.env.OPENMEETING_E2E_DESKTOP_LAYOUT === '1') {
      const webpack = require('webpack');
      config.plugins.push(new webpack.NormalModuleReplacementPlugin(/^(@\/contexts\/IMContext|@deeprespond\/im-web-react)$/, resource => {
        resource.request = path.resolve(__dirname, '../tests/e2e/fixtures/desktop-layout-im.jsx');
      }));
      config.plugins.push(new webpack.NormalModuleReplacementPlugin(/\.\/media\/imChannel$/, resource => {
        resource.request = path.resolve(__dirname, process.env.OPENMEETING_E2E_MEETING_UI === '1'
          ? '../tests/e2e/fixtures/meeting-ui-media.ts' : process.env.OPENMEETING_E2E_IM_RTC_SCREEN === 'local'
          ? '../tests/e2e/fixtures/im-rtc-screen-local.ts' : process.env.OPENMEETING_E2E_IM_RTC_SCREEN === '1'
          ? '../tests/e2e/fixtures/im-rtc-screen-media.ts' : process.env.OPENMEETING_E2E_MEETING_SESSION === '1'
          ? '../tests/e2e/fixtures/meeting-session-media.ts' : '../tests/e2e/fixtures/desktop-layout-media.ts');
      }));
    }
    // Explicit local E2E fixture: exercise capture without consuming real devices/RTC.
    if (process.env.NODE_ENV === 'development' && process.env.OPENMEETING_E2E_SYNTHETIC === '1') {
      const webpack = require('webpack');
      config.plugins.push(new webpack.NormalModuleReplacementPlugin(/\.\/media\/imChannel$/, resource => {
        resource.request = path.resolve(__dirname, '../tests/e2e/fixtures/synthetic-media.ts');
      }));
    }
    if (!isServer) {
      config.resolve.fallback = {
        ...config.resolve.fallback,
        fs: false,
        path: false,
        os: false,
      };

      // Keep ProseMirror single-instanced for BlockNote/Tiptap.
      config.resolve.alias = {
        ...config.resolve.alias,
        // Resolve the patched SDK from this installation, including imports made
        // by im-tauri. A running dev server can otherwise retain the old pnpm
        // package path after a patch changes the dependency's real location.
        '@deeprespond/im-web$': resolveImSdk('im-web'),
        '@deeprespond/im-tauri$': resolveImSdk('im-tauri'),
        '@blocknote/core$': require.resolve('@blocknote/core'),
        '@blocknote/react$': require.resolve('@blocknote/react'),
        '@blocknote/shadcn$': require.resolve('@blocknote/shadcn'),
        'prosemirror-model': resolveFromTiptapPm('prosemirror-model'),
        'prosemirror-state': resolveFromTiptapPm('prosemirror-state'),
        'prosemirror-view': resolveFromTiptapPm('prosemirror-view'),
        'prosemirror-transform': resolveFromTiptapPm('prosemirror-transform'),
        'prosemirror-tables': resolveFromTiptapPm('prosemirror-tables'),
        'prosemirror-schema-list': resolveFromTiptapPm('prosemirror-schema-list'),
        'prosemirror-keymap': resolveFromTiptapPm('prosemirror-keymap'),
        'prosemirror-commands': resolveFromTiptapPm('prosemirror-commands'),
        'prosemirror-history': resolveFromTiptapPm('prosemirror-history'),
        'prosemirror-inputrules': resolveFromTiptapPm('prosemirror-inputrules'),
        'prosemirror-gapcursor': resolveFromTiptapPm('prosemirror-gapcursor'),
        'prosemirror-dropcursor': resolveFromTiptapPm('prosemirror-dropcursor'),
      };
    }
    return config;
  },
}

module.exports = nextConfig
