import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meeting/features/recording/domain/pcm.dart';
import 'package:meeting/features/recording/domain/time_format.dart';

void main() {
  group('Pcm16', () {
    test('encode/decode round-trips little-endian samples', () {
      final samples = Int16List.fromList([0, 1, -1, 32767, -32768, 1234, -4321]);
      final bytes = Pcm16.encode(samples);
      expect(bytes.length, samples.length * 2);
      expect(bytes.sublist(0, 4), [0, 0, 1, 0]); // 0, 1 little-endian
      expect(bytes.sublist(4, 6), [0xFF, 0xFF]); // -1
      expect(Pcm16.decode(bytes), samples);
    });

    test('decode ignores a trailing odd byte', () {
      expect(Pcm16.decode(Uint8List.fromList([1, 0, 9])), [1]);
    });

    test('encode supports sub-ranges', () {
      final samples = Int16List.fromList([1, 2, 3, 4]);
      expect(Pcm16.decode(Pcm16.encode(samples, 1, 3)), [2, 3]);
    });

    test('energyDb of silence is the epsilon floor, full-scale square is 0 dB', () {
      expect(Pcm16.energyDb(Int16List(480)), closeTo(-100, 1e-6));
      final square = Int16List.fromList(List.generate(480, (i) => i.isEven ? 32767 : -32767));
      expect(Pcm16.energyDb(square), closeTo(0, 0.01));
    });

    test('durationOf respects sample rate and channels', () {
      expect(Pcm16.durationOf(32000, sampleRate: 16000, channels: 1), const Duration(seconds: 1));
      expect(
        Pcm16.durationOf(32000, sampleRate: 16000, channels: 2),
        const Duration(milliseconds: 500),
      );
    });

    test('levelFromDb maps floor..0 dBFS to 0..1 and clamps', () {
      expect(Pcm16.levelFromDb(-60, floorDb: -60), 0);
      expect(Pcm16.levelFromDb(-30, floorDb: -60), 0.5);
      expect(Pcm16.levelFromDb(0, floorDb: -60), 1);
      expect(Pcm16.levelFromDb(-160, floorDb: -60), 0);
      expect(Pcm16.levelFromDb(5, floorDb: -60), 1);
    });
  });

  group('formatElapsed', () {
    test('MM:SS below an hour, H:MM:SS above', () {
      expect(formatElapsed(Duration.zero), '00:00');
      expect(formatElapsed(const Duration(minutes: 3, seconds: 7)), '03:07');
      expect(formatElapsed(const Duration(hours: 1, minutes: 2, seconds: 3)), '1:02:03');
      expect(formatSeconds(65.4), '01:05');
    });
  });
}
