import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'broadcast_chunk_reader.dart';
import 'models.dart';

/// Dart side of the system-audio ("内录") capture plugin.
///
/// * Android: MediaProjection + `AudioPlaybackCaptureConfiguration`, mixed with the mic
///   natively; PCM arrives on the `pcm` event channel.
/// * iOS: a ReplayKit Broadcast Upload Extension mixes app + mic audio and writes chunk
///   files into the App Group container; `start` returns that directory and this class
///   reads the chunks ([BroadcastChunkReader]) when notified (and on a polling timer).
///
/// Output: mono PCM16 little-endian at [SystemAudioStartOptions.sampleRate].
class SystemAudioCapture {
  SystemAudioCapture({
    MethodChannel? methodChannel,
    EventChannel? pcmChannel,
    EventChannel? levelChannel,
    EventChannel? eventChannel,
  }) : _method = methodChannel ?? const MethodChannel('$channelPrefix/method'),
       _pcmChannel = pcmChannel ?? const EventChannel('$channelPrefix/pcm'),
       _levelChannel = levelChannel ?? const EventChannel('$channelPrefix/level'),
       _eventChannel = eventChannel ?? const EventChannel('$channelPrefix/events');

  static const String channelPrefix = 'cn.deeprespond.system_audio_capture';

  /// Start result `mode` values.
  static const String modeStream = 'stream';
  static const String modeChunks = 'chunks';

  final MethodChannel _method;
  final EventChannel _pcmChannel;
  final EventChannel _levelChannel;
  final EventChannel _eventChannel;

  final _pcm = StreamController<Uint8List>.broadcast();
  final _level = StreamController<double>.broadcast();
  final _events = StreamController<SystemAudioCaptureEvent>.broadcast();

  final List<StreamSubscription<Object?>> _subscriptions = [];
  SystemAudioStartOptions? _options;
  BroadcastChunkReader? _chunkReader;
  Timer? _pollTimer;
  bool _starting = false;
  bool _active = false;
  bool _paused = false;
  Future<void>? _stopping;

  /// Mono PCM16 LE frames while capturing (not while paused).
  Stream<Uint8List> get pcm => _pcm.stream;

  /// Normalized level 0..1.
  Stream<double> get level => _level.stream;

  Stream<SystemAudioCaptureEvent> get events => _events.stream;

  bool get isCapturing => _active;
  bool get isPaused => _paused;

  Future<SystemAudioAvailability> availability() async {
    final String? raw;
    try {
      raw = await _method.invokeMethod<String>('availability');
    } on MissingPluginException {
      return SystemAudioAvailability.unsupported;
    }
    return SystemAudioAvailability.values.firstWhere(
      (v) => v.name == raw,
      orElse: () => SystemAudioAvailability.unsupported,
    );
  }

  /// Asks for consent and starts capturing. Throws [SystemAudioCaptureException].
  Future<void> start(SystemAudioStartOptions options) async {
    if (_active || _starting || _stopping != null) {
      throw const SystemAudioCaptureException(SystemAudioErrorCode.busy);
    }
    _options = options;
    _paused = false;
    _starting = true;
    _listenNative();
    final Map<Object?, Object?>? result;
    try {
      result = await _method.invokeMapMethod<Object?, Object?>('start', options.toMap());
    } on PlatformException catch (e) {
      _starting = false;
      await _cancelNative();
      throw SystemAudioCaptureException(SystemAudioErrorCode.fromWire(e.code), e.message);
    } on MissingPluginException catch (e) {
      _starting = false;
      await _cancelNative();
      throw SystemAudioCaptureException(SystemAudioErrorCode.unsupported, e.message);
    }
    _starting = false;
    _active = true;
    if (result?['mode'] == modeChunks) {
      final dir = result?['directory'];
      if (dir is! String) {
        await stop();
        throw const SystemAudioCaptureException(SystemAudioErrorCode.platform, 'no directory');
      }
      _chunkReader = BroadcastChunkReader(Directory(dir));
      _pollTimer = Timer.periodic(
        Duration(milliseconds: options.iosPollIntervalMs),
        (_) => unawaited(_drainChunks()),
      );
      unawaited(_drainChunks());
    }
  }

  Future<void> pause() async {
    if (!_active || _paused) return;
    _paused = true;
    await _invokeQuietly('pause');
  }

  Future<void> resume() async {
    if (!_active || !_paused) return;
    _paused = false;
    await _invokeQuietly('resume');
  }

  /// Stops capturing and releases native resources. Idempotent.
  Future<void> stop() => _stopping ??= _stop().whenComplete(() => _stopping = null);

