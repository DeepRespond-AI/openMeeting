// Production router/pages/controllers, explicit identity/repository/SDK/picker
// seams. The native entry reuses this flow on an isolated Android test package.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:deeprespond_im/deeprespond_im.dart' hide AuthState;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meeting/core/auth/session_controller.dart';
import 'package:meeting/core/config/app_config_provider.dart';
import 'package:meeting/core/im/avatar_controller.dart';
import 'package:meeting/core/im/im_gateway.dart';
import 'package:meeting/core/im/messaging_controller.dart';
import 'package:meeting/core/im/widgets/user_identity.dart';
import 'package:meeting/core/l10n/l10n.dart';
import 'package:meeting/core/router/app_router.dart';
import 'package:meeting/core/theme/app_theme.dart';
import 'package:meeting/core/update/update_controller.dart';
import 'package:meeting/core/widgets/brand_logo.dart';
import 'package:meeting/features/live_meeting/data/live_repository_impl.dart';
import 'package:meeting/features/live_meeting/domain/live_models.dart';
import 'package:meeting/features/live_meeting/domain/live_repository.dart';
import 'package:meeting/features/live_meeting/presentation/room_controller.dart';
import 'package:meeting/features/settings/presentation/settings_providers.dart';
import 'package:mocktail/mocktail.dart';

import '../core/im/avatar_controller_test.dart' show AvatarTestSession;
import '../helpers/avatar_fixture.dart';
import '../helpers/test_config.dart';

class AvatarNetwork extends HttpOverrides {
  final clients = <HttpClient>[];
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    clients.add(client);
    return client;
  }
}

class UiAvatarAuth extends Mock implements AuthModule {}

class UiAvatarMessages extends Mock implements MessagesModule {}

class UiAvatarMessageList extends Mock implements MessageList {}

class UiAvatarRepo extends Mock implements LiveRepository {}

class UiAvatarUpdate extends UpdateController {
  @override
  UpdateState build() => const UpdateState();
}

class UiAvatarRoom extends RoomController {
  @override
  LiveRoomState build() => const LiveRoomState.active(
    room: LiveRoom(
      id: 'avatar-room',
      code: '123456',
      title: '头像与消息验收',
      hostId: 'self',
      participants: [
        LiveParticipant(id: 'self', userId: 'self-id', name: '林小明', isSelf: true, isHost: true),
        LiveParticipant(id: 'peer', userId: 'bd71-technical-id', name: '张同学'),
      ],
      recording: LiveRecording(active: true, epoch: 1),
    ),
    self: LiveParticipant(id: 'self', userId: 'self-id', name: '林小明', isSelf: true, isHost: true),
    connection: 'connected',
    media: 'unavailable',
  );
}

