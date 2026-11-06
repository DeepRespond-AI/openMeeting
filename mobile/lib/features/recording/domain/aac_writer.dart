import 'dart:typed_data';

/// Encodes PCM16 audio into an AAC-LC `.m4a` file while recording (≈15 MB/hour).
///
/// One instance per recording. [write] may be called without awaiting: writes are
/// applied in order, and the returned future completes once the chunk was handed to
/// the encoder (natural backpressure). [close] finalizes the file.
abstract interface class AacWriter {
  Future<void> open({
    required String path,
    required int sampleRate,
    required int channels,
    required int bitrate,
  });

  /// Appends little-endian PCM16 audio.
  Future<void> write(Uint8List pcm16);

  /// Flushes the encoder and finalizes the container. Idempotent.
  /// When nothing was written, the file may not exist afterwards.
  Future<void> close();
}

/// Creates a fresh [AacWriter] for each recording.
typedef AacWriterFactory = AacWriter Function();