  Future<void> _stop() async {
    if (!_active) {
      // Cancels a start that is still waiting for user consent (the start call then fails
      // with userCancelled).
      if (_starting) await _invokeQuietly('stop');
      await _cancelNative();
      return;
    }
    await _invokeQuietly('stop');
    // Emit what the extension wrote before it stopped, then clean up.
    await _drainChunks(force: true);
    await _chunkReader?.clear();
    _chunkReader = null;
    _active = false;
    _paused = false;
    await _cancelNative();
  }

  /// Stops and closes the streams. The instance can't be used afterwards.
  Future<void> dispose() async {
    await stop();
    await Future.wait([_pcm.close(), _level.close(), _events.close()]);
  }

  void _listenNative() {
    _subscriptions
      ..add(_pcmChannel.receiveBroadcastStream().listen(_onPcm, onError: _onNativeError))
      ..add(_levelChannel.receiveBroadcastStream().listen(_onLevel, onError: _onNativeError))
      ..add(_eventChannel.receiveBroadcastStream().listen(_onEvent, onError: _onNativeError));
  }

  Future<void> _cancelNative() async {
    _pollTimer?.cancel();
    _pollTimer = null;
    final subs = List.of(_subscriptions);
    _subscriptions.clear();
    for (final s in subs) {
      await s.cancel();
    }
  }

  void _onPcm(Object? data) {
    if (_paused || !(_active || _starting)) return;
    if (data is Uint8List && data.isNotEmpty) _pcm.add(data);
  }

  void _onLevel(Object? data) {
    if (_paused || !(_active || _starting)) return;
    if (data is num) _level.add(data.toDouble().clamp(0.0, 1.0));
  }

  void _onEvent(Object? data) {
    if (data is! Map) return;
    switch (data['type']) {
      case 'chunksAvailable':
        unawaited(_drainChunks());
      case 'interrupted':
        _events.add(const SystemAudioInterrupted());
      case 'interruptionEnded':
        _events.add(const SystemAudioInterruptionEnded());
      case 'stoppedExternally':
        final reason = data['reason'] as String?;
        unawaited(
          _drainChunks(force: true)
              .whenComplete(() => _events.add(SystemAudioStoppedExternally(reason))),
        );
      case 'failed':
        _events.add(
          SystemAudioFailed(
            SystemAudioCaptureException(
              SystemAudioErrorCode.fromWire(data['code'] as String?),
              data['message'] as String?,
            ),
          ),
        );
    }
  }

  void _onNativeError(Object error) {
    final e = error is PlatformException
        ? SystemAudioCaptureException(SystemAudioErrorCode.fromWire(error.code), error.message)
        : SystemAudioCaptureException(SystemAudioErrorCode.platform, '$error');
    _events.add(SystemAudioFailed(e));
  }

  Future<void> _drainChunks({bool force = false}) async {
    final reader = _chunkReader;
    final options = _options;
    if (reader == null || options == null || (!_active && !force)) return;
    final List<Uint8List> chunks;
    try {
      chunks = await reader.drain();
    } on FileSystemException catch (e) {
      _events.add(
        SystemAudioFailed(SystemAudioCaptureException(SystemAudioErrorCode.platform, e.message)),
      );
      return;
    }
    if (_paused) return; // Consumed (and deleted) but dropped while paused.
    for (final chunk in chunks) {
      _pcm.add(chunk);
      _level.add(pcm16Level(chunk, options.levelFloorDb));
    }
  }

  Future<void> _invokeQuietly(String method) async {
    try {
      await _method.invokeMethod<void>(method);
    } on PlatformException catch (e) {
      _events.add(
        SystemAudioFailed(
          SystemAudioCaptureException(SystemAudioErrorCode.fromWire(e.code), e.message),
        ),
      );
    } on MissingPluginException {
      // Nothing to release.
    }
  }
}

/// Level of mono PCM16 LE [bytes]: RMS in dBFS mapped linearly from [floorDb]..0 to 0..1
/// (same mapping as the native side).
@visibleForTesting
double pcm16Level(Uint8List bytes, double floorDb) {
  final samples = bytes.length ~/ 2;
  if (samples == 0 || floorDb >= 0) return 0;
  final data = ByteData.sublistView(bytes);
  var sum = 0.0;
  for (var i = 0; i < samples; i++) {
    final s = data.getInt16(i * 2, Endian.little) / 32768.0;
    sum += s * s;
  }
  final rms = math.sqrt(sum / samples);
  if (rms <= 0) return 0;
  final db = 20 * math.log(rms) / math.ln10;
  return ((db - floorDb) / -floorDb).clamp(0.0, 1.0);
}
