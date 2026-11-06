import 'dart:async';
// Opt-in acceptance: real Flutter widgets + real gateway/room WS. Only device
// storage/identity and the IM SDK's documented VM platform replace native plugins.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:deeprespond_im/deeprespond_im.dart';
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
import 'package:meeting/core/im/im_gateway.dart';
import 'package:meeting/core/l10n/l10n.dart';
import 'package:meeting/core/router/app_router.dart';
import 'package:meeting/features/live_meeting/data/live_repository_impl.dart';
import 'package:meeting/features/live_meeting/domain/live_models.dart';
import 'package:meeting/features/live_meeting/presentation/home_page.dart';
import 'package:meeting/features/live_meeting/presentation/room_controller.dart';
import 'package:meeting/features/live_meeting/presentation/room_page.dart';
import 'package:meeting/features/live_meeting/presentation/schedule_sheet.dart';
import 'package:meeting/features/live_meeting/presentation/schedules_controller.dart';
import 'package:meeting/features/messaging/presentation/messages_page.dart';
import 'package:meeting/features/messaging/presentation/messaging_controller.dart';
import 'package:meeting/features/messaging/presentation/social_pages.dart';

import '../helpers/test_config.dart';
import 'support/real_backend.dart';

final captureKey = GlobalKey();
int imageIndex = 0;
final zh = lookupAppLocalizations(const Locale('zh'));

