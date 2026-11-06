import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/im/screen_capture.dart';
import '../data/live_repository_impl.dart';
import '../domain/live_models.dart';
import 'room_controller.dart';

part 'screen_controller.freezed.dart';
part 'screen_controller.g.dart';

enum ScreenPhase { idle, capturing, publishing, sharing, stopping }

enum ScreenFailure { denied, unavailable, replaced, start, stop }

@freezed
abstract class ScreenState with _$ScreenState {
  const factory ScreenState({
    @Default(ScreenPhase.idle) ScreenPhase phase,
    ScreenFailure? error,
    Object? video,
  }) = _ScreenState;
}

@Riverpod(keepAlive: true)
class RoomScreen extends _$RoomScreen {
  ScreenCapture? _capture;
  String? _claim, _room;
  int _generation = 0;
  bool _disposed = false;
  bool _starting = false;
  @override
  ScreenState build() {
    final repository = ref.read(liveRepositoryProvider);
    ref.listen(roomControllerProvider, (_, next) {
      if (next is! RoomActive || next.media == 'error' || next.media == 'unavailable') {
        if (_capture != null || state.phase != ScreenPhase.idle) unawaited(stop());
        return;
      }
      if (_claim != null &&
          (next.room.id != _room ||
              !next.room.participants.any(
                (p) => p.isSelf && p.screenSharing && p.screenShareId == _claim,
              ))) {
        unawaited(stop(replaced: true));
      }
    });
    ref.listen(roomChannelProvider, (before, next) {
      if (before != null && !identical(before, next)) unawaited(stop());
    });
    ref.onDispose(() {
      _disposed = true;
      ++_generation;
      final capture = _capture;
      _capture = null;
      if (capture != null) unawaited(capture.dispose().catchError((Object _) {}));
      if (_room != null && _claim != null) {
        unawaited(repository.stopScreenShare(_room!, _claim!).catchError((Object _) {}));
      }
    });
    return const ScreenState();
  }

  Future<void> start(String title, String body) async {
    if (_starting || state.phase != ScreenPhase.idle) return;
    final current = ref.read(roomControllerProvider), channel = ref.read(roomChannelProvider);
    if (current is! RoomActive || channel == null || current.media != 'connected') {
      state = const ScreenState(error: ScreenFailure.unavailable);
      return;
    }
    final generation = ++_generation, repository = ref.read(liveRepositoryProvider);
    final roomId = current.room.id;
    ScreenCapture? capture;
    String? claim;
    _starting = true;
    state = const ScreenState(phase: ScreenPhase.capturing);
    try {
      capture = await ref.read(captureScreenProvider)(title, body);
      if (!_valid(generation)) {
        await capture.dispose();
        return;
      }
      _capture = capture;
      capture.onEnded = () => unawaited(stop());
      state = const ScreenState(phase: ScreenPhase.publishing);
      claim = await repository.startScreenShare(roomId);
      if (!_valid(generation)) {
        await repository.stopScreenShare(roomId, claim);
        await capture.dispose();
        return;
      }
      // Verify ownership before exposing any screen pixels to the channel.
      final latest = await repository.room(roomId);
      if (!_valid(generation) ||
          !latest.participants.any(
            (p) => p.id == current.self.id && p.screenSharing && p.screenShareId == claim,
          )) {
        await repository.stopScreenShare(roomId, claim);
        await capture.dispose();
        if (_valid(generation)) {
          _capture = null;
          state = const ScreenState(error: ScreenFailure.replaced);
          await ref.read(roomControllerProvider.notifier).refresh();
        }
        return;
      }
      ref.read(roomControllerProvider.notifier).applyRoom(latest);
      _room = roomId;
      _claim = claim;
      await capture.publish(channel, claim);
      if (!_valid(generation)) {
        await capture.dispose();
        return;
      }
      state = ScreenState(phase: ScreenPhase.sharing, video: capture.video);
      await ref.read(roomControllerProvider.notifier).refresh();
    } on Object catch (error) {
      if (capture != null) await capture.dispose();
      if (claim != null) {
        try {
          await repository.stopScreenShare(roomId, claim);
        } on Object {
          /* Refresh will reconcile server ownership. */
        }
      }
      if (_valid(generation)) {
        _capture = null;
        _room = _claim = null;
        state = ScreenState(
          error: error is ScreenCaptureDenied ? ScreenFailure.denied : ScreenFailure.start,
        );
        await ref.read(roomControllerProvider.notifier).refresh();
      }
    } finally {
      _starting = false;
      if (!_disposed && ref.mounted && state.phase == ScreenPhase.stopping) {
        state = state.copyWith(phase: ScreenPhase.idle);
      }
    }
  }

  bool _valid(int generation) => !_disposed && ref.mounted && generation == _generation;

  Future<void> stop({bool replaced = false}) async {
    if (_disposed) return;
    if (_capture == null && _claim == null && state.phase == ScreenPhase.idle) return;
    final generation = ++_generation;
    final capture = _capture, room = _room, claim = _claim;
    final repository = ref.read(liveRepositoryProvider);
    _capture = null;
    _room = _claim = null;
    state = const ScreenState(phase: ScreenPhase.stopping);
    ScreenFailure? error = replaced ? ScreenFailure.replaced : null;
    try {
      await capture?.dispose();
    } on Object {
      error = ScreenFailure.stop;
    }
    try {
      if (room != null && claim != null) await repository.stopScreenShare(room, claim);
    } on Object {
      error = ScreenFailure.stop;
    }
    if (_valid(generation)) {
      state = ScreenState(phase: _starting ? ScreenPhase.stopping : ScreenPhase.idle, error: error);
    }
    if (!_disposed && ref.mounted && ref.read(roomControllerProvider) is RoomActive) {
      await ref.read(roomControllerProvider.notifier).refresh();
    }
  }
}
