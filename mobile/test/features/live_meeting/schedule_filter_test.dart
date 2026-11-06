import 'package:flutter_test/flutter_test.dart';
import 'package:meeting/features/live_meeting/domain/live_models.dart';
import 'package:meeting/features/live_meeting/domain/schedule_filter.dart';

void main() {
  final now = DateTime.utc(2026, 10, 26, 10);
  LiveSchedule item(
    String id,
    int days, {
    bool cancelled = false,
    String? meetingId,
    String title = 'Design review',
  }) => LiveSchedule(
    id: id,
    code: '123456',
    title: title,
    startAt: now.add(Duration(days: days)),
    durationMin: 30,
    host: {'name': 'Jasper'},
    cancelled: cancelled,
    meetingId: meetingId,
  );
  test('reservations retain past dates and previous records until cancellation', () {
    final result = filterUpcomingSchedules(
      [
        item('far', 365),
        item('soon', 1),
        item('past', -1),
        item('cancelled', 2, cancelled: true),
        item('ended', 3, meetingId: 'notes'),
      ],
      now,
      '',
    );
    expect(result.map((r) => r.id), ['past', 'soon', 'ended', 'far']);
  });
  test('search matches normalized title, host and meeting number', () {
    final rows = [item('one', 1)];
    for (final query in ['DESIGN REVIEW', 'jasper', '123 456']) {
      expect(filterUpcomingSchedules(rows, now, query).single.id, 'one');
    }
    expect(filterUpcomingSchedules(rows, now, 'absent'), isEmpty);
  });
}
