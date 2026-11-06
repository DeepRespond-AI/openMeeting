// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// App version shown in "About" (same value that is reported to the server).

@ProviderFor(settingsAppVersion)
final settingsAppVersionProvider = SettingsAppVersionProvider._();

/// App version shown in "About" (same value that is reported to the server).

final class SettingsAppVersionProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  /// App version shown in "About" (same value that is reported to the server).
  SettingsAppVersionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsAppVersionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsAppVersionHash();

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    return settingsAppVersion(ref);
  }
}

String _$settingsAppVersionHash() =>
    r'e68659a7cb2bf6b480e9b59c9d25d4d8a25d99d4';

/// The signed-in user's phone, masked per `AppConfig.auth.phoneMask*`; null when unknown.

@ProviderFor(maskedPhone)
final maskedPhoneProvider = MaskedPhoneProvider._();

/// The signed-in user's phone, masked per `AppConfig.auth.phoneMask*`; null when unknown.

final class MaskedPhoneProvider
    extends $FunctionalProvider<String?, String?, String?>
    with $Provider<String?> {
  /// The signed-in user's phone, masked per `AppConfig.auth.phoneMask*`; null when unknown.
  MaskedPhoneProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'maskedPhoneProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$maskedPhoneHash();

  @$internal
  @override
  $ProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String? create(Ref ref) {
    return maskedPhone(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$maskedPhoneHash() => r'552f5e6f454935b430134a698647287461312569';

/// True while recording: logout and server changes are disabled.

@ProviderFor(settingsLocked)
final settingsLockedProvider = SettingsLockedProvider._();

/// True while recording: logout and server changes are disabled.

final class SettingsLockedProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// True while recording: logout and server changes are disabled.
  SettingsLockedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsLockedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsLockedHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return settingsLocked(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$settingsLockedHash() => r'92b92919f766ac21ce5053e9f5fd53e2de5a9152';
