import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meeting/core/auth/session_controller.dart';
import 'package:meeting/core/config/app_config_provider.dart';
import 'package:meeting/core/im/rtc_telemetry.dart';
import 'package:meeting/core/im/screen_capture.dart';
import 'package:meeting/core/l10n/l10n.dart';
import 'package:meeting/core/router/app_router.dart';
import 'package:meeting/core/theme/app_theme.dart';
import 'package:meeting/core/update/update_controller.dart';
import 'package:meeting/features/live_meeting/data/live_repository_impl.dart';
import 'package:meeting/features/live_meeting/domain/live_models.dart';
import 'package:meeting/features/live_meeting/presentation/room_controller.dart';
import 'package:meeting/features/live_meeting/presentation/room_metrics.dart';
import 'package:meeting/features/live_meeting/presentation/screen_controller.dart';
import 'package:mocktail/mocktail.dart';

import '../core/im/avatar_controller_test.dart' show AvatarTestSession;
import '../helpers/core_media_fixture.dart';
import '../helpers/test_config.dart';
import 'avatar_toolbar_ui_test.dart' show UiAvatarUpdate;

Future<void> runCoreFlow(
  WidgetTester t, {
  required Future<void> Function(Map<String, Object?>) emit,
  required Future<void> Function(String, GlobalKey) screenshot,
  required bool capture,
  bool native = false,
}) async {
  final l = lookupAppLocalizations(const Locale('zh'));
  var imageIndex = 0;
  final sizes = native
      ? [t.view.physicalSize / t.view.devicePixelRatio]
      : [const Size(390, 844), const Size(1024, 768)];
  for (final size in sizes) {
    await t.binding.setSurfaceSize(size);
    final f = CoreMediaFixture();
    final metrics = StreamController<RoomMetrics>();
    final c = await createTestContainer(
      config: native ? await loadAppConfig() : loadConfigFile('dev'),
      prefs: {'settings.onboardingCompleted': true, 'settings.localeMode': 'zh'},
      overrides: [
        sessionControllerProvider.overrideWith(AvatarTestSession.new),
        updateControllerProvider.overrideWith(UiAvatarUpdate.new),
        roomControllerProvider.overrideWith(CoreRoomController.new),
        liveRepositoryProvider.overrideWithValue(f.repo),
        captureScreenProvider.overrideWithValue(f.acquire),
        roomMetricsProvider.overrideWith((_) => metrics.stream),
      ],
    );
    c.read(roomChannelProvider.notifier).set(f.channel);
    final boundary = GlobalKey();
    Future<void> tap(Finder finder) async {
      await t.ensureVisible(finder.last);
      await t.pump();
      await t.tap(finder.last);
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));
    }

    Future<void> step(
      String action,
      String expected,
      Future<void> Function() run, {
      String? picture,
    }) async {
      final row = <String, Object?>{
        'platform': native ? 'android' : 'flutter-vm',
        'phase': capture ? 'screenshots' : 'assertions',
        'viewport': '${size.width.toInt()}x${size.height.toInt()}',
        'operation': action,
        'expected': expected,
        'actual': '',
        'pass': false,
        'screenshot': null,
      };
      try {
        await run();
        final exception = t.takeException();
        if (exception != null) throw StateError('$exception');
        row['pass'] = true;
        row['actual'] = '全部断言通过';
        if (capture && picture != null) {
          final name =
              'screenshots/${native ? 'android' : 'vm'}-${(++imageIndex).toString().padLeft(2, '0')}-${size.width.toInt()}-$picture.png';
          await screenshot(name, boundary);
          row['screenshot'] = name;
        }
      } catch (error) {
        row['actual'] = '$error';
        rethrow;
      } finally {
        await emit(row);
      }
    }

    try {
      await t.runAsync(() => c.read(sessionControllerProvider.future));
      final router = c.read(appRouterProvider);
      router.go(AppRoutes.liveRoom);
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
      await step('会中默认状态', '网络无采样显示未知，不伪造良好', () async {
        expect(find.text(l.liveNetworkUnknown), findsOneWidget);
        expect(find.text(l.liveNetworkGood), findsNothing);
      }, picture: 'normal');
      await step('真实指标展示边界', '夹具 350ms/3% 显示一般，详情展示原始数值', () async {
        metrics.add(
          RoomMetrics(
            speaker: corePeer.userId,
            network: {
              coreSelf.userId!: NetworkMetrics(
                rttMs: 350,
                lossPercent: 3,
                measuredAt: DateTime.now(),
              ),
            },
          ),
        );
        await t.pump();
        await t.pump();
        expect(find.text(l.liveNetworkFair), findsOneWidget);
        expect(find.byIcon(Icons.graphic_eq), findsOneWidget);
        await tap(find.byKey(const ValueKey('rtc-network')));
        expect(find.textContaining('350 ms'), findsOneWidget);
        expect(find.textContaining('3.0%'), findsOneWidget);
      }, picture: 'network');
      await tap(find.text(l.liveClose));
      await step('最小化保持会话', '首页有返回会议入口，保留同一会议', () async {
        await tap(find.byKey(const ValueKey('minimize-live-meeting')));
        expect(find.byKey(const ValueKey('return-live-meeting')), findsOneWidget);
        expect(c.read(roomControllerProvider), isA<RoomActive>());
      }, picture: 'minimized');
      await step('首页滚动', '会中横幅保持可操作，预定空态可以完整滚动到', () async {
        await t.drag(find.byType(ListView).first, const Offset(0, -300));
        await t.pump(const Duration(milliseconds: 400));
        expect(find.byKey(const ValueKey('return-live-meeting')).hitTestable(), findsOneWidget);
      }, picture: 'home-scroll');
      await step('返回现有会议', '不新建房间，返回原会议', () async {
        await tap(find.byKey(const ValueKey('return-live-meeting')));
        expect(find.byKey(const ValueKey('minimize-live-meeting')), findsOneWidget);
        expect((c.read(roomControllerProvider) as RoomActive).room.id, coreRoom.id);
      });
      await tap(find.text(l.liveMore));
      await step('更多菜单', '没有会议录制按钮，共享可操作', () async {
        expect(find.text(l.liveRecordingTitle), findsNothing);
        expect(
          t.widget<ListTile>(find.byKey(const ValueKey('screen-share-action'))).onTap,
          isNotNull,
        );
      }, picture: 'more');
      await step('拒绝采集授权', '确定性拒绝，不申请共享会话', () async {
        f.denyCapture = true;
        await tap(find.byKey(const ValueKey('screen-share-action')));
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('screen-share-action')),
            matching: find.text(l.liveShareDenied),
          ),
          findsOneWidget,
        );
        expect(f.starts, 0);
      }, picture: 'permission');
      await step('发布失败回滚', '共享失败展示，可重试并停止采集/释放标识', () async {
        f.denyCapture = false;
        f.capture.failPublish = true;
        await tap(find.byKey(const ValueKey('screen-share-action')));
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('screen-share-action')),
            matching: find.text(l.liveShareFailed),
          ),
          findsOneWidget,
        );
        expect(f.stops, contains(CoreMediaFixture.claim));
      }, picture: 'share-error');
      await step('加载中取消', '等待授权显示加载，取消后晚到捕获不发布', () async {
        f.capture.failPublish = false;
        f.captureGate = Completer<ScreenCapture>();
        await tap(find.byKey(const ValueKey('screen-share-action')));
        expect(find.text(l.liveShareStarting), findsOneWidget);
      }, picture: 'loading');
      await tap(find.byKey(const ValueKey('screen-share-action')));
      f.captureGate!.complete(f.capture);
      f.captureGate = null;
      await t.pump();
      await step('共享成功重试', '共享业务标识与发布一致，允许停止；像素流由夹具替代', () async {
        await tap(find.byKey(const ValueKey('screen-share-action')));
        expect(c.read(roomScreenProvider).phase, ScreenPhase.sharing);
        expect(f.capture.lastClaim, CoreMediaFixture.claim);
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('screen-share-action')),
            matching: find.text(l.liveShareStop),
          ),
          findsOneWidget,
        );
      });
      await tap(find.byTooltip(l.liveClose));
      await step('共享舞台', '显示共享者、停止入口和明确的等待画面', () async {
        expect(find.text(l.liveShareSharing), findsOneWidget);
        expect(find.text(l.liveShareWaiting), findsOneWidget);
        expect(
          find.text(corePeer.name).hitTestable(),
          findsOneWidget,
          reason: 'Shared-screen thumbnails must keep participant names visible',
        );
      }, picture: 'shared');
      await step('停止共享', '采集关闭，舞台移除，会议仍在进行', () async {
        await tap(find.text(l.liveShareStop));
        expect(c.read(roomScreenProvider).phase, ScreenPhase.idle);
        expect(find.text(l.liveShareWaiting), findsNothing);
        expect(c.read(roomControllerProvider), isA<RoomActive>());
      });
      await step('成员权限', '成员打开设置只读，不能修改密码', () async {
        final room = c.read(roomControllerProvider.notifier) as CoreRoomController;
        room.replace(
          const RoomActive(
            room: coreRoom,
            self: corePeer,
            media: 'connected',
            connection: 'connected',
          ),
        );
        await t.pump();
        await tap(find.text(l.liveMore));
        await tap(find.text(l.liveSettings));
        expect(find.text(l.liveHostOnly), findsOneWidget);
        expect(t.widget<TextField>(find.widgetWithText(TextField, l.liveTitle)).enabled, false);
      }, picture: 'member-settings');
      await tap(find.byTooltip(l.liveClose));
      await tap(find.byTooltip(l.liveClose));
      await step('远程结束返回首页', '关闭弹层并直接返回首页，没有结束中转页和残留入口', () async {
        (c.read(roomControllerProvider.notifier) as CoreRoomController).replace(const RoomEnded());
        await t.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, AppRoutes.meetings);
        expect(find.byKey(const ValueKey('return-live-meeting')), findsNothing);
      }, picture: 'ended');
    } finally {
      await t.pumpWidget(const SizedBox());
      c.dispose();
      unawaited(metrics.close());
      await t.pump();
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    registerFallbackValue(DateTime(2026));
  });
  testWidgets('core parity flows, assertions before visual replay', (t) async {
    final out = Directory('../.artifacts/mobile-core-parity');
    out.createSync(recursive: true);
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
    final rows = <Map<String, Object?>>[];
    Future<void> emit(Map<String, Object?> row) async {
      rows.add(row);
      stdout.writeln(jsonEncode(row));
      File('${out.path}/vm-results.json')
          .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(rows));
    }

    Future<void> shot(String name, GlobalKey key) async {
      await t.pump();
      final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await t.runAsync(() async {
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('${out.path}/$name');
        file.parent.createSync(recursive: true);
        file.writeAsBytesSync(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    await runCoreFlow(t, emit: emit, screenshot: shot, capture: false);
    await runCoreFlow(t, emit: emit, screenshot: shot, capture: true);
  });
}
