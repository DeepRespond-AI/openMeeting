import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' show PlatformDispatcher;

import 'package:system_audio_capture/system_audio_capture.dart';

import '../../../core/config/app_config.dart';
import '../../../core/config/app_config_provider.dart';
import '../../../core/config/app_enums.dart';
import '../../../core/l10n/l10n.dart';
import '../domain/audio_source.dart';

/// System-audio ("内录") source backed by the `system_audio_capture` plugin
/// (Android MediaProjection + AudioPlaybackCapture, iOS ReplayKit broadcast extension).
///
/// All tunables come from [AppConfig] (`systemAudio`, `audio.levelUpdateIntervalMs`,
/// `features.systemAudioCapture`) and [AudioCaptureOptions]; OS-visible texts from l10n.
/// Pass [config] / [l10n] when available (e.g. from `appConfigProvider`); otherwise the
/// config asset is loaded on first use and texts follow the device locale.
///
/// Lifecycle: `frames`/`level`/`events` belong to the current session — they complete after
/// [stop], and a later [start] opens new streams (re-read the getters). Data emitted before the
/// first listener subscribes (e.g. between the native start and the caller's `listen` after
/// `await start()`) is buffered and delivered to that listener.
class SystemAudioSource implements AudioSource {
  SystemAudioSource({SystemAudioCapture? capture, this._config, this._l10n})
    : _capture = capture ?? SystemAudioCapture() {
    _openSession();
  }

  final SystemAudioCapture _capture;
  AppConfig? _config;
  final AppLocalizations? _l10n;

  late _BufferedBroadcast<Uint8List> _frames;
  late _BufferedBroadcast<double> _level;
  late _BufferedBroadcast<AudioSourceEvent> _events;
  final List<StreamSubscription<Object?>> _subscriptions = [];
  _State _state = _State.idle;
  Future<void>? _stopping;

  @override
  RecordingSource get kind => RecordingSource.system;

  @override
  Stream<Uint8List> get frames => _frames.stream;

  @override
  Stream<double> get level => _level.stream;

  @override
  Stream<AudioSourceEvent> get events => _events.stream;

  @override
  Future<AudioSourceAvailability> availability() async {
    final config = await _loadConfig();
    if (!config.features.systemAudioCapture) return AudioSourceAvailability.unsupported;
    return switch (await _capture.availability()) {
      SystemAudioAvailability.available => AudioSourceAvailability.available,
      SystemAudioAvailability.needsPermission => AudioSourceAvailability.needsPermission,
      SystemAudioAvailability.unsupported => AudioSourceAvailability.unsupported,
    };
  }

  @override
  Future<void> start(AudioCaptureOptions options) async {
    if (_state != _State.idle || _stopping != null) {
      throw const AudioSourceException(AudioSourceErrorCode.busy);
    }
    final config = await _loadConfig();
    if (!config.features.systemAudioCapture) {
      throw const AudioSourceException(AudioSourceErrorCode.unsupported);
    }
    if (options.channels != config.audio.channels) {
      throw AudioSourceException(
        AudioSourceErrorCode.unsupported,
        'system audio is captured with ${config.audio.channels} channel(s)',
      );
    }
    _state = _State.starting;
    if (_frames.isClosed) _openSession();
    _subscriptions
      ..add(_capture.pcm.listen(_frames.add))
      ..add(_capture.level.listen(_level.add))
      ..add(_capture.events.listen((e) => _events.add(_mapEvent(e))));
    try {
      await _capture.start(_startOptions(options, config));
    } on SystemAudioCaptureException catch (e) {
      await _cancelSubscriptions();
      _state = _State.idle;
      throw AudioSourceException(_mapCode(e.code), e.message);
    }
    _state = _State.capturing;
  }

  @override
  Future<void> pause() async {
    if (_state != _State.capturing) return;
    _state = _State.paused;
    await _capture.pause();
  }

  @override
  Future<void> resume() async {
    if (_state != _State.paused) return;
    _state = _State.capturing;
    await _capture.resume();
  }

  @override
  Future<void> stop() => _stopping ??= _stop().whenComplete(() => _stopping = null);

  Future<void> _stop() async {
    if (_state == _State.idle) return;
    await _capture.stop();
    await _cancelSubscriptions();
    _state = _State.idle;
    await Future.wait([_frames.close(), _level.close(), _events.close()]);
  }

