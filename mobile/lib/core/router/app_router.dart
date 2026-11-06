import 'package:deeprespond_im/deeprespond_im.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/presentation/login_page.dart';
import '../../features/import/presentation/import_page.dart';
import '../../features/live_meeting/domain/live_models.dart';
import '../../features/live_meeting/presentation/home_page.dart';
import '../../features/live_meeting/presentation/room_controller.dart';
import '../../features/live_meeting/presentation/room_page.dart';
import '../../features/live_meeting/presentation/upcoming_meetings.dart';
import '../../features/meetings/presentation/meeting_detail_page.dart';
import '../../features/meetings/presentation/meetings_list_page.dart';
import '../../features/messaging/presentation/messages_page.dart';
import '../../features/messaging/presentation/social_pages.dart';
import '../../features/onboarding/presentation/onboarding_page.dart';
import '../../features/recording/presentation/recording_page.dart';
import '../../features/recording/presentation/recording_tools_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../features/update/presentation/force_update_page.dart';
import '../auth/session_controller.dart';
import '../config/settings_controller.dart';
import '../heartbeat/recording_status.dart';
import '../im/live_activity.dart';
import '../update/update_controller.dart';
import '../widgets/splash_page.dart';
import 'app_routes.dart';
import 'notice_presentation.dart';
import 'route_guard.dart';

export 'app_routes.dart';

part 'app_router.g.dart';

/// The app's [GoRouter]. Created once; re-evaluates [guardRedirect] whenever the session
/// status or the onboarding flag changes (via `refreshListenable`), so navigation state
/// survives those changes.
///
/// Feature agents: replace the placeholder pages in `features/*/presentation/`, keep the
/// class names (or update the imports here). Add sub-routes as children of the matching route.
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  late final GoRouter router;
  final refresh = ValueNotifier<int>(0);
  ref.onDispose(refresh.dispose);

  void bump() => refresh.value++;
  ref.listen(sessionControllerProvider.select(sessionStatusOf), (_, _) => bump());
  ref.listen(effectiveSettingsProvider.select((s) => s.onboardingCompleted), (_, _) => bump());
  // A forced update blocks the app — but never interrupts a recording.
  bool updateRequired() =>
      ref.read(updateControllerProvider).required &&
      !ref.read(recordingStatusControllerProvider).recording &&
      !ref.read(liveActivityProvider);
  ref.listen(updateControllerProvider.select((s) => s.required), (_, _) => bump());
  ref.listen(recordingStatusControllerProvider.select((s) => s.recording), (_, _) => bump());
  ref.listen(liveActivityProvider, (_, _) => bump());
  ref.listen(roomControllerProvider.select((s) => s is RoomEnded), (_, ended) {
    if (ended &&
        router.routerDelegate.currentConfiguration.lastOrNull?.matchedLocation ==
            AppRoutes.liveRoom) {
      // The room is pushed above the shell. Refreshing its redirect would turn
      // that pushed page into another shell, reusing the shell's observers on a
      // second Navigator. Replace the stack when the active room ends instead.
      router.go(AppRoutes.meetings);
    } else {
      bump();
    }
  });

  router = GoRouter(
    observers: [NoticeNavigatorObserver(ref.read(noticePresentationProvider))],
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    debugLogDiagnostics: kDebugMode,
    redirect: (context, state) => guardRedirect(
      location: state.matchedLocation,
      session: sessionStatusOf(ref.read(sessionControllerProvider)),
      onboardingCompleted: ref.read(effectiveSettingsProvider).onboardingCompleted,
      updateRequired: updateRequired(),
      roomEnded: ref.read(roomControllerProvider) is RoomEnded,
    ),
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashPage()),
      GoRoute(path: AppRoutes.onboarding, builder: (_, _) => const OnboardingPage()),
      GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginPage()),
      ShellRoute(
        observers: [NoticeNavigatorObserver(ref.read(noticePresentationProvider))],
        builder: (context, state, child) => MobileShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: AppRoutes.meetings,
            builder: (_, _) => const LiveHomePage(),
            routes: [
              GoRoute(
                path: AppRoutes.meetingDetailPattern,
                builder: (_, state) =>
                    MeetingDetailPage(meetingId: state.pathParameters[AppRoutes.meetingIdParam]!),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.history,
            builder: (_, _) => const MeetingsListPage(upcoming: UpcomingMeetings()),
          ),
          GoRoute(path: AppRoutes.settings, builder: (_, _) => const SettingsPage()),
        ],
      ),
      GoRoute(path: AppRoutes.liveRoom, builder: (_, _) => const LiveRoomPage()),
      GoRoute(path: AppRoutes.messages, builder: (_, _) => const MessagesPage()),
      GoRoute(
        path: AppRoutes.messageChat,
        builder: (_, state) => ConversationChatPage(
          conversationKey: state.uri.queryParameters['key'] ?? '',
          initial: state.extra is ConversationView ? state.extra as ConversationView : null,
        ),
      ),
      GoRoute(
        path: AppRoutes.imGroup,
        builder: (_, state) => GroupDetailPage(groupId: state.uri.queryParameters['id'] ?? ''),
      ),
      GoRoute(path: AppRoutes.recording, builder: (_, _) => const RecordingPage()),
      GoRoute(path: AppRoutes.recordingTools, builder: (_, _) => const RecordingToolsPage()),
      GoRoute(path: AppRoutes.import, builder: (_, _) => const ImportPage()),
      GoRoute(path: AppRoutes.forceUpdate, builder: (_, _) => const ForceUpdatePage()),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
}
