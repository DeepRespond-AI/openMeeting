import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meeting/core/l10n/l10n.dart';
import 'package:meeting/features/live_meeting/domain/home_schedule_filter.dart';
import 'package:meeting/features/live_meeting/domain/live_models.dart';
import 'package:meeting/features/live_meeting/domain/room_grid_layout.dart';

void main() {
  test('new Chinese labels and time separator survive resource generation', () {
    final l = lookupAppLocalizations(const Locale('zh'));
    expect(l.liveRecordingTools, '录音转写');
    expect(l.liveToday, '今天');
    expect(l.liveTomorrow, '明天');
    expect(l.liveInvite, '邀请参会');
    expect(l.liveAgendaOngoing, '进行中');
    expect(l.liveAgendaJoined, '已入会');
    expect(l.liveAgendaTime('16:00', '16:30'), '16:00–16:30');
  });
  RoomGridLayout grid(double width, double height, int count) =>
      RoomGridLayout.fit(width: width, height: height, count: count, gap: 12, minExtent: 132);
  test('two people fill portrait vertically and landscape horizontally', () {
    expect(grid(358, 540, 2).columns, 1);
    expect(grid(358, 540, 2).rows, 2);
    expect(grid(990, 440, 2).columns, 2);
    expect(grid(990, 440, 2).rows, 1);
  });
  test('single participant fills stage; uneven rows use one invitation', () {
    final single = grid(358, 540, 1), three = grid(358, 540, 3);
    expect(single.rows, 1);
    expect(single.columns, 1);
    expect(single.inviteSpan, 0);
    expect(single.height, 540);
    expect(three.columns, 2);
    expect(three.rows, 2);
    expect(three.inviteSpan, 1);
    final five = grid(990, 440, 5);
    expect(five.columns, 3);
    expect(five.rows, 2);
    expect(five.inviteSpan, 1);
  });
  test('all slots covered and large rooms preserve scrollable tile height', () {
    for (final size in [(288.0, 240.0), (358.0, 540.0), (990.0, 440.0)]) {
      for (var count = 0; count <= 40; count++) {
        final result = grid(size.$1, size.$2, count);
        expect(count + result.inviteSpan, result.rows * result.columns);
        expect(result.inviteSpan, lessThanOrEqualTo(1));
        expect(result.height, greaterThanOrEqualTo(size.$2));
        expect((result.height - (result.rows - 1) * 12) / result.rows, greaterThanOrEqualTo(132));
      }
    }
    expect(grid(358, 300, 20).height, greaterThan(300));
  });
  final now = DateTime(2026, 10, 28, 12);
  LiveSchedule item(String id, DateTime start, {bool cancelled = false, String? active}) =>
      LiveSchedule(
        id: id,
        code: '123456',
        title: id,
        startAt: start,
        durationMin: 30,
        cancelled: cancelled,
        activeRoomId: active,
      );
  test('agenda retains yesterday active session, sorts and excludes expired/cancelled', () {
    final rows = [
      item('tomorrow', now.add(const Duration(days: 1))),
      item('expired', now.subtract(const Duration(hours: 1))),
      item('yesterday-active', now.subtract(const Duration(days: 1)), active: 'room'),
      item('today', now.add(const Duration(hours: 1))),
      item('cancelled-active', now, cancelled: true, active: 'cancelled-room'),
    ];
    expect(homeSchedules(rows, now).map((v) => v.id), ['yesterday-active', 'today', 'tomorrow']);
    expect(rows.first.id, 'tomorrow', reason: 'Do not mutate the shared provider list');
  });
  test('slot expires exactly at the scheduled end', () {
    expect(
      homeSchedules([item('ended-now', now.subtract(const Duration(minutes: 30)))], now),
      isEmpty,
    );
  });
}
