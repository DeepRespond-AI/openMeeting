import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/config/app_config_provider.dart';
import '../data/just_audio_engine.dart';
import '../data/meetings_repository_impl.dart';
import '../domain/audio_playback.dart';
import '../domain/meeting_audio_source.dart';

part 'meeting_player_controller.g.dart';

/// Meeting recording player: resolves the audio URL (302 → OSS URL without Authorization,
/// else the API URL with the Bearer header), then exposes play/pause/seek/skip/speed.
/// Speeds and skip step come from `AppConfig.player`.
@riverpod
class MeetingPlayerController extends _$MeetingPlayerController {
  AudioPlaybackEngine? _engine;
  final List<StreamSubscription<Object?>> _subs = [];

  @override
  MeetingPlayerState build(String meetingId) {
    final engine = ref.read(audioPlaybackEngineFactoryProvider)();
    _engine = engine;
    _subs
      ..add(engine.positionStream.listen((p) => _update((s) => s.copyWith(position: p))))
      ..add(engine.durationStream.listen((d) => _update((s) => s.copyWith(duration: d))))
      ..add(engine.playingStream.listen((p) => _update((s) => s.copyWith(playing: p))))
      ..add(engine.completedStream.listen((_) => unawaited(_onCompleted())));
    ref.onDispose(() {
      for (final sub in _subs) {
        unawaited(sub.cancel());
      }
      _subs.clear();
      _engine = null;
      unawaited(engine.dispose());
    });
    return const MeetingPlayerState();
  }

  void _update(MeetingPlayerState Function(MeetingPlayerState) change) {
    if (ref.mounted) state = change(state);
  }

  /// Resolves and loads the recording (also used as "retry").
  Future<void> load({Uri? localFile}) async {
    final engine = _engine;
    if (engine == null || state.status == PlayerStatus.loading) return;
    _update((s) => s.copyWith(status: PlayerStatus.loading, error: null));
    try {
      final source = localFile == null
          ? await ref.read(meetingsRepositoryProvider).resolveAudio(meetingId)
          : MeetingAudioRedirect(localFile);
      if (!ref.mounted) return;
      final Duration? duration;
      switch (source) {
        case MeetingAudioNone():
          _update((s) => s.copyWith(status: PlayerStatus.unavailable));
          return;
        case MeetingAudioRedirect(:final url):
          duration = await engine.load(url);
        case MeetingAudioDirect(:final url, :final headers):
          duration = await engine.load(url, headers: headers);
      }
      final speeds = ref.read(appConfigProvider).player.speeds;
      if (speeds.isNotEmpty) await engine.setSpeed(speeds[state.speedIndex % speeds.length]);
      _update((s) => s.copyWith(status: PlayerStatus.ready, duration: duration ?? s.duration));
    } on Object catch (e) {
      _update((s) => s.copyWith(status: PlayerStatus.error, error: e));
    }
  }

  Future<void> togglePlay() async {
    if (state.status == PlayerStatus.idle) await load();
    if (!ref.mounted) return;
    final engine = _engine;
    if (engine == null || !state.isReady) return;
    if (state.playing) {
      await engine.pause();
    } else {
      await engine.play();
    }
  }

  Future<void> seek(Duration position) async {
    final engine = _engine;
    if (engine == null || !state.isReady) return;
    final clamped = _clamp(position);
    _update((s) => s.copyWith(position: clamped));
    await engine.seek(clamped);
  }

  /// Jumps by `AppConfig.player.skipSeconds` forward or back.
  Future<void> skip({required bool forward}) {
    final step = ref.read(appConfigProvider).player.skip;
    return seek(forward ? state.position + step : state.position - step);
  }

  /// Cycles through `AppConfig.player.speeds`.
  Future<void> cycleSpeed() async {
    final speeds = ref.read(appConfigProvider).player.speeds;
    if (speeds.isEmpty) return;
    final next = (state.speedIndex + 1) % speeds.length;
    _update((s) => s.copyWith(speedIndex: next));
    await _engine?.setSpeed(speeds[next]);
  }

  /// Transcript timestamp tapped: seek to [seconds] and play.
  Future<void> playFrom(double seconds) async {
    if (!state.isReady) return;
    await seek(Duration(milliseconds: (seconds * Duration.millisecondsPerSecond).round()));
    if (!state.playing) await _engine?.play();
  }

  Future<void> _onCompleted() async {
    await _engine?.pause();
    await _engine?.seek(Duration.zero);
    _update((s) => s.copyWith(position: Duration.zero, playing: false));
  }

  Duration _clamp(Duration position) {
    if (position < Duration.zero) return Duration.zero;
    final duration = state.duration;
    if (duration != null && position > duration) return duration;
    return position;
  }
}
