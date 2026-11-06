// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'screen_capture.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(captureScreen)
final captureScreenProvider = CaptureScreenProvider._();

final class CaptureScreenProvider
    extends $FunctionalProvider<CaptureScreen, CaptureScreen, CaptureScreen>
    with $Provider<CaptureScreen> {
  CaptureScreenProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'captureScreenProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$captureScreenHash();

  @$internal
  @override
  $ProviderElement<CaptureScreen> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CaptureScreen create(Ref ref) {
    return captureScreen(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CaptureScreen value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CaptureScreen>(value),
    );
  }
}

String _$captureScreenHash() => r'9bcb5d86617b00387be21ca7c3db1f9afc2c9768';
