// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Distribution channel of this build (`APP_CHANNEL`); a provider so tests can override it.

@ProviderFor(updateChannel)
final updateChannelProvider = UpdateChannelProvider._();

/// Distribution channel of this build (`APP_CHANNEL`); a provider so tests can override it.

final class UpdateChannelProvider
    extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  /// Distribution channel of this build (`APP_CHANNEL`); a provider so tests can override it.
  UpdateChannelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'updateChannelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$updateChannelHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return updateChannel(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$updateChannelHash() => r'7f177c5e1e535da019e4eae3aa2ae64842335634';

@ProviderFor(updateClock)
final updateClockProvider = UpdateClockProvider._();

final class UpdateClockProvider
    extends
        $FunctionalProvider<
          DateTime Function(),
          DateTime Function(),
          DateTime Function()
        >
    with $Provider<DateTime Function()> {
  UpdateClockProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'updateClockProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$updateClockHash();

  @$internal
  @override
  $ProviderElement<DateTime Function()> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DateTime Function() create(Ref ref) {
    return updateClock(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime Function() value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime Function()>(value),
    );
  }
}

String _$updateClockHash() => r'ac0e13abc5435626ba8a23eb109da2bb0befe624';

/// App upgrades (server/API.md §1.8): checks on start-up, on resume and periodically
/// (throttled by `AppConfig.update.checkInterval`), and installs the offered release —
/// download + SHA-256 check + system installer for the Android `direct` build, the store page
/// otherwise. A forced offer blocks the app (route guard → force-update page).

@ProviderFor(UpdateController)
final updateControllerProvider = UpdateControllerProvider._();

/// App upgrades (server/API.md §1.8): checks on start-up, on resume and periodically
/// (throttled by `AppConfig.update.checkInterval`), and installs the offered release —
/// download + SHA-256 check + system installer for the Android `direct` build, the store page
/// otherwise. A forced offer blocks the app (route guard → force-update page).
final class UpdateControllerProvider
    extends $NotifierProvider<UpdateController, UpdateState> {
  /// App upgrades (server/API.md §1.8): checks on start-up, on resume and periodically
  /// (throttled by `AppConfig.update.checkInterval`), and installs the offered release —
  /// download + SHA-256 check + system installer for the Android `direct` build, the store page
  /// otherwise. A forced offer blocks the app (route guard → force-update page).
  UpdateControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'updateControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$updateControllerHash();

  @$internal
  @override
  UpdateController create() => UpdateController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UpdateState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UpdateState>(value),
    );
  }
}

String _$updateControllerHash() => r'c1f6403c3210cbc2c8879f9fdda5e1c2543fc617';

/// App upgrades (server/API.md §1.8): checks on start-up, on resume and periodically
/// (throttled by `AppConfig.update.checkInterval`), and installs the offered release —
/// download + SHA-256 check + system installer for the Android `direct` build, the store page
/// otherwise. A forced offer blocks the app (route guard → force-update page).

abstract class _$UpdateController extends $Notifier<UpdateState> {
  UpdateState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<UpdateState, UpdateState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<UpdateState, UpdateState>,
              UpdateState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
