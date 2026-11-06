import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/auth/session_controller.dart';
import '../../../core/config/app_config_provider.dart';
import '../domain/live_models.dart';
import 'schedules_controller.dart';

part 'reminder_controller.g.dart';

/// Foreground reminders only. Background push requires platform credentials.
@Riverpod(keepAlive: true)
class LiveReminder extends _$LiveReminder {
  final _delivered = <String>{};
  bool _foreground = true;
  @override
  LiveSchedule? build() {
    final signedIn = ref.watch(currentUserProvider)?.id;
    _delivered.clear();
    if (signedIn == null) return null;
    final config = ref.watch(appConfigProvider).live;
    void refresh() {
      if (_foreground) ref.invalidate(liveSchedulesProvider);
    }

    final timer = Timer.periodic(Duration(milliseconds: config.reminderPollMs), (_) => refresh());
    final lifecycle = AppLifecycleListener(
      onResume: () {
        _foreground = true;
        refresh();
      },
      onPause: () => _foreground = false,
      onHide: () => _foreground = false,
    );
    ref.onDispose(() {
      timer.cancel();
      lifecycle.dispose();
    });
    ref.listen(liveSchedulesProvider, (_, next) {
      final now = DateTime.now();
      for (final item in next.value ?? <LiveSchedule>[]) {
        final key = '${item.id}/${item.startAt.toUtc().toIso8601String()}';
        if (_foreground &&
            item.remind &&
            !item.cancelled &&
            item.startAt.isAfter(now) &&
            item.startAt.difference(now) <= Duration(minutes: config.reminderLeadMin) &&
            _delivered.add(key)) {
          state = item;
          break;
        }
      }
    });
    return null;
  }
}
