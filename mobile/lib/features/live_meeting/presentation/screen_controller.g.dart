// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'screen_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(RoomScreen)
final roomScreenProvider = RoomScreenProvider._();

final class RoomScreenProvider
    extends $NotifierProvider<RoomScreen, ScreenState> {
  RoomScreenProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'roomScreenProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$roomScreenHash();

  @$internal
  @override
  RoomScreen create() => RoomScreen();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ScreenState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ScreenState>(value),
    );
  }
}

String _$roomScreenHash() => r'fadd176f1d78424e3899e1d8e78671e786a5012e';

abstract class _$RoomScreen extends $Notifier<ScreenState> {
  ScreenState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ScreenState, ScreenState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ScreenState, ScreenState>,
              ScreenState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
