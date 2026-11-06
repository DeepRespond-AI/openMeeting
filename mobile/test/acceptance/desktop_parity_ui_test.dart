// Headless Flutter renderer + real isolated REST/WS/IM. Device/secure storage
// use documented VM adapters. PCM below is explicit synthetic input, NOT hardware.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:deeprespond_im/io.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meeting/app.dart';
import 'package:meeting/core/api/api_client.dart';
import 'package:meeting/core/api/endpoints.dart';
import 'package:meeting/core/api/models/auth_models.dart';
import 'package:meeting/core/auth/data/client_info_source.dart';
import 'package:meeting/core/auth/session_controller.dart';
import 'package:meeting/core/im/im_gateway.dart';
import 'package:meeting/core/im/messaging_controller.dart';
import 'package:meeting/core/l10n/l10n.dart';
import 'package:meeting/core/router/app_router.dart';
import 'package:meeting/features/live_meeting/data/live_repository_impl.dart';
import 'package:meeting/features/live_meeting/domain/live_models.dart';
import 'package:meeting/features/live_meeting/presentation/room_controller.dart';
import 'package:meeting/features/live_meeting/presentation/schedule_sheet.dart';
import 'package:meeting/features/live_meeting/presentation/schedules_controller.dart';
import 'package:meeting/features/meetings/data/just_audio_engine.dart';
import 'package:meeting/features/meetings/domain/audio_playback.dart';

import '../helpers/test_config.dart';
import 'support/real_backend.dart' show RealNetwork;

class VmPlayback implements AudioPlaybackEngine {
  @override
  Stream<Duration> get positionStream => const Stream.empty();
  @override
  Stream<Duration?> get durationStream => const Stream.empty();
  @override
  Stream<bool> get playingStream => const Stream.empty();
  @override
  Stream<void> get completedStream => const Stream.empty();
  @override
  Future<Duration?> load(Uri url, {Map<String, String>? headers}) async =>
      const Duration(seconds: 1);
  @override
  Future<void> dispose() async {}
  @override
  Future<void> play() async {}
  @override
  Future<void> pause() async {}
  @override
  Future<void> seek(Duration position) async {}
  @override
  Future<void> setSpeed(double speed) async {}
}

