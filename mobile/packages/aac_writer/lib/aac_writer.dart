/// Streams PCM16 audio into an AAC-LC `.m4a` file using the platform encoders
/// (Android MediaCodec + MediaMuxer, iOS AVAudioFile).
library;

import 'dart:async';

import 'package:flutter/services.dart';

/// One encoder session writing one file.
///
/// ```dart
/// final writer = NativeAacWriter();
/// await writer.open(path: p, sampleRate: 16000, channels: 1, bitrate: 32000);
/// await writer.write(pcm16le);
/// await writer.close();
/// ```
///
/// Calls are serialized: [write] completes after the chunk was encoded on the native side,
/// so awaiting it (or the [pending] future) applies backpressure.
class NativeAacWriter {
  NativeAacWriter({MethodChannel? channel})
    : _channel = channel ?? defaultChannel;

  static const MethodChannel defaultChannel = MethodChannel(
    'cn.deeprespond.aac_writer',
  );

  final MethodChannel _channel;
  int? _handle;
  Future<void> _tail = Future<void>.value();

  bool get isOpen => _handle != null;

  /// Completes when every call issued so far has finished.
  Future<void> get pending => _tail;

  Future<void> open({
    required String path,
    required int sampleRate,
    required int channels,
    required int bitrate,
  }) => _serial(() async {
    if (_handle != null) throw StateError('NativeAacWriter already open');
    _handle = await _channel.invokeMethod<int>('open', {
      'path': path,
      'sampleRate': sampleRate,
      'channels': channels,
      'bitrate': bitrate,
    });
  });

  /// Appends little-endian PCM16 samples (interleaved when [channels] > 1).
  Future<void> write(Uint8List pcm16) => _serial(() async {
    final handle = _handle;
    if (handle == null) throw StateError('NativeAacWriter not open');
    if (pcm16.isEmpty) return;
    await _channel.invokeMethod<void>('write', {
      'handle': handle,
      'data': pcm16,
    });
  });

  /// Drains the encoder and finalizes the file. Idempotent.
  Future<void> close() => _serial(() async {
    final handle = _handle;
    if (handle == null) return;
    _handle = null;
    await _channel.invokeMethod<void>('close', {'handle': handle});
  });

  Future<T> _serial<T>(Future<T> Function() task) {
    final result = _tail.then((_) => task());
    _tail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }
}
