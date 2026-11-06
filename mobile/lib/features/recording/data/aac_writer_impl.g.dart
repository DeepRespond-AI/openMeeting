// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'aac_writer_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Creates one writer per recording. Override in tests with a fake factory.

@ProviderFor(aacWriterFactory)
final aacWriterFactoryProvider = AacWriterFactoryProvider._();

/// Creates one writer per recording. Override in tests with a fake factory.

final class AacWriterFactoryProvider
    extends
        $FunctionalProvider<
          AacWriterFactory,
          AacWriterFactory,
          AacWriterFactory
        >
    with $Provider<AacWriterFactory> {
  /// Creates one writer per recording. Override in tests with a fake factory.
  AacWriterFactoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'aacWriterFactoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aacWriterFactoryHash();

  @$internal
  @override
  $ProviderElement<AacWriterFactory> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AacWriterFactory create(Ref ref) {
    return aacWriterFactory(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AacWriterFactory value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AacWriterFactory>(value),
    );
  }
}

String _$aacWriterFactoryHash() => r'3377a700f9320c02a0bd73df5255ae3a7f17334d';
