// Production home/room/history pages and router; deterministic business fixture.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meeting/core/api/models/auth_models.dart';
import 'package:meeting/core/api/models/meeting_models.dart';
import 'package:meeting/core/auth/session_controller.dart';
import 'package:meeting/core/config/app_config_provider.dart';
import 'package:meeting/core/im/live_activity.dart';
import 'package:meeting/core/l10n/l10n.dart';
import 'package:meeting/core/router/app_router.dart';
import 'package:meeting/core/router/notice_presentation.dart';
import 'package:meeting/core/theme/app_theme.dart';
import 'package:meeting/core/update/update_controller.dart';
import 'package:meeting/features/live_meeting/data/live_repository_impl.dart';
import 'package:meeting/features/live_meeting/domain/live_models.dart';
import 'package:meeting/features/live_meeting/domain/live_repository.dart';
import 'package:meeting/features/live_meeting/presentation/home_page.dart';
import 'package:meeting/features/live_meeting/presentation/room_controller.dart';
import 'package:meeting/features/live_meeting/presentation/room_page.dart';
import 'package:meeting/features/meetings/presentation/meetings_list_controller.dart';
import 'package:meeting/features/meetings/presentation/meetings_list_page.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/test_config.dart';

class HistoryRepo extends Mock implements LiveRepository {}

class HistorySession extends SessionController {
  @override
  Future<AuthState> build() async => const AuthState.signedIn(User(id: 'nav-host', name: '导航测试'));
}

class HistoryUpdate extends UpdateController {
  @override
  UpdateState build() => const UpdateState();
}

class HistoryList extends MeetingsListController {
  @override
  Future<List<MeetingSummary>> build() async => [];
}

class HistoryRoom extends RoomController {
  @override
  LiveRoomState build() => const LiveRoomState.idle();
  @override
  Future<void> join(
    String code, {
    String? password,
    bool mic = false,
    bool cam = false,
    String? scheduledId,
    bool create = false,
    String? title,
  }) async {
    const self = LiveParticipant(
      id: 'self',
      userId: 'nav-host',
      name: '导航测试',
      isSelf: true,
      isHost: true,
    );
    const room = LiveRoom(
      id: 'nav-room',
      code: '123456',
      title: '结束后打开会议记录',
      hostId: 'self',
      participants: [self],
    );
    ref.read(liveActivityProvider.notifier).set(true);
    state = const LiveRoomState.active(
      room: room,
      self: self,
      // Navigation is under test; this explicit media fixture represents an
      // initialized meeting so the production entry gate exposes the toolbar.
      media: 'connected',
      connection: 'connected',
    );
  }
}

