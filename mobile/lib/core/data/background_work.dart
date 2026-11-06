import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'background_work.freezed.dart';
part 'background_work.g.dart';

/// Meetings whose background work is still running: the sync after a recording was stopped
/// (remaining segments, audio upload) or the server transcription of an imported file
/// (desktop `recording_sync_pending`). The meeting page shows a "transcribing in the
/// background" state, reloads when the id leaves the set and holds the automatic summary.
@Riverpod(keepAlive: true)
class MeetingSync extends _$MeetingSync {
  @override
  Set<String> build() => const {};

  void begin(String meetingId) => state = {...state, meetingId};

  void end(String meetingId) => state = {...state}..remove(meetingId);
}

/// Outcome of background work, shown by the app shell as a SnackBar wherever the user is.
@freezed
sealed class BackgroundNotice with _$BackgroundNotice {
  /// The server finished transcribing an imported file.
  const factory BackgroundNotice.importTranscribed({
    required int id,
    required String meetingId,
    required String title,
    required int segments,
  }) = ImportTranscribedNotice;

  /// Transcribing an imported file failed; the server removed its meeting.
  /// [message] = server job error (already Chinese), `null` = request failure.
  const factory BackgroundNotice.importFailed({
    required int id,
    required String meetingId,
    required String title,
    String? message,
  }) = ImportFailedNotice;

  /// Uploading a stopped recording's audio failed; the local file is kept for a retry.
  const factory BackgroundNotice.recordingUploadFailed({
    required int id,
    required String meetingId,
  }) = RecordingUploadFailedNotice;
}

/// The latest [BackgroundNotice] (`null` until the first one). Each notice carries a fresh
/// [BackgroundNotice.id] so two equal outcomes in a row are both shown.
@Riverpod(keepAlive: true)
class BackgroundNotices extends _$BackgroundNotices {
  int _nextId = 0;

  @override
  BackgroundNotice? build() => null;

  /// Next notice id (pass it to the [BackgroundNotice] constructor).
  int nextId() => ++_nextId;

  void post(BackgroundNotice notice) => state = notice;
}
