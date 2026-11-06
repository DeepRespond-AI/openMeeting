// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'just_audio_engine.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Creates a new player per meeting page. Override in tests with a fake factory.

@ProviderFor(audioPlaybackEngineFactory)
final audioPlaybackEngineFactoryProvider =
    AudioPlaybackEngineFactoryProvider._();

/// Creates a new player per meeting page. Override in tests with a fake factory.

final class AudioPlaybackEngineFactoryProvider
    extends
        $FunctionalProvider<
          AudioPlaybackEngine Function(),
          AudioPlaybackEngine Function(),
          AudioPlaybackEngine Function()
        >
    with $Provider<AudioPlaybackEngine Function()> {
  /// Creates a new player per meeting page. Override in tests with a fake factory.
  AudioPlaybackEngineFactoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'audioPlaybackEngineFactoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$audioPlaybackEngineFactoryHash();

  @$internal
  @override
  $ProviderElement<AudioPlaybackEngine Function()> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AudioPlaybackEngine Function() create(Ref ref) {
    return audioPlaybackEngineFactory(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AudioPlaybackEngine Function() value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AudioPlaybackEngine Function()>(
        value,
      ),
    );
  }
}

String _$audioPlaybackEngineFactoryHash() =>
    r'76566dab00dcac821c4ed1b4d6ac6643d5c11f1c';
