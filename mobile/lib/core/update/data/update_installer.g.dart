// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_installer.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(updateInstaller)
final updateInstallerProvider = UpdateInstallerProvider._();

final class UpdateInstallerProvider
    extends
        $FunctionalProvider<UpdateInstaller, UpdateInstaller, UpdateInstaller>
    with $Provider<UpdateInstaller> {
  UpdateInstallerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'updateInstallerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$updateInstallerHash();

  @$internal
  @override
  $ProviderElement<UpdateInstaller> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  UpdateInstaller create(Ref ref) {
    return updateInstaller(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UpdateInstaller value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UpdateInstaller>(value),
    );
  }
}

String _$updateInstallerHash() => r'15c40164d698dcbe1b8d7d3c1614c4f219682518';
