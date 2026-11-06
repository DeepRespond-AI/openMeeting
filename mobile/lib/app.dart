import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/api/meeting_recording.dart';
import 'core/auth/session_controller.dart';
import 'core/config/app_config_provider.dart';
import 'core/config/settings_controller.dart';
import 'core/data/background_work.dart';
import 'core/data/meetings_changed.dart';
import 'core/heartbeat/heartbeat_controller.dart';
import 'core/im/live_activity.dart';
import 'core/im/meeting_record_notices.dart';
import 'core/l10n/l10n.dart';
import 'core/router/app_router.dart';
import 'core/router/notice_presentation.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/context_extensions.dart';
import 'core/update/update_controller.dart';
import 'features/live_meeting/presentation/reminder_controller.dart';
import 'features/live_meeting/presentation/room_controller.dart';
import 'features/meetings/presentation/meeting_detail_controller.dart';
import 'features/recording/presentation/recording_controller.dart';
import 'features/summary/presentation/summary_controller.dart';
import 'features/update/presentation/update_dialog.dart';

/// Root widget: router, theme and locale all come from providers.
class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> with WidgetsBindingObserver {
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  NoticePresentation? _noticePresentation;
  bool _foreground = true;

  void _clearNotices() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _messengerKey.currentState?.clearSnackBars();
      _messengerKey.currentState?.removeCurrentSnackBar();
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _noticePresentation?.onNavigation = null;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (state == AppLifecycleState.resumed) ref.read(meetingsChangedProvider.notifier).bump();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    ref.watch(roomChatLifecycleProvider);
    final localeMode = ref.watch(localeModeProvider);
    _noticePresentation = ref.watch(noticePresentationProvider);
    _noticePresentation!.onNavigation = _clearNotices;
    ref.listen(liveActivityProvider, (_, active) {
      if (active) _clearNotices();
    });
    ref.listen(meetingRecordNoticesProvider, (_, next) {
      final notice = next.asData?.value;
      if (notice == null) return;
      ref.invalidate(meetingDetailControllerProvider(notice.meetingId));
      ref.invalidate(transcriptsControllerProvider(notice.meetingId));
      ref.invalidate(meetingRecordingProvider(notice.meetingId));
      ref.invalidate(summaryControllerProvider(notice.meetingId));
      final context = _messengerKey.currentContext;
      if (context == null ||
          !_foreground ||
          ref.read(liveActivityProvider) ||
          !_noticePresentation!.canShow) {
        return;
      }
      final l = AppLocalizations.of(context);
      _messengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(switch (notice.event) {
            'meeting_ended' => l.liveRecordEndedNotice,
            'processing_completed' => l.liveRecordCompletedNotice,
            _ => l.liveRecordFailedNotice,
          }),
          duration: ref.read(appConfigProvider).ui.snackBarDuration,
          action: SnackBarAction(
            label: l.liveViewRecord,
            onPressed: () => router.push(AppRoutes.meetingDetail(notice.meetingId)),
          ),
        ),
      );
    });

    // Keeps the heartbeat alive for the app's lifetime without rebuilding on each beat.
    ref.listen(heartbeatControllerProvider, (_, _) {});
    ref.listen(liveReminderProvider, (_, meeting) {
      final context = _messengerKey.currentContext;
      if (meeting == null || context == null) return;
      _messengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).liveReminderSoon(meeting.title)),
          duration: ref.read(appConfigProvider).ui.snackBarDuration,
        ),
      );
    });

    // Session expired (401) → SnackBar; the router redirects to /login by itself.
    ref.listen(sessionControllerProvider, (previous, next) {
      final before = previous?.value;
      final after = next.value;
      if ((before is AuthSignedIn ? before.user.id : null) !=
          (after is AuthSignedIn ? after.user.id : null)) {
        _clearNotices();
      }
      if (previous?.value is AuthSignedIn && next.value is AuthExpired) {
        final messenger = _messengerKey.currentState;
        final messengerContext = _messengerKey.currentContext;
        if (messenger == null || messengerContext == null) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(messengerContext).authSessionExpired),
            duration: ref.read(appConfigProvider).ui.snackBarDuration,
          ),
        );
      }
    });

    // A newly offered optional update → dialog (once per version within the cooldown).
    // Forced updates are handled by the route guard (force-update page).
    ref.listen(updateControllerProvider.select((s) => s.offer), (previous, offer) {
      if (offer == null || offer.force || offer == previous) return;
      final updates = ref.read(updateControllerProvider.notifier);
      final navigatorContext = router.routerDelegate.navigatorKey.currentContext;
      if (navigatorContext == null || !updates.shouldPrompt(offer)) return;
      unawaited(updates.markPrompted(offer));
      unawaited(showUpdateDialog(navigatorContext));
    });

    // Outcomes of background work (import transcription, recording upload), on any page.
    ref.listen(backgroundNoticesProvider, (_, notice) {
      final messenger = _messengerKey.currentState;
      final messengerContext = _messengerKey.currentContext;
      if (notice == null || messenger == null || messengerContext == null) return;
      final l10n = AppLocalizations.of(messengerContext);
      final colors = messengerContext.colors;
      final (text, error, action) = switch (notice) {
        ImportTranscribedNotice(:final title, :final segments) => (
          l10n.importTranscribed(title, segments),
          false,
          null,
        ),
        ImportFailedNotice(:final title, :final message) => (
          message == null
              ? l10n.importTranscribeLost(title)
              : l10n.importTranscribeFailed(title, message),
          true,
          null,
        ),
        RecordingUploadFailedNotice(:final meetingId) => (
          l10n.recordingErrorUploadTitle,
          true,
          SnackBarAction(
            label: l10n.recordingRetryUpload,
            textColor: colors.onDestructive,
            onPressed: () =>
                ref.read(recordingControllerProvider.notifier).retryUpload(meetingId).ignore(),
          ),
        ),
      };
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(text),
            action: action,
            backgroundColor: error ? colors.destructive : null,
            duration: ref.read(appConfigProvider).ui.snackBarDuration,
          ),
        );
    });

    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: _messengerKey,
      routerConfig: router,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      // The desktop app is light-only; keep the brand look until a dark mode setting exists.
      themeMode: ThemeMode.light,
      locale: localeForMode(localeMode),
      supportedLocales: appSupportedLocales,
      localizationsDelegates: localizationsDelegates,
      localeListResolutionCallback: (deviceLocales, _) => resolveSystemLocale(deviceLocales),
    );
  }
}
