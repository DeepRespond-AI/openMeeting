import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../api/api_client.dart';
import '../../api/api_exception.dart';
import '../../api/endpoints.dart';
import '../../config/app_config.dart';
import '../../config/app_config_provider.dart';
import '../update_models.dart';

part 'update_repository.g.dart';

/// Reports download progress: [received] of [total] bytes ([total] ≤ 0 when unknown).
typedef DownloadProgress = void Function(int received, int total);

/// Update check and package download (server/API.md §1.8). Throws [ApiException].
abstract interface class UpdateRepository {
  Future<UpdateCheckResult> check({
    required String platform,
    required String version,
    required String channel,
    required String clientId,
  });

  /// Downloads the package at [url] (absolute, public) to [path].
  Future<void> download(String url, String path, {DownloadProgress? onProgress});
}

/// Query parameter names of `GET /updates/check`.
abstract final class _UpdateParams {
  static const String platform = 'platform';
  static const String version = 'version';
  static const String channel = 'channel';
  static const String clientId = 'client_id';
}

class DioUpdateRepository implements UpdateRepository {
  DioUpdateRepository(this._dio, this._network);

  final Dio _dio;
  final NetworkConfig _network;

  @override
  Future<UpdateCheckResult> check({
    required String platform,
    required String version,
    required String channel,
    required String clientId,
  }) => apiCall(() async {
    final res = await _dio.get<Map<String, dynamic>>(
      Endpoints.updatesCheck,
      queryParameters: {
        _UpdateParams.platform: platform,
        _UpdateParams.version: version,
        _UpdateParams.channel: channel,
        _UpdateParams.clientId: clientId,
      },
    );
    return UpdateCheckResult.fromJson(res.data ?? const {});
  });

  @override
  Future<void> download(String url, String path, {DownloadProgress? onProgress}) => apiCall(
    () =>
        _dio.download(url, path, onReceiveProgress: onProgress, options: transferOptions(_network)),
  );
}

@Riverpod(keepAlive: true)
UpdateRepository updateRepository(Ref ref) => DioUpdateRepository(
  ref.watch(apiClientProvider),
  ref.watch(appConfigProvider.select((c) => c.network)),
);