Future<void> runAvatarFlow(
  WidgetTester t, {
  required Uri imageBase,
  required Future<void> Function(Map<String, Object?>) emit,
  required Future<void> Function(String, GlobalKey) screenshot,
  required bool capture,
  bool native = false,
}) async {
  final l = lookupAppLocalizations(const Locale('zh'));
  var count = 0;
  final sizes = native
      ? [
          Size(
            t.view.physicalSize.width / t.view.devicePixelRatio,
            t.view.physicalSize.height / t.view.devicePixelRatio,
          ),
        ]
      : [const Size(390, 844), const Size(1024, 768)];
  for (final size in sizes) {
    await t.binding.setSurfaceSize(size);
    final f = AvatarFixture(),
        repo = UiAvatarRepo(),
        auth = UiAvatarAuth(),
        messages = UiAvatarMessages(),
        list = UiAvatarMessageList();
    f.avatarUrl = imageBase.resolve('/avatar.png?version=2').toString();
    when(() => f.client.auth).thenReturn(auth);
    when(() => auth.currentUser).thenReturn(const CurrentUser('self-id', 'fixture-session'));
    when(() => f.client.messages).thenReturn(messages);
    when(() => messages.canRecall(any())).thenReturn(false);
    when(() => messages.open(any())).thenReturn(list);
    when(() => repo.schedules(any(), any())).thenAnswer((_) async => []);
    DRFile? selected = avatarInput;
    final config = native ? await loadAppConfig() : loadConfigFile('dev');
    final c = await createTestContainer(
      config: config,
      prefs: {'settings.onboardingCompleted': true, 'settings.localeMode': 'zh'},
      overrides: [
        sessionControllerProvider.overrideWith(AvatarTestSession.new),
        updateControllerProvider.overrideWith(UiAvatarUpdate.new),
        imClientProvider.overrideWith((_) async => f.client),
        avatarPickerProvider.overrideWith(
          (_) =>
              () async => selected,
        ),
        liveRepositoryProvider.overrideWithValue(repo),
        roomControllerProvider.overrideWith(UiAvatarRoom.new),
        settingsAppVersionProvider.overrideWith((_) async => '1.0.0-test'),
        roomChatSessionProvider.overrideWith(
          (_) async => ConversationView({
            'conversation_key': 'avatar-chat',
            'conversation_id': 'avatar-chat',
          }),
        ),
        imConversationProvider('avatar-chat').overrideWith((_) async => null),
        imMessagesProvider('avatar-chat').overrideWith(
          (_) => Stream.value(
            const MessageListSnapshot(
              items: [
                MessageView({
                  'type': 'text',
                  'sender': 'bd71-technical-id',
                  'body': {'text': '你好，消息应显示姓名和头像'},
                  'seq': 1,
                }),
                MessageView({
                  'type': 'text',
                  'sender': 'self-id',
                  'body': {'text': '自己的头像会同步更新'},
                  'seq': 2,
                }),
              ],
              gaps: [],
              hasOlder: false,
              hasNewer: false,
              loading: MessageListLoading.none,
              pinned: [],
            ),
          ),
        ),
      ],
    );
    final boundary = GlobalKey();
    Future<void> wait(bool Function() predicate) async {
      for (var i = 0; i < 150; i++) {
        await t.pump(const Duration(milliseconds: 40));
        await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
        if (predicate()) return;
      }
      throw StateError('UI condition timed out');
    }

    Future<void> tap(Finder finder) async {
      await t.ensureVisible(finder.first);
      await t.pump();
      await t.tap(finder.first);
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));
    }

    Future<void> step(
      String operation,
      String expected,
      Future<void> Function() check, {
      String? picture,
    }) async {
      final row = <String, Object?>{
        'platform': native ? 'android' : 'flutter-vm',
        'phase': capture ? 'screenshots' : 'assertions',
        'viewport': '${size.width.toInt()}x${size.height.toInt()}',
        'operation': operation,
        'expected': expected,
        'actual': '',
        'pass': false,
        'screenshot': null,
      };
      try {
        await check();
        row['pass'] = true;
        row['actual'] = '全部断言通过';
        if (capture && picture != null) {
          if (['upload-error', 'uploading', 'save-error', 'saved'].contains(picture)) {
            await t.drag(find.byType(ListView).first, const Offset(0, 800));
            await t.pump(const Duration(milliseconds: 400));
            await t.pump();
          }
          final file =
              'screenshots/${native ? 'android' : 'vm'}-${(++count).toString().padLeft(2, '0')}-${size.width.toInt()}-$picture.png';
          await screenshot(file, boundary);
          row['screenshot'] = file;
        }
      } catch (error) {
        row['actual'] = error.toString();
        final file =
            'screenshots/${native ? 'android' : 'vm'}-${++count}-${size.width.toInt()}-failure.png';
        try {
          await screenshot(file, boundary);
          row['screenshot'] = file;
        } on Object {
          /* keep the original failure */
        }
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
      await step('隐藏会议录制按钮', '更多菜单没有会议录制入口，自动录音状态仍保留', () async {
        await tap(find.text(l.liveMore));
        expect(find.text(l.liveRecordingTitle), findsNothing);
        expect(find.text(l.liveSettings), findsOneWidget);
      }, picture: 'more');
      await tap(find.byTooltip(l.liveClose));
      await tap(find.text(l.liveChat));
      await wait(() => find.byType(ImMessageSender).evaluate().length == 2);
      await step('聊天初次资料缺失', '用参会姓名及本人姓名占位，不显示内部ID', () async {
        expect(find.text('bd71-technical-id'), findsNothing);
        expect(find.text('self-id'), findsNothing);
        expect(find.byType(ImUserAvatar), findsNWidgets(2));
        expect(find.text('林小明'), findsOneWidget);
      });
      const longName = '张同学 · 研发产品讨论组与超长姓名显示检查';
      await step('资料异步更新', 'SDK资料事件更新姓名与头像，无需退出聊天', () async {
        f.profile(
          'bd71-technical-id',
          name: longName,
          avatar: imageBase.resolve('/avatar.png').toString(),
        );
        await wait(() => find.text(longName).evaluate().isNotEmpty);
      }, picture: 'chat');
      await step('无效头像地址', '图片加载失败使用姓名首字占位，消息仍可见', () async {
        f.profile(
          'bd71-technical-id',
          name: longName,
          avatar: imageBase.resolve('/missing.png').toString(),
        );
        await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
        await t.pump();
        expect(find.text('你好，消息应显示姓名和头像'), findsOneWidget);
        expect(find.byType(ErrorWidget), findsNothing);
        expect(
          find.descendant(
            of: find.byWidgetPredicate(
              (widget) => widget is ImUserAvatar && widget.username == 'bd71-technical-id',
            ),
            matching: find.text('张'),
          ),
          findsOneWidget,
        );
      });
      router.go(AppRoutes.settings);
      await t.pumpAndSettle();
      final change = find.byKey(const ValueKey('change-avatar'));
      await step('取消选图', '取消不上传，不改原头像', () async {
        selected = null;
        await tap(change);
        expect(f.uploads, 0);
        expect(f.me.avatarUrl, '');
      });
      await step('图片类型校验', '假图片在上传前拒绝并显示原因', () async {
        selected = DRFile.fromBytes(Uint8List.fromList([1, 2, 3]), name: 'wrong.png');
        await tap(change);
        expect(find.text(l.settingsAvatarType), findsOneWidget);
        expect(f.uploads, 0);
      });
      await step('图片大小校验', '超限在上传前拒绝，不读取或上传任意大文件', () async {
        selected = DRFile.fromBytes(Uint8List(5242881), name: 'large.png');
        await tap(change);
        expect(find.text(l.settingsAvatarSize(5)), findsOneWidget);
        expect(f.uploads, 0);
      });
      await step('上传失败', '明确显示错误，保留原头像并可重试', () async {
        selected = avatarInput;
        f.uploadError = true;
        await tap(change);
        await wait(() => c.read(avatarControllerProvider).failure == AvatarFailure.upload);
        expect(find.text(l.settingsAvatarUploadFailed), findsOneWidget);
        expect(f.me.avatarUrl, '');
      }, picture: 'upload-error');
      await step('上传中', '显示进度，禁止重复操作', () async {
        f.uploadError = false;
        f.uploadGate = Completer<FileInfo>();
        f.saveGate = Completer<void>();
        await tap(change);
        await wait(() => c.read(avatarControllerProvider).phase == AvatarPhase.uploading);
        expect(c.read(avatarControllerProvider).progress, .5);
        expect(t.widget<ListTile>(change).enabled, false);
      }, picture: 'uploading');
      await step('保存中', '上传完成后等待资料保存，不提前显示成功', () async {
        f.uploadGate!.complete(FileInfo({'url': f.avatarUrl}));
        await wait(() => c.read(avatarControllerProvider).phase == AvatarPhase.saving);
        expect(find.text(l.settingsAvatarSaved), findsNothing);
      });
      await step('保存失败', '资料保存失败保留原头像，提供重试', () async {
        f.saveError = true;
        f.saveGate!.complete();
        await wait(() => c.read(avatarControllerProvider).failure == AvatarFailure.save);
        expect(find.text(l.settingsAvatarSaveFailed), findsOneWidget);
        expect(f.me.avatarUrl, '');
      }, picture: 'save-error');
      await step('修改头像成功', '重试通过公开头像用途上传并保存IM资料', () async {
        f.uploadGate = null;
        f.saveGate = null;
        f.saveError = false;
        await tap(change);
        await wait(() => c.read(avatarControllerProvider).phase == AvatarPhase.saved);
        expect(f.lastPurpose, UploadPurpose.userAvatar);
        expect(find.text(l.settingsAvatarSaved), findsOneWidget);
      }, picture: 'saved');
      await step('聊天同步新头像', '再次打开会中聊天立即显示新头像及姓名', () async {
        router.go(AppRoutes.liveRoom);
        await t.pumpAndSettle();
        await tap(find.text(l.liveChat));
        await wait(() => find.byType(ImMessageSender).evaluate().length == 2);
        expect(f.me.avatarUrl, f.avatarUrl);
        expect(find.text('self-id'), findsNothing);
        expect(find.text('林小明'), findsOneWidget);
      }, picture: 'chat-updated');
    } finally {
      await t.pumpWidget(const SizedBox.shrink());
      c.dispose();
      await t.pump();
      await f.dispose();
    }
  }
  await t.binding.setSurfaceSize(null);
}

