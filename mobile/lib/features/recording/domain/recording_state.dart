import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/config/app_enums.dart';

part 'recording_state.freezed.dart';

/// One live transcript line returned for an uploaded segment.
@freezed
abstract class LiveTranscript with _$LiveTranscript {
  const factory LiveTranscript({
    required int seq,
    required String text,
    required double startSec,
    required double endSec,
  }) = _LiveTranscript;
}

/// Everything known about the recording in progress.
@freezed
abstract class RecordingSession with _$RecordingSession {
  const factory RecordingSession({
    required String meetingId,
    required String title,

    /// The user renamed the meeting during the recording → `PATCH` the title at stop.
    @Default(false) bool titleEdited,
    required RecordingSource source,

    /// Transcription language; `null` = auto-detect.
    String? language,

    /// Captured audio duration (pauses excluded).
    @Default(Duration.zero) Duration elapsed,

    /// Ordered by `seq`.
    @Default(<LiveTranscript>[]) List<LiveTranscript> transcripts,

    /// Segments waiting in the persistent upload queue (offline / server errors).
    @Default(0) int pendingUploads,

    /// Local `.m4a` path.
    required String audioPath,
  }) = _RecordingSession;
}

/// Where a failure happened (decides which recovery the UI offers).
enum RecordingErrorStage {
  /// Before capture started (permission, meeting creation); nothing to recover.
  start,

  /// While capturing; the recording was stopped and what was captured is kept.
  capture,
}

/// `RecordingController` state machine (DEVELOPMENT.md §2):
/// `idle → preparing → recording ⇄ paused → stopping → done | error`; the server sync after
/// Stop runs in the background (`RecordingController`, `MeetingSync`).
@freezed
sealed class RecordingState with _$RecordingState {
  const factory RecordingState.idle() = RecordingIdle;

  /// Requesting permission, creating the meeting, starting capture.
  const factory RecordingState.preparing({required RecordingSource source}) = RecordingPreparing;

  const factory RecordingState.recording({required RecordingSession session}) = RecordingActive;

  /// [interrupted] = paused by the system (phone call, another app took the microphone).
  const factory RecordingState.paused({
    required RecordingSession session,
    @Default(false) bool interrupted,
  }) = RecordingPaused;

  /// Capture stopped; submitting the last segment and finalizing the local audio file.
  const factory RecordingState.stopping({required RecordingSession session}) = RecordingStopping;

  /// Finished. [autoSummary] = the meeting page should start a summary.
  const factory RecordingState.done({required String meetingId, required bool autoSummary}) =
      RecordingDone;

  const factory RecordingState.error({
    required Object error,
    required RecordingErrorStage stage,
    RecordingSession? session,
  }) = RecordingError;

  const RecordingState._();

  RecordingSession? get session => switch (this) {
    RecordingActive(:final session) ||
    RecordingPaused(:final session) ||
    RecordingStopping(:final session) => session,
    RecordingError(:final session) => session,
    _ => null,
  };

  /// Capturing or paused — the recording can still be paused/resumed/stopped.
  bool get isLive => this is RecordingActive || this is RecordingPaused;

  /// A recording is underway in any phase (UI locks source/language pickers).
  bool get isBusy => this is RecordingPreparing || isLive || this is RecordingStopping;
}
