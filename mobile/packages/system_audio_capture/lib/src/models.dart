import 'package:flutter/foundation.dart';

/// What the device/OS can do for system-audio capture.
enum SystemAudioAvailability {
  available,

  /// Supported, but a runtime permission (Android `RECORD_AUDIO`) is not granted yet.
  needsPermission,

  /// Not possible here (Android < 10, iOS simulator, broadcast extension missing).
  unsupported,
}

/// Error codes reported by the native side (string values are the wire format).
enum SystemAudioErrorCode {
  permissionDenied,
  userCancelled,
  unsupported,
  busy,
  platform;

  static SystemAudioErrorCode fromWire(String? code) {
    for (final c in values) {
      if (c.name == code) return c;
    }
    return SystemAudioErrorCode.platform;
  }
}

class SystemAudioCaptureException implements Exception {
  const SystemAudioCaptureException(this.code, [this.message]);

  final SystemAudioErrorCode code;
  final String? message;

  @override
  String toString() =>
      'SystemAudioCaptureException(${code.name}${message == null ? '' : ': $message'})';
}

/// Lifecycle events from the native capture.
@immutable
sealed class SystemAudioCaptureEvent {
  const SystemAudioCaptureEvent();
}

/// Capture is temporarily silenced by the OS (incoming call, broadcast paused).
final class SystemAudioInterrupted extends SystemAudioCaptureEvent {
  const SystemAudioInterrupted();
}

final class SystemAudioInterruptionEnded extends SystemAudioCaptureEvent {
  const SystemAudioInterruptionEnded();
}

/// Capture ended outside the app (projection revoked, broadcast stopped from Control Center).
final class SystemAudioStoppedExternally extends SystemAudioCaptureEvent {
  const SystemAudioStoppedExternally(this.reason);
  final String? reason;
}

final class SystemAudioFailed extends SystemAudioCaptureEvent {
  const SystemAudioFailed(this.error);
  final SystemAudioCaptureException error;
}

/// Texts shown by the OS on behalf of the capture (Android foreground-service
/// notification, iOS broadcast end alert). Supplied by the app's l10n.
@immutable
class SystemAudioTexts {
  const SystemAudioTexts({
    required this.notificationChannelName,
    required this.notificationTitle,
    required this.notificationText,
    required this.broadcastStoppedByApp,
    required this.broadcastNotStartedFromApp,
  });

  final String notificationChannelName;
  final String notificationTitle;
  final String notificationText;

  /// iOS: message of the alert iOS shows when the app ends the broadcast.
  final String broadcastStoppedByApp;

  /// iOS: shown when a broadcast is started from Control Center without the app arming it.
  final String broadcastNotStartedFromApp;

  Map<String, Object?> toMap() => {
    'notificationChannelName': notificationChannelName,
    'notificationTitle': notificationTitle,
    'notificationText': notificationText,
    'broadcastStoppedByApp': broadcastStoppedByApp,
    'broadcastNotStartedFromApp': broadcastNotStartedFromApp,
  };
}

/// All parameters of one capture session. Every value comes from the app's
/// configuration — the plugin has no built-in tunables.
@immutable
class SystemAudioStartOptions {
  const SystemAudioStartOptions({
    required this.sampleRate,
    required this.includeMicrophone,
    required this.micGain,
    required this.duckingRatio,
    required this.frameMs,
    required this.jitterBufferMs,
    required this.maxBufferMs,
    required this.micActiveRmsThreshold,
    required this.duckingAttackMs,
    required this.duckingReleaseMs,
    required this.softClipKnee,
    required this.levelIntervalMs,
    required this.levelFloorDb,
    required this.androidCaptureUsages,
    required this.androidMicSource,
    required this.androidFallbackCaptureSampleRate,
    required this.androidNotificationChannelId,
    required this.androidNotificationId,
    required this.iosChunkMs,
    required this.iosStartTimeoutMs,
    required this.iosStopTimeoutMs,
    required this.iosPollIntervalMs,
    required this.iosMaxPendingChunks,
    required this.iosKeepAliveInBackground,
    required this.texts,
  });

  /// Output sample rate (mono PCM16 LE).
  final int sampleRate;
  final bool includeMicrophone;
  final double micGain;

  /// System-audio gain while the microphone carries speech (0..1).
  final double duckingRatio;

  /// Mixer frame duration.
  final int frameMs;

  /// Mixer latency used to absorb bursty delivery of the two inputs.
  final int jitterBufferMs;

  /// Per-input backlog cap; older samples are dropped beyond it.
  final int maxBufferMs;

  /// Mic RMS (0..1) above which the mic counts as active for ducking.
  final double micActiveRmsThreshold;
  final int duckingAttackMs;
  final int duckingReleaseMs;

  /// Soft-clip knee (0..1); samples above it are compressed smoothly towards ±1.
  final double softClipKnee;
  final int levelIntervalMs;

  /// dBFS mapped to level 0 (0 dBFS = level 1).
  final double levelFloorDb;

  /// Android `AudioAttributes` usages to capture: `media`, `game`, `unknown`.
  final List<String> androidCaptureUsages;

  /// Android mic source: `voiceRecognition` | `mic` | `voiceCommunication` | `camcorder`.
  final String androidMicSource;

  /// Rate used when the device refuses to capture directly at [sampleRate].
  final int androidFallbackCaptureSampleRate;
  final String androidNotificationChannelId;
  final int androidNotificationId;

  /// iOS: duration of each chunk file written by the broadcast extension.
  final int iosChunkMs;

  /// iOS: how long to wait for the user to start the broadcast.
  final int iosStartTimeoutMs;

  /// iOS: how long to wait for the extension to confirm it stopped.
  final int iosStopTimeoutMs;

  /// iOS: chunk polling interval (in addition to Darwin notifications).
  final int iosPollIntervalMs;

  /// iOS: chunks the extension keeps before dropping the oldest unread ones.
  final int iosMaxPendingChunks;

  /// iOS: keep the app alive in the background with a silent audio session while capturing.
  final bool iosKeepAliveInBackground;

  final SystemAudioTexts texts;

  Map<String, Object?> toMap() => {
    'sampleRate': sampleRate,
    'includeMicrophone': includeMicrophone,
    'micGain': micGain,
    'duckingRatio': duckingRatio,
    'frameMs': frameMs,
    'jitterBufferMs': jitterBufferMs,
    'maxBufferMs': maxBufferMs,
    'micActiveRmsThreshold': micActiveRmsThreshold,
    'duckingAttackMs': duckingAttackMs,
    'duckingReleaseMs': duckingReleaseMs,
    'softClipKnee': softClipKnee,
    'levelIntervalMs': levelIntervalMs,
    'levelFloorDb': levelFloorDb,
    'androidCaptureUsages': androidCaptureUsages,
    'androidMicSource': androidMicSource,
    'androidFallbackCaptureSampleRate': androidFallbackCaptureSampleRate,
    'androidNotificationChannelId': androidNotificationChannelId,
    'androidNotificationId': androidNotificationId,
    'iosChunkMs': iosChunkMs,
    'iosStartTimeoutMs': iosStartTimeoutMs,
    'iosStopTimeoutMs': iosStopTimeoutMs,
    'iosPollIntervalMs': iosPollIntervalMs,
    'iosMaxPendingChunks': iosMaxPendingChunks,
    'iosKeepAliveInBackground': iosKeepAliveInBackground,
    'texts': texts.toMap(),
  };
}