void main() {
  if (Platform.environment['MOBILE_AVATAR_UI'] != '1') return;
  setUpAll(() {
    AvatarFixture.register();
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(const MessageView({}));
  });
  testWidgets('mobile avatar and toolbar assertions then screenshots', (t) async {
    final out = Directory(
      const String.fromEnvironment(
        'E2E_AVATAR_OUT',
        defaultValue: '../.artifacts/mobile-avatar-toolbar',
      ),
    );
    final budgetFile = File('${out.path}/budget.json');
    if (!budgetFile.existsSync()) {
      budgetFile.writeAsStringSync(
        jsonEncode({'started': DateTime.now().millisecondsSinceEpoch, 'limitMinutes': 30}),
      );
    }
    final budget = jsonDecode(budgetFile.readAsStringSync()) as Map;
    final started = budget['started'] as num;
    final limit = budget['limitMs'] as num? ?? 1800000;
    if (DateTime.now().millisecondsSinceEpoch - started > limit) {
      throw StateError('E2E budget exhausted');
    }
    final network = AvatarNetwork();
    HttpOverrides.global = network;
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
    final server = await t.runAsync(() async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        request.response.statusCode = request.uri.path == '/avatar.png' ? 200 : 404;
        request.response.headers.contentType = ContentType('image', 'png');
        if (request.uri.path == '/avatar.png') {
          request.response.add(await File(BrandAssets.logo).readAsBytes());
        }
        await request.response.close();
      });
      return server;
    });
    Future<void> emit(Map<String, Object?> row) async {
      rows.add(row);
      stdout.writeln(jsonEncode(row));
      File('${out.path}/vm-results.json')
          .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(rows));
    }

    Future<void> shot(String name, GlobalKey key) async {
      await t.runAsync(
        () => precacheImage(
          NetworkImage('http://127.0.0.1:${server!.port}/avatar.png'),
          key.currentContext!,
        ),
      );
      await t.pumpAndSettle();
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

    try {
      await runAvatarFlow(
        t,
        imageBase: Uri.parse('http://127.0.0.1:${server!.port}'),
        emit: emit,
        screenshot: shot,
        capture: false,
      );
      await runAvatarFlow(
        t,
        imageBase: Uri.parse('http://127.0.0.1:${server.port}'),
        emit: emit,
        screenshot: shot,
        capture: true,
      );
    } finally {
      await t.runAsync(() => server!.close(force: true));
      for (final client in network.clients) {
        client.close(force: true);
      }
      HttpOverrides.global = null;
      await t.pump();
    }
  });
}
