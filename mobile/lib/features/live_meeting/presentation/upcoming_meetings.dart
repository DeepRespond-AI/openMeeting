import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config_provider.dart';
import '../../../core/theme/context_extensions.dart';
import '../domain/schedule_filter.dart';
import 'home_page.dart';
import 'live_feedback.dart';
import 'schedule_sheet.dart';
import 'schedules_controller.dart';

class UpcomingMeetings extends ConsumerStatefulWidget {
  const UpcomingMeetings({super.key});
  @override
  ConsumerState<UpcomingMeetings> createState() => _UpcomingMeetingsState();
}

class _UpcomingMeetingsState extends ConsumerState<UpcomingMeetings> {
  final search = TextEditingController();
  Timer? _timer;
  AppLifecycleListener? _lifecycle;
  bool _foreground = true;
  @override
  void initState() {
    super.initState();
    void refresh() {
      if (mounted && _foreground) ref.invalidate(upcomingSchedulesProvider);
    }

    _timer = Timer.periodic(
      Duration(milliseconds: ref.read(appConfigProvider).live.reminderPollMs),
      (_) => refresh(),
    );
    _lifecycle = AppLifecycleListener(
      onPause: () => _foreground = false,
      onResume: () {
        _foreground = true;
        refresh();
      },
    );
  }

  @override
  void dispose() {
    search.dispose();
    _timer?.cancel();
    _lifecycle?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n, schedules = ref.watch(upcomingSchedulesProvider);
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: context.sizes.maxContentWidth),
        child: Column(
          children: [
            Padding(
              padding: context.spacing.page,
              child: Column(
                children: [
                  TextField(
                    key: const ValueKey('upcoming-search'),
                    controller: search,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: l.liveScheduleSearch,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: search.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: l.meetingsSearchClear,
                              onPressed: () {
                                search.clear();
                                setState(() {});
                              },
                              icon: const Icon(Icons.close),
                            ),
                    ),
                  ),
                  context.spacing.gapSm,
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: () => showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        builder: (_) => const ScheduleSheet(),
                      ),
                      icon: const Icon(Icons.add),
                      label: Text(l.liveSchedule),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: schedules.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) =>
                    LiveError(error, onRetry: () => ref.invalidate(upcomingSchedulesProvider)),
                data: (items) {
                  final rows = filterUpcomingSchedules(items, DateTime.now(), search.text);
                  return RefreshIndicator(
                    onRefresh: () => ref.read(upcomingSchedulesProvider.notifier).reload(),
                    child: ListView(
                      padding: context.spacing.page,
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        if (rows.isEmpty)
                          Padding(
                            padding: context.spacing.page,
                            child: Text(
                              search.text.trim().isEmpty
                                  ? l.liveNoSchedules
                                  : l.liveScheduleNoMatches,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        for (var i = 0; i < rows.length; i++) ...[
                          if (i == 0 ||
                              DateUtils.dateOnly(rows[i - 1].startAt.toLocal()) !=
                                  DateUtils.dateOnly(rows[i].startAt.toLocal()))
                            Padding(
                              padding: context.spacing.card,
                              child: Text(
                                MaterialLocalizations.of(context)
                                    .formatFullDate(rows[i].startAt.toLocal()),
                                style: context.textTheme.titleMedium,
                              ),
                            ),
                          ScheduleCard(rows[i]),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
