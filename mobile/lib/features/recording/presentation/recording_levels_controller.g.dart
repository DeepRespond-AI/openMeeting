// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recording_levels_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Recent input levels (0..1, oldest first) for the live waveform; length is
/// `AppConfig.recording.waveformBars`. Fed by `RecordingController`.

@ProviderFor(RecordingLevelsController)
final recordingLevelsControllerProvider = RecordingLevelsControllerProvider._();

/// Recent input levels (0..1, oldest first) for the live waveform; length is
/// `AppConfig.recording.waveformBars`. Fed by `RecordingController`.
final class RecordingLevelsControllerProvider
    extends $NotifierProvider<RecordingLevelsController, List<double>> {
  /// Recent input levels (0..1, oldest first) for the live waveform; length is
  /// `AppConfig.recording.waveformBars`. Fed by `RecordingController`.
  RecordingLevelsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recordingLevelsControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recordingLevelsControllerHash();

  @$internal
  @override
  RecordingLevelsController create() => RecordingLevelsController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<double> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<double>>(value),
    );
  }
}

String _$recordingLevelsControllerHash() =>
    r'8668bb051af18b6ba455ddd25b676424cc240a84';

/// Recent input levels (0..1, oldest first) for the live waveform; length is
/// `AppConfig.recording.waveformBars`. Fed by `RecordingController`.

abstract class _$RecordingLevelsController extends $Notifier<List<double>> {
  List<double> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<List<double>, List<double>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<double>, List<double>>,
              List<double>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