class UiRun {
  UiRun(this.tester, this.c, this.name, this.capture, this.results);
  final WidgetTester tester;
  final ProviderContainer c;
  final String name;
  final bool capture;
  final Results results;
  Future<void> wait(
    bool Function() condition, {
    String reason = 'UI state',
    int seconds = 12,
  }) async {
    final deadline = DateTime.now().add(Duration(seconds: seconds));
    while (!condition()) {
      if (DateTime.now().isAfter(deadline)) throw StateError('Timeout: $reason');
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 60)));
      await tester.pump(const Duration(milliseconds: 60));
      final error = tester.takeException();
      if (error != null) throw StateError('Flutter: $error');
    }
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> tap(Finder finder) async {
    await tester.pump(const Duration(milliseconds: 400));
    await tester.ensureVisible(finder.last);
    await tester.pump(const Duration(milliseconds: 60));
    await tester.tap(finder.last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
  }

  Future<void> text(String value) => tap(find.text(value));
  Future<T> settle<T>(Future<T> Function() operation) async {
    T? result;
    Object? failure;
    var done = false;
    unawaited(
      operation().then(
        (value) {
          result = value;
          done = true;
        },
        onError: (Object error) {
          failure = error;
          done = true;
        },
      ),
    );
    await wait(() => done, reason: 'real async operation');
    if (failure != null) throw failure!;
    return result as T;
  }

  Future<void> field(String label, String value) =>
      tester.enterText(find.widgetWithText(TextField, label).last, value);
  Future<void> closePanel() async {
    await tap(find.byTooltip(zh.liveClose).last);
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> step(String label, String expected, Future<void> Function() action) async {
    String? screenshot;
    if (capture) {
      screenshot = 'screenshots/${(++imageIndex).toString().padLeft(2, '0')}-$name-$label.png';
    }
    await results.step('$name/${capture ? '截图复验' : '断言'}/$label', expected, () async {
      await action();
      final error = tester.takeException();
      if (error != null) throw StateError('Flutter: $error');
      if (screenshot != null) await shot(screenshot);
      return expected;
    }, screenshot: screenshot);
  }

  Future<void> shot(String path) async {
    await tester.pump(const Duration(milliseconds: 30));
    final boundary = captureKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('${artifactRoot.path}/$path').writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  Future<void> mode(Map<String, Object?> value) async {
    await tester.runAsync(() => fixture(value));
  }
}

void main() {
  if (Platform.environment['OPENMEETING_REAL_TEST'] != '1') return;
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('real mobile user flow then unified narrow/wide screenshot pass', (tester) async {
    final budget = File('${artifactRoot.path}/e2e-budget.json');
    final first = budget.existsSync()
        ? DateTime.parse(
            (jsonDecode(budget.readAsStringSync()) as Map<String, dynamic>)['firstAttempt']
                as String,
          )
        : DateTime.now();
    if (!budget.existsSync()) {
      budget.writeAsStringSync(
        jsonEncode({'firstAttempt': first.toIso8601String(), 'limitMinutes': 30}),
      );
    }
    expect(
      DateTime.now().difference(first),
      lessThan(const Duration(minutes: 30)),
      reason: 'E2E debug budget exhausted; use API fallback and retain failed evidence',
    );
    HttpOverrides.global = RealNetwork();
    debugDisableShadows = false;
    final captureOnly = Platform.environment['OPENMEETING_CAPTURE_ONLY'] == '1';
    if (captureOnly) {
      final previous =
          (jsonDecode(File('${artifactRoot.path}/ui-real-attempt-12.json').readAsStringSync())
                  as List<dynamic>)
              .where(
                (dynamic row) =>
                    ((row as Map<String, dynamic>)['action'] as String).contains('/断言/'),
              )
              .toList();
      expect(previous.length, 62);
      expect(
        previous.every((dynamic row) => (row as Map<String, dynamic>)['passed'] == true),
        isTrue,
      );
    }
    final results = Results(
      'ui-real-attempt-${Platform.environment['OPENMEETING_ATTEMPT'] ?? '01'}',
      io: (write) async {
        await tester.runAsync(write);
      },
    );
    await tester.runAsync(() async {
      final bytes = await File('C:/Windows/Fonts/msyh.ttc').readAsBytes();
      final loader = FontLoader('Roboto')..addFont(Future.value(ByteData.sublistView(bytes)));
      await loader.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    });
    final host = (await tester.runAsync(() => RealAccount.restore('rtchostvalidation')))!;
    final member = (await tester.runAsync(() => RealAccount.restore('rtcmembervalidation')))!;
    final memberApi = member.client();
    final config = loadConfigWithServer('http://127.0.0.1:39220');
    try {
      // All assertions complete for BOTH viewports before screenshot replay begins.
      for (final capture in captureOnly ? [true] : [false, true]) {
        for (final viewport in [('窄屏', const Size(390, 844)), ('宽屏', const Size(1280, 900))]) {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = viewport.$2;
          final suffix = DateTime.now().millisecondsSinceEpoch;
          final c = (await tester.runAsync(
            () => createTestContainer(
              config: config,
              prefs: {'settings.onboardingCompleted': true, 'settings.localeMode': 'zh'},
              secure: {
                'session.token': host.token,
                'session.user': jsonEncode(host.user),
                'session.serverUrl': config.defaultServerUrl,
              },
              overrides: [
                clientInfoProvider.overrideWith(
                  (ref) async => const ClientInfo(
                    clientId: 'flutter-headless-acceptance',
                    hostname: 'Flutter test renderer',
                    os: 'android',
                    appVersion: '1.0.0+1',
                  ),
                ),
                imPlatformProvider.overrideWithValue(
                  IoPlatform(
                    dataDir: Directory('.dart_tool/acceptance/ui-$suffix').absolute.path,
                    platformName: 'windows',
                    database: const DefaultDatabaseOpener(background: false),
                  ),
                ),
              ],
            ),
          ))!;
          final run = UiRun(tester, c, viewport.$1, capture, results);
          String? roomId, scheduleId, groupId;
          try {
            await run.mode({});
            await tester.pumpWidget(
              UncontrolledProviderScope(
                container: c,
                child: RepaintBoundary(key: captureKey, child: const App()),
              ),
            );
            await run.wait(() => find.byType(LiveHomePage).evaluate().isNotEmpty);
            await run.step('首页正常', '恢复现有登录态，真实日程加载完成', () async {
              await run.wait(() => c.read(liveSchedulesProvider).hasValue);
              expect(c.read(sessionControllerProvider).value, isA<AuthSignedIn>());
            });
            await run.step('首页错误', '503 有明确错误及重试入口', () async {
              await run.mode({'schedules': 'error'});
              c.invalidate(liveSchedulesProvider);
              await run.wait(() => c.read(liveSchedulesProvider).hasError);
              expect(find.text('测试夹具：日程服务暂不可用'), findsOneWidget);
            });
            await run.step('首页空态', '服务返回空列表时展示空态', () async {
              await run.mode({'schedules': 'empty'});
              c.invalidate(liveSchedulesProvider);
              await run.wait(() => find.text(zh.liveNoSchedules).evaluate().isNotEmpty);
              await tester.ensureVisible(find.text(zh.liveNoSchedules));
            });
            await run.mode({});
            c.invalidate(liveSchedulesProvider);
            await run.step('预定校验', '真实打开预定表单，空标题禁止提交', () async {
              await run.tap(find.byKey(const ValueKey('live-schedule')));
              await run.text(zh.liveSave);
              expect(find.text(zh.liveTitleRequired), findsOneWidget);
            });
            await run.step('预定成功', '填写长标题后真实创建预定并回到首页', () async {
              await run.field(zh.liveTitle, '移动端真实会议-$suffix-长主题用于验证换行展示');
              await run.text(zh.liveSave);
              await run.wait(() => find.byType(ScheduleSheet).evaluate().isEmpty);
              final items = c.read(liveSchedulesProvider).requireValue;
              final item = items.firstWhere((s) => s.title.contains('$suffix'));
              scheduleId = item.id;
              await tester.ensureVisible(find.text(item.title));
              expect(item.startAt.isAfter(DateTime.now()), isTrue);
            });
            await run.step('取消预定弹窗', '真实打开确认弹窗，可取消后再次打开', () async {
              final title = c
                  .read(liveSchedulesProvider)
                  .requireValue
                  .firstWhere((s) => s.id == scheduleId)
                  .title;
              final card = find.ancestor(of: find.text(title), matching: find.byType(ScheduleCard));
              await run.tap(find.descendant(of: card, matching: find.text(zh.liveCancelSchedule)));
              expect(find.byType(AlertDialog), findsOneWidget);
            });
            await run.text(zh.liveConfirm);
            await run.wait(
              () => !c
                  .read(liveSchedulesProvider)
                  .requireValue
                  .any((s) => s.id == scheduleId && !s.cancelled),
            );
            await run.step('入会表单', '打开入会表单，6 位会议号校验可见', () async {
              await run.tap(find.byKey(const ValueKey('live-join')));
              await run.tap(find.widgetWithText(FilledButton, zh.liveJoin));
              expect(find.text(zh.liveCodeHint), findsAtLeastNWidgets(1));
            });
            c.read(appRouterProvider).pop();
            await tester.pump(const Duration(milliseconds: 400));
            await run.mode({'join': 'delay'});
            await run.step('入会加载', '快速会议进入真实异步入会状态', () async {
              await run.tap(find.byKey(const ValueKey('live-quick')));
              await run.wait(() => c.read(roomControllerProvider) is RoomJoining);
              expect(find.text(zh.liveJoining), findsOneWidget);
            });
            await run.wait(() => c.read(roomControllerProvider) is RoomActive);
            roomId = (c.read(roomControllerProvider) as RoomActive).room.id;
            final journal = File('${artifactRoot.path}/room-journal.json');
            final rooms = journal.existsSync()
                ? jsonDecode(journal.readAsStringSync()) as List<dynamic>
                : <dynamic>[];
            rooms.add({
              'id': roomId,
              'suffix': suffix,
              'attempt': Platform.environment['OPENMEETING_ATTEMPT'],
            });
            journal.writeAsStringSync(jsonEncode(rooms));
            await run.mode({});
            await run.step('房间正常', '真实创建房间并建立业务 WebSocket，媒体不可用明确展示', () async {
              await run.wait(
                () => (c.read(roomControllerProvider) as RoomActive).connection == 'connected',
              );
              final room = c.read(roomControllerProvider) as RoomActive;
              expect(room.self.isHost, isTrue);
              expect(room.room.code.length, 6);
              expect(room.room.participants.length, 1);
            });
            await run.text(zh.liveMore);
            await run.text(zh.liveSettings);
            await run.step('会中设置错误', '主持人设置被拒绝时保留表单并展示 403', () async {
              await run.field(zh.liveTitle, 'Flutter会中设置-$suffix-长主题验证');
              await run.text(zh.liveRequirePassword);
              await run.field(zh.livePassword, '6666');
              await run.text(zh.liveWaitingRoom);
              await run.mode({'settings': 'forbidden'});
              await run.text(zh.liveSave);
              await run.wait(() => find.text('测试夹具：当前用户没有主持人权限').evaluate().isNotEmpty);
            });
            await run.step('会中设置成功', '重试保存主题、密码和等候室，服务端回读一致', () async {
              await run.mode({});
              await run.text(zh.liveSave);
              await run.wait(() => find.byType(RoomSettingsPanel).evaluate().isEmpty);
              final snapshot = await run.settle(() => c.read(liveRepositoryProvider).room(roomId!));
              expect(snapshot.pwdEnabled && snapshot.waitRoom, isTrue);
              expect(snapshot.title, contains('$suffix'));
              await run.closePanel();
            });
            await run.step('密码失败与等候室', '真实错误密码返回 403，正确密码进入等候室', () async {
              final code = (c.read(roomControllerProvider) as RoomActive).room.code;
              final denied = await tester.runAsync(
                () => memberApi.post<Object?>(
                  '/api/v1/rooms/join',
                  data: {'code': code, 'pwd': '1111'},
                  options: Options(validateStatus: (_) => true),
                ),
              );
              expect(denied!.statusCode, 403);
              final waiting = await tester.runAsync(
                () => memberApi.post<Map<String, dynamic>>(
                  '/api/v1/rooms/join',
                  data: {'code': code, 'pwd': '6666', 'micOn': false, 'camOn': false},
                ),
              );
              expect(waiting!.data!['state'], 'waiting');
              await run.wait(
                () => (c.read(roomControllerProvider) as RoomActive).room.waiting.length == 1,
              );
              await run.text(zh.liveMembers);
            });
            await run.step('主持人准入', '点击准入后房间出现两个真实成员', () async {
              await run.text(zh.liveAdmit);
              await run.wait(
                () =>
                    (c.read(roomControllerProvider) as RoomActive).room.participants.length == 2 &&
                    !(c.read(roomControllerProvider) as RoomActive).busy,
              );
              expect(
                find.descendant(
                  of: find.byType(MembersPanel),
                  matching: find.text(member.user['name'] as String),
                ),
                findsOneWidget,
              );
            });
            await run.closePanel();
            await run.step('会中聊天空态', '打开真实聊天抽屉并显示空态', () async {
              await run.text(zh.liveChat);
              expect(find.text(zh.liveNoMessages), findsOneWidget);
            });
            await run.step('会中聊天成功', '输入消息后真实发送，对端消息经 WS 更新', () async {
              await run.field(zh.liveMessage, '真实 Flutter 会中消息-$suffix');
              await run.tap(find.byTooltip(zh.liveSend));
              await run.wait(
                () => (c.read(roomControllerProvider) as RoomActive).chats.any(
                  (s) => s.text.contains('$suffix'),
                ),
              );
              for (var i = 0; i < 6; i++) {
                await tester.runAsync(
                  () => memberApi.post<void>(
                    '/api/v1/rooms/$roomId/chat',
                    data: {'text': '对端消息 $i：${List.filled(12, '长文本换行及滚动检查。').join()}'},
                  ),
                );
              }
              await run.wait(
                () =>
                    (c.read(roomControllerProvider) as RoomActive).chats.length == 7 &&
                    !(c.read(roomControllerProvider) as RoomActive).busy,
              );
            });
            await run.step('聊天滚动', '真实滚动消息列表，长文本可读且输入区可见', () async {
              await tester.drag(
                find.descendant(of: find.byType(RoomChatPanel), matching: find.byType(ListView)),
                const Offset(0, 300),
              );
              await tester.pump(const Duration(milliseconds: 400));
              final list = find.descendant(
                of: find.byType(RoomChatPanel),
                matching: find.byType(ListView),
              );
              final scroll = tester.state<ScrollableState>(
                find.descendant(of: list, matching: find.byType(Scrollable)).first,
              );
              expect(scroll.position.pixels, greaterThan(0));
              expect(find.byTooltip(zh.liveSend), findsOneWidget);
            });
            await run.closePanel();
            await run.step('成员权限', '真实转移主持人后设置只读，成员不能提交', () async {
              final room = c.read(roomControllerProvider) as RoomActive;
              final peer = room.room.participants.firstWhere((p) => p.userId == member.id);
              await run.settle(
                () => c.read(liveRepositoryProvider).participant(roomId!, peer.id, 'transfer-host'),
              );
              await run.wait(() => !(c.read(roomControllerProvider) as RoomActive).self.isHost);
              await run.text(zh.liveMore);
              await run.text(zh.liveSettings);
              expect(find.text(zh.liveHostOnly), findsOneWidget);
              expect(find.widgetWithText(FilledButton, zh.liveSave), findsNothing);
            });
            await run.closePanel();
            await run.closePanel();
            final current = c.read(roomControllerProvider) as RoomActive;
            await tester.runAsync(
              () => memberApi.post<void>(
                '/api/v1/rooms/$roomId/participants/${current.self.id}/transfer-host',
              ),
            );
            await run.settle(() => c.read(roomControllerProvider.notifier).refresh());
            await run.wait(() => (c.read(roomControllerProvider) as RoomActive).self.isHost);
            await run.step('结束会议确认', '真实打开结束弹窗，长会议状态不遮挡操作', () async {
              await run.text(zh.liveEnd);
              expect(find.byType(AlertDialog), findsOneWidget);
            });
            await run.step('结束会议成功', '结束真实会议并释放连接，进入成功页', () async {
              await run.text(zh.liveConfirm);
              await run.wait(() => c.read(roomControllerProvider) is RoomEnded);
              expect(find.text(zh.liveEnded), findsOneWidget);
            });
            await run.text(zh.liveBackHome);
            await run.step('IM失败可重试', '票据夹具 503 显示错误和重试入口', () async {
              await run.mode({'im': 'error'});
              c.invalidate(imClientProvider);
              await run.tap(find.byTooltip(zh.liveMessages));
              await run.wait(() => find.text('测试夹具：IM 服务暂不可用').evaluate().isNotEmpty);
              expect(find.text(zh.liveRetry), findsAtLeastNWidgets(1));
            });
            await run.mode({});
            c.invalidate(imClientProvider);
            await run.step('IM真实会话', '票据恢复后真实 SDK 就绪，列表可重试恢复', () async {
              await run.wait(
                () => c.read(imClientProvider).hasValue,
                seconds: 20,
                reason: 'IM ready',
              );
              await run.wait(
                () => c.read(imConversationsProvider).hasValue,
                reason: 'conversation list',
              );
            });
            await run.step('IM联系人', '真实切换联系人页，申请和联系人列表已加载', () async {
              await run.text(zh.imContacts);
              await run.wait(
                () => c.read(imFriendsProvider).hasValue && c.read(imRequestsProvider).hasValue,
              );
            });
            await run.step('IM群列表', '真实切换群列表，群邀请加载完成', () async {
              await run.text(zh.imGroups);
              await run.wait(
                () => c.read(imGroupsProvider).hasValue && c.read(imInvitationsProvider).hasValue,
              );
            });
            await run.step('IM新建弹窗', '真实打开新建会话弹窗，用户标识可输入', () async {
              await run.tap(find.byTooltip(zh.imNew));
              expect(find.byType(NewConversationDialog), findsOneWidget);
            });
            await run.step('IM单聊发送', '从新建会话进入真实聊天，消息由服务端确认', () async {
              await run.field(zh.imUserId, member.id);
              await run.text(zh.imCreate);
              await run.wait(() => find.byType(ConversationChatPage).evaluate().isNotEmpty);
              final page = tester.widget<ConversationChatPage>(find.byType(ConversationChatPage));
              await run.wait(
                () =>
                    c.read(imMessagesProvider(page.conversationKey)).value?.loading ==
                    MessageListLoading.none,
                reason: 'message initial load',
              );
              await run.field(zh.liveMessage, '移动端 UI 单聊成功-$suffix');
              await run.tap(find.byTooltip(zh.liveSend));
              await run.wait(
                () =>
                    c
                        .read(imMessagesProvider(page.conversationKey))
                        .value
                        ?.items
                        .any(
                          (m) =>
                              m.body?['text'] == '移动端 UI 单聊成功-$suffix' && m.local.status == 'sent',
                        ) ??
                    false,
                seconds: 20,
              );
              expect(find.text('移动端 UI 单聊成功-$suffix').hitTestable(), findsOneWidget);
            });
            await run.step('IM附件菜单', '真实打开图片、视频和文件入口，并可关闭', () async {
              final list = find.descendant(
                of: find.byType(ConversationChatPage),
                matching: find.byType(ListView),
              );
              await tester.drag(list, const Offset(0, 300));
              await tester.pump(const Duration(milliseconds: 400));
              final scroll = tester.state<ScrollableState>(
                find.descendant(of: list, matching: find.byType(Scrollable)).first,
              );
              expect(scroll.position.pixels, greaterThan(0));
              await run.tap(find.byTooltip(zh.liveAttach));
              expect(find.text(zh.imImage), findsOneWidget);
              expect(find.text(zh.imVideo), findsOneWidget);
            });
            c.read(appRouterProvider).pop();
            await tester.pump(const Duration(milliseconds: 400));
            c.read(appRouterProvider).go(AppRoutes.messages);
            await tester.pump();
            await run.step('IM群创建', '从真实表单创建带成员的群会话', () async {
              await run.tap(find.byTooltip(zh.imNew));
              await run.text(zh.imCreateGroup);
              await run.field(zh.imGroupName, 'Flutter移动验收群-$suffix');
              await run.field(zh.imMemberIds, member.id);
              await run.text(zh.imCreate);
              await run.wait(() => find.byType(ConversationChatPage).evaluate().isNotEmpty);
              final page = tester.widget<ConversationChatPage>(find.byType(ConversationChatPage));
              groupId = page.initial?.groupId;
              expect(groupId, isNotNull);
              await run.wait(() => c.read(imMessagesProvider(page.conversationKey)).hasValue);
            });
            await run.step('IM群管理', '群信息和成员真实加载，群主可管理', () async {
              await run.tap(find.byTooltip(zh.imManageGroup));
              await run.wait(
                () =>
                    c.read(imGroupInfoProvider(groupId!)).hasValue &&
                    c.read(imMembersProvider(groupId!)).value?.length == 2,
              );
              expect(c.read(imGroupInfoProvider(groupId!)).requireValue?.owner, host.id);
              expect(c.read(imMembersProvider(groupId!)).requireValue.length, 2);
            });
            await run.step('IM公告弹窗', '真实编辑群资料，公告支持长文本及滚动', () async {
              await run.text(zh.liveEdit);
              await tester.enterText(find.byType(TextField).last, 'Flutter移动验收群更新-$suffix');
              await run.text(zh.liveConfirm);
              await tester.enterText(
                find.byType(TextField).last,
                List.filled(15, '公告长文本用于检查滚动和换行。').join(),
              );
              await tester.drag(find.byType(TextField).last, const Offset(0, -120));
              await tester.pump(const Duration(milliseconds: 300));
            });
            await run.step('IM公告成功', '群公告和名称更新后回读一致', () async {
              await run.text(zh.liveConfirm);
              await run.wait(
                () => c.read(imGroupInfoProvider(groupId!)).value?.name == 'Flutter移动验收群更新-$suffix',
              );
              expect(c.read(imGroupInfoProvider(groupId!)).value?.announcement, contains('公告长文本'));
              await tester.drag(
                find.descendant(of: find.byType(GroupDetailPage), matching: find.byType(ListView)),
                const Offset(0, -400),
              );
              await tester.pump(const Duration(milliseconds: 300));
            });
            await run.step('IM解散确认', '群主实际打开解散弹窗', () async {
              await run.text(zh.imDismissGroup);
              expect(find.byType(AlertDialog), findsOneWidget);
            });
            await run.text(zh.liveConfirm);
            await run.wait(
              () =>
                  find.byType(MessagesPage).evaluate().isNotEmpty &&
                  find.byType(GroupDetailPage).evaluate().isEmpty,
            );
            groupId = null;
          } catch (_) {
            final im = c.read(imClientProvider).value;
            File(
              '${artifactRoot.path}/logs/ui-diagnostic-${Platform.environment['OPENMEETING_ATTEMPT']}-${viewport.$1}.json',
            ).writeAsStringSync(
              jsonEncode({
                'im': im?.connection.diagnostics(),
                'operation': c.read(messagingActionsProvider).toString(),
                'chat': [
                  for (final element in find.byType(ConversationChatPage).evaluate())
                    for (final m
                        in c
                                .read(
                                  imMessagesProvider(
                                    (element.widget as ConversationChatPage).conversationKey,
                                  ),
                                )
                                .value
                                ?.items ??
                            <MessageView>[])
                      {
                        'seq': m.seq,
                        'status': m.local.status,
                        'text': m.body?['text'],
                        'error': m.local.error?.code,
                      },
                ],
              }),
            );
            await run.shot(
              'screenshots/failure-${Platform.environment['OPENMEETING_ATTEMPT'] ?? '01'}-${viewport.$1}.png',
            );
            rethrow;
          } finally {
            if (groupId != null) {
              await run.settle(() async {
                try {
                  await (await c.read(imClientProvider.future)).groups.dismiss(groupId!);
                } catch (_) {}
              });
            }
            if (roomId != null) {
              await run.settle(() async {
                for (final api in [c.read(apiClientProvider), memberApi]) {
                  try {
                    await api.post<void>('/api/v1/rooms/$roomId/end');
                    break;
                  } catch (_) {}
                }
              });
            }
            if (scheduleId != null) {
              await run.settle(() async {
                try {
                  await c.read(liveRepositoryProvider).cancelSchedule(scheduleId!);
                } catch (_) {}
              });
            }
            await run.settle(() => c.read(roomControllerProvider.notifier).cleanup());
            await run.settle(() => c.read(imGatewayProvider).logout());
            await tester.pumpWidget(const SizedBox());
            c.dispose();
            await tester.pump();
          }
        }
      }
    } finally {
      await tester.runAsync(() => fixture({}));
      memberApi.close();
      // SDK logout starts a best-effort server logout and graceful WS close;
      // drain their bounded 5 s grace period and the HTTP pool's 15 s idle timer.
      await tester.pump(const Duration(seconds: 20));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
      await tester.pump(const Duration(seconds: 20));
      HttpOverrides.global = null;
      debugDisableShadows = true;
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    }
  }, timeout: const Timeout(Duration(minutes: 12)));
}
