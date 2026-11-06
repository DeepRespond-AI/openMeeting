// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'segment_upload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SegmentUpload _$SegmentUploadFromJson(Map<String, dynamic> json) =>
    _SegmentUpload(
      meetingId: json['meetingId'] as String,
      seq: (json['seq'] as num).toInt(),
      startSec: (json['startSec'] as num).toDouble(),
      endSec: (json['endSec'] as num).toDouble(),
      language: json['language'] as String?,
    );

Map<String, dynamic> _$SegmentUploadToJson(_SegmentUpload instance) =>
    <String, dynamic>{
      'meetingId': instance.meetingId,
      'seq': instance.seq,
      'startSec': instance.startSec,
      'endSec': instance.endSec,
      'language': instance.language,
    };
