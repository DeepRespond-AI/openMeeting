// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'im_gateway.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(imPlatform)
final imPlatformProvider = ImPlatformProvider._();

final class ImPlatformProvider
    extends $FunctionalProvider<DRPlatform, DRPlatform, DRPlatform>
    with $Provider<DRPlatform> {
  ImPlatformProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'imPlatformProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$imPlatformHash();

  @$internal
  @override
  $ProviderElement<DRPlatform> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DRPlatform create(Ref ref) {
    return imPlatform(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DRPlatform value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DRPlatform>(value),
    );
  }
}

String _$imPlatformHash() => r'ecebd02f015e6853c607c6123c179fe692c7c17f';

@ProviderFor(imGateway)
final imGatewayProvider = ImGatewayProvider._();

final class ImGatewayProvider
    extends $FunctionalProvider<ImGateway, ImGateway, ImGateway>
    with $Provider<ImGateway> {
  ImGatewayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'imGatewayProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$imGatewayHash();

  @$internal
  @override
  $ProviderElement<ImGateway> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ImGateway create(Ref ref) {
    return imGateway(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ImGateway value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ImGateway>(value),
    );
  }
}

String _$imGatewayHash() => r'f19f2db5aea015e667597964f1e3de2cf952b7a0';

@ProviderFor(imClient)
final imClientProvider = ImClientProvider._();

final class ImClientProvider
    extends
        $FunctionalProvider<AsyncValue<DRClient>, DRClient, FutureOr<DRClient>>
    with $FutureModifier<DRClient>, $FutureProvider<DRClient> {
  ImClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'imClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$imClientHash();

  @$internal
  @override
  $FutureProviderElement<DRClient> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<DRClient> create(Ref ref) {
    return imClient(ref);
  }
}

String _$imClientHash() => r'27922df7e4d0d9c03706efd456a86aa917946702';
