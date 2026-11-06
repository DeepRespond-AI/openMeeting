import 'dart:io';
import 'dart:typed_data';

import '../../../core/api/models/meeting_models.dart';
import 'segment_upload.dart';

/// Called with bytes sent so far and the total (`total` ≤ 0 when unknown).
typedef UploadProgress = void Function(int sent, int total);

/// Server calls of the recording flow (server/API.md §1.2–1.4). Implementations throw
/// `ApiException`.
abstract interface class RecordingRepository {
  /// `POST /meetings`.
  Future<MeetingMetadata> createMeeting(String title);

  /// `POST /meetings/{id}/segments` with the raw PCM16 [pcm] body.
  Future<SegmentResult> uploadSegment(SegmentUpload upload, Uint8List pcm);

  /// `PUT /meetings/{id}/audio` streaming [file].
  Future<AudioUploadResult> uploadAudio(
    String meetingId,
    File file, {
    double? duration,
    UploadProgress? onProgress,
  });

  /// `PATCH /meetings/{id}`.
  Future<void> renameMeeting(String meetingId, String title);

  /// `DELETE /meetings/{id}` (cleanup when the recording could not start).
  Future<void> deleteMeeting(String meetingId);
}
