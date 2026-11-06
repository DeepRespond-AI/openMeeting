// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'permission_handler_microphone_permission.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(microphonePermissionRepository)
final microphonePermissionRepositoryProvider =
    MicrophonePermissionRepositoryProvider._();

final class MicrophonePermissionRepositoryProvider
    extends
        $FunctionalProvider<
          MicrophonePermissionRepository,
          MicrophonePermissionRepository,
          MicrophonePermissionRepository
        >
    with $Provider<MicrophonePermissionRepository> {
  MicrophonePermissionRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'microphonePermissionRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$microphonePermissionRepositoryHash();

  @$internal
  @override
  $ProviderElement<MicrophonePermissionRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MicrophonePermissionRepository create(Ref ref) {
    return microphonePermissionRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MicrophonePermissionRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MicrophonePermissionRepository>(
        value,
      ),
    );
  }
}

String _$microphonePermissionRepositoryHash() =>
    r'41037227fb6b22cd04a06ccfc0ef6f9919768b04';
