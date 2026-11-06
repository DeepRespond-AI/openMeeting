import 'dart:io';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meeting/core/api/api_client.dart';
import 'package:meeting/core/api/api_exception.dart';
import 'package:meeting/core/api/api_exception_l10n.dart';
import 'package:meeting/core/api/endpoints.dart';
import 'package:meeting/core/api/retry.dart';
import 'package:meeting/core/config/app_config.dart';
import 'package:meeting/core/l10n/l10n.dart';

import '../../helpers/test_config.dart';

DioException _badResponse(int status, Object? body) {
  final options = RequestOptions(path: '/x');
  return DioException.badResponse(
    statusCode: status,
    requestOptions: options,
    response: Response<Object?>(requestOptions: options, statusCode: status, data: body),
  );
}

void main() {
  final zh = lookupAppLocalizations(const Locale('zh'));
  final en = lookupAppLocalizations(const Locale('en'));

  group('ApiException mapping', () {
    test('uses the server detail string', () {
      final e = ApiException.fromDio(_badResponse(409, {'detail': '该手机号已注册，请直接登录'}));
      expect(e.kind, ApiErrorKind.conflict);
      expect(e.statusCode, 409);
      expect(e.message, '该手机号已注册，请直接登录');
      expect(e.describe(en), '该手机号已注册，请直接登录'); // server text is never translated
      expect(e.isRetryable, isFalse);
    });

    test('422 with a validation list falls back to localized invalid input', () {
      final e = ApiException.fromDio(
        _badResponse(422, {
          'detail': [
            {
              'loc': ['body', 'phone'],
              'msg': 'field required',
              'type': 'missing',
            },
          ],
        }),
      );
      expect(e.kind, ApiErrorKind.validation);
      expect(e.message, isNull);
      expect(e.describe(zh), zh.errorInvalidInput);
      expect(e.describe(en), en.errorInvalidInput);
    });

    test('network errors', () {
      final e = ApiException.fromDio(
        DioException.connectionError(
          requestOptions: RequestOptions(path: '/x'),
          reason: 'refused',
          error: const SocketException('refused'),
        ),
      );
      expect(e.kind, ApiErrorKind.network);
      expect(e.isRetryable, isTrue);
      expect(e.isConnectivity, isTrue);
      expect(e.describe(zh), zh.errorNetwork);
      expect(ApiException.from(const SocketException('x')).kind, ApiErrorKind.network);
    });

    test('timeouts and 408', () {
      final timeout = ApiException.fromDio(
        DioException.receiveTimeout(
          timeout: const Duration(seconds: 1),
          requestOptions: RequestOptions(path: '/x'),
        ),
      );
      expect(timeout.kind, ApiErrorKind.timeout);
      expect(ApiException.fromDio(_badResponse(408, null)).kind, ApiErrorKind.timeout);
    });

    test('status codes map to kinds and retryability', () {
      expect(ApiException.kindForStatus(400), ApiErrorKind.badRequest);
      expect(ApiException.kindForStatus(401), ApiErrorKind.unauthorized);
      expect(ApiException.kindForStatus(403), ApiErrorKind.forbidden);
      expect(ApiException.kindForStatus(404), ApiErrorKind.notFound);
      expect(ApiException.kindForStatus(413), ApiErrorKind.payloadTooLarge);
      expect(ApiException.kindForStatus(429), ApiErrorKind.rateLimited);
      expect(ApiException.kindForStatus(502), ApiErrorKind.server);
      expect(ApiException.kindForStatus(503), ApiErrorKind.unavailable);
      for (final s in [408, 429, 500, 502, 503]) {
        expect(ApiException.fromResponse(s, null).isRetryable, isTrue, reason: '$s');
      }
      for (final s in [400, 401, 403, 404, 409, 422]) {
        expect(ApiException.fromResponse(s, null).isRetryable, isFalse, reason: '$s');
      }
    });

    test('HTML error pages are not used as a message', () {
      expect(ApiException.fromResponse(502, '<html>Bad gateway</html>').message, isNull);
      expect(ApiException.fromResponse(502, null).describe(en), en.errorServer);
    });

    test('apiCall converts DioException into ApiException', () async {
      await expectLater(
        apiCall<void>(() async => throw _badResponse(404, {'detail': '会议不存在'})),
        throwsA(
          isA<ApiException>()
              .having((e) => e.kind, 'kind', ApiErrorKind.notFound)
              .having((e) => e.message, 'message', '会议不存在'),
        ),
      );
    });
  });

  group('interceptors', () {
    Dio buildDio(StubAdapter adapter, {String? token, required void Function() onRejected}) {
      return Dio(BaseOptions(baseUrl: 'http://server'))
        ..httpClientAdapter = adapter
        ..interceptors.addAll([
          AuthInterceptor(tokenReader: () async => token),
          ErrorMappingInterceptor(onSessionRejected: onRejected),
        ]);
    }

    test('attaches bearer token and reports 401 on authenticated requests', () async {
      var rejected = 0;
      final adapter = StubAdapter(401, {'detail': '登录凭证无效，请重新登录'});
      final dio = buildDio(adapter, token: 'ms_token', onRejected: () => rejected++);
      await expectLater(
        apiCall(() => dio.get<Object?>(Endpoints.meetings)),
        throwsA(isA<ApiException>().having((e) => e.kind, 'kind', ApiErrorKind.unauthorized)),
      );
      expect(adapter.requests.single.headers[AuthHeader.name], 'Bearer ms_token');
      expect(rejected, 1);
    });

    test('public endpoints get no token and their 401 never expires the session', () async {
      var rejected = 0;
      final adapter = StubAdapter(401);
      final dio = buildDio(adapter, token: 'ms_token', onRejected: () => rejected++);
      await expectLater(
        apiCall(() => dio.post<Object?>(Endpoints.authLogin)),
        throwsA(isA<ApiException>()),
      );
      expect(adapter.requests.single.headers.containsKey(AuthHeader.name), isFalse);
      expect(rejected, 0);
    });

    test('rejects relative requests when no server is configured', () async {
      final dio = Dio()
        ..httpClientAdapter = StubAdapter(200)
        ..interceptors.add(AuthInterceptor(tokenReader: () async => null));
      await expectLater(
        apiCall(() => dio.get<Object?>(Endpoints.meetings)),
        throwsA(isA<ApiException>().having((e) => e.kind, 'kind', ApiErrorKind.notConfigured)),
      );
    });
  });

  group('retry', () {
    const policy = RetryConfig(maxRetries: 3, backoffMs: [500, 1000, 2000]);

    test('retries retryable errors with the configured backoff, then succeeds', () async {
      final delays = <Duration>[];
      var calls = 0;
      final result = await retry(
        () async {
          calls++;
          if (calls < 3) throw const ApiException(kind: ApiErrorKind.network);
          return 'ok';
        },
        policy: policy,
        sleep: (d) async => delays.add(d),
      );
      expect(result, 'ok');
      expect(calls, 3);
      expect(delays, [const Duration(milliseconds: 500), const Duration(milliseconds: 1000)]);
    });

    test('gives up after 1 + maxRetries attempts', () async {
      var calls = 0;
      await expectLater(
        retry<void>(
          () async {
            calls++;
            throw const ApiException(kind: ApiErrorKind.server, statusCode: 500);
          },
          policy: policy,
          sleep: (_) async {},
        ),
        throwsA(isA<ApiException>()),
      );
      expect(calls, 4);
    });

    test('does not retry non-retryable errors', () async {
      var calls = 0;
      await expectLater(
        retry<void>(
          () async {
            calls++;
            throw const ApiException(kind: ApiErrorKind.badRequest, statusCode: 400);
          },
          policy: policy,
          sleep: (_) async {},
        ),
        throwsA(isA<ApiException>()),
      );
      expect(calls, 1);
    });

    test('uses AppConfig values', () {
      final config = loadConfigFile('prod');
      expect(config.network.audioUploadRetry.delayFor(0), const Duration(seconds: 4));
    });
  });
}
