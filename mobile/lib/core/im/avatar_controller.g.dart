// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'avatar_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(avatarPicker)
final avatarPickerProvider = AvatarPickerProvider._();

final class AvatarPickerProvider
    extends
        $FunctionalProvider<
          Future<DRFile?> Function(),
          Future<DRFile?> Function(),
          Future<DRFile?> Function()
        >
    with $Provider<Future<DRFile?> Function()> {
  AvatarPickerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'avatarPickerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$avatarPickerHash();

  @$internal
  @override
  $ProviderElement<Future<DRFile?> Function()> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Future<DRFile?> Function() create(Ref ref) {
    return avatarPicker(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Future<DRFile?> Function() value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Future<DRFile?> Function()>(value),
    );
  }
}

String _$avatarPickerHash() => r'ae7b246537664ffa53582709687582e68b586570';

/// Upload through the same public-avatar SDK contract as desktop; publish the
/// profile only after upload completes. An old identity never saves a new one.

@ProviderFor(AvatarController)
final avatarControllerProvider = AvatarControllerProvider._();

/// Upload through the same public-avatar SDK contract as desktop; publish the
/// profile only after upload completes. An old identity never saves a new one.
final class AvatarControllerProvider
    extends $NotifierProvider<AvatarController, AvatarEditState> {
  /// Upload through the same public-avatar SDK contract as desktop; publish the
  /// profile only after upload completes. An old identity never saves a new one.
  AvatarControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'avatarControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$avatarControllerHash();

  @$internal
  @override
  AvatarController create() => AvatarController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AvatarEditState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AvatarEditState>(value),
    );
  }
}

String _$avatarControllerHash() => r'24e7237cb21fbf6197f98e2c1f8d1722cd5f6d9f';

/// Upload through the same public-avatar SDK contract as desktop; publish the
/// profile only after upload completes. An old identity never saves a new one.

abstract class _$AvatarController extends $Notifier<AvatarEditState> {
  AvatarEditState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AvatarEditState, AvatarEditState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AvatarEditState, AvatarEditState>,
              AvatarEditState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
