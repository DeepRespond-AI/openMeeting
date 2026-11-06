import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../api/api_exception.dart';
import '../api/models/client_models.dart';
import '../auth/session_controller.dart';
import '../config/app_config_provider.dart';
import 'client_repository.dart';
import 'recording_status.dart';

part 'heartbeat_controller.freezed.dart';
part 'heartbeat_controller.g.dart';

@freezed
abstract class HeartbeatState with _$HeartbeatState {
  const factory HeartbeatState({
    /// True while signed in (beats are being sent).
    @Default(false) bool active,

    /// App is in the foreground (resumed).
    @Default(true) bool foreground,
    DateTime? lastSuccessAt,

    /// Last failure (network errors are kept here; they never sign the user out).
    ApiException? lastError,
    String? serverVersion,
  }) = _HeartbeatState;

  const HeartbeatState._();

  /// Server reachable as of the last beat.
  bool get connected => active && lastSuccessAt != null && lastError == null;
}

/// Latest `GET /client/capabilities` (null until the first successful beat, and after sign-out).
/// UI uses it to show "STT/LLM not ready"; call `refresh()` to fetch immediately.
@Riverpod(keepAlive: true, name: 'capabilitiesProvider')
class CapabilitiesController extends _$CapabilitiesController {
  @override
  Capabilities? build() {
    ref.watch(isSignedInProvider);
    return null;
  }

  // ignore: use_setters_to_change_properties
  void set(Capabilities value) => state = value;

  Future<Capabilities> refresh() async {
    final caps = await ref.read(clientRepositoryProvider).capabilities();
    if (ref.mounted) state = caps;
    return caps;
  }
}

/// Sends `POST /client/heartbeat` every `AppConfig.heartbeat.interval` while signed in, then
/// refreshes [capabilitiesProvider]. In the background it slows down to
/// `backgroundInterval` unless recording. Errors are recorded in the state; a 401 is
/// handled by the dio interceptor (session expires), network errors never sign out.
///
/// Kept alive by `App` (`ref.listen(heartbeatControllerProvider, ...)`).
@Riverpod(keepAlive: true)
class HeartbeatController extends _$HeartbeatController {
  Timer? _timer;
  AppLifecycleListener? _lifecycle;
  bool _inFlight = false;

  @override
  HeartbeatState build() {
    final signedIn = ref.watch(isSignedInProvider);
    final foreground = _isForeground();
    _lifecycle = AppLifecycleListener(onStateChange: _onLifecycleChanged);
    ref.onDispose(() {
      _timer?.cancel();
      _timer = null;
      _lifecycle?.dispose();
      _lifecycle = null;
    });
    ref.listen(recordingStatusControllerProvider.select((s) => s.recording), (prev, next) {
      if (prev != next) unawaited(beatNow());
    });
    if (signedIn) {
      // First beat right after sign-in / app start; also refresh the cached user.
      scheduleMicrotask(() {
        if (!ref.mounted) return;
        unawaited(beatNow());
        unawaited(
          ref
              .read(sessionControllerProvider.notifier)
              .refreshMe()
              .then<void>((_) {}, onError: (_) {}),
        );
      });
    }
    return HeartbeatState(active: signedIn, foreground: foreground);
  }

  static bool _isForeground() {
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    return lifecycle == null || lifecycle == AppLifecycleState.resumed;
  }

  void _onLifecycleChanged(AppLifecycleState lifecycle) {
    if (!ref.mounted) return;
    final foreground = lifecycle == AppLifecycleState.resumed;
    if (foreground == state.foreground) return;
    state = state.copyWith(foreground: foreground);
    if (foreground) {
      unawaited(beatNow());
    } else {
      _schedule();
    }
  }

  /// Current interval: foreground (or recording) → `interval`, otherwise `backgroundInterval`.
  Duration _currentInterval() {
    final config = ref.read(appConfigProvider).heartbeat;
    final recording = ref.read(recordingStatusControllerProvider).recording;
    return (state.foreground || recording) ? config.interval : config.backgroundInterval;
  }

  void _schedule() {
    _timer?.cancel();
    if (!ref.mounted || !state.active) return;
    _timer = Timer(_currentInterval(), () => unawaited(beatNow()));
  }

  /// Sends a heartbeat now (and reschedules the next one).
  Future<void> beatNow() async {
    if (!ref.mounted || !state.active || _inFlight) return;
    _timer?.cancel();
    _inFlight = true;
    try {
      final repo = ref.read(clientRepositoryProvider);
      final recording = ref.read(recordingStatusControllerProvider);
      final result = await repo.heartbeat(
        recording: recording.recording,
        meetingId: recording.meetingId,
      );
      final caps = await repo.capabilities();
      if (!ref.mounted) return;
      ref.read(capabilitiesProvider.notifier).set(caps);
      state = state.copyWith(
        lastSuccessAt: DateTime.now(),
        lastError: null,
        serverVersion: result.serverVersion ?? caps.serverVersion,
      );
    } on Object catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(lastError: ApiException.from(e));
    } finally {
      _inFlight = false;
      if (ref.mounted) _schedule();
    }
  }
}
