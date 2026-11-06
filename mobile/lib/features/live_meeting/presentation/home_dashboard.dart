import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/auth/session_controller.dart';
import '../../../core/config/app_config_provider.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/context_extensions.dart';
import '../../../core/widgets/brand_logo.dart';
import '../domain/home_schedule_filter.dart';
import '../domain/live_models.dart';
import 'home_page.dart';
import 'live_feedback.dart';
import 'room_controller.dart';
import 'schedule_sheet.dart';
import 'schedules_controller.dart';

class LiveHomePage extends ConsumerStatefulWidget {
  const LiveHomePage({super.key});
  @override
  ConsumerState<LiveHomePage> createState() => _LiveHomePageState();
}

class _LiveHomePageState extends ConsumerState<LiveHomePage> {
  Timer? _timer;
  late final AppLifecycleListener _lifecycle;
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
    _timer?.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n, s = context.spacing;
    final messagesEnabled = ref.watch(appConfigProvider).features.standaloneMessages;
    final actions = [
      (
        Icons.videocam_outlined,
        l.liveQuick,
        'live-quick',
        () {
          if (resumeMeeting(context, ref)) return;
          unawaited(ref.read(roomControllerProvider.notifier).join('', create: true));
          context.push(AppRoutes.liveRoom);
        },
      ),
      (
        Icons.add_box_outlined,
        l.liveJoin,
        'live-join',
        () {
          if (!resumeMeeting(context, ref)) {
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              builder: (_) => const JoinSheet(),
            );
          }
        },
      ),
      (
        Icons.event_outlined,
        l.liveSchedule,
        'live-schedule',
        () {
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            builder: (_) => const ScheduleSheet(),
          );
        },
      ),
      (
        Icons.graphic_eq,
        l.liveRecordingTools,
        'live-recording-tools',
        () {
          context.push(AppRoutes.recordingTools);
        },
      ),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [const BrandLogo(), s.gapSm, Text(l.appName)]),
        actions: [
          if (messagesEnabled)
            IconButton(
              tooltip: l.liveMessages,
              icon: const Icon(Icons.chat_bubble_outline),
              onPressed: () => context.push(AppRoutes.messages),
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: context.sizes.maxContentWidth),
          child: RefreshIndicator(
            onRefresh: () => ref.read(upcomingSchedulesProvider.notifier).reload(),
            child: ListView(
              key: const ValueKey('live-home-scroll'),
              physics: const AlwaysScrollableScrollPhysics(),
              padding: s.page,
              children: [
                Text(l.liveWelcome, style: Theme.of(context).textTheme.headlineSmall),
                s.gapSm,
                Text(l.liveWelcomeHint, style: TextStyle(color: context.colors.mutedForeground)),
                s.gapXl,
                LayoutBuilder(
                  builder: (context, box) => Wrap(
                    spacing: s.sm,
                    runSpacing: s.sm,
                    children: [
                      for (final action in actions)
                        SizedBox(
                          width: (box.maxWidth - s.sm) / 2,
                          child: Card(
                            margin: EdgeInsets.zero,
                            child: InkWell(
                              key: ValueKey(action.$3),
                              onTap: action.$4,
                              borderRadius: context.radius.lgAll,
                              child: Padding(
                                padding: s.card,
                                child: Column(
                                  children: [
                                    CircleAvatar(
                                      radius: context.sizes.iconXl,
                                      backgroundColor: action.$3 == 'live-quick'
                                          ? context.colors.primary
                                          : context.colors.accent,
                                      child: Icon(
                                        action.$1,
                                        color: action.$3 == 'live-quick'
                                            ? context.colors.onPrimary
                                            : context.colors.primary,
                                      ),
                                    ),
                                    s.gapSm,
                                    Text(action.$2, textAlign: TextAlign.center),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                s.gapXl,
                Row(
                  children: [
                    Expanded(
                      child: Text(l.liveUpcoming, style: Theme.of(context).textTheme.titleMedium),
                    ),
                    IconButton(
                      key: const ValueKey('home-schedules-refresh'),
                      tooltip: l.liveRefresh,
                      onPressed: () => ref.invalidate(upcomingSchedulesProvider),
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                Text(
                  DateFormat.MMMd(Localizations.localeOf(context).toLanguageTag())
                      .format(DateTime.now()),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                s.gapSm,
                const HomeScheduleList(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A compact home agenda; detailed editing/cancellation stays in the row sheet.
class HomeScheduleList extends ConsumerWidget {
  const HomeScheduleList({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedules = ref.watch(upcomingSchedulesProvider), now = DateTime.now();
    final l = context.l10n, s = context.spacing;
    final session = ref.watch(roomControllerProvider);
    return schedules.when(
      loading: () => Padding(
        padding: s.page,
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) =>
          LiveError(error, onRetry: () => ref.invalidate(upcomingSchedulesProvider)),
      data: (items) {
        final rows = homeSchedules(items, now);
        if (rows.isEmpty) {
          return Padding(
            padding: s.page,
            child: Column(
              children: [
                Icon(Icons.event_available_outlined, color: context.colors.mutedForeground),
                s.gapSm,
                Text(l.liveNoSchedules),
              ],
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i == 0 ||
                  !DateUtils.isSameDay(rows[i - 1].startAt.toLocal(), rows[i].startAt.toLocal()))
                Padding(
                  padding: EdgeInsets.only(top: s.lg, bottom: s.xs),
                  child: Text(
                    _dayLabel(context, rows[i].startAt.toLocal(), now),
                    style: TextStyle(
                      color: context.colors.mutedForeground,
                      fontSize: Theme.of(context).textTheme.bodySmall?.fontSize,
                    ),
                  ),
                ),
              HomeScheduleRow(
                rows[i],
                joined: switch (session) {
                  RoomActive(:final room) || RoomWaiting(:final room) =>
                    room.id == rows[i].activeRoomId || room.code == rows[i].code,
                  _ => false,
                },
              ),
            ],
          ],
        );
      },
    );
  }

  String _dayLabel(BuildContext context, DateTime date, DateTime now) {
    final today = DateUtils.dateOnly(now), locale = Localizations.localeOf(context).toLanguageTag();
    final relative = DateUtils.isSameDay(date, today)
        ? context.l10n.liveToday
        : DateUtils.isSameDay(date, DateTime(today.year, today.month, today.day + 1))
        ? context.l10n.liveTomorrow
        : DateFormat.E(locale).format(date);
    final format = date.year == now.year ? DateFormat.MMMd(locale) : DateFormat.yMMMd(locale);
    return context.l10n.liveAgendaDay(relative, format.format(date));
  }
}

class HomeScheduleRow extends ConsumerWidget {
  const HomeScheduleRow(this.item, {required this.joined, super.key});
  final LiveSchedule item;
  final bool joined;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n, s = context.spacing;
    final start = item.startAt.toLocal(),
        end = item.startAt.toLocal().add(Duration(minutes: item.durationMin));
    final time = MaterialLocalizations.of(context);
    final range = l.liveAgendaTime(
      time.formatTimeOfDay(TimeOfDay.fromDateTime(start), alwaysUse24HourFormat: true),
      time.formatTimeOfDay(TimeOfDay.fromDateTime(end), alwaysUse24HourFormat: true),
    );
    return Material(
      color: context.colors.surface,
      borderRadius: context.radius.mdAll,
      child: InkWell(
        key: ValueKey('home-schedule-${item.id}'),
        borderRadius: context.radius.mdAll,
        onTap: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (sheetContext) => SingleChildScrollView(
            padding: s.page,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text(l.liveSchedule),
                  trailing: IconButton(
                    tooltip: l.liveClose,
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(sheetContext),
                  ),
                ),
                ScheduleCard(item),
              ],
            ),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: s.sm, vertical: s.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    s.gapXs,
                    Wrap(
                      spacing: s.xs,
                      runSpacing: s.xxs,
                      children: [
                        Text(range, style: Theme.of(context).textTheme.bodySmall),
                        Text(
                          item.code.replaceAllMapped(RegExp(r'.{1,3}'), (m) => '${m[0]} ').trim(),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (item.activeRoomId != null)
                          Text(
                            l.liveAgendaOngoing,
                            style: TextStyle(
                              color: context.colors.primary,
                              fontSize: Theme.of(context).textTheme.bodySmall?.fontSize,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              s.gapXs,
              FilledButton(
                key: ValueKey('home-schedule-join-${item.id}'),
                onPressed: () => openScheduledMeeting(context, ref, item),
                child: Text(joined ? l.liveAgendaJoined : l.liveJoin),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void openScheduledMeeting(BuildContext context, WidgetRef ref, LiveSchedule item) {
  final session = ref.read(roomControllerProvider);
  if (session is RoomActive &&
      (session.room.id == item.activeRoomId || session.room.code == item.code)) {
    context.go(AppRoutes.liveRoom);
    return;
  }
  if (resumeMeeting(context, ref)) return;
  final auth = ref.read(sessionControllerProvider).value;
  final own = auth is AuthSignedIn && item.host['id'] == auth.user.id;
  unawaited(
    ref
        .read(roomControllerProvider.notifier)
        .join(item.code, scheduledId: own ? item.id : null, password: item.pwd),
  );
  context.push(AppRoutes.liveRoom);
}
