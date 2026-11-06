// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Capabilities _$CapabilitiesFromJson(Map<String, dynamic> json) =>
    _Capabilities(
      serverVersion: json['server_version'] as String,
      user: json['user'] == null
          ? null
          : CapabilityUser.fromJson(json['user'] as Map<String, dynamic>),
      stt: SttStatus.fromJson(json['stt'] as Map<String, dynamic>),
      llm: LlmStatus.fromJson(json['llm'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CapabilitiesToJson(_Capabilities instance) =>
    <String, dynamic>{
      'server_version': instance.serverVersion,
      'user': instance.user?.toJson(),
      'stt': instance.stt.toJson(),
      'llm': instance.llm.toJson(),
    };

_CapabilityUser _$CapabilityUserFromJson(Map<String, dynamic> json) =>
    _CapabilityUser(
      id: json['id'] as String,
      name: json['name'] as String?,
      phone: json['phone'] as String?,
    );

Map<String, dynamic> _$CapabilityUserToJson(_CapabilityUser instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'phone': instance.phone,
    };

_SttStatus _$SttStatusFromJson(Map<String, dynamic> json) => _SttStatus(
  engine: json['engine'] as String?,
  model: json['model'] as String?,
  ready: json['ready'] as bool,
  error: json['error'] as String?,
);

Map<String, dynamic> _$SttStatusToJson(_SttStatus instance) =>
    <String, dynamic>{
      'engine': instance.engine,
      'model': instance.model,
      'ready': instance.ready,
      'error': instance.error,
    };

_LlmStatus _$LlmStatusFromJson(Map<String, dynamic> json) => _LlmStatus(
  name: json['name'] as String?,
  model: json['model'] as String?,
  ready: json['ready'] as bool,
  error: json['error'] as String?,
);

Map<String, dynamic> _$LlmStatusToJson(_LlmStatus instance) =>
    <String, dynamic>{
      'name': instance.name,
      'model': instance.model,
      'ready': instance.ready,
      'error': instance.error,
    };

_HeartbeatResult _$HeartbeatResultFromJson(Map<String, dynamic> json) =>
    _HeartbeatResult(
      serverTime: json['server_time'] as String?,
      serverVersion: json['server_version'] as String?,
    );

Map<String, dynamic> _$HeartbeatResultToJson(_HeartbeatResult instance) =>
    <String, dynamic>{
      'server_time': instance.serverTime,
      'server_version': instance.serverVersion,
    };
