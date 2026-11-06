# 支持范围

本项目由 DeepRespond-AI 维护。当前维护线为 0.1.x，优先处理最新补丁版本；使用前查看[当前功能与平台边界](docs/feature-status.md)。服务端 API 版本独立于桌面和移动安装包版本。

| 目标 | 当前支持方式 |
|---|---|
| Linux x86_64 服务端 | Docker Compose；CPU、本地对象存储、MinIO 或 OSS；CUDA 另需目标硬件验收 |
| Windows x64 桌面 | 原生编译检查和安装包构建；真实设备、安装与更新单独验收 |
| macOS Apple Silicon / Linux x86_64 桌面 | 提供构建入口；运行、设备与安装包应在目标系统验证 |
| Android | Flutter 分析、测试与 debug APK 原生构建；系统音频、后台行为与升级需真机验收 |
| iOS | 需要 macOS/Xcode、签名及真实设备；不以 Android 结果推定 iOS 已验证 |

普通问题使用 Issue，说明版本、系统、部署模式、复现步骤与脱敏日志。先搜索已有问题；安全漏洞走 [SECURITY.md](SECURITY.md)。维护者尽力处理社区反馈，不承诺固定响应时间。

功能建议说明场景、当前限制与最小可接受行为，避免仅提交技术方案。较大改动先用 Issue 协调范围，再从 `develop` 创建功能分支并提交以 `develop` 为目标的 PR。发布与版本记录见[发布指南](docs/releases.md)和 [CHANGELOG](CHANGELOG.md)。
