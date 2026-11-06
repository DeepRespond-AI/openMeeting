import '../../../core/api/models/summary_models.dart';

/// AI summary access (server/API.md §1.6). The server picks the LLM. Throws `ApiException`.
abstract interface class SummaryRepository {
  /// `POST /meetings/{id}/summary` with `language: null` (server detects) and `text: null`
  /// (stored transcripts). The server picks the summary template.
  Future<ProcessStarted> start(String meetingId, {String? customPrompt});

  /// `GET /meetings/{id}/summary`.
  Future<SummaryResponse> get(String meetingId);

  /// `DELETE /meetings/{id}/summary` — cancels a running generation.
  Future<void> cancel(String meetingId);

  /// `PUT /meetings/{id}/summary` `{"summary":{"markdown": md}}` (400 empty/invalid, 404 none yet).
  Future<void> saveMarkdown(String meetingId, String markdown);
}
