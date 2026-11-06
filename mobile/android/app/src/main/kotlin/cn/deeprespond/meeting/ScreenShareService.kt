package cn.deeprespond.meeting

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder

/** Separate projection service: microphone recording keeps its own lifecycle. */
class ScreenShareService : Service() {
    companion object {
        var ready: ((Exception?) -> Unit)? = null
        private const val CHANNEL = "meeting_screen_share"
        private const val NOTIFICATION = 4103
    }
    override fun onBind(intent: Intent?): IBinder? = null
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        try {
            val title = intent?.getStringExtra("title") ?: applicationInfo.loadLabel(packageManager).toString()
            val manager = getSystemService(NotificationManager::class.java)
            if (Build.VERSION.SDK_INT >= 26) manager.createNotificationChannel(
                NotificationChannel(CHANNEL, title, NotificationManager.IMPORTANCE_LOW))
            val builder = if (Build.VERSION.SDK_INT >= 26) Notification.Builder(this, CHANNEL) else Notification.Builder(this)
            val launch = packageManager.getLaunchIntentForPackage(packageName)
            val notification = builder.setSmallIcon(android.R.drawable.ic_menu_view)
                .setContentTitle(title).setContentText(intent?.getStringExtra("body"))
                .setOngoing(true)
                .setContentIntent(PendingIntent.getActivity(this, 0, launch, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT))
                .build()
            if (Build.VERSION.SDK_INT >= 29) startForeground(NOTIFICATION, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION)
            else startForeground(NOTIFICATION, notification)
            ready?.invoke(null)
        } catch (error: Exception) {
            ready?.invoke(error)
            stopSelf()
        } finally {
            ready = null
        }
        return START_NOT_STICKY
    }
    override fun onDestroy() {
        stopForeground(STOP_FOREGROUND_REMOVE)
        super.onDestroy()
    }
}
