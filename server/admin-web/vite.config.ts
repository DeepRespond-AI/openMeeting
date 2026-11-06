import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import { fileURLToPath, URL } from 'node:url'

export default defineConfig({
  base: '/admin/',
  plugins: [vue()],
  resolve: {
    alias: { '@': fileURLToPath(new URL('./src', import.meta.url)) },
  },
  build: {
    outDir: '../gateway_ms/static/admin',
    emptyOutDir: true,
    chunkSizeWarningLimit: 1500,
  },
  server: {
    port: 5173,
    proxy: {
      '/api/v1/updates': {
        target: process.env.OPENMEETING_GATEWAY_URL || 'http://127.0.0.1:39110',
        changeOrigin: true,
      },
      '/admin/api': {
        target: process.env.OPENMEETING_GATEWAY_URL || 'http://127.0.0.1:39110',
        changeOrigin: true,
        // Keep SSE (/admin/api/events) streaming: disable buffering/compression on the proxied response
        configure: (proxy) => {
          proxy.on('proxyReq', (proxyReq, req) => {
            if (req.url?.startsWith('/admin/api/events')) {
              proxyReq.setHeader('Accept-Encoding', 'identity')
            }
          })
          proxy.on('proxyRes', (proxyRes) => {
            if (String(proxyRes.headers['content-type'] || '').includes('text/event-stream')) {
              proxyRes.headers['cache-control'] = 'no-cache'
              proxyRes.headers['x-accel-buffering'] = 'no'
            }
          })
        },
      },
    },
  },
})
