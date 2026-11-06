import 'dart:async';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meeting/core/config/app_config.dart';
import 'package:meeting/core/config/app_enums.dart';
import 'package:meeting/core/l10n/l10n.dart';
import 'package:meeting/features/recording/data/system_audio_source.dart';
import 'package:meeting/features/recording/domain/audio_source.dart';
import 'package:system_audio_capture/system_audio_capture.dart';

import '../../../helpers/test_config.dart';

/// Mocks the system_audio_capture method + event channels.
class _FakeNative {
  _FakeNative() {
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(_method, (call) async {
      calls.add(call);
      final handler = handlers[call.method];
      return handler == null ? null : await handler(call);
    });
    for (final name in ['pcm', 'level', 'events']) {
      messenger.setMockStreamHandler(
        EventChannel('${SystemAudioCapture.channelPrefix}/$name'),
        MockStreamHandler.inline(
          onListen: (_, sink) => sinks[name] = sink,
          onCancel: (_) => sinks.remove(name),
        ),
      );
    }
  }

  static const _method = MethodChannel('${SystemAudioCapture.channelPrefix}/method');

  final calls = <MethodCall>[];
  final handlers = <String, Future<Object?> Function(MethodCall)>{};
  final sinks = <String, MockStreamHandlerEventSink>{};

  List<String> get methods => calls.map((c) => c.method).toList();

