// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recording_background_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(recordingBackground)
final recordingBackgroundProvider = RecordingBackgroundProvider._();

final class RecordingBackgroundProvider
    extends
        $FunctionalProvider<
          RecordingBackground,
          RecordingBackground,
          RecordingBackground
        >
    with $Provider<RecordingBackground> {
  RecordingBackgroundProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recordingBackgroundProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recordingBackgroundHash();

  @$internal
  @override
  $ProviderElement<RecordingBackground> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RecordingBackground create(Ref ref) {
    return recordingBackground(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecordingBackground value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecordingBackground>(value),
    );
  }
}

String _$recordingBackgroundHash() =>
    r'1316ac0f18c7886caa39b92270b2a4f59db6ee78';
