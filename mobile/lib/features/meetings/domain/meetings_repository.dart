import '../../../core/api/models/meeting_models.dart';
import 'meeting_audio_source.dart';

/// Meetings data access (server/API.md §1.3, §1.4). Implementations throw `ApiException`.
///
/// Layering: `domain/` holds the interface (and feature-specific freezed entities when the
/// shared API models are not enough), `data/` the Dio implementation + its provider,
/// `presentation/` Notifiers and pages.
abstract interface class MeetingsRepository {
  /// `GET /meetings` — newest first.
  Future<List<MeetingSummary>> listMeetings();

  /// `GET /transcripts/search?q=` — one row per matching transcript.
  Future<List<TranscriptSearchResult>> searchTranscripts(String query);

  /// `GET /meetings/{id}/metadata`.
  Future<MeetingMetadata> getMetadata(String meetingId);

  /// `GET /meetings/{id}/transcripts?limit=&offset=`.
  Future<PaginatedTranscripts> getTranscripts(
    String meetingId, {
    required int limit,
    required int offset,
  });

  /// `PATCH /meetings/{id}` `{"title"}`.
  Future<MeetingMetadata> rename(String meetingId, String title);

  /// `DELETE /meetings/{id}`.
  Future<void> delete(String meetingId);

  /// Resolves how the player should fetch `GET /meetings/{id}/audio`: a 302 (OSS) yields the
  /// signed URL to be fetched WITHOUT the session token; otherwise the API URL with the
  /// Bearer header. [MeetingAudioSource.none] when the server has no audio (404).
  Future<MeetingAudioSource> resolveAudio(String meetingId);
}
