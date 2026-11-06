import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:system_audio_capture/system_audio_capture.dart';

/// Mocks the plugin's method + event channels on the test binary messenger.
class FakeNative {
  FakeNative() {
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(method, (call) async {
      calls.add(call);
      final handler = handlers[call.method];
      return handler == null ? null : await handler(call);
    });
    for (final entry in {
      'pcm': pcmChannel,
      'level': levelChannel,
      'events': eventChannel,
    }.entries) {
      messenger.setMockStreamHandler(
        entry.value,
        MockStreamHandler.inline(
          onListen: (_, sink) => sinks[entry.key] = sink,
          onCancel: (_) => sinks.remove(entry.key),
        ),
      );
    }
  }

  static const prefix = SystemAudioCapture.channelPrefix;
  static const method = MethodChannel('$prefix/method');
  static const pcmChannel = EventChannel('$prefix/pcm');
  static const levelChannel = EventChannel('$prefix/level');
  static const eventChannel = EventChannel('$prefix/events');

  final calls = <MethodCall>[];
  final handlers = <String, Future<Object?> Function(MethodCall)>{};
  final sinks = <String, MockStreamHandlerEventSink>{};

  List<String> get methods => calls.map((c) => c.method).toList();

  void dispose() {
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(method, null);
    for (final c in [pcmChannel, levelChannel, eventChannel]) {
      messenger.setMockStreamHandler(c, null);
    }
  }
}

SystemAudioStartOptions testStartOptions({bool mic = true}) => SystemAudioStartOptions(
  sampleRate: 16000,
  includeMicrophone: mic,
  micGain: 1,
  duckingRatio: 0.5,
  frameMs: 20,
  jitterBufferMs: 100,
  maxBufferMs: 1000,
  micActiveRmsThreshold: 0.01,
  duckingAttackMs: 50,
  duckingReleaseMs: 400,
  softClipKnee: 0.8,
  levelIntervalMs: 100,
  levelFloorDb: -60,
  androidCaptureUsages: const ['media'],
  androidMicSource: 'mic',
  androidFallbackCaptureSampleRate: 48000,
  androidNotificationChannelId: 'c',
  androidNotificationId: 1,
  iosChunkMs: 200,
  iosStartTimeoutMs: 1000,
  iosStopTimeoutMs: 1000,
  iosPollIntervalMs: 20,
  iosMaxPendingChunks: 10,
  iosKeepAliveInBackground: false,
  texts: const SystemAudioTexts(
    notificationChannelName: 'n',
    notificationTitle: 't',
    notificationText: 'x',
    broadcastStoppedByApp: 's',
    broadcastNotStartedFromApp: 'a',
  ),
);
