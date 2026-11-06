# 桌面端测试

在 `frontend/` 执行命令，另有注明的除外。环境、隔离数据库、跨端脚本和历史证据见[测试总入口](../docs/testing/README.md)。开发与发布操作见[桌面指南](README.md)。

## 类型、单元与故障契约

提交前按改动范围执行检查：

GitHub PR 使用 Node.js 24、Bun 1.3.14 和锁定依赖运行 `pnpm test:ci`，统一执行类型、单元、媒体契约和 updater 初始化检查。Windows 环境加载与日志脱敏由独立作业运行 `pnpm test:build-logs`。完整范围及失败复现见[持续集成](../docs/continuous-integration.md)。

```powershell
pnpm exec tsc --noEmit # 检查 TypeScript 类型，不生成编译文件
pnpm test:unit # 使用 Bun 按文件隔离运行前端单元测试
pnpm test:recording # 验证录音行为及故障恢复契约，使用注入故障
pnpm test:audio # 音频设备与当前轨道替换契约
pnpm test:camera # 摄像头关闭、重开及预览轨道契约
pnpm test:screen # 屏幕共享发布、停止、归属及迟到采集清理契约
```

`test:unit` 需要 Bun，并按文件隔离进程；可用 `OPENMEETING_BUN_BIN` 指定 Bun 可执行文件。真实跨端流程见 [E2E 说明](../tests/e2e/README.md)，已有记录见本地验收记录（不随源码分发）。

昵称保存后被心跳旧资料覆盖的回归：从仓库根运行 `cargo test --lib server::heartbeat::tests`，从 `frontend/` 运行 `bun test tests/hooks/server-session.test.tsx`。Rust 测试使用本机随机端口 HTTP 夹具验证账号资料冲突及过期心跳结果，不依赖真实账号或业务数据库。该修复位于 Rust 原生层，需重新构建桌面客户端后生效。

## 音频补丁与会议通知

从 `frontend/` 执行；媒体补丁重启与兼容范围见[补丁说明](patches/README.md)。

```powershell
node tests/contracts/meeting-audio-ui.mjs # 音频菜单/错误和设备切换的界面契约
node tests/contracts/meeting-audio-bundle.mjs http://localhost:3118 # 检查实际开发服务交付的 SDK 模块
node tests/contracts/meeting-notifications.mjs # 会议群提醒筛选、声音与角标策略的边界夹具
```

通知后端契约在 `server/` 执行 `uv run pytest tests/test_meeting_im_contract.py -q`，不连接数据库或真实 IM。原生系统通知的人工检查见[通知验证](src-tauri/NOTIFICATION_TESTING.md)，不能把 SDK/native 替身当作 OS 权限、声音或任务栏验收。

## 本地输出与验收

RTC 旧会话恢复专项在独立进程执行，避免模块替身相互影响：

```powershell
bun test tests/lib/rtc-recovery.test.ts # 验证释放确认、轮询截止时间与取消
bun test tests/hooks/room-media-recovery.test.tsx # 验证真实 RoomProvider 保留业务房间和聊天
pnpm test:resilience # 验证媒体适配器与 SDK 会话的恢复边界
```

这些测试不操作真实平台会话；恢复接口约束及部署要求见[当前功能与限制](../docs/feature-status.md)。

本地结果及历史证据保存在已忽略的本地目录，不随公开源码分发。真实 IM/RTC、原生设备和生产安装包分别验收，不能用 IPC/SDK 夹具替代。后端数据库测试从[测试总入口](../docs/testing/README.md)选择，避免指向日常业务库。
