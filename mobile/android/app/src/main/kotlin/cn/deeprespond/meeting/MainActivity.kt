package cn.deeprespond.meeting

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.os.Build

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "meeting/screen-share").setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    // Dart requests MediaProjection consent first; this service must
                    // be foreground before flutter_webrtc consumes the consent.
                    ScreenShareService.ready = { error ->
                        if (error == null) result.success(null)
                        else result.error("foreground", error.message, null)
                    }
                    try {
                        val intent = Intent(this, ScreenShareService::class.java)
                            .putExtra("title", call.argument<String>("title"))
                            .putExtra("body", call.argument<String>("body"))
                        if (Build.VERSION.SDK_INT >= 26) startForegroundService(intent) else startService(intent)
                    } catch (error: Exception) {
                        ScreenShareService.ready = null
                        result.error("foreground", error.message, null)
                    }
                }
                "stop" -> {
                    stopService(Intent(this, ScreenShareService::class.java))
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
