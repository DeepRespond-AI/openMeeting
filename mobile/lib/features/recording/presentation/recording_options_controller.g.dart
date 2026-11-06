// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recording_options_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Per-recording source/language selection. Starts from the effective settings and follows
/// them until the user picks something on the recording page.

@ProviderFor(RecordingOptionsController)
final recordingOptionsControllerProvider =
    RecordingOptionsControllerProvider._();

/// Per-recording source/language selection. Starts from the effective settings and follows
/// them until the user picks something on the recording page.
final class RecordingOptionsControllerProvider
    extends $NotifierProvider<RecordingOptionsController, RecordingOptions> {
  /// Per-recording source/language selection. Starts from the effective settings and follows
  /// them until the user picks something on the recording page.
  RecordingOptionsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recordingOptionsControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recordingOptionsControllerHash();

  @$internal
  @override
  RecordingOptionsController create() => RecordingOptionsController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecordingOptions value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecordingOptions>(value),
    );
  }
}

String _$recordingOptionsControllerHash() =>
    r'9efe70051f27748099a0c90d988d1a29be2962b1';

/// Per-recording source/language selection. Starts from the effective settings and follows
/// them until the user picks something on the recording page.

abstract class _$RecordingOptionsController
    extends $Notifier<RecordingOptions> {
  RecordingOptions build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<RecordingOptions, RecordingOptions>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RecordingOptions, RecordingOptions>,
              RecordingOptions,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
