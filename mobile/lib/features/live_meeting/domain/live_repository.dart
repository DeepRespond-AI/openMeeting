import 'dart:typed_data';

import 'live_models.dart';

abstract interface class LiveRepository {
  Future<String> startScreenShare(String id);
  Future<void> stopScreenShare(String id, String sessionId);
  Future<List<LiveSchedule>> schedules(DateTime? from, DateTime? to);
  Future<Map<String, dynamic>> chatSession(String id);
  Future<LiveRoom> controlRecording(String id, Map<String, Object?> values);
  Future<void> recordingChunk(String id, Map<String, Object?> chunk);
  Future<LiveSchedule> saveSchedule(Map<String, Object?> values, {String? id});
  Future<void> cancelSchedule(String id);
  Future<LiveRoom> create({String? title, String? scheduledId});
  Future<Map<String, dynamic>> join(Map<String, Object?> values);
  Future<LiveRoom> room(String id);
  Future<LiveRoom> peek(String code);
  Future<LiveRoom> settings(String id, Map<String, Object?> values);
  Future<void> self(String id, Map<String, Object?> values);
  Future<void> action(String id, String action, {Map<String, Object?>? values});
  Future<void> participant(
    String id,
    String participant,
    String action, {
    Map<String, Object?>? values,
  });
  Future<String?> end(String id);
  Future<Map<String, dynamic>> media(String id);
  Future<Map<String, dynamic>> imTicket();
  Future<List<LiveChat>> chats(String id, {String? after});
  Future<void> send(String id, String text);
  Future<void> sendFile(String id, String name, Uint8List bytes);
  Future<String?> pickAndSendFile(String id);
  Future<void> download(String id, LiveAttachment file);
  Stream<Map<String, dynamic>> events(String id);
}
