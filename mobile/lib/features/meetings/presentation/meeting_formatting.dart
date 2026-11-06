import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/l10n.dart';
import '../domain/meeting_markdown.dart';

/// Locale tag for `intl` formatters.
String localeTagOf(BuildContext context) => Localizations.localeOf(context).toLanguageTag();

/// Absolute date + time in the UI locale (e.g. `2026年10月7日 11:59` / `October 7, 2026 11:59`).
String formatMeetingDateTime(DateTime date, String locale) =>
    DateFormat.yMMMMd(locale).add_Hm().format(date.toLocal());

/// Relative date for list cards: "just now", "5 minutes ago", "3 hours ago", "2 days ago",
/// then the absolute date once older than [maxDays].
String formatRelativeDate(
  DateTime date, {
  required DateTime now,
  required int maxDays,
  required AppLocalizations l10n,
  required String locale,
}) {
  final diff = now.difference(date);
  if (diff.isNegative || diff.inMinutes < 1) return l10n.timeJustNow;
  if (diff.inHours < 1) return l10n.timeMinutesAgo(diff.inMinutes);
  if (diff.inDays < 1) return l10n.timeHoursAgo(diff.inHours);
  if (diff.inDays < maxDays) return l10n.timeDaysAgo(diff.inDays);
  return DateFormat.yMMMd(locale).format(date.toLocal());
}

/// Player clock (`mm:ss` / `h:mm:ss`).
String formatPlayerTime(Duration d) =>
    formatClock(d.inMilliseconds / Duration.millisecondsPerSecond) ?? formatClock(0)!;

/// Labels for the Markdown builders.
MeetingMarkdownLabels markdownLabelsOf(AppLocalizations l10n) => MeetingMarkdownLabels(
  transcriptTitle: l10n.meetingsMdTranscriptTitle,
  summaryTitle: l10n.meetingsMdSummaryTitle,
  date: l10n.meetingsMdDate,
  duration: l10n.meetingsMdDuration,
  meetingId: l10n.meetingsMdMeetingId,
  summary: l10n.meetingsMdSummary,
  transcript: l10n.meetingsMdTranscript,
  noSummary: l10n.meetingsMdNoSummary,
);
