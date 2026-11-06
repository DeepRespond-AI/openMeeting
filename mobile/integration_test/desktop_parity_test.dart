// Real Android plugins/RTC/IM, isolated business services and explicit HTTP faults.
import 'dart:typed_data';

import 'package:deeprespond_im/deeprespond_im.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:meeting/app.dart';
import 'package:meeting/core/api/api_client.dart';
import 'package:meeting/core/api/endpoints.dart';
import 'package:meeting/core/api/models/auth_models.dart';
import 'package:meeting/core/auth/data/session_store.dart';
import 'package:meeting/core/auth/session_controller.dart';
import 'package:meeting/core/config/app_config_provider.dart';
import 'package:meeting/core/config/settings_store.dart';
import 'package:meeting/core/im/im_gateway.dart';
import 'package:meeting/core/im/messaging_controller.dart';
import 'package:meeting/core/im/widgets/inline_video.dart';
import 'package:meeting/core/l10n/l10n.dart';
import 'package:meeting/core/router/app_router.dart';
import 'package:meeting/features/live_meeting/data/live_repository_impl.dart';
import 'package:meeting/features/live_meeting/domain/live_models.dart';
import 'package:meeting/features/live_meeting/presentation/room_controller.dart';
import 'package:meeting/features/live_meeting/presentation/schedule_sheet.dart';
import 'package:meeting/features/live_meeting/presentation/schedules_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('desktop parity main assertions then narrow/tablet screenshot replay', (t) async {
    final bridge = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:39331'));
    final proxy = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:39330'));
    await bridge.post<void>(
      '/start',
      data: {'attempt': const int.fromEnvironment('E2E_ATTEMPT', defaultValue: 1)},
    );
    final config = await loadAppConfig(), prefs = await SharedPreferences.getInstance();
    await prefs.setBool('settings.onboardingCompleted', true);
    await prefs.setString('settings.localeMode', 'zh');
    final c = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      retry: (_, _) => null,
    );
    final session = (await bridge.get<Map<String, dynamic>>('/session')).data!;
    await c
        .read(sessionStoreProvider)
        .save(
          StoredSession(
            token: session['token'] as String,
            user: User.fromJson(Map<String, dynamic>.from(session['user'] as Map)),
            serverUrl: config.defaultServerUrl,
          ),
        );
    await c.read(sessionControllerProvider.future);
    await c.read(sessionControllerProvider.notifier).refreshMe();
    await bridge.post<void>('/permissions');
    final l = lookupAppLocalizations(const Locale('zh'));
    final api = c.read(apiClientProvider), schedules = <String>[];
    final ctl = c.read(roomControllerProvider.notifier);
    await t.pumpWidget(UncontrolledProviderScope(container: c, child: const App()));
    bool ready(AsyncValue<Object?> value) => value.hasValue && !value.isLoading && !value.hasError;
    Future<void> wait(bool Function() condition, {int seconds = 35}) async {
      final deadline = DateTime.now().add(Duration(seconds: seconds));
      while (!condition()) {
        if (DateTime.now().isAfter(deadline)) throw StateError('Native UI condition timed out');
        await t.pump(const Duration(milliseconds: 150));
        await Future<void>.delayed(const Duration(milliseconds: 60));
        final error = t.takeException();
        if (error != null) throw StateError('Flutter: $error');
      }
      await t.pump(const Duration(milliseconds: 350));
    }

    Future<void> tap(Finder finder) async {
      await t.pump(const Duration(milliseconds: 200));
      await t.ensureVisible(finder.last);
      await t.tap(finder.last);
      await t.pump(const Duration(milliseconds: 350));
    }

    Future<void> text(String value) => tap(find.text(value));
    Future<void> mode(Map<String, Object?> values) =>
        proxy.post<void>('/__fixture/mode', data: values);
    Future<void> close() => tap(find.byTooltip(l.liveClose).last);
    Future<void> until(Future<bool> Function() predicate) async {
      final deadline = DateTime.now().add(const Duration(seconds: 35));
      while (!await predicate()) {
        if (DateTime.now().isAfter(deadline)) throw StateError('Real service state timed out');
        await t.pump(const Duration(milliseconds: 200));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    }

    RoomActive active() => c.read(roomControllerProvider) as RoomActive;
    try {
      // A complete assertion pass for BOTH viewports precedes all routine screenshots.
      for (final capture in [false, true]) {
        for (final wide in [false, true]) {
          final size = wide ? '平板横屏' : '手机窄屏';
          Future<void> step(String label, String expected, Future<void> Function() run) async {
            final action = '$size/${capture ? '截图复验' : '断言'}/$label';
            try {
              await run();
              final error = t.takeException();
              if (error != null) throw StateError('Flutter: $error');
              await bridge.post<void>(
                '/step',
                data: {
                  'action': action,
                  'expected': expected,
                  'actual': expected,
                  'passed': true,
                  'capture': capture,
                },
              );
            } catch (error) {
              await bridge.post<void>(
                '/step',
                data: {
                  'action': action,
                  'expected': expected,
                  'actual': error is DioException
                      ? 'HTTP ${error.response?.statusCode}'
                      : error.toString(),
                  'passed': false,
                  'capture': true,
                },
              );
              rethrow;
            }
          }

          await bridge.post<void>('/viewport', data: {'wide': wide});
          await mode({});
          c.read(appRouterProvider).go(AppRoutes.meetings);
          await wait(() => ready(c.read(liveSchedulesProvider)));
          await step('首页', '保留移动端主题和真实日程成功状态', () async {
            expect(find.byKey(const ValueKey('live-quick')), findsOneWidget);
          });
          await step('日程错误', '确定性503展示且可恢复', () async {
            await mode({'schedules': 'error'});
            c.invalidate(liveSchedulesProvider);
            await wait(() => c.read(liveSchedulesProvider).hasError);
            await t.drag(find.byType(ListView).first, const Offset(0, -550));
            await t.pump(const Duration(milliseconds: 400));
            expect(find.textContaining('日程服务暂不可用'), findsWidgets);
          });
          await mode({});
          c.invalidate(liveSchedulesProvider);
          await wait(() => ready(c.read(liveSchedulesProvider)));
          final futureTitle = '未来会议-${DateTime.now().millisecondsSinceEpoch}';
          final future = await c.read(liveRepositoryProvider).saveSchedule({
            'title': futureTitle,
            'startAt': DateTime.now().add(const Duration(days: 365)).toUtc().toIso8601String(),
            'durationMin': 30,
          });
          schedules.add(future.id);
          c.read(appRouterProvider).go(AppRoutes.history);
          await t.pump(const Duration(milliseconds: 600));
          await text(l.liveUpcomingTab);
          await wait(() => ready(c.read(upcomingSchedulesProvider)));
          await step('全年预定', '待开始列表包含一年后会议并支持主题搜索', () async {
            await t.enterText(find.byKey(const ValueKey('upcoming-search')), futureTitle);
            await t.pump(const Duration(milliseconds: 400));
            expect(
              find.descendant(of: find.byType(Card), matching: find.text(futureTitle)),
              findsOneWidget,
            );
          });
          await step('搜索空态', '未匹配预定显示明确空态', () async {
            await t.enterText(find.byKey(const ValueKey('upcoming-search')), 'no-match-fixture');
            await t.pump(const Duration(milliseconds: 400));
            expect(find.text(l.liveScheduleNoMatches), findsOneWidget);
          });
          await text(l.liveSchedule);
          await wait(() => find.byType(ScheduleSheet).evaluate().isNotEmpty);
          await step('日期独立选择', '日期选择不连开时间选择器', () async {
            await tap(find.byKey(const ValueKey('schedule-date')));
            expect(find.byType(DatePickerDialog), findsOneWidget);
          });
          await text(
            MaterialLocalizations.of(t.element(find.byType(DatePickerDialog))).cancelButtonLabel,
          );
          expect(find.byType(TimePickerDialog), findsNothing);
          await step('时间输入', '独立时间输入弹窗可打开和关闭', () async {
            await tap(find.byKey(const ValueKey('schedule-time')));
            expect(find.byType(TimePickerDialog), findsOneWidget);
          });
          await text(
            MaterialLocalizations.of(t.element(find.byType(TimePickerDialog))).cancelButtonLabel,
          );
          await step('预定校验', '空主题保留表单并显示校验提示', () async {
            await text(l.liveSave);
            expect(find.text(l.liveTitleRequired), findsOneWidget);
          });
          Navigator.of(t.element(find.byType(ScheduleSheet))).pop();
          await t.pump(const Duration(milliseconds: 400));
          c.read(appRouterProvider).go(AppRoutes.meetings);
          await t.pump(const Duration(milliseconds: 400));
          await mode({'join': 'delay'});
          await step('入会加载', '进入会中前显示连接加载状态', () async {
            await tap(find.byKey(const ValueKey('live-quick')));
            await wait(() => c.read(roomControllerProvider) is RoomJoining);
            expect(find.text(l.liveJoining), findsOneWidget);
          });
          await wait(
            () =>
                c.read(roomControllerProvider) is RoomActive &&
                active().media == 'connected' &&
                active().connection == 'connected',
            seconds: 65,
          );
          final roomId = active().room.id;
          await mode({});
          await step('原生麦克风', '真实麦克风开启且服务端状态同步', () async {
            await text(l.liveMic);
            await wait(() => active().self.micOn && !active().busy);
          });
          await text(l.liveMore);
          await text(l.liveRecordingTitle);
          await step('录制权限失败', '403保留当前房间和录制入口', () async {
            await mode({'recording': 'forbidden'});
            await text(l.liveRecordingStart);
            await wait(() => active().error?.contains('仅主持人') == true);
            expect(find.textContaining('仅主持人'), findsWidgets);
          });
          await step('录音上传失败', '真实PCM产生后503显示错误而非伪成功', () async {
            await mode({'upload': 'error'});
            await text(l.liveRecordingStart);
            await wait(() => active().captureError?.contains('音频上传') == true, seconds: 40);
          });
          await step('录音恢复', '重试后真实音频分段进入数据库', () async {
            await mode({});
            await text(l.liveRetry);
            await until(() async {
              final r = (await bridge.post<Map<String, dynamic>>(
                '/recording-state',
                data: {'roomId': roomId},
              )).data!;
              return (r['chunks'] as num) > 0;
            });
            await wait(() => active().captureError == null && !active().busy);
          });
          await step('停止录制', '末段确认后停止服务器录制状态', () async {
            await text(l.liveRecordingStop);
            await wait(() => active().room.recording?.active == false && !active().busy);
          });
          await text(l.liveRecordingStart);
          await wait(() => active().room.recording?.active == true && !active().busy);
          await close();
          await close();
          await mode({'chat': 'error'});
          await text(l.liveChat);
          await step('聊天授权失败', '会议IM群授权503显示重试，不回退本地聊天', () async {
            await wait(() => c.read(roomChatSessionProvider).hasError);
            expect(find.textContaining('会议聊天暂不可用'), findsWidgets);
          });
          await mode({});
          await text(l.liveRetry);
          await wait(() => ready(c.read(roomChatSessionProvider)));
          final conversation = c.read(roomChatSessionProvider).requireValue;
          await wait(() => ready(c.read(imMessagesProvider(conversation.conversationKey))));
          final message = '移动对齐真实消息-${DateTime.now().millisecondsSinceEpoch}';
          await step('会议群消息', '从真实输入框发送会议群消息并收到SDK确认', () async {
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
                      .read(imMessagesProvider(conversation.conversationKey))
                      .value
                      ?.items
                      .any((m) => m.body?['text'] == message && m.local.status == 'sent') ==
                  true,
            );
            expect(find.text(message), findsOneWidget);
          });
          final im = await c.read(imClientProvider.future);
          final bytes = (await bridge.get<List<int>>(
            '/asset',
            options: Options(responseType: ResponseType.bytes),
          )).data!;
          final video = await im.messages.send(
            SendTarget.conversation(conversation.conversationKey),
            OutgoingContent.video(
              DRFile.fromBytes(Uint8List.fromList(bytes), name: 'fixture-video.mp4'),
            ),
            options: const SendOptions(waitUntilSent: true),
          );
          await step('内联视频', 'SDK上传的视频在聊天中完成原生初始化并播放', () async {
            await wait(() => find.byType(ImInlineVideo).evaluate().isNotEmpty);
            await text(l.imPlay);
            final url = video.body!['url'] as String;
            await wait(() => ready(c.read(imVideoPlayerProvider(url))));
            await tap(find.byTooltip(l.imPlay));
            await wait(
              () => c.read(imVideoPlayerProvider(url)).requireValue.controller.value.isPlaying,
            );
          });
          await close();
          await step('结束失败', '结束503保留房间和录音重试能力', () async {
            await mode({'end': 'error'});
            expect(await ctl.leave(end: true), false);
            expect(c.read(roomControllerProvider), isA<RoomActive>());
            expect(active().error, contains('结束会议暂不可用'));
          });
          await mode({});
          await step('结束确认', '真实打开结束确认弹窗', () async {
            await text(l.liveEnd);
            expect(find.byType(AlertDialog), findsOneWidget);
          });
          await text(l.liveConfirm);
          await wait(() => c.read(roomControllerProvider) is RoomEnded);
          final meetingId = (c.read(roomControllerProvider) as RoomEnded).meetingId!;
          await step('录音已保存', '会后真实元数据确认有可回放录音', () async {
            await until(() async {
              final r = await api.get<Map<String, dynamic>>(Endpoints.meetingMetadata(meetingId));
              return r.data!['has_audio'] == true;
            });
            expect(find.text(l.liveEnded), findsNothing);
            expect(
              c.read(appRouterProvider).routeInformationProvider.value.uri.path,
              AppRoutes.meetings,
            );
          });
          await step('会后状态', '详情显示实际处理状态，模型不可用不掩盖录音结果', () async {
            c.read(appRouterProvider).go(AppRoutes.meetingDetail(meetingId));
            await t.pump();
            await wait(
              () =>
                  find.textContaining(l.liveRecordingProcessing).evaluate().isNotEmpty ||
                  find.text(l.liveRecordingFailed).evaluate().isNotEmpty ||
                  find.text(l.liveRecordingProcessed).evaluate().isNotEmpty,
            );
          });
          await c.read(liveRepositoryProvider).cancelSchedule(future.id);
          schedules.remove(future.id);
          c.read(appRouterProvider).go(AppRoutes.meetings);
          await t.pump(const Duration(milliseconds: 400));
        }
      }
    } finally {
      await mode({});
      if (c.read(roomControllerProvider) is RoomActive) {
        try {
          await ctl.leave(end: true);
        } catch (_) {}
      }
      for (final id in schedules) {
        try {
          await c.read(liveRepositoryProvider).cancelSchedule(id);
        } catch (_) {}
      }
      await ctl.cleanup();
      await c.read(imGatewayProvider).logout();
      await c.read(sessionStoreProvider).clear();
      await t.pumpWidget(const SizedBox());
      c.dispose();
      api.close();
      bridge.close();
      proxy.close();
    }
  }, timeout: const Timeout(Duration(minutes: 20)));
}
