# aac_writer

项目内的 PCM16 → AAC-LC `.m4a` 流式编码插件，Android 使用 MediaCodec/MediaMuxer，iOS 使用 AVAudioFile。它负责写文件，不负责采集、VAD、上传或服务端转写。

[NativeAacWriter](lib/aac_writer.dart) 按 `open → write → close` 使用；调用串行执行，等待 `write` 或 `pending` 可施加背压，`close` 排空编码器并完成文件。采样率、声道和码率由调用方提供，不在本页重复应用配置。

应用架构与配置见[移动端开发指南](../../DEVELOPMENT.md)，系统声音与麦克风的采集流程见[内录说明](../../SYSTEM_AUDIO_CAPTURE.md)。Android/iOS 的实际编码与文件可播放性需分别在原生平台验证。
