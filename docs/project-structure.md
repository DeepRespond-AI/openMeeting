# 项目结构与目录约定

## 当前布局

```text
openmeeting/
├── frontend/                 桌面客户端
│   ├── src/app/              Next.js 路由及页面组合
│   ├── src/components/       按业务组织的 UI 与通用 ui 原语
│   ├── src/services/         业务服务及真实/mock 适配
│   ├── src/hooks/            可复用 hooks
│   ├── src/contexts/         跨组件状态
│   ├── src/im/               IM 引擎和工作台接入
│   ├── src/i18n/             双语文案
│   ├── src-tauri/            原生命令、设备与服务端通信
│   └── tests/                hooks、lib、contracts 回归
├── server/
│   ├── gateway_ms/           对外网关与管理端静态页面
│   ├── user_ms/              用户、鉴权、短信、版本及 IM
│   ├── meeting_ms/           会议、房间、录音、任务及总结
│   ├── stt_ms/               语音识别及模型管理
│   ├── service_net/          共享的网关出站 HTTP / SDK 代理配置
│   ├── admin-web/            Vue 管理端源码
│   └── tests/                跨服务集成测试
├── mobile/                   Flutter 客户端及自身测试
├── tests/e2e/                可复用跨客户端回归、输入夹具
├── docs/
│   ├── README.md             文档总导航与维护职责
│   └── testing/              测试入口、隔离及验收说明
├── scripts/                  仓库级发布、链接检查及维护工具
│   └── build_scripts/        服务端 Linux 离线部署包的 PowerShell 打包脚本
├── Cargo.toml                桌面 Rust 工作区入口
├── quickstart.md             当前启动入口
└── README.md                 项目导航
```

依赖、缓存、data、target、worktrees 和 `.artifacts` 是本地目录，不构成新的业务模块。`worktrees/` 保留本地内容并忽略提交；后续可直接在仓库外创建工作树。已有工作区中的 `legacy/` 历史档案仅在本地保留，已取消 Git 跟踪，新克隆不包含该目录。

## 目录职责与命名

项目技术标识统一使用 `openmeeting`，环境变量前缀使用 `OPENMEETING_`。桌面应用标识为 `com.openmeeting.ai`；IM 会议通知和邀请分别使用 `openmeeting.meeting`、`openmeeting.invitation`。桌面端、移动端和服务端使用相同的消息契约。

Docker Compose 项目名为 `openmeeting-split`，默认数据库为 `openmeeting_user`、`openmeeting_meeting`、`openmeeting_stt`。应用标识及 Compose 项目名决定配置目录和资源命名，现有数据不会随标识变化自动复制到新目录或数据卷。构建和部署前，核对实际环境文件与当前模板的变量名一致，并明确数据库、卷及存储位置。

- 业务目录使用 kebab-case，例如 `meeting-details`、`live-meeting`、`ai-summary`。React 组件文件使用 PascalCase，hooks 使用 useX；沿用既有 Rust/Python 命名规范。
- 页面入口负责路由和组合；业务 UI 放 `components/<业务>/`；业务请求、适配和媒体逻辑放 `services/<业务>/`。共享 hooks、状态和类型按实际复用范围保留。
- 已有根级组件按后续实际业务变更逐步归入业务目录，新增业务组件不再继续堆入根级。不要为目录对称新增无职责的空层。
- 组件目录与消息命名空间是不同概念；目录命名不改变 `liveMeeting.*` 等翻译键、函数名、浏览器存储键、API、Tauri 命令或路由。
- 单服务测试就近放 `<service>/tests/`，前端测试放 `frontend/tests/`；跨客户端脚本统一放 `tests/e2e/`。历史阶段快照不加入默认测试发现路径。

## 常见功能定位

| 功能 | UI / 客户端逻辑 | 服务端 |
|---|---|---|
| 预定、入会、房间 | `frontend/src/components/live-meeting/`、`src/services/live-meeting/` | `meeting_ms/api/v1/` |
| 录音上传及共享 | `src/services/live-meeting/recording.ts`、`media/` | `meeting_ms/api/v1/recording.py`、`screen_share.py` |
| 会议详情、播放、转写和纪要 | `src/components/meeting-details/`、`ai-summary/` | `meeting_ms/jobs/`、`summary/`、`storage/` |
| 独立录音与设备 | `src-tauri/src/audio/` | `meeting_ms`、`stt_ms` |
| IM 工作台 | `src/components/im/`、`src/im/` | `user_ms`、平台 SDK |
| 管理端 | `server/admin-web/src/` | 网关转发至对应业务服务 |

当前启动见[快速启动](../quickstart.md)，部署见[服务端说明](../server/README.md)，构建与签名见[桌面指南](../frontend/README.md)和[移动端指南](../mobile/README.md)，测试见[测试说明](testing/README.md)。

Markdown 的阅读顺序和各入口的维护职责见[文档导航](README.md)。内部开发计划和历史测试证据只在本地保留，不随源码分发。目录表说明代码位置，不重复各端完整操作步骤。
