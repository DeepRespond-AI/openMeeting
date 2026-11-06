// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recording_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Clock used for the meeting title; overridable in tests.

@ProviderFor(recordingClock)
final recordingClockProvider = RecordingClockProvider._();

/// Clock used for the meeting title; overridable in tests.

final class RecordingClockProvider
    extends
        $FunctionalProvider<
          DateTime Function(),
          DateTime Function(),
          DateTime Function()
        >
    with $Provider<DateTime Function()> {
  /// Clock used for the meeting title; overridable in tests.
  RecordingClockProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recordingClockProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recordingClockHash();

  @$internal
  @override
  $ProviderElement<DateTime Function()> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DateTime Function() create(Ref ref) {
    return recordingClock(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime Function() value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime Function()>(value),
    );
  }
}

String _$recordingClockHash() => r'b24b318d4f37afbf9220d8a3aafa346d765ffa91';

/// The recording flow (DEVELOPMENT.md §2): one global state machine that aggregates the audio
/// source, VAD, segment uploader and AAC writer. Pages and the notification only observe it.
///
/// `idle → preparing → recording ⇄ paused → stopping → done | error`
///
/// - start: create the meeting (`POST /meetings`), open the m4a writer, start the foreground
///   service and capture; every frame goes to the AAC writer and the streaming VAD, whose
///   segments are uploaded live (results → [RecordingSession.transcripts]).
/// - stop: stop capture, submit the VAD tail and finalize the local m4a, then [RecordingDone]
///   right away (the page navigates to the meeting). The rest runs in the background while
///   the meeting is marked in [MeetingSync] (desktop `finish_meeting_sync`): apply a rename,
///   flush the segment queue, upload the audio (`PUT /meetings/{id}/audio`,
///   `AppConfig.network.audioUploadRetry`). A failed upload keeps the local file and posts a
///   [BackgroundNotice.recordingUploadFailed]; [retryUpload] tries again.

@ProviderFor(RecordingController)
final recordingControllerProvider = RecordingControllerProvider._();

/// The recording flow (DEVELOPMENT.md §2): one global state machine that aggregates the audio
/// source, VAD, segment uploader and AAC writer. Pages and the notification only observe it.
///
/// `idle → preparing → recording ⇄ paused → stopping → done | error`
///
/// - start: create the meeting (`POST /meetings`), open the m4a writer, start the foreground
///   service and capture; every frame goes to the AAC writer and the streaming VAD, whose
///   segments are uploaded live (results → [RecordingSession.transcripts]).
/// - stop: stop capture, submit the VAD tail and finalize the local m4a, then [RecordingDone]
///   right away (the page navigates to the meeting). The rest runs in the background while
///   the meeting is marked in [MeetingSync] (desktop `finish_meeting_sync`): apply a rename,
///   flush the segment queue, upload the audio (`PUT /meetings/{id}/audio`,
///   `AppConfig.network.audioUploadRetry`). A failed upload keeps the local file and posts a
///   [BackgroundNotice.recordingUploadFailed]; [retryUpload] tries again.
final class RecordingControllerProvider
    extends $NotifierProvider<RecordingController, RecordingState> {
  /// The recording flow (DEVELOPMENT.md §2): one global state machine that aggregates the audio
  /// source, VAD, segment uploader and AAC writer. Pages and the notification only observe it.
  ///
  /// `idle → preparing → recording ⇄ paused → stopping → done | error`
  ///
  /// - start: create the meeting (`POST /meetings`), open the m4a writer, start the foreground
  ///   service and capture; every frame goes to the AAC writer and the streaming VAD, whose
  ///   segments are uploaded live (results → [RecordingSession.transcripts]).
  /// - stop: stop capture, submit the VAD tail and finalize the local m4a, then [RecordingDone]
  ///   right away (the page navigates to the meeting). The rest runs in the background while
  ///   the meeting is marked in [MeetingSync] (desktop `finish_meeting_sync`): apply a rename,
  ///   flush the segment queue, upload the audio (`PUT /meetings/{id}/audio`,
  ///   `AppConfig.network.audioUploadRetry`). A failed upload keeps the local file and posts a
  ///   [BackgroundNotice.recordingUploadFailed]; [retryUpload] tries again.
  RecordingControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recordingControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recordingControllerHash();

  @$internal
  @override
  RecordingController create() => RecordingController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecordingState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecordingState>(value),
    );
  }
}

String _$recordingControllerHash() =>
    r'e9130176dc8db9afc05a3f62243beec98b3d7986';

/// The recording flow (DEVELOPMENT.md §2): one global state machine that aggregates the audio
/// source, VAD, segment uploader and AAC writer. Pages and the notification only observe it.
///
/// `idle → preparing → recording ⇄ paused → stopping → done | error`
///
/// - start: create the meeting (`POST /meetings`), open the m4a writer, start the foreground
///   service and capture; every frame goes to the AAC writer and the streaming VAD, whose
///   segments are uploaded live (results → [RecordingSession.transcripts]).
/// - stop: stop capture, submit the VAD tail and finalize the local m4a, then [RecordingDone]
///   right away (the page navigates to the meeting). The rest runs in the background while
///   the meeting is marked in [MeetingSync] (desktop `finish_meeting_sync`): apply a rename,
///   flush the segment queue, upload the audio (`PUT /meetings/{id}/audio`,
///   `AppConfig.network.audioUploadRetry`). A failed upload keeps the local file and posts a
///   [BackgroundNotice.recordingUploadFailed]; [retryUpload] tries again.

abstract class _$RecordingController extends $Notifier<RecordingState> {
  RecordingState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<RecordingState, RecordingState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RecordingState, RecordingState>,
              RecordingState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
