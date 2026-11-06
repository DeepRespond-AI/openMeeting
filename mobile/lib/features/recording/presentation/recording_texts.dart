import '../../../core/api/api_exception_l10n.dart';
import '../../../core/l10n/l10n.dart';
import '../domain/audio_source.dart';
import '../domain/recording_state.dart';

/// User-facing text for a recording failure: capture errors get recording-specific text,
/// everything else goes through the API error mapping.
String describeRecordingError(Object error, AppLocalizations l10n) => switch (error) {
  AudioSourceException(code: AudioSourceErrorCode.permissionDenied) =>
    l10n.recordingErrorPermission,
  AudioSourceException(code: AudioSourceErrorCode.userCancelled) => l10n.recordingErrorCancelled,
  AudioSourceException(code: AudioSourceErrorCode.unsupported) => l10n.recordingErrorUnsupported,
  AudioSourceException(code: AudioSourceErrorCode.busy) => l10n.recordingErrorBusy,
  AudioSourceException(code: AudioSourceErrorCode.platform) => l10n.recordingErrorPlatform,
  _ => describeError(error, l10n),
};

/// Status chip text.
String recordingStatusLabel(RecordingState state, AppLocalizations l10n) => switch (state) {
  RecordingIdle() => l10n.recordingStatusIdle,
  RecordingPreparing() => l10n.recordingStatusPreparing,
  RecordingActive() => l10n.recordingStatusRecording,
  RecordingPaused(interrupted: true) => l10n.recordingStatusInterrupted,
  RecordingPaused() => l10n.recordingStatusPaused,
  RecordingStopping() => l10n.recordingStatusStopping,
  RecordingDone() => l10n.recordingStatusDone,
  RecordingError() => l10n.recordingStatusError,
};
