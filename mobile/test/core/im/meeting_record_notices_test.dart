import 'package:deeprespond_im/deeprespond_im.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meeting/core/im/meeting_record_notices.dart';

MessageView notice({
  String sender = 'notice',
  String event = 'meeting_ended',
  String id = 'meeting-1',
  int seq = 1,
  bool erased = false,
  bool recalled = false,
  Object title = '共享会议',
}) => MessageView({
  'conversation_id': 'notice:user',
  'seq': seq,
  'type': 'custom',
  'sender': sender,
  'erased': erased,
  if (recalled) 'recalled': {'at': '2026-10-26'},
  'body': {
    'kind': 'openmeeting.meeting',
    'version': 1,
    'event': event,
    'meetingId': id,
    'title': title,
  },
});

void main() {
  test('offline history restores only latest unread outcome per meeting', () {
    final latest = latestMeetingNotices(
      [
        notice(seq: 1),
        notice(seq: 2, event: 'processing_completed'),
        notice(seq: 3, id: 'other'),
        notice(seq: 4, sender: 'forged'),
      ],
      readSeq: 1,
      limit: 3,
    );
    expect(latest.map((m) => m.seq), [2, 3]);
    expect(latestMeetingNotices(latest, readSeq: 3, limit: 3), isEmpty);
    expect(latestMeetingNotices(latest, readSeq: 0, limit: 1).single.seq, 3);
  });
  test('trusted meeting outcomes accepted without claiming failed work is ready', () {
    for (final event in ['meeting_ended', 'processing_completed', 'processing_failed']) {
      expect(parseMeetingRecordNotice(notice(event: event))?.event, event);
    }
  });
  test('forged sender, invalid IDs and unknown outcomes ignored', () {
    for (final message in [
      notice(sender: 'someone'),
      notice(id: '../private'),
      notice(event: 'ready'),
      notice(erased: true),
      notice(recalled: true),
      const MessageView({'type': 'text'}),
    ]) {
      expect(parseMeetingRecordNotice(message), isNull);
    }
  });
  test('malformed title cannot crash the global notification stream', () {
    expect(parseMeetingRecordNotice(notice(title: 42))?.title, isNull);
  });
  test('duplicate delivery suppressed; dedup storage is bounded', () {
    final filter = MeetingNoticeFilter(2);
    expect(filter.accept(notice(seq: 1)), isNotNull);
    expect(filter.accept(notice(seq: 1)), isNull);
    expect(filter.accept(notice(seq: 2)), isNotNull);
    expect(filter.accept(notice(seq: 3)), isNotNull);
    expect(filter.accept(notice(seq: 1)), isNotNull);
  });
}
