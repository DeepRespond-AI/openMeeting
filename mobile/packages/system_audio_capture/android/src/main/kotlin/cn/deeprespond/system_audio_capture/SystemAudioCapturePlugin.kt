package cn.deeprespond.system_audio_capture

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.projection.MediaProjectionConfig
import android.media.projection.MediaProjectionManager
import android.os.Build
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry

/**
 * Android side of `system_audio_capture`: consent (RECORD_AUDIO + MediaProjection dialog),
 * foreground service lifecycle, and the method/event channels.
 *
 * State machine: idle → requestingPermission → requestingProjection → starting → capturing → idle.
 */
class SystemAudioCapturePlugin :
    FlutterPlugin,
    MethodCallHandler,
    ActivityAware,
    PluginRegistry.ActivityResultListener,
    PluginRegistry.RequestPermissionsResultListener,
    CaptureHub.Listener {

    private enum class State { IDLE, REQUESTING_PERMISSION, REQUESTING_PROJECTION, STARTING, CAPTURING }

    private lateinit var context: Context
    private lateinit var methodChannel: MethodChannel
    private val eventChannels = mutableListOf<EventChannel>()
    private var pcmSink: EventChannel.EventSink? = null
    private var levelSink: EventChannel.EventSink? = null
    private var eventSink: EventChannel.EventSink? = null

    private var activityBinding: ActivityPluginBinding? = null
    private var state = State.IDLE
    private var pendingResult: Result? = null
    private var pendingConfig: CaptureConfig? = null

    // region FlutterPlugin

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        methodChannel = MethodChannel(binding.binaryMessenger, "$CHANNEL_PREFIX/method")
        methodChannel.setMethodCallHandler(this)
        eventChannels += channel(binding, "pcm") { pcmSink = it }
        eventChannels += channel(binding, "level") { levelSink = it }
        eventChannels += channel(binding, "events") { eventSink = it }
        CaptureHub.listener = this
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannels.forEach { it.setStreamHandler(null) }
        eventChannels.clear()
        if (CaptureHub.listener === this) CaptureHub.listener = null
        CaptureHub.service?.stopCapture(null)
        state = State.IDLE
    }

    private fun channel(
        binding: FlutterPlugin.FlutterPluginBinding,
        name: String,
        setSink: (EventChannel.EventSink?) -> Unit,
    ): EventChannel = EventChannel(binding.binaryMessenger, "$CHANNEL_PREFIX/$name").also {
        it.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) = setSink(events)
            override fun onCancel(arguments: Any?) = setSink(null)
        })
    }

    // endregion

    // region ActivityAware

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        binding.addActivityResultListener(this)
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() = onDetachedFromActivity()

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) =
        onAttachedToActivity(binding)

    override fun onDetachedFromActivity() {
        activityBinding?.removeActivityResultListener(this)
        activityBinding?.removeRequestPermissionsResultListener(this)
        activityBinding = null
    }

    // endregion

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "availability" -> result.success(availability())
            "start" -> start(call, result)
            "pause" -> {
                CaptureHub.service?.setPaused(true)
                result.success(null)
            }
            "resume" -> {
                CaptureHub.service?.setPaused(false)
                result.success(null)
            }
            "stop" -> {
                stop()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun availability(): String = when {
        Build.VERSION.SDK_INT < Build.VERSION_CODES.Q -> "unsupported"
        !hasRecordPermission() -> "needsPermission"
        else -> "available"
    }

    private fun hasRecordPermission() =
        context.checkSelfPermission(Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED

    private fun start(call: MethodCall, result: Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            result.error(ErrorCodes.UNSUPPORTED, "Android 10+ required", null)
            return
        }
        if (state != State.IDLE || CaptureHub.service != null) {
            result.error(ErrorCodes.BUSY, "capture already in progress", null)
            return
        }
        val config = try {
            CaptureConfig.fromArgs(call.arguments as? Map<*, *> ?: emptyMap<String, Any>())
        } catch (e: CaptureException) {
            result.error(e.code, e.message, null)
            return
        }
        val activity = activityBinding?.activity
        if (activity == null) {
            result.error(ErrorCodes.PLATFORM, "no foreground activity", null)
            return
        }
        pendingResult = result
        pendingConfig = config
        if (hasRecordPermission()) {
            requestProjection(activity)
        } else {
            state = State.REQUESTING_PERMISSION
            activity.requestPermissions(arrayOf(Manifest.permission.RECORD_AUDIO), REQUEST_RECORD_AUDIO)
        }
    }

    private fun requestProjection(activity: Activity) {
        state = State.REQUESTING_PROJECTION
        val manager = activity.getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        // Android 14+: offer only whole-screen sharing; single-app sharing cannot capture other apps' audio.
        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            manager.createScreenCaptureIntent(MediaProjectionConfig.createConfigForDefaultDisplay())
        } else {
            manager.createScreenCaptureIntent()
        }
        try {
            activity.startActivityForResult(intent, REQUEST_PROJECTION)
        } catch (e: android.content.ActivityNotFoundException) {
            finishStart(ErrorCodes.UNSUPPORTED, e.message)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ): Boolean {
        if (requestCode != REQUEST_RECORD_AUDIO || state != State.REQUESTING_PERMISSION) return false
        val granted = grantResults.isNotEmpty() && grantResults.all { it == PackageManager.PERMISSION_GRANTED }
        val activity = activityBinding?.activity
        when {
            !granted -> finishStart(ErrorCodes.PERMISSION_DENIED, "RECORD_AUDIO denied")
            activity == null -> finishStart(ErrorCodes.PLATFORM, "no foreground activity")
            else -> requestProjection(activity)
        }
        return true
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_PROJECTION || state != State.REQUESTING_PROJECTION) return false
        val config = pendingConfig
        if (resultCode != Activity.RESULT_OK || data == null || config == null) {
            finishStart(ErrorCodes.USER_CANCELLED, "screen capture consent declined")
            return true
        }
        state = State.STARTING
        CaptureHub.setPendingRequest(CaptureHub.StartRequest(config, resultCode, data))
        val intent = Intent(context, SystemAudioCaptureService::class.java)
            .setAction(SystemAudioCaptureService.ACTION_START)
        try {
            context.startForegroundService(intent)
        } catch (e: IllegalStateException) {
            CaptureHub.takePendingRequest()
            finishStart(ErrorCodes.PLATFORM, e.message)
        } catch (e: SecurityException) {
            CaptureHub.takePendingRequest()
            finishStart(ErrorCodes.PERMISSION_DENIED, e.message)
        }
        return true
    }

    private fun finishStart(errorCode: String?, message: String?) {
        val result = pendingResult
        pendingResult = null
        pendingConfig = null
        if (errorCode == null) {
            state = State.CAPTURING
            result?.success(mapOf("mode" to MODE_STREAM))
        } else {
            state = State.IDLE
            result?.error(errorCode, message, null)
        }
    }

    private fun stop() {
        when (state) {
            State.CAPTURING -> {
                state = State.IDLE
                CaptureHub.service?.stopCapture(null)
            }
            State.STARTING -> {
                CaptureHub.takePendingRequest()
                CaptureHub.service?.stopCapture(null)
                finishStart(ErrorCodes.USER_CANCELLED, "stopped before start")
            }
            State.REQUESTING_PERMISSION, State.REQUESTING_PROJECTION ->
                finishStart(ErrorCodes.USER_CANCELLED, "stopped before start")
            State.IDLE -> Unit
        }
    }

    // region CaptureHub.Listener (main thread)

    override fun onStarted() {
        if (state == State.STARTING) finishStart(null, null) else CaptureHub.service?.stopCapture(null)
    }

    override fun onStartFailed(code: String, message: String?) {
        if (state == State.STARTING) finishStart(code, message)
    }

    override fun onPcm(bytes: ByteArray) {
        if (state == State.CAPTURING) pcmSink?.success(bytes)
    }

    override fun onLevel(level: Double) {
        if (state == State.CAPTURING) levelSink?.success(level)
    }

    override fun onEvent(event: Map<String, Any?>) {
        if (event["type"] == CaptureEngine.EVENT_STOPPED_EXTERNALLY) {
            if (state != State.CAPTURING) return
            state = State.IDLE
        }
        eventSink?.success(event)
    }

    // endregion

    private companion object {
        const val CHANNEL_PREFIX = "cn.deeprespond.system_audio_capture"
        const val MODE_STREAM = "stream"
        // Request codes must not collide with other plugins' codes on the same activity.
        const val REQUEST_RECORD_AUDIO = 0x5AC1
        const val REQUEST_PROJECTION = 0x5AC2
    }
}
