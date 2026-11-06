import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meeting/core/api/api_client.dart';
import 'package:meeting/core/api/api_exception.dart';
import 'package:meeting/features/meetings/data/meetings_repository_impl.dart';
import 'package:meeting/features/meetings/domain/meeting_audio_source.dart';

/// Adapter answering with a fixed status, headers and body; records requests.
class _Adapter implements HttpClientAdapter {
  _Adapter(this.status, {this.headers = const {}, this.body = ''});

  final int status;
  final Map<String, List<String>> headers;
  final String body;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(body, status, headers: headers);
  }

  @override
  void close({bool force = false}) {}
}

const _base = 'https://meeting.example.com';
const _token = 'ms_secret';

(DioMeetingsRepository, _Adapter) _repo(_Adapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: _base))
    ..httpClientAdapter = adapter
    ..interceptors.addAll([
      AuthInterceptor(tokenReader: () async => _token),
      ErrorMappingInterceptor(onSessionRejected: () {}),
    ]);
  return (DioMeetingsRepository(dio), adapter);
}

void main() {
  group('resolveAudio', () {
    test('302 → signed OSS URL without Authorization', () async {
      const oss = 'https://bucket.oss-cn-hangzhou.aliyuncs.com/audio/u/m1/audio.m4a?Signature=x';
      final (repo, adapter) = _repo(
        _Adapter(
          HttpStatus.found,
          headers: {
            HttpHeaders.locationHeader: [oss],
          },
        ),
      );

      final source = await repo.resolveAudio('m1');

      expect(source, MeetingAudioSource.redirect(Uri.parse(oss)));
      final probe = adapter.requests.single;
      expect(probe.followRedirects, isFalse);
      expect(probe.path, '/api/v1/meetings/m1/audio');
      expect(probe.headers['Range'], 'bytes=0-0');
    });

    test('206/200 → API URL streamed with the Bearer header', () async {
      final (repo, _) = _repo(
        _Adapter(
          HttpStatus.partialContent,
          headers: {
            HttpHeaders.contentTypeHeader: ['audio/mp4'],
          },
          body: 'x',
        ),
      );

      final source = await repo.resolveAudio('m1');

      expect(
        source,
        MeetingAudioSource.direct(Uri.parse('$_base/api/v1/meetings/m1/audio'), {
          AuthHeader.name: AuthHeader.bearer(_token),
        }),
      );
    });

    test('404 → no audio', () async {
      final (repo, _) = _repo(
        _Adapter(
          HttpStatus.notFound,
          headers: {
            HttpHeaders.contentTypeHeader: [Headers.jsonContentType],
          },
          body: jsonEncode({'detail': '没有音频'}),
        ),
      );
      expect(await repo.resolveAudio('m1'), const MeetingAudioSource.none());
    });

    test('other errors are ApiExceptions', () async {
      final (repo, _) = _repo(
        _Adapter(
          HttpStatus.serviceUnavailable,
          headers: {
            HttpHeaders.contentTypeHeader: [Headers.jsonContentType],
          },
          body: jsonEncode({'detail': 'OSS 未配置'}),
        ),
      );
      await expectLater(
        repo.resolveAudio('m1'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.kind, 'kind', ApiErrorKind.unavailable)
              .having((e) => e.message, 'message', 'OSS 未配置'),
        ),
      );
    });
  });

  test('getTranscripts sends limit/offset and parses the page', () async {
    final adapter = _Adapter(
      HttpStatus.ok,
      headers: {
        HttpHeaders.contentTypeHeader: [Headers.jsonContentType],
      },
      body: jsonEncode({
        'transcripts': [
          {'id': 't1', 'text': '你好', 'timestamp': '2026-10-07T03:59:35Z', 'audio_start_time': 1.5},
        ],
        'total_count': 1,
        'has_more': false,
      }),
    );
    final (repo, _) = _repo(adapter);
    final page = await repo.getTranscripts('m1', limit: 100, offset: 200);
    expect(page.transcripts.single.audioStartTime, 1.5);
    expect(adapter.requests.single.queryParameters, {'limit': 100, 'offset': 200});
  });
}