  void dispose() {
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(_method, null);
    for (final name in ['pcm', 'level', 'events']) {
      messenger.setMockStreamHandler(
        EventChannel('${SystemAudioCapture.channelPrefix}/$name'),
        null,
      );
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeNative native;
  late AppConfig config;
  final l10n = lookupAppLocalizations(const Locale('zh'));

  AudioCaptureOptions options({bool mic = true}) => AudioCaptureOptions(
    sampleRate: config.audio.sampleRate,
    channels: config.audio.channels,
    includeMicrophone: mic,
    micGain: config.recording.systemAudioMicGain,
    systemDuckingRatio: config.recording.systemAudioDuckingRatio,
  );

  SystemAudioSource source([AppConfig? c]) => SystemAudioSource(config: c ?? config, l10n: l10n);

  setUp(() {
    native = _FakeNative();
    config = loadConfigFile('dev');
  });

  tearDown(() => native.dispose());

  test('kind is system', () => expect(source().kind, RecordingSource.system));

  group('availability', () {
    test('maps the plugin result', () async {
      final expected = {
        'available': AudioSourceAvailability.available,
        'needsPermission': AudioSourceAvailability.needsPermission,
        'unsupported': AudioSourceAvailability.unsupported,
      };
      for (final e in expected.entries) {
        native.handlers['availability'] = (_) async => e.key;
        expect(await source().availability(), e.value);
      }
    });

    test('feature flag off → unsupported without asking the platform', () async {
      final off = config.copyWith(features: config.features.copyWith(systemAudioCapture: false));
      expect(await source(off).availability(), AudioSourceAvailability.unsupported);
      await expectLater(
        source(off).start(options()),
        throwsA(
          isA<AudioSourceException>().having(
            (e) => e.code,
            'code',
            AudioSourceErrorCode.unsupported,
          ),
        ),
      );
      expect(native.calls, isEmpty);
    });
  });

  group('start', () {
    test('passes options from AudioCaptureOptions, AppConfig and l10n', () async {
      native.handlers['start'] = (_) async => {'mode': 'stream'};
      await source().start(options(mic: false));
      final args = native.calls.single.arguments as Map;
      final sa = config.systemAudio;
      expect(args['sampleRate'], config.audio.sampleRate);
      expect(args['includeMicrophone'], false);
      expect(args['micGain'], config.recording.systemAudioMicGain);
      expect(args['duckingRatio'], config.recording.systemAudioDuckingRatio);
      expect(args['levelIntervalMs'], config.audio.levelUpdateIntervalMs);
      expect(args['frameMs'], sa.frameMs);
      expect(args['androidCaptureUsages'], sa.androidCaptureUsages);
      expect(args['androidNotificationId'], sa.androidNotificationId);
      expect(args['iosChunkMs'], sa.iosChunkMs);
      expect(args['iosStartTimeoutMs'], sa.iosStartTimeoutMs);
      final texts = args['texts'] as Map;
      expect(texts['notificationTitle'], l10n.systemAudioNotificationTitle);
      expect(texts['broadcastStoppedByApp'], l10n.systemAudioBroadcastStoppedByApp);
    });

    final errors = {
      'permissionDenied': AudioSourceErrorCode.permissionDenied,
      'userCancelled': AudioSourceErrorCode.userCancelled,
      'unsupported': AudioSourceErrorCode.unsupported,
      'busy': AudioSourceErrorCode.busy,
      'platform': AudioSourceErrorCode.platform,
      'somethingNew': AudioSourceErrorCode.platform,
    };
    for (final e in errors.entries) {
      test('native ${e.key} → ${e.value.name}, source stays restartable', () async {
        final s = source();
        native.handlers['start'] = (_) async => throw PlatformException(code: e.key);
        await expectLater(
          s.start(options()),
          throwsA(isA<AudioSourceException>().having((x) => x.code, 'code', e.value)),
        );
        native.handlers['start'] = (_) async => {'mode': 'stream'};
        await s.start(options());
        await s.stop();
      });
    }

    test('second start while capturing → busy', () async {
      native.handlers['start'] = (_) async => {'mode': 'stream'};
      final s = source();
      await s.start(options());
      await expectLater(
        s.start(options()),
        throwsA(
          isA<AudioSourceException>().having((e) => e.code, 'code', AudioSourceErrorCode.busy),
        ),
      );
    });
  });

  test('frames, level and events are forwarded and mapped; streams complete on stop', () async {
    native.handlers['start'] = (_) async => {'mode': 'stream'};
    final s = source();
    final frames = <Uint8List>[];
    final levels = <double>[];
    final events = <AudioSourceEvent>[];
    final framesDone = Completer<void>();
    s.frames.listen(frames.add, onDone: framesDone.complete);
    s.level.listen(levels.add);
    s.events.listen(events.add);

    await s.start(options());
    native.sinks['pcm']!.success(Uint8List.fromList([1, 0, 2, 0]));
    native.sinks['level']!.success(0.25);
    final ev = native.sinks['events']!;
    ev.success({'type': 'interrupted'});
    ev.success({'type': 'interruptionEnded'});
    ev.success({'type': 'stoppedExternally', 'reason': 'projectionStopped'});
    ev.success({'type': 'failed', 'code': 'busy', 'message': 'mic busy'});
    await pumpEventQueue();

    expect(frames.single, [1, 0, 2, 0]);
    expect(levels.single, 0.25);
    expect(events[0], isA<AudioSourceInterrupted>());
    expect(events[1], isA<AudioSourceInterruptionEnded>());
    expect(
      events[2],
      isA<AudioSourceStoppedExternally>().having((e) => e.reason, 'reason', 'projectionStopped'),
    );
    expect(
      events[3],
      isA<AudioSourceFailed>()
          .having((e) => e.error.code, 'code', AudioSourceErrorCode.busy)
          .having((e) => e.error.message, 'message', 'mic busy'),
    );

    await s.stop();
    await framesDone.future;
  });

  test('frames/level/events emitted during start reach listeners subscribing afterwards', () async {
    late _FakeNative n;
    n = native;
    n.handlers['start'] = (_) async {
      // Native data arriving before `start` returns to the caller.
      n.sinks['pcm']!.success(Uint8List.fromList([9, 0]));
      n.sinks['level']!.success(0.5);
      n.sinks['events']!.success({'type': 'interrupted'});
      await pumpEventQueue();
      return {'mode': 'stream'};
    };
    final s = source();
    await s.start(options());
    final frames = <Uint8List>[];
    final levels = <double>[];
    final events = <AudioSourceEvent>[];
    s.frames.listen(frames.add);
    s.level.listen(levels.add);
    s.events.listen(events.add);
    native.sinks['pcm']!.success(Uint8List.fromList([8, 0]));
    await pumpEventQueue();
    expect(frames, [
      [9, 0],
      [8, 0],
    ]);
    expect(levels, [0.5]);
    expect(events.single, isA<AudioSourceInterrupted>());
    await s.stop();
  });

  test('pause/resume reach the platform and gate frames', () async {
    native.handlers['start'] = (_) async => {'mode': 'stream'};
    final s = source();
    final frames = <Uint8List>[];
    s.frames.listen(frames.add);
    await s.start(options());
    await s.pause();
    await s.pause(); // no duplicate call
    native.sinks['pcm']!.success(Uint8List.fromList([1, 0]));
    await pumpEventQueue();
    expect(frames, isEmpty);
    await s.resume();
    native.sinks['pcm']!.success(Uint8List.fromList([2, 0]));
    await pumpEventQueue();
    expect(frames.single, [2, 0]);
    expect(native.methods, ['start', 'pause', 'resume']);
  });

  test('stop is idempotent and a new session can start afterwards', () async {
    native.handlers['start'] = (_) async => {'mode': 'stream'};
    final s = source();
    await s.stop(); // before start: no-op
    expect(native.calls, isEmpty);

    await s.start(options());
    await Future.wait([s.stop(), s.stop()]);
    await s.stop();
    expect(native.methods.where((m) => m == 'stop'), hasLength(1));

    final frames = <Uint8List>[];
    await s.start(options());
    s.frames.listen(frames.add); // new session stream
    native.sinks['pcm']!.success(Uint8List.fromList([3, 0]));
    await pumpEventQueue();
    expect(frames.single, [3, 0]);
    await s.stop();
  });
}
