// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audio_sources.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The capture source for [kind]. The recording controller invalidates it after every
/// recording (which stops it), so each recording gets a fresh instance.

@ProviderFor(audioSource)
final audioSourceProvider = AudioSourceFamily._();

/// The capture source for [kind]. The recording controller invalidates it after every
/// recording (which stops it), so each recording gets a fresh instance.

final class AudioSourceProvider
    extends $FunctionalProvider<AudioSource, AudioSource, AudioSource>
    with $Provider<AudioSource> {
  /// The capture source for [kind]. The recording controller invalidates it after every
  /// recording (which stops it), so each recording gets a fresh instance.
  AudioSourceProvider._({
    required AudioSourceFamily super.from,
    required RecordingSource super.argument,
  }) : super(
         retry: null,
         name: r'audioSourceProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$audioSourceHash();

  @override
  String toString() {
    return r'audioSourceProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<AudioSource> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AudioSource create(Ref ref) {
    final argument = this.argument as RecordingSource;
    return audioSource(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AudioSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AudioSource>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AudioSourceProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$audioSourceHash() => r'6c77dac98388af4332e0875d1f5162aa49584d94';

/// The capture source for [kind]. The recording controller invalidates it after every
/// recording (which stops it), so each recording gets a fresh instance.

final class AudioSourceFamily extends $Family
    with $FunctionalFamilyOverride<AudioSource, RecordingSource> {
  AudioSourceFamily._()
    : super(
        retry: null,
        name: r'audioSourceProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// The capture source for [kind]. The recording controller invalidates it after every
  /// recording (which stops it), so each recording gets a fresh instance.

  AudioSourceProvider call(RecordingSource kind) =>
      AudioSourceProvider._(argument: kind, from: this);

  @override
  String toString() => r'audioSourceProvider';
}

/// Whether [kind] can be offered on this device (feature flag + OS support/permission).

@ProviderFor(audioSourceAvailability)
final audioSourceAvailabilityProvider = AudioSourceAvailabilityFamily._();

/// Whether [kind] can be offered on this device (feature flag + OS support/permission).

final class AudioSourceAvailabilityProvider
    extends
        $FunctionalProvider<
          AsyncValue<AudioSourceAvailability>,
          AudioSourceAvailability,
          FutureOr<AudioSourceAvailability>
        >
    with
        $FutureModifier<AudioSourceAvailability>,
        $FutureProvider<AudioSourceAvailability> {
  /// Whether [kind] can be offered on this device (feature flag + OS support/permission).
  AudioSourceAvailabilityProvider._({
    required AudioSourceAvailabilityFamily super.from,
    required RecordingSource super.argument,
  }) : super(
         retry: null,
         name: r'audioSourceAvailabilityProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$audioSourceAvailabilityHash();

  @override
  String toString() {
    return r'audioSourceAvailabilityProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<AudioSourceAvailability> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<AudioSourceAvailability> create(Ref ref) {
    final argument = this.argument as RecordingSource;
    return audioSourceAvailability(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is AudioSourceAvailabilityProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$audioSourceAvailabilityHash() =>
    r'd0a415cd045d09851d3832582dee4bd8f3be1c32';

/// Whether [kind] can be offered on this device (feature flag + OS support/permission).

final class AudioSourceAvailabilityFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<AudioSourceAvailability>,
          RecordingSource
        > {
  AudioSourceAvailabilityFamily._()
    : super(
        retry: null,
        name: r'audioSourceAvailabilityProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Whether [kind] can be offered on this device (feature flag + OS support/permission).

  AudioSourceAvailabilityProvider call(RecordingSource kind) =>
      AudioSourceAvailabilityProvider._(argument: kind, from: this);

  @override
  String toString() => r'audioSourceAvailabilityProvider';
}
