import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meeting/features/recording/data/pending_queue.dart';
import 'package:meeting/features/recording/domain/segment_upload.dart';

SegmentUpload upload(int seq, {String meeting = 'm1', String? language}) => SegmentUpload(
  meetingId: meeting,
  seq: seq,
  startSec: seq * 1.0,
  endSec: seq + 0.5,
  language: language,
);

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('pending_queue_test'));
  tearDown(() => dir.deleteSync(recursive: true));

  PendingQueue open() => PendingQueue(() async => dir);

  test('keeps FIFO order and the PCM of each entry', () async {
    final q = open();
    await q.add(upload(2), Uint8List.fromList([2, 2]));
    await q.add(upload(0, meeting: 'm2'), Uint8List.fromList([9]));
    await q.add(upload(3, language: 'zh'), Uint8List.fromList([3, 3, 3]));

    final all = await q.entries();
    expect(all.map((e) => '${e.meetingId}/${e.seq}'), ['m1/2', 'm2/0', 'm1/3']);
    expect(await q.entries(meetingId: 'm1'), [upload(2), upload(3, language: 'zh')]);
    expect(await q.read(upload(3)), [3, 3, 3]);
    expect(await q.count(), 3);
  });

  test('persists across instances (app restart)', () async {
    final q = open();
    await q.add(upload(0), Uint8List.fromList([1]));
    await q.add(upload(1), Uint8List.fromList([2]));

    final reopened = open();
    expect(await reopened.entries(), [upload(0), upload(1)]);
    expect(await reopened.read(upload(1)), [2]);
  });

  test('remove deletes the entry and its file; re-adding a seq replaces it', () async {
    final q = open();
    await q.add(upload(0), Uint8List.fromList([1]));
    await q.add(upload(1), Uint8List.fromList([2]));
    await q.remove(upload(0));
    await q.add(upload(1), Uint8List.fromList([5]));

    expect(await q.entries(), [upload(1)]);
    expect(await q.read(upload(1)), [5]);
    final pcmFiles = dir.listSync().where((f) => f.path.endsWith('.pcm'));
    expect(pcmFiles, hasLength(1));
    expect(await open().entries(), [upload(1)]);
  });

  test('emits the queue size on changes', () async {
    final q = open();
    final sizes = <int>[];
    final sub = q.changes.listen(sizes.add);
    await q.add(upload(0), Uint8List.fromList([1]));
    await q.add(upload(1), Uint8List.fromList([1]));
    await q.remove(upload(0));
    await Future<void>.delayed(Duration.zero);
    expect(sizes, [1, 2, 1]);
    await sub.cancel();
  });

  test('a corrupt index is treated as empty; entries without audio are dropped', () async {
    File('${dir.path}/index.json').writeAsStringSync('{not json');
    expect(await open().entries(), isEmpty);

    final q = open();
    await q.add(upload(0), Uint8List.fromList([1]));
    await q.add(upload(1), Uint8List.fromList([1]));
    File('${dir.path}/m1_0.pcm').deleteSync();
    expect(await open().entries(), [upload(1)]);
  });
}
