import 'package:freezed_annotation/freezed_annotation.dart';

part 'audio_playback.freezed.dart';

/// Platform audio player behind an interface so Notifiers can be tested with a fake
/// (the implementation wraps `just_audio`).
abstract interface class AudioPlaybackEngine {
  /// Loads [url] (sending [headers] with every request, incl. Range). Returns the duration.
  Future<Duration?> load(Uri url, {Map<String, String>? headers});

  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);
  Future<void> setSpeed(double speed);

  Stream<Duration> get positionStream;
  Stream<Duration?> get durationStream;
  Stream<bool> get playingStream;

  /// Emits when playback reached the end.
  Stream<void> get completedStream;

  Future<void> dispose();
}

enum PlayerStatus {
  /// Not loaded yet.
  idle,
  loading,
  ready,

  /// The meeting has no recording.
  unavailable,
  error,
}

/// Meeting audio player state.
@freezed
abstract class MeetingPlayerState with _$MeetingPlayerState {
  const factory MeetingPlayerState({
    @Default(PlayerStatus.idle) PlayerStatus status,
    @Default(false) bool playing,
    @Default(Duration.zero) Duration position,
    Duration? duration,

    /// Index into `AppConfig.player.speeds`.
    @Default(0) int speedIndex,
    Object? error,
  }) = _MeetingPlayerState;

  const MeetingPlayerState._();

  bool get isReady => status == PlayerStatus.ready;
}
