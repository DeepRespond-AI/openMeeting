# 构建、发布与客户端更新

GitHub Actions 的 `Release` 工作流从选定提交创建 GitHub 草稿 Release；服务端管理端的版本发布用于向已部署客户端分发更新，两者分别操作。GitLab 不执行 `.github/workflows/`。

## 版本与构建来源

桌面 `frontend/package.json`、`frontend/src-tauri/Cargo.toml` 和 `tauri.conf.json` 的版本必须一致，由 `node scripts/ci/check-versions.mjs` 检查。移动端在 `mobile/pubspec.yaml` 独立递增构建号；桌面与移动端的对外版本按发布计划协调，服务端 API 版本独立维护。

GitHub Release 标签严格使用源码版本 `vX.Y.Z`，指向此次运行选中的提交。已有标签指向其他提交或版本已正式发布时，工作流报错并要求先递增源码版本；不移动标签，也不拼接第四段版本号。相同提交的已有草稿可重新运行补齐构建。

## GitHub 构建设置

维护者在仓库 **Settings → Secrets and variables → Actions** 配置自己的发布环境：

| 类型 | 名称 | 内容 |
|---|---|---|
| Variable | `TAURI_SIGNING_PUBLIC_KEY` | 本环境完整 Tauri 公钥内容，不是文件路径 |
| Secret | `TAURI_SIGNING_PRIVATE_KEY` | 同一环境私钥内容；GitHub 托管 runner 不能读取开发机路径 |
| Secret | `TAURI_SIGNING_PRIVATE_KEY_PASSWORD` | 私钥密码；无密码密钥可留空 |
| Variable，可选 | `OPENMEETING_SERVER_URL` | 复用构建工作流未显式传地址时使用的网关 |
| Variables，可选 | `OPENMEETING_ANALYTICS_KEY`、`OPENMEETING_ANALYTICS_HOST` | 自有统计项目与 HTTPS 主机；不配置则统计不可用，详见[隐私与统计](privacy.md) |

首次密钥生成与备份见 [Updater 指南](../frontend/UPDATER.md)。正式构建会生成一次性签名探针并验证公私钥配套；日志和构建配置不写入私钥或密码。更换已发行客户端的更新密钥须另行安排升级，初始化脚本不会代替密钥轮换。

在 **Actions → Release → Run workflow** 选择源分支并填写客户端可访问的 HTTPS 网关。Windows EXE、macOS Apple Silicon 安装包及 Linux x86_64 DEB / AppImage 从同一提交构建；草稿中的安装包、公钥对应的 `.sig` 和更新元数据检查完成后，再手动发布草稿。

Linux 自动更新使用 AppImage；DEB 通过下载新包重新安装升级。不能把 DEB 当作 updater 载荷。AppImage 的依赖与系统版本限制见 [Tauri 分发说明](https://v2.tauri.app/distribute/appimage/)，更新文件格式见 [Tauri updater](https://v2.tauri.app/plugin/updater/)。

`sign-binaries` 控制 Windows/macOS 系统代码签名，需要维护者自己的 DigiCert/Apple 凭据；默认关闭。它与更新签名独立，正式 `Release` 始终要求更新密钥。各平台手动 Build 工作流的 `sign-updater` 默认关闭，可在不配置生产密钥时构建测试包，关闭时不生成自动更新签名。

## 服务端分发验收

在管理端为对应平台创建版本，上传安装包；桌面同时上传同名 `.sig`。确认架构、包内版本、文件 SHA-256、公钥和网关属于同一发布环境，再发布版本。操作与灰度配置见[服务端发布](../server/README.md#七客户端升级版本发布)。

发布前至少验证：旧版能获得正确更新、下载后的字节与产物一致、原生 updater 接受签名、安装后包内版本确实变化、当前版本不重复提示更新。HTTPS 管理端与下载入口都使用 HTTPS。独立 fork 应设置自己的应用标识，避免配置和安装目录与原项目冲突。

## 本地部署 E2E

安装桌面锁定依赖与 Playwright headless Chromium 后，在仓库根运行：

```bash
pnpm --dir frontend install --frozen-lockfile
pnpm --dir frontend exec playwright install --only-shell chromium
node tests/e2e/open-source-readiness.mjs
```

脚本构建实际生产 Dockerfile，使用独立项目、随机本机端口、临时数据库和卷，验证登录、开发验证码注册、发布校验、真实 Tauri 签名、更新元数据以及浏览器下载。默认 local 存储；`OPENMEETING_TEST_STORAGE=minio` 验证 MinIO 路径。`OPENMEETING_E2E_INSTALLER` 可指向本提交实际构建的 Windows EXE，否则使用明确标记的测试载荷。

Windows 原生登录可额外设置 `OPENMEETING_E2E_NATIVE_EXE`，指向应用标识为 `org.example.openmeeting.readiness`（或其子标识）的本地调试客户端，脚本拒绝使用日常应用标识。构建时的 `OPENMEETING_SERVER_URL` 必须与 `OPENMEETING_E2E_PORT` 对应；调试窗口须启用 WebView2 CDP，并与 `OPENMEETING_E2E_CDP_PORT` 对应，例如额外浏览器参数 `--remote-debugging-port=37392 --remote-allow-origins=*`。脚本验证真实 UI 登录、完成引导以及未配置统计时的原生状态。CDP 参数仅用于隔离验收，不加入正式发行包；此路径不验证 IM/RTC SDK 的运行。

报告、失败历史、截图与本地环境文件输出至忽略目录 `.artifacts/open-source-readiness/`；环境文件和签名文件不可公开。脚本只清理自己创建的容器、网络和卷。下载验证不等于实际 OS 安装或真实会议媒体验收；macOS、iOS 和 CUDA 应在相应系统及硬件上独立验收。
