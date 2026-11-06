import 'package:flutter_test/flutter_test.dart';
import 'package:meeting/core/api/models/meeting_models.dart';
import 'package:meeting/features/meetings/domain/meeting_detail_route.dart';
import 'package:meeting/features/meetings/domain/meeting_markdown.dart';

final _labels = MeetingMarkdownLabels(
  transcriptTitle: (t) => 'Transcript: $t',
  summaryTitle: (t) => 'Meeting summary: $t',
  date: 'Date',
  duration: 'Duration',
  meetingId: 'Meeting ID',
  summary: 'Summary',
  transcript: 'Transcript',
  noSummary: '(No summary yet)',
);

const _rows = [
  MeetingTranscript(id: 'a', text: '大家好', timestamp: '10:00:00', audioStartTime: 0),
  MeetingTranscript(id: 'b', text: '开始', timestamp: '10:01:05', audioStartTime: 65.9),
  MeetingTranscript(id: 'c', text: '旧数据', timestamp: '10:02:00'),
];

void main() {
  test('formatClock / formatTranscriptTime', () {
    expect(formatClock(5), '00:05');
    expect(formatClock(3725), '1:02:05');
    expect(formatClock(null), isNull);
    expect(formatClock(-1), isNull);
    expect(formatTranscriptTime(65.9, 'x'), '[01:05]');
    expect(formatTranscriptTime(null, '10:02:00'), '10:02:00');
  });

  test('meeting export mirrors desktop handleExportMarkdown', () {
    final md = buildMeetingMarkdown(
      title: '周会',
      meetingId: 'meeting-1',
      formattedDate: 'October 7, 2026 11:59',
      durationSeconds: 3725,
      summaryMarkdown: '  ## 要点\n- A  ',
      transcripts: _rows,
      labels: _labels,
    );
    expect(
      md,
      '# 周会\n'
      '\n'
      '**Date:** October 7, 2026 11:59  \n'
      '**Duration:** 1:02:05  \n'
      '**Meeting ID:** meeting-1\n'
      '\n'
      '## Summary\n'
      '\n'
      '## 要点\n- A\n'
      '\n'
      '## Transcript\n'
      '\n'
      '[00:00] 大家好  \n'
      '[01:05] 开始  \n'
      '10:02:00 旧数据  \n',
    );
  });

  test('export without summary or duration', () {
    final md = buildMeetingMarkdown(
      title: 'T',
      meetingId: 'm',
      formattedDate: 'D',
      durationSeconds: null,
      summaryMarkdown: null,
      transcripts: const [],
      labels: _labels,
    );
    expect(md, contains('(No summary yet)'));
    expect(md, isNot(contains('Duration')));
  });

  test('transcript and summary copy documents', () {
    expect(
      buildTranscriptMarkdown(
        title: '周会',
        formattedDate: 'D',
        transcripts: _rows.take(1).toList(),
        labels: _labels,
      ),
      '# Transcript: 周会\n\n**Date:** D\n\n[00:00] 大家好  ',
    );
    expect(
      buildSummaryMarkdown(
        title: '周会',
        meetingId: 'm',
        formattedDate: 'D',
        summaryMarkdown: 'S',
        labels: _labels,
      ),
      '# Meeting summary: 周会\n\n**Meeting ID:** m\n**Date:** D\n\n---\n\nS',
    );
  });

  test('detail route with autoSummary', () {
    expect(MeetingDetailRoute.location('meeting-1'), '/meetings/meeting-1');
    final withAuto = MeetingDetailRoute.location('meeting-1', autoSummary: true);
    expect(withAuto, '/meetings/meeting-1?autoSummary=1');
    expect(MeetingDetailRoute.wantsAutoSummary(Uri.parse(withAuto).queryParameters), isTrue);
    expect(MeetingDetailRoute.wantsAutoSummary(const {}), isFalse);
  });
}
