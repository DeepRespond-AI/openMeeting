import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meeting/core/config/app_config.dart';
import 'package:meeting/features/recording/domain/energy_vad.dart';

import '../../helpers/test_config.dart';
import 'signal.dart';

void main() {
  final config = loadConfigFile('dev');
  final vadConfig = config.vad;
  final sr = config.audio.sampleRate;
  final frame = sr * vadConfig.frameMs ~/ 1000;
  final frameSec = vadConfig.frameMs / 1000;
  final padSec = vadConfig.paddingMs / 1000;

  List<SpeechSegment> run(Uint8List audio, {VadConfig? cfg, int? chunkBytes}) {
    final vad = EnergyVad(config: cfg ?? vadConfig, sampleRate: sr);
    final out = <SpeechSegment>[];
    final step = chunkBytes ?? audio.length;
    for (var i = 0; i < audio.length; i += step) {
      out.addAll(vad.add(Uint8List.sublistView(audio, i, math.min(audio.length, i + step))));
    }
    out.addAll(vad.flush());
    return out;
  }

  test('pure silence yields no segments', () {
    expect(run(SignalBuilder(sr).silence(5).build()), isEmpty);
  });

  test('low-level noise alone yields no segments', () {
    expect(run(SignalBuilder(sr).noise(5, amp: 0.01).build()), isEmpty);
  });

  test('a tone between silences becomes one padded segment', () {
    final audio = SignalBuilder(sr).silence(1).tone(2).silence(1.5).build();
    final segments = run(audio);
    expect(segments, hasLength(1));
    final s = segments.single;
    expect(s.startSec, closeTo(1 - padSec, frameSec));
    expect(s.endSec, closeTo(3 + padSec, frameSec));
    expect(s.pcm.length, ((s.endSec - s.startSec) * sr).round() * 2);
  });

  test('the segment is emitted as soon as the silence exceeds silenceToEndMs', () {
    final vad = EnergyVad(config: vadConfig, sampleRate: sr);
    expect(vad.add(SignalBuilder(sr).silence(1).tone(1).build()), isEmpty);
    // Just under the end-of-speech silence: still open.
    final almost = (vadConfig.silenceToEndMs / 1000) - frameSec;
    expect(vad.add(SignalBuilder(sr).silence(almost).build()), isEmpty);
    expect(vad.add(SignalBuilder(sr).silence(2 * frameSec).build()), hasLength(1));
  });

  test('tone bursts in background noise are found, noise is not', () {
    final audio = SignalBuilder(sr).noise(1).tone(1).noise(1.5).tone(0.8).noise(1.5).build();
    final segments = run(audio);
    expect(segments, hasLength(2));
    expect(segments[0].startSec, closeTo(1 - padSec, frameSec * 2));
    expect(segments[1].startSec, closeTo(3.5 - padSec, frameSec * 2));
    expect(segments[1].endSec, closeTo(4.3 + padSec, frameSec * 2));
  });

  test('speech shorter than minSpeechMs is dropped', () {
    final audio = SignalBuilder(sr).silence(1).tone(0.15).silence(1).build();
    expect(run(audio), isEmpty);
    final longer = SignalBuilder(sr).silence(1).tone(0.45).silence(1).build();
    expect(run(longer), hasLength(1));
  });

  test('minSpeechMs comes from config', () {
    final audio = SignalBuilder(sr).silence(1).tone(0.45).silence(1).build();
    expect(run(audio, cfg: vadConfig.copyWith(minSpeechMs: 600)), isEmpty);
  });

  test('pauses shorter than silenceToEndMs keep one segment', () {
    final audio = SignalBuilder(sr).silence(1).tone(1).silence(0.3).tone(1).silence(1).build();
    expect(run(audio), hasLength(1));
  });

  test('flush closes an open segment at the end of the audio', () {
    final audio = SignalBuilder(sr).silence(1).tone(1.5).build();
    final segments = run(audio);
    expect(segments, hasLength(1));
    expect(segments.single.endSec, closeTo(2.5, 1e-9));
  });

  test('results do not depend on chunking (incl. odd byte splits)', () {
    final audio = SignalBuilder(sr)
        .silence(1)
        .tone(1.2)
        .noise(1)
        .tone(0.7, hz: 300)
        .silence(1)
        .build();
    final whole = run(audio);
    for (final chunk in [101, 320, 3333]) {
      final chunked = run(audio, chunkBytes: chunk);
      expect(chunked.length, whole.length, reason: 'chunk $chunk');
      for (var i = 0; i < whole.length; i++) {
        expect(chunked[i].startSec, whole[i].startSec);
        expect(chunked[i].endSec, whole[i].endSec);
        expect(chunked[i].pcm, whole[i].pcm);
      }
    }
  });

  group('maxSegmentSec', () {
    // Speech-like signal: 270 ms tone + 90 ms near-silence, repeated (gaps never end speech).
    SignalBuilder speech(SignalBuilder b, double seconds) {
      const cycle = 12; // frames: 9 tone + 3 quiet
      final cycles = (seconds / (cycle * frameSec)).floor();
      for (var c = 0; c < cycles; c++) {
        b.tone(9 * frameSec).noise(3 * frameSec, amp: 0.002);
      }
      return b;
    }

    test('long speech is split into segments no longer than maxSegmentSec', () {
      final b = SignalBuilder(sr).silence(1);
      final audio = speech(b, 70).silence(1).build();
      final segments = run(audio);
      expect(segments.length, greaterThanOrEqualTo(3));
      for (final s in segments) {
        expect(s.durationSec, lessThanOrEqualTo(vadConfig.maxSegmentSec + 1e-9));
      }
      // Consecutive split pieces are contiguous (no audio lost or duplicated).
      for (var i = 1; i < segments.length; i++) {
        expect(segments[i].startSec, closeTo(segments[i - 1].endSec, 1e-9));
      }
      expect(segments.first.startSec, closeTo(1 - padSec, frameSec));
    });

    test('splits at the quietest frame of the search window', () {
      // Everything frame-aligned: frame k covers samples [k * frame, (k + 1) * frame).
      const prefixFrames = 34;
      final segStartSec = prefixFrames * frameSec - padSec;
      final maxEndSec = segStartSec + vadConfig.maxSegmentSec;
      // One digital-silence frame 1 s before the max length (inside the search window).
      final quietFrame = ((maxEndSec - 1) / frameSec).floor();

      final b = SignalBuilder(sr).zeros(prefixFrames * frame);
      var f = prefixFrames;
      while (f < quietFrame) {
        // 9 tone frames, then 3 near-silent frames (never long enough to end speech).
        for (var i = 0; i < 9 && f < quietFrame; i++, f++) {
          b.tone(frameSec);
        }
        for (var i = 0; i < 3 && f < quietFrame; i++, f++) {
          b.noise(frameSec, amp: 0.002);
        }
      }
      expect(b.length, quietFrame * frame);
      b.zeros(frame);
      speech(b, 10).silence(1);

      final segments = run(b.build());
      expect(segments.length, greaterThanOrEqualTo(2));
      expect(segments.first.startSec, closeTo(segStartSec, 1e-9));
      final cut = (quietFrame * frame + frame ~/ 2) / sr;
      expect(segments.first.endSec, closeTo(cut, 1e-9));
      expect(segments[1].startSec, closeTo(cut, 1e-9));
    });
  });
}
