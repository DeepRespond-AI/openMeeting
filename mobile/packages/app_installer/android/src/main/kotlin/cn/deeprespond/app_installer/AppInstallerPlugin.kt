package cn.deeprespond.app_installer

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

/** Installs a downloaded APK through the system package installer (in-app updates). */
class AppInstallerPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
  private lateinit var channel: MethodChannel
  private lateinit var context: Context

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    context = binding.applicationContext
    channel = MethodChannel(binding.binaryMessenger, "cn.deeprespond.app_installer")
    channel.setMethodCallHandler(this)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    try {
      when (call.method) {
        "canInstallPackages" -> result.success(canInstallPackages())
        "openInstallSettings" -> {
          openInstallSettings()
          result.success(null)
        }
        "installApk" -> {
          val path = call.argument<String>("path")
          if (path.isNullOrEmpty()) {
            result.error("bad_args", "path is required", null)
          } else {
            installApk(File(path))
            result.success(null)
          }
        }
        else -> result.notImplemented()
      }
    } catch (e: Exception) {
      result.error("install_failed", e.message ?: e.javaClass.simpleName, null)
    }
  }

  private fun canInstallPackages(): Boolean =
    Build.VERSION.SDK_INT < Build.VERSION_CODES.O || context.packageManager.canRequestPackageInstalls()

  private fun openInstallSettings() {
    val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
      Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES, Uri.parse("package:${context.packageName}"))
    } else {
      Intent(Settings.ACTION_SECURITY_SETTINGS)
    }
    context.startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
  }

  private fun installApk(file: File) {
    require(file.isFile) { "APK not found: ${file.path}" }
    val uri = FileProvider.getUriForFile(context, "${context.packageName}.app_installer.fileprovider", file)
    val intent = Intent(Intent.ACTION_VIEW)
      .setDataAndType(uri, "application/vnd.android.package-archive")
      .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
    context.startActivity(intent)
  }
}
