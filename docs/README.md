# 文档导航

第一次运行项目从[快速启动](../quickstart.md)开始；查当前实现与验收范围看[功能状态](feature-status.md)。本页只维护阅读入口，操作步骤在对应指南中维护。

## 新开发者阅读路径

先按[项目结构](project-structure.md)定位代码，按[系统架构](architecture.md)理解各端与服务职责，再选择下面的开发路径。开始前核对[工具链版本](continuous-integration.md#检查范围)；首次启动使用[快速启动](../quickstart.md)，不需要先打包安装程序或离线部署包。

| 开发方向 | 环境与运行 | 修改约定与接口 | 验证 |
|---|---|---|---|
| 桌面客户端 | [桌面指南](../frontend/README.md)；[Linux 系统依赖](building_in_linux.md) | [UI 规范](../frontend/UI_design.md)、[API 接入](../frontend/API.md) | [桌面测试](../frontend/TESTING.md) |
| Flutter 移动端 | [移动端指南](../mobile/README.md)、[设备与存储连接](../mobile/DEVICE_DEVELOPMENT.md) | [开发规范](../mobile/DEVELOPMENT.md)、[会议开发](../mobile/LIVE_MEETING_DEVELOPMENT.md) | [移动测试](../mobile/TESTING.md) |
| 后端与管理端 | [服务端指南](../server/README.md)、[热重载](../server/docker_dev.md)、[管理端开发](../server/admin-web/README.md) | [API 接入指南](../server/API_GUIDE.md)、[API 契约](../server/API.md) | [测试总入口](testing/README.md)、[PR 检查](continuous-integration.md) |

构建签名、服务器部署、备份和发布是后续任务，入口见下表。

## 启动、开发与发布

| 任务 | 维护入口 |
|---|---|
| 首次启动后端、配置平台并连接客户端 | [快速启动](../quickstart.md) |
| 桌面 dev / prod 启动、平台依赖、构建签名、产物及分发 | [桌面指南](../frontend/README.md) |
| Linux 桌面系统依赖、Bash 开发与安装包构建 | [Linux 构建指南](building_in_linux.md) |
| Windows 三客户端联调 | [桌面三开](../frontend/DEV_MULTI.md) |
| Vue 管理端开发、代理与静态构建 | [管理端指南](../server/admin-web/README.md) |
| 桌面更新密钥、公钥与签名环境 | [Updater 签名](../frontend/UPDATER.md) |
| 移动端应用配置初始化与签名准备 | [移动端构建](../mobile/README.md#构建) |
| 服务端部署、环境变量与裸机启动 | [服务端指南](../server/README.md) |
| 运行巡检、数据库与文件备份、隔离恢复、发布回退 | [服务端运维](../server/OPERATIONS.md) |
| 本机构建、上传镜像并替换服务器上的单个服务 | [单服务镜像更新流程](service-image-update.md) |
| Docker 源码重载、依赖更新与重启选择 | [后端开发](../server/docker_dev.md) |
| 数据库实例、连接与隔离 | [数据库说明](database-isolation.md) |
| Docker MinIO、阿里云 OSS 及环境变量切换 | [对象存储](object-storage.md) |
| 出站代理、供应商域名及 CDN 放行 | [统一出入网关](unified-egress.md) |
| STT GPU 环境 | [GPU 部署入口](GPU_ACCELERATION.md) |
| 移动端启动与 dev / prod 构建 | [移动端指南](../mobile/README.md) |
| Android 模拟器、USB / Wi-Fi 真机 | [设备开发](../mobile/DEVICE_DEVELOPMENT.md) |
| Flutter 三客户端开发 | [移动三开](../mobile/DEV_MULTI.md) |
| 移动端版本更新、Android 签名 | [更新流程](../mobile/UPDATES.md)、[签名说明](../mobile/android/keystores/README.md) |

## 架构、接口与规范

| 问题 | 维护入口 |
|---|---|
| 系统有哪些模块、请求经过哪些服务 | [系统架构](architecture.md) |
| 代码放在哪里、目录如何命名 | [项目结构](project-structure.md) |
| 功能做到了什么、哪些还未验收 | [功能状态与验收边界](feature-status.md) |
| 如何登录、搜索、入会、处理异步结果 | [API 中文接入指南](../server/API_GUIDE.md) |
| HTTP 字段、管理端接口、事件和 Tauri 命令 | [API 契约](../server/API.md) |
| 桌面视觉与交互规范 | [桌面 UI 规范](../frontend/UI_design.md) |
| Flutter 架构、状态、主题及国际化规范 | [移动端开发指南](../mobile/DEVELOPMENT.md) |
| 提交与评审要求 | [开发协作](../CONTRIBUTING.md) |
| GitHub PR 自动检查、失败复现与合并门槛 | [持续集成](continuous-integration.md) |
| 客户端构建、版本规则、签名与分发验收 | [发布指南](releases.md) |
| 运行模式、规格与容量测量 | [部署容量](deployment-capacity.md) |
| 数据流与可选使用统计 | [隐私与统计](privacy.md) |
| 支持平台、维护线与社区反馈 | [支持范围](../SUPPORT.md)、[安全报告](../SECURITY.md) |

## 会议说明与开发记录

- 当前 IM：群与文件授权见[会中聊天](meeting-im-chat.md)，提醒与投递见[通知策略](meeting-im-capabilities.md)，页面操作和媒体统计见[工作台](meeting-im-workbench.md)。
- 当前 RTC 与共享：[连接和成员生命周期](meeting-resilience.md)、[第二路视频实现](im-rtc-second-video.md)、[媒体预览](chat-inline-media.md)。
- 当前页面配置：[会议 UI 模块](meeting-ui-config.md)。
- 设计说明：[IM 接入记录](meeting-im-development.md)、[共享方案取舍](im-rtc-screen-share.md)、[跨页返回设计](meeting-share-return.md)、[同账号排查](same-account-meeting-entry-investigation.md)、[安全取消设计](same-account-entry-fix.md)。
- 移动端：[会议开发](../mobile/LIVE_MEETING_DEVELOPMENT.md)、[UI 布局设计](../mobile/UI_design.md)、[系统声音采集](../mobile/SYSTEM_AUDIO_CAPTURE.md)。各阶段桌面对齐范围从[移动端指南](../mobile/README.md#专题与开发记录)进入。

专题中的阶段计划和当时通过数用于追溯，不覆盖 API 契约，也不能替代当前功能状态。

## 测试和历史记录

- [测试总入口](testing/README.md)：隔离环境、证据要求、跨客户端及服务端测试。
- [桌面专项检查](../frontend/TESTING.md)、[移动端专项检查](../mobile/TESTING.md)：各端命令及明确的验收边界。
- [可复用跨端 E2E](../tests/e2e/README.md)：测试方法及输入边界。运行结果写入本地 `.artifacts/`，内部截图、日志及历史验收档案不随源码分发。

## 文档维护约定

详细步骤集中在上表的维护入口，其他页面保留必要说明和链接。快速启动是例外：保留可独立执行的配置与启动命令，无需跳转即可完成首次运行；相关命令变化时同步更新快速启动。模块 README 只维护本模块的代码、数据及约束，不复制完整部署或公共 API 清单。测试总入口维护隔离与证据要求，各端 TESTING 维护检查命令，E2E 入口维护脚本参数。接口字段更新 `server/API.md`，当前验收边界更新 `feature-status.md`，逐次过程和日志写专题或历史记录。新增专题先更新本页或专题索引，不将测试日志继续追加到启动 README。

修改或移动文档时同步修改引用。修改后在仓库根运行 `node scripts/check-doc-links.mjs`。此命令只验证本地目标存在，不证明外部链接可访问或命令已执行。内部开发计划、历史报告、截图及日志保存在已忽略的本地目录，不新增到公开源码中。

## 只记录当前状态

启动、部署、架构、接口、配置、测试方法和功能说明只描述当前代码及其运行约束，不记录旧版本差异、升级前后对照、旧数据库搬迁或某轮执行统计。已实现的兼容接口仍属于当前契约，按接口现状说明。

法律文本、第三方包的 CHANGELOG 及保留的专题设计说明维持各自用途。内部过程记录、验收档案与本地历史资料不纳入公开源码；公开文档不依赖这些目录即可阅读和操作。
