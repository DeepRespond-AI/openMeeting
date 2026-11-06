import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/endpoints.dart';
import '../../../core/auth/data/session_store.dart';
import '../../../core/config/app_config.dart';
import '../../../core/config/app_config_provider.dart';
import '../domain/live_models.dart';
import '../domain/live_repository.dart';
part 'live_repository_impl.g.dart';

@Riverpod(keepAlive: true)
LiveRepository liveRepository(Ref ref) => DioLiveRepository(
  ref.watch(apiClientProvider),
  ref.watch(sessionStoreProvider),
  ref.watch(appConfigProvider),
);

class DioLiveRepository implements LiveRepository {
  DioLiveRepository(this.dio, this.store, this.config);
  final Dio dio;
  final SessionStore store;
  final AppConfig config;
  @override
  Future<String> startScreenShare(String id) async =>
      (await request('POST', Endpoints.roomScreenStart(id)))['sessionId'] as String;
  @override
  Future<void> stopScreenShare(String id, String sessionId) =>
      write('POST', Endpoints.roomScreenStop(id), data: {'sessionId': sessionId});
  Map<String, dynamic> object(dynamic data) => Map<String, dynamic>.from(data as Map);
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, Object?>? data,
    Map<String, Object?>? query,
  }) => apiCall(
    () async => object(
      (await dio.request<dynamic>(
        path,
        data: data,
        queryParameters: query,
        options: Options(method: method),
      )).data,
    ),
  );
  Future<void> write(String method, String path, {Map<String, Object?>? data}) => apiCall(() async {
    await dio.request<dynamic>(
      path,
      data: data,
      options: Options(method: method),
    );
  });
  @override
  Future<List<LiveSchedule>> schedules(DateTime? from, DateTime? to) => apiCall(() async {
    final response = await dio.get<List<dynamic>>(
      Endpoints.schedules,
      queryParameters: {
        'from': ?from?.toUtc().toIso8601String(),
        'to': ?to?.toUtc().toIso8601String(),
      },
    );
    return response.data!.map((json) => LiveSchedule.fromJson(object(json))).toList();
  });
  @override
  Future<Map<String, dynamic>> chatSession(String id) =>
      request('POST', Endpoints.roomChatSession(id));
  @override
  Future<LiveRoom> controlRecording(String id, Map<String, Object?> values) async =>
      LiveRoom.fromJson(await request('POST', Endpoints.roomRecordingControl(id), data: values));
  @override
  Future<void> recordingChunk(String id, Map<String, Object?> chunk) =>
      write('POST', Endpoints.roomRecordingChunks(id), data: chunk);
  @override
  Future<LiveSchedule> saveSchedule(Map<String, Object?> values, {String? id}) async =>
      LiveSchedule.fromJson(
        await request(
          id == null ? 'POST' : 'PATCH',
          id == null ? Endpoints.schedules : Endpoints.schedule(id),
          data: values,
        ),
      );
  @override
  Future<void> cancelSchedule(String id) => write('DELETE', Endpoints.schedule(id));
  @override
  Future<LiveRoom> create({String? title, String? scheduledId}) async => LiveRoom.fromJson(
    await request(
      'POST',
      Endpoints.rooms,
      data: {'title': ?title, 'scheduledMeetingId': ?scheduledId},
    ),
  );
  @override
  Future<Map<String, dynamic>> join(Map<String, Object?> values) =>
      request('POST', Endpoints.roomJoin, data: values);
  @override
  Future<LiveRoom> room(String id) async =>
      LiveRoom.fromJson(await request('GET', Endpoints.room(id)));
  @override
  Future<LiveRoom> peek(String code) async =>
      LiveRoom.fromJson(await request('GET', Endpoints.rooms, query: {'code': code}));
  @override
  Future<LiveRoom> settings(String id, Map<String, Object?> values) async =>
      LiveRoom.fromJson(await request('PATCH', Endpoints.room(id), data: values));
  @override
  Future<void> self(String id, Map<String, Object?> values) =>
      write('POST', Endpoints.roomAction(id, 'participants/me'), data: values);
  @override
  Future<void> action(String id, String action, {Map<String, Object?>? values}) =>
      write('POST', Endpoints.roomAction(id, action), data: values);
  @override
  Future<void> participant(
    String id,
    String participant,
    String action, {
    Map<String, Object?>? values,
  }) => write('POST', Endpoints.roomParticipant(id, participant, action), data: values);
  @override
  Future<String?> end(String id) async =>
      (await request('POST', Endpoints.roomAction(id, 'end')))['meetingId'] as String?;
  @override
  Future<Map<String, dynamic>> media(String id) =>
      request('POST', Endpoints.roomAction(id, 'media'));
  @override
  Future<Map<String, dynamic>> imTicket() => request('POST', Endpoints.imTicket);
  @override
  Future<List<LiveChat>> chats(String id, {String? after}) async {
    final rows = <LiveChat>[];
    var cursor = after;
    for (var page = 0; page < config.live.imPageSize; page++) {
      final data = await request('GET', Endpoints.roomChat(id), query: {'after': ?cursor});
      final messages = (data['messages'] as List).map((v) => LiveChat.fromJson(object(v))).toList();
      rows.addAll(messages);
      if (cursor == null || data['hasMore'] != true || messages.isEmpty) break;
      cursor = messages.last.id;
    }
    return rows;
  }

  @override
  Future<void> send(String id, String text) =>
      write('POST', Endpoints.roomChat(id), data: {'text': text});
  @override
  Future<void> sendFile(String id, String name, Uint8List bytes) => apiCall(() async {
    if (bytes.isEmpty || bytes.length > config.live.attachmentMaxBytes) {
      throw const ApiException(kind: ApiErrorKind.payloadTooLarge);
    }
    final data = await dio.post<Map<String, dynamic>>(
      Endpoints.roomAction(id, 'chat/attachments'),
      data: FormData.fromMap({'file': MultipartFile.fromBytes(bytes, filename: name)}),
      options: transferOptions(config.network),
    );
    await sendAttachment(id, data.data!['attachmentId'] as String);
  });
  Future<void> sendAttachment(String id, String attachment) =>
      write('POST', Endpoints.roomChat(id), data: {'text': '', 'attachmentId': attachment});
  @override
  Future<String?> pickAndSendFile(String id) async {
    final picked = await FilePicker.pickFiles();
    if (picked.isEmpty) return null;
    final file = picked.single;
    if ((await file.length() ?? 0) > config.live.attachmentMaxBytes) {
      throw const ApiException(kind: ApiErrorKind.payloadTooLarge);
    }
    final bytes = await file.readAsBytes();
    await sendFile(id, file.name, bytes);
    return file.name;
  }

  @override
  Future<void> download(String id, LiveAttachment file) => apiCall(() async {
    final data = await dio.get<List<int>>(
      Endpoints.roomAttachment(id, file.id),
      options: Options(
        responseType: ResponseType.bytes,
        receiveTimeout: config.network.transferTimeout,
      ),
    );
    await FilePicker.saveFile(fileName: file.name, bytes: Uint8List.fromList(data.data!));
  });
  @override
  Stream<Map<String, dynamic>> events(String id) async* {
    for (var attempt = 0; attempt <= config.live.maxReconnects; attempt++) {
      WebSocket? socket;
      Timer? heartbeat;
      try {
        final base = Uri.parse(dio.options.baseUrl);
        final uri = base.replace(
          scheme: base.scheme == 'https' ? 'wss' : 'ws',
          path: Endpoints.roomWs(id),
          query: null,
        );
        final token = await store.currentToken();
        if (token == null) {
          yield {
            'type': 'connection_state',
            'data': {'state': 'unauthorized'},
          };
          return;
        }
        socket = await WebSocket.connect(
          uri.toString(),
          headers: {AuthHeader.name: AuthHeader.bearer(token)},
        ).timeout(config.network.connectTimeout);
        final current = socket;
        heartbeat = Timer.periodic(Duration(milliseconds: config.live.wsPingMs), (_) {
          if (current.readyState == WebSocket.open) current.add(jsonEncode({'type': 'ping'}));
        });
        yield {
          'type': 'connection_state',
          'data': {'state': 'connected'},
        };
        await for (final raw in socket) {
          final event = object(jsonDecode(raw as String));
          yield event;
          if (event['type'] == 'room_ended') return;
        }
        if (socket.closeCode == 4401 || socket.closeCode == 4403) {
          yield {
            'type': 'connection_state',
            'data': {'state': 'removed'},
          };
          return;
        }
      } on Object {
        if (attempt == config.live.maxReconnects) {
          yield {
            'type': 'connection_state',
            'data': {'state': 'failed'},
          };
          return;
        }
      } finally {
        heartbeat?.cancel();
        await socket?.close();
      }
      if (attempt == config.live.maxReconnects) {
        yield {
          'type': 'connection_state',
          'data': {'state': 'failed'},
        };
        return;
      }
      yield {
        'type': 'connection_state',
        'data': {'state': 'reconnecting'},
      };
      await Future<void>.delayed(Duration(milliseconds: config.live.reconnectMs));
    }
  }
}
