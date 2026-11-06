import 'dart:io';
import 'dart:typed_data';

/// Reads the PCM chunk files the iOS broadcast extension writes into the App Group
/// container, strictly in index order, deleting each chunk once consumed.
///
/// Wire format (shared with `ios/BroadcastExtension/SampleHandler.swift`): the extension
/// writes `<tmp>` first and atomically renames it to `chunk_<index>.pcm`, where `<index>` is a
/// zero-padded, monotonically increasing integer starting at 0. A file with the final name is
/// therefore always complete. When the app falls behind, the extension deletes the oldest
/// unread chunks; the reader then skips the gap and continues with the oldest remaining one.
class BroadcastChunkReader {
  BroadcastChunkReader(this.directory);

  static const String chunkPrefix = 'chunk_';
  static const String chunkSuffix = '.pcm';

  final Directory directory;

  int _next = 0;
  int _skipped = 0;
  Future<void> _tail = Future.value();

  /// Index of the next chunk expected.
  int get nextIndex => _next;

  /// Number of chunks lost because the extension dropped them before they were read.
  int get skippedChunks => _skipped;

  /// The chunk index encoded in [fileName], or `null` if it is not a complete chunk file.
  static int? parseIndex(String fileName) {
    if (!fileName.startsWith(chunkPrefix) || !fileName.endsWith(chunkSuffix)) return null;
    return int.tryParse(
      fileName.substring(chunkPrefix.length, fileName.length - chunkSuffix.length),
    );
  }

  /// Reads every available chunk from [nextIndex] on, in order, and deletes it.
  /// Concurrent calls are serialized: each chunk is returned by exactly one call.
  Future<List<Uint8List>> drain() {
    final pass = _tail.then((_) => _drain());
    _tail = pass.then<void>((_) {}, onError: (Object _) {});
    return pass;
  }

  Future<List<Uint8List>> _drain() async {
    if (!directory.existsSync()) return const [];
    final byIndex = <int, File>{};
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is! File) continue;
      final index = parseIndex(entity.uri.pathSegments.last);
      if (index != null) byIndex[index] = entity;
    }
    final indices = byIndex.keys.toList()..sort();
    final out = <Uint8List>[];
    for (final index in indices) {
      final file = byIndex[index]!;
      if (index < _next) {
        // Stale (already consumed but not deleted, e.g. after a crash).
        await _delete(file);
        continue;
      }
      if (index > _next) _skipped += index - _next;
      final Uint8List bytes;
      try {
        bytes = await file.readAsBytes();
      } on FileSystemException {
        break; // Removed by the extension's backlog trimming meanwhile; next pass resyncs.
      }
      await _delete(file);
      _next = index + 1;
      if (bytes.isNotEmpty) out.add(bytes);
    }
    return out;
  }

  /// Deletes every chunk file (complete or not) and resets the expected index.
  /// Runs after any drain already in progress.
  Future<void> clear() {
    final pass = _tail.then((_) => _clear());
    _tail = pass.then<void>((_) {}, onError: (Object _) {});
    return pass;
  }

  Future<void> _clear() async {
    _next = 0;
    _skipped = 0;
    if (!directory.existsSync()) return;
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is File) await _delete(entity);
    }
  }

  static Future<void> _delete(File file) async {
    try {
      await file.delete();
    } on FileSystemException {
      // Already gone.
    }
  }
}
