# app_installer

仅支持 Android 的应用内更新辅助插件，用于 `direct`（非应用商店）渠道：

- `canInstallPackages()`：检查用户是否允许本应用安装软件包（Android 8+）。
- `openInstallSettings()`：打开本应用的“安装未知应用”设置。
- `installApk(path)`：将已下载到应用缓存目录的 APK 交给系统安装程序。

清单文件声明 `REQUEST_INSTALL_PACKAGES`，并配置 FileProvider
（`${applicationId}.app_installer.fileprovider`），仅开放缓存目录。其他平台会抛出
`UnsupportedError`；iOS 更新通过 App Store 完成。
