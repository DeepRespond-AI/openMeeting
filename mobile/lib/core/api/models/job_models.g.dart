// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Job _$JobFromJson(Map<String, dynamic> json) => _Job(
  id: json['id'] as String,
  kind: $enumDecode(
    _$JobKindEnumMap,
    json['kind'],
    unknownValue: JobKind.unknown,
  ),
  status: $enumDecode(
    _$JobStatusEnumMap,
    json['status'],
    unknownValue: JobStatus.unknown,
  ),
  progress: (json['progress'] as num?)?.toInt() ?? 0,
  message: json['message'] as String?,
  meetingId: json['meeting_id'] as String?,
  error: json['error'] as String?,
  segments: (json['segments'] as num?)?.toInt(),
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$JobToJson(_Job instance) => <String, dynamic>{
  'id': instance.id,
  'kind': _$JobKindEnumMap[instance.kind]!,
  'status': _$JobStatusEnumMap[instance.status]!,
  'progress': instance.progress,
  'message': instance.message,
  'meeting_id': instance.meetingId,
  'error': instance.error,
  'segments': instance.segments,
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
};

const _$JobKindEnumMap = {
  JobKind.import: 'import',
  JobKind.retranscribe: 'retranscribe',
  JobKind.summary: 'summary',
  JobKind.unknown: 'unknown',
};

const _$JobStatusEnumMap = {
  JobStatus.queued: 'queued',
  JobStatus.running: 'running',
  JobStatus.completed: 'completed',
  JobStatus.failed: 'failed',
  JobStatus.cancelled: 'cancelled',
  JobStatus.unknown: 'unknown',
};
