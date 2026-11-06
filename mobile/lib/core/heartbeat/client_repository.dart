import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../api/endpoints.dart';
import '../api/models/auth_models.dart';
import '../api/models/client_models.dart';
import '../auth/data/client_info_source.dart';

part 'client_repository.g.dart';

/// Connection endpoints (server/API.md §1.1). Throws [ApiException].
abstract interface class ClientRepository {
  Future<HeartbeatResult> heartbeat({required bool recording, String? meetingId});

  Future<Capabilities> capabilities();
}

class DioClientRepository implements ClientRepository {
  DioClientRepository(this._dio, this._clientInfo);

  final Dio _dio;
  final Future<ClientInfo> Function() _clientInfo;

  @override
  Future<HeartbeatResult> heartbeat({required bool recording, String? meetingId}) =>
      apiCall(() async {
        final client = await _clientInfo();
        final res = await _dio.post<Map<String, dynamic>>(
          Endpoints.heartbeat,
          data: {...client.toJson(), 'recording': recording, 'meeting_id': meetingId},
        );
        return HeartbeatResult.fromJson(res.data ?? const {});
      });

  @override
  Future<Capabilities> capabilities() => apiCall(() async {
    final res = await _dio.get<Map<String, dynamic>>(Endpoints.capabilities);
    return Capabilities.fromJson(res.data!);
  });
}

@Riverpod(keepAlive: true)
ClientRepository clientRepository(Ref ref) =>
    DioClientRepository(ref.watch(apiClientProvider), () => ref.read(clientInfoProvider.future));
