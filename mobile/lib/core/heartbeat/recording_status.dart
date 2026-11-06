import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'recording_status.freezed.dart';
part 'recording_status.g.dart';

/// What the heartbeat reports about recording (`recording`, `meeting_id`).
@freezed
abstract class RecordingStatus with _$RecordingStatus {
  const factory RecordingStatus({@Default(false) bool recording, String? meetingId}) =
      _RecordingStatus;
}

/// Injection point between the recording feature and the heartbeat (core must not
/// import features). Defaults to idle.
///
/// The recording feature's `RecordingController` pushes its state here:
/// ```dart
/// ref.read(recordingStatusControllerProvider.notifier).set(recording: true, meetingId: id);
/// ref.read(recordingStatusControllerProvider.notifier).setIdle();
/// ```
/// A change of `recording` triggers an immediate heartbeat. While recording, the
/// heartbeat keeps the foreground interval even when the app is in the background.
@Riverpod(keepAlive: true)
class RecordingStatusController extends _$RecordingStatusController {
  @override
  RecordingStatus build() => const RecordingStatus();

  void set({required bool recording, String? meetingId}) =>
      state = RecordingStatus(recording: recording, meetingId: meetingId);

  void setIdle() => state = const RecordingStatus();
}
