# 桌面 API 接入入口

| 需要的信息 | 文档 |
|---|---|
| 登录、搜索、入会、异步任务和错误处理 | [API 中文接入指南](../server/API_GUIDE.md) |
| HTTP、管理端、字段和事件 | [API 契约](../server/API.md) |
| Next.js 调用原生命令 | [Tauri 命令契约](../server/API.md#tauri-api) |
| 开发启动与构建 | [桌面指南](README.md) |

Next.js 通过 Tauri invoke 与 Rust 通信，Rust 向业务网关发送 HTTP。Flutter 使用 HTTP 仓储及 IM/RTC SDK，不调用 Tauri 命令。命令名和 HTTP 路径不可混用。桌面本地负责采集和预处理音频，会议存储、转写及总结由服务端负责。
