# Android 签名密钥（深应会议 App）

本目录约定 Android App 开发版、测试版、正式版签名文件的本地位置。各环境的 `*.jks` 和 `key.properties` 只保存在本机或受控构建环境，已从 Git 跟踪中移除并加入忽略规则。

已有构建机继续使用原路径下的本地文件；新构建机应从凭据保管处恢复相应文件。公开仓库的独立发行版应生成自己的签名密钥。

> 取消跟踪不会删除历史提交中的密钥。公开发布时应使用不含这些密钥的新历史，或先清理旧历史；不要直接推送仍含密钥的旧分支或标签。
>
> 正式版签名密钥关系到现有用户的覆盖升级，不要为了停止 Git 跟踪而重新生成或替换它。

## 目录结构

```
keystores/
├── README.md
├── dev/
│   ├── meeting-dev.jks      # 开发版 keystore
│   └── key.properties       # 开发版密码 / 别名
├── test/
│   ├── meeting-test.jks     # 测试版 keystore
│   └── key.properties
└── prod/
    ├── meeting-prod.jks     # 正式版 keystore
    └── key.properties
```

密码和别名都在各自目录的 `key.properties` 里：

```properties
storePassword=<密码>
keyPassword=<密码，PKCS12 格式下与 storePassword 相同>
keyAlias=meeting-<env>
storeFile=../keystores/<env>/meeting-<env>.jks
```

`storeFile` 是相对于 `mobile/android/app/` 的路径，可以直接给 Gradle 用。

## 一条命令初始化

准备好 Flutter/Dart 和 JDK 后，在 `mobile/` 执行：

```powershell
dart run tool/init_android_keystores.dart
```

默认生成 dev/test/prod 三套独立的 RSA 4096 密钥，实际 keystore 格式为 PKCS12、证书有效期 10000 天。每个环境使用独立随机密码，同时生成可直接供当前 Gradle 构建读取的 `key.properties`，无需手动填写密码或路径。

只初始化某个环境，或指定自己的 JDK 和证书主体：

```powershell
dart run tool/init_android_keystores.dart --env prod
dart run tool/init_android_keystores.dart --env prod --keytool '<JDK目录>/bin/keytool.exe' --dname 'CN=My Meeting, O=My Company, C=CN'
```

脚本依次查找 `JAVA_HOME`、`STUDIO_JDK`、PATH 及常见 Android Studio JDK 位置；自定义安装位置可通过 `--keytool` 显式指定。使用 `flutter doctor -v` 可以查看 Flutter 实际使用的 JDK 路径。脚本只使用 Dart 标准库，不依赖 Node.js 或额外 Dart 包。

已有完整的 `.jks` 和 `key.properties` 会跳过且不修改；只存在其中一个时会拒绝初始化，避免混用新旧密钥。没有强制覆盖选项。所有选中环境生成并校验成功后才写入正式路径，失败会清理临时文件。

密码通过子进程环境变量传给 `keytool`，不会放进命令行参数或终端日志。生成的 `.jks` 和 `key.properties` 已被 Git 忽略；请在受控位置备份。脚本不修改 `APP_ENV`、网关地址或包名，也不负责构建 APK。已有发行版的构建机应恢复原密钥后继续使用，不能重新生成来替换已发布签名。

