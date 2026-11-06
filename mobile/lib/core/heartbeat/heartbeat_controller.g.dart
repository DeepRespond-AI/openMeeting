// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'heartbeat_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Latest `GET /client/capabilities` (null until the first successful beat, and after sign-out).
/// UI uses it to show "STT/LLM not ready"; call `refresh()` to fetch immediately.

@ProviderFor(CapabilitiesController)
final capabilitiesProvider = CapabilitiesControllerProvider._();

/// Latest `GET /client/capabilities` (null until the first successful beat, and after sign-out).
/// UI uses it to show "STT/LLM not ready"; call `refresh()` to fetch immediately.
final class CapabilitiesControllerProvider
    extends $NotifierProvider<CapabilitiesController, Capabilities?> {
  /// Latest `GET /client/capabilities` (null until the first successful beat, and after sign-out).
  /// UI uses it to show "STT/LLM not ready"; call `refresh()` to fetch immediately.
  CapabilitiesControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'capabilitiesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$capabilitiesControllerHash();

  @$internal
  @override
  CapabilitiesController create() => CapabilitiesController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Capabilities? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Capabilities?>(value),
    );
  }
}

String _$capabilitiesControllerHash() =>
    r'6145f135e2c263458c99f3a888a712133bc69de3';

/// Latest `GET /client/capabilities` (null until the first successful beat, and after sign-out).
/// UI uses it to show "STT/LLM not ready"; call `refresh()` to fetch immediately.

abstract class _$CapabilitiesController extends $Notifier<Capabilities?> {
  Capabilities? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Capabilities?, Capabilities?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Capabilities?, Capabilities?>,
              Capabilities?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Sends `POST /client/heartbeat` every `AppConfig.heartbeat.interval` while signed in, then
/// refreshes [capabilitiesProvider]. In the background it slows down to
/// `backgroundInterval` unless recording. Errors are recorded in the state; a 401 is
/// handled by the dio interceptor (session expires), network errors never sign out.
///
/// Kept alive by `App` (`ref.listen(heartbeatControllerProvider, ...)`).

@ProviderFor(HeartbeatController)
final heartbeatControllerProvider = HeartbeatControllerProvider._();

/// Sends `POST /client/heartbeat` every `AppConfig.heartbeat.interval` while signed in, then
/// refreshes [capabilitiesProvider]. In the background it slows down to
/// `backgroundInterval` unless recording. Errors are recorded in the state; a 401 is
/// handled by the dio interceptor (session expires), network errors never sign out.
///
/// Kept alive by `App` (`ref.listen(heartbeatControllerProvider, ...)`).
final class HeartbeatControllerProvider
    extends $NotifierProvider<HeartbeatController, HeartbeatState> {
  /// Sends `POST /client/heartbeat` every `AppConfig.heartbeat.interval` while signed in, then
  /// refreshes [capabilitiesProvider]. In the background it slows down to
  /// `backgroundInterval` unless recording. Errors are recorded in the state; a 401 is
  /// handled by the dio interceptor (session expires), network errors never sign out.
  ///
  /// Kept alive by `App` (`ref.listen(heartbeatControllerProvider, ...)`).
  HeartbeatControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'heartbeatControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$heartbeatControllerHash();

  @$internal
  @override
  HeartbeatController create() => HeartbeatController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HeartbeatState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HeartbeatState>(value),
    );
  }
}

String _$heartbeatControllerHash() =>
    r'649e12024cd61437a2a264ac78d5b97815710b89';

/// Sends `POST /client/heartbeat` every `AppConfig.heartbeat.interval` while signed in, then
/// refreshes [capabilitiesProvider]. In the background it slows down to
/// `backgroundInterval` unless recording. Errors are recorded in the state; a 401 is
/// handled by the dio interceptor (session expires), network errors never sign out.
///
/// Kept alive by `App` (`ref.listen(heartbeatControllerProvider, ...)`).

abstract class _$HeartbeatController extends $Notifier<HeartbeatState> {
  HeartbeatState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<HeartbeatState, HeartbeatState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<HeartbeatState, HeartbeatState>,
              HeartbeatState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
