# 深应会议 管理端（admin-web）

Vue 3 + Vite + TypeScript + Element Plus + ECharts 单页应用，由 FastAPI 服务以 `/admin/` 路径托管，调用 `/admin/api`（接口约定见 [API 契约](../API.md#admin-api)）。

## 开发

在 `server/admin-web/` 执行，先按[服务端指南](../README.md)启动网关及业务服务：

```bash
pnpm install --frozen-lockfile # 按锁文件安装依赖
pnpm dev          # http://localhost:5173/admin/
```

开发服务器会把 `/admin/api`（含 SSE `/admin/api/events`）代理到 `http://127.0.0.1:39110`，请先启动网关及业务服务。

## 构建

```bash
pnpm build        # vue-tsc 类型检查 + vite 构建
```

产物输出到 `../gateway_ms/static/admin/`（构建前会清空该目录），由网关在 `/admin/` 下提供静态访问。Docker 网关镜像使用同一路径。产物不入库（见 `server/.gitignore`），裸机部署前需先执行构建。

> 前端使用 HTML5 history 路由（如 `/admin/dashboard`），后端需对 `/admin/*` 中非静态文件、非 `/admin/api` 的路径回退返回 `index.html`。