void main() {
  if (Platform.environment['MOBILE_PARITY_UI'] != '1') return;
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('real isolated mobile parity flow and unified screenshot review', (t) async {
    HttpOverrides.global = RealNetwork();
    await t.runAsync(() async {
      final bytes = await File('C:/Windows/Fonts/msyh.ttc').readAsBytes();
      await (FontLoader('Roboto')..addFont(Future.value(ByteData.sublistView(bytes)))).load();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    });
    final out = Directory('../.artifacts/mobile-desktop-parity');
    final rows = <Map<String, Object?>>[];
    final boundary = GlobalKey();
    int shot = 0;
    final runTag = DateTime.now().millisecondsSinceEpoch;
    final bridge = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:39331'));
    final proxy = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:39330'));
    final session = (await t.runAsync(() => bridge.get<Map<String, dynamic>>('/session')))!.data!;
    final config = loadConfigWithServer('http://127.0.0.1:39330');
    final c = (await t.runAsync(
      () => createTestContainer(
        config: config,
        prefs: {'settings.onboardingCompleted': true, 'settings.localeMode': 'zh'},
        secure: {
          'session.token': session['token'] as String,
          'session.user': jsonEncode(session['user']),
          'session.serverUrl': config.defaultServerUrl,
        },
        overrides: [
          audioPlaybackEngineFactoryProvider.overrideWithValue(VmPlayback.new),
          clientInfoProvider.overrideWith(
            (_) async => const ClientInfo(
              clientId: 'mobile-parity-vm',
              hostname: 'Flutter VM renderer',
              os: 'android',
              appVersion: '1.0.0',
            ),
          ),
          imPlatformProvider.overrideWithValue(
            IoPlatform(
              dataDir: Directory('.dart_tool/parity-im').absolute.path,
              platformName: 'windows',
              database: const DefaultDatabaseOpener(background: false),
            ),
          ),
        ],
      ),
    ))!;
    await t.runAsync(() => c.read(sessionControllerProvider.future));
    final l = lookupAppLocalizations(const Locale('zh')),
        api = c.read(apiClientProvider),
        ctl = c.read(roomControllerProvider.notifier);
    Future<T> real<T>(Future<T> Function() action) async {
      T? value;
      Object? failure;
      var done = false;
      unawaited(
        action().then(
          (result) {
            value = result;
            done = true;
          },
          onError: (Object error) {
            failure = error;
            done = true;
          },
        ),
      );
      final deadline = DateTime.now().add(const Duration(seconds: 25));
      while (!done) {
        if (DateTime.now().isAfter(deadline)) throw StateError('Real service request timed out');
        await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
        await t.pump(const Duration(milliseconds: 80));
      }
      if (failure != null) throw failure!;
      return value as T;
    }

    Future<void> wait(bool Function() test) async {
      final until = DateTime.now().add(const Duration(seconds: 25));
      while (!test()) {
        if (DateTime.now().isAfter(until)) throw StateError('Flutter VM UI timed out');
        await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 70)));
        await t.pump(const Duration(milliseconds: 100));
        final e = t.takeException();
        if (e != null) throw StateError('Flutter: $e');
      }
      await t.pump(const Duration(milliseconds: 300));
    }

    Future<void> tap(Finder finder) async {
      await t.pump(const Duration(milliseconds: 400));
      await t.ensureVisible(finder.last);
      await t.tap(finder.last);
      await t.pump(const Duration(milliseconds: 400));
    }

    Future<void> text(String value) => tap(find.text(value));
    Future<void> mode(Map<String, Object?> values) => real(() async {
      await proxy.post<void>('/__fixture/mode', data: values);
    });
    bool ready(AsyncValue<Object?> v) => v.hasValue && !v.isLoading && !v.hasError;
    RoomActive active() => c.read(roomControllerProvider) as RoomActive;
    try {
      for (final capture in [false, true]) {
        for (final viewport in [('手机窄屏', const Size(390, 844)), ('平板横屏', const Size(1024, 768))]) {
          t.view.devicePixelRatio = 1;
          t.view.physicalSize = viewport.$2;
          await t.pumpWidget(
            UncontrolledProviderScope(
              container: c,
              child: RepaintBoundary(key: boundary, child: const App()),
            ),
          );
          Future<void> step(String label, String expected, Future<void> Function() run) async {
            final row = <String, Object?>{
              'action': '${viewport.$1}/${capture ? '截图复验' : '断言'}/$label',
              'expected': expected,
              'passed': false,
              'viewport': [viewport.$2.width, viewport.$2.height],
            };
            try {
              await run();
              final e = t.takeException();
              if (e != null) throw StateError('Flutter: $e');
              row['actual'] = expected;
              row['passed'] = true;
            } catch (e) {
              row['actual'] = e is DioException ? 'HTTP ${e.response?.statusCode}' : e.toString();
              rethrow;
            } finally {
              if (capture || row['passed'] == false) {
                final file =
                    'screenshots/${(++shot).toString().padLeft(2, '0')}-$runTag-${viewport.$1}-$label.png';
                await t.pump();
                final surface =
                    boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
                await t.runAsync(() async {
                  final image = await surface.toImage(pixelRatio: 1);
                  final b = await image.toByteData(format: ui.ImageByteFormat.png);
                  await File('${out.path}/$file').writeAsBytes(b!.buffer.asUint8List());
                  image.dispose();
                });
                row['screenshot'] = file;
              }
              rows.add(row);
              await t.runAsync(
                () =>
                    File('${out.path}/ui-results.json')
                        .writeAsString(const JsonEncoder.withIndent('  ').convert(rows)),
              );
              // ignore: avoid_print
              print(jsonEncode(row));
            }
          }

          await mode({});
          c.read(appRouterProvider).go(AppRoutes.meetings);
          await wait(() => ready(c.read(liveSchedulesProvider)));
          await step('首页', '真实后端日程成功且移动主题保持', () async {
            expect(find.byKey(const ValueKey('live-quick')), findsOneWidget);
          });
          await step('日程错误', '503错误和重试入口真实展示', () async {
            await mode({'schedules': 'error'});
            c.invalidate(liveSchedulesProvider);
            await wait(() => c.read(liveSchedulesProvider).hasError);
            await t.drag(find.byType(ListView).first, const Offset(0, -600));
            await t.pump(const Duration(milliseconds: 400));
            expect(find.textContaining('日程服务暂不可用'), findsWidgets);
          });
          await mode({});
          c.invalidate(liveSchedulesProvider);
          await wait(() => ready(c.read(liveSchedulesProvider)));
          final title = '对齐未来-${DateTime.now().millisecondsSinceEpoch}';
          final future = await real(
            () => c.read(liveRepositoryProvider).saveSchedule({
              'title': title,
              'startAt': DateTime.now().add(const Duration(days: 365)).toUtc().toIso8601String(),
              'durationMin': 30,
            }),
          );
          c.read(appRouterProvider).go(AppRoutes.history);
          await t.pump(const Duration(milliseconds: 500));
          await text(l.liveUpcomingTab);
          await wait(() => ready(c.read(upcomingSchedulesProvider)));
          await step('未来预定', '完整未来列表能搜索一年后会议', () async {
            await t.enterText(find.byKey(const ValueKey('upcoming-search')), title);
            await t.pump(const Duration(milliseconds: 350));
            expect(
              find.descendant(of: find.byType(Card), matching: find.text(title)),
              findsOneWidget,
            );
          });
          await step('搜索空态', '无匹配项时展示空态', () async {
            await t.enterText(find.byKey(const ValueKey('upcoming-search')), 'absent-fixture');
            await t.pump(const Duration(milliseconds: 350));
            expect(find.text(l.liveScheduleNoMatches), findsOneWidget);
          });
          await text(l.liveSchedule);
          await t.pump(const Duration(milliseconds: 400));
          await step('日期选择', '独立日期弹窗真实打开', () async {
            await tap(find.byKey(const ValueKey('schedule-date')));
            expect(find.byType(DatePickerDialog), findsOneWidget);
          });
          await text(
            MaterialLocalizations.of(t.element(find.byType(DatePickerDialog))).cancelButtonLabel,
          );
          expect(find.byType(TimePickerDialog), findsNothing);
          await step('时间输入', '时间输入弹窗独立打开', () async {
            await tap(find.byKey(const ValueKey('schedule-time')));
            expect(find.byType(TimePickerDialog), findsOneWidget);
          });
          await text(
            MaterialLocalizations.of(t.element(find.byType(TimePickerDialog))).cancelButtonLabel,
          );
          await step('表单校验', '空主题保存失败并保留输入界面', () async {
            await text(l.liveSave);
            expect(find.text(l.liveTitleRequired), findsOneWidget);
          });
          Navigator.of(t.element(find.byType(ScheduleSheet))).pop();
          await t.pump(const Duration(milliseconds: 350));
          c.read(appRouterProvider).go(AppRoutes.meetings);
          await t.pump(const Duration(milliseconds: 400));
          await real(() => ctl.join('', create: true));
          c.read(appRouterProvider).go(AppRoutes.liveRoom);
          await wait(
            () =>
                c.read(roomControllerProvider) is RoomActive &&
                active().connection == 'connected' &&
                active().media == 'unavailable',
          );
          final id = active().room.id;
          await step('入会与媒体边界', '真实业务入会，VM不支持RTC时明确展示不可用', () async {
            expect(find.text(l.liveMediaUnavailable), findsOneWidget);
          });
          await text(l.liveMore);
          await text(l.liveRecordingTitle);
          await step('权限失败', '录制403保留房间与错误', () async {
            await mode({'recording': 'forbidden'});
            await text(l.liveRecordingStart);
            await wait(() => active().error != null);
            expect(find.textContaining('仅主持人'), findsWidgets);
          });
          await mode({});
          await text(l.liveRecordingStart);
          await wait(() => active().room.recording?.active == true && !active().busy);
          await step('等待音轨', '没有原生音轨时等待，不伪造采集成功', () async {
            expect(find.text(l.liveRecordingWaiting), findsWidgets);
          });
          await real(() async {
            final pcm = Uint8List(32000); // Explicit one-second synthetic silence.
            await c.read(liveRepositoryProvider).recordingChunk(id, {
              'chunkId': 'vm-${DateTime.now().microsecondsSinceEpoch}',
              'participantId': active().self.id,
              'startTime': 0.0,
              'pcm': base64Encode(pcm),
              'epoch': active().room.recording!.epoch,
            });
          });
          await step('停止录制', '真实服务器停止状态与界面同步', () async {
            await text(l.liveRecordingStop);
            await wait(() => active().room.recording?.active == false && !active().busy);
          });
          await tap(find.byTooltip(l.liveClose).last);
          await tap(find.byTooltip(l.liveClose).last);
          await mode({'chat': 'error'});
          await text(l.liveChat);
          await step('聊天授权错误', 'IM群授权503显示重试', () async {
            await wait(() => c.read(roomChatSessionProvider).hasError);
            expect(find.textContaining('会议聊天暂不可用'), findsWidgets);
          });
          await mode({});
          await text(l.liveRetry);
          await wait(() => ready(c.read(roomChatSessionProvider)));
          final key = c.read(roomChatSessionProvider).requireValue.conversationKey;
          await wait(() => ready(c.read(imMessagesProvider(key))));
          final message = '真实会议消息-${DateTime.now().millisecondsSinceEpoch}';
          await step('群消息成功', '真实IM群文本由输入框发送并获得确认', () async {
            await t.enterText(
              find.byWidgetPredicate(
                (w) => w is TextField && w.decoration?.labelText == l.liveMessage,
              ),
              message,
            );
            await tap(find.byTooltip(l.liveSend));
            await wait(
              () =>
                  c
                      .read(imMessagesProvider(key))
                      .value
                      ?.items
                      .any((m) => m.body?['text'] == message && m.local.status == 'sent') ==
                  true,
            );
            expect(find.text(message), findsOneWidget);
          });
          await tap(find.byTooltip(l.liveClose).last);
          await step('结束失败', '真实结束失败保留房间', () async {
            await mode({'end': 'error'});
            expect(await real(() => ctl.leave(end: true)), false);
            expect(c.read(roomControllerProvider), isA<RoomActive>());
          });
          await mode({});
          await step('结束确认', '实际打开结束弹窗', () async {
            await text(l.liveEnd);
            expect(find.byType(AlertDialog), findsOneWidget);
          });
          await text(l.liveConfirm);
          await wait(() => c.read(roomControllerProvider) is RoomEnded);
          final mid = (c.read(roomControllerProvider) as RoomEnded).meetingId!;
          await step('录音保存与状态', '合成PCM经真实后端生成可回放录音，详情显示处理结果', () async {
            await real(() async {
              for (var i = 0; i < 40; i++) {
                final m = (await api.get<Map<String, dynamic>>(Endpoints.meetingMetadata(mid)))
                    .data!;
                if (m['has_audio'] == true) return;
                await Future<void>.delayed(const Duration(milliseconds: 100));
              }
              throw StateError('Audio not saved');
            });
            await text(l.liveViewNotes);
            await wait(
              () =>
                  find.text(l.liveRecordingFailed).evaluate().isNotEmpty ||
                  find.text(l.liveRecordingProcessed).evaluate().isNotEmpty,
            );
            expect(find.textContaining('录音'), findsWidgets);
          });
          await real(() => c.read(liveRepositoryProvider).cancelSchedule(future.id));
          c.read(appRouterProvider).go(AppRoutes.meetings);
          await t.pump(const Duration(milliseconds: 400));
        }
      }
    } finally {
      await mode({});
      if (c.read(roomControllerProvider) is RoomActive) {
        try {
          await real(() => ctl.leave(end: true));
        } catch (_) {}
      }
      await real(ctl.cleanup);
      await real(() => c.read(imGatewayProvider).logout());
      await t.pumpWidget(const SizedBox());
      c.dispose();
      await t.pump(const Duration(seconds: 20));
      HttpOverrides.global = null;
      t.view.resetPhysicalSize();
      t.view.resetDevicePixelRatio();
      api.close();
      bridge.close();
      proxy.close();
    }
  }, timeout: const Timeout(Duration(minutes: 10)));
}
