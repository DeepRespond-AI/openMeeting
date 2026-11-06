// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recording_storage.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(recordingStorage)
final recordingStorageProvider = RecordingStorageProvider._();

final class RecordingStorageProvider
    extends
        $FunctionalProvider<
          RecordingStorage,
          RecordingStorage,
          RecordingStorage
        >
    with $Provider<RecordingStorage> {
  RecordingStorageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recordingStorageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recordingStorageHash();

  @$internal
  @override
  $ProviderElement<RecordingStorage> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RecordingStorage create(Ref ref) {
    return recordingStorage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecordingStorage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecordingStorage>(value),
    );
  }
}

String _$recordingStorageHash() => r'46c1de8683f90766673d57e1b9898fc8cb5b9db5';
