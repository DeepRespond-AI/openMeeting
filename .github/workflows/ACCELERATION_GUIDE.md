# CI/CD 硬件加速指南

> 文档类型：开发过程或验收记录。保留当时的设计、环境和执行边界；当前能力以[功能状态](../../docs/feature-status.md)为准，不作为当前启动或升级指南。

> **过时说明：**Tauri 应用已移除本地 AI 推理（Whisper/Parakeet GPU 特性、`llama-helper` 辅助进程、ONNX Runtime、Vulkan SDK），转写及大模型现由远程服务端处理。下文 GPU/BLAS 特性及 Vulkan 细节属于历史资料，不再适用于 CI。

本文说明 深应会议 CI/CD 工作流当时使用的硬件加速及 CPU 可移植配置。

## 概述

CI 按平台选择加速方式，并保持 Windows 发布产物对所支持 CPU 基线的可移植性：

| 平台 | 加速方式 | 技术 | 分发基线 |
| --- | --- | --- | --- |
| **macOS** | GPU | 默认 Metal；Apple Silicon 可使用 CoreML | Apple Silicon 构建目标 |
| **Windows** | GPU | Vulkan | 支持 AVX2 的 x64 CPU；关闭 AVX-512 |
| **Linux** | CI 中使用 CPU 优化 | OpenBLAS | 源码构建配置 |

Windows 发布包使用启用 Vulkan 的 Whisper，不会自动选择 CUDA。CUDA 需要 NVIDIA 硬件、CUDA 工具链和对应的源码构建配置。Vulkan SDK 是原生构建的前置依赖，需独立于 pnpm 前端依赖安装准备。

## Windows 安装包配置（当时已启用）

### 1. Windows 构建（Vulkan GPU）

```yaml
args: --target x86_64-pc-windows-msvc --features vulkan
```

**提供的能力：**

- Windows 安装包中的 Whisper 启用 Vulkan。
- 兼容支持 Vulkan 的 AMD、Intel 和 NVIDIA 硬件。
- 使用可复现的 CI 配置，避免生成仅针对 CI 机器优化的安装包。

**工作方式：**

- CI 安装 Vulkan SDK `1.4.309.0`，并在构建前验证环境。
- Tauri 构建为 Windows 启用 Vulkan 特性。
- 分发产物保持使用 Vulkan；CUDA 由源码构建时选择。

### 2. Windows CPU 可移植性

发布安装包与针对单台本地机器优化的构建采用不同配置：

- Rust 使用 `x86-64-v2` 目标。
- 原生 Whisper 保留 AVX2，关闭针对构建主机的专门优化。
- `GGML_AVX512`、`GGML_AVX512_VBMI`、`GGML_AVX512_VNNI` 和 `GGML_AVX512_BF16` 必须全部设为 OFF。

工作流将 `CMAKE_PROJECT_INCLUDE` 设为 `force-portable-ggml.cmake`，强制应用以下配置：

```cmake
set(GGML_NATIVE OFF CACHE BOOL "Build without host CPU specialization" FORCE)
```

Rust 目标参数不会控制 Whisper 的原生 C/C++ 编译。不要用旧的 `WHISPER_NATIVE=OFF` 临时方案或单独的 `GGML_*` 环境变量替代仓库中的发布配置。

### 3. 可移植构建缓存与打包前验证

Windows 可移植构建使用 `windows-portable-v1` Rust 缓存前缀，避免通过回退键恢复之前针对构建主机优化的目标缓存。

打包前，`verify-portable-ggml.cjs` 读取 Whisper 生成的 CMake 缓存。缺少原生构建证据、启用 `GGML_NATIVE`，或四个 AVX-512 选项中任一开启时，构建均会失败，防止未经验证的原生库进入安装包。

## Linux 构建（OpenBLAS CPU）

```yaml
args: --target x86_64-unknown-linux-gnu --features openblas
```

**CI 使用 OpenBLAS 的原因：**

- GitHub Actions Linux 执行器不提供用于发布型加速测试的 GPU。
- OpenBLAS 提供优化的 CPU 运算，不依赖 GPU。
- Linux 安装沿用源码构建，本地加速方式应与源码环境配置一致。

具备对应硬件和工具链时，Linux 源码构建可选择 CUDA、Vulkan、ROCm、OpenBLAS 或 CPU 配置。本地准备方式见源码构建指南。

## macOS 构建（Metal GPU）

