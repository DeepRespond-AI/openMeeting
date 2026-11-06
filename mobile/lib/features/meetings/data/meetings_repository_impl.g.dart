// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meetings_repository_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Override in tests: `meetingsRepositoryProvider.overrideWithValue(FakeMeetingsRepository())`.

@ProviderFor(meetingsRepository)
final meetingsRepositoryProvider = MeetingsRepositoryProvider._();

/// Override in tests: `meetingsRepositoryProvider.overrideWithValue(FakeMeetingsRepository())`.

final class MeetingsRepositoryProvider
    extends
        $FunctionalProvider<
          MeetingsRepository,
          MeetingsRepository,
          MeetingsRepository
        >
    with $Provider<MeetingsRepository> {
  /// Override in tests: `meetingsRepositoryProvider.overrideWithValue(FakeMeetingsRepository())`.
  MeetingsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'meetingsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$meetingsRepositoryHash();

  @$internal
  @override
  $ProviderElement<MeetingsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MeetingsRepository create(Ref ref) {
    return meetingsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MeetingsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MeetingsRepository>(value),
    );
  }
}

String _$meetingsRepositoryHash() =>
    r'167837962ebc5a9f313bae0e725fe225d802840c';
