// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Persisted user settings (DEVELOPMENT.md §3, layer 3). The only place settings change.
///
/// State is the raw [AppSettings] (nulls = use config default). Read resolved values
/// through [effectiveSettingsProvider] / [effectiveServerUrlProvider].

@ProviderFor(SettingsController)
final settingsControllerProvider = SettingsControllerProvider._();

/// Persisted user settings (DEVELOPMENT.md §3, layer 3). The only place settings change.
///
/// State is the raw [AppSettings] (nulls = use config default). Read resolved values
/// through [effectiveSettingsProvider] / [effectiveServerUrlProvider].
final class SettingsControllerProvider
    extends $NotifierProvider<SettingsController, AppSettings> {
  /// Persisted user settings (DEVELOPMENT.md §3, layer 3). The only place settings change.
  ///
  /// State is the raw [AppSettings] (nulls = use config default). Read resolved values
  /// through [effectiveSettingsProvider] / [effectiveServerUrlProvider].
  SettingsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsControllerHash();

  @$internal
  @override
  SettingsController create() => SettingsController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppSettings value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppSettings>(value),
    );
  }
}

String _$settingsControllerHash() =>
    r'4be24be31a729b79267cbff524a9542578943252';

/// Persisted user settings (DEVELOPMENT.md §3, layer 3). The only place settings change.
///
/// State is the raw [AppSettings] (nulls = use config default). Read resolved values
/// through [effectiveSettingsProvider] / [effectiveServerUrlProvider].

abstract class _$SettingsController extends $Notifier<AppSettings> {
  AppSettings build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AppSettings, AppSettings>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AppSettings, AppSettings>,
              AppSettings,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Settings with config defaults applied (user settings > app config).

@ProviderFor(effectiveSettings)
final effectiveSettingsProvider = EffectiveSettingsProvider._();

/// Settings with config defaults applied (user settings > app config).

final class EffectiveSettingsProvider
    extends
        $FunctionalProvider<
          EffectiveSettings,
          EffectiveSettings,
          EffectiveSettings
        >
    with $Provider<EffectiveSettings> {
  /// Settings with config defaults applied (user settings > app config).
  EffectiveSettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'effectiveSettingsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$effectiveSettingsHash();

  @$internal
  @override
  $ProviderElement<EffectiveSettings> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  EffectiveSettings create(Ref ref) {
    return effectiveSettings(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EffectiveSettings value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EffectiveSettings>(value),
    );
  }
}

String _$effectiveSettingsHash() => r'b808939de596620839fc6164b572d095db0ddd6c';

/// Effective server base URL ('' = not configured). Narrow provider so that
/// `apiClientProvider` only rebuilds when the URL itself changes.

@ProviderFor(effectiveServerUrl)
final effectiveServerUrlProvider = EffectiveServerUrlProvider._();

/// Effective server base URL ('' = not configured). Narrow provider so that
/// `apiClientProvider` only rebuilds when the URL itself changes.

final class EffectiveServerUrlProvider
    extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  /// Effective server base URL ('' = not configured). Narrow provider so that
  /// `apiClientProvider` only rebuilds when the URL itself changes.
  EffectiveServerUrlProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'effectiveServerUrlProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$effectiveServerUrlHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return effectiveServerUrl(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$effectiveServerUrlHash() =>
    r'9234e563766ca4c360d867b62ddf54b50487f338';

/// UI locale preference (narrow provider for MaterialApp).

@ProviderFor(localeMode)
final localeModeProvider = LocaleModeProvider._();

/// UI locale preference (narrow provider for MaterialApp).

final class LocaleModeProvider
    extends $FunctionalProvider<LocaleMode, LocaleMode, LocaleMode>
    with $Provider<LocaleMode> {
  /// UI locale preference (narrow provider for MaterialApp).
  LocaleModeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localeModeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localeModeHash();

  @$internal
  @override
  $ProviderElement<LocaleMode> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LocaleMode create(Ref ref) {
    return localeMode(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocaleMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocaleMode>(value),
    );
  }
}

String _$localeModeHash() => r'd7aa1c3587972562d7feff2ddd806a9573ae4284';
