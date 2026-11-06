package cn.deeprespond.system_audio_capture

import kotlin.math.abs
import kotlin.math.exp
import kotlin.math.log10
import kotlin.math.max
import kotlin.math.roundToInt
import kotlin.math.sqrt
import kotlin.math.tanh

/**
 * Pure DSP building blocks (no Android APIs, unit-testable on the JVM). The same rules are
 * implemented in Swift by the iOS broadcast extension (ios/BroadcastExtension/AudioMixing.swift).
 */

/** Thread-safe float FIFO with a fixed capacity; writing past capacity drops the oldest samples. */
internal class FloatRing(capacity: Int) {
    private val buf = FloatArray(max(1, capacity))
    private var head = 0 // read position
    private var size = 0
    private val lock = Object()

    val available: Int get() = synchronized(lock) { size }

    fun write(src: FloatArray, count: Int = src.size) {
        synchronized(lock) {
            var from = 0
            var n = count
            if (n > buf.size) { // keep only the newest samples
                from = n - buf.size
                n = buf.size
            }
            val overflow = size + n - buf.size
            if (overflow > 0) {
                head = (head + overflow) % buf.size
                size -= overflow
            }
            var tail = (head + size) % buf.size
            for (i in 0 until n) {
                buf[tail] = src[from + i]
                tail++
                if (tail == buf.size) tail = 0
            }
            size += n
        }
    }

    /** Reads up to [count] samples into [dst]; the rest of [dst] is zero-filled. Returns samples read. */
    fun readPadded(dst: FloatArray, count: Int = dst.size): Int {
        synchronized(lock) {
            val n = minOf(count, size)
            for (i in 0 until n) {
                dst[i] = buf[head]
                head++
                if (head == buf.size) head = 0
            }
            size -= n
            for (i in n until count) dst[i] = 0f
            return n
        }
    }

    fun clear() {
        synchronized(lock) {
            head = 0
            size = 0
        }
    }
}

/**
 * Streaming mono resampler: 4th-order Butterworth low-pass (when downsampling) followed by
 * linear interpolation. Keeps phase across calls so chunk boundaries are seamless.
 */
internal class StreamingResampler(private val inRate: Int, private val outRate: Int) {
    private val step = inRate.toDouble() / outRate
    private val filters: List<Biquad> =
        if (inRate > outRate) {
            val cutoff = outRate * LOWPASS_FRACTION_OF_NYQUIST / 2.0
            listOf(Biquad.lowPass(inRate, cutoff, Q1), Biquad.lowPass(inRate, cutoff, Q2))
        } else {
            emptyList()
        }
    private var pos = 0.0 // position of the next output sample, relative to [prev]
    private var prev = 0f
    private var hasPrev = false

    val isPassThrough: Boolean get() = inRate == outRate

    fun process(input: FloatArray, count: Int = input.size): FloatArray {
        if (isPassThrough) return input.copyOf(count)
        val out = FloatArray(((count + 1) / step).toInt() + 2)
        var n = 0
        for (i in 0 until count) {
            var x = input[i]
            for (f in filters) x = f.process(x)
            if (!hasPrev) {
                prev = x
                hasPrev = true
                continue
            }
            // Output samples falling between prev (t=0) and x (t=1).
            while (pos < 1.0) {
                out[n++] = (prev + (x - prev) * pos).toFloat()
                pos += step
            }
            pos -= 1.0
            prev = x
        }
        return out.copyOf(n)
    }

