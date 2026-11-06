// Real pages/router/controllers; deterministic identity, business and media boundaries.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meeting/core/api/api_exception.dart';
import 'package:meeting/core/auth/session_controller.dart';
import 'package:meeting/core/config/app_config_provider.dart';
import 'package:meeting/core/config/app_enums.dart';
import 'package:meeting/core/im/live_activity.dart';
import 'package:meeting/core/l10n/l10n.dart';
import 'package:meeting/core/router/app_router.dart';
import 'package:meeting/core/theme/app_theme.dart';
import 'package:meeting/core/update/update_controller.dart';
import 'package:meeting/features/import/presentation/import_page.dart';
import 'package:meeting/features/live_meeting/data/live_repository_impl.dart';
import 'package:meeting/features/live_meeting/domain/live_models.dart';
import 'package:meeting/features/live_meeting/presentation/home_dashboard.dart';
import 'package:meeting/features/live_meeting/presentation/meeting_gallery.dart';
import 'package:meeting/features/live_meeting/presentation/room_controller.dart';
import 'package:meeting/features/live_meeting/presentation/room_page.dart';
import 'package:meeting/features/live_meeting/presentation/schedule_sheet.dart';
import 'package:meeting/features/live_meeting/presentation/schedules_controller.dart';
import 'package:meeting/features/recording/data/audio_sources.dart';
import 'package:meeting/features/recording/domain/audio_source.dart';
import 'package:meeting/features/recording/domain/recording_state.dart';
import 'package:meeting/features/recording/presentation/recording_controller.dart';
import 'package:meeting/features/recording/presentation/recording_page.dart';
import 'package:meeting/features/recording/presentation/recording_tools_page.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/test_config.dart';
import 'meeting_history_navigation_test.dart' show HistoryRepo, HistorySession, HistoryUpdate;

class DashboardRecording extends RecordingController {
  @override
  RecordingState build() => const RecordingState.idle();
}

class DashboardRoom extends RoomController {
  int _joins = 0;
  int joinCount() => _joins;
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
    _joins++;
    const self = LiveParticipant(
      id: 'self',
      userId: 'nav-host',
      name: '房主',
      isSelf: true,
      isHost: true,
    );
    final room = LiveRoom(
      id: 'grid-room',
      code: code.isEmpty ? '123456789' : code,
      title: title ?? '移动会议自适应网格',
      hostId: 'self',
      participants: [self],
    );
    ref.read(liveActivityProvider.notifier).set(true);
    state = LiveRoomState.active(
      room: room,
      self: self,
      media: 'connected',
      connection: 'connected',
    );
    members(3);
  }

  void members(int count) {
    final current = state as RoomActive;
    state = current.copyWith(
      room: current.room.copyWith(
        participants: [
          current.self,
          for (var i = 1; i < count; i++)
            LiveParticipant(
              id: 'p$i',
              userId: 'user$i',
              name: '参会成员 $i 很长的昵称用于检查布局',
              micOn: i == 1,
            ),
        ],
      ),
    );
  }
}

