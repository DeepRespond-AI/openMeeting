import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:system_audio_capture/system_audio_capture.dart';

String _name(int i) => 'chunk_${i.toString().padLeft(12, '0')}.pcm';

void main() {
  late Directory dir;
  late BroadcastChunkReader reader;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('chunks');
    reader = BroadcastChunkReader(dir);
  });

  tearDown(() => dir.deleteSync(recursive: true));

  void write(int index, List<int> bytes) =>
      File('${dir.path}/${_name(index)}').writeAsBytesSync(bytes);

  List<String> files() => dir.listSync().map((e) => e.uri.pathSegments.last).toList()..sort();

  test('parseIndex accepts only complete chunk files', () {
    expect(BroadcastChunkReader.parseIndex(_name(42)), 42);
    expect(BroadcastChunkReader.parseIndex('${_name(1)}.tmp'), isNull);
    expect(BroadcastChunkReader.parseIndex('state.json'), isNull);
    expect(BroadcastChunkReader.parseIndex('chunk_x.pcm'), isNull);
  });

  test('reads chunks in index order and deletes them', () async {
    write(1, [3, 4]);
    write(0, [1, 2]);
    write(2, [5, 6]);
    final chunks = await reader.drain();
    expect(chunks, [
      Uint8List.fromList([1, 2]),
      Uint8List.fromList([3, 4]),
      Uint8List.fromList([5, 6]),
    ]);
    expect(reader.nextIndex, 3);
    expect(files(), isEmpty);
  });

  test('ignores temp files still being written', () async {
    write(0, [1]);
    File('${dir.path}/${_name(1)}.tmp').writeAsBytesSync([9]);
    expect(await reader.drain(), [
      Uint8List.fromList([1]),
    ]);
    expect(files(), ['${_name(1)}.tmp']);
    expect(reader.nextIndex, 1);
  });

  test('continues across drains and skips chunks dropped by the extension', () async {
    write(0, [1]);
    await reader.drain();
    write(3, [4]); // 1 and 2 were trimmed from the backlog by the extension
    write(4, [5]);
    expect(await reader.drain(), [
      Uint8List.fromList([4]),
      Uint8List.fromList([5]),
    ]);
    expect(reader.skippedChunks, 2);
    expect(reader.nextIndex, 5);
  });

  test('deletes stale chunks older than the expected index', () async {
    write(0, [1]);
    write(1, [2]);
    await reader.drain();
    write(0, [7]); // leftover, e.g. after a crash
    write(2, [3]);
    expect(await reader.drain(), [
      Uint8List.fromList([3]),
    ]);
    expect(files(), isEmpty);
  });

  test('concurrent drains never emit a chunk twice', () async {
    for (var i = 0; i < 20; i++) {
      write(i, [i]);
    }
    final results = await Future.wait([reader.drain(), reader.drain(), reader.drain()]);
    final emitted = [for (final r in results) ...r.map((c) => c.first)];
    expect(emitted, List.generate(20, (i) => i));
  });

  test('clear removes everything and resets the index', () async {
    write(0, [1]);
    await reader.drain();
    write(5, [1]);
    File('${dir.path}/${_name(6)}.tmp').writeAsBytesSync([1]);
    await reader.clear();
    expect(files(), isEmpty);
    expect(reader.nextIndex, 0);
  });

  test('missing directory yields nothing', () async {
    final r = BroadcastChunkReader(Directory('${dir.path}/missing'));
    expect(await r.drain(), isEmpty);
    await r.clear();
  });
}
