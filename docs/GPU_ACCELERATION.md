# 服务端 GPU 推理

当前桌面端不运行 STT 模型，语音识别引擎位于 `server/stt_ms/stt/`。GPU 是服务端部署选项。

在 `server/` 执行：

```bash
docker compose -f docker-compose.yml -f docker-compose.gpu.yml up -d --build
```

该编排仅为 stt_ms 配置 GPU，宿主机需要 NVIDIA 驱动及 NVIDIA Container Toolkit。模型仍需在 `http://<网关>:39110/admin` 下载、启用；检查容器日志及管理端就绪状态。

具体配置以 [docker-compose.gpu.yml](../server/docker-compose.gpu.yml)及[服务端说明](../server/README.md)为准。