macOS 构建默认启用 Metal；Apple Silicon 构建也可使用 CoreML。标准 macOS 安装包构建不需要额外特性开关。

## 当时调整的工作流

### 1. `build.yml`（共享发布工作流）

共享工作流构建 Windows 时：

- 启用 Vulkan 特性。
- 安装并验证 Vulkan SDK `1.4.309.0`。
- 应用可移植 CMake 钩子和 `x86-64-v2` Rust 目标。
- 使用 `windows-portable-v1` 缓存前缀。
- 执行打包前的 Whisper 验证。

Linux 构建可启用 OpenBLAS；macOS 默认使用 Metal。

### 2. `build-devtest.yml`（Windows DevTest）

Windows DevTest 使用与正式构建相同的可移植 CMake 钩子、Rust 目标、缓存前缀、Vulkan 配置和打包前验证。修改 DevTest 行为时须保留这些检查。

### 3. `build-windows.yml`（Windows 独立构建）

Windows 独立工作流使用 Vulkan 特性，并在打包前执行同样的可移植性检查。只更新共享工作流或只更新独立工作流，都不能视为完成修改。

## 验证

### 如何验证 Windows 安装包构建

1. **检查工作流配置**
   - Windows 构建参数包含 `--features vulkan`。
   - 已安装并验证 Vulkan SDK `1.4.309.0`。
   - `CMAKE_PROJECT_INCLUDE` 使用可移植构建钩子。
   - Rust 使用 `-C target-cpu=x86-64-v2`。

2. **检查原生 Whisper 配置**
   - `GGML_NATIVE` 为 OFF。
   - 四个 AVX-512 选项均为 OFF。
   - 打包前已完成 `verify-portable-ggml.cjs` 检查。

3. **检查缓存隔离**
   - Windows 构建使用 `windows-portable-v1` 缓存前缀。
   - 不复用 CPU 配置未知的原生缓存。

### 运行时验证

确认打包后的应用可以在支持 AVX2、但不支持 AVX-512 的 Windows 电脑上运行。不支持 AVX2 的环境需单独验收，不属于此 Whisper 安装包基线。

## 技术细节

### Whisper 后端

Whisper 集成支持以下加速路径：

```toml
metal = ["whisper-rs/metal"]
cuda = ["whisper-rs/cuda"]
vulkan = ["whisper-rs/vulkan"]
hipblas = ["whisper-rs/hipblas"]
openblas = ["whisper-rs/openblas"]
```

### Windows CI 选择 Vulkan 的原因

CUDA 需要兼容的 NVIDIA 硬件、驱动及 CUDA 工具链。标准 Windows 安装包使用 Vulkan，使 CI 能生成统一配置的产物，不替终端用户选择 CUDA。需要 CUDA 的开发者应准备兼容的源码构建。

### Linux 源码构建

OpenBLAS 适合无 GPU 的 Linux CI 执行器。Linux 本地开发应按已安装的 SDK 和硬件选择后端，不直接套用 Windows 安装包配置。

## 故障排查

### Windows 构建出现 Vulkan 错误

- 确认 Vulkan SDK 安装和环境验证步骤均已完成。
- 确认工作流仍使用 SDK `1.4.309.0`。
- pnpm 安装不会安装或修复 Vulkan SDK。

### 可移植性验证失败

此类失败必须阻止打包。检查生成的 Whisper CMake 缓存和可移植缓存前缀，不绕过打包前验证器。重新进行可移植构建比复用 CPU 标记未知的缓存更可靠。

### 需要 CUDA

使用具备 CUDA 工具链的兼容 NVIDIA 源码构建环境。标准 Windows 安装包保持使用 Vulkan 构建。

## 相关文档

- 源码构建：[桌面端](../../frontend/README.md)、[移动端](../../mobile/README.md)
- [工作流总览](WORKFLOWS_OVERVIEW.md)
- [DevTest 工作流指南](README_DEVTEST.md)
- [Whisper.cpp](https://github.com/ggerganov/whisper.cpp)

## 概述

- Windows 安装包中的 Whisper 启用 Vulkan、保留 AVX2 并关闭 AVX-512。
- 可移植 CMake 钩子、Rust 目标、缓存前缀、Vulkan 配置和打包前验证共同生效，须整体保留。
- 正确配置源码构建后仍可选择 CUDA。
- Linux 沿用源码构建，macOS 默认使用 Metal。
