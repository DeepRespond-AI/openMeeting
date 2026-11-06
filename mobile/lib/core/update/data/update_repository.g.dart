// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(updateRepository)
final updateRepositoryProvider = UpdateRepositoryProvider._();

final class UpdateRepositoryProvider
    extends
        $FunctionalProvider<
          UpdateRepository,
          UpdateRepository,
          UpdateRepository
        >
    with $Provider<UpdateRepository> {
  UpdateRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'updateRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$updateRepositoryHash();

  @$internal
  @override
  $ProviderElement<UpdateRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  UpdateRepository create(Ref ref) {
    return updateRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UpdateRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UpdateRepository>(value),
    );
  }
}

String _$updateRepositoryHash() => r'33a7bb23fe743117a910df9f08a234573139a5b0';
