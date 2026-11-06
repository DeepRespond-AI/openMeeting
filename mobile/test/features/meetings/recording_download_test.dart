import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meeting/features/meetings/data/recording_download.dart';

class AudioAdapter implements HttpClientAdapter {
  int status = 200, requests = 0;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests++;
    return ResponseBody.fromBytes(
      List.generate(32044, (i) => i % 256),
      status,
      headers: {
        'content-disposition': ['attachment; filename="recording.wav"'],
        'content-type': ['audio/wav'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Directory dir;
  late Dio dio;
  late AudioAdapter adapter;
  late RecordingFiles files;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('meeting-download-');
    adapter = AudioAdapter();
    dio = Dio(BaseOptions(baseUrl: 'http://localhost'))..httpClientAdapter = adapter;
    files = RecordingFiles(
      dio: dio,
      directory: () async => dir,
      export: (_) async {},
      folder: 'recordings',
      timeout: const Duration(seconds: 2),
    );
  });
  tearDown(() async {
    dio.close();
    await dir.delete(recursive: true);
  });
  test('real file published only after complete download and partitioned per account', () async {
    final a = await files.download('meeting-1', 'owner', CancelToken());
    final b = await files.download('meeting-1', 'member', CancelToken());
    expect(await a.length(), 32044);
    expect(a.path.endsWith('.wav'), isTrue);
    expect(a.parent.path, isNot(b.parent.path));
    expect(
      dir.listSync(recursive: true).whereType<File>().any((f) => f.path.endsWith('.part')),
      isFalse,
    );
  });
  test('503 removes partial transfer without deleting a previously saved recording', () async {
    final saved = await files.download('meeting-1', 'owner', CancelToken());
    adapter.status = 503;
    await expectLater(files.download('meeting-1', 'owner', CancelToken()), throwsA(anything));
    expect(saved.existsSync(), isTrue);
    expect(dir.listSync(recursive: true).whereType<File>().length, 1);
  });
  test('cancelled transfer never reports a published file', () async {
    final cancel = CancelToken()..cancel();
    await expectLater(files.download('meeting-1', 'owner', cancel), throwsA(anything));
    expect(dir.listSync(recursive: true).whereType<File>(), isEmpty);
  });
  test('untrusted record path rejected before making a request', () async {
    await expectLater(files.download('../outside', 'owner', CancelToken()), throwsA(anything));
    expect(adapter.requests, 0);
  });
}
