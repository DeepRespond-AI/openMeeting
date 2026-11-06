import 'package:flutter_test/flutter_test.dart';
import 'package:meeting/core/api/models/meeting_models.dart';
import 'package:meeting/features/meetings/domain/meeting_search.dart';

void main() {
  const meetings = [
    MeetingSummary(id: 'budget', title: '移动端预算评审'),
    MeetingSummary(id: 'design', title: 'Design Review'),
    MeetingSummary(id: 'literal', title: '进度 100%_完成'),
    MeetingSummary(id: 'notes', title: '研发周会'),
  ];
  List<String> ids(String query, [List<TranscriptSearchResult> hits = const []]) =>
      matchingMeetings(meetings, query, hits).map((m) => m.id).toList();

  test('Chinese title matches prefix, middle and suffix without any transcript', () {
    for (final query in ['移动', '预算', '评审']) {
      expect(ids(query), ['budget']);
    }
  });
  test('title matching trims input and ignores Latin case like desktop', () {
    expect(ids('  dEsIgN  '), ['design']);
    expect(ids('REVIEW'), ['design']);
  });
  test('search metacharacters are literal substrings', () {
    expect(ids('%_'), ['literal']);
    expect(ids('.*'), isEmpty);
  });
  test('unions title and transcript hits in meeting order, with one row per meeting', () {
    final hits = [
      const TranscriptSearchResult(id: 'notes', title: 'old title', matchContext: '预算内容'),
      const TranscriptSearchResult(id: 'budget', title: 'old title', matchContext: '首个预算片段'),
      const TranscriptSearchResult(id: 'budget', title: 'old title', matchContext: '重复片段'),
      const TranscriptSearchResult(id: 'not-listed', title: '不可见', matchContext: '预算'),
    ];
    final result = matchingMeetings(meetings, '预算', hits);
    expect(result.map((r) => r.id), ['budget', 'notes']);
    expect(result.first.title, '移动端预算评审');
    expect(result.first.matchContext, '首个预算片段');
  });
  test('empty query restores original meeting order and no match yields an empty list', () {
    expect(ids('  '), ['budget', 'design', 'literal', 'notes']);
    expect(ids('不存在'), isEmpty);
  });
}
