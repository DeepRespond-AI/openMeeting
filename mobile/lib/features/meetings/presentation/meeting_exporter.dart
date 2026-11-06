import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/models/meeting_models.dart';
import '../../../core/config/app_config_provider.dart';
import '../../summary/presentation/summary_controller.dart';
import '../data/meetings_repository_impl.dart';
import '../domain/meeting_markdown.dart';
import '../domain/meetings_repository.dart';

part 'meeting_exporter.g.dart';

/// Builds the copy / share documents of a meeting (desktop `useCopyOperations`).
class MeetingExporter {
  MeetingExporter({required this.repository, required this.pageSize, required this.summaryOf});

  final MeetingsRepository repository;
  final int pageSize;

  /// Current summary Markdown of a meeting (null when none).
  final String? Function(String meetingId) summaryOf;

  /// Every transcript row (pages through the endpoint).
  Future<List<MeetingTranscript>> fetchAllTranscripts(String meetingId) async {
    final all = <MeetingTranscript>[];
    while (true) {
      final page = await repository.getTranscripts(meetingId, limit: pageSize, offset: all.length);
      all.addAll(page.transcripts);
      if (!page.hasMore || page.transcripts.isEmpty) return all;
    }
  }

  /// "Copy transcript" document, or `null` when there is no transcript.
  Future<String?> transcriptDocument(
    MeetingMetadata meeting, {
    required String formattedDate,
    required MeetingMarkdownLabels labels,
  }) async {
    final transcripts = await fetchAllTranscripts(meeting.id);
    if (transcripts.isEmpty) return null;
    return buildTranscriptMarkdown(
      title: meeting.title,
      formattedDate: formattedDate,
      transcripts: transcripts,
      labels: labels,
    );
  }

  /// Whole-meeting export (summary + transcript), or `null` when both are empty.
  Future<String?> meetingDocument(
    MeetingMetadata meeting, {
    required String formattedDate,
    required MeetingMarkdownLabels labels,
  }) async {
    final transcripts = await fetchAllTranscripts(meeting.id);
    final summary = summaryOf(meeting.id);
    if (transcripts.isEmpty && (summary == null || summary.trim().isEmpty)) return null;
    return buildMeetingMarkdown(
      title: meeting.title,
      meetingId: meeting.id,
      formattedDate: formattedDate,
      durationSeconds: meeting.audioDuration,
      summaryMarkdown: summary,
      transcripts: transcripts,
      labels: labels,
    );
  }
}

@riverpod
MeetingExporter meetingExporter(Ref ref) => MeetingExporter(
  repository: ref.watch(meetingsRepositoryProvider),
  pageSize: ref.watch(appConfigProvider.select((c) => c.pagination.transcriptPageSize)),
  summaryOf: (id) => ref.read(summaryControllerProvider(id)).value?.visible?.content,
);
