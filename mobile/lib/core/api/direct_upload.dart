import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:crypto/crypto.dart' as crypto;
import 'package:dio/dio.dart';

import '../config/app_config.dart';
import 'api_client.dart';
import 'api_exception.dart';

class _DigestSink implements Sink<crypto.Digest> {
  crypto.Digest? digest;
  @override
  void add(crypto.Digest value) => digest = value;
  @override
  void close() {}
}

/// Returns null only for explicit local storage or a server predating direct uploads.
/// Storage transfers use a separate Dio without auth/session interceptors.
Future<Map<String, dynamic>?> directFileUpload(
  Dio api,
  NetworkConfig network,
  String path,
  File file, {
  required String fileName,
  Map<String, Object?> extra = const {},
  ProgressCallback? onProgress,
  CancelToken? cancelToken,
  Dio? storageClient,
}) async {
  final shaResult = _DigestSink(), md5Result = _DigestSink();
  final sha = crypto.sha256.startChunkedConversion(shaResult);
  final md5 = crypto.md5.startChunkedConversion(md5Result);
  var size = 0;
  await for (final bytes in file.openRead()) {
    if (cancelToken?.isCancelled ?? false) throw cancelToken!.cancelError!;
    sha.add(bytes);
    md5.add(bytes);
    size += bytes.length;
  }
  sha.close();
  md5.close();
  Map<String, dynamic> offer;
  try {
    final response = await api.post<Map<String, dynamic>>(
      '$path/uploads',
      data: {
        'file_name': fileName,
        'size': size,
        'sha256': shaResult.digest!.toString(),
        'md5': base64Encode(md5Result.digest!.bytes),
        ...extra,
      },
      cancelToken: cancelToken,
    );
    offer = response.data!;
  } on DioException catch (error) {
    if ([404, 405].contains(error.response?.statusCode)) return null;
    rethrow;
  }
  if (offer['mode'] == 'proxy') return null;
  final url = Uri.tryParse(offer['url'] as String? ?? '');
  if (offer['mode'] != 'direct' ||
      url == null ||
      !['http', 'https'].contains(url.scheme) ||
      url.host.isEmpty ||
      url.userInfo.isNotEmpty ||
      url.hasFragment ||
      offer['ticket'] is! String) {
    throw const FormatException('服务器返回的上传授权无效');
  }
  final headers = Map<String, dynamic>.from(offer['headers'] as Map);
  if (headers.keys.any(
    (key) =>
        ['cookie', 'host'].contains(key.toLowerCase()) ||
        (key.toLowerCase() == 'authorization' &&
            !(headers[key] as String).startsWith('AWS4-HMAC-SHA256 ')),
  )) {
    throw const FormatException('服务器返回的上传请求头无效');
  }
  final storage = storageClient ?? Dio(BaseOptions(connectTimeout: network.connectTimeout));
  try {
    try {
      await storage.put<String>(
        url.toString(),
        data: file.openRead(),
        options: transferOptions(
          network,
          contentType: headers['Content-Type'] as String?,
          headers: {...headers, Headers.contentLengthHeader: size},
        ).copyWith(responseType: ResponseType.plain, followRedirects: false),
        cancelToken: cancelToken,
        onSendProgress: (sent, total) =>
            onProgress?.call(math.min(sent, (total * 0.95).floor()), total),
      );
    } on DioException catch (error) {
      final mapped = ApiException.fromDio(error);
      throw ApiException(
        kind: [ApiErrorKind.unauthorized, ApiErrorKind.forbidden].contains(mapped.kind)
            ? ApiErrorKind.badRequest
            : mapped.kind,
        statusCode: error.response?.statusCode,
        message: '对象存储上传失败，请检查网络后重试',
      );
    }
    if (cancelToken?.isCancelled ?? false) throw cancelToken!.cancelError!;
    final response = await api.post<Map<String, dynamic>>(
      '$path/uploads/complete',
      data: {'ticket': offer['ticket']},
      cancelToken: cancelToken,
    );
    onProgress?.call(size, size);
    return response.data!;
  } finally {
    storage.close(force: true);
  }
}
