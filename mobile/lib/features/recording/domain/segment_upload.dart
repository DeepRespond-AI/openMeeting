import 'package:freezed_annotation/freezed_annotation.dart';

part 'segment_upload.freezed.dart';
part 'segment_upload.g.dart';

/// Metadata of one live segment upload (`POST /meetings/{id}/segments`). The PCM body is
/// stored/passed separately. Also the persisted record of the pending upload queue.
@freezed
abstract class SegmentUpload with _$SegmentUpload {
  const factory SegmentUpload({
    required String meetingId,

    /// 0-based, increasing per meeting; the server dedups on `(meeting_id, seq)`.
    required int seq,
    required double startSec,
    required double endSec,

    /// Transcription language; `null` = auto-detect (query parameter omitted).
    String? language,
  }) = _SegmentUpload;

  factory SegmentUpload.fromJson(Map<String, dynamic> json) => _$SegmentUploadFromJson(json);
}

/// Server result of a segment upload, tagged with what was uploaded.
@freezed
abstract class SegmentUploadResult with _$SegmentUploadResult {
  const factory SegmentUploadResult({
    required SegmentUpload upload,

    /// Transcribed text ('' when the server heard nothing).
    required String text,

    /// Stored transcript id; `null` when nothing was stored.
    String? transcriptId,
  }) = _SegmentUploadResult;
}
