package cn.deeprespond.system_audio_capture

import android.annotation.SuppressLint
import android.annotation.TargetApi
import android.content.Context
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioPlaybackCaptureConfiguration
import android.media.AudioRecord
import android.media.AudioRecordingConfiguration
import android.media.projection.MediaProjection
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.Process
import android.os.SystemClock
import android.util.Log
import java.util.concurrent.TimeUnit
import kotlin.math.max

/** Receives the engine's output. Called on the engine's mixer thread. */
internal interface CaptureSink {
    fun onPcm(bytes: ByteArray)
    fun onLevel(level: Double)
    fun onEvent(type: String, extra: Map<String, Any?> = emptyMap())
}

/**
 * System audio (AudioPlaybackCapture) + optional microphone capture.
 *
 * One reader thread per AudioRecord pushes resampled float samples into a [FloatRing]. A mixer
 * thread paced by the monotonic clock (delayed by `jitterBufferMs` to absorb bursty delivery)
 * pulls exactly one frame per `frameMs` from each ring — zero-padding an input that has no data,
 * e.g. system capture while nothing is playing — so the output is continuous and its sample count
 * matches wall-clock time, which the VAD/segment timestamps downstream rely on.
 */
@TargetApi(Build.VERSION_CODES.Q)
internal class CaptureEngine(
    private val context: Context,
    private val projection: MediaProjection,
    private val config: CaptureConfig,
    private val sink: CaptureSink,
) {
    @Volatile var paused = false

    @Volatile private var running = false
    private val threads = mutableListOf<Thread>()
    private var systemInput: Input? = null
    private var micInput: Input? = null
    private var recordingCallback: AudioManager.AudioRecordingCallback? = null
    private val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager

    private class Input(val name: String, val record: AudioRecord, val rate: Int, val ring: FloatRing)

    /** Opens the recorders and starts the threads. Throws [CaptureException]. */
    fun start() {
        val ringCapacity = config.samplesFor(config.maxBufferMs)
        try {
            systemInput = openInput("system", ringCapacity) { rate -> buildPlaybackRecord(rate) }
            if (config.includeMicrophone) {
                micInput = openInput("mic", ringCapacity) { rate -> buildMicRecord(rate) }
            }
        } catch (e: CaptureException) {
            release()
            throw e
        } catch (e: SecurityException) {
            release()
            throw CaptureException(ErrorCodes.PERMISSION_DENIED, e.message)
        }
        running = true
        listOfNotNull(systemInput, micInput).forEach { input ->
            try {
                input.record.startRecording()
            } catch (e: IllegalStateException) {
                stop()
                throw CaptureException(ErrorCodes.BUSY, "${input.name}: ${e.message}")
            }
            if (input.record.recordingState != AudioRecord.RECORDSTATE_RECORDING) {
                stop()
                throw CaptureException(ErrorCodes.BUSY, "${input.name} did not start")
            }
            threads += Thread({ readLoop(input) }, "SystemAudioCapture-${input.name}")
        }
        threads += Thread(::mixLoop, "SystemAudioCapture-mixer")
        threads.forEach { it.start() }
        micInput?.let { registerSilenceCallback(it.record) }
    }

    fun stop() {
        running = false
        // Stopping the recorders unblocks readers waiting in READ_BLOCKING.
        listOfNotNull(systemInput, micInput).forEach { input ->
            try {
                if (input.record.recordingState == AudioRecord.RECORDSTATE_RECORDING) input.record.stop()
            } catch (_: IllegalStateException) {
            }
        }
        threads.forEach { t ->
            if (t !== Thread.currentThread()) {
                try {
                    t.join(JOIN_TIMEOUT_MS)
                } catch (_: InterruptedException) {
                    Thread.currentThread().interrupt()
                }
            }
        }
        threads.clear()
        release()
    }

    private fun release() {
        recordingCallback?.let { audioManager.unregisterAudioRecordingCallback(it) }
        recordingCallback = null
        listOfNotNull(systemInput, micInput).forEach { input ->
            try {
                if (input.record.recordingState == AudioRecord.RECORDSTATE_RECORDING) input.record.stop()
            } catch (_: IllegalStateException) {
            }
            input.record.release()
        }
        systemInput = null
        micInput = null
    }

    /** Tries the output rate first (no resampling), then the configured fallback rate. */
    private fun openInput(name: String, ringCapacity: Int, build: (Int) -> AudioRecord?): Input {
        val rates = listOf(config.sampleRate, config.fallbackCaptureSampleRate).distinct()
        for (rate in rates) {
            val record = try {
                build(rate)
            } catch (e: UnsupportedOperationException) {
                Log.w(TAG, "$name: $rate Hz unsupported: ${e.message}")
                null
            } catch (e: IllegalArgumentException) {
                Log.w(TAG, "$name: $rate Hz rejected: ${e.message}")
                null
            }
            if (record != null && record.state == AudioRecord.STATE_INITIALIZED) {
                return Input(name, record, rate, FloatRing(ringCapacity))
            }
            record?.release()
        }
        throw CaptureException(ErrorCodes.BUSY, "cannot open $name capture")
    }

    private fun format(rate: Int): AudioFormat = AudioFormat.Builder()
        .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
        .setSampleRate(rate)
        .setChannelMask(AudioFormat.CHANNEL_IN_MONO)
        .build()

    private fun bufferBytes(rate: Int): Int {
        val min = AudioRecord.getMinBufferSize(rate, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT)
        if (min <= 0) return -1
        // Room for the whole backlog window so short stalls of the reader never overrun.
        val wanted = (rate.toLong() * config.maxBufferMs / MS_PER_SECOND * BYTES_PER_SAMPLE).toInt()
        return max(min, wanted)
    }

    @SuppressLint("MissingPermission") // RECORD_AUDIO is checked by the plugin before start.
    private fun buildPlaybackRecord(rate: Int): AudioRecord? {
        val size = bufferBytes(rate)
        if (size <= 0) return null
        val capture = AudioPlaybackCaptureConfiguration.Builder(projection).apply {
            config.captureUsages.forEach { addMatchingUsage(it) }
        }.build()
        return AudioRecord.Builder()
            .setAudioFormat(format(rate))
            .setBufferSizeInBytes(size)
            .setAudioPlaybackCaptureConfig(capture)
            .build()
    }

    @SuppressLint("MissingPermission")
    private fun buildMicRecord(rate: Int): AudioRecord? {
        val size = bufferBytes(rate)
        if (size <= 0) return null
        return AudioRecord.Builder()
            .setAudioSource(config.micSource)
            .setAudioFormat(format(rate))
            .setBufferSizeInBytes(size)
            .build()
    }

    private fun readLoop(input: Input) {
        Process.setThreadPriority(Process.THREAD_PRIORITY_URGENT_AUDIO)
        val frame = ShortArray(max(1, (input.rate.toLong() * config.frameMs / MS_PER_SECOND).toInt()))
        val floats = FloatArray(frame.size)
        val resampler = StreamingResampler(input.rate, config.sampleRate)
        while (running) {
            val n = input.record.read(frame, 0, frame.size, AudioRecord.READ_BLOCKING)
            if (n < 0) {
                Log.e(TAG, "${input.name}: read error $n")
                if (running) sink.onEvent(EVENT_FAILED, mapOf("code" to ErrorCodes.PLATFORM, "message" to "${input.name} read error $n"))
                return
            }
            if (n == 0) continue
            for (i in 0 until n) floats[i] = frame[i] / PCM16_SCALE
            if (resampler.isPassThrough) input.ring.write(floats, n) else input.ring.write(resampler.process(floats, n))
        }
    }

    private fun mixLoop() {
        Process.setThreadPriority(Process.THREAD_PRIORITY_AUDIO)
        val frameSamples = max(1, config.samplesFor(config.frameMs))
        val frameNanos = TimeUnit.MILLISECONDS.toNanos(config.frameMs.toLong())
        val mixer = DuckingMixer(
            sampleRate = config.sampleRate,
            micGain = config.micGain,
            duckingRatio = config.duckingRatio,
            micActiveRms = config.micActiveRmsThreshold,
            attackMs = config.duckingAttackMs,
            releaseMs = config.duckingReleaseMs,
            softClipKnee = config.softClipKnee,
        )
        val sys = FloatArray(frameSamples)
        val mic = if (micInput != null) FloatArray(frameSamples) else null
        val out = FloatArray(frameSamples)
        val levelEvery = max(1, config.levelIntervalMs / max(1, config.frameMs))
        var levelSum = 0.0
        var levelCount = 0
        var levelFrames = 0
        val start = SystemClock.elapsedRealtimeNanos() + TimeUnit.MILLISECONDS.toNanos(config.jitterBufferMs.toLong())
        var emitted = 0L
        while (running) {
            val now = SystemClock.elapsedRealtimeNanos()
            val due = if (now < start) 0L else (now - start) / frameNanos
            while (emitted < due && running) {
                systemInput?.ring?.readPadded(sys)
                micInput?.ring?.readPadded(mic!!)
                mixer.mix(mic, sys, out)
                emitted++
                if (paused) continue
                sink.onPcm(DuckingMixer.toPcm16Le(out))
                for (v in out) levelSum += v.toDouble() * v
                levelCount += out.size
                if (++levelFrames >= levelEvery) {
                    sink.onLevel(DuckingMixer.level(kotlin.math.sqrt(levelSum / levelCount), config.levelFloorDb))
                    levelSum = 0.0
                    levelCount = 0
                    levelFrames = 0
                }
            }
            val nextDue = start + (emitted + 1) * frameNanos
            val sleepNanos = nextDue - SystemClock.elapsedRealtimeNanos()
            if (sleepNanos > 0) {
                try {
                    TimeUnit.NANOSECONDS.sleep(sleepNanos)
                } catch (_: InterruptedException) {
                    return
                }
            }
        }
    }

    /** Reports the mic being silenced by the OS (e.g. a phone call) as interrupted / interruptionEnded. */
    private fun registerSilenceCallback(record: AudioRecord) {
        var silenced = false
        val callback = object : AudioManager.AudioRecordingCallback() {
            override fun onRecordingConfigChanged(configs: MutableList<AudioRecordingConfiguration>) {
                val mine = configs.firstOrNull { it.clientAudioSessionId == record.audioSessionId } ?: return
                if (mine.isClientSilenced != silenced) {
                    silenced = mine.isClientSilenced
                    sink.onEvent(if (silenced) EVENT_INTERRUPTED else EVENT_INTERRUPTION_ENDED)
                }
            }
        }
        audioManager.registerAudioRecordingCallback(callback, Handler(Looper.getMainLooper()))
        recordingCallback = callback
    }

    companion object {
        private const val TAG = "SystemAudioCapture"
        private const val MS_PER_SECOND = 1000L
        private const val BYTES_PER_SAMPLE = 2
        private const val PCM16_SCALE = 32768f
        private const val JOIN_TIMEOUT_MS = 1000L
        const val EVENT_INTERRUPTED = "interrupted"
        const val EVENT_INTERRUPTION_ENDED = "interruptionEnded"
        const val EVENT_STOPPED_EXTERNALLY = "stoppedExternally"
        const val EVENT_FAILED = "failed"
    }
}
