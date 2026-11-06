import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/session_controller.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/context_extensions.dart';
import '../../../core/widgets/app_switch_list_tile.dart';
import '../domain/live_models.dart';
import 'home_dashboard.dart';
import 'live_feedback.dart';
import 'room_controller.dart';
import 'schedule_sheet.dart';
import 'schedules_controller.dart';

export 'home_dashboard.dart' show LiveHomePage;

class MobileShell extends ConsumerWidget {
  const MobileShell({required this.child, required this.location, super.key});
  final Widget child;
  final String location;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(roomControllerProvider);
    final ongoing = session is RoomActive || session is RoomWaiting || session is RoomJoining;
    final title = switch (session) {
      RoomActive(:final room) || RoomWaiting(:final room) => room.title,
      _ => context.l10n.liveJoining,
    };
    return Scaffold(
      body: child,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (ongoing)
            Card(
              margin: EdgeInsets.symmetric(
                horizontal: context.spacing.md,
                vertical: context.spacing.xs,
              ),
              child: ListTile(
                leading: Icon(Icons.videocam_outlined, color: context.colors.primary),
                title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  switch (session) {
                    RoomJoining() => context.l10n.liveJoining,
                    RoomWaiting() => context.l10n.liveWaiting,
                    RoomActive(:final connection) when connection != 'connected' =>
                      context.l10n.liveReconnecting,
                    _ => context.l10n.liveSessionOngoing,
                  },
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: TextButton(
                  key: const ValueKey('return-live-meeting'),
                  onPressed: () => context.go(AppRoutes.liveRoom),
                  child: Text(context.l10n.liveReturnMeeting),
                ),
                onTap: () => context.go(AppRoutes.liveRoom),
              ),
            ),
          NavigationBar(
            selectedIndex: location == AppRoutes.history
                ? 1
                : location == AppRoutes.settings
                ? 2
                : 0,
            onDestinationSelected: (index) =>
                context.go([AppRoutes.meetings, AppRoutes.history, AppRoutes.settings][index]),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                label: context.l10n.liveHome,
              ),
              NavigationDestination(
                icon: const Icon(Icons.video_library_outlined),
                label: context.l10n.liveHistory,
              ),
              NavigationDestination(
                icon: const Icon(Icons.person_outline),
                label: context.l10n.liveMine,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

bool resumeMeeting(BuildContext context, WidgetRef ref) {
  final session = ref.read(roomControllerProvider);
  if (session is! RoomActive && session is! RoomWaiting && session is! RoomJoining) return false;
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(context.l10n.liveRoomConflict)));
  context.go(AppRoutes.liveRoom);
  return true;
}

class ScheduleCard extends ConsumerWidget {
  const ScheduleCard(this.item, {super.key});
  final LiveSchedule item;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n, auth = ref.watch(sessionControllerProvider).value;
    final own = auth is AuthSignedIn && item.host['id'] == auth.user.id;
    return Card(
      child: Padding(
        padding: context.spacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.title, style: Theme.of(context).textTheme.titleMedium),
            context.spacing.gapXs,
            Text(
              '${MaterialLocalizations.of(context).formatMediumDate(item.startAt.toLocal())} ${TimeOfDay.fromDateTime(item.startAt.toLocal()).format(context)}',
            ),
            Text(l.liveCodeValue(item.code)),
            if (item.activeRoomId != null) Text(l.liveScheduleActive),
            Text(l.liveScheduleHost(item.host['name']?.toString() ?? '')),
            Wrap(
              spacing: context.spacing.xs,
              children: [
                TextButton(
                  onPressed: () {
                    openScheduledMeeting(context, ref, item);
                  },
                  child: Text(l.liveJoin),
                ),
                if (own && item.activeRoomId == null) ...[
                  TextButton(
                    onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      builder: (_) => ScheduleSheet(item: item),
                    ),
                    child: Text(l.liveEdit),
                  ),
                  TextButton(
                    onPressed: () async {
                      final yes = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(l.liveCancelSchedule),
                          content: Text(item.title),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(l.liveBack),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text(l.liveConfirm),
                            ),
                          ],
                        ),
                      );
                      if (yes != true) return;
                      try {
                        await ref.read(liveSchedulesProvider.notifier).cancel(item.id);
                      } on Object catch (error) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(describeLiveError(context, error))),
                          );
                        }
                      }
                    },
                    child: Text(l.liveCancelSchedule),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class JoinSheet extends ConsumerStatefulWidget {
  const JoinSheet({super.key});
  @override
  ConsumerState<JoinSheet> createState() => _JoinSheetState();
}

class _JoinSheetState extends ConsumerState<JoinSheet> {
  final code = TextEditingController(), password = TextEditingController();
  bool mic = false, cam = false;
  String? error;
  @override
  void dispose() {
    code.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: context.spacing.page.add(
        EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.liveJoin, style: Theme.of(context).textTheme.titleLarge),
            context.spacing.gapLg,
            TextField(
              controller: code,
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(labelText: l.liveCode, hintText: l.liveCodeHint),
            ),
            context.spacing.gapSm,
            TextField(
              controller: password,
              obscureText: true,
              maxLength: 6,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l.livePassword,
                hintText: l.livePasswordOptional,
              ),
            ),
            AppSwitchListTile(
              title: Text(l.liveMic),
              value: mic,
              onChanged: (value) => setState(() => mic = value),
            ),
            AppSwitchListTile(
              title: Text(l.liveCamera),
              value: cam,
              onChanged: (value) => setState(() => cam = value),
            ),
            Text(l.liveJoinNotice, style: TextStyle(color: context.colors.mutedForeground)),
            if (error != null) LiveError(error!),
            context.spacing.gapLg,
            FilledButton(
              onPressed: () {
                if (!RegExp(r'^[0-9]{6}$').hasMatch(code.text)) {
                  setState(() => error = l.liveCodeHint);
                  return;
                }
                final router = GoRouter.of(context);
                unawaited(
                  ref
                      .read(roomControllerProvider.notifier)
                      .join(
                        code.text,
                        password: password.text.isEmpty ? null : password.text,
                        mic: mic,
                        cam: cam,
                      ),
                );
                Navigator.pop(context);
                router.push(AppRoutes.liveRoom);
              },
              child: Text(l.liveJoin),
            ),
          ],
        ),
      ),
    );
  }
}
