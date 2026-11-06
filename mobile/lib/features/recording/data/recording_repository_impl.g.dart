// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recording_repository_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Override in tests with a fake.

@ProviderFor(recordingRepository)
final recordingRepositoryProvider = RecordingRepositoryProvider._();

/// Override in tests with a fake.

final class RecordingRepositoryProvider
    extends
        $FunctionalProvider<
          RecordingRepository,
          RecordingRepository,
          RecordingRepository
        >
    with $Provider<RecordingRepository> {
  /// Override in tests with a fake.
  RecordingRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recordingRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recordingRepositoryHash();

  @$internal
  @override
  $ProviderElement<RecordingRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RecordingRepository create(Ref ref) {
    return recordingRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecordingRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecordingRepository>(value),
    );
  }
}

String _$recordingRepositoryHash() =>
    r'963a86870ff782fc44a0b55d6c7fca0f4418835c';