  void _openSession() {
    _frames = _BufferedBroadcast<Uint8List>();
    _level = _BufferedBroadcast<double>();
    _events = _BufferedBroadcast<AudioSourceEvent>();
  }

  Future<void> _cancelSubscriptions() async {
    final subs = List.of(_subscriptions);
    _subscriptions.clear();
    for (final s in subs) {
      await s.cancel();
    }
  }

  Future<AppConfig> _loadConfig() async => _config ??= await loadAppConfig();

  AppLocalizations get _texts =>
      _l10n ?? lookupAppLocalizations(resolveSystemLocale(PlatformDispatcher.instance.locales));

  SystemAudioStartOptions _startOptions(AudioCaptureOptions options, AppConfig config) {
    final c = config.systemAudio;
    final t = _texts;
    return SystemAudioStartOptions(
      sampleRate: options.sampleRate,
      includeMicrophone: options.includeMicrophone,
      micGain: options.micGain,
      duckingRatio: options.systemDuckingRatio,
      frameMs: c.frameMs,
      jitterBufferMs: c.jitterBufferMs,
      maxBufferMs: c.maxBufferMs,
      micActiveRmsThreshold: c.micActiveRmsThreshold,
      duckingAttackMs: c.duckingAttackMs,
      duckingReleaseMs: c.duckingReleaseMs,
      softClipKnee: c.softClipKnee,
      levelIntervalMs: config.audio.levelUpdateIntervalMs,
      levelFloorDb: c.levelFloorDb,
      androidCaptureUsages: c.androidCaptureUsages,
      androidMicSource: c.androidMicSource,
      androidFallbackCaptureSampleRate: c.androidFallbackCaptureSampleRate,
      androidNotificationChannelId: c.androidNotificationChannelId,
      androidNotificationId: c.androidNotificationId,
      iosChunkMs: c.iosChunkMs,
      iosStartTimeoutMs: c.iosStartTimeoutMs,
      iosStopTimeoutMs: c.iosStopTimeoutMs,
      iosPollIntervalMs: c.iosPollIntervalMs,
      iosMaxPendingChunks: c.iosMaxPendingChunks,
      iosKeepAliveInBackground: c.iosKeepAliveInBackground,
      texts: SystemAudioTexts(
        notificationChannelName: t.systemAudioNotificationChannelName,
        notificationTitle: t.systemAudioNotificationTitle,
        notificationText: t.systemAudioNotificationText,
        broadcastStoppedByApp: t.systemAudioBroadcastStoppedByApp,
        broadcastNotStartedFromApp: t.systemAudioBroadcastNotStartedFromApp,
      ),
    );
  }

  static AudioSourceErrorCode _mapCode(SystemAudioErrorCode code) => switch (code) {
    SystemAudioErrorCode.permissionDenied => AudioSourceErrorCode.permissionDenied,
    SystemAudioErrorCode.userCancelled => AudioSourceErrorCode.userCancelled,
    SystemAudioErrorCode.unsupported => AudioSourceErrorCode.unsupported,
    SystemAudioErrorCode.busy => AudioSourceErrorCode.busy,
    SystemAudioErrorCode.platform => AudioSourceErrorCode.platform,
  };

  static AudioSourceEvent _mapEvent(SystemAudioCaptureEvent event) => switch (event) {
    SystemAudioInterrupted() => const AudioSourceInterrupted(),
    SystemAudioInterruptionEnded() => const AudioSourceInterruptionEnded(),
    SystemAudioStoppedExternally(:final reason) => AudioSourceStoppedExternally(reason: reason),
    SystemAudioFailed(:final error) => AudioSourceFailed(
      AudioSourceException(_mapCode(error.code), error.message),
    ),
  };
}

enum _State { idle, starting, capturing, paused }

/// Broadcast stream that buffers events until its first listener subscribes.
class _BufferedBroadcast<T> {
  _BufferedBroadcast() {
    _controller = StreamController<T>.broadcast(onListen: _flush);
  }

  late final StreamController<T> _controller;
  final List<T> _pending = [];

  Stream<T> get stream => _controller.stream;
  bool get isClosed => _controller.isClosed;

  void add(T value) {
    if (_controller.isClosed) return;
    if (_controller.hasListener) {
      _controller.add(value);
    } else {
      _pending.add(value);
    }
  }

  void _flush() {
    final pending = List.of(_pending);
    _pending.clear();
    pending.forEach(_controller.add);
  }

  Future<void> close() {
    _pending.clear();
    return _controller.close();
  }
}
