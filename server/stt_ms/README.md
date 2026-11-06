# stt_ms（语音识别推理服务）

深应会议 微服务架构中的 **转写推理域**，端口 `39109`，数据库 `openmeeting_stt`（表：`stt_models`、`system_settings`）。
唯一携带 torch/whisper/funasr 重依赖的镜像；由网关（`gateway_ms`）转发 `/admin/api/stt/*`，业务请求来自 `meeting_ms` 的 internal API。

## 运行与配置

启动、依赖选择和数据库环境见[服务端指南](../README.md)，源码重载见[Docker 开发指南](../docker_dev.md)，GPU 要求与部署命令见[GPU 推理](../../docs/GPU_ACCELERATION.md)。本页维护推理域内部接口，不重复整套启动步骤。

## Internal API（供 meeting_ms 调用，需 `X-Internal-Token` 头）

| 方法 | 路径 | 说明 |
|---|---|---|
| POST | `/internal/transcribe?language=` | body 为原始音频（`X-Audio-Format: pcm16le`（默认）或 `wav`，16kHz 单声道），响应 `{"text","confidence","language"}` |
| GET | `/internal/status` | 当前引擎状态 + device |
| GET | `/internal/models` | 模型目录 |
| POST | `/internal/models/{id}/activate` | 激活模型 |
| GET | `/internal/engines` | 引擎可用性 |

## 配置

见 `.env.example`。配置键包括：`OPENMEETING_SECRET_KEY`（云端 API Key 加密）、`OPENMEETING_DATA_DIR`（模型存放于 `<data>/models/`）。

模型下载进度按目录大小估算，下载 SDK 使用网关出站代理；域名与 CDN 配置见[出站说明](../../docs/unified-egress.md#stt-模型下载的最小配置)。模型目录的备份是可选项，未备份时需重新下载并加载。当前引擎配置及实现见 [config.py](config.py) 和 [stt/](stt/)。
