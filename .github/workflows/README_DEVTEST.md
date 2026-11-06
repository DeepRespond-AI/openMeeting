# DevTest 构建工作流

> 文档类型：开发过程或验收记录。保留当时的设计、环境和执行边界；当前能力以[功能状态](../../docs/feature-status.md)为准，不作为当前启动或升级指南。

本文说明如何使用 `build-devtest.yml` 工作流进行构建和测试。

## 概述

DevTest 工作流专用于开发与测试，提供以下能力：
- 为 macOS、Windows 和 Linux 全部平台构建。
- **默认关闭代码签名**，以缩短构建时间。
- 可通过工作流输入参数**选择启用签名**。
- 上传产物用于测试。

## 触发工作流

工作流**仅手动触发**：

1. 打开 GitHub 仓库的 **Actions** 页面。
2. 从左侧栏选择 **Build and Test - DevTest**。
3. 点击 **Run workflow** 按钮。
4. 配置选项：
   - **Branch**：选择构建分支。
   - **Sign the build**：勾选以启用代码签名，默认不勾选。
   - **Upload build artifacts**：勾选以上传产物，默认勾选。
5. 点击 **Run workflow** 开始。

## 工作流选项

### 构建签名（Sign the build）
- **不勾选（默认）：**不签名，构建较快，约 25–30 分钟。
- **勾选：**为全部平台完整签名，约 35–45 分钟。

### 上传构建产物（Upload build artifacts）
- **勾选（默认）：**上传产物并提供下载。
- **不勾选：**执行构建，但不保存产物。

## 构建矩阵

工作流并行构建全部平台：

| 平台 | 目标 | 产物 |
|----------|--------|--------|
| macOS (Apple Silicon) | aarch64-apple-darwin | DMG + App |
| Windows (x64) | x86_64-pc-windows-msvc | MSI + NSIS |
| Linux (Ubuntu 22.04) | x86_64-unknown-linux-gnu | DEB |
| Linux (Ubuntu 24.04) | x86_64-unknown-linux-gnu | AppImage + RPM |

## 代码签名说明

启用签名时：

### macOS
- 使用密钥配置中的 **Apple 开发者证书**。
- 使用 Apple ID 进行**公证**。
- 为 DMG 和 .app 应用包签名。
- 使用 `codesign` 和 `spctl` 验证签名。

### Windows
- 使用 **DigiCert KeyLocker**（云 HSM）。
- 为 MSI 和 NSIS 安装包签名。
- 使用 PowerShell 验证签名。

### Linux
- 使用 **Tauri 自动更新签名**（Ed25519）。
- 为自动更新清单签名。

## 构建产物

产物自动上传并保留 **14 天**：

- **macOS**: `*.dmg`, `*.app`, `*.app.tar.gz`, `*.app.tar.gz.sig`
- **Windows**: `*.msi`, `*.msi.sig`, `*.exe`, `*.exe.sig`
- **Linux**: `*.deb`, `*.AppImage`, `*.rpm`

### 下载产物

1. 打开 **Actions** 页面。
2. 选择已完成的工作流运行记录。
3. 向下滚动到 **Artifacts** 区域。
4. 点击产物名称下载。

## 示例

### 示例 1：不签名构建（默认，较快）

1. 打开 Actions > Build and Test - DevTest。
2. 点击“Run workflow”。
3. 保持全部选项为默认值。
4. 点击“Run workflow”。

**结果：**生成未签名构建，约需 25–30 分钟。

---

### 示例 2：签名构建

1. 打开 Actions > Build and Test - DevTest。
2. 点击“Run workflow”。
3. 勾选“Sign the build”。
4. 点击“Run workflow”。

**结果：**生成完整代码签名构建，约需 35–45 分钟。

## 硬件加速

> **过时说明：**Tauri 应用已移除本地推理，转写和大模型现由远程服务端处理，因此 CI 不再构建 GPU/BLAS 特性。

当时各平台的硬件加速配置如下：

| 平台 | 加速方式 | 性能 |
|----------|-------------|-------------|
| macOS | Metal GPU | 比 CPU 快 10–15 倍 |
| Windows | Vulkan GPU | 比 CPU 快 5–10 倍 |
| Linux | OpenBLAS CPU | 比普通 CPU 实现快 2–3 倍 |

## 故障排查

### 签名未生效

**问题：**已启用签名，但产物仍未签名。

**处理方法：**
1. 确认仓库设置中已配置全部必需密钥。
2. 查看工作流日志中的具体错误。
3. 确认密钥未过期。

### 构建失败

**问题：**构建在签名阶段失败。

**处理方法：**
1. 检查全部必需密钥是否已配置：
   - `APPLE_CERTIFICATE`, `APPLE_ID`, `APPLE_PASSWORD`, `APPLE_TEAM_ID`
   - `SM_HOST`, `SM_API_KEY`, `SM_CODE_SIGNING_CERT_SHA1_HASH`
   - `TAURI_SIGNING_PRIVATE_KEY`, `TAURI_SIGNING_PRIVATE_KEY_PASSWORD`
2. 查看工作流日志中的具体错误。
3. 先尝试不签名构建，以缩小问题范围。

### 产物不可用

**问题：**无法下载构建产物。

**处理方法：**
1. 检查工作流状态，只有构建成功后才提供产物。
2. 产物保留 14 天后过期。
3. 确认运行时勾选了“Upload build artifacts”。

## 耗时对比

| 构建类型 | 耗时 | 适用场景 |
|------------|----------|-------------|
| **不签名**（默认） | 约 25–30 分钟 | 日常开发、快速测试 |
| **签名** | 约 35–45 分钟 | 发布前测试、生产相似环境测试 |

## 建议做法

1. 日常开发和测试使用**不签名构建**。
2. 仅在以下情况**启用签名**：
   - 测试接近生产环境的场景。
   - 准备发布。
   - 测试安装包行为。
   - 验证代码签名基础设施。
3. 触发工作流前先在本地测试，减少 CI 耗时。
4. 查看工作流摘要，确认构建状态。

## 工作流配置

配置文件位于 `.github/workflows/build-devtest.yml`。

主要配置：
- **默认签名：**关闭。
- **产物保留期：**14 天。
- **并行构建：**全部平台同时执行。
- **触发方式：**仅手动触发。

## 相关工作流

- `build-macos.yml`：带签名的 macOS 专项构建。
- `build-windows.yml`：带签名的 Windows 专项构建。
- `build-linux.yml`：带签名的 Linux 专项构建。
- `build-test.yml`：全部平台签名构建，用于发布前测试。
- `release.yml`：正式发布工作流。
