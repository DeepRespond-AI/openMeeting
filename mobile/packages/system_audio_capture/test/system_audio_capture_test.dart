import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:system_audio_capture/src/system_audio_capture.dart' show pcm16Level;
import 'package:system_audio_capture/system_audio_capture.dart';

import 'fake_native.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeNative native;
  late SystemAudioCapture capture;

  setUp(() {
    native = FakeNative();
    capture = SystemAudioCapture();
  });

  tearDown(() => native.dispose());

  test('availability maps wire values', () async {
    for (final v in SystemAudioAvailability.values) {
      native.handlers['availability'] = (_) async => v.name;
      expect(await capture.availability(), v);
    }
    native.handlers['availability'] = (_) async => 'garbage';
    expect(await capture.availability(), SystemAudioAvailability.unsupported);
  });

  test('start sends all options and streams PCM/level until stopped', () async {
    native.handlers['start'] = (_) async => {'mode': 'stream'};
    final frames = <Uint8List>[];
    final levels = <double>[];
    capture.pcm.listen(frames.add);
    capture.level.listen(levels.add);

    await capture.start(testStartOptions());
    final args = native.calls.single.arguments as Map;
    expect(args['sampleRate'], 16000);
    expect(args['includeMicrophone'], true);
    expect(args['duckingRatio'], 0.5);
    expect((args['texts'] as Map)['notificationTitle'], 't');

    native.sinks['pcm']!.success(Uint8List.fromList([1, 2]));
    native.sinks['level']!.success(1.5);
    await pumpEventQueue();
    expect(frames.single, [1, 2]);
    expect(levels.single, 1.0); // clamped

    await capture.pause();
    native.sinks['pcm']!.success(Uint8List.fromList([3, 4]));
    await pumpEventQueue();
    expect(frames, hasLength(1)); // dropped while paused
    await capture.resume();

    await capture.stop();
    await capture.stop(); // idempotent
    expect(native.methods, ['start', 'pause', 'resume', 'stop']);
    expect(native.sinks, isEmpty); // native streams cancelled
    expect(capture.isCapturing, isFalse);
  });

  test('start failure maps the error code', () async {
    for (final code in SystemAudioErrorCode.values) {
      native.handlers['start'] = (_) async =>
          throw PlatformException(code: code.name, message: 'm');
      await expectLater(
        capture.start(testStartOptions()),
        throwsA(isA<SystemAudioCaptureException>().having((e) => e.code, 'code', code)),
      );
      expect(native.sinks, isEmpty);
    }
  });

  test('second start while capturing is busy', () async {
    native.handlers['start'] = (_) async => {'mode': 'stream'};
    await capture.start(testStartOptions());
    await expectLater(
      capture.start(testStartOptions()),
      throwsA(
        isA<SystemAudioCaptureException>().having((e) => e.code, 'code', SystemAudioErrorCode.busy),
      ),
    );
  });

  test('stop while waiting for consent asks native to cancel', () async {
    final consent = Completer<Object?>();
    native.handlers['start'] = (_) => consent.future;
    final start = capture.start(testStartOptions());
    await pumpEventQueue();
    native.handlers['stop'] = (_) async {
      consent.completeError(PlatformException(code: 'userCancelled'));
      return null;
    };
    await capture.stop();
    await expectLater(
      start,
      throwsA(
        isA<SystemAudioCaptureException>().having(
          (e) => e.code,
          'code',
          SystemAudioErrorCode.userCancelled,
        ),
      ),
    );
    expect(native.methods, ['start', 'stop']);
  });

  test('maps native events', () async {
    native.handlers['start'] = (_) async => {'mode': 'stream'};
    final events = <SystemAudioCaptureEvent>[];
    capture.events.listen(events.add);
    await capture.start(testStartOptions());
    final sink = native.sinks['events']!;
    sink.success({'type': 'interrupted'});
    sink.success({'type': 'interruptionEnded'});
    sink.success({'type': 'failed', 'code': 'busy', 'message': 'x'});
    sink.success({'type': 'stoppedExternally', 'reason': 'projectionStopped'});
    sink.success({'type': 'unknown'});
    await pumpEventQueue();
    expect(events[0], isA<SystemAudioInterrupted>());
    expect(events[1], isA<SystemAudioInterruptionEnded>());
    expect(
      events[2],
      isA<SystemAudioFailed>().having((e) => e.error.code, 'code', SystemAudioErrorCode.busy),
    );
    expect(
      events[3],
      isA<SystemAudioStoppedExternally>().having((e) => e.reason, 'reason', 'projectionStopped'),
    );
    expect(events, hasLength(4));
  });

  group('iOS chunk mode', () {
    late Directory dir;

    setUp(() => dir = Directory.systemTemp.createTempSync('broadcast'));
    tearDown(() {
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    });

    void write(int i, List<int> bytes) =>
        File('${dir.path}/chunk_${i.toString().padLeft(12, '0')}.pcm').writeAsBytesSync(bytes);

    test('reads chunks on notification, emits level, drains and clears on stop', () async {
      native.handlers['start'] = (_) async => {'mode': 'chunks', 'directory': dir.path};
      final frames = <Uint8List>[];
      final levels = <double>[];
      capture.pcm.listen(frames.add);
      capture.level.listen(levels.add);
      await capture.start(testStartOptions());

      write(0, [0, 64, 0, 64]); // two samples of 0.5
      native.sinks['events']!.success({'type': 'chunksAvailable'});
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(frames.single, [0, 64, 0, 64]);
      expect(levels.single, closeTo(pcm16Level(frames.single, -60), 1e-9));

      write(1, [1, 0]);
      await capture.stop(); // final drain
      expect(frames.last, [1, 0]);
      expect(dir.listSync(), isEmpty);
    });

    test('stoppedExternally is emitted after the remaining chunks', () async {
      native.handlers['start'] = (_) async => {'mode': 'chunks', 'directory': dir.path};
      final order = <String>[];
      capture.pcm.listen((_) => order.add('pcm'));
      capture.events.listen((e) => order.add(e.runtimeType.toString()));
      await capture.start(testStartOptions());
      write(0, [1, 0]);
      native.sinks['events']!.success({'type': 'stoppedExternally', 'reason': 'user'});
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(order, ['pcm', 'SystemAudioStoppedExternally']);
    });
  });

  test('pcm16Level maps dBFS onto 0..1', () {
    Uint8List constant(int v) {
      final b = ByteData(200);
      for (var i = 0; i < 100; i++) {
        b.setInt16(i * 2, v, Endian.little);
      }
      return b.buffer.asUint8List();
    }

    expect(pcm16Level(constant(0), -60), 0);
    expect(pcm16Level(constant(32767), -60), closeTo(1, 1e-3));
    expect(pcm16Level(constant(328), -60), closeTo(1 / 3, 0.01)); // ≈ -40 dBFS
    expect(pcm16Level(Uint8List(0), -60), 0);
  });
}
