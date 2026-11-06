import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:deeprespond_im/deeprespond_im.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meeting/core/l10n/l10n.dart';
import 'package:meeting/core/theme/app_theme.dart';
import 'package:meeting/features/live_meeting/domain/live_models.dart';
import 'package:meeting/features/live_meeting/presentation/room_controller.dart';
import 'package:meeting/features/live_meeting/presentation/room_page.dart';
import 'package:mocktail/mocktail.dart';

import '../features/live_meeting/room_release_race_test.dart';

// Production RoomController, RoomPage, toolbar, leave confirmation and retry.
// Only SDK and business endpoints are deterministic fixtures. No native media
// or real IM login is claimed by this rendering/interaction acceptance.
void main() {
  final out = Directory(
    Platform.environment['MOBILE_RTC_RELEASE_OUTPUT'] ?? '../.artifacts/mobile-rtc-release-race',
  );
  final capture = Platform.environment['RTC_RELEASE_CAPTURE'] == '1';
  final results = <Map<String, Object?>>[];
  setUpAll(() {
    registerFallbackValue(<String, Object?>{});
    registerFallbackValue(const ChannelJoinOptions());
    registerFallbackValue(DRCancelToken());
  });
  for (final width in [390.0, 1200.0]) {
    testWidgets('rapid enter leave re-enter and release timeout at $width', (t) async {
      final budget = File('${out.path}/budget.json');
      if (budget.existsSync()) {
        final start = (jsonDecode(budget.readAsStringSync()) as Map)['started'] as int;
        expect(
          DateTime.now().millisecondsSinceEpoch - start,
          lessThan(const Duration(minutes: 30).inMilliseconds),
        );
      }
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = Size(width, 800);
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
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
      final h = RaceHarness();
      await h.init(releaseTimeoutMs: 1200, autoCleanup: false);
      var joins = 0, releasing = false;
      final pending = Completer<ChannelHandle>(), closed = Completer<void>();
      final old = h.handle('late', release: closed.future), next = h.handle('next');
      addTearDown(() {
        if (!pending.isCompleted) pending.complete(old);
        if (!closed.isCompleted) closed.complete();
      });
      when(() => h.channels.join(any(), options: any(named: 'options')))
          .thenAnswer((_) => ++joins == 1 ? pending.future : Future.value(next));
      when(h.channels.getCurrentSession).thenAnswer(
        (_) async => releasing
            ? const ChannelSession({'status': 'leaving', 'channel_id': 'race-room'})
            : null,
      );
      final boundary = GlobalKey();
      await t.pumpWidget(
        UncontrolledProviderScope(
          container: h.container,
          child: MaterialApp(
            locale: const Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.dark(),
            builder: (context, child) => RepaintBoundary(key: boundary, child: child!),
            home: Consumer(
              builder: (context, ref, _) {
                final state = ref.watch(roomControllerProvider);
                if (state is RoomIdle || state is RoomEnded) {
                  return Scaffold(
                    body: Center(
                      child: FilledButton(
                        onPressed: () => ref.read(roomControllerProvider.notifier).join('123456'),
                        child: const Text('进入测试会议'),
                      ),
                    ),
                  );
                }
                return const LiveRoomPage();
              },
            ),
          ),
        ),
      );
      Future<void> pump() async {
        await t.pump();
        await t.pump(const Duration(milliseconds: 40));
      }

      Future<void> step(String name, String expected, Future<void> Function() action) async {
        final row = <String, Object?>{
          'operation': name,
          'expected': expected,
          'actual': null,
          'pass': false,
          'viewport': '${width.toInt()}x800',
          'screenshot': null,
        };
        try {
          await action();
          expect(t.takeException(), isNull);
          row['actual'] = 'all assertions passed';
          row['pass'] = true;
          if (capture) {
            final file = 'screenshots/${results.length + 1}-${width.toInt()}-$name.png';
            await t.runAsync(() async {
              final image =
                  await (boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary)
                      .toImage();
              final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
              await File('${out.path}/$file').parent.create(recursive: true);
              await File('${out.path}/$file').writeAsBytes(bytes!.buffer.asUint8List());
              image.dispose();
            });
            row['screenshot'] = file;
          }
        } catch (e) {
          row['actual'] = e.toString();
          final file =
              'screenshots/failure-${DateTime.now().millisecondsSinceEpoch}-${width.toInt()}.png';
          await t.runAsync(() async {
            final image =
                await (boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary)
                    .toImage();
            final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
            await File('${out.path}/$file').parent.create(recursive: true);
            await File('${out.path}/$file').writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
          row['screenshot'] = file;
          rethrow;
        } finally {
          results.add(row);
          stdout.writeln(jsonEncode(row));
          await t.runAsync(() async {
            await out.create(recursive: true);
            await File('${out.path}/${capture ? 'visual' : 'ui'}-results.json')
                .writeAsString(const JsonEncoder.withIndent('  ').convert(results));
          });
        }
      }

      await step(
        'initial-joining',
        'initialization page covers first media attach; meeting content not entered yet',
        () async {
          await t.tap(find.text('进入测试会议'));
          await pump();
          expect(joins, 1);
          expect(find.byType(CircularProgressIndicator), findsOneWidget);
          expect(find.byKey(const ValueKey('participant-p')), findsNothing);
          expect(find.text('正在加入会议…'), findsOneWidget);
          expect(find.text('音视频正在后台连接，可先使用聊天和成员功能'), findsNothing);
          expect(find.text('重试'), findsNothing);
        },
      );
      await step('leave-confirmation', 'actual room leave dialog opens', () async {
        await t.tap(find.byIcon(Icons.logout).first);
        await t.pump();
        await t.pump(const Duration(milliseconds: 300));
        expect(find.byType(AlertDialog), findsOneWidget);
      });
      await step(
        'immediate-next-room',
        'leave returns immediately; next business room opens before old RTC release',
        () async {
          await t.tap(find.widgetWithText(FilledButton, '确认'));
          await pump();
          expect(h.calls, contains('business-leave'));
          expect(find.text('进入测试会议'), findsOneWidget);
          pending.complete(old);
          await pump();
          expect(h.calls, contains('leave-late'));
          expect(joins, 1);
          releasing = true;
          await t.tap(find.text('进入测试会议'));
          await pump();
          expect(h.container.read(roomControllerProvider), isA<RoomActive>());
          expect(joins, 1);
        },
      );
      await step(
        'waiting-release',
        're-entry waits leaving without reserving another seat',
        () async {
          closed.complete();
          await t.runAsync(() => Future<void>.delayed(Duration.zero));
          await pump();
          h.events.add({
            'type': 'connection_state',
            'data': {'state': 'connected'},
          });
          await pump();
          expect(find.text('音视频正在后台连接，可先使用聊天和成员功能'), findsNothing);
          expect(find.text('正在等待上一次音视频连接释放…'), findsNothing);
          expect(find.byType(CircularProgressIndicator), findsOneWidget);
          expect(find.byKey(const ValueKey('participant-p')), findsNothing);
          expect(joins, 1);
        },
      );
      await step(
        'release-timeout',
        'bounded wait produces actionable retry on actual page',
        () async {
          await t.pump(const Duration(milliseconds: 1400));
          await pump();
          expect(find.textContaining('上一次音视频连接仍在释放'), findsOneWidget);
          expect(find.text('重试'), findsOneWidget);
          expect(joins, 1);
        },
      );
      await step(
        'retry-connected',
        'release completes and one retry restores normal room',
        () async {
          releasing = false;
          await t.tap(find.text('重试'));
          await t.pumpAndSettle();
          expect(joins, 2);
          expect(h.active.media, 'connected');
          expect(find.byKey(const ValueKey('participant-p')), findsOneWidget);
          expect(find.text('音视频正在后台连接，可先使用聊天和成员功能'), findsNothing);
          expect(find.text('重试'), findsNothing);
          expect(find.byType(CircularProgressIndicator), findsNothing);
          expect(h.container.read(roomChannelProvider), same(next));
        },
      );
      await step(
        'final-leave',
        'normal leave releases current handle and returns to entry',
        () async {
          await t.tap(find.byIcon(Icons.logout).first);
          await t.pumpAndSettle();
          await t.tap(find.widgetWithText(FilledButton, '确认'));
          await t.runAsync(() => Future<void>.delayed(Duration.zero));
          await t.pumpAndSettle();
          expect(h.calls, contains('leave-next'));
          expect(find.text('进入测试会议'), findsOneWidget);
        },
      );
      await t.pumpWidget(const SizedBox.shrink());
      await h.controller.cleanup();
      await h.events.close();
    });
  }
}
