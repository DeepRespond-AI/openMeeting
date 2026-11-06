import 'dart:typed_data';

import 'package:aac_writer/aac_writer.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/aac_writer.dart';

part 'aac_writer_impl.g.dart';

/// [AacWriter] backed by the local `aac_writer` plugin (MediaCodec / AVAudioFile).
class PluginAacWriter implements AacWriter {
  PluginAacWriter([NativeAacWriter? native]) : _native = native ?? NativeAacWriter();

  final NativeAacWriter _native;

  @override
  Future<void> open({
    required String path,
    required int sampleRate,
    required int channels,
    required int bitrate,
  }) => _native.open(path: path, sampleRate: sampleRate, channels: channels, bitrate: bitrate);

  @override
  Future<void> write(Uint8List pcm16) => _native.write(pcm16);

  @override
  Future<void> close() => _native.close();
}

/// Creates one writer per recording. Override in tests with a fake factory.
@Riverpod(keepAlive: true)
AacWriterFactory aacWriterFactory(Ref ref) => PluginAacWriter.new;
