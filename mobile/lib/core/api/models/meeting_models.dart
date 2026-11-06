import 'package:freezed_annotation/freezed_annotation.dart';

part 'meeting_models.freezed.dart';
part 'meeting_models.g.dart';

/// Item of `GET /meetings` (`[{"id","title"}]`, newest first).
@freezed
abstract class MeetingSummary with _$MeetingSummary {
  const factory MeetingSummary({
    required String id,
    required String title,
    @JsonKey(name: 'can_manage') @Default(true) bool canManage,
    // Present since the list endpoint returns timestamps; null on older servers.
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _MeetingSummary;

  factory MeetingSummary.fromJson(Map<String, dynamic> json) => _$MeetingSummaryFromJson(json);
}

/// `MeetingMetadata` — returned by create, metadata and rename.
@freezed
abstract class MeetingMetadata with _$MeetingMetadata {
  const factory MeetingMetadata({
    required String id,
    required String title,
    @JsonKey(name: 'can_manage') @Default(true) bool canManage,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @JsonKey(name: 'folder_path') String? folderPath,
    @JsonKey(name: 'has_audio') @Default(false) bool hasAudio,

    /// Seconds.
    @JsonKey(name: 'audio_duration') double? audioDuration,
  }) = _MeetingMetadata;

  factory MeetingMetadata.fromJson(Map<String, dynamic> json) => _$MeetingMetadataFromJson(json);
}

/// One transcript row (`MeetingTranscript` / `TranscriptSegment`).
@freezed
abstract class MeetingTranscript with _$MeetingTranscript {
  const factory MeetingTranscript({
    required String id,
    required String text,
    required String timestamp,

    /// Seconds from the start of the recording.
    @JsonKey(name: 'audio_start_time') double? audioStartTime,
    @JsonKey(name: 'audio_end_time') double? audioEndTime,
    double? duration,
  }) = _MeetingTranscript;

  factory MeetingTranscript.fromJson(Map<String, dynamic> json) =>
      _$MeetingTranscriptFromJson(json);
}

/// `GET /meetings/{id}` — details including all transcripts.
@freezed
abstract class MeetingDetails with _$MeetingDetails {
  const factory MeetingDetails({
    required String id,
    required String title,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @Default(<MeetingTranscript>[]) List<MeetingTranscript> transcripts,
  }) = _MeetingDetails;

  factory MeetingDetails.fromJson(Map<String, dynamic> json) => _$MeetingDetailsFromJson(json);
}

/// `GET /meetings/{id}/transcripts?limit=&offset=`.
@freezed
abstract class PaginatedTranscripts with _$PaginatedTranscripts {
  const factory PaginatedTranscripts({
    required List<MeetingTranscript> transcripts,
    @JsonKey(name: 'total_count') required int totalCount,
    @JsonKey(name: 'has_more') required bool hasMore,
  }) = _PaginatedTranscripts;

  factory PaginatedTranscripts.fromJson(Map<String, dynamic> json) =>
      _$PaginatedTranscriptsFromJson(json);
}

/// Item of `GET /transcripts/search?q=` (note the camelCase `matchContext`).
@freezed
abstract class TranscriptSearchResult with _$TranscriptSearchResult {
  const factory TranscriptSearchResult({
    required String id,
    required String title,
    required String matchContext,
    String? timestamp,
  }) = _TranscriptSearchResult;

  factory TranscriptSearchResult.fromJson(Map<String, dynamic> json) =>
      _$TranscriptSearchResultFromJson(json);
}

/// Response of `POST /meetings/{id}/segments`. `id == null` → empty text, nothing stored.
@freezed
abstract class SegmentResult with _$SegmentResult {
  const factory SegmentResult({
    String? id,
    required String text,
    double? confidence,
    required int seq,
  }) = _SegmentResult;

  factory SegmentResult.fromJson(Map<String, dynamic> json) => _$SegmentResultFromJson(json);
}

/// Response of `PUT /meetings/{id}/audio`.
@freezed
abstract class AudioUploadResult with _$AudioUploadResult {
  const factory AudioUploadResult({required int size, double? duration}) = _AudioUploadResult;

  factory AudioUploadResult.fromJson(Map<String, dynamic> json) =>
      _$AudioUploadResultFromJson(json);
}

/// `GET/PUT /meetings/{id}/notes`.
@freezed
abstract class MeetingNotes with _$MeetingNotes {
  const factory MeetingNotes({
    @JsonKey(name: 'meeting_id') required String meetingId,
    @JsonKey(name: 'notes_markdown') String? notesMarkdown,
    @JsonKey(name: 'notes_json') String? notesJson,
    @JsonKey(name: 'updated_at') String? updatedAt,
  }) = _MeetingNotes;

  factory MeetingNotes.fromJson(Map<String, dynamic> json) => _$MeetingNotesFromJson(json);
}
