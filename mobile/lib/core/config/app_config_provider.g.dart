// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_config_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The app configuration — synchronous for consumers.
///
/// It is loaded in `main()` and injected with
/// `appConfigProvider.overrideWithValue(config)`; tests override it the same way
/// (see `test/helpers/test_config.dart`).

@ProviderFor(appConfig)
final appConfigProvider = AppConfigProvider._();

/// The app configuration — synchronous for consumers.
///
/// It is loaded in `main()` and injected with
/// `appConfigProvider.overrideWithValue(config)`; tests override it the same way
/// (see `test/helpers/test_config.dart`).

final class AppConfigProvider
    extends $FunctionalProvider<AppConfig, AppConfig, AppConfig>
    with $Provider<AppConfig> {
  /// The app configuration — synchronous for consumers.
  ///
  /// It is loaded in `main()` and injected with
  /// `appConfigProvider.overrideWithValue(config)`; tests override it the same way
  /// (see `test/helpers/test_config.dart`).
  AppConfigProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appConfigProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appConfigHash();

  @$internal
  @override
  $ProviderElement<AppConfig> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppConfig create(Ref ref) {
    return appConfig(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppConfig value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppConfig>(value),
    );
  }
}

String _$appConfigHash() => r'52cbdf91da59eea091ccdf9141a26115f04dfb87';
