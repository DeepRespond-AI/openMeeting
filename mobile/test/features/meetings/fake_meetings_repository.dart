import 'dart:async';

import 'package:meeting/core/api/models/meeting_models.dart';
import 'package:meeting/features/meetings/domain/meeting_audio_source.dart';
import 'package:meeting/features/meetings/domain/meetings_repository.dart';

/// In-memory [MeetingsRepository] for Notifier tests.
class FakeMeetingsRepository implements MeetingsRepository {
  List<MeetingSummary> items = const [MeetingSummary(id: 'm1', title: '周会')];
  List<MeetingTranscript> transcripts = const [];
  Map<String, List<TranscriptSearchResult>> searchResults = {};
  Object? error;
  Object? deleteError;
  Object? searchError;
  int listCalls = 0;
  final List<String> searches = [];
  final List<String> deleted = [];
  final List<(int limit, int offset)> pages = [];

  /// When set, `searchTranscripts` waits for it (to test stale responses).
  Map<String, Completer<void>> searchGates = {};

  @override
  Future<List<MeetingSummary>> listMeetings() async {
    listCalls++;
    if (error case final e?) throw e;
    return items;
  }

  @override
  Future<List<TranscriptSearchResult>> searchTranscripts(String query) async {
    searches.add(query);
    await searchGates[query]?.future;
    if (searchError case final e?) throw e;
    return searchResults[query] ?? const [];
  }

  @override
  Future<MeetingMetadata> getMetadata(String meetingId) async =>
      MeetingMetadata(id: meetingId, title: 'T', createdAt: DateTime.utc(2026, 10, 7));

  @override
  Future<PaginatedTranscripts> getTranscripts(
    String meetingId, {
    required int limit,
    required int offset,
  }) async {
    pages.add((limit, offset));
    final end = (offset + limit).clamp(0, transcripts.length);
    final slice = offset >= transcripts.length
        ? <MeetingTranscript>[]
        : transcripts.sublist(offset, end);
    return PaginatedTranscripts(
      transcripts: slice,
      totalCount: transcripts.length,
      hasMore: end < transcripts.length,
    );
  }

  @override
  Future<MeetingMetadata> rename(String meetingId, String title) async {
    if (error case final e?) throw e;
    return MeetingMetadata(id: meetingId, title: title);
  }

  @override
  Future<void> delete(String meetingId) async {
    deleted.add(meetingId);
    if (deleteError case final e?) throw e;
  }

  @override
  Future<MeetingAudioSource> resolveAudio(String meetingId) async =>
      const MeetingAudioSource.none();
}

List<MeetingTranscript> makeTranscripts(int n) => [
  for (var i = 0; i < n; i++)
    MeetingTranscript(
      id: 't$i',
      text: 'line $i',
      timestamp: '2026-10-07T00:00:00Z',
      audioStartTime: i * 2.0,
      audioEndTime: i * 2.0 + 2,
    ),
];
