// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recording_status.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(RecordingStatusController)
final recordingStatusControllerProvider = RecordingStatusControllerProvider._();

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
final class RecordingStatusControllerProvider
    extends $NotifierProvider<RecordingStatusController, RecordingStatus> {
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
  RecordingStatusControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recordingStatusControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recordingStatusControllerHash();

  @$internal
  @override
  RecordingStatusController create() => RecordingStatusController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecordingStatus value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecordingStatus>(value),
    );
  }
}

String _$recordingStatusControllerHash() =>
    r'af55e95f26e5f428e3c43cd0fad028e6c85c5f74';

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

abstract class _$RecordingStatusController extends $Notifier<RecordingStatus> {
  RecordingStatus build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<RecordingStatus, RecordingStatus>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RecordingStatus, RecordingStatus>,
              RecordingStatus,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
