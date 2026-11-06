# Android 模拟器与真机开发指南

本文说明如何启动 Android 模拟器、连接 USB/Wi-Fi 真机、使用 Flutter 热重载，以及安装已构建的 APK。命令在 PowerShell 中执行；除非另有说明，先进入仓库的 `mobile` 目录。执行前将尖括号占位符替换为当前设备、地址或 APK 路径，保留引号。

## 首次环境准备

使用[移动端指南](README.md#环境准备与开发运行)中的 Flutter / Dart 和 JDK 版本，安装 Android SDK（含 Platform-Tools 和 Emulator），并接受 Android SDK licenses：

```powershell
flutter doctor
flutter doctor --android-licenses
```

首次克隆后在 `mobile/` 安装依赖并生成本地 dev 配置，之后再启动模拟器或真机应用：

```powershell
flutter pub get
dart run tool/init_app_config.dart --env dev --server-url http://10.0.2.2:39110
```

`assets/config/` 不随仓库分发。上面的地址用于 Android 模拟器访问宿主机；真机使用实际可访问的网关，或使用下文的 `OPENMEETING_SERVER_URL` 构建覆盖。已有配置不会被脚本覆盖，完整环境初始化见[移动端构建准备](README.md#构建)。

完整录音直传和音频下载还需要对象存储地址可达。多人跨设备联调时，后端 `server/.env` 的 `OPENMEETING_MINIO_PUBLIC_ENDPOINT` 应设为所有设备可达的局域网地址，例如 `http://<开发电脑局域网IP>:39120`；服务端内部 `OPENMEETING_MINIO_ENDPOINT` 不变。只有业务网关可达时仍可能上传、下载失败；配置生效和签名约束见[对象存储联调地址](../docs/object-storage.md#客户端联调地址)。

首次创建或配置 Android 虚拟设备时，建议使用 Android Studio 的 Device Manager。配置完成后，日常启动模拟器、构建和调试都可以通过命令行完成，不必每次打开 Android Studio。

## Android 模拟器

查看可用的 AVD，并按列表中的 ID 启动：

```powershell
flutter emulators
flutter emulators --launch Pixel_7
flutter devices
```

`flutter emulators` 显示的是 AVD 名称（如 `Pixel_7`）；启动后，`flutter devices` 或 `adb devices` 显示的是运行设备 ID（如 `emulator-5582`）。将实际设备 ID 用于 `-d`：

```powershell
flutter run -d emulator-5582 --dart-define=APP_ENV=dev
```

模拟器开发配置默认访问 `http://10.0.2.2:39110`，其中 `10.0.2.2` 是 Android 模拟器访问宿主机的特殊地址。若后端不在运行 Flutter 的这台电脑上，需覆盖为模拟器可访问的地址：

```powershell
flutter run -d emulator-5582 --dart-define=APP_ENV=dev --dart-define=OPENMEETING_SERVER_URL=http://<后端可访问地址>:39110
```

## USB 真机开发与热重载

1. 在手机/平板开发者选项中打开 USB 调试，使用支持数据传输的 USB 线连接电脑，并在设备上确认 USB 调试授权。
2. 查看设备状态：

```powershell
adb devices -l
flutter devices
```

若设备显示 `offline`，先解锁设备并确认授权提示；可拔插数据线后重试。仍不行时，在设备上撤销 USB 调试授权、重新插线并再次授权。若有多台设备，始终通过 `-s <设备ID>` 或 Flutter 的 `-d <设备ID>` 指定目标。

3. 选择一种后端连接方式。

同一局域网下，设备和后端主机应互相可达，防火墙需允许后端端口。将 `<后端局域网IP>` 替换为实际地址：

```powershell
flutter run -d '<设备ID>' --dart-define=APP_ENV=dev --dart-define=OPENMEETING_SERVER_URL=http://<后端局域网IP>:39110
```

如果后端运行在连接 USB 的开发电脑上，也可用 ADB 反向端口映射：

```powershell
adb -s '<设备ID>' reverse tcp:39110 tcp:39110
adb -s '<设备ID>' reverse tcp:39120 tcp:39120 # 使用默认 localhost:39120 MinIO 签名入口时需要
flutter run -d '<设备ID>' --dart-define=APP_ENV=dev --dart-define=OPENMEETING_SERVER_URL=http://127.0.0.1:39110
```

两条 `adb reverse` 分别转发业务网关和 MinIO 文件入口。后一条仅适用于服务端签发的地址为 `localhost:39120` / `127.0.0.1:39120`、MinIO 运行在该开发电脑上的情况；使用局域网入口或远程对象存储时，设备直接访问对应地址。模拟器沿用默认 MinIO 签名地址时也需映射 39120。后端必须正在电脑上监听相应端口。设备重启、USB/ADB 断开后，重新执行所需映射。

保持 `flutter run` 进程运行即可调试：终端按 `r` 对 Dart 代码热重载，按 `R` 热重启，按 `q` 退出。原生 Android、Gradle 或插件代码变更通常需要停止并重新运行 `flutter run`，部分变更还需要重新构建/安装。

## Wi-Fi ADB 无线调试

Wi-Fi 调试有两种常见方式，端口取决于 Android 版本和设备设置；不要默认假设设备地址一定是 `:5555`。

### Android 11 及以上：无线调试配对

电脑和设备连接同一 Wi-Fi。在设备的“开发者选项 → 无线调试”中选择“使用配对码配对设备”，按屏幕显示的地址和配对端口执行：

```powershell
adb pair '<设备IP>:<配对端口>' # 替换为无线调试页面显示的配对地址
```

输入设备上显示的配对码。配对成功后，回到无线调试页面查看“IP 地址和端口”，再连接该连接端口：

```powershell
adb connect '<设备IP>:<连接端口>' # 使用连接端口，可能与配对端口不同
adb devices
```

配对端口和连接端口可能不同，使用页面显示的值。之后 `flutter devices` 会列出无线设备，可用其设备 ID 执行 `flutter run`。

### USB 授权后切换到传统 TCP/IP 调试

适用于设备支持该模式且能先通过 USB 授权的场景。USB 连接并确认 `adb devices` 状态为 `device` 后执行：

```powershell
adb -s '<设备ID>' tcpip 5555
adb connect '<设备当前IP>:5555' # 替换为当前设备地址
adb devices
```

连接成功后可拔掉 USB。设备重启或 ADB TCP/IP 服务停止后，通常需要重新 USB 连接并执行 `adb tcpip 5555`。若提示连接被拒绝，确认设备和电脑在同一网络、IP 未变化，并且设备仍在监听该端口；Android 11 及以上也可使用前述“无线调试”方式。

## 安装已构建的 APK

先确认设备已连接且状态为 `device`，再安装 APK。以下示例使用 USB 设备序列号；若使用 Wi-Fi ADB，把 `-s` 后的值换成 `adb devices` 列出的 `<设备IP>:<端口>`：

```powershell
adb devices
adb -s '<设备ID>' install -r '<APK绝对路径>'
```

`-r` 表示覆盖安装并保留应用数据，但要求包名和签名证书一致，且新 APK 的 Android `versionCode` 不能低于已安装版本。项目的版本和 build number 位于 `mobile/pubspec.yaml`，例如 `1.0.0+5` 中 `5` 是 Android versionCode。遇到 `INSTALL_FAILED_VERSION_DOWNGRADE`，提高 build number 后重新构建；若必须安装低版本，只能先卸载旧应用再安装（应用本地数据会被清除）。

开发安装包的构建命令和封装脚本统一见[移动端构建](README.md#开发版)。`flutter run` 安装的通常是 debug 签名包；它可能无法直接被 dev 签名的 release APK 覆盖。若提示签名不匹配，需卸载旧包后重装，或始终使用同一种签名构建。

## 常用排查

```powershell
adb kill-server
adb start-server
adb devices -l
flutter devices
```

重启 ADB 后若 USB 设备变为 `offline`，解锁设备并检查/重新确认 USB 调试授权，必要时拔插数据线。`adb kill-server` 会断开当前所有 ADB 连接；Wi-Fi 设备需要重新 `adb connect`，USB 反向映射也要重新执行。模拟器访问本机服务使用 `10.0.2.2`；真机不能直接使用该模拟器专用地址，应使用局域网地址或 `adb reverse`。
