import 'dart:typed_data';

import '../../../core/config/app_enums.dart';

/// Contract shared by every recording input (microphone via the `record` plugin,
/// system audio via the `system_audio_capture` plugin). Everything downstream —
/// VAD, AAC writer, segment upload — consumes [AudioSource.frames] and never
/// needs to know which source produced it.
abstract interface class AudioSource {
  RecordingSource get kind;

  /// What this device/OS can do for this source (checked before offering it in the UI).
  Future<AudioSourceAvailability> availability();

  /// Requests permissions / user consent (microphone permission, Android
  /// MediaProjection dialog, iOS broadcast picker) and starts capturing.
  /// Throws [AudioSourceException] when the user declines or the OS refuses.
  Future<void> start(AudioCaptureOptions options);

  Future<void> pause();
  Future<void> resume();

  /// Stops capturing and releases native resources. Idempotent.
  Future<void> stop();

  /// Mono PCM16 little-endian frames at [AudioCaptureOptions.sampleRate].
  /// Emits only while capturing; completes after [stop].
  Stream<Uint8List> get frames;

  /// Normalized input level 0..1, roughly every `audio.levelUpdateIntervalMs`.
  Stream<double> get level;

  /// Lifecycle events the controller must react to (interruption by a phone
  /// call, broadcast stopped from Control Center, projection revoked, ...).
  Stream<AudioSourceEvent> get events;
}

/// Capture parameters, all taken from `AppConfig` / user settings — never literals.
class AudioCaptureOptions {
  const AudioCaptureOptions({
    required this.sampleRate,
    required this.channels,
    this.includeMicrophone = true,
    this.micGain = 1.0,
    this.systemDuckingRatio = 1.0,
  });

  final int sampleRate;
  final int channels;

  /// System source only: mix the microphone in (desktop-like) or capture system audio alone.
  final bool includeMicrophone;

  /// System source only: gain applied to the microphone before mixing (`recording.systemAudioMicGain`).
  final double micGain;

  /// System source only: how much system audio is ducked while the mic is active
  /// (`recording.systemAudioDuckingRatio`).
  final double systemDuckingRatio;
}

enum AudioSourceAvailability {
  available,

  /// Supported, but needs a permission the user has not granted yet.
  needsPermission,

  /// Not possible on this OS version/device (e.g. Android < 10).
  unsupported,
}

sealed class AudioSourceEvent {
  const AudioSourceEvent();
}

/// Audio session interrupted (incoming call, another app took the mic). Controller should pause.
final class AudioSourceInterrupted extends AudioSourceEvent {
  const AudioSourceInterrupted();
}

/// Interruption ended; capture may resume.
final class AudioSourceInterruptionEnded extends AudioSourceEvent {
  const AudioSourceInterruptionEnded();
}

/// Capture ended outside the app's control (user stopped the iOS broadcast,
/// Android revoked the projection). Controller should stop the recording.
final class AudioSourceStoppedExternally extends AudioSourceEvent {
  const AudioSourceStoppedExternally({this.reason});
  final String? reason;
}

final class AudioSourceFailed extends AudioSourceEvent {
  const AudioSourceFailed(this.error);
  final AudioSourceException error;
}

enum AudioSourceErrorCode { permissionDenied, userCancelled, unsupported, busy, platform }

class AudioSourceException implements Exception {
  const AudioSourceException(this.code, [this.message]);
  final AudioSourceErrorCode code;
  final String? message;

  @override
  String toString() => 'AudioSourceException($code${message == null ? '' : ': $message'})';
}
