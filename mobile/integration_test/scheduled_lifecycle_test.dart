// Real production pages/controllers and PostgreSQL service. Only identity and
// media activation are explicit fixtures; no real IM/RTC/audio claim.
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:meeting/core/api/api_client.dart';
import 'package:meeting/core/api/models/auth_models.dart';
import 'package:meeting/core/auth/session_controller.dart';
import 'package:meeting/core/config/app_config_provider.dart';
import 'package:meeting/core/im/live_activity.dart';
import 'package:meeting/core/l10n/l10n.dart';
import 'package:meeting/core/router/app_router.dart';
import 'package:meeting/core/theme/app_theme.dart';
import 'package:meeting/core/update/update_controller.dart';
import 'package:meeting/features/live_meeting/domain/live_models.dart';
import 'package:meeting/features/live_meeting/presentation/home_page.dart';
import 'package:meeting/features/live_meeting/presentation/room_controller.dart';
import 'package:meeting/features/live_meeting/presentation/room_page.dart';
import 'package:meeting/features/live_meeting/presentation/schedule_sheet.dart';
import 'package:meeting/features/live_meeting/presentation/schedules_controller.dart';

import '../test/helpers/test_config.dart';

class ScheduledSession extends SessionController {
  @override
  Future<AuthState> build() async =>
      const AuthState.signedIn(User(id: 'scheduled-host', name: 'host'));
}

class ScheduledUpdate extends UpdateController {
  @override
  UpdateState build() => const UpdateState();
}

class ScheduledMedia extends RoomController {
  @override
  Future<void> activate(LiveRoom room, LiveParticipant self, Map<dynamic, dynamic>? media) async {
    ref.read(liveActivityProvider.notifier).set(true);
    state = LiveRoomState.active(
      room: room,
      self: self,
      media: 'unavailable',
      connection: 'connected',
    );
  }
}

