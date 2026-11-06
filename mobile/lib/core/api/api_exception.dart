import 'dart:io';

import 'package:dio/dio.dart';

/// Coarse error category, independent of transport details.
enum ApiErrorKind {
  /// No connection / DNS / refused / TLS.
  network,

  /// Connect/send/receive timeout or HTTP 408.
  timeout,

  /// 400 — e.g. wrong/expired SMS code (detail explains).
  badRequest,

  /// 401 — session missing/invalid/expired/revoked.
  unauthorized,

  /// 403 — disabled user, registration closed.
  forbidden,

  /// 404 — not found / not owned / phone not registered.
  notFound,

  /// 409 — e.g. phone already registered.
  conflict,

  /// 413 — payload too large (segment > 120 s).
  payloadTooLarge,

  /// 422 — request validation failed.
  validation,

  /// 429 — rate limited.
  rateLimited,

  /// 503 — STT/LLM/SMS/OSS not ready.
  unavailable,

  /// Other 5xx.
  server,

  /// Request cancelled by the client (CancelToken).
  cancelled,

  /// No server URL configured.
  notConfigured,

  /// Anything else (unexpected status, bad response body, programming error).
  unknown,
}

/// The only error type repositories throw (DEVELOPMENT.md §4).
///
/// [message] is the server's `detail` string when it sent one (already Chinese, shown
/// as-is). It is `null` when there is no usable detail (e.g. a 422 list detail or a network
/// error) — use `describe(context.l10n)` (`api_exception_l10n.dart`) for a localized text.
class ApiException implements Exception {
  const ApiException({required this.kind, this.statusCode, this.message, this.cause});

  final ApiErrorKind kind;
  final int? statusCode;
  final String? message;
  final Object? cause;

  /// Worth retrying: network error, timeout/408, 429, 5xx (incl. 503).
  bool get isRetryable => switch (kind) {
    ApiErrorKind.network ||
    ApiErrorKind.timeout ||
    ApiErrorKind.rateLimited ||
    ApiErrorKind.unavailable ||
    ApiErrorKind.server => true,
    _ => false,
  };

  /// True when the device could not reach the server at all (never logs the user out).
  bool get isConnectivity => kind == ApiErrorKind.network || kind == ApiErrorKind.timeout;

  /// Maps an HTTP status + response body to an [ApiException].
  factory ApiException.fromResponse(int statusCode, Object? body, {Object? cause}) {
    return ApiException(
      kind: kindForStatus(statusCode),
      statusCode: statusCode,
      message: detailFromBody(body),
      cause: cause,
    );
  }

  /// Converts any error into an [ApiException] (idempotent).
  factory ApiException.from(Object error) {
    if (error is ApiException) return error;
    if (error is DioException) return ApiException.fromDio(error);
    if (error is SocketException || error is HttpException) {
      return ApiException(kind: ApiErrorKind.network, cause: error);
    }
    return ApiException(kind: ApiErrorKind.unknown, cause: error);
  }

  factory ApiException.fromDio(DioException e) {
    final inner = e.error;
    if (inner is ApiException) return inner;
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return ApiException(kind: ApiErrorKind.timeout, cause: e);
      case DioExceptionType.connectionError:
        return ApiException(kind: ApiErrorKind.network, cause: e);
      case DioExceptionType.cancel:
        return ApiException(kind: ApiErrorKind.cancelled, cause: e);
      case DioExceptionType.badCertificate:
        return ApiException(kind: ApiErrorKind.network, cause: e);
      case DioExceptionType.badResponse:
        final response = e.response;
        if (response?.statusCode case final int status) {
          return ApiException.fromResponse(status, response?.data, cause: e);
        }
        return ApiException(kind: ApiErrorKind.unknown, cause: e);
      case DioExceptionType.unknown:
        if (inner is SocketException || inner is HttpException) {
          return ApiException(kind: ApiErrorKind.network, cause: e);
        }
        return ApiException(kind: ApiErrorKind.unknown, cause: e);
    }
  }

  static ApiErrorKind kindForStatus(int status) => switch (status) {
    400 => ApiErrorKind.badRequest,
    401 => ApiErrorKind.unauthorized,
    403 => ApiErrorKind.forbidden,
    404 => ApiErrorKind.notFound,
    408 => ApiErrorKind.timeout,
    409 => ApiErrorKind.conflict,
    413 => ApiErrorKind.payloadTooLarge,
    422 => ApiErrorKind.validation,
    429 => ApiErrorKind.rateLimited,
    503 => ApiErrorKind.unavailable,
    >= 500 && < 600 => ApiErrorKind.server,
    _ => ApiErrorKind.unknown,
  };

  /// Extracts a human-readable `detail` string. FastAPI 422 bodies carry a list of
  /// validation errors instead — those yield `null` (UI shows a localized "invalid input").
  static String? detailFromBody(Object? body) {
    if (body is Map) {
      final detail = body['detail'];
      if (detail is String && detail.trim().isNotEmpty) return detail;
    } else if (body is String && body.trim().isNotEmpty && !body.trimLeft().startsWith('<')) {
      // Plain-text error bodies (e.g. a proxy) — ignore HTML pages.
      return body.trim();
    }
    return null;
  }

  @override
  String toString() =>
      'ApiException(kind: ${kind.name}, status: $statusCode, message: $message, cause: $cause)';
}

/// Runs [body] and converts any thrown error into an [ApiException].
/// Repositories wrap every Dio call with it.
Future<T> apiCall<T>(Future<T> Function() body) async {
  try {
    return await body();
  } catch (e, st) {
    Error.throwWithStackTrace(ApiException.from(e), st);
  }
}
