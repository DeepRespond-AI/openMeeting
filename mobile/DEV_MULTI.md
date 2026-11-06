# Android 三客户端开发

先按 [后端启动说明](../quickstart.md) 启动开发网关。工具链按[移动端指南](README.md#环境准备与开发运行)准备；三开脚本另需 Node.js 24.15+（24.x）。在 Windows 安装 Android Studio，并在 Device Manager 安装一个 Android 模拟器（推荐已有的 Pixel_7）。然后在 `mobile/` 执行：

```powershell
dart run tool/init_app_config.dart --env dev --server-url http://10.0.2.2:39110 # 首次克隆后初始化本地配置
.\dev-multi.ps1
# PowerShell 执行策略限制时，使用等价的 Node 入口：
node dev-multi.mjs start
```

脚本从 Android 工程的 `local.properties`、环境变量或 PATH 查找 SDK。找不到时可以指定：

```powershell
.\dev-multi.ps1 -TemplateAvd Pixel_7 -FlutterSdk C:\tools\flutter
.\dev-multi.ps1 -ServerUrl http://10.0.2.2:39110
```

后端地址优先级为 `-ServerUrl`、环境变量 `OPENMEETING_SERVER_URL`、默认 `http://10.0.2.2:39110`。`10.0.2.2` 是 Android 模拟器访问宿主机的地址，不能填 `localhost`。脚本先探测网关，再用 `APP_ENV=dev` 构建一个共享 debug APK，随后启动三个模拟器和三个 Flutter 调试会话。

| 窗口 | 独立模拟器 | 登录数据 |
|---|---|---|
| DEV A | `OpenMeeting_DEV_A_<worktree标识>` | A 的 userdata / 安全存储 |
| DEV B | `OpenMeeting_DEV_B_<worktree标识>` | B 的 userdata / 安全存储 |
| DEV C | `OpenMeeting_DEV_C_<worktree标识>` | C 的 userdata / 安全存储 |

三个客户端分别登录不同测试账号，即可进入同一会议。使用同一个 applicationId `cn.deeprespond.meeting`，通过三个独立 Android 系统隔离数据。首次启动只复制模板的硬件配置，系统镜像共用 SDK，不复制模板的账号、userdata、快照或 SD 卡。三个开发模拟器各自持久化，停止后保留登录态；原有 Pixel_7 不受影响。不同 worktree 的模拟器名称不同。

新版模拟器的共享 Wi-Fi 会偶发无法访问 `10.0.2.2`。对这个宿主机地址，脚本自动为每个专用 AVD 设置 ADB reverse，把构建内的地址改为 `127.0.0.1` 的同一端口，HTTP 与 WebSocket 均通过该映射访问宿主机。状态中分别显示 `serverUrl`（输入）和 `runtimeServerUrl`（构建内地址）。Wi-Fi 保持开启，供 IM/RTC 的外部服务使用。脚本创建的映射在停止时移除；已有相同映射会复用，冲突映射报错并保留。使用局域网或远程地址时直接连接，不做映射。

```powershell
.\dev-multi.ps1 -Action status    # 查看三个客户端和日志目录
.\dev-multi.ps1 -Action reload    # 三个客户端统一热重载
.\dev-multi.ps1 -Action restart   # 三个客户端统一热重启
.\dev-multi.ps1 -Action stop      # 停止本脚本启动的客户端、模拟器；保留数据
.\dev-multi.ps1 -Rebuild          # 停止旧会话、重新构建和启动
.\dev-multi.ps1 -NoWatch          # 关闭文件监听，仅手动 reload
```

默认监听 `lib/` 和 `assets/`，按内容变化去重，保存后依次向三个 Flutter 会话发送热重载。修改 `main()` 初始化逻辑或 `assets/config/` 初始配置时使用 `restart`；原生插件、Android 配置、依赖和构建地址变化后使用 `-Rebuild`。修改 ARB/代码生成源文件仍需先按[测试与代码生成说明](TESTING.md)执行生成命令。编译错误会记录在日志，修正后再次 reload。重复启动会复用三个仍在运行的客户端；有会话丢失时重启开发环境并保留数据。

运行记录和日志位于根目录 `.artifacts/mobile-dev-multi/`，APK 在 `mobile/build/`，模拟器数据位于 `ANDROID_AVD_HOME`（默认 `%USERPROFILE%\.android\avd`）。这些本机产物不提交。三个模拟器各分配 2 GiB RAM、2 核，数据分区请求 4 GiB（系统镜像可能提高最低值，API 35 实测为 6 GiB，按需占用磁盘），建议至少有 8 GiB 可用内存和足够磁盘空间。首次构建需要下载 Android/Gradle 依赖；构建日志见 `build.log`。

模拟器使用 SwiftShader 软件图形并关闭 Vulkan，避免旧 Windows 显卡驱动在多实例初始化时崩溃。真实手机的渲染性能仍需另行验收。

脚本保留已运行的后端、ADB 服务和外部启动的模拟器。停止时核对 PID、创建时间、可执行文件和模拟器名称。启动失败保留日志并关闭本次启动的资源。停止或重建前，请先结束会议及录制。

Windows 开发终端的全局 HTTP 代理会干扰 Flutter 调试连接，脚本只在子进程中清除 `HTTP_PROXY` / `HTTPS_PROXY` / `ALL_PROXY`，保留 Pub 国内镜像和 `JAVA_TOOL_OPTIONS`。需要代理下载 Gradle 时在启动前自行设置 Java 的代理参数，不会修改全局配置或 Flutter SDK。

Gradle 使用 `.artifacts/mobile-dev-multi/gradle-home/` 中的独立配置，默认加上阿里云 Maven 镜像以避免本地 Google Maven TLS 错误；`-NoMirror` 可关闭。通过 Windows 目录联接复用原 Gradle 的 `caches/` 和 `wrapper/`，不重复下载或复制缓存，也不改写用户的 `~/.gradle/init.d`。

该脚本提供三客户端联调环境。三账号会议、双向音视频、权限拒绝和后台行为仍需分别实际操作验证；模拟器不能替代真机音画质量验收。当前入口支持 Windows 上的 Android 模拟器，iOS 需要 macOS。

三客户端的实际运行与系统界面需在目标设备验证；启动或端口连通不等于完整原生流程通过。
