package cn.deeprespond.system_audio_capture

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log

/**
 * Foreground service (type mediaProjection|microphone) that owns the MediaProjection and the
 * [CaptureEngine] for the duration of a system-audio capture.
 *
 * Android 14+: the service must already be in the foreground with type mediaProjection before
 * `getMediaProjection` is called, and the consent token can be used only once.
 */
class SystemAudioCaptureService : Service() {
    private val mainHandler = Handler(Looper.getMainLooper())
    private var projection: MediaProjection? = null
    private var engine: CaptureEngine? = null
    private var stopping = false

    private val projectionCallback = object : MediaProjection.Callback() {
        override fun onStop() {
            // Revoked by the user (status-bar chip / "stop sharing") or by the system.
            if (!stopping) stopCapture(REASON_PROJECTION_STOPPED)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> handleStart()
            ACTION_STOP -> stopCapture(null)
            else -> stopSelf()
        }
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        if (engine != null && !stopping) stopCapture(REASON_SERVICE_DESTROYED)
        if (CaptureHub.service === this) CaptureHub.service = null
        super.onDestroy()
    }

    private fun handleStart() {
        val request = CaptureHub.takePendingRequest()
        if (request == null || Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            CaptureHub.onStartFailed(ErrorCodes.PLATFORM, "no pending capture request")
            stopSelf()
            return
        }
        val config = request.config
        stopping = false
        CaptureHub.service = this
        try {
            startForeground(config.notificationId, buildNotification(config), serviceTypes(config))
        } catch (e: SecurityException) {
            fail(ErrorCodes.PERMISSION_DENIED, e.message)
            return
        } catch (e: IllegalStateException) { // e.g. ForegroundServiceStartNotAllowedException
            fail(ErrorCodes.PLATFORM, e.message)
            return
        }
        val manager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        val mp = try {
            manager.getMediaProjection(request.resultCode, request.data)
        } catch (e: SecurityException) {
            fail(ErrorCodes.PERMISSION_DENIED, e.message)
            return
        } catch (e: IllegalStateException) {
            fail(ErrorCodes.BUSY, e.message)
            return
        }
        if (mp == null) {
            fail(ErrorCodes.USER_CANCELLED, "projection not granted")
            return
        }
        projection = mp
        mp.registerCallback(projectionCallback, mainHandler)
        val e = CaptureEngine(this, mp, config, CaptureHub.sink)
        try {
            e.start()
        } catch (ex: CaptureException) {
            fail(ex.code, ex.message)
            return
        }
        engine = e
        CaptureHub.onStarted()
    }

    private fun fail(code: String, message: String?) {
        Log.w(TAG, "start failed: $code $message")
        stopping = true
        releaseAll()
        CaptureHub.onStartFailed(code, message)
    }

    fun setPaused(paused: Boolean) {
        engine?.paused = paused
    }

    /** Stops capturing. [externalReason] != null means the stop did not come from the app. */
    fun stopCapture(externalReason: String?) {
        if (stopping) return
        stopping = true
        releaseAll()
        if (externalReason != null) CaptureHub.onStoppedExternally(externalReason)
    }

    private fun releaseAll() {
        engine?.stop()
        engine = null
        projection?.let {
            it.unregisterCallback(projectionCallback)
            it.stop()
        }
        projection = null
        if (CaptureHub.service === this) CaptureHub.service = null
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private fun serviceTypes(config: CaptureConfig): Int {
        var types = ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION
        if (config.includeMicrophone && Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            types = types or ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE
        }
        return types
    }

    private fun buildNotification(config: CaptureConfig): Notification {
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.createNotificationChannel(
            NotificationChannel(
                config.notificationChannelId,
                config.notificationChannelName,
                NotificationManager.IMPORTANCE_LOW,
            ),
        )
        val launch = packageManager.getLaunchIntentForPackage(packageName)?.let {
            PendingIntent.getActivity(this, 0, it, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        }
        return Notification.Builder(this, config.notificationChannelId)
            .setContentTitle(config.notificationTitle)
            .setContentText(config.notificationText)
            .setSmallIcon(applicationInfo.icon)
            .setOngoing(true)
            .setContentIntent(launch)
            .build()
    }

    companion object {
        private const val TAG = "SystemAudioCapture"
        const val ACTION_START = "cn.deeprespond.system_audio_capture.START"
        const val ACTION_STOP = "cn.deeprespond.system_audio_capture.STOP"
        const val REASON_PROJECTION_STOPPED = "projectionStopped"
        const val REASON_SERVICE_DESTROYED = "serviceDestroyed"
    }
}
