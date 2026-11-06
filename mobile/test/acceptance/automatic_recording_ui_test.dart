// Production Flutter app + isolated real REST/WS/IM. Native storage/platform
// adapters are explicit. PCM is synthetic; hardware capture/export are not proved.
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
import 'package:meeting/core/api/models/auth_models.dart';
import 'package:meeting/core/auth/data/client_info_source.dart';
import 'package:meeting/core/auth/session_controller.dart';
import 'package:meeting/core/config/app_enums.dart';
import 'package:meeting/core/im/im_gateway.dart';
import 'package:meeting/core/im/messaging_controller.dart';
import 'package:meeting/core/l10n/l10n.dart';
import 'package:meeting/core/router/app_router.dart';
import 'package:meeting/core/router/notice_presentation.dart';
import 'package:meeting/features/live_meeting/data/live_repository_impl.dart';
import 'package:meeting/features/live_meeting/domain/live_models.dart';
import 'package:meeting/features/live_meeting/presentation/room_controller.dart';
import 'package:meeting/features/live_meeting/presentation/schedules_controller.dart';
import 'package:meeting/features/meetings/data/just_audio_engine.dart';
import 'package:meeting/features/meetings/data/recording_download.dart';
import 'package:meeting/features/meetings/presentation/meeting_detail_controller.dart';
import 'package:meeting/features/recording/data/audio_sources.dart';
import 'package:meeting/features/recording/domain/audio_source.dart';

import '../helpers/test_config.dart';
import 'desktop_parity_ui_test.dart' show VmPlayback;
import 'support/real_backend.dart' show RealNetwork;

