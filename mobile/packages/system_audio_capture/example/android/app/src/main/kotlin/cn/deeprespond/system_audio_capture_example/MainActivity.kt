package cn.deeprespond.system_audio_capture_example

import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioTrack
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlin.math.PI
import kotlin.math.sin

/** Harness only: plays a test tone (USAGE_MEDIA) so system-audio capture has something to record. */
class MainActivity : FlutterActivity() {
    private var track: AudioTrack? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "harness/tone").setMethodCallHandler { call, result ->
            when (call.method) {
                "play" -> { play(call.argument<Int>("hz") ?: 440, call.argument<Int>("seconds") ?: 3); result.success(null) }
                else -> result.notImplemented()
            }
        }
    }

    private fun play(hz: Int, seconds: Int) {
        track?.release()
        val rate = 48000
        val pcm = ShortArray(rate * seconds) { i -> (sin(2 * PI * hz * i / rate) * 0.5 * Short.MAX_VALUE).toInt().toShort() }
        val t = AudioTrack.Builder()
            .setAudioAttributes(AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_MEDIA).setContentType(AudioAttributes.CONTENT_TYPE_MUSIC).build())
            .setAudioFormat(AudioFormat.Builder().setEncoding(AudioFormat.ENCODING_PCM_16BIT).setSampleRate(rate).setChannelMask(AudioFormat.CHANNEL_OUT_MONO).build())
            .setTransferMode(AudioTrack.MODE_STATIC)
            .setBufferSizeInBytes(pcm.size * 2)
            .build()
        t.write(pcm, 0, pcm.size)
        t.play()
        track = t
    }
}
