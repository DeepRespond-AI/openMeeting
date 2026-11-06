// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'summary_repository_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(summaryRepository)
final summaryRepositoryProvider = SummaryRepositoryProvider._();

final class SummaryRepositoryProvider
    extends
        $FunctionalProvider<
          SummaryRepository,
          SummaryRepository,
          SummaryRepository
        >
    with $Provider<SummaryRepository> {
  SummaryRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'summaryRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$summaryRepositoryHash();

  @$internal
  @override
  $ProviderElement<SummaryRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SummaryRepository create(Ref ref) {
    return summaryRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SummaryRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SummaryRepository>(value),
    );
  }
}

String _$summaryRepositoryHash() => r'e29a2528e0b3cdd61b6a3748586c5b63edf537a5';
