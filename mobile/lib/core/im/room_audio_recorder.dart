import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:deeprespond_im/deeprespond_im.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:uuid/uuid.dart';

/// The server recording contract is PCM16 LE, mono, 16 kHz.
abstract final class RoomAudioFormat {
  static const sampleRate = 16000;
  static const channels = 1;
  static const sampleBytes = 2;
}

typedef DetachAudio = Future<void> Function();

abstract interface class RoomAudioSource {
  DetachAudio attach(Object track, void Function(Uint8List) onData);
}

/// Observes SDK-authorized tracks. Removing a renderer never stops the RTC track.
class LiveKitRoomAudioSource implements RoomAudioSource {
  @override
  DetachAudio attach(Object track, void Function(Uint8List) onData) {
    if (track is! lk.AudioTrack) throw UnsupportedError('RTC audio track renderer unavailable');
    final remove = track.addAudioRenderer(
      onFrame: (frame) {
        if (frame.format != lk.AudioFormat.Int16 ||
            frame.sampleRate != RoomAudioFormat.sampleRate ||
            frame.channels != RoomAudioFormat.channels) {
          return;
        }
        onData(frame.data);
      },
      options: const lk.AudioRendererOptions(
        sampleRate: RoomAudioFormat.sampleRate,
        channels: RoomAudioFormat.channels,
        format: lk.AudioFormat.Int16,
      ),
    );
    return () async {
      await remove();
    };
  }
}

class _Capture {
  _Capture(this.participantId);
  final String participantId;
  final bytes = BytesBuilder(copy: false);
  double start = 0;
  DetachAudio? detach;
  Timer? watchdog;
}

/// Bounded upload queue, stable chunk IDs and a mandatory final flush before
/// stop/end. Failed uploads retain exactly the same bytes for idempotent retry.
class RoomAudioRecorder {
  RoomAudioRecorder({
    required this.epoch,
    required this.startedAt,
    required this.source,
    required this.upload,
    required this.report,
    required this.chunkMs,
    required this.maxPending,
    required this.frameTimeout,
    required this.retryDelay,
    DateTime Function()? now,
  }) : assert(chunkMs > 0 && chunkMs <= 10000),
       assert(maxPending > 0),
       now = now ?? DateTime.now;
  final int epoch, chunkMs, maxPending;
  final DateTime startedAt;
  final RoomAudioSource source;
  final Future<void> Function(Map<String, Object?> chunk) upload;
  final void Function(String state, String? error) report;
  final Duration frameTimeout, retryDelay;
  final DateTime Function() now;
  final _captures = Map<Object, _Capture>.identity();
  final _pending = Queue<Map<String, Object?>>();
  Future<void>? _draining;
  Future<void> _detaching = Future.value();
  Timer? _retry;
  bool _closed = false, _finishing = false, _backlogged = false;
  List<ChannelTrack> _tracks = [];
  Map<String, String> _members = {};
  int get pendingCount => _pending.length;

