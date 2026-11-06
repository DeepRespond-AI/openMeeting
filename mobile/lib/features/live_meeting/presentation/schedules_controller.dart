import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/auth/session_controller.dart';

import '../data/live_repository_impl.dart';
import '../domain/live_models.dart';
part 'schedules_controller.g.dart';

@Riverpod(keepAlive: true)
class LiveSchedules extends _$LiveSchedules {
  @override
  Future<List<LiveSchedule>> build() {
    ref.watch(currentUserProvider.select((user) => user?.id));
    final now = DateTime.now();
    return ref
        .watch(liveRepositoryProvider)
        .schedules(
          DateTime(now.year, now.month, now.day),
          DateTime(now.year, now.month, now.day + 1),
        );
  }

  Future<void> reload() async {
    final next = await AsyncValue.guard(build);
    if (ref.mounted) state = next;
  }

  Future<void> save(Map<String, Object?> values, {String? id}) async {
    await ref.read(liveRepositoryProvider).saveSchedule(values, id: id);
    ref.invalidate(upcomingSchedulesProvider);
    await reload();
  }

  Future<void> cancel(String id) async {
    await ref.read(liveRepositoryProvider).cancelSchedule(id);
    ref.invalidate(upcomingSchedulesProvider);
    await reload();
  }
}

@riverpod
class UpcomingSchedules extends _$UpcomingSchedules {
  @override
  Future<List<LiveSchedule>> build() {
    ref.watch(currentUserProvider.select((user) => user?.id));
    return ref.watch(liveRepositoryProvider).schedules(null, null);
  }

  Future<void> reload() async {
    final next = await AsyncValue.guard(build);
    if (ref.mounted) state = next;
  }
}
