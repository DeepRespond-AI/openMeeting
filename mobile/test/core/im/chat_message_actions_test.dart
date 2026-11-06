// Production tile and actions; IM transport, clipboard and identity are fixtures.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:deeprespond_im/deeprespond_im.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meeting/core/auth/session_controller.dart';
import 'package:meeting/core/im/im_gateway.dart';
import 'package:meeting/core/im/messaging_controller.dart';
import 'package:meeting/core/im/widgets/chat_message_tile.dart';
import 'package:meeting/core/im/widgets/user_identity.dart';
import 'package:meeting/core/l10n/l10n.dart';
import 'package:meeting/core/theme/app_theme.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/avatar_fixture.dart';

class ChatAuth extends Mock implements AuthModule {}

class ChatMessages extends Mock implements MessagesModule {}

MessageView message({
  String text = '2',
  String sender = 'self',
  String status = 'sent',
  bool recalled = false,
}) => MessageView({
  'seq': 2,
  'conversation_id': 'chat',
  'client_msg_id': 'c2',
  'sender': sender,
  'type': 'text',
  'body': {'text': text},
  'need_receipt': true,
  'created_at': DateTime.now().toUtc().toIso8601String(),
  '_local': {'status': status},
  if (recalled) 'recalled': {'by': sender},
});

void main() {
  setUpAll(() {
    AvatarFixture.register();
    registerFallbackValue(message());
  });

  for (final width in [390.0, 320.0, 1024.0]) {
    testWidgets('message menu, deletion and recall at $width', (t) async {
      await t.binding.setSurfaceSize(Size(width, 800));
      addTearDown(() => t.binding.setSurfaceSize(null));
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
      final f = AvatarFixture(), auth = ChatAuth(), messages = ChatMessages();
      addTearDown(f.dispose);
      f.me = const SelfProfile({'username': 'self', 'nickname': '135****3130'});
      f.profile('peer', name: '林晓晨');
      when(() => f.client.auth).thenReturn(auth);
      when(() => auth.currentUser).thenReturn(const CurrentUser('self', 'fixture'));
      when(() => f.client.messages).thenReturn(messages);
      when(() => f.client.config).thenReturn(const ClientConfig({'recall_window_seconds': 120}));
      var expired = false, serverExpired = false, failDelete = false;
      var current = message();
      var deleted = false;
      StateSetter? rebuild;
      when(() => messages.canRecall(any())).thenAnswer((_) => !expired);
      when(() => messages.recall('chat', 2)).thenAnswer((_) async {
        if (serverExpired) {
          throw DRException(
            code: 'invalid_state',
            source: ErrorSource.http,
            details: {'reason': 'recall_window_expired'},
          );
        }
        rebuild!(() => current = message(recalled: true));
        return true;
      });
      when(() => messages.deleteForMe('chat', [2])).thenAnswer((_) async {
        if (failDelete) throw StateError('delete fixture failure');
        rebuild!(() => deleted = true);
      });
      when(() => messages.discard('c2')).thenAnswer((_) async {});
      String? copied;
      t.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (
        call,
      ) async {
        if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String;
        return null;
      });
      addTearDown(
        () => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final c = ProviderContainer(
        overrides: [
          imClientProvider.overrideWith((_) async => f.client),
          currentUserProvider.overrideWithValue(null),
        ],
        retry: (_, _) => null,
      );
      addTearDown(c.dispose);
      final boundary = GlobalKey();
      await t.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: RepaintBoundary(
            key: boundary,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              locale: const Locale('zh'),
              localizationsDelegates: localizationsDelegates,
              supportedLocales: appSupportedLocales,
              theme: AppTheme.light(),
              home: Scaffold(
                body: StatefulBuilder(
                  builder: (context, set) {
                    rebuild = set;
                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        ChatMessageTile(
                          message: message(text: '收到，会议资料已更新。', sender: 'peer'),
                          own: false,
                          showTime: true,
                        ),
                        if (!deleted) ChatMessageTile(message: current, own: true, showTime: true),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      Future<void> shot(String name) async {
        await t.pumpAndSettle();
        await t.runAsync(() async {
          final image =
              await (boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary)
                  .toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final dir = Directory('../.artifacts/chat-message-actions/mobile')
            ..createSync(recursive: true);
          File('${dir.path}/${width.toInt()}-$name.png')
              .writeAsBytesSync(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }

      Future<void> menu(String action) async {
        await t.tap(find.byTooltip('消息操作').last);
        await t.pumpAndSettle();
        expect(find.text('复制'), findsOneWidget);
        expect(find.text('删除'), findsOneWidget);
        expect(find.text('撤回'), findsOneWidget);
        expect(find.text('回复'), findsNothing);
        await t.tap(find.text(action));
        await t.pumpAndSettle();
      }

      expect(find.byIcon(Icons.done), findsNothing);
      expect(find.byIcon(Icons.done_all), findsNothing);
      expect(
        t.getCenter(find.byType(ImUserAvatar).last).dx,
        greaterThan(t.getCenter(find.text('2')).dx),
      );
      await shot('bubbles');
      await menu('复制');
      expect(copied, '2');
      // Incoming messages have no recall option.
      await t.tap(find.byTooltip('消息操作').first);
      await t.pumpAndSettle();
      expect(find.text('撤回'), findsNothing);
      await t.tap(find.text('复制'));
      await t.pumpAndSettle();
      expired = true;
      await menu('撤回');
      expect(find.text('无法撤回2分钟前发送的消息'), findsOneWidget);
      verifyNever(() => messages.recall(any(), any()));
      expired = false;
      serverExpired = true;
      await menu('撤回');
      expect(find.text('2'), findsOneWidget);
      serverExpired = false;
      await menu('撤回');
      expect(find.text('你撤回了一条消息'), findsOneWidget);
      expect(find.text('2'), findsNothing);
      expect(find.byType(ImUserAvatar), findsOneWidget);
      await shot('recalled');
      rebuild!(() => current = message(text: 'test'));
      await t.pumpAndSettle();
      await menu('删除');
      expect(find.text('是否删除该消息？'), findsOneWidget);
      await shot('delete-confirm');
      await t.tap(find.text('取消'));
      await t.pumpAndSettle();
      verifyNever(() => messages.deleteForMe(any(), any()));
      await menu('删除');
      failDelete = true;
      await t.tap(find.text('确定'));
      await t.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('test'), findsOneWidget);
      failDelete = false;
      await t.tap(find.text('确定'));
      await t.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('test'), findsNothing);
      expect(find.byTooltip('消息操作'), findsOneWidget);
      await shot('deleted');
      // Pending messages are discarded locally, never recalled or deleted remotely.
      final pending = message(status: 'failed');
      expect(await c.read(messagingActionsProvider.notifier).deleteMessage(pending), isTrue);
      verify(() => messages.discard('c2')).called(1);
      rebuild!(() {
        deleted = false;
        current = message(text: 'LongTextWithoutSpaces'.padRight(800, 'x'));
      });
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      await shot('long-text');
      // Server configuration controls the expiry text, not a hardcoded two minutes.
      when(() => f.client.config).thenReturn(const ClientConfig({'recall_window_seconds': 300}));
      expired = true;
      final result = await c.read(messagingActionsProvider.notifier).recall(message());
      expect(result?.windowSeconds, 300);
      await t.pumpWidget(const SizedBox());
    });
  }
}
