// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'live_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LiveParticipant _$LiveParticipantFromJson(Map<String, dynamic> json) =>
    _LiveParticipant(
      id: json['id'] as String,
      userId: json['userId'] as String?,
      name: json['name'] as String,
      isHost: json['isHost'] as bool? ?? false,
      isSelf: json['isSelf'] as bool? ?? false,
      micOn: json['micOn'] as bool? ?? false,
      mutedByHost: json['mutedByHost'] as bool? ?? false,
      camOn: json['camOn'] as bool? ?? false,
      handRaised: json['handRaised'] as bool? ?? false,
      screenSharing: json['screenSharing'] as bool? ?? false,
      screenShareId: json['screenShareId'] as String?,
    );

Map<String, dynamic> _$LiveParticipantToJson(_LiveParticipant instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'name': instance.name,
      'isHost': instance.isHost,
      'isSelf': instance.isSelf,
      'micOn': instance.micOn,
      'mutedByHost': instance.mutedByHost,
      'camOn': instance.camOn,
      'handRaised': instance.handRaised,
      'screenSharing': instance.screenSharing,
      'screenShareId': instance.screenShareId,
    };

_LiveWaiting _$LiveWaitingFromJson(Map<String, dynamic> json) => _LiveWaiting(
  participantId: json['participantId'] as String,
  name: json['name'] as String,
);

Map<String, dynamic> _$LiveWaitingToJson(_LiveWaiting instance) =>
    <String, dynamic>{
      'participantId': instance.participantId,
      'name': instance.name,
    };

_LiveRoom _$LiveRoomFromJson(Map<String, dynamic> json) => _LiveRoom(
  id: json['id'] as String,
  code: json['code'] as String,
  title: json['title'] as String,
  hostId: json['hostId'] as String,
  hostUserId: json['hostUserId'] as String?,
  status: json['status'] as String? ?? 'active',
  pwdEnabled: json['pwdEnabled'] as bool? ?? false,
  waitRoom: json['waitRoom'] as bool? ?? false,
  participants:
      (json['participants'] as List<dynamic>?)
          ?.map((e) => LiveParticipant.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  waiting:
      (json['waiting'] as List<dynamic>?)
          ?.map((e) => LiveWaiting.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  startedAt: json['startedAt'] == null
      ? null
      : DateTime.parse(json['startedAt'] as String),
  meetingId: json['meetingId'] as String?,
  recording: json['recording'] == null
      ? null
      : LiveRecording.fromJson(json['recording'] as Map<String, dynamic>),
);

Map<String, dynamic> _$LiveRoomToJson(_LiveRoom instance) => <String, dynamic>{
  'id': instance.id,
  'code': instance.code,
  'title': instance.title,
  'hostId': instance.hostId,
  'hostUserId': instance.hostUserId,
  'status': instance.status,
  'pwdEnabled': instance.pwdEnabled,
  'waitRoom': instance.waitRoom,
  'participants': instance.participants.map((e) => e.toJson()).toList(),
  'waiting': instance.waiting.map((e) => e.toJson()).toList(),
  'startedAt': instance.startedAt?.toIso8601String(),
  'meetingId': instance.meetingId,
  'recording': instance.recording?.toJson(),
};

_LiveSender _$LiveSenderFromJson(Map<String, dynamic> json) => _LiveSender(
  id: json['id'] as String,
  name: json['name'] as String,
  isSelf: json['isSelf'] as bool? ?? false,
);

Map<String, dynamic> _$LiveSenderToJson(_LiveSender instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'isSelf': instance.isSelf,
    };

_LiveAttachment _$LiveAttachmentFromJson(Map<String, dynamic> json) =>
    _LiveAttachment(
      id: json['id'] as String,
      name: json['name'] as String,
      size: (json['size'] as num).toInt(),
    );

Map<String, dynamic> _$LiveAttachmentToJson(_LiveAttachment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'size': instance.size,
    };

_LiveChat _$LiveChatFromJson(Map<String, dynamic> json) => _LiveChat(
  id: json['id'] as String,
  sender: LiveSender.fromJson(json['sender'] as Map<String, dynamic>),
  text: json['text'] as String? ?? '',
  attachment: json['attachment'] == null
      ? null
      : LiveAttachment.fromJson(json['attachment'] as Map<String, dynamic>),
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$LiveChatToJson(_LiveChat instance) => <String, dynamic>{
  'id': instance.id,
  'sender': instance.sender.toJson(),
  'text': instance.text,
  'attachment': instance.attachment?.toJson(),
  'createdAt': instance.createdAt?.toIso8601String(),
};

_LiveSchedule _$LiveScheduleFromJson(Map<String, dynamic> json) =>
    _LiveSchedule(
      id: json['id'] as String,
      code: json['code'] as String,
      title: json['title'] as String,
      startAt: DateTime.parse(json['startAt'] as String),
      durationMin: (json['durationMin'] as num).toInt(),
      pwdEnabled: json['pwdEnabled'] as bool? ?? false,
      pwd: json['pwd'] as String?,
      waitRoom: json['waitRoom'] as bool? ?? false,
      remind: json['remind'] as bool? ?? false,
      cancelled: json['cancelled'] as bool? ?? false,
      meetingId: json['meetingId'] as String?,
      activeRoomId: json['activeRoomId'] as String?,
      host: json['host'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$LiveScheduleToJson(_LiveSchedule instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'title': instance.title,
      'startAt': instance.startAt.toIso8601String(),
      'durationMin': instance.durationMin,
      'pwdEnabled': instance.pwdEnabled,
      'pwd': instance.pwd,
      'waitRoom': instance.waitRoom,
      'remind': instance.remind,
      'cancelled': instance.cancelled,
      'meetingId': instance.meetingId,
      'activeRoomId': instance.activeRoomId,
      'host': instance.host,
    };

_LiveRecording _$LiveRecordingFromJson(Map<String, dynamic> json) =>
    _LiveRecording(
      active: json['active'] as bool? ?? false,
      epoch: (json['epoch'] as num?)?.toInt() ?? 0,
      startedAt: json['startedAt'] == null
          ? null
          : DateTime.parse(json['startedAt'] as String),
      requests:
          (json['requests'] as List<dynamic>?)
              ?.map(
                (e) => LiveRecordingRequest.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    );

Map<String, dynamic> _$LiveRecordingToJson(_LiveRecording instance) =>
    <String, dynamic>{
      'active': instance.active,
      'epoch': instance.epoch,
      'startedAt': instance.startedAt?.toIso8601String(),
      'requests': instance.requests.map((e) => e.toJson()).toList(),
    };

_LiveRecordingRequest _$LiveRecordingRequestFromJson(
  Map<String, dynamic> json,
) => _LiveRecordingRequest(
  participantId: json['participantId'] as String,
  requestId: json['requestId'] as String,
  name: json['name'] as String,
  status: json['status'] as String,
);

Map<String, dynamic> _$LiveRecordingRequestToJson(
  _LiveRecordingRequest instance,
) => <String, dynamic>{
  'participantId': instance.participantId,
  'requestId': instance.requestId,
  'name': instance.name,
  'status': instance.status,
};
