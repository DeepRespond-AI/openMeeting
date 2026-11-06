# GitHub Actions 工作流总览

> 文档类型：开发过程或验收记录。保留当时的设计、环境和执行边界；当前能力以[功能状态](../../docs/feature-status.md)为准，不作为当前启动或升级指南。

> **过时说明：**下文有关 Metal/Vulkan GPU 加速、`llama-helper` 和 ONNX Runtime 的内容已过时；本地推理已移除，转写和大模型现由远程服务端处理。

本文概述仓库中可用的 CI/CD 工作流。

构建来源、网关地址、签名与草稿发布的当前操作见[发布指南](../../docs/releases.md)。

**当前入口：**[PR Checks](pr-main-check.yml) 已在 PR、`main` / `develop` 推送及合并队列事件自动运行，并提供 `Quality Gate` 汇总结果；范围与分支保护设置见[持续集成](../../docs/continuous-integration.md)。下文构建与发布工作流仍手动触发，涉及旧架构的说明仅供历史参考。

## 工作流文件

### 1. **build-devtest.yml**：DevTest 开发测试构建
**用途：**为开发和测试快速构建。

**主要功能：**
- 默认关闭签名，以加快构建。
- 可通过工作流手动输入启用签名。
- 各平台并行构建。
- 产物保留 14 天。

**触发方式：**
- 仅手动触发。

**适用场景：**
- 日常开发。
- 功能测试。
- 需要快速反馈。

---

### 2. **build-macos.yml**：macOS 独立构建
**用途：**针对 Apple Silicon（M1/M2/M3）构建和测试。

**主要功能：**
- Apple 开发者证书签名，可选。
- 使用 Apple ID 公证。
- 签名验证。
- 针对 macOS 的优化。

**触发方式：**
- 仅手动触发。

**适用场景：**
- macOS 专项开发。
- 测试 Metal GPU 加速。
- 验证 macOS 专属功能。

**产物：**
- `.dmg` 安装包。
- `.app` 应用包。

---

### 3. **build-windows.yml**：Windows 独立构建
**用途：**针对 Windows x64 构建和测试。

**主要功能：**
- DigiCert KeyLocker 签名（云 HSM）。
- 为 MSI 和 NSIS 安装包签名。
- 使用 PowerShell 验证签名。
- 验证 MSI 安装包。

**触发方式：**
- 仅手动触发。

**适用场景：**
- Windows 专项开发。
- 测试 Vulkan GPU 加速。
- 验证 Windows 专属功能。

**产物：**
- `.msi` 安装包。
- `.exe` NSIS 安装包。

---

### 4. **build-linux.yml**：Linux 独立构建
**用途：**针对 Linux 发行版构建和测试。

**主要功能：**
- 支持 Ubuntu 22.04 和 24.04。
- 支持 DEB、AppImage、RPM 等安装包格式。
- Tauri 自动更新签名。
- AppImage 兼容性修复。
- 安装包验证。

**触发方式：**
- 仅手动触发。

**适用场景：**
- Linux 专项开发。
- 测试 Vulkan GPU 加速。
- 验证安装包格式。

**产物：**
- `.deb` 安装包（Ubuntu/Debian）。
- `.AppImage` 便携包。
- `.rpm` 安装包（Fedora/RHEL）。

---

### 5. **build-test.yml**：多平台测试构建
**用途：**为所有平台生成带签名的测试构建。

**主要功能：**
- 默认启用签名。
- 各平台并行构建。
- 使用可复用的 `build.yml` 工作流。
- 产物保留 30 天。
- 产物名称使用 `openmeeting-test-` 前缀。

**触发方式：**
- 仅手动触发。

**适用场景：**
- 发布前测试。
- 验证签名基础设施。
- 同时测试全部平台。

---

### 6. **build.yml**：可复用构建工作流
**用途：**供其他工作流调用的共享构建流程。

**主要功能：**
- 作为可复用工作流被其他流程调用。
- 提供丰富的输入配置。
- 由 `build-test.yml` 和 `release.yml` 使用。

**不直接触发**，作为其他工作流的构建基础。

---

### 7. **release.yml**：正式发布
**用途：**创建包含已签名二进制文件的正式版本。

**主要功能：**
- 必须签名。
- 创建 GitHub Release 草稿。
- 从 `tauri.conf.json` 读取版本标签。
- 上传发布产物。
- **仅包含 macOS 和 Windows**，正式发布不包含 Linux。
- 自动生成 Tauri 更新所需的 `latest.json`。
- **版本自动递增：**标签已存在时自动递增，例如 `0.1.1` -> `0.1.1.1` -> `0.1.1.2`，最多到 `.100`。

**触发方式：**
- 仅手动触发。

**适用场景：**
- 准备发布新版本。
- 创建正式发布产物。

**产物：**
- GitHub Release 草稿。
- macOS：DMG 安装包、app.tar.gz 更新包及 .sig。
- Windows：已签名 MSI、NSIS 安装包及 .sig 文件。
- 自动更新清单：latest.json。
- 自动生成发布说明。

**版本规则：**
- `v0.1.1` 标签不存在时，创建 `v0.1.1`。
- `v0.1.1` 已存在时，创建 `v0.1.1.1`。
- `v0.1.1.1` 已存在时，创建 `v0.1.1.2`。
- 上限为 `v0.1.1.100`，之后需更新 `tauri.conf.json`。

**说明：**发布不包含 Linux 构建，Linux 测试使用 `build-linux.yml`。

---

### 8. **pr-main-check.yml**：PR 自动检查
**用途：**在 PR 中执行源码检查和隔离测试，并汇总为可配置的合并门槛。