    private class Biquad(
        private val b0: Double, private val b1: Double, private val b2: Double,
        private val a1: Double, private val a2: Double,
    ) {
        private var z1 = 0.0
        private var z2 = 0.0

        fun process(x: Float): Float {
            val y = b0 * x + z1
            z1 = b1 * x - a1 * y + z2
            z2 = b2 * x - a2 * y
            return y.toFloat()
        }

        companion object {
            fun lowPass(rate: Int, cutoff: Double, q: Double): Biquad {
                val w0 = 2 * Math.PI * cutoff / rate
                val alpha = kotlin.math.sin(w0) / (2 * q)
                val cos = kotlin.math.cos(w0)
                val a0 = 1 + alpha
                return Biquad(
                    (1 - cos) / 2 / a0, (1 - cos) / a0, (1 - cos) / 2 / a0,
                    -2 * cos / a0, (1 - alpha) / a0,
                )
            }
        }
    }

    private companion object {
        // Butterworth Q values for a 4th-order filter built from two biquads.
        const val Q1 = 0.5411961
        const val Q2 = 1.3065630
        // Cut-off at 90% of the output Nyquist frequency (filter design constant).
        const val LOWPASS_FRACTION_OF_NYQUIST = 0.9
    }
}

/**
 * Mixes microphone and system audio like the desktop pipeline (frontend/src-tauri/src/audio/pipeline.rs):
 * mic * micGain + system * gain, where the system gain is ducked to [duckingRatio] while the mic
 * carries speech (RMS above [micActiveRms]), smoothed with attack/release time constants, and the
 * sum is soft-clipped above [softClipKnee] instead of hard clipping.
 */
internal class DuckingMixer(
    sampleRate: Int,
    private val micGain: Float,
    private val duckingRatio: Float,
    private val micActiveRms: Float,
    attackMs: Int,
    releaseMs: Int,
    private val softClipKnee: Float,
) {
    private val attackCoef = smoothingCoef(sampleRate, attackMs)
    private val releaseCoef = smoothingCoef(sampleRate, releaseMs)
    private var sysGain = 1f

    val currentSystemGain: Float get() = sysGain

    /** Mixes one frame. [mic] is null when the microphone is not included. */
    fun mix(mic: FloatArray?, sys: FloatArray, out: FloatArray, count: Int = out.size) {
        val target = if (mic != null && rms(mic, count) >= micActiveRms) duckingRatio else 1f
        val coef = if (target < sysGain) attackCoef else releaseCoef
        for (i in 0 until count) {
            sysGain += (target - sysGain) * coef
            val m = if (mic != null) mic[i] * micGain else 0f
            out[i] = softClip(m + sys[i] * sysGain, softClipKnee)
        }
    }

    companion object {
        private fun smoothingCoef(sampleRate: Int, ms: Int): Float =
            if (ms <= 0) 1f else (1.0 - exp(-1000.0 / (ms.toDouble() * sampleRate))).toFloat()

        fun softClip(x: Float, knee: Float): Float {
            val a = abs(x)
            if (a <= knee || knee >= 1f) return x.coerceIn(-1f, 1f)
            val range = 1f - knee
            val y = knee + range * tanh((a - knee) / range)
            return if (x < 0) -y else y
        }

        fun rms(x: FloatArray, count: Int = x.size): Float {
            if (count == 0) return 0f
            var sum = 0.0
            for (i in 0 until count) sum += x[i].toDouble() * x[i]
            return sqrt(sum / count).toFloat()
        }

        /** RMS in dBFS mapped linearly from [floorDb]..0 to 0..1. */
        fun level(rms: Double, floorDb: Double): Double {
            if (rms <= 0 || floorDb >= 0) return 0.0
            val db = 20 * log10(rms)
            return ((db - floorDb) / -floorDb).coerceIn(0.0, 1.0)
        }

        /** Float [-1, 1] → PCM16 little-endian bytes. */
        fun toPcm16Le(src: FloatArray, count: Int = src.size): ByteArray {
            val out = ByteArray(count * 2)
            for (i in 0 until count) {
                val v = (src[i].coerceIn(-1f, 1f) * Short.MAX_VALUE).roundToInt()
                out[2 * i] = (v and 0xFF).toByte()
                out[2 * i + 1] = ((v shr 8) and 0xFF).toByte()
            }
            return out
        }
    }
}
