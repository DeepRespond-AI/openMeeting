import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../auth/data/session_store.dart';
import '../auth/session_controller.dart';
import '../config/app_config.dart';
import '../config/app_config_provider.dart';
import '../config/settings_controller.dart';
import 'api_exception.dart';
import 'endpoints.dart';

part 'api_client.g.dart';

/// `Authorization` header helpers.
abstract final class AuthHeader {
  static const String name = 'Authorization';
  static String bearer(String token) => 'Bearer $token';
}

/// Keys in [RequestOptions.extra].
abstract final class ApiExtra {
  /// Set by [AuthInterceptor] when it attached the session token.
  static const String authenticated = 'meeting.authenticated';
}

/// The app's single [Dio] (DEVELOPMENT.md §4).
///
/// - `baseUrl` = effective server URL (settings > config); the provider rebuilds when it changes.
/// - Default timeouts from `AppConfig.network`; for uploads/downloads pass
///   `transferOptions(config.network)`.
/// - Errors arrive as [DioException] whose `.error` is an [ApiException]; wrap calls
///   in `apiCall(() => ...)` to get the [ApiException] thrown directly.
@Riverpod(keepAlive: true)
Dio apiClient(Ref ref) {
  final network = ref.watch(appConfigProvider.select((c) => c.network));
  final baseUrl = ref.watch(effectiveServerUrlProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: network.connectTimeout,
      receiveTimeout: network.requestTimeout,
      sendTimeout: network.requestTimeout,
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    ),
  );
  dio.interceptors.addAll([
    AuthInterceptor(tokenReader: () => ref.read(sessionStoreProvider).currentToken()),
    ErrorMappingInterceptor(
      onSessionRejected: () {
        if (ref.mounted) ref.read(sessionControllerProvider.notifier).expire();
      },
    ),
  ]);
  ref.onDispose(dio.close);
  return dio;
}

/// Per-request options for large transfers (audio upload/download, import).
Options transferOptions(
  NetworkConfig network, {
  Map<String, Object?>? headers,
  String? contentType,
}) => Options(
  sendTimeout: network.transferTimeout,
  receiveTimeout: network.transferTimeout,
  headers: headers,
  contentType: contentType,
);

/// Rejects relative requests when no server is configured, and attaches the session
/// token to every non-public endpoint (unless the request already has an Authorization header).
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.tokenReader});

  final Future<String?> Function() tokenReader;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final isAbsolute = options.path.startsWith('http://') || options.path.startsWith('https://');
    if (options.baseUrl.isEmpty && !isAbsolute) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: const ApiException(kind: ApiErrorKind.notConfigured),
          type: DioExceptionType.unknown,
        ),
      );
      return;
    }
    final path = options.uri.path;
    final isPublic =
        Endpoints.publicPaths.any(path.endsWith) || Endpoints.publicPrefixes.any(path.contains);
    if (!isPublic) {
      if (options.headers.containsKey(AuthHeader.name)) {
        options.extra[ApiExtra.authenticated] = true;
      } else {
        final token = await tokenReader();
        if (token != null) {
          options.headers[AuthHeader.name] = AuthHeader.bearer(token);
          options.extra[ApiExtra.authenticated] = true;
        }
      }
    }
    handler.next(options);
  }
}

/// Converts every failure into a [DioException] carrying an [ApiException] and, for a 401
/// on an authenticated request, reports the session as rejected (→ `SessionController.expire()`).
class ErrorMappingInterceptor extends Interceptor {
  ErrorMappingInterceptor({required this.onSessionRejected});

  final void Function() onSessionRejected;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final apiError = ApiException.fromDio(err);
    if (apiError.kind == ApiErrorKind.unauthorized &&
        err.requestOptions.extra[ApiExtra.authenticated] == true) {
      onSessionRejected();
    }
    handler.next(err.copyWith(error: apiError, message: apiError.toString()));
  }
}
