import 'dart:math' as math;
import 'dart:typed_data';

import 'package:meeting/features/recording/domain/pcm.dart';

/// Builds synthetic mono PCM16 test audio.
class SignalBuilder {
  SignalBuilder(this.sampleRate, {int seed = 7}) : _random = math.Random(seed);

  final int sampleRate;
  final math.Random _random;
  final List<int> _samples = [];

  int get length => _samples.length;
  double get seconds => _samples.length / sampleRate;

  int _n(double sec) => (sec * sampleRate).round();

  SignalBuilder silence(double sec) {
    _samples.addAll(List.filled(_n(sec), 0));
    return this;
  }

  /// Sine tone with amplitude [amp] (0..1 of full scale).
  SignalBuilder tone(double sec, {double amp = 0.3, double hz = 440}) {
    final start = _samples.length;
    for (var i = 0; i < _n(sec); i++) {
      _samples.add(
        (amp * Pcm16.fullScale * math.sin(2 * math.pi * hz * (start + i) / sampleRate))
            .round()
            .clamp(-32768, 32767),
      );
    }
    return this;
  }

  /// Uniform white noise with peak [amp].
  SignalBuilder noise(double sec, {double amp = 0.01}) {
    for (var i = 0; i < _n(sec); i++) {
      _samples.add(((_random.nextDouble() * 2 - 1) * amp * Pcm16.fullScale).round());
    }
    return this;
  }

  /// Exact sample counts (frame-aligned constructions).
  SignalBuilder zeros(int count) {
    _samples.addAll(List.filled(count, 0));
    return this;
  }

  Uint8List build() => Pcm16.encode(Int16List.fromList(_samples));
}