覆盖桌面、管理端、后端、Flutter、Windows 构建脚本以及文档与配置。PR、`main` / `develop` 推送和合并队列自动触发，也可手动运行。配置 `Quality Gate` 必需状态检查及本地复现见[持续集成](../../docs/continuous-integration.md)。

---

## 如何运行工作流

1. 打开 GitHub 仓库的 **Actions** 页面。
2. 从左侧栏选择工作流。
3. 点击 **Run workflow** 按钮。
4. 选择运行分支。
5. 配置构建类型、签名等选项。
6. 点击 **Run workflow** 开始。
7. 在 Actions 页面查看进度。

---

## 快速选择

### 开发新功能
- 使用 **`build-devtest.yml`**，手动触发。
- 构建较快，默认不签名。
- 需要时勾选签名。

### 测试 macOS 专属代码
- 使用 **`build-macos.yml`**，手动触发。
- 专注于 macOS。
- 签名可选。

### 测试 Windows 专属代码
- 使用 **`build-windows.yml`**，手动触发。
- 专注于 Windows。
- 签名可选。

### 测试 Linux 安装包
- 使用 **`build-linux.yml`**，手动触发。
- 选择 Ubuntu 版本。
- 选择安装包类型。

### 为全部平台生成签名构建
- 使用 **`build-test.yml`**，手动触发。
- 全部平台。
- 启用签名。
- 完整验证。

### 准备发布
- 使用 **`release.yml`**，手动触发。
- 创建 GitHub Release。
- 全部平台，完整签名。
- 生成面向生产环境的产物。

---

## 工作流依赖关系

```
build.yml（可复用）
    |-- build-test.yml（调用 build.yml）
    |-- release.yml（调用 build.yml）

独立工作流（不使用 build.yml）：
    |-- build-macos.yml
    |-- build-windows.yml
    |-- build-linux.yml
    |-- build-devtest.yml
    |-- pr-main-check.yml（PR 自动检查与 Quality Gate）
```

---

## 对比表

| 工作流 | 平台 | 默认签名 | 速度 | 保留时间 | 用途 |
|----------|-----------|----------------|-------|-----------|----------|
| `build-devtest.yml` | 全部 | 关闭 | 快 | 14 天 | 开发 |
| `build-macos.yml` | macOS | 可选 | 中 | 30 天 | macOS 开发 |
| `build-windows.yml` | Windows | 可选 | 中 | 30 天 | Windows 开发 |
| `build-linux.yml` | Linux | 可选 | 中 | 30 天 | Linux 开发 |
| `build-test.yml` | 全部 | 启用 | 慢 | 30 天 | 发布前测试 |
| `release.yml` | macOS + Windows | 必须 | 慢 | 永久 | 发布 |

---

## 产物命名规则

```
openmeeting-{workflow}-{platform}-{target}-{version}
```

**示例：**
- `openmeeting-devtest-macOS-aarch64-apple-darwin-0.1.3`
- `openmeeting-test-windows-x86_64-pc-windows-msvc-0.1.3`
- `openmeeting-macos-aarch64-release-0.1.3`

---

## 所需密钥配置

各工作流所需的密钥配置如下：

### macOS 签名
- `APPLE_CERTIFICATE`：Developer ID 证书（base64）。
- `APPLE_CERTIFICATE_PASSWORD`：证书密码。
- `APPLE_ID`：Apple ID 邮箱。
- `APPLE_PASSWORD`：应用专用密码。
- `APPLE_TEAM_ID`：团队 ID。
- `KEYCHAIN_PASSWORD`：临时钥匙串密码。

### Windows 签名（DigiCert）
- `SM_HOST`：DigiCert 服务 URL。
- `SM_API_KEY`：API 密钥。
- `SM_CLIENT_CERT_FILE_B64`：客户端证书（base64）。
- `SM_CLIENT_CERT_PASSWORD`：客户端证书密码。
- `SM_CODE_SIGNING_CERT_SHA1_HASH`：证书哈希。

### Tauri 自动更新（全部平台）
- `TAURI_SIGNING_PRIVATE_KEY`：Ed25519 私钥。
- `TAURI_SIGNING_PRIVATE_KEY_PASSWORD`：私钥密码。

### 应用配置
- `OPENMEETING_RSA_PUBLIC_KEY`：许可证校验公钥。
- `SUPABASE_URL`：在线许可证验证地址。
- `SUPABASE_ANON_KEY`：Supabase 匿名密钥。

---

## 性能建议

1. 日常开发使用 **devtest 工作流**，速度最快。
2. 仅在必要时**启用签名**，签名约增加 10–15 分钟。
3. 开发平台专属代码时，只测试对应平台。
4. 发布前运行**完整构建**（`build-test.yml`）。
5. 已启用缓存，后续构建会更快。

---

## 故障排查

### Windows MSI 构建出现版本错误
- 确认 `tauri.conf.json` 的版本不包含非数字预发布标识。
- 使用 `0.1.3`，不要使用 `0.1.2-pro-trial`。

### 签名失败
- 确认所有必需密钥均已配置。
- 检查密钥有效期。
- 查看工作流日志中的具体错误。

### 产物不可用
- 确认构建完整成功。
- 产物会按保留期过期。
- 确认启用了 `upload-artifacts`。

### Actions 中未显示工作流
- 检查 YAML 语法。
- 确认文件位于 `.github/workflows/` 目录。
- 确认扩展名为 `.yml` 或 `.yaml`。

---

## 支持

工作流出现问题时：
1. 在 Actions 页面查看工作流日志。
2. 查阅本文。
3. devtest 专项问题见 `README_DEVTEST.md`。
4. GPU 和性能信息见 `ACCELERATION_GUIDE.md`。
