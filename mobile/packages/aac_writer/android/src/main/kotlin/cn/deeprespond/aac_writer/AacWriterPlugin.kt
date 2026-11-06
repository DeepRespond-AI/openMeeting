package cn.deeprespond.aac_writer

import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaFormat
import android.media.MediaMuxer
import android.os.Handler
import android.os.HandlerThread
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicInteger

/**
 * PCM16 → AAC-LC (.m4a) streaming encoder: MediaCodec + MediaMuxer.
 *
 * Every session owns a background [HandlerThread]; method calls are queued to it in order and
 * answered on the main thread once processed, so the Dart side gets natural backpressure.
 */
class AacWriterPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private val sessions = ConcurrentHashMap<Int, Session>()
    private val nextHandle = AtomicInteger(1)
    private val main = Handler(Looper.getMainLooper())

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        for (session in sessions.values) session.post { session.close() }
        sessions.clear()
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "open" -> open(call, result)
            "write" -> {
                val session = sessionFor(call, result) ?: return
                val data = call.argument<ByteArray>("data") ?: ByteArray(0)
                session.post {
                    try {
                        session.write(data)
                        reply(result)
                    } catch (e: Exception) {
                        fail(result, "write_failed", e)
                    }
                }
            }
            "close" -> {
                val handle = call.argument<Int>("handle") ?: -1
                val session = sessions.remove(handle)
                if (session == null) {
                    result.success(null)
                    return
                }
                session.post {
                    try {
                        session.close()
                        reply(result)
                    } catch (e: Exception) {
                        fail(result, "close_failed", e)
                    } finally {
                        session.quit()
                    }
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun open(call: MethodCall, result: Result) {
        val path = call.argument<String>("path")
        val sampleRate = call.argument<Int>("sampleRate")
        val channels = call.argument<Int>("channels")
        val bitrate = call.argument<Int>("bitrate")
        if (path == null || sampleRate == null || channels == null || bitrate == null) {
            result.error("bad_args", "path, sampleRate, channels and bitrate are required", null)
            return
        }
        val handle = nextHandle.getAndIncrement()
        val session = Session(path, sampleRate, channels, bitrate)
        session.post {
            try {
                session.start()
                sessions[handle] = session
                main.post { result.success(handle) }
            } catch (e: Exception) {
                session.quit()
                fail(result, "open_failed", e)
            }
        }
    }

    private fun sessionFor(call: MethodCall, result: Result): Session? {
        val handle = call.argument<Int>("handle") ?: -1
        val session = sessions[handle]
        if (session == null) result.error("not_open", "No open AAC writer with handle $handle", null)
        return session
    }

    private fun reply(result: Result) = main.post { result.success(null) }

    private fun fail(result: Result, code: String, e: Exception) =
        main.post { result.error(code, e.message ?: e.toString(), null) }

    private class Session(
        private val path: String,
        private val sampleRate: Int,
        private val channels: Int,
        private val bitrate: Int,
    ) {
        private val thread = HandlerThread("AacWriter").apply { start() }
        private val handler = Handler(thread.looper)
        private val frameBytes = 2 * channels
        private lateinit var codec: MediaCodec
        private lateinit var muxer: MediaMuxer
        private val info = MediaCodec.BufferInfo()
        private var track = -1
        private var muxerStarted = false
        private var framesQueued = 0L
        private var closed = false

        fun post(block: () -> Unit) {
            handler.post(block)
        }

        fun quit() {
            thread.quitSafely()
        }

        fun start() {
            File(path).parentFile?.mkdirs()
            val format = MediaFormat.createAudioFormat(MediaFormat.MIMETYPE_AUDIO_AAC, sampleRate, channels).apply {
                setInteger(MediaFormat.KEY_AAC_PROFILE, MediaCodecInfo.CodecProfileLevel.AACObjectLC)
                setInteger(MediaFormat.KEY_BIT_RATE, bitrate)
                setInteger(MediaFormat.KEY_MAX_INPUT_SIZE, MAX_INPUT_SIZE)
            }
            codec = MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_AUDIO_AAC)
            codec.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
            codec.start()
            muxer = MediaMuxer(path, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
        }

        fun write(data: ByteArray) {
            if (closed) return
            var offset = 0
            val usable = data.size - data.size % frameBytes
            while (offset < usable) {
                val index = codec.dequeueInputBuffer(TIMEOUT_US)
                if (index < 0) {
                    drain(false)
                    continue
                }
                val buffer = codec.getInputBuffer(index) ?: continue
                buffer.clear()
                var n = minOf(buffer.remaining(), usable - offset)
                n -= n % frameBytes
                buffer.put(data, offset, n)
                codec.queueInputBuffer(index, 0, n, presentationTimeUs(), 0)
                offset += n
                framesQueued += n / frameBytes
                drain(false)
            }
        }

        fun close() {
            if (closed) return
            closed = true
            try {
                var attempts = 0
                while (attempts++ < MAX_DRAIN_ATTEMPTS) {
                    val index = codec.dequeueInputBuffer(TIMEOUT_US)
                    if (index >= 0) {
                        codec.queueInputBuffer(index, 0, 0, presentationTimeUs(), MediaCodec.BUFFER_FLAG_END_OF_STREAM)
                        break
                    }
                    drain(false)
                }
                drain(true)
            } finally {
                runCatching { codec.stop() }
                runCatching { codec.release() }
                if (muxerStarted) {
                    runCatching { muxer.stop() }
                }
                runCatching { muxer.release() }
                if (!muxerStarted) File(path).delete()
            }
        }

        private fun presentationTimeUs() = framesQueued * 1_000_000L / sampleRate

        private fun drain(endOfStream: Boolean) {
            var idleAttempts = 0
            while (true) {
                val index = codec.dequeueOutputBuffer(info, if (endOfStream) TIMEOUT_US else 0)
                when {
                    index == MediaCodec.INFO_TRY_AGAIN_LATER -> {
                        if (!endOfStream || ++idleAttempts > MAX_DRAIN_ATTEMPTS) return
                    }
                    index == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                        if (!muxerStarted) {
                            track = muxer.addTrack(codec.outputFormat)
                            muxer.start()
                            muxerStarted = true
                        }
                    }
                    index >= 0 -> {
                        val buffer = codec.getOutputBuffer(index)
                        if (info.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG != 0) info.size = 0
                        if (buffer != null && info.size > 0 && muxerStarted) {
                            buffer.position(info.offset)
                            buffer.limit(info.offset + info.size)
                            muxer.writeSampleData(track, buffer, info)
                        }
                        codec.releaseOutputBuffer(index, false)
                        if (info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) return
                    }
                }
            }
        }
    }

    companion object {
        private const val CHANNEL = "cn.deeprespond.aac_writer"
        private const val TIMEOUT_US = 10_000L
        private const val MAX_INPUT_SIZE = 64 * 1024
        private const val MAX_DRAIN_ATTEMPTS = 500
    }
}