  void sync(List<ChannelTrack> tracks, Map<String, String> members) {
    _tracks = tracks;
    _members = members;
    if (_closed || _finishing || _backlogged) return;
    final authorized = <Object, String>{};
    for (final track in tracks) {
      final member = members[track.username];
      if (track.kind == 'audio' && member != null) authorized[track.track] = member;
    }
    for (final key in _captures.keys.toList()) {
      if (authorized[key] != _captures[key]!.participantId) _remove(key);
    }
    for (final entry in authorized.entries) {
      if (_captures.containsKey(entry.key)) continue;
      final capture = _Capture(entry.value);
      _captures[entry.key] = capture;
      try {
        capture.watchdog = Timer(frameTimeout, () {
          if (!_closed && _captures[entry.key] == capture) {
            report('error', 'audio_frames_unavailable');
          }
        });
        capture.detach = source.attach(entry.key, (data) {
          if (_closed || _finishing || _backlogged || _captures[entry.key] != capture) return;
          if (data.isEmpty || data.length.isOdd) return;
          capture.watchdog?.cancel();
          final maxBytes =
              RoomAudioFormat.sampleRate * RoomAudioFormat.sampleBytes * chunkMs ~/ 1000;
          // A native callback can contain more than one chunk. Split rather than
          // ever sending a segment above the backend's ten-second limit.
          var offset = 0;
          while (offset < data.length && !_backlogged) {
            if (capture.bytes.isEmpty) {
              capture.start =
                  (now().difference(startedAt).inMicroseconds / 1000000 -
                          (data.length - offset) /
                              (RoomAudioFormat.sampleRate * RoomAudioFormat.sampleBytes))
                      .clamp(0, double.infinity);
            }
            final count = (maxBytes - capture.bytes.length).clamp(0, data.length - offset);
            capture.bytes.add(Uint8List.sublistView(data, offset, offset + count));
            offset += count;
            if (capture.bytes.length >= maxBytes) _flush(capture);
          }
          if (!_backlogged && _pending.isEmpty) report('recording', null);
        });
      } on Object catch (error) {
        capture.watchdog?.cancel();
        _captures.remove(entry.key);
        report('error', error.toString());
      }
    }
    if (_captures.isEmpty && _pending.isEmpty) report('waiting', null);
  }

  void _flush(_Capture capture) {
    if (capture.bytes.isEmpty || _closed) return;
    _pending.add({
      'chunkId': const Uuid().v4(),
      'participantId': capture.participantId,
      'startTime': capture.start,
      'pcm': base64Encode(capture.bytes.takeBytes()),
      'epoch': epoch,
    });
    if (_pending.length >= maxPending && !_backlogged) {
      _backlogged = true;
      for (final key in _captures.keys.toList()) {
        _remove(key);
      }
      report('error', 'recording_backlog');
    }
    unawaited(_drain().catchError((Object _) {}));
  }

  void _remove(Object key) {
    final capture = _captures.remove(key);
    if (capture == null) return;
    capture.watchdog?.cancel();
    _flush(capture);
    final detach = capture.detach;
    if (detach != null) _detaching = _detaching.then((_) => detach());
  }

  Future<void> _drain() {
    if (_draining != null) return _draining!;
    if (_pending.isEmpty || _closed) return Future.value();
    final work = () async {
      try {
        while (_pending.isNotEmpty && !_closed) {
          report('uploading', null);
          await upload(_pending.first);
          _pending.removeFirst();
        }
        if (!_closed) report(_finishing ? 'stopped' : 'waiting', null);
      } on Object catch (error) {
        if (!_closed) {
          report('error', error.toString());
          _retry?.cancel();
          _retry = Timer(retryDelay, () => unawaited(retry().catchError((Object _) {})));
        }
        rethrow;
      }
    }();
    _draining = work;
    // Both handlers consume their derived future; callers own the work error.
    unawaited(
      work.then(
        (_) {
          _draining = null;
        },
        onError: (Object _, StackTrace _) {
          _draining = null;
        },
      ),
    );
    return work;
  }

  Future<void> retry() async {
    _retry?.cancel();
    await _draining?.catchError((Object _) {});
    await _drain();
    if (_backlogged && !_finishing && !_closed) {
      _backlogged = false;
      sync(_tracks, _members);
    }
  }

  Future<void> finish() async {
    _finishing = true;
    for (final key in _captures.keys.toList()) {
      _remove(key);
    }
    await _detaching;
    await retry();
  }

  /// When end/stop fails, capture may resume on the same still-active epoch.
  void resume() {
    if (_closed) return;
    _finishing = false;
    if (_pending.length < maxPending) _backlogged = false;
    sync(_tracks, _members);
  }

  Future<void> dispose() async {
    if (_closed) return;
    _closed = true;
    _retry?.cancel();
    for (final key in _captures.keys.toList()) {
      _remove(key);
    }
    await _detaching;
    await _draining?.catchError((Object _) {});
    _pending.clear();
  }
}
