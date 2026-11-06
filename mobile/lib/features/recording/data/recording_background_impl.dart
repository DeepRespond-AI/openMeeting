import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/config/app_config_provider.dart';
import '../domain/recording_background.dart';

part 'recording_background_impl.g.dart';

/// Messages between the foreground-service isolate and the app.
abstract final class _Msg {
  static const String stopButtonId = 'stop';
  static const String stopRequested = 'recording.stop';
}

@pragma('vm:entry-point')
void recordingTaskCallback() => FlutterForegroundTask.setTaskHandler(_RecordingTaskHandler());

/// Runs in the service isolate; only forwards the notification's stop action to the app.
class _RecordingTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  @override
  void onNotificationButtonPressed(String id) {
    if (id == _Msg.stopButtonId) FlutterForegroundTask.sendDataToMain(_Msg.stopRequested);
  }

  @override
  void onNotificationPressed() => FlutterForegroundTask.launchApp();
}

/// Android: `flutter_foreground_task` service of type `microphone` with an ongoing
/// notification (elapsed time + stop action). iOS: no-op — the `audio` background mode keeps
/// the active AVAudioSession recording.
class ForegroundTaskRecordingBackground implements RecordingBackground {
  ForegroundTaskRecordingBackground({required this.channelId, required this.serviceId});

  final String channelId;
  final int serviceId;
  final StreamController<void> _stops = StreamController<void>.broadcast();
  bool _running = false;

  bool get _supported => Platform.isAndroid;

  @override
  Stream<void> get stopRequests => _stops.stream;

  @override
  Future<void> start({
    required String channelName,
    required String title,
    required String text,
    required String stopLabel,
  }) async {
    if (!_supported) return;
    try {
      FlutterForegroundTask.initCommunicationPort();
      FlutterForegroundTask.addTaskDataCallback(_onData);
      if (await FlutterForegroundTask.checkNotificationPermission() !=
          NotificationPermission.granted) {
        await FlutterForegroundTask.requestNotificationPermission();
      }
      FlutterForegroundTask.init(
        androidNotificationOptions: AndroidNotificationOptions(
          channelId: channelId,
          channelName: channelName,
          onlyAlertOnce: true,
        ),
        iosNotificationOptions: const IOSNotificationOptions(showNotification: false),
        foregroundTaskOptions: ForegroundTaskOptions(
          eventAction: ForegroundTaskEventAction.nothing(),
          allowWakeLock: true,
          stopWithTask: true,
        ),
      );
      if (await FlutterForegroundTask.isRunningService) await FlutterForegroundTask.stopService();
      final result = await FlutterForegroundTask.startService(
        serviceId: serviceId,
        serviceTypes: [ForegroundServiceTypes.microphone],
        notificationTitle: title,
        notificationText: text,
        notificationButtons: [NotificationButton(id: _Msg.stopButtonId, text: stopLabel)],
        callback: recordingTaskCallback,
      );
      _running = result is ServiceRequestSuccess;
      if (result case ServiceRequestFailure(:final error)) {
        debugPrint('Recording foreground service failed to start: $error');
      }
    } on Object catch (e) {
      debugPrint('Recording foreground service failed to start: $e');
    }
  }

  @override
  Future<void> update({required String text}) async {
    if (!_running) return;
    await FlutterForegroundTask.updateService(notificationText: text);
  }

  @override
  Future<void> stop() async {
    if (!_supported) return;
    FlutterForegroundTask.removeTaskDataCallback(_onData);
    if (!_running) return;
    _running = false;
    await FlutterForegroundTask.stopService();
  }

  void _onData(Object data) {
    if (data == _Msg.stopRequested) _stops.add(null);
  }
}

@Riverpod(keepAlive: true)
RecordingBackground recordingBackground(Ref ref) {
  final config = ref.watch(appConfigProvider).recording;
  return ForegroundTaskRecordingBackground(
    channelId: config.notificationChannelId,
    serviceId: config.foregroundServiceId,
  );
}
