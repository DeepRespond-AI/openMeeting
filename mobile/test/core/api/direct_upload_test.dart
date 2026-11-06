import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meeting/core/api/api_exception.dart';
import 'package:meeting/core/api/direct_upload.dart';

import '../../helpers/test_config.dart';

class UploadAdapter implements HttpClientAdapter {
  UploadAdapter(this.reply);
  final Future<(int, Object)> Function(RequestOptions, List<int>) reply;
  final requests = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final bytes = <int>[];
    if (requestStream != null) {
      await for (final chunk in requestStream) {
        bytes.addAll(chunk);
      }
    }
    final (status, data) = await reply(options, bytes);
    return ResponseBody.fromString(
      jsonEncode(data),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Directory dir;
  late File file;
  final network = loadConfigFile('dev').network;
  final payload = List.generate(150000, (i) => i % 251);
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('direct-upload-test-');
    file = await File('${dir.path}/recording.wav').writeAsBytes(payload);
  });
  tearDown(() async => dir.delete(recursive: true));
  Dio client(UploadAdapter adapter, {bool business = false}) => Dio(
    BaseOptions(
      baseUrl: 'http://api.test',
      headers: business ? {'Authorization': 'Bearer business-session'} : {},
    ),
  )..httpClientAdapter = adapter;
  Map<String, Object> offer({Map<String, String> headers = const {'Content-Type': 'audio/wav'}}) =>
      {
        'mode': 'direct',
        'url': 'http://storage.test/scoped-object',
        'ticket': 'scoped-ticket',
        'headers': headers,
      };

  test('streaming digests, separate storage credentials, and confirmation before 100%', () async {
    final events = <String>[];
    final storage = UploadAdapter((request, bytes) async {
      expect(request.headers.keys.any((key) => key.toLowerCase() == 'cookie'), isFalse);
      expect(request.headers['Authorization'], startsWith('AWS4-HMAC-SHA256 '));
      expect(bytes, payload);
      events.add('PUT');
      return (200, <String, Object>{});
    });
    final api = UploadAdapter((request, bytes) async {
      expect(request.headers['Authorization'], 'Bearer business-session');
      if (request.path.endsWith('/complete')) {
        expect(events, ['PUT']);
        events.add('confirmed');
        return (200, {'size': payload.length});
      }
      final proof = request.data as Map;
      expect(proof['sha256'], sha256.convert(payload).toString());
      expect(proof['md5'], base64Encode(md5.convert(payload).bytes));
      expect(proof['size'], payload.length);
      expect(proof['duration'], 1.25);
      return (
        200,
        offer(
          headers: {
            'Content-Type': 'audio/wav',
            'Authorization': 'AWS4-HMAC-SHA256 scoped-signature',
          },
        ),
      );
    });
    final result = await directFileUpload(
      client(api, business: true),
      network,
      '/audio',
      file,
      fileName: 'recording.wav',
      extra: {'duration': 1.25},
      storageClient: client(storage),
      onProgress: (sent, total) {
        if (sent == total) expect(events.last, 'confirmed');
      },
    );
    expect(result?['size'], payload.length);
    expect(file.existsSync(), isTrue);
    expect(events, ['PUT', 'confirmed']);
  });
  for (final status in [403, 503]) {
    test('storage $status keeps local file and never confirms or falls back', () async {
      final api = UploadAdapter((r, b) async => (200, offer()));
      final storage = UploadAdapter((r, b) async => (status, {'detail': 'storage outage'}));
      await expectLater(
        directFileUpload(
          client(api, business: true),
          network,
          '/audio',
          file,
          fileName: 'recording.wav',
          storageClient: client(storage),
        ),
        throwsA(isA<ApiException>().having((e) => e.isRetryable, 'retry policy', status == 503)),
      );
      expect(api.requests.length, 1);
      expect(file.existsSync(), isTrue);
    });
  }
  test('confirmation failure does not report success or delete retry source', () async {
    final api = UploadAdapter(
      (r, b) async =>
          r.path.endsWith('/complete') ? (502, {'detail': 'confirm failed'}) : (200, offer()),
    );
    final storage = UploadAdapter((r, b) async => (200, <String, Object>{}));
    var complete = false;
    await expectLater(
      directFileUpload(
        client(api),
        network,
        '/audio',
        file,
        fileName: 'recording.wav',
        storageClient: client(storage),
        onProgress: (n, total) {
          if (n == total) complete = true;
        },
      ),
      throwsA(isA<DioException>()),
    );
    expect(complete, isFalse);
    expect(file.existsSync(), isTrue);
    expect(api.requests.length, 2);
  });
  for (final status in [200, 404, 405]) {
    test('explicit proxy or older server $status returns legacy marker without PUT', () async {
      final api = UploadAdapter((r, b) async => (status, {'mode': 'proxy'}));
      final storage = UploadAdapter((r, b) async => throw StateError('must not PUT'));
      expect(
        await directFileUpload(
          client(api),
          network,
          '/audio',
          file,
          fileName: 'recording.wav',
          storageClient: client(storage),
        ),
        isNull,
      );
      expect(storage.requests, isEmpty);
    });
  }
  test('cancel before hashing sends no requests', () async {
    final api = UploadAdapter((r, b) async => throw StateError('must not request'));
    await expectLater(
      directFileUpload(
        client(api),
        network,
        '/audio',
        file,
        fileName: 'recording.wav',
        cancelToken: CancelToken()..cancel(),
      ),
      throwsA(isA<DioException>()),
    );
    expect(api.requests, isEmpty);
  });
  test('business bearer in a storage offer is rejected', () async {
    final api = UploadAdapter(
      (r, b) async => (200, offer(headers: {'Authorization': 'Bearer leaked-session'})),
    );
    final storage = UploadAdapter((r, b) async => throw StateError('must not PUT'));
    await expectLater(
      directFileUpload(
        client(api),
        network,
        '/audio',
        file,
        fileName: 'recording.wav',
        storageClient: client(storage),
      ),
      throwsA(isA<FormatException>()),
    );
    expect(storage.requests, isEmpty);
  });
}
