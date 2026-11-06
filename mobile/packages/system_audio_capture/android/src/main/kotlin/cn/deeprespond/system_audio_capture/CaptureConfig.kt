package cn.deeprespond.system_audio_capture

import android.media.AudioAttributes
import android.media.MediaRecorder

/** Error codes shared with Dart (`SystemAudioErrorCode`). */
internal object ErrorCodes {
    const val PERMISSION_DENIED = "permissionDenied"
    const val USER_CANCELLED = "userCancelled"
    const val UNSUPPORTED = "unsupported"
    const val BUSY = "busy"
    const val PLATFORM = "platform"
}

internal class CaptureException(val code: String, message: String?) : Exception(message)

/** Parameters of one capture session, decoded from the Dart `SystemAudioStartOptions` map. */
internal data class CaptureConfig(
    val sampleRate: Int,
    val includeMicrophone: Boolean,
    val micGain: Float,
    val duckingRatio: Float,
    val frameMs: Int,
    val jitterBufferMs: Int,
    val maxBufferMs: Int,
    val micActiveRmsThreshold: Float,
    val duckingAttackMs: Int,
    val duckingReleaseMs: Int,
    val softClipKnee: Float,
    val levelIntervalMs: Int,
    val levelFloorDb: Double,
    val captureUsages: List<Int>,
    val micSource: Int,
    val fallbackCaptureSampleRate: Int,
    val notificationChannelId: String,
    val notificationId: Int,
    val notificationChannelName: String,
    val notificationTitle: String,
    val notificationText: String,
) {
    fun samplesFor(ms: Int): Int = (sampleRate.toLong() * ms / MS_PER_SECOND).toInt()

    companion object {
        private const val MS_PER_SECOND = 1000

        @Suppress("UNCHECKED_CAST")
        fun fromArgs(args: Map<*, *>): CaptureConfig {
            fun num(key: String): Number =
                args[key] as? Number ?: throw CaptureException(ErrorCodes.PLATFORM, "missing $key")
            fun str(map: Map<*, *>, key: String): String =
                map[key] as? String ?: throw CaptureException(ErrorCodes.PLATFORM, "missing $key")
            val texts = args["texts"] as? Map<*, *>
                ?: throw CaptureException(ErrorCodes.PLATFORM, "missing texts")
            val usages = (args["androidCaptureUsages"] as? List<*>).orEmpty().mapNotNull {
                when (it) {
                    "media" -> AudioAttributes.USAGE_MEDIA
                    "game" -> AudioAttributes.USAGE_GAME
                    "unknown" -> AudioAttributes.USAGE_UNKNOWN
                    else -> null
                }
            }
            if (usages.isEmpty()) throw CaptureException(ErrorCodes.PLATFORM, "no capture usages")
            val micSource = when (args["androidMicSource"]) {
                "mic" -> MediaRecorder.AudioSource.MIC
                "voiceCommunication" -> MediaRecorder.AudioSource.VOICE_COMMUNICATION
                "camcorder" -> MediaRecorder.AudioSource.CAMCORDER
                else -> MediaRecorder.AudioSource.VOICE_RECOGNITION
            }
            return CaptureConfig(
                sampleRate = num("sampleRate").toInt(),
                includeMicrophone = args["includeMicrophone"] as? Boolean ?: false,
                micGain = num("micGain").toFloat(),
                duckingRatio = num("duckingRatio").toFloat(),
                frameMs = num("frameMs").toInt(),
                jitterBufferMs = num("jitterBufferMs").toInt(),
                maxBufferMs = num("maxBufferMs").toInt(),
                micActiveRmsThreshold = num("micActiveRmsThreshold").toFloat(),
                duckingAttackMs = num("duckingAttackMs").toInt(),
                duckingReleaseMs = num("duckingReleaseMs").toInt(),
                softClipKnee = num("softClipKnee").toFloat(),
                levelIntervalMs = num("levelIntervalMs").toInt(),
                levelFloorDb = num("levelFloorDb").toDouble(),
                captureUsages = usages,
                micSource = micSource,
                fallbackCaptureSampleRate = num("androidFallbackCaptureSampleRate").toInt(),
                notificationChannelId = args["androidNotificationChannelId"] as? String
                    ?: throw CaptureException(ErrorCodes.PLATFORM, "missing channel id"),
                notificationId = num("androidNotificationId").toInt(),
                notificationChannelName = str(texts, "notificationChannelName"),
                notificationTitle = str(texts, "notificationTitle"),
                notificationText = str(texts, "notificationText"),
            )
        }
    }
}
