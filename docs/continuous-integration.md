# PR 自动检查与合并门槛

[PR Checks](../.github/workflows/pr-main-check.yml) 在创建或更新 PR、向 `main` / `develop` 推送、进入合并队列时自动运行，也支持在 Actions 中手动运行。PR 不限制目标分支，也不按文件路径跳过检查，文档修改同样会生成完整的检查结果。

## 检查范围

| 检查 | 内容 |
|---|---|
| Configuration and documentation | 桌面 `package.json`、Tauri 配置与 Cargo 版本一致；文档本地链接有效；部署和开发 Compose 配置可解析 |
| Desktop checks | TypeScript 类型、Bun 单元测试、录音/音频/摄像头/共享/聊天/入会/通知及恢复契约；生成临时 updater 密钥并验证真实签名 |
| Windows build scripts | 在 Windows 上执行 PowerShell 环境变量加载、错误处理与日志脱敏测试 |
| Windows native compile | 编译实际 Rust 插件、Tauri 权限和原生依赖，并验证统计默认关闭、目标主机和敏感属性过滤 |
| Admin checks | Vue TypeScript 检查与 Vite 生产构建 |
| Backend (user_ms / meeting_ms / stt_ms / gateway_ms / contracts) | 五个独立作业运行对应 pytest；各作业使用自己的临时 PostgreSQL 16，失败时其他作业继续执行；JUnit 报告保留 7 天 |
| Mobile checks | Flutter 锁定依赖安装；生成临时应用配置；Dart 静态分析与完整 `flutter test`；编译 Android arm64 debug APK，不使用正式签名密钥 |
| Production images and deployment smoke | 构建实际生产镜像，使用隔离数据库及随机端口，验证基础注册、鉴权、版本发布、真实签名和浏览器下载；另构建默认 CPU 镜像并离线加载推理依赖；MinIO 另行选择 |
| Quality Gate | 汇总全部检查作业；任一作业失败、取消或跳过均返回失败，只有全部作业成功才通过 |

当前工具链为 Node.js 24（本地使用 24.15+ 的 24.x，满足锁定的 IM SDK 与 jsdom 要求）、桌面 pnpm 12.14.0、Bun 1.3.14、管理端 pnpm 10.6.5（与网关 Dockerfile 一致）、Python 3.11 / uv 0.13.3、Flutter 3.47.7 / Dart 3.13.5、JDK 17。桌面原生编译另需 Rust 1.90+，见[桌面指南](../frontend/README.md)。升级工具链时同步更新工作流，并验证锁文件及相关测试。

Fork PR 使用 `pull_request` 事件和只读仓库权限，不需要维护者的签名、短信、OSS、IM 或模型服务凭据。生成的配置使用示例地址，密钥仅用于临时测试。首次参与的外部贡献者可能需要维护者在 GitHub 批准工作流运行，具体取决于仓库的 Actions 设置。

## 配置 GitHub 合并门槛

自动检查结果需要配合仓库规则，才能在失败时阻止合并。由具有管理仓库规则权限的维护者操作：

1. 将工作流推送到 GitHub 并至少完成一次运行，让 GitHub 识别检查名称。
2. 在 **Settings → Rules → Rulesets** 创建分支规则（也可使用 **Settings → Branches** 的分支保护），覆盖 `main`；若 `develop` 用于集成，也为它配置规则。
3. 启用 **Require a pull request before merging** 和 **Require status checks to pass**，选择 **Quality Gate**，检查来源选择 GitHub Actions。
4. 按团队要求启用分支保持最新和限制绕过规则；先确认测试 PR 能运行，并且检查失败时确实禁止合并。

只需把固定名称 `Quality Gate` 设为必需检查，无需逐个添加矩阵作业。不要为此工作流添加路径过滤或把汇总条件改成仅在成功时运行，否则可能出现检查一直等待或失败未正确汇总。

GitHub 的状态检查与权限说明见[分支保护文档](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches#require-status-checks-before-merging)。本工作流只在 GitHub Actions 中运行，GitLab MR 的检查需另行配置 GitLab CI。

## 本地复现与失败处理

在仓库根执行 `node scripts/ci/check-versions.mjs` 和 `node scripts/check-doc-links.mjs`。桌面在 `frontend/` 安装锁定依赖后执行 `pnpm test:ci`；Windows 日志测试执行 `pnpm test:build-logs`。管理端在 `server/admin-web/` 执行 `pnpm build`。

后端使用[测试数据库说明](testing/README.md#后端测试数据库)中的专用库，在独立进程中分别执行各服务测试和 `uv run --locked pytest tests -q`。不要对日常业务库运行测试，夹具会清空测试表。移动端在生成本地应用配置后运行 `dart analyze --fatal-infos`、`flutter test --no-pub`；完整准备见[移动测试](../mobile/TESTING.md)。

CI 使用干净工作区。部分移动 UI 验收用例读取本地 `.artifacts/` 中的累计执行预算，本机重复运行时需按对应 E2E 脚本开启新一轮输出，避免沿用旧轮次的过期预算。

在 PR 的 **Checks** 页面查看失败作业和日志，后端可下载对应 `pytest-<suite>` 报告。修复后推送提交会重新检查；同一 PR 的旧运行会自动取消。安装失败、依赖不可用或静态分析失败都不会被转换为通过。

这组检查包含 Windows Rust 编译、Android debug APK 编译、静态构建和隔离测试。实际安装、真实 IM/RTC、语音模型、短信、OSS 和 Android/iOS 真机仍按[测试说明](testing/README.md)单独验收；完整发包见[发布指南](releases.md)。
