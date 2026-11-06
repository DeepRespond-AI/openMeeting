// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'summary_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SummaryResponse _$SummaryResponseFromJson(Map<String, dynamic> json) =>
    _SummaryResponse(
      status: $enumDecode(
        _$SummaryStatusEnumMap,
        json['status'],
        unknownValue: SummaryStatus.unknown,
      ),
      meetingName: json['meetingName'] as String?,
      meetingId: json['meeting_id'] as String?,
      start: json['start'] as String?,
      end: json['end'] as String?,
      data: json['data'],
      error: json['error'] as String?,
    );

Map<String, dynamic> _$SummaryResponseToJson(_SummaryResponse instance) =>
    <String, dynamic>{
      'status': _$SummaryStatusEnumMap[instance.status]!,
      'meetingName': instance.meetingName,
      'meeting_id': instance.meetingId,
      'start': instance.start,
      'end': instance.end,
      'data': instance.data,
      'error': instance.error,
    };

const _$SummaryStatusEnumMap = {
  SummaryStatus.idle: 'idle',
  SummaryStatus.pending: 'pending',
  SummaryStatus.processing: 'processing',
  SummaryStatus.completed: 'completed',
  SummaryStatus.failed: 'failed',
  SummaryStatus.cancelled: 'cancelled',
  SummaryStatus.error: 'error',
  SummaryStatus.unknown: 'unknown',
};

_ProcessStarted _$ProcessStartedFromJson(Map<String, dynamic> json) =>
    _ProcessStarted(
      message: json['message'] as String,
      processId: json['process_id'] as String,
    );

Map<String, dynamic> _$ProcessStartedToJson(_ProcessStarted instance) =>
    <String, dynamic>{
      'message': instance.message,
      'process_id': instance.processId,
    };

_SummaryLanguage _$SummaryLanguageFromJson(Map<String, dynamic> json) =>
    _SummaryLanguage(
      language: json['language'] as String?,
      detectedLanguage: json['detected_language'] as String?,
    );

Map<String, dynamic> _$SummaryLanguageToJson(_SummaryLanguage instance) =>
    <String, dynamic>{
      'language': instance.language,
      'detected_language': instance.detectedLanguage,
    };
