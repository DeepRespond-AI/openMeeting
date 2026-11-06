package cn.deeprespond.system_audio_capture

import android.content.Intent
import android.os.Handler
import android.os.Looper

/**
 * Process-wide bridge between the plugin (Flutter side) and [SystemAudioCaptureService].
 * All listener callbacks are delivered on the main thread.
 */
internal object CaptureHub {
    interface Listener {
        fun onStarted()
        fun onStartFailed(code: String, message: String?)
        fun onPcm(bytes: ByteArray)
        fun onLevel(level: Double)
        fun onEvent(event: Map<String, Any?>)
    }

    class StartRequest(val config: CaptureConfig, val resultCode: Int, val data: Intent)

    private val main = Handler(Looper.getMainLooper())

    @Volatile var listener: Listener? = null
    @Volatile var service: SystemAudioCaptureService? = null
    private var pending: StartRequest? = null

    fun setPendingRequest(request: StartRequest) {
        synchronized(this) { pending = request }
    }

    fun takePendingRequest(): StartRequest? = synchronized(this) { pending.also { pending = null } }

    fun onStarted() = post { it.onStarted() }

    fun onStartFailed(code: String, message: String?) = post { it.onStartFailed(code, message) }

    fun onStoppedExternally(reason: String) =
        post { it.onEvent(mapOf("type" to CaptureEngine.EVENT_STOPPED_EXTERNALLY, "reason" to reason)) }

    val sink = object : CaptureSink {
        override fun onPcm(bytes: ByteArray) = post { it.onPcm(bytes) }
        override fun onLevel(level: Double) = post { it.onLevel(level) }
        override fun onEvent(type: String, extra: Map<String, Any?>) =
            post { it.onEvent(mapOf("type" to type) + extra) }
    }

    private fun post(block: (Listener) -> Unit) {
        main.post { listener?.let(block) }
    }
}
