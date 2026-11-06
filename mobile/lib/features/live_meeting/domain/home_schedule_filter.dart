import 'live_models.dart';

/// Keep active sessions even if their scheduled slot was yesterday. Finished
/// slots remain manageable in the full schedule page, rather than this agenda.
List<LiveSchedule> homeSchedules(List<LiveSchedule> items, DateTime now) =>
    items
        .where(
          (item) =>
              !item.cancelled &&
              (item.activeRoomId != null ||
                  item.startAt.add(Duration(minutes: item.durationMin)).isAfter(now)),
        )
        .toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
