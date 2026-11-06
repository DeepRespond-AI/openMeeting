import '../../../core/api/models/meeting_models.dart';

/// Mirrors desktop MeetingList: title substring OR transcript hit, in list order.
/// Only meetings in the current user's list are shown, once per meeting.
List<TranscriptSearchResult> matchingMeetings(
  List<MeetingSummary> meetings,
  String query,
  List<TranscriptSearchResult> transcriptHits,
) {
  final normalized = query.trim().toLowerCase();
  final snippets = <String, TranscriptSearchResult>{};
  for (final hit in transcriptHits) {
    snippets.putIfAbsent(hit.id, () => hit);
  }
  return [
    for (final meeting in meetings)
      if (meeting.title.toLowerCase().contains(normalized) || snippets.containsKey(meeting.id))
        TranscriptSearchResult(
          id: meeting.id,
          title: meeting.title,
          matchContext: snippets[meeting.id]?.matchContext ?? '',
        ),
  ];
}