void main() {
  if (Platform.environment['MOBILE_AUTO_RECORDS_UI'] != '1') return;
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('automatic recording and shared records: real user flow then screenshots', (t) async {
    HttpOverrides.global = RealNetwork();
    final out = Directory('../.artifacts/mobile-auto-records');
    final budget = jsonDecode(File('${out.path}/e2e-budget.json').readAsStringSync()) as Map;
    if (DateTime.now()
            .toUtc()
            .difference(DateTime.parse(budget['firstAttempt'] as String))
            .inMinutes >=
        30) {
      throw StateError('Cumulative E2E budget exhausted. Use API validation.');
    }
    await t.runAsync(() async {
      final bytes = await File('C:/Windows/Fonts/msyh.ttc').readAsBytes();
      await (FontLoader('Roboto')..addFont(Future.value(ByteData.sublistView(bytes)))).load();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    });
    final accounts = (jsonDecode(
      File('${out.path}/accounts.private.json').readAsStringSync(),
    ) as List).map((value) => Map<String, dynamic>.from(value as Map)).toList();
    final bridge = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:39331'));
    final proxy = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:39330'));
    final session = (await t.runAsync(() => bridge.get<Map<String, dynamic>>('/session')))!.data!;
    final config = loadConfigWithServer('http://127.0.0.1:39330');
    final c = await t.runAsync(
      () => createTestContainer(
        config: config,
        prefs: {'settings.onboardingCompleted': true, 'settings.localeMode': 'zh'},
        secure: {
          'session.token': session['token'] as String,
          'session.user': jsonEncode(session['user']),
          'session.serverUrl': config.defaultServerUrl,
        },
        overrides: [
          audioSourceAvailabilityProvider(RecordingSource.microphone)
              .overrideWith((_) async => AudioSourceAvailability.needsPermission),
          audioSourceAvailabilityProvider(RecordingSource.system)
              .overrideWith((_) async => AudioSourceAvailability.unsupported),
          audioPlaybackEngineFactoryProvider.overrideWithValue(VmPlayback.new),
          clientInfoProvider.overrideWith(
            (_) async => const ClientInfo(
              clientId: 'mobile-auto-records-ui',
              hostname: 'Flutter VM renderer',
              os: 'android',
              appVersion: '1.0.0',
            ),
          ),
          imPlatformProvider.overrideWithValue(
            IoPlatform(
              dataDir: Directory('.dart_tool/auto-records-im').absolute.path,
              platformName: 'windows',
              database: const DefaultDatabaseOpener(background: false),
            ),
          ),
          recordingFilesProvider.overrideWith(
            (ref) => RecordingFiles(
              dio: ref.watch(apiClientProvider),
              directory: () async => Directory('${out.path}/downloads').create(recursive: true),
              export: (_) async {},
              folder: config.recording.recordingsDirName,
              timeout: config.network.transferTimeout,
            ),
          ),
        ],
      ),
    );
    final container = c!;
    await t.runAsync(() => container.read(sessionControllerProvider.future));
    final l = lookupAppLocalizations(const Locale('zh'));
    final boundary = GlobalKey();
    final rows = <Map<String, Object?>>[];
    final tag = DateTime.now().millisecondsSinceEpoch;
    var shot = 0;
    final result = File('${out.path}/ui-results.json');
    if (result.existsSync()) result.copySync('${out.path}/history/$tag-ui-results.json');
    Future<T> real<T>(Future<T> Function() action) async {
      T? value;
      Object? error;
      var done = false;
      unawaited(
        action().then(
          (v) {
            value = v;
            done = true;
          },
          onError: (Object e) {
            error = e;
            done = true;
          },
        ),
      );
      final deadline = DateTime.now().add(const Duration(seconds: 25));
      while (!done) {
        if (DateTime.now().isAfter(deadline)) throw StateError('Real request timed out');
        await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
        await t.pump(const Duration(milliseconds: 80));
      }
      if (error != null) throw error!;
      return value as T;
    }

    Future<void> wait(bool Function() ready) async {
      final deadline = DateTime.now().add(const Duration(seconds: 25));
      while (!ready()) {
        if (DateTime.now().isAfter(deadline)) throw StateError('UI condition timed out');
        await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 60)));
        await t.pump(const Duration(milliseconds: 80));
        final error = t.takeException();
        if (error != null) throw StateError('Flutter: $error');
      }
      await t.pump(const Duration(milliseconds: 400));
    }

    Future<void> tap(Finder f) async {
      await t.pump(const Duration(milliseconds: 400));
      await t.ensureVisible(f);
      await t.pump(const Duration(milliseconds: 300));
      await t.tap(f);
      await t.pump(const Duration(milliseconds: 400));
    }

    Future<void> mode(Map<String, Object?> value) =>
        real(() => proxy.post<void>('/__fixture/mode', data: value));
    Future<void> account(int index) async {
      await real(() => container.read(sessionControllerProvider.notifier).logout());
      await real(
        () => container
            .read(sessionControllerProvider.notifier)
            .loginWithPassword(
              accounts[index]['phone'] as String,
              accounts[index]['password'] as String,
            ),
      );
      container.read(appRouterProvider).go(AppRoutes.meetings);
      await wait(() => find.byKey(const ValueKey('live-quick')).evaluate().isNotEmpty);
    }

    try {
      for (final capture in [false, true]) {
        for (final wide in [false, true]) {
          final viewport = wide ? const Size(1024, 768) : const Size(390, 844);
          final label = wide ? '平板横屏' : '手机窄屏';
          await t.binding.setSurfaceSize(viewport);
          if (find.byType(App).evaluate().isEmpty) {
            await t.pumpWidget(
              UncontrolledProviderScope(
                container: container,
                child: RepaintBoundary(key: boundary, child: const App()),
              ),
            );
          } else {
            await account(0);
          }
          final controller = container.read(roomControllerProvider.notifier);
          controller.reset();
          Future<void> step(String action, String expected, Future<void> Function() run) async {
            final row = <String, Object?>{
              'action': '$label/${capture ? '截图复验' : '断言'}/$action',
              'expected': expected,
              'passed': false,
              'viewport': [viewport.width, viewport.height],
            };
            try {
              await run();
              final error = t.takeException();
              if (error != null) throw StateError(error.toString());
              row['passed'] = true;
              row['actual'] = expected;
            } on Object catch (error) {
              row['actual'] = error.toString();
              rethrow;
            } finally {
              if (capture || row['passed'] == false) {
                if (!container.read(noticePresentationProvider).canShow) {
                  await t.pumpAndSettle(const Duration(milliseconds: 100));
                }
                await t.pump();
                final name =
                    'screenshots/${(++shot).toString().padLeft(2, '0')}-$tag-$label-$action.png';
                await t.runAsync(() async {
                  final render =
                      boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
                  final image = await render.toImage(pixelRatio: 1);
                  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
                  await File('${out.path}/$name').writeAsBytes(bytes!.buffer.asUint8List());
                  image.dispose();
                });
                row['screenshot'] = name;
              }
              rows.add(row);
              await t.runAsync(
                () => result.writeAsString(const JsonEncoder.withIndent('  ').convert(rows)),
              );
              // ignore: avoid_print
              print(jsonEncode(row));
            }
          }

          await step('首页', '消息按钮和消息快捷卡隐藏，快速会议仍可用', () async {
            await wait(() => find.byKey(const ValueKey('live-quick')).evaluate().isNotEmpty);
            expect(find.byTooltip(l.liveMessages), findsNothing);
            expect(find.byKey(const ValueKey('live-messages')), findsNothing);
          });
          await step('独立录音入口', '独立录音页面打开；原生采集权限为显式VM适配，不执行硬件录音', () async {
            container.read(appRouterProvider).go(AppRoutes.recording);
            await wait(() => find.text(l.navRecording).evaluate().isNotEmpty);
            expect(find.byType(Scaffold), findsWidgets);
          });
          await step('导入入口', '导入页面可打开；文件选择与原生导入未执行', () async {
            container.read(appRouterProvider).go(AppRoutes.import);
            await wait(() => find.text(l.navImport).evaluate().isNotEmpty);
          });
          await step('个人设置', '个人设置页面打开，可实际滚动', () async {
            container.read(appRouterProvider).go(AppRoutes.settings);
            await wait(() => find.text(l.navSettings).evaluate().isNotEmpty);
            await t.drag(find.byType(ListView).first, const Offset(0, -200));
            await t.pump(const Duration(milliseconds: 400));
          });
          container.read(appRouterProvider).go(AppRoutes.meetings);
          await wait(() => find.byKey(const ValueKey('live-schedule')).evaluate().isNotEmpty);
          await tap(find.byKey(const ValueKey('live-schedule')));
          await step('预定日期弹窗', '真实日期选择弹窗打开并完成绘制', () async {
            await tap(find.byKey(const ValueKey('schedule-date')));
            expect(find.byType(DatePickerDialog), findsOneWidget);
          });
          await tap(
            find.text(
              MaterialLocalizations.of(t.element(find.byType(DatePickerDialog))).cancelButtonLabel,
            ),
          );
          await step('预定时间弹窗', '真实时间输入弹窗打开，与日期选择独立', () async {
            await tap(find.byKey(const ValueKey('schedule-time')));
            expect(find.byType(TimePickerDialog), findsOneWidget);
          });
          await tap(
            find.text(
              MaterialLocalizations.of(t.element(find.byType(TimePickerDialog))).cancelButtonLabel,
            ),
          );
          await step('预定必填校验', '空标题无法提交，显示真实校验文案', () async {
            await tap(find.text(l.liveSave));
            expect(find.text(l.liveTitleRequired), findsOneWidget);
          });
          var scheduleTitle = '移动预定-$tag-$wide-$capture';
          await step('新建预定', '表单提交真实后端并出现在今日列表', () async {
            await t.enterText(find.byType(TextField).first, scheduleTitle);
            await tap(find.text(l.liveSave));
            await wait(
              () => find
                  .descendant(of: find.byType(Card), matching: find.text(scheduleTitle))
                  .evaluate()
                  .isNotEmpty,
            );
            await t.ensureVisible(
              find.descendant(of: find.byType(Card), matching: find.text(scheduleTitle)).first,
            );
            await t.pump(const Duration(milliseconds: 400));
          });
          await step('编辑预定', '真实修改预定标题，保存后列表同步更新', () async {
            final card = find
                .ancestor(of: find.text(scheduleTitle), matching: find.byType(Card))
                .first;
            await tap(find.descendant(of: card, matching: find.text(l.liveEdit)));
            scheduleTitle = '$scheduleTitle-修改';
            await t.enterText(find.byType(TextField).first, scheduleTitle);
            await tap(find.text(l.liveSave));
            await wait(
              () => find
                  .descendant(of: find.byType(Card), matching: find.text(scheduleTitle))
                  .evaluate()
                  .isNotEmpty,
            );
          });
          await step('取消预定确认', '实际打开取消确认弹窗', () async {
            final card = find
                .ancestor(of: find.text(scheduleTitle), matching: find.byType(Card))
                .first;
            await tap(find.descendant(of: card, matching: find.text(l.liveCancelSchedule)));
            expect(find.byType(AlertDialog), findsOneWidget);
          });
          await tap(find.text(l.liveConfirm));
          await wait(() => find.text(scheduleTitle).evaluate().isEmpty);
          final future = await real(
            () => container.read(liveRepositoryProvider).saveSchedule({
              'title': '未来预定-$tag-$wide-$capture',
              'startAt': DateTime.now().add(const Duration(days: 365)).toUtc().toIso8601String(),
              'durationMin': 30,
            }),
          );
          container.read(appRouterProvider).go(AppRoutes.history);
          await t.pump(const Duration(milliseconds: 400));
          await tap(find.text(l.liveUpcomingTab));
          await step('未来预定搜索', '待开始列表可搜索一年后的预定', () async {
            await wait(() => container.read(upcomingSchedulesProvider).hasValue);
            await t.enterText(find.byKey(const ValueKey('upcoming-search')), future.title);
            await t.pump(const Duration(milliseconds: 400));
            expect(
              find.descendant(of: find.byType(Card), matching: find.text(future.title)),
              findsOneWidget,
            );
          });
          await step('预定搜索空态', '没有匹配项显示空态', () async {
            await t.enterText(find.byKey(const ValueKey('upcoming-search')), 'no-match-$tag');
            await t.pump(const Duration(milliseconds: 400));
            expect(find.text(l.liveScheduleNoMatches), findsOneWidget);
          });
          await real(() => container.read(liveRepositoryProvider).cancelSchedule(future.id));
          container.read(appRouterProvider).go(AppRoutes.meetings);
          await t.pump(const Duration(milliseconds: 400));
          await step('自动录音', '真实创建入会即active，展示等待音轨，会中聊天保留', () async {
            await tap(find.byKey(const ValueKey('live-quick')));
            await wait(
              () =>
                  container.read(roomControllerProvider) is RoomActive &&
                  (container.read(roomControllerProvider) as RoomActive).connection ==
                      'connected' &&
                  (container.read(roomControllerProvider) as RoomActive).media == 'unavailable',
            );
            expect(
              (container.read(roomControllerProvider) as RoomActive).room.recording?.active,
              true,
            );
            expect(find.text(l.liveChat), findsOneWidget);
            expect(find.text(l.liveRecordingWaiting), findsOneWidget);
          });
          await step('隐藏会议录制入口', '更多菜单不再提供会议录制按钮，自动录音状态保留在舞台', () async {
            await tap(find.text(l.liveMore));
            expect(find.text(l.liveRecordingTitle), findsNothing);
            expect(find.byKey(const ValueKey('room-recording-control')), findsNothing);
            expect(find.text(l.liveRecordingApprovals), findsNothing);
          });
          await tap(find.byTooltip(l.liveClose).last);
          await tap(find.text(l.liveMore));
          await tap(find.text(l.liveSettings));
          final meetingTitle = '移动自动录音共享验收 · 长标题展示及权限验证 $wide-$capture';
          await step('会中设置失败', '主持人设置403错误可见，未错误关闭表单', () async {
            await t.enterText(find.byType(TextField).first, meetingTitle);
            await tap(find.text(l.liveRequirePassword));
            await t.enterText(find.byType(TextField).last, '2468');
            await tap(find.text(l.liveWaitingRoom));
            await mode({'settings': 'forbidden'});
            await tap(find.text(l.liveSave));
            await wait(() => (container.read(roomControllerProvider) as RoomActive).error != null);
            expect(find.textContaining('没有主持人权限'), findsWidgets);
          });
          await mode({});
          await step('会中设置保存', '修改主题、密码及等候室，真实保存成功', () async {
            await tap(find.text(l.liveSave));
            await wait(
              () =>
                  (container.read(roomControllerProvider) as RoomActive).room.title == meetingTitle,
            );
            expect((container.read(roomControllerProvider) as RoomActive).room.pwdEnabled, true);
            expect((container.read(roomControllerProvider) as RoomActive).room.waitRoom, true);
          });
          await tap(find.byTooltip(l.liveClose).last);
          final room = (container.read(roomControllerProvider) as RoomActive).room;
          await real(
            () => proxy.post<void>(
              '/api/v1/rooms/join',
              data: {'code': room.code, 'pwd': '2468', 'micOn': false, 'camOn': false},
              options: Options(headers: {'authorization': 'Bearer ${session['peerToken']}'}),
            ),
          );
          await step('等候室接纳成员', '成员真实进入等候室，由主持人界面接纳', () async {
            await tap(find.text(l.liveMembers));
            await wait(() => find.text(l.liveAdmit).evaluate().isNotEmpty);
            await tap(find.text(l.liveAdmit).first);
            await wait(
              () =>
                  (container.read(roomControllerProvider) as RoomActive).room.participants.length ==
                  2,
            );
          });
          await tap(find.byTooltip(l.liveClose).last);
          await real(
            () => proxy.post<void>(
              '/api/v1/rooms/${room.id}/leave',
              data: {},
              options: Options(headers: {'authorization': 'Bearer ${session['peerToken']}'}),
            ),
          );
          await mode({'chat': 'error'});
          await step('会中聊天失败', '独立消息隐藏后，会中聊天仍保留并显示授权503重试', () async {
            await tap(find.text(l.liveChat));
            await wait(() => container.read(roomChatSessionProvider).hasError);
            expect(find.textContaining('会议聊天暂不可用'), findsWidgets);
          });
          await mode({});
          await tap(find.text(l.liveRetry).last);
          await wait(() => container.read(roomChatSessionProvider).hasValue);
          final conversation = container.read(roomChatSessionProvider).requireValue.conversationKey;
          await wait(() => container.read(imMessagesProvider(conversation)).hasValue);
          await step('会中聊天发送', '通过真实会议专属IM群发送文字并收到sent确认', () async {
            final text = '移动共享验收消息-$tag-$wide-$capture';
            await t.enterText(find.byType(TextField).last, text);
            await tap(find.byIcon(Icons.send));
            await wait(
              () =>
                  container
                      .read(imMessagesProvider(conversation))
                      .value
                      ?.items
                      .any(
                        (message) =>
                            message.body?['text'] == text &&
                            (message.local.status == 'sent' || message.seq != null),
                      ) ==
                  true,
            );
            expect(find.text(text), findsOneWidget);
          });
          await tap(find.byTooltip(l.liveClose).last);
          await real(
            () => container
                .read(apiClientProvider)
                .post<void>(
                  '/api/v1/rooms/${room.id}/recording/chunks',
                  data: {
                    'chunkId': 'ui-$tag-${wide ? 'wide' : 'narrow'}-$capture',
                    'participantId': room.hostId,
                    'startTime': 0,
                    'pcm': base64Encode(List.filled(32000, 0)),
                    'epoch': room.recording!.epoch,
                  },
                ),
          );
          await mode({'end': 'error'});
          await step('结束失败', '结束503保留房间并显示错误，可再次结束', () async {
            await tap(find.text(l.liveEnd));
            await tap(find.text(l.liveConfirm));
            await wait(() => (container.read(roomControllerProvider) as RoomActive).error != null);
            expect(find.textContaining('测试夹具：结束会议暂不可用'), findsWidgets);
          });
          await mode({});
          await step('结束确认弹窗', '真实打开自动录音结束确认，说明全员记录及后台处理', () async {
            await tap(find.text(l.liveEnd));
            expect(find.byType(AlertDialog), findsOneWidget);
            expect(find.text(l.liveEndHint), findsOneWidget);
          });
          await tap(find.text(l.liveConfirm));
          await wait(() => container.read(roomControllerProvider) is RoomEnded);
          final id = (container.read(roomControllerProvider) as RoomEnded).meetingId!;
          await wait(
            () =>
                container.read(appRouterProvider).routeInformationProvider.value.uri.path ==
                AppRoutes.meetings,
          );
          expect(find.text(l.liveEnded), findsNothing);
          container.read(appRouterProvider).go(AppRoutes.meetingDetail(id));
          await t.pump();
          await wait(
            () => container.read(meetingDetailControllerProvider(id)).value?.hasAudio == true,
          );
          await mode({'download': 'error'});
          await step('下载失败', '真实下载503显示错误而不伪报保存成功', () async {
            await tap(find.byKey(const ValueKey('download-recording')));
            await wait(() => container.read(recordingDownloadControllerProvider(id)).hasError);
            expect(find.text(l.liveAudioSaved), findsNothing);
          });
          await mode({'download': 'delay'});
          await step('下载加载', '下载期间禁用按钮并显示加载状态', () async {
            await tap(find.byKey(const ValueKey('download-recording')));
            expect(container.read(recordingDownloadControllerProvider(id)).isLoading, true);
            expect(find.text(l.liveDownloadingAudio), findsOneWidget);
          });
          await step('下载成功', '重试真实下载WAV并显示保存及系统导出入口', () async {
            await wait(() => container.read(recordingDownloadControllerProvider(id)).value != null);
            final file = container.read(recordingDownloadControllerProvider(id)).value!;
            final bytes = file.readAsBytesSync();
            expect(ascii.decode(bytes.sublist(0, 4)), 'RIFF');
            expect(find.text(l.liveAudioSaved), findsOneWidget);
            expect(find.byKey(const ValueKey('export-recording')), findsOneWidget);
          });
          await mode({});
          await account(1);
          container.read(appRouterProvider).go(AppRoutes.history);
          await step('早退成员记录列表', '提前离开成员能从真实列表打开同一条记录', () async {
            await wait(() => find.text(room.title).evaluate().isNotEmpty);
            await tap(find.text(room.title).first);
            await wait(
              () => container.read(meetingDetailControllerProvider(id)).value?.canManage == false,
            );
          });
          await step('成员只读信息', '共享记录标记只读，菜单没有重命名重处理和删除', () async {
            expect(find.text(l.liveSharedRecord), findsOneWidget);
            await tap(find.byTooltip(l.meetingsActions));
            expect(find.text(l.commonRename), findsNothing);
            expect(find.text(l.meetingsActionDelete), findsNothing);
            expect(find.text(l.meetingsActionRetranscribe), findsNothing);
          });
          await t.tapAt(const Offset(8, 180));
          await t.pump(const Duration(milliseconds: 400));
          await step('成员只读纪要', '可读取纪要状态，不显示生成编辑和补充输入', () async {
            await tap(find.text(l.meetingsTabSummary));
            await t.pump(const Duration(milliseconds: 400));
            await wait(() => find.text(l.liveSharedSummaryEmpty).evaluate().isNotEmpty);
            expect(find.text(l.summaryCustomPromptLabel), findsNothing);
            expect(find.text(l.summaryGenerate), findsNothing);
            expect(find.text(l.summaryRegenerate), findsNothing);
          });
          await tap(find.text(l.meetingsTabInfo));
          await step('成员录音下载', '早退成员具有同等下载能力，保存真实RIFF音频', () async {
            await tap(find.byKey(const ValueKey('download-recording')));
            await wait(() => container.read(recordingDownloadControllerProvider(id)).value != null);
            final bytes = container
                .read(recordingDownloadControllerProvider(id))
                .value!
                .readAsBytesSync();
            expect(ascii.decode(bytes.sublist(0, 4)), 'RIFF');
            expect(bytes.length, greaterThan(44));
          });
          await account(2);
          container.read(appRouterProvider).go(AppRoutes.meetingDetail(id));
          await step('非参会账号拒绝', '真实404错误界面不展示会议内容或下载入口', () async {
            await wait(() => container.read(meetingDetailControllerProvider(id)).hasError);
            expect(find.byKey(const ValueKey('download-recording')), findsNothing);
            expect(find.text(l.liveSharedRecord), findsNothing);
          });
        }
      }
    } on Object catch (error) {
      if (rows.isEmpty || rows.last['passed'] != false) {
        final name = 'screenshots/${(++shot).toString().padLeft(2, '0')}-$tag-运行器失败.png';
        await t.pump();
        await t.runAsync(() async {
          final render = boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await render.toImage(pixelRatio: 1);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File('${out.path}/$name').writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
        rows.add({
          'action': '运行器未分步错误',
          'expected': '完整流程完成',
          'actual': error.toString(),
          'passed': false,
          'screenshot': name,
        });
        result.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(rows));
      }
      rethrow;
    } finally {
      await mode({});
      final current = container.read(roomControllerProvider);
      if (current is RoomActive) {
        try {
          await real(
            () => container.read(roomControllerProvider.notifier).leave(end: current.self.isHost),
          );
        } on Object {
          /* Failure evidence is already persisted; cleanup still proceeds. */
        }
      }
      await real(() => container.read(roomControllerProvider.notifier).cleanup());
      await real(() => container.read(imGatewayProvider).logout());
      await t.pumpWidget(const SizedBox.shrink());
      await t.pump();
      container.dispose();
      await t.pump(const Duration(seconds: 20));
      await t.binding.setSurfaceSize(null);
      bridge.close();
      proxy.close();
      HttpOverrides.global = null;
    }
  }, timeout: const Timeout(Duration(minutes: 5)));
}