Future<void> runHomeGridFlow(
  WidgetTester t, {
  required Future<void> Function(Map<String, Object?>) emit,
  Future<void> Function(String, GlobalKey)? screenshot,
  bool native = false,
  bool capture = false,
}) async {
  final sizes = native
      ? [t.view.physicalSize / t.view.devicePixelRatio]
      : [const Size(390, 844), const Size(1024, 768)];
  final l = lookupAppLocalizations(const Locale('zh'));
  var imageNumber = 0;
  for (final size in sizes) {
    await t.binding.setSurfaceSize(size);
    final now = DateTime.now(), repo = HistoryRepo();
    final pending = Completer<List<LiveSchedule>>();
    var mode = 'loading', rejectSave = false;
    var records = [
      LiveSchedule(
        id: 'active',
        code: '677793692',
        title: '昨天仍在进行的会议',
        startAt: now.subtract(const Duration(days: 1)),
        durationMin: 30,
        activeRoomId: 'active-room',
        host: {'id': 'nav-host', 'name': '房主'},
      ),
      LiveSchedule(
        id: 'today',
        code: '862243154',
        title: '今天预定会议',
        startAt: now.add(const Duration(minutes: 10)),
        durationMin: 30,
        host: {'id': 'nav-host', 'name': '房主'},
      ),
      LiveSchedule(
        id: 'tomorrow',
        code: '123456789',
        title: '明天的产品评审 · 很长的会议主题验证换行与详情完整查看',
        startAt: now.add(const Duration(days: 1)),
        durationMin: 30,
        host: {'id': 'nav-host', 'name': '房主'},
      ),
      LiveSchedule(
        id: 'cancelled',
        code: '999999999',
        title: '已取消不可显示',
        startAt: now.add(const Duration(days: 1)),
        durationMin: 30,
        cancelled: true,
      ),
      LiveSchedule(
        id: 'expired',
        code: '888888888',
        title: '过期不可显示',
        startAt: now.subtract(const Duration(days: 1)),
        durationMin: 30,
      ),
    ];
    when(() => repo.schedules(any(), any())).thenAnswer((_) async {
      if (mode == 'loading') return pending.future;
      if (mode == 'error') throw const ApiException(kind: ApiErrorKind.unavailable);
      return records;
    });
    when(() => repo.end(any())).thenAnswer((_) async => 'record');
    when(() => repo.saveSchedule(any(), id: any(named: 'id'))).thenAnswer((call) async {
      if (rejectSave) throw const ApiException(kind: ApiErrorKind.unavailable);
      final values = call.positionalArguments.first as Map<String, Object?>;
      final created = LiveSchedule(
        id: 'created',
        code: '123456789',
        title: values['title']! as String,
        startAt: DateTime.parse(values['startAt']! as String),
        durationMin: values['durationMin']! as int,
        host: {'id': 'nav-host', 'name': '房主'},
      );
      records = [...records, created];
      return created;
    });
    final c = await createTestContainer(
      config: native ? await loadAppConfig() : loadConfigFile('dev'),
      prefs: {'settings.onboardingCompleted': true, 'settings.localeMode': 'zh'},
      overrides: [
        sessionControllerProvider.overrideWith(HistorySession.new),
        updateControllerProvider.overrideWith(HistoryUpdate.new),
        liveRepositoryProvider.overrideWithValue(repo),
        roomControllerProvider.overrideWith(DashboardRoom.new),
        recordingControllerProvider.overrideWith(DashboardRecording.new),
        audioSourceAvailabilityProvider(RecordingSource.microphone)
            .overrideWith((_) async => AudioSourceAvailability.needsPermission),
        audioSourceAvailabilityProvider(RecordingSource.system)
            .overrideWith((_) async => AudioSourceAvailability.unsupported),
      ],
    );
    final boundary = GlobalKey();
    Future<void> frames() async {
      await t.pump();
      await t.pump(const Duration(milliseconds: 150));
    }

    Future<void> tap(Finder f) async {
      await t.ensureVisible(f.last);
      await t.pumpAndSettle();
      await t.tap(f.last);
      await t.pumpAndSettle();
    }

    Future<void> step(
      String operation,
      String expected,
      Future<void> Function() run, {
      String? shot,
    }) async {
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
        if (capture && screenshot != null && shot != null) {
          final file =
              'screenshots/${native ? 'android' : 'vm'}-${++imageNumber}-${size.width.toInt()}-$shot.png';
          await screenshot(file, boundary);
          row['screenshot'] = file;
        }
        row['actual'] = expected;
        row['pass'] = true;
      } catch (e) {
        row['actual'] = '$e';
        rethrow;
      } finally {
        await emit(row);
      }
    }

    void bounds(int count) {
      final stage = t.getRect(find.byKey(const ValueKey('meeting-gallery-stage')));
      final widgets = [
        for (final id in ['self', for (var i = 1; i < count; i++) 'p$i'])
          find.byKey(ValueKey('participant-$id')),
      ];
      final invite = find.byKey(const ValueKey('meeting-invite'));
      if (invite.evaluate().isNotEmpty) widgets.add(invite);
      final rects = widgets.map(t.getRect).toList();
      expect(rects.reduce((a, b) => a.expandToInclude(b)).left, closeTo(stage.left, 1));
      expect(rects.reduce((a, b) => a.expandToInclude(b)).top, closeTo(stage.top, 1));
      expect(rects.reduce((a, b) => a.expandToInclude(b)).right, closeTo(stage.right, 1));
      expect(rects.reduce((a, b) => a.expandToInclude(b)).bottom, closeTo(stage.bottom, 1));
      for (var i = 0; i < rects.length; i++) {
        expect(rects[i].width, greaterThan(0));
        expect(rects[i].height, greaterThanOrEqualTo(132));
        for (var j = i + 1; j < rects.length; j++) {
          expect(rects[i].overlaps(rects[j]), isFalse);
        }
      }
    }

    try {
      await step('夹具独立冒烟', '列表503可重复触发；预定503可重复触发；恢复后均返回确定状态', () async {
        mode = 'error';
        for (var i = 0; i < 2; i++) {
          await expectLater(repo.schedules(null, null), throwsA(isA<ApiException>()));
        }
        rejectSave = true;
        for (var i = 0; i < 2; i++) {
          await expectLater(repo.saveSchedule({}), throwsA(isA<ApiException>()));
        }
        rejectSave = false;
        mode = 'data';
        expect(await repo.schedules(null, null), isNotEmpty);
        mode = 'loading';
      });
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
      await frames();
      await step('首页加载', '四宫格保留可用，列表显示加载状态', () async {
        for (final key in ['live-quick', 'live-join', 'live-schedule', 'live-recording-tools']) {
          expect(find.byKey(ValueKey(key)), findsOneWidget);
        }
        expect(find.text(l.meetingsStartRecording), findsNothing);
        expect(find.text(l.meetingsImportAudio), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      }, shot: 'loading');
      await step('列表加载失败', '首页仍可操作，错误与重试入口可见', () async {
        mode = 'error';
        pending.completeError(const ApiException(kind: ApiErrorKind.unavailable));
        await frames();
        expect(find.text(l.liveRetry), findsOneWidget);
      }, shot: 'load-error');
      await step('列表重试及日期分组', '昨天进行中、今天和明天分组；过滤已取消/过期', () async {
        mode = 'data';
        await tap(find.text(l.liveRetry));
        expect(find.byType(HomeScheduleRow), findsNWidgets(3));
        expect(find.text('已取消不可显示'), findsNothing);
        expect(find.text('过期不可显示'), findsNothing);
        expect(find.text(l.liveAgendaOngoing), findsOneWidget);
        await t.ensureVisible(find.byKey(const ValueKey('home-schedule-today')));
        await t.pumpAndSettle();
      }, shot: 'agenda');
      await step('录音转写入口', '第四块打开独立页面，收纳开始录音和导入音频', () async {
        await tap(find.byKey(const ValueKey('live-recording-tools')));
        expect(find.byType(RecordingToolsPage), findsOneWidget);
        expect(find.byKey(const ValueKey('recording-tools-start')), findsOneWidget);
        expect(find.byKey(const ValueKey('recording-tools-import')), findsOneWidget);
      }, shot: 'recording-tools');
      await step('打开录音与导入页面', '两个入口分别打开原有真实页面，返回后仍在录音转写页', () async {
        await tap(find.byKey(const ValueKey('recording-tools-start')));
        expect(find.byType(RecordingPage), findsOneWidget);
        router.pop();
        await t.pumpAndSettle();
        await tap(find.byKey(const ValueKey('recording-tools-import')));
        expect(find.byType(ImportPage), findsOneWidget);
        router.pop();
        await t.pumpAndSettle();
        expect(find.byType(RecordingToolsPage), findsOneWidget);
        router.pop();
        await t.pumpAndSettle();
      });
      await step('预定失败及重试', '保存503留在原表单，重试后关闭表单并出现在首页', () async {
        await tap(find.byKey(const ValueKey('live-schedule')));
        expect(find.byType(ScheduleSheet), findsOneWidget);
        await t.enterText(find.byType(TextField).first, '首页四宫格预定回归');
        rejectSave = true;
        await tap(find.text(l.liveSave));
        expect(find.byType(ScheduleSheet), findsOneWidget);
        expect(find.text(l.liveRetry), findsNothing);
      }, shot: 'schedule-error');
      await step('预定恢复成功', '原表单可直接重试，保存成功后展示新条目', () async {
        rejectSave = false;
        await tap(find.text(l.liveSave));
        expect(find.byType(ScheduleSheet), findsNothing);
        expect(find.byKey(const ValueKey('home-schedule-created')), findsOneWidget);
        await t.ensureVisible(find.byKey(const ValueKey('home-schedule-created')));
        await t.pumpAndSettle();
      }, shot: 'schedule-success');
      await step('会议详情展开关闭', '紧凑列表保留完整主题和发起人、加入、编辑和取消操作', () async {
        await tap(find.byKey(const ValueKey('home-schedule-tomorrow')));
        expect(find.text(l.liveEdit), findsOneWidget);
        expect(find.text(l.liveCancelSchedule), findsOneWidget);
      }, shot: 'schedule-details');
      Navigator.of(t.element(find.text(l.liveEdit))).pop();
      await t.pumpAndSettle();
      await step('从预定加入会议', '真实加入入口进入会中，三个成员和邀请框覆盖全部网格', () async {
        await tap(find.byKey(const ValueKey('home-schedule-join-created')));
        expect(find.byType(LiveRoomPage), findsOneWidget);
        expect(find.byType(MeetingGallery), findsOneWidget);
        bounds(3);
      }, shot: 'room-three');
      final controller = c.read(roomControllerProvider.notifier) as DashboardRoom;
      final selfElement = t.element(find.byKey(const ValueKey('participant-self')));
      for (final count in [1, 2, 5, 9, 18]) {
        await step(
          '$count 人动态网格',
          '成员区域填满可用舞台、无重叠；相同成员组件保留；多人时可滚动',
          () async {
            controller.members(count);
            await t.pumpAndSettle();
            bounds(count);
            expect(
              identical(selfElement, t.element(find.byKey(const ValueKey('participant-self')))),
              isTrue,
            );
            if (count == 18) {
              await t.ensureVisible(find.byKey(const ValueKey('participant-p17')));
              await t.pumpAndSettle();
            }
          },
          shot: count == 2
              ? 'room-two'
              : count == 5
              ? 'room-five'
              : count == 18
              ? 'room-many'
              : null,
        );
      }
      await step('邀请框复制', '邀请框可以复制真实会议主题及会议号', () async {
        controller.members(3);
        await t.pumpAndSettle();
        // Three participants may fit one landscape row; use a larger set if needed.
        if (find.byKey(const ValueKey('meeting-invite')).evaluate().isEmpty) {
          controller.members(5);
          await t.pumpAndSettle();
        }
        if (find.byKey(const ValueKey('meeting-invite')).evaluate().isEmpty) {
          controller.members(7);
          await t.pumpAndSettle();
        }
        await tap(find.byKey(const ValueKey('meeting-invite')));
        final data = await Clipboard.getData(Clipboard.kTextPlain);
        expect(data?.text, contains('123456789'));
        expect(find.text(l.commonCopied), findsOneWidget);
      });
      await step('最小化与恢复', '首页保留会中状态，再次快速会议恢复已有房间而不重复加入', () async {
        final joins = controller.joinCount();
        await tap(find.byKey(const ValueKey('minimize-live-meeting')));
        expect(find.byKey(const ValueKey('return-live-meeting')), findsOneWidget);
        await tap(find.byKey(const ValueKey('live-quick')));
        expect(controller.joinCount(), joins);
        expect(find.byType(LiveRoomPage), findsOneWidget);
      });
      await step('结束后直接首页', '真实结束清理后回首页，四宫格与记录导航可继续使用', () async {
        await tap(find.text(l.liveEnd));
        await tap(find.text(l.liveConfirm));
        await t.pump(const Duration(milliseconds: 400));
        await t.pumpAndSettle();
        expect(find.byType(LiveRoomPage), findsNothing);
        expect(find.byType(LiveHomePage), findsOneWidget);
      });
      await step('首页空态', '列表无数据时展示空态，四个入口仍保留', () async {
        records = [];
        c.invalidate(upcomingSchedulesProvider);
        await t.pumpAndSettle();
        await t.ensureVisible(find.text(l.liveNoSchedules));
        await t.pumpAndSettle();
        expect(find.text(l.liveNoSchedules), findsOneWidget);
      }, shot: 'empty');
    } finally {
      await t.pumpWidget(const SizedBox.shrink());
      c.dispose();
      await t.pump();
    }
  }
}

