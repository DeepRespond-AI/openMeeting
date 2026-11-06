import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/segment_upload.dart';
import 'recording_storage.dart';
import 'serial_executor.dart';

part 'pending_queue.g.dart';

/// Persistent FIFO of segment uploads that failed (offline, server errors), flushed in order
/// later. Survives app restarts: one `.pcm` file per segment plus a small JSON index
/// (`index.json`, rewritten atomically). All operations are serialized.
class PendingQueue {
  PendingQueue(this._dir);

  static const String _indexFile = 'index.json';
  static const String _indexTmpFile = 'index.json.tmp';
  static const String _pcmExtension = '.pcm';
  static const String _entriesKey = 'entries';

  final Future<Directory> Function() _dir;
  final SerialExecutor _serial = SerialExecutor();
  final StreamController<int> _changes = StreamController<int>.broadcast();
  List<SegmentUpload>? _cache;

  /// Emits the total number of queued segments after every change.
  Stream<int> get changes => _changes.stream;

  /// Queued uploads in FIFO order, optionally only those of [meetingId].
  Future<List<SegmentUpload>> entries({String? meetingId}) => _serial.run(() async {
    final all = await _load();
    return [
      for (final e in all)
        if (meetingId == null || e.meetingId == meetingId) e,
    ];
  });

  Future<int> count({String? meetingId}) async => (await entries(meetingId: meetingId)).length;

  /// Stores [pcm] and appends [upload] (replacing an entry with the same meeting/seq).
  Future<void> add(SegmentUpload upload, Uint8List pcm) => _serial.run(() async {
    final dir = await _dir();
    await File(_pcmPath(dir, upload)).writeAsBytes(pcm, flush: true);
    final all = await _load();
    all
      ..removeWhere((e) => _same(e, upload))
      ..add(upload);
    await _save(dir, all);
  });

  /// The stored PCM of [upload].
  Future<Uint8List> read(SegmentUpload upload) => _serial.run(() async {
    final dir = await _dir();
    return File(_pcmPath(dir, upload)).readAsBytes();
  });

  /// Removes [upload] and its PCM file (no-op when absent).
  Future<void> remove(SegmentUpload upload) => _serial.run(() async {
    final dir = await _dir();
    final all = await _load();
    final before = all.length;
    all.removeWhere((e) => _same(e, upload));
    if (all.length != before) await _save(dir, all);
    final file = File(_pcmPath(dir, upload));
    if (file.existsSync()) await file.delete();
  });

  Future<void> dispose() => _changes.close();

  Future<List<SegmentUpload>> _load() async {
    if (_cache case final cached?) return cached;
    final dir = await _dir();
    final file = File(_join(dir, _indexFile));
    var loaded = <SegmentUpload>[];
    if (file.existsSync()) {
      try {
        final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        loaded = [
          for (final item in json[_entriesKey] as List<dynamic>)
            SegmentUpload.fromJson(item as Map<String, dynamic>),
        ];
        // Drop index entries whose audio file is gone.
        loaded = [
          for (final e in loaded)
            if (File(_pcmPath(dir, e)).existsSync()) e,
        ];
      } on Object {
        loaded = [];
      }
    }
    return _cache = loaded;
  }

  Future<void> _save(Directory dir, List<SegmentUpload> all) async {
    final tmp = File(_join(dir, _indexTmpFile));
    await tmp.writeAsString(
      jsonEncode({
        _entriesKey: [for (final e in all) e.toJson()],
      }),
      flush: true,
    );
    await tmp.rename(_join(dir, _indexFile));
    _cache = all;
    if (!_changes.isClosed) _changes.add(all.length);
  }

  static bool _same(SegmentUpload a, SegmentUpload b) =>
      a.meetingId == b.meetingId && a.seq == b.seq;

  static String _join(Directory dir, String name) => '${dir.path}${Platform.pathSeparator}$name';

  static String _pcmPath(Directory dir, SegmentUpload u) =>
      _join(dir, '${Uri.encodeComponent(u.meetingId)}_${u.seq}$_pcmExtension');
}

@Riverpod(keepAlive: true)
PendingQueue pendingQueue(Ref ref) {
  final queue = PendingQueue(ref.watch(recordingStorageProvider).pendingQueueDir);
  ref.onDispose(queue.dispose);
  return queue;
}
