import 'live_models.dart';

List<LiveSchedule> filterUpcomingSchedules(List<LiveSchedule> items, DateTime now, String query) {
  String normalized(String value) => value.toLowerCase().replaceAll(RegExp(r'\s+'), '');
  final search = normalized(query);
  return items
      .where(
        (item) =>
            !item.cancelled &&
            (search.isEmpty ||
                [
                  item.title,
                  item.code,
                  item.host['name']?.toString() ?? '',
                ].any((v) => normalized(v).contains(search))),
      )
      .toList()
    ..sort((a, b) => a.startAt.compareTo(b.startAt));
}
