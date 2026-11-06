// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_store.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The process-wide [SharedPreferences] instance.
///
/// Loaded in `main()` (`SharedPreferences.getInstance()`) and injected with
/// `sharedPreferencesProvider.overrideWithValue(prefs)` so settings are synchronous.
/// Tests: `SharedPreferences.setMockInitialValues({...})` then override the same way.

@ProviderFor(sharedPreferences)
final sharedPreferencesProvider = SharedPreferencesProvider._();

/// The process-wide [SharedPreferences] instance.
///
/// Loaded in `main()` (`SharedPreferences.getInstance()`) and injected with
/// `sharedPreferencesProvider.overrideWithValue(prefs)` so settings are synchronous.
/// Tests: `SharedPreferences.setMockInitialValues({...})` then override the same way.

final class SharedPreferencesProvider
    extends
        $FunctionalProvider<
          SharedPreferences,
          SharedPreferences,
          SharedPreferences
        >
    with $Provider<SharedPreferences> {
  /// The process-wide [SharedPreferences] instance.
  ///
  /// Loaded in `main()` (`SharedPreferences.getInstance()`) and injected with
  /// `sharedPreferencesProvider.overrideWithValue(prefs)` so settings are synchronous.
  /// Tests: `SharedPreferences.setMockInitialValues({...})` then override the same way.
  SharedPreferencesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sharedPreferencesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sharedPreferencesHash();

  @$internal
  @override
  $ProviderElement<SharedPreferences> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SharedPreferences create(Ref ref) {
    return sharedPreferences(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SharedPreferences value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SharedPreferences>(value),
    );
  }
}

String _$sharedPreferencesHash() => r'5535f34fe66089f283cd5b2cc2fe11774f13bb0e';

@ProviderFor(settingsStore)
final settingsStoreProvider = SettingsStoreProvider._();

final class SettingsStoreProvider
    extends $FunctionalProvider<SettingsStore, SettingsStore, SettingsStore>
    with $Provider<SettingsStore> {
  SettingsStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsStoreHash();

  @$internal
  @override
  $ProviderElement<SettingsStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SettingsStore create(Ref ref) {
    return settingsStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SettingsStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SettingsStore>(value),
    );
  }
}

String _$settingsStoreHash() => r'e5786f9f681807cc2238d355a14fe40e049dc11d';
