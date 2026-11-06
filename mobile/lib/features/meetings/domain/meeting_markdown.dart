import '../../../core/api/models/meeting_models.dart';

/// Localized labels used by the Markdown builders (filled from l10n by the caller so the
/// builders stay pure and testable).
class MeetingMarkdownLabels {
  const MeetingMarkdownLabels({
    required this.transcriptTitle,
    required this.summaryTitle,
    required this.date,
    required this.duration,
    required this.meetingId,
    required this.summary,
    required this.transcript,
    required this.noSummary,
  });

  /// `Transcript: {title}`.
  final String Function(String title) transcriptTitle;

  /// `Meeting summary: {title}`.
  final String Function(String title) summaryTitle;
  final String date;
  final String duration;
  final String meetingId;
  final String summary;
  final String transcript;
  final String noSummary;
}

/// Formats seconds as `mm:ss` or `h:mm:ss` (desktop `formatClock`). `null`/negative → null.
String? formatClock(double? seconds) {
  if (seconds == null || seconds.isNaN || seconds.isInfinite || seconds < 0) return null;
  final total = seconds.floor();
  final h = total ~/ 3600;
  final m = (total % 3600) ~/ 60;
  final s = total % 60;
  String two(int v) => v.toString().padLeft(2, '0');
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
}

/// Recording-relative `[MM:SS]`; rows without `audio_start_time` keep their wall-clock time
/// (desktop `formatTranscriptTime`).
String formatTranscriptTime(double? seconds, String fallbackTimestamp) {
  if (seconds == null) return fallbackTimestamp;
  final total = seconds.floor();
  String two(int v) => v.toString().padLeft(2, '0');
  return '[${two(total ~/ 60)}:${two(total % 60)}]';
}

/// Transcript lines as the desktop copies them (two trailing spaces = Markdown line break).
String transcriptLines(List<MeetingTranscript> transcripts) => transcripts
    .map((t) => '${formatTranscriptTime(t.audioStartTime, t.timestamp)} ${t.text}  ')
    .join('\n');

/// "Copy transcript" document (desktop `handleCopyTranscript`).
String buildTranscriptMarkdown({
  required String title,
  required String formattedDate,
  required List<MeetingTranscript> transcripts,
  required MeetingMarkdownLabels labels,
}) =>
    '# ${labels.transcriptTitle(title)}\n\n'
    '**${labels.date}:** $formattedDate\n\n'
    '${transcriptLines(transcripts)}';

/// "Copy summary" document.
String buildSummaryMarkdown({
  required String title,
  required String meetingId,
  required String formattedDate,
  required String summaryMarkdown,
  required MeetingMarkdownLabels labels,
}) =>
    '# ${labels.summaryTitle(title)}\n\n'
    '**${labels.meetingId}:** $meetingId\n'
    '**${labels.date}:** $formattedDate\n\n---\n\n'
    '$summaryMarkdown';

/// Whole-meeting export (desktop `handleExportMarkdown`): title, date, duration, id,
/// summary (or a placeholder) and the full transcript.
String buildMeetingMarkdown({
  required String title,
  required String meetingId,
  required String formattedDate,
  required double? durationSeconds,
  required String? summaryMarkdown,
  required List<MeetingTranscript> transcripts,
  required MeetingMarkdownLabels labels,
}) {
  final summary = summaryMarkdown?.trim() ?? '';
  final duration = (durationSeconds != null && durationSeconds > 0)
      ? formatClock(durationSeconds)
      : null;
  final lines = <String>[
    '# $title',
    '',
    '**${labels.date}:** $formattedDate  ',
    if (duration != null) '**${labels.duration}:** $duration  ',
    '**${labels.meetingId}:** $meetingId',
    '',
    '## ${labels.summary}',
    '',
    if (summary.isEmpty) labels.noSummary else summary,
    '',
    '## ${labels.transcript}',
    '',
    transcriptLines(transcripts),
    '',
  ];
  return lines.join('\n');
}
