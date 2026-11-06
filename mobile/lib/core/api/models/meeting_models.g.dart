// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meeting_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MeetingSummary _$MeetingSummaryFromJson(Map<String, dynamic> json) =>
    _MeetingSummary(
      id: json['id'] as String,
      title: json['title'] as String,
      canManage: json['can_manage'] as bool? ?? true,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$MeetingSummaryToJson(_MeetingSummary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'can_manage': instance.canManage,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

_MeetingMetadata _$MeetingMetadataFromJson(Map<String, dynamic> json) =>
    _MeetingMetadata(
      id: json['id'] as String,
      title: json['title'] as String,
      canManage: json['can_manage'] as bool? ?? true,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      folderPath: json['folder_path'] as String?,
      hasAudio: json['has_audio'] as bool? ?? false,
      audioDuration: (json['audio_duration'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$MeetingMetadataToJson(_MeetingMetadata instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'can_manage': instance.canManage,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'folder_path': instance.folderPath,
      'has_audio': instance.hasAudio,
      'audio_duration': instance.audioDuration,
    };

_MeetingTranscript _$MeetingTranscriptFromJson(Map<String, dynamic> json) =>
    _MeetingTranscript(
      id: json['id'] as String,
      text: json['text'] as String,
      timestamp: json['timestamp'] as String,
      audioStartTime: (json['audio_start_time'] as num?)?.toDouble(),
      audioEndTime: (json['audio_end_time'] as num?)?.toDouble(),
      duration: (json['duration'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$MeetingTranscriptToJson(_MeetingTranscript instance) =>
    <String, dynamic>{
      'id': instance.id,
      'text': instance.text,
      'timestamp': instance.timestamp,
      'audio_start_time': instance.audioStartTime,
      'audio_end_time': instance.audioEndTime,
      'duration': instance.duration,
    };

_MeetingDetails _$MeetingDetailsFromJson(Map<String, dynamic> json) =>
    _MeetingDetails(
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      transcripts:
          (json['transcripts'] as List<dynamic>?)
              ?.map(
                (e) => MeetingTranscript.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <MeetingTranscript>[],
    );

Map<String, dynamic> _$MeetingDetailsToJson(_MeetingDetails instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'transcripts': instance.transcripts.map((e) => e.toJson()).toList(),
    };

_PaginatedTranscripts _$PaginatedTranscriptsFromJson(
  Map<String, dynamic> json,
) => _PaginatedTranscripts(
  transcripts: (json['transcripts'] as List<dynamic>)
      .map((e) => MeetingTranscript.fromJson(e as Map<String, dynamic>))
      .toList(),
  totalCount: (json['total_count'] as num).toInt(),
  hasMore: json['has_more'] as bool,
);

Map<String, dynamic> _$PaginatedTranscriptsToJson(
  _PaginatedTranscripts instance,
) => <String, dynamic>{
  'transcripts': instance.transcripts.map((e) => e.toJson()).toList(),
  'total_count': instance.totalCount,
  'has_more': instance.hasMore,
};

_TranscriptSearchResult _$TranscriptSearchResultFromJson(
  Map<String, dynamic> json,
) => _TranscriptSearchResult(
  id: json['id'] as String,
  title: json['title'] as String,
  matchContext: json['matchContext'] as String,
  timestamp: json['timestamp'] as String?,
);

Map<String, dynamic> _$TranscriptSearchResultToJson(
  _TranscriptSearchResult instance,
) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'matchContext': instance.matchContext,
  'timestamp': instance.timestamp,
};

_SegmentResult _$SegmentResultFromJson(Map<String, dynamic> json) =>
    _SegmentResult(
      id: json['id'] as String?,
      text: json['text'] as String,
      confidence: (json['confidence'] as num?)?.toDouble(),
      seq: (json['seq'] as num).toInt(),
    );

Map<String, dynamic> _$SegmentResultToJson(_SegmentResult instance) =>
    <String, dynamic>{
      'id': instance.id,
      'text': instance.text,
      'confidence': instance.confidence,
      'seq': instance.seq,
    };

_AudioUploadResult _$AudioUploadResultFromJson(Map<String, dynamic> json) =>
    _AudioUploadResult(
      size: (json['size'] as num).toInt(),
      duration: (json['duration'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$AudioUploadResultToJson(_AudioUploadResult instance) =>
    <String, dynamic>{'size': instance.size, 'duration': instance.duration};

_MeetingNotes _$MeetingNotesFromJson(Map<String, dynamic> json) =>
    _MeetingNotes(
      meetingId: json['meeting_id'] as String,
      notesMarkdown: json['notes_markdown'] as String?,
      notesJson: json['notes_json'] as String?,
      updatedAt: json['updated_at'] as String?,
    );

Map<String, dynamic> _$MeetingNotesToJson(_MeetingNotes instance) =>
    <String, dynamic>{
      'meeting_id': instance.meetingId,
      'notes_markdown': instance.notesMarkdown,
      'notes_json': instance.notesJson,
      'updated_at': instance.updatedAt,
    };
