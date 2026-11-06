import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meeting/core/config/app_config.dart';
import 'package:meeting/features/recording/data/pending_queue.dart';
import 'package:meeting/features/recording/data/recording_repository_impl.dart';
import 'package:meeting/features/recording/data/segment_uploader.dart';
import 'package:meeting/features/recording/domain/segment_upload.dart';

import '../../helpers/test_config.dart';

SegmentUpload upload(int seq, {String? language}) => SegmentUpload(
  meetingId: 'm1',
  seq: seq,
  startSec: seq * 2.0,
  endSec: seq * 2.0 + 1.23456,
  language: language,
);

void main() {
  final config = loadConfigFile('dev');
  late Directory dir;
  late Dio dio;
  late PendingQueue queue;
  late StreamController<bool> online;
  late List<Duration> sleeps;
  late SegmentUploader uploader;

  SegmentUploader create({RetryConfig? policy}) => SegmentUploader(
    repository: DioRecordingRepository(dio, config),
    queue: queue,
    policy: policy ?? config.network.retry,
    onlineChanges: online.stream,
    sleep: (d) async => sleeps.add(d),
  );

  setUp(() {
    dir = Directory.systemTemp.createTempSync('segment_uploader_test');
    dio = Dio(BaseOptions(baseUrl: 'http://server'));
    queue = PendingQueue(() async => dir);
    online = StreamController<bool>.broadcast();
    sleeps = [];
    uploader = create();
  });

  tearDown(() async {
    await uploader.dispose();
    await online.close();
    dir.deleteSync(recursive: true);
  });

  StubAdapter answer(int status, [Object body = const <String, Object?>{}]) {
    final adapter = StubAdapter(status, body);
    dio.httpClientAdapter = adapter;
    return adapter;
  }

  Map<String, Object?> ok(int seq) => {'id': 't$seq', 'text': 'text $seq', 'seq': seq};

  test('uploads PCM with seq, 3-decimal start/end and octet-stream body', () async {
    final adapter = answer(200, ok(0));
    final results = <SegmentUploadResult>[];
    uploader.results.listen(results.add);

    await uploader.submit(upload(0, language: 'zh'), Uint8List.fromList([1, 2, 3, 4]));
    await uploader.submit(upload(1), Uint8List.fromList([5, 6]));
    await Future<void>.delayed(Duration.zero);

    final first = adapter.requests.first;
    expect(first.method, 'POST');
    expect(first.uri.path, '/api/v1/meetings/m1/segments');
    expect(first.uri.queryParameters, {
      'seq': '0',
      'start': '0.000',
      'end': '1.235',
      'language': 'zh',
    });
    expect(first.contentType, config.recording.segmentContentType);
    // Auto language → parameter omitted.
    expect(adapter.requests[1].uri.queryParameters.containsKey('language'), isFalse);
    expect(results.map((r) => r.text), ['text 0', 'text 0']);
    expect(results.first.transcriptId, 't0');
    expect(await queue.count(), 0);
  });

  test('retries retryable errors per config, then queues the segment', () async {
    final adapter = answer(503, {'detail': 'busy'});
    await uploader.submit(upload(0), Uint8List.fromList([1, 2]));

    expect(adapter.requests, hasLength(1 + config.network.retry.maxRetries));
    expect(sleeps, [
      for (var i = 0; i < config.network.retry.maxRetries; i++) config.network.retry.delayFor(i),
    ]);
    expect(await queue.entries(), [upload(0)]);
  });

  test('while the queue is not empty, new segments queue behind it in order', () async {
    answer(503);
    await uploader.submit(upload(0), Uint8List.fromList([1]));
    final adapter = answer(200, ok(1));
    await uploader.submit(upload(1), Uint8List.fromList([2]));

    // Suspended after the failure: nothing sent, order preserved.
    expect(adapter.requests, isEmpty);
    expect((await queue.entries()).map((e) => e.seq), [0, 1]);
  });

  test('connectivity regained flushes the queue in order', () async {
    answer(503);
    await uploader.submit(upload(0), Uint8List.fromList([1]));
    await uploader.submit(upload(1), Uint8List.fromList([2]));
    await uploader.submit(upload(2), Uint8List.fromList([3]));
    final adapter = answer(200, ok(0));
    final results = <SegmentUploadResult>[];
    uploader.results.listen(results.add);

    online.add(true);
    await uploader.flush();

    expect(adapter.requests.map((r) => r.uri.queryParameters['seq']), ['0', '1', '2']);
    expect(results.map((r) => r.upload.seq), [0, 1, 2]);
    expect(await queue.count(), 0);
  });

  test('flush stops at the first failure and reports what is left', () async {
    answer(503);
    await uploader.submit(upload(0), Uint8List.fromList([1]));
    await uploader.submit(upload(1), Uint8List.fromList([2]));
    expect(await uploader.flush(meetingId: 'm1'), 2);
    expect(await uploader.flush(meetingId: 'other'), 0);
  });

  test('permanent rejections are dropped and reported, not queued', () async {
    answer(413, {'detail': 'too large'});
    final errors = <Object>[];
    uploader.errors.listen(errors.add);
    await uploader.submit(upload(0), Uint8List.fromList([1]));
    await Future<void>.delayed(Duration.zero);

    expect(errors, hasLength(1));
    expect(await queue.count(), 0);
    expect(sleeps, isEmpty);
  });

  test('a new uploader flushes segments left over from an earlier session', () async {
    answer(503);
    await uploader.submit(upload(0), Uint8List.fromList([1]));
    await uploader.dispose();

    final adapter = answer(200, ok(0));
    uploader = create();
    expect(await uploader.flush(), 0);
    expect(adapter.requests, hasLength(1));
  });
}