Dio direct(String base) => Dio(BaseOptions(baseUrl: base, headers: {'X-Test-Actor': 'host'}))
  ..httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () => HttpClient()..findProxy = (_) => 'DIRECT',
  );
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('固定会议号跨端预定与重复场次', (t) async {
    final api = direct('http://127.0.0.1:3169'), bridge = direct('http://127.0.0.1:39349');
    final c = await createTestContainer(
      config: (await loadAppConfig()).copyWith(defaultServerUrl: 'http://127.0.0.1:3169'),
      prefs: {'settings.onboardingCompleted': true, 'settings.localeMode': 'zh'},
      overrides: [
        sessionControllerProvider.overrideWith(ScheduledSession.new),
        updateControllerProvider.overrideWith(ScheduledUpdate.new),
        apiClientProvider.overrideWithValue(api),
        roomControllerProvider.overrideWith(ScheduledMedia.new),
      ],
    );
    final l = lookupAppLocalizations(const Locale('zh'));
    await c.read(sessionControllerProvider.future);
    final router = c.read(appRouterProvider);
    router.go(AppRoutes.history);
    await t.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          routerConfig: router,
          theme: AppTheme.light(),
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: appSupportedLocales,
        ),
      ),
    );
    Future<void> settle() async {
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 150));
        await Future<void>.delayed(const Duration(milliseconds: 60));
      }
    }

    Future<void> until(bool Function() predicate) async {
      for (var i = 0; i < 60 && !predicate(); i++) {
        await t.pump(const Duration(milliseconds: 100));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      expect(predicate(), isTrue);
    }

    Future<void> tap(Finder f) async {
      await t.ensureVisible(f.last);
      await t.tap(f.last);
      await settle();
    }

    var index = 0;
    String phase = 'assertions';
    Future<void> step(
      String operation,
      String expected,
      Future<void> Function() fn,
      String shot,
    ) async {
      final row = <String, Object?>{
        'platform': 'Android emulator',
        'phase': phase,
        'operation': operation,
        'expected': expected,
        'actual': '',
        'pass': false,
        'screenshot': null,
      };
      try {
        await fn();
        final e = t.takeException();
        if (e != null) throw StateError('$e');
        row['actual'] = expected;
        row['pass'] = true;
        if (phase == 'screenshots') {
          final p = 'screenshots/android-${++index}-$shot.png';
          await bridge.post<void>('/shot', data: {'path': p});
          row['screenshot'] = p;
        }
      } catch (e) {
        row['pass'] = false;
        row['actual'] = '$e';
        rethrow;
      } finally {
        await bridge.post<void>('/row', data: row);
      }
    }

    await settle();
    for (phase in ['assertions', 'screenshots']) {
      router.go(AppRoutes.history);
      await settle();
      await tap(find.text(l.liveUpcomingTab));
      await until(() => find.byType(ScheduleCard).evaluate().isNotEmpty);
      final rows = (await api.get<List<dynamic>>('/api/v1/scheduled-meetings')).data!;
      var plan = Map<String, dynamic>.from(
        rows.cast<Map<String, dynamic>>().where((x) => x['cancelled'] == false).first,
      );
      final code = plan['code'] as String;
      await step(phase == 'assertions' ? '移动端读取桌面预定' : '移动端读取预定复验', '真实HTTP读取相同六位会议号', () async {
        expect(find.text(l.liveCodeValue(code)), findsOneWidget);
      }, 'shared-plan');
      await tap(find.text(l.liveEdit));
      await step('编辑失败保留输入', '503错误可见，可重试', () async {
        await api.post<void>('/__control', data: {'scheduleError': true});
        await t.enterText(
          find.descendant(of: find.byType(ScheduleSheet), matching: find.byType(TextField)).first,
          '移动端修改固定号会议',
        );
        await tap(find.text(l.liveSave));
        expect(find.textContaining('预定服务暂不可用'), findsWidgets);
      }, 'edit-error');
      await step('编辑成功且固定号不变', '移动端保存到同一服务，桌面可读取相同数据', () async {
        await api.post<void>('/__control', data: {'scheduleError': false});
        await tap(find.text(l.liveSave));
        await until(() => find.byType(ScheduleSheet).evaluate().isEmpty);
        plan = (await api.get<Map<String, dynamic>>('/api/v1/scheduled-meetings/${plan['id']}'))
            .data!;
        expect(plan['code'], code);
        expect(plan['title'], '移动端修改固定号会议');
      }, 'edited');
      final records = <String>[];
      for (var cycle = 0; cycle < 2; cycle++) {
        await step('移动端提前进入第${cycle + 1}场', '生产加入按钮与控制器创建活动场次', () async {
          await tap(find.text(l.liveJoin));
          await until(() => c.read(roomControllerProvider) is RoomActive);
          expect(find.byType(LiveRoomPage), findsOneWidget);
          expect((c.read(roomControllerProvider) as RoomActive).room.code, code);
        }, 'scene-${cycle + 1}');
        if (cycle == 0) {
          await step('结束失败保持会中', '503后会中不退出、显示可重试错误', () async {
            await api.post<void>('/__control', data: {'endError': true});
            await tap(find.text(l.liveEnd));
            await tap(find.text(l.liveConfirm));
            expect(c.read(roomControllerProvider), isA<RoomActive>());
            expect(find.textContaining('结束会议暂不可用'), findsWidgets);
            await api.post<void>('/__control', data: {'endError': false});
          }, 'end-error');
        }
        await step('结束第${cycle + 1}场生成记录', '生产确认结束返回首页，预定仍可进入/编辑/取消', () async {
          await tap(find.text(l.liveEnd));
          await tap(find.text(l.liveConfirm));
          await until(() => c.read(roomControllerProvider) is RoomEnded);
          records.add((c.read(roomControllerProvider) as RoomEnded).meetingId!);
          expect(find.byType(LiveHomePage), findsOneWidget);
          router.go(AppRoutes.history);
          await settle();
          await tap(find.text(l.liveUpcomingTab));
          c.invalidate(upcomingSchedulesProvider);
          await settle();
          expect(find.byType(ScheduleCard), findsOneWidget);
          expect(find.text(l.liveEdit), findsOneWidget);
        }, 'ended-${cycle + 1}');
      }
      expect(records.toSet().length, 2);
      await step('取消失败后重试', '错误不移除预定；重试取消后保留两份记录', () async {
        await api.post<void>('/__control', data: {'cancelError': true});
        await tap(find.text(l.liveCancelSchedule));
        await tap(find.text(l.liveConfirm));
        expect(find.byType(ScheduleCard), findsOneWidget);
        await api.post<void>('/__control', data: {'cancelError': false});
        await tap(find.text(l.liveCancelSchedule));
        await tap(find.text(l.liveConfirm));
        await until(() => find.byType(ScheduleCard).evaluate().isEmpty);
        for (final id in records) {
          expect((await api.get<dynamic>('/api/v1/meetings/$id/metadata')).statusCode, 200);
        }
      }, 'cancelled');
      if (phase == 'assertions') {
        await tap(find.widgetWithText(FilledButton, l.liveSchedule));
        await until(() => find.byType(ScheduleSheet).evaluate().isNotEmpty);
        await t.enterText(
          find.descendant(of: find.byType(ScheduleSheet), matching: find.byType(TextField)).first,
          '移动端创建供截图复验',
        );
        await tap(find.text(l.liveSave));
        await until(() => find.byType(ScheduleSheet).evaluate().isEmpty);
      }
    }
    await t.pumpWidget(const SizedBox.shrink());
    await bridge.post<void>('/done');
    api.close();
    bridge.close();
  }, timeout: const Timeout(Duration(minutes: 10)));
}