void main() {
  testWidgets('home dashboard and adaptive meeting gallery user flow', (t) async {
    registerFallbackValue(DateTime(2026));
    final out = Directory(
      Platform.environment['HOME_GRID_OUTPUT'] ?? '../.artifacts/mobile-home-grid-20261028',
    )..createSync(recursive: true);
    final budget = File('${out.path}/budget.json');
    if (!budget.existsSync()) {
      budget.writeAsStringSync(
        jsonEncode({'started': DateTime.now().millisecondsSinceEpoch, 'limitMs': 1800000}),
      );
    }
    final b = jsonDecode(budget.readAsStringSync()) as Map;
    if (DateTime.now().millisecondsSinceEpoch - (b['started'] as num) > (b['limitMs'] as num)) {
      throw StateError('Cumulative E2E budget exhausted');
    }
    var clipboard = '';
    t.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (
      call,
    ) async {
      if (call.method == 'Clipboard.setData') {
        clipboard = (call.arguments as Map)['text'] as String;
      }
      if (call.method == 'Clipboard.getData') {
        return {'text': clipboard};
      }
      return null;
    });
    addTearDown(
      () =>
          t.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );
    await t.runAsync(() async {
      final font = File('C:/Windows/Fonts/msyh.ttc');
      if (font.existsSync()) {
        await (FontLoader(
          'Roboto',
        )..addFont(Future.value(ByteData.sublistView(await font.readAsBytes())))).load();
      }
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    });
    final rows = <Map<String, Object?>>[];
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

    await runHomeGridFlow(t, emit: emit);
    if (Platform.environment['HOME_GRID_CAPTURE'] == '1') {
      await runHomeGridFlow(t, emit: emit, capture: true, screenshot: shot);
    }
  });
}
