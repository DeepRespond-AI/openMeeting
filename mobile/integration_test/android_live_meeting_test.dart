// Runs on Android with production plugins, storage, RTC and IM.
// The loopback bridge restores an existing, validated test session without
// embedding credentials in source, command arguments, logs or the APK.
import 'package:deeprespond_im/deeprespond_im.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:meeting/app.dart';
import 'package:meeting/core/api/models/auth_models.dart';
import 'package:meeting/core/auth/data/session_store.dart';
import 'package:meeting/core/auth/session_controller.dart';
import 'package:meeting/core/config/app_config_provider.dart';
import 'package:meeting/core/config/settings_store.dart';
import 'package:meeting/core/im/im_gateway.dart';
import 'package:meeting/core/l10n/l10n.dart';
import 'package:meeting/core/router/app_router.dart';
import 'package:meeting/features/live_meeting/domain/live_models.dart';
import 'package:meeting/features/live_meeting/presentation/home_page.dart';
import 'package:meeting/features/live_meeting/presentation/room_controller.dart';
import 'package:meeting/features/live_meeting/presentation/room_page.dart';
import 'package:meeting/features/live_meeting/presentation/schedules_controller.dart';
import 'package:meeting/features/messaging/presentation/messages_page.dart';
import 'package:meeting/features/messaging/presentation/messaging_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Android native meeting and IM flows, then screenshot replay', (t) async {
    const physical = bool.fromEnvironment('E2E_PHYSICAL_DEVICE');
    final bridge = Dio(
      BaseOptions(
        baseUrl: const String.fromEnvironment(
          'E2E_BRIDGE_URL',
          defaultValue: 'http://10.0.2.2:39221',
        ),
      ),
    );
    final proxy = Dio(
      BaseOptions(
        baseUrl: const String.fromEnvironment(
          'E2E_FIXTURE_URL',
          defaultValue: 'http://10.0.2.2:39220',
        ),
      ),
    );
    const captureOnly = bool.fromEnvironment('E2E_CAPTURE_ONLY');
    if (captureOnly) {
      final proof = (await bridge.post<Map<String, dynamic>>('/prior-assertions')).data!;
      expect(proof['passed'], true);
      expect(proof['count'], 40);
    }
    await bridge.post<void>(
      '/start',
      data: {'attempt': const int.fromEnvironment('E2E_ATTEMPT', defaultValue: 1)},
    );
    final config = await loadAppConfig();
    final prefs = await SharedPreferences.getInstance();
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
    bool ready(AsyncValue<Object?> value) => value.hasValue && !value.isLoading && !value.hasError;
    bool composerEmpty() {
      final fields = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == l.liveMessage,
      );
      return fields.evaluate().length == 1 &&
          t.widget<TextField>(fields).controller?.text.isEmpty == true;
    }

    await t.pumpWidget(UncontrolledProviderScope(container: c, child: const App()));
    Future<void> wait(bool Function() predicate, {int seconds = 25}) async {
      final end = DateTime.now().add(Duration(seconds: seconds));
      while (!predicate()) {
        if (DateTime.now().isAfter(end)) throw StateError('Native UI timed out');
        await t.pump(const Duration(milliseconds: 150));
        await Future<void>.delayed(const Duration(milliseconds: 60));
        final error = t.takeException();
        if (error != null) throw StateError('Flutter: $error');
      }
      await t.pump(const Duration(milliseconds: 450));
    }

    Future<void> tap(Finder finder) async {
      await t.pump(const Duration(milliseconds: 350));
      await t.ensureVisible(finder.last);
      await t.tap(finder.last);
      await t.pump(const Duration(milliseconds: 450));
    }

    Future<void> text(String value) => tap(find.text(value));
    Future<void> field(String label, String value) async {
      await t.enterText(
        find.byWidgetPredicate((w) => w is TextField && w.decoration?.labelText == label),
        value,
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await t.pump(const Duration(milliseconds: 350));
    }

    Future<void> mode(Map<String, Object?> values) async {
      await proxy.post<void>('/__fixture/mode', data: values);
    }

    bool capture = false;
    String viewport = '';
    Future<void> step(String label, String expected, Future<void> Function() action) async {
      final start = DateTime.now();
      try {
        await action();
        final error = t.takeException();
        if (error != null) throw StateError('Flutter: $error');
        await t.pump(const Duration(milliseconds: 450));
        await bridge.post<void>(
          '/step',
          data: {
            'action': '$viewport/${capture ? '截图复验' : '断言'}/$label',
            'expected': expected,
            'actual': expected,
            'passed': true,
            'capture': capture,
            'durationMs': DateTime.now().difference(start).inMilliseconds,
          },
        );
      } catch (e) {
        await bridge.post<void>(
          '/step',
          data: {
            'action': '$viewport/失败/$label',
            'expected': expected,
            'actual': e is DioException ? 'HTTP ${e.response?.statusCode}' : e.toString(),
            'passed': false,
            'capture': true,
          },
        );
        rethrow;
      }
    }

    try {
      for (final shot in captureOnly ? [true] : [false, true]) {
        capture = shot;
        for (final wide in [false, true]) {
          viewport = wide ? '宽屏' : '窄屏';
          await bridge.post<void>('/viewport', data: {'wide': wide});
          await t.pump(const Duration(seconds: 2));
          await mode({});
          c.read(appRouterProvider).go(AppRoutes.meetings);
          c.invalidate(liveSchedulesProvider);
          await step('首页正常', '原生存储恢复登录，真实日程加载成功', () async {
            await wait(
              () =>
                  find.byType(LiveHomePage).evaluate().isNotEmpty &&
                  ready(c.read(liveSchedulesProvider)),
            );
            expect(c.read(sessionControllerProvider).value, isA<AuthSignedIn>());
            t.state<ScrollableState>(find.byType(Scrollable).first).position.jumpTo(0);
            await t.pump(const Duration(milliseconds: 450));
          });
          await step('首页错误', '确定性 503 显示错误并可重试', () async {
            await mode({'schedules': 'error'});
            c.invalidate(liveSchedulesProvider);
            await wait(() => c.read(liveSchedulesProvider).hasError);
            await t.scrollUntilVisible(
              find.textContaining('测试夹具：日程服务暂不可用'),
              300,
              scrollable: find.byType(Scrollable).first,
              maxScrolls: 8,
            );
            await wait(() => find.textContaining('测试夹具：日程服务暂不可用').evaluate().isNotEmpty);
          });
          await step('首页空态', '真实页面显示空日程', () async {
            await mode({'schedules': 'empty'});
            await text(l.liveRetry);
            await wait(
              () =>
                  ready(c.read(liveSchedulesProvider)) &&
                  c.read(liveSchedulesProvider).value?.isEmpty == true &&
                  find.text(l.liveNoSchedules).evaluate().isNotEmpty,
            );
            expect(find.text(l.liveNoSchedules), findsOneWidget);
          });
          t.state<ScrollableState>(find.byType(Scrollable).first).position.jumpTo(0);
          await t.pump(const Duration(milliseconds: 450));
          await mode({'join': 'delay'});
          await tap(find.byKey(const ValueKey('live-quick')));
          await step('入会加载', '快速会议显示确定性加载状态', () async {
            expect(c.read(roomControllerProvider), isA<RoomJoining>());
          });
          await step('会议正常', '真实会议建立业务 WebSocket，主持人入会', () async {
            await wait(
              () =>
                  c.read(roomControllerProvider) is RoomActive &&
                  (c.read(roomControllerProvider) as RoomActive).connection == 'connected',
            );
            expect((c.read(roomControllerProvider) as RoomActive).self.isHost, isTrue);
          });
          await mode({});
          await step('原生麦克风', 'Android 麦克风采集开启，服务端 micOn 同步', () async {
            await wait(() => c.read(roomChannelProvider) != null, seconds: 60);
            await text(l.liveMic);
            await wait(
              () =>
                  (c.read(roomControllerProvider) as RoomActive).self.micOn &&
                  !(c.read(roomControllerProvider) as RoomActive).busy,
            );
          });
          await step(
            '原生摄像头',
            physical ? 'Android 真机摄像头开启，服务端 camOn 同步' : 'Android 模拟摄像头开启，服务端 camOn 同步',
            () async {
              await text(l.liveCamera);
              await wait(
                () =>
                    (c.read(roomControllerProvider) as RoomActive).self.camOn &&
                    !(c.read(roomControllerProvider) as RoomActive).busy,
              );
            },
          );
          await text(l.liveMic);
          await text(l.liveCamera);
          await text(l.liveMore);
          await text(l.liveSettings);
          final title = 'Android原生验收-${DateTime.now().millisecondsSinceEpoch}-长主题检查';
          await field(l.liveTitle, title);
          await step('设置错误', '403 保留输入和错误信息', () async {
            await mode({'settings': 'forbidden'});
            await text(l.liveSave);
            await wait(() => find.textContaining('测试夹具：当前用户没有主持人权限').evaluate().isNotEmpty);
          });
          await step('设置成功', '重试保存后主题与服务端状态同步', () async {
            await mode({});
            await text(l.liveSave);
            await wait(() => find.byType(RoomSettingsPanel).evaluate().isEmpty);
            expect((c.read(roomControllerProvider) as RoomActive).room.title, title);
          });
          if (find.byTooltip(l.liveClose).evaluate().isNotEmpty) {
            await tap(find.byTooltip(l.liveClose));
          }
          await text(l.liveChat);
          final message =
              'Android${physical ? '真机' : '模拟器'}真实聊天-${DateTime.now().millisecondsSinceEpoch}';
          await step('聊天空态', '真实打开聊天抽屉', () async {
            expect(find.byType(RoomChatPanel), findsOneWidget);
          });
          await step('聊天成功', '从输入框发送消息，服务端及页面同步', () async {
            await field(l.liveMessage, message);
            await tap(find.byTooltip(l.liveSend));
            await wait(
              () =>
                  (c.read(roomControllerProvider) as RoomActive).chats.any(
                    (m) => m.text == message,
                  ) &&
                  !(c.read(roomControllerProvider) as RoomActive).busy &&
                  composerEmpty(),
            );
            expect(find.text(message), findsOneWidget);
          });
          await tap(find.byTooltip(l.liveClose));
          await step('结束确认', '真实打开结束会议弹窗', () async {
            await text(l.liveEnd);
            expect(find.byType(AlertDialog), findsOneWidget);
          });
          await step('结束成功', '结束本轮创建的会议并释放连接', () async {
            await text(l.liveConfirm);
            await wait(() => c.read(roomControllerProvider) is RoomEnded);
          });
          c.read(appRouterProvider).go(AppRoutes.messages);
          await mode({'im': 'error'});
          c.invalidate(imClientProvider);
          await step('IM错误', '原生 IM 票据失败可重试', () async {
            await wait(() => c.read(imClientProvider).hasError);
          });
          await mode({});
          await text(l.liveRetry);
          await step('原生IM成功', 'DRFlutterPlatform 真实就绪并加载会话', () async {
            await wait(
              () => ready(c.read(imClientProvider)) && ready(c.read(imConversationsProvider)),
              seconds: 60,
            );
            expect(find.byType(MessagesPage), findsOneWidget);
          });
          await step('联系人', '真实切换联系人列表', () async {
            await text(l.imContacts);
            await wait(() => ready(c.read(imFriendsProvider)) && ready(c.read(imRequestsProvider)));
          });
          await step('群列表', '真实切换群列表并加载邀请', () async {
            await text(l.imGroups);
            await wait(
              () => ready(c.read(imGroupsProvider)) && ready(c.read(imInvitationsProvider)),
            );
          });
          await step('新建弹窗', '真实打开新建会话表单并可关闭', () async {
            await tap(find.byTooltip(l.imNew));
            expect(find.byType(NewConversationDialog), findsOneWidget);
          });
          await step('IM单聊发送', '原生 SDK 发送真实消息，获得服务端确认', () async {
            await field(l.imUserId, session['peerId'] as String);
            await text(l.imCreate);
            await wait(() => find.byType(ConversationChatPage).evaluate().isNotEmpty);
            final page = t.widget<ConversationChatPage>(find.byType(ConversationChatPage));
            await wait(
              () =>
                  c.read(imMessagesProvider(page.conversationKey)).value?.loading ==
                  MessageListLoading.none,
            );
            final message = 'Android原生IM验收-${DateTime.now().millisecondsSinceEpoch}';
            await field(l.liveMessage, message);
            await tap(find.byTooltip(l.liveSend));
            await wait(
              () =>
                  (c
                          .read(imMessagesProvider(page.conversationKey))
                          .value
                          ?.items
                          .any((m) => m.body?['text'] == message && m.local.status == 'sent') ??
                      false) &&
                  composerEmpty(),
            );
            expect(find.text(message).hitTestable(), findsOneWidget);
          });
          await step('附件菜单', '真实打开原生附件入口并关闭', () async {
            await tap(find.byTooltip(l.liveAttach));
            expect(find.text(l.imImage), findsOneWidget);
            expect(find.text(l.imVideo), findsOneWidget);
          });
          c.read(appRouterProvider).pop();
          await t.pump(const Duration(milliseconds: 400));
          c.read(appRouterProvider).pop();
          await t.pump(const Duration(milliseconds: 400));
        }
      }
    } finally {
      await mode({});
      if (c.read(roomControllerProvider) is RoomActive) {
        await c.read(roomControllerProvider.notifier).leave(end: true);
      }
      await c.read(imGatewayProvider).logout();
      await c.read(sessionStoreProvider).clear();
      await t.pumpWidget(const SizedBox.shrink());
      c.dispose();
      await bridge.post<void>('/viewport', data: {'wide': false});
      proxy.close();
      bridge.close();
    }
  }, timeout: const Timeout(Duration(minutes: 25)));
}