初始化完成后，按[移动端构建指南](../../README.md#构建)选择匹配的 `signingEnv` 构建。

## 手动生成签名密钥

本节仅适用于首次创建独立 Android 发行版；已有发行版应恢复原签名文件，保持覆盖升级所需的签名一致性。iOS 使用 Apple 的证书和描述文件，不使用这里的 Android keystore。

准备好 JDK 的 `keytool`，在 `mobile/` 中以 PowerShell 执行下面的 `prod` 示例。`dev`、`test` 分别替换目录名、文件名及别名，各环境独立生成一次：

```powershell
New-Item -ItemType Directory -Force android/keystores/prod | Out-Null
if (Test-Path android/keystores/prod/meeting-prod.jks) { throw '签名文件已存在，请使用原密钥，不要覆盖' }
keytool -genkeypair -v -storetype PKCS12 -keystore android/keystores/prod/meeting-prod.jks -alias meeting-prod -keyalg RSA -keysize 4096 -validity 10000
```

按交互提示设置密码并填写证书主体信息，不将真实密码写进命令行。若找不到 `keytool`，运行 `flutter doctor -v` 查看 JDK 路径，使用同一 JDK 的 `bin/keytool`；Windows 的绝对路径命令形式为 `& '你的JDK目录/bin/keytool.exe' ...`。

生成的 `.jks` 实际是 PKCS12 格式，内部同时包含私钥和配套的公钥证书。随后在 `android/keystores/prod/key.properties` 本地创建：

```properties
storePassword=<刚才设置的密码>
keyPassword=<同一个密码>
keyAlias=meeting-prod
storeFile=../keystores/prod/meeting-prod.jks
```

替换密码占位符，不保留尖括号；PKCS12 使用同一个存储和私钥密码。该文件和 `.jks` 均已被 Git 忽略。按下方命令查看证书指纹，再按[移动端构建指南](../../README.md#构建)选择匹配的 `signingEnv` 构建。

Android 不需要单独的 `.pub` 文件：签名证书会随 APK 分发，系统使用证书中的公钥验证签名和更新身份。如需向第三方平台提供公钥证书，可在 `mobile/` 导出不含私钥的副本：

```powershell
keytool -exportcert -rfc -keystore android/keystores/prod/meeting-prod.jks -alias meeting-prod -file android/keystores/prod/meeting-prod.cert.pem
```

公钥证书和指纹可以公开，通常无需为构建单独跟踪导出的证书文件。密钥生成和本地密码文件说明另见 [Flutter 官方 Android 签名指南](https://docs.flutter.dev/deployment/android#sign-the-app)。

## 密钥信息

以下参数和指纹记录现有官方发行版的三份密钥；自行生成的密钥应以自己的 `keytool` 输出为准：

| 项目 | 值 |
| --- | --- |
| 格式 | PKCS12（`.jks` 后缀） |
| 算法 | RSA 4096 |
| 有效期 | 10000 天，2026-10-07 生成，**2054-02-22 到期** |
| 证书主体 | `CN=DeepRespond Meeting <Dev/Test/Release>, OU=Mobile, O=DeepRespond, L=Beijing, ST=Beijing, C=CN` |
| applicationId | `cn.deeprespond.meeting` |

### 开发版 `dev/`

- 别名：`meeting-dev`
- 用途：日常开发、内部调试包
- MD5：`38:6C:CC:7A:5E:00:69:B5:A4:12:55:36:23:ED:5E:16`
- SHA1：`FA:64:6E:6B:26:87:73:77:F6:72:0A:8B:14:A5:A9:01:25:94:9D:1F`
- SHA256：`88:E4:10:03:DF:CE:64:62:02:3D:E0:DF:77:78:6C:83:40:EB:D6:4F:9B:3A:5E:89:E4:A2:B6:44:49:7D:4A:39`

### 测试版 `test/`

- 别名：`meeting-test`
- 用途：发给测试同事 / 内测用户的包
- MD5：`DE:D5:59:CA:AF:AC:2D:40:25:7B:10:3F:BC:A3:9D:71`
- SHA1：`E4:EF:27:22:DF:AC:D7:6A:51:E0:6E:66:C1:5D:FA:3A:6F:11:96:7F`
- SHA256：`DE:43:A2:7C:66:0A:CF:A7:1F:B2:A6:16:DE:BD:35:1C:30:61:50:38:7D:24:41:09:51:78:CA:AD:6F:D7:30:0A`

### 正式版 `prod/`

- 别名：`meeting-prod`
- 用途：应用市场上架、正式发布。**这份最重要，丢了就无法更新线上 App**
- MD5：`63:F5:6D:C6:E8:C2:A1:AD:BE:3F:96:A2:5B:4A:D9:A8`
- SHA1：`26:CF:E4:03:7E:1A:F7:BB:CA:D2:09:AB:3D:95:C4:B0:B1:82:BB:F2`
- SHA256：`1E:AB:1D:4F:89:4D:8D:BF:1F:FF:17:39:15:95:98:87:1F:2E:18:F8:75:B6:9F:69:B4:C1:3C:87:1A:55:C3:A3`

> 微信开放平台、部分国内应用市场要求填写「应用签名」，格式是 **MD5 去掉冒号、全小写**。
> 例如正式版应填 `63f56dc6e8c2a1adbe3f96a25b4ad9a8`。
> 高德/百度地图、Firebase 等 SDK 一般要求填 SHA1 或 SHA256。

## 使用方法

[build.gradle.kts](../app/build.gradle.kts) 从 `keystores/<signingEnv>/key.properties` 读取配置；`signingEnv` 默认 `prod`。缺少该文件时 release 构建直接报错并提示初始化或恢复密钥；debug 构建继续使用调试签名。发布前仍需检查实际 APK 证书。

各环境打包命令统一见[移动端构建](../../README.md#构建)。`APP_ENV` 控制应用配置，`signingEnv` 控制签名，二者独立；本页只维护密钥、证书指纹和校验方法，不复制 Gradle 实现。

### 查看 / 校验密钥

本机没有装 Java 时，用 Android Studio 自带的 keytool：

```bash
KT="/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/keytool"
"$KT" -list -v -keystore mobile/android/keystores/prod/meeting-prod.jks -alias meeting-prod
# 按提示输入 prod/key.properties 里的 storePassword
```

校验已打好的 APK 用的是哪个签名：

```bash
$ANDROID_HOME/build-tools/<版本>/apksigner verify --print-certs app-release.apk
# 用输出里的 SHA-256 和上面的指纹对比
```

## 注意事项

- 同一个 `applicationId` 的 App，签名不同就**不能覆盖安装**。从开发包换成测试包或正式包前，要先卸载旧包。
- 正式版密钥及密码应备份在密码管理器或加密离线介质中，不以源码仓库作为凭据备份。
- 如果启用 Google Play App Signing，上传的 `prod` 密钥只是「上传密钥」，Google 会用自己的应用签名密钥重新签名；
  这种情况下，第三方 SDK 要填 Play Console 里显示的应用签名指纹。
- `mobile/android/.gitignore` 会忽略所有 `*.jks`、`*.keystore` 和 `key.properties`，包括本目录下的文件。
