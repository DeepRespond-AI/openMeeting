// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_client.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The app's single [Dio] (DEVELOPMENT.md §4).
///
/// - `baseUrl` = effective server URL (settings > config); the provider rebuilds when it changes.
/// - Default timeouts from `AppConfig.network`; for uploads/downloads pass
///   `transferOptions(config.network)`.
/// - Errors arrive as [DioException] whose `.error` is an [ApiException]; wrap calls
///   in `apiCall(() => ...)` to get the [ApiException] thrown directly.

@ProviderFor(apiClient)
final apiClientProvider = ApiClientProvider._();

/// The app's single [Dio] (DEVELOPMENT.md §4).
///
/// - `baseUrl` = effective server URL (settings > config); the provider rebuilds when it changes.
/// - Default timeouts from `AppConfig.network`; for uploads/downloads pass
///   `transferOptions(config.network)`.
/// - Errors arrive as [DioException] whose `.error` is an [ApiException]; wrap calls
///   in `apiCall(() => ...)` to get the [ApiException] thrown directly.

final class ApiClientProvider extends $FunctionalProvider<Dio, Dio, Dio>
    with $Provider<Dio> {
  /// The app's single [Dio] (DEVELOPMENT.md §4).
  ///
  /// - `baseUrl` = effective server URL (settings > config); the provider rebuilds when it changes.
  /// - Default timeouts from `AppConfig.network`; for uploads/downloads pass
  ///   `transferOptions(config.network)`.
  /// - Errors arrive as [DioException] whose `.error` is an [ApiException]; wrap calls
  ///   in `apiCall(() => ...)` to get the [ApiException] thrown directly.
  ApiClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'apiClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$apiClientHash();

  @$internal
  @override
  $ProviderElement<Dio> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Dio create(Ref ref) {
    return apiClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Dio value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Dio>(value),
    );
  }
}

String _$apiClientHash() => r'645d04c9009485a6c64150a1cc425dd41f636967';
