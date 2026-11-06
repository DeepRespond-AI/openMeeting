import 'dart:math' as math;
import 'dart:typed_data';

/// Helpers for mono/interleaved PCM16 little-endian audio (the format every
/// [AudioSource] emits and `POST /meetings/{id}/segments` expects).
abstract final class Pcm16 {
  /// Bytes per PCM16 sample.
  static const int bytesPerSample = 2;

  /// Full-scale value used to normalize samples to -1..1.
  static const double fullScale = 32768;

  /// Guard added to the mean square before `log10` (same as the server VAD).
  static const double energyEpsilon = 1e-10;

  /// Decodes little-endian PCM16 [bytes] into samples. A trailing odd byte is ignored.
  static Int16List decode(Uint8List bytes) {
    final count = bytes.length ~/ bytesPerSample;
    final view = ByteData.sublistView(bytes);
    final out = Int16List(count);
    for (var i = 0; i < count; i++) {
      out[i] = view.getInt16(i * bytesPerSample, Endian.little);
    }
    return out;
  }

  /// Encodes [samples] as little-endian PCM16 bytes.
  static Uint8List encode(Int16List samples, [int start = 0, int? end]) {
    final stop = end ?? samples.length;
    final out = Uint8List((stop - start) * bytesPerSample);
    final view = ByteData.sublistView(out);
    for (var i = start; i < stop; i++) {
      view.setInt16((i - start) * bytesPerSample, samples[i], Endian.little);
    }
    return out;
  }

  /// Mean square of the normalized samples in `[start, end)`.
  static double meanSquare(Int16List samples, [int start = 0, int? end]) {
    final stop = end ?? samples.length;
    final n = stop - start;
    if (n <= 0) return 0;
    var sum = 0.0;
    for (var i = start; i < stop; i++) {
      final v = samples[i] / fullScale;
      sum += v * v;
    }
    return sum / n;
  }

  /// Energy in dBFS of `[start, end)`: `10 * log10(mean(x²) + 1e-10)`, like the server VAD.
  static double energyDb(Int16List samples, [int start = 0, int? end]) =>
      10 * math.log(meanSquare(samples, start, end) + energyEpsilon) / math.ln10;

  /// Duration of [byteCount] bytes of PCM16 audio.
  static Duration durationOf(int byteCount, {required int sampleRate, required int channels}) {
    final frames = byteCount ~/ (bytesPerSample * channels);
    return Duration(microseconds: frames * Duration.microsecondsPerSecond ~/ sampleRate);
  }

  /// Maps a dBFS value to a 0..1 meter level, with [floorDb] → 0 and 0 dBFS → 1.
  static double levelFromDb(double db, {required double floorDb}) {
    if (floorDb >= 0) return 0;
    return ((db - floorDb) / -floorDb).clamp(0.0, 1.0);
  }
}