Future<void> runMeetingHistoryFlow(
  WidgetTester t, {
  required Future<void> Function(Map<String, Object?>) emit,
  Future<void> Function(String, GlobalKey)? screenshot,
  bool native = false,
  bool capture = false,
}) async {
  final sizes = native
      ? [t.view.physicalSize / t.view.devicePixelRatio]
      : [const Size(390, 844), const Size(1024, 768)];
  var imageNumber = 0;
  final l = lookupAppLocalizations(const Locale('zh'));
  for (final size in sizes) {
    await t.binding.setSurfaceSize(size);
    final repo = HistoryRepo();
    var rejectEnd = false;
    when(() => repo.end(any())).thenAnswer((_) async {
      if (rejectEnd) throw StateError('fixture end unavailable');
      return 'nav-record';
    });
    when(() => repo.schedules(any(), any())).thenAnswer((_) async => []);
    final c = await createTestContainer(
      config: native ? await loadAppConfig() : loadConfigFile('dev'),
      prefs: {'settings.onboardingCompleted': true, 'settings.localeMode': 'zh'},
      overrides: [
        sessionControllerProvider.overrideWith(HistorySession.new),
        updateControllerProvider.overrideWith(HistoryUpdate.new),
        liveRepositoryProvider.overrideWithValue(repo),
        roomControllerProvider.overrideWith(HistoryRoom.new),
        meetingsListControllerProvider.overrideWith(HistoryList.new),
      ],
    );
    final boundary = GlobalKey();
    final captured = <String>{};
    Future<void> step(
      String operation,
      String expected,
      Future<void> Function() run,
      String state,
    ) async {
      final row = <String, Object?>{
        'platform': native ? 'android' : 'flutter-headless',
        'phase': capture ? 'screenshots' : 'assertions',
        'viewport': '${size.width.toInt()}x${size.height.toInt()}',
        'operation': operation,
        'expected': expected,
        'actual': '',
        'pass': false,
        'screenshot': null,
      };
      try {
        await run();
        final error = t.takeException();
        if (error != null) throw StateError('$error');
        row['actual'] = expected;
        row['pass'] = true;
        if (capture && screenshot != null && state != 'fixture-smoke' && captured.add(state)) {
          final name = 'screenshots/android-${++imageNumber}-${size.width.toInt()}-$state.png';
          await screenshot(name, boundary);
          row['screenshot'] = name;
        }
      } catch (error) {
        row['actual'] = '$error';
        row['pass'] = false;
        rethrow;
      } finally {
        await emit(row);
      }
    }

    Future<void> tap(Finder finder) async {
      await t.ensureVisible(finder.last);
      await t.tap(finder.last);
      await t.pumpAndSettle();
    }

    try {
      await t.runAsync(() => c.read(sessionControllerProvider.future));
      final router = c.read(appRouterProvider);
      router.go(AppRoutes.meetings);
      await t.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: RepaintBoundary(
            key: boundary,
            child: MaterialApp.router(
              debugShowCheckedModeBanner: false,
              routerConfig: router,
              theme: AppTheme.light(),
              locale: const Locale('zh'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: appSupportedLocales,
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      await step('失败入口独立冒烟', '结束故障可确定触发，解除后返回记录标识', () async {
        rejectEnd = true;
        await expectLater(repo.end('nav-room'), throwsStateError);
        await expectLater(repo.end('nav-room'), throwsStateError);
        rejectEnd = false;
        expect(await repo.end('nav-room'), 'nav-record');
      }, 'fixture-smoke');
      for (var cycle = 0; cycle < 2; cycle++) {
        await step('从首页发起会议 ${cycle + 1}', '从真实首页点击快速会议，通过 push 进入会中', () async {
          expect(find.byType(LiveHomePage), findsOneWidget);
          await tap(find.byKey(const ValueKey('live-quick')));
          expect(find.byType(LiveRoomPage), findsOneWidget);
        }, 'room');
        if (cycle == 1) {
          await step('结束失败保留会中', '失败文案可见，会议和原有导航栈保持，允许重试', () async {
            rejectEnd = true;
            await tap(find.text(l.liveEnd));
            await tap(find.text(l.liveConfirm));
            expect(find.textContaining('fixture end unavailable'), findsWidgets);
            expect(find.byType(LiveRoomPage), findsOneWidget);
            rejectEnd = false;
          }, 'end-error');
        }
        await step('确认结束并返回首页 ${cycle + 1}', '关闭结束确认弹窗，回到首页，无中转页或框架异常', () async {
          await tap(find.text(l.liveEnd));
          await tap(find.text(l.liveConfirm));
          await t.pump(const Duration(milliseconds: 500));
          await t.pumpAndSettle();
          expect(router.routeInformationProvider.value.uri.path, AppRoutes.meetings);
          expect(find.byType(LiveRoomPage), findsNothing);
          expect(find.byType(LiveHomePage), findsOneWidget);
        }, 'home');
        await step('结束后打开会议记录 ${cycle + 1}', '点击底部会议，真实历史页面和空态可见，无观察器重复绑定', () async {
          await tap(
            find.descendant(of: find.byType(NavigationBar), matching: find.text(l.liveHistory)),
          );
          expect(find.byType(MeetingsListPage), findsOneWidget);
          expect(find.text(l.meetingsEmpty), findsOneWidget);
        }, 'history');
        await step('记录页弹层打开关闭 ${cycle + 1}', '嵌套导航的弹窗阻止通知，关闭后恢复通知策略', () async {
          final context = t.element(find.byType(MeetingsListPage));
          unawaited(
            showDialog<void>(
              context: context,
              useRootNavigator: false,
              builder: (dialog) => AlertDialog(
                title: const Text('导航回归弹窗'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(dialog), child: Text(l.liveConfirm)),
                ],
              ),
            ),
          );
          await t.pumpAndSettle();
          expect(c.read(noticePresentationProvider).canShow, isFalse);
          if (capture && screenshot != null && cycle == 0) {
            await screenshot(
              'screenshots/android-${++imageNumber}-${size.width.toInt()}-history-dialog-open.png',
              boundary,
            );
          }
          await tap(find.text(l.liveConfirm));
          expect(c.read(noticePresentationProvider).canShow, isTrue);
        }, 'history-dialog-closed');
        await step('从记录切换回首页 ${cycle + 1}', '底部首页可正常切换，下一轮能够继续发起会议', () async {
          await tap(
            find.descendant(of: find.byType(NavigationBar), matching: find.text(l.liveHome)),
          );
          expect(find.byType(LiveHomePage), findsOneWidget);
        }, 'home-restored');
      }
    } finally {
      await t.pumpWidget(const SizedBox.shrink());
      c.dispose();
      await t.pump();
    }
  }
}

void main() {
  testWidgets('start end then history preserves navigator ownership', (t) async {
    registerFallbackValue(DateTime(2026));
    final out = Directory(
      Platform.environment['MEETING_HISTORY_OUTPUT'] ?? '../.artifacts/mobile-meeting-history',
    );
    out.createSync(recursive: true);
    final budget = File('${out.path}/budget.json');
    if (budget.existsSync()) {
      final b = jsonDecode(budget.readAsStringSync().replaceFirst('\uFEFF', '')) as Map;
      if (DateTime.now().millisecondsSinceEpoch - (b['started'] as num) > (b['limitMs'] as num)) {
        throw StateError('Cumulative E2E budget exhausted');
      }
    }
    final rows = <Map<String, Object?>>[];
    await t.runAsync(() async {
      await (FontLoader('Roboto')..addFont(
            Future.value(
              ByteData.sublistView(await File('C:/Windows/Fonts/msyh.ttc').readAsBytes()),
            ),
          ))
          .load();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    });
    Future<void> emit(Map<String, Object?> row) async {
      rows.add(row);
      File('${out.path}/vm-results.json').writeAsStringSync(jsonEncode(rows));
      stdout.writeln(jsonEncode(row));
    }

    Future<void> shot(String name, GlobalKey key) async {
      await t.runAsync(() async {
        final image = await (key.currentContext!.findRenderObject()! as RenderRepaintBoundary)
            .toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('${out.path}/$name');
        file.parent.createSync(recursive: true);
        file.writeAsBytesSync(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    await runMeetingHistoryFlow(t, emit: emit);
    if (Platform.environment['MEETING_HISTORY_CAPTURE'] == '1') {
      await runMeetingHistoryFlow(t, emit: emit, screenshot: shot, capture: true);
    }
  });
}
