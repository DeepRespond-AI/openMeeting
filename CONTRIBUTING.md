# 开发协作

Fork 仓库，从最新 `develop` 创建功能分支，修改后向本仓库 `develop` 提交 PR；`main` 用于经过验收的版本发布。较大改动先提交 Issue 协调范围，部署或生产发布单独执行。当前目录和职责见[项目结构](docs/project-structure.md)，启动见[快速启动](quickstart.md)。

## 变更约定

- HTTP、管理端或 Tauri 命令变更同步维护 [API 契约](server/API.md)及消费者。
- 文档遵循[维护入口约定](docs/README.md#文档维护约定)：详细步骤维护一份，其他页面引用；当前状态与逐次开发、历史验收记录分开。
- 业务目录统一 kebab-case；React 组件文件 PascalCase；hooks 使用 useX。
- 桌面界面遵循 [UI_design.md](frontend/UI_design.md)，用户文案维护双语键。
- 保留现有配置、数据库数据、路由、IPC 命令和存储键。目录调整与行为变更分开描述。
- 当前代码位于 frontend、server、mobile；本地可能保留的 legacy 历史档案不纳入 Git 跟踪，不作为开发入口。

## 验证及评审

按[测试说明](docs/testing/README.md)运行相关检查。PR/MR 描述写清问题、修改后的行为、验证和未覆盖范围。设备、平台、模型及生产包分别记录验收边界。

GitHub PR 会自动运行 [PR Checks](.github/workflows/pr-main-check.yml)，覆盖文档与配置、桌面类型/单元/媒体契约、Windows 构建脚本、管理端构建、后端隔离数据库测试及 Flutter 分析/测试。提交前按[自动检查说明](docs/continuous-integration.md)本地复现；合并前确认 `Quality Gate` 成功。维护者应按同页说明在 GitHub 启用必需状态检查，才能强制阻止失败 PR 合并。

可复用自动化放各端 tests 或根 tests/e2e；新运行结果与历史证据留在已忽略的本地目录。不要提交内部截图、日志、依赖、模型、构建缓存、用户录音或认证凭据。

## 外部贡献流程

1. 克隆自己的 Fork，添加本仓库为 upstream，更新本地 `develop` 后创建 `feat/<主题>` 或 `fix/<主题>` 分支。
2. 按快速启动生成自己的配置和密钥，不使用维护者凭据。PR 写清触发方式、修改后的行为与验证范围。
3. 本地验证后推送功能分支，创建目标为 `develop` 的 PR；首次 Fork PR 的 Actions 可能需要维护者批准。
4. 等待 `Quality Gate` 和人工评审，修复后追加提交，不为通过检查而跳过断言或隐藏失败。

普通问题见 [SUPPORT.md](SUPPORT.md)，漏洞走 [SECURITY.md](SECURITY.md)。仅使用虚构数据和脱敏日志，维护者不承诺固定响应时间。版本说明维护在 [CHANGELOG.md](CHANGELOG.md)，签名与发布见[发布指南](docs/releases.md)。
