import 'package:freezed_annotation/freezed_annotation.dart';
part 'live_models.freezed.dart';
part 'live_models.g.dart';

@freezed
abstract class LiveParticipant with _$LiveParticipant {
  const factory LiveParticipant({
    required String id,
    String? userId,
    required String name,
    @Default(false) bool isHost,
    @Default(false) bool isSelf,
    @Default(false) bool micOn,
    @Default(false) bool mutedByHost,
    @Default(false) bool camOn,
    @Default(false) bool handRaised,
    @Default(false) bool screenSharing,
    String? screenShareId,
  }) = _LiveParticipant;
  factory LiveParticipant.fromJson(Map<String, dynamic> json) => _$LiveParticipantFromJson(json);
}

@freezed
abstract class LiveWaiting with _$LiveWaiting {
  const factory LiveWaiting({required String participantId, required String name}) = _LiveWaiting;
  factory LiveWaiting.fromJson(Map<String, dynamic> json) => _$LiveWaitingFromJson(json);
}

@freezed
abstract class LiveRoom with _$LiveRoom {
  const factory LiveRoom({
    required String id,
    required String code,
    required String title,
    required String hostId,
    String? hostUserId,
    @Default('active') String status,
    @Default(false) bool pwdEnabled,
    @Default(false) bool waitRoom,
    @Default([]) List<LiveParticipant> participants,
    @Default([]) List<LiveWaiting> waiting,
    DateTime? startedAt,
    String? meetingId,
    LiveRecording? recording,
  }) = _LiveRoom;
  factory LiveRoom.fromJson(Map<String, dynamic> json) => _$LiveRoomFromJson(json);
}

@freezed
abstract class LiveSender with _$LiveSender {
  const factory LiveSender({
    required String id,
    required String name,
    @Default(false) bool isSelf,
  }) = _LiveSender;
  factory LiveSender.fromJson(Map<String, dynamic> json) => _$LiveSenderFromJson(json);
}

@freezed
abstract class LiveAttachment with _$LiveAttachment {
  const factory LiveAttachment({required String id, required String name, required int size}) =
      _LiveAttachment;
  factory LiveAttachment.fromJson(Map<String, dynamic> json) => _$LiveAttachmentFromJson(json);
}

@freezed
abstract class LiveChat with _$LiveChat {
  const factory LiveChat({
    required String id,
    required LiveSender sender,
    @Default('') String text,
    LiveAttachment? attachment,
    DateTime? createdAt,
  }) = _LiveChat;
  factory LiveChat.fromJson(Map<String, dynamic> json) => _$LiveChatFromJson(json);
}

@freezed
abstract class LiveSchedule with _$LiveSchedule {
  const factory LiveSchedule({
    required String id,
    required String code,
    required String title,
    required DateTime startAt,
    required int durationMin,
    @Default(false) bool pwdEnabled,
    String? pwd,
    @Default(false) bool waitRoom,
    @Default(false) bool remind,
    @Default(false) bool cancelled,
    String? meetingId,
    String? activeRoomId,
    @Default({}) Map<String, dynamic> host,
  }) = _LiveSchedule;
  factory LiveSchedule.fromJson(Map<String, dynamic> json) => _$LiveScheduleFromJson(json);
}

@freezed
abstract class LiveRecording with _$LiveRecording {
  const factory LiveRecording({
    @Default(false) bool active,
    @Default(0) int epoch,
    DateTime? startedAt,
    @Default([]) List<LiveRecordingRequest> requests,
  }) = _LiveRecording;
  factory LiveRecording.fromJson(Map<String, dynamic> json) => _$LiveRecordingFromJson(json);
}

@freezed
abstract class LiveRecordingRequest with _$LiveRecordingRequest {
  const factory LiveRecordingRequest({
    required String participantId,
    required String requestId,
    required String name,
    required String status,
  }) = _LiveRecordingRequest;
  factory LiveRecordingRequest.fromJson(Map<String, dynamic> json) =>
      _$LiveRecordingRequestFromJson(json);
}

@freezed
sealed class LiveRoomState with _$LiveRoomState {
  const factory LiveRoomState.idle() = RoomIdle;
  const factory LiveRoomState.joining() = RoomJoining;
  const factory LiveRoomState.waiting({
    required LiveRoom room,
    required LiveParticipant self,
    String? error,
  }) = RoomWaiting;
  const factory LiveRoomState.active({
    required LiveRoom room,
    required LiveParticipant self,
    @Default([]) List<LiveChat> chats,
    @Default('connecting') String connection,
    @Default('idle') String media,
    @Default(false) bool busy,
    @Default('waiting') String capture,
    String? captureError,
    String? error,
  }) = RoomActive;
  const factory LiveRoomState.ended({String? meetingId}) = RoomEnded;
  const factory LiveRoomState.failed(String message) = RoomFailed;
}
