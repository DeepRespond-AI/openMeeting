# 后端日常开发：Docker 自动重载与更新

本文只维护 Docker 开发编排、代码更新和重启选择。首次配置见[快速启动](../quickstart.md)，常规部署、完整环境变量与裸机启动见[服务端指南](README.md)。桌面启动、构建与发布见[桌面指南](../frontend/README.md)。

使用 `docker-compose.dev.yml` 叠加默认编排：各服务源码只读挂载到容器，Uvicorn 监听对应服务目录内的 Python 文件。保存代码会重启该服务的 Python 进程，容器及 PostgreSQL 不随每次代码编辑重启。

## 启用

先按[快速启动](../quickstart.md)准备 `server/.env`。
在 `server/` 执行：

```bash
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d
```

首次缺少镜像时 Compose 会构建；代码已改但 Python 依赖未变，可以复用已有镜像。需要明确重新构建时加 `--build`。切换到开发编排会一次性重新创建受影响服务容器，以启用挂载与重载器。

后续直接修改 `gateway_ms/`、`user_ms/`、`meeting_ms/` 或 `stt_ms/` 的 `.py` 文件即可。每个服务只监听自己的源码目录，模型和录音数据不在监听范围内。开发配置开启 watchfiles 轮询，兼容 Windows/Docker Desktop 文件挂载。

```bash
docker compose -f docker-compose.yml -f docker-compose.dev.yml logs -f meeting_ms
```

看到 `WatchFiles detected changes`、`Started server process` 和 `Application startup complete` 即完成一次自动重载。Docker 服务或 Docker Desktop 本身无需重启。

## 哪些修改需要额外操作

| 修改 | 操作 |
|---|---|
| 已安装依赖范围内的 Python 业务代码 | 保存文件，自动重载对应服务 |
| requirements.txt、Dockerfile、系统依赖或 SDK 版本 | 对相应服务执行 `up -d --build --no-deps <服务>`，使用相同的两个 `-f` 参数 |
| .env 中由 Compose 传入的环境变量或编排配置 | 再执行相同开发 `up -d` 命令，让 Compose 更新容器配置 |
| 数据库结构/迁移 | 按现有 Alembic 流程升级；应用启动、自动重载仍会执行已启用的启动迁移，热更新不能替代结构变更 |
| STT 模型、LLM 等管理端配置 | 使用管理端运行配置；修改 stt_ms 源码会重载推理进程和模型，可能较慢 |

重载会短暂中断请求和 WS，也可能中断正在处理的任务。会议断线恢复不代表录制无损；测试活跃会议时应区分代码重载与网络故障。

开发编排将旧进程的退出等待限制为 5 秒，避免 SSE、长请求等连接让热重载永久停在 `Waiting for connections to close`。超过等待时间的请求会中断，由客户端重连或重试。修改此编排配置后需再次执行相同的 `up -d` 命令，后续 Python 修改仍自动重载。

## 数据库结构开发

在 `server/` 执行，先通过 `OPENMEETING_DATABASE_URL` 指向与目标服务匹配的隔离开发库。以 meeting_ms 为例：

```powershell
uv run alembic -c meeting_ms/alembic.ini revision --autogenerate -m '<变更说明>' # 根据模型生成新迁移，替换说明并人工检查脚本
uv run alembic -c meeting_ms/alembic.ini upgrade head # 仅在指定的隔离开发库验证迁移
uv run alembic -c meeting_ms/alembic.ini check # 验证升级后的库与模型一致
```

其他服务使用自己的 Alembic 配置和数据库。不要把模型变化仅依赖热重载或 `create_all` 应用；迁移脚本与模型一并提交。正式环境启动迁移、发布前备份及回退按[运维指南](OPERATIONS.md#发布更新与回退)执行。

## 本地端口覆盖与 GPU

显式使用 `-f` 时，不会自动附加本机 `docker-compose.override.yml`。如果需要其中的微服务端口映射，并且该文件存在，执行：

```bash
docker compose -f docker-compose.yml -f docker-compose.override.yml -f docker-compose.dev.yml up -d
```

没有本地覆盖文件时使用基本的两个 `-f` 命令，网关仍通过 39110 访问。GPU 开发使用：

```bash
docker compose -f docker-compose.yml -f docker-compose.gpu.yml -f docker-compose.dev.yml up -d --build
```

同一轮开发保持相同的 Compose 文件组合，不需要执行 `down`，也不需要删除任何数据卷。

## 前端与管理端

- 桌面启动、热更新和重新构建按[桌面指南](../frontend/README.md)执行。
- 管理端开发命令与静态构建按[管理端指南](admin-web/README.md#构建)执行。开发编排挂载网关源码后会覆盖镜像内的静态管理端目录；若要从 39110 访问静态管理页，需先在宿主机生成 `gateway_ms/static/admin/`。这一静态目录本身不提供 Vue HMR。

## 切回常规运行

在 `server/` 执行 `docker compose -f docker-compose.yml up -d --build`，需要本机端口覆盖时再显式加对应文件。Compose 会按配置重新创建服务，不挂载开发源码。常规部署不附加 dev 文件。

机制参考：[Uvicorn 重载设置](https://www.uvicorn.org/settings/)、[Compose 文件合并规则](https://docs.docker.com/compose/how-tos/multiple-compose-files/merge/)。

当前运行的 Compose 文件组合通过 `docker compose ls` 查看，服务状态通过 `docker compose ps` 查看。
