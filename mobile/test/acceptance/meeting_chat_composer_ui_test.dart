// Production room sheet, chat page, composer and message actions. SDK/attachment seams are explicit.
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
import 'package:meeting/core/api/api_exception.dart';
import 'package:meeting/core/auth/session_controller.dart';
import 'package:meeting/core/im/im_gateway.dart';
import 'package:meeting/core/im/messaging_controller.dart';
import 'package:meeting/core/im/widgets/chat_emoji_picker.dart';
import 'package:meeting/core/im/widgets/meeting_chat_composer.dart';
import 'package:meeting/core/l10n/l10n.dart';
import 'package:meeting/core/theme/app_theme.dart';
import 'package:meeting/features/live_meeting/domain/live_models.dart';
import 'package:meeting/features/live_meeting/presentation/room_controller.dart';
import 'package:meeting/features/live_meeting/presentation/room_page.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/avatar_fixture.dart';
import '../helpers/test_config.dart';

class _Auth extends Mock implements AuthModule {}

class _Messages extends Mock implements MessagesModule {}

class _MessageList extends Mock implements MessageList {}

class _Room extends RoomController {
  @override
  LiveRoomState build() => const LiveRoomState.active(
    room: LiveRoom(
      id: 'composer-room',
      code: '123456789',
      title: '会中聊天输入区',
      hostId: 'self',
      participants: [],
    ),
    self: LiveParticipant(id: 'self', userId: 'self-id', name: '林小明', isSelf: true, isHost: true),
    connection: 'connected',
    media: 'unavailable',
  );
}

class _Fixture {
  _Fixture() {
    when(() => avatar.client.auth).thenReturn(auth);
    when(() => auth.currentUser).thenReturn(const CurrentUser('self-id', 'fixture'));
    when(() => avatar.client.messages).thenReturn(messages);
    when(() => avatar.client.config).thenReturn(const ClientConfig({'recall_window_seconds': 120}));
    when(() => messages.canRecall(any())).thenReturn(false);
    when(() => messages.open('composer-chat')).thenReturn(list);
    when(() => list.snapshot).thenAnswer((_) => snapshot);
    when(() => list.stream).thenAnswer((_) => events.stream);
    when(() => messages.send(any(), any())).thenAnswer((call) async {
      attempts++;
      final target = call.positionalArguments[0] as ConversationTarget;
      expect(target.conversationKey, 'composer-chat');
      final content = call.positionalArguments[1] as TextContent;
      await gate?.future;
      if (failSend) throw const ApiException(kind: ApiErrorKind.unavailable);
      sent.add(content.text);
      final message = MessageView({
        'seq': sent.length,
        'client_msg_id': 'sent-${sent.length}',
        'conversation_id': 'composer-chat',
        'sender': 'self-id',
        'type': 'text',
        'body': {'text': content.text},
        'created_at': DateTime.now().toUtc().toIso8601String(),
        '_local': {'status': 'sent'},
      });
      items.add(message);
      events.add(snapshot);
      return message;
    });
  }
  final avatar = AvatarFixture(), auth = _Auth(), messages = _Messages(), list = _MessageList();
  final events = StreamController<MessageListSnapshot>.broadcast(sync: true);
  final items = <MessageView>[], sent = <String>[], attachments = <String>[];
  bool failSend = false, failAttachment = false;
  int attempts = 0;
  Completer<void>? gate;
  MessageListSnapshot get snapshot => MessageListSnapshot(
    items: [...items],
    gaps: [],
    hasOlder: false,
    hasNewer: false,
    loading: MessageListLoading.none,
    pinned: [],
  );
  Future<ProviderContainer> container() => createTestContainer(
    overrides: [
      imClientProvider.overrideWith((_) async => avatar.client),
      currentUserProvider.overrideWithValue(null),
      imConversationProvider('composer-chat').overrideWith((_) async => null),
      roomControllerProvider.overrideWith(_Room.new),
      roomChatSessionProvider.overrideWith(
        (_) async => ConversationView({'conversation_key': 'composer-chat'}),
      ),
      messagingActionsProvider.overrideWith(() => _Actions(this)),
    ],
  );
  Future<void> dispose() async {
    await events.close();
    await avatar.dispose();
  }
}

// The native picker/upload is outside this layout change. Keep text send/perform real.
class _Actions extends MessagingActions {
  _Actions(this.fixture);
  final _Fixture fixture;
  @override
  Future<void> attachment(String key, String type) => perform((_) async {
    expect(key, 'composer-chat');
    fixture.attachments.add(type);
    if (fixture.failAttachment) throw const ApiException(kind: ApiErrorKind.unavailable);
  }).then((_) {});
}

void main() {
  setUpAll(() {
    AvatarFixture.register();
    registerFallbackValue(const MessageView({'type': 'text', 'sender': 'fixture'}));
    registerFallbackValue(const SendTarget.conversation('composer-chat'));
    registerFallbackValue(const OutgoingContent.text('fixture'));
  });
  final output = Directory(
    Platform.environment['CHAT_COMPOSER_OUTPUT'] ??
        '../.artifacts/mobile-meeting-chat-composer-20261029',
  )..createSync(recursive: true);
  final rows = <Map<String, Object?>>[];
  void emit(Map<String, Object?> row) {
    rows.add(row);
    File('${output.path}/results.json').writeAsStringSync(jsonEncode(rows));
    stdout.writeln(jsonEncode(row));
  }

  test('failure seam independently repeats and recovers before pages run', () async {
    final fixture = _Fixture()..failSend = true;
    final c = await fixture.container();
    final row = <String, Object?>{
      'phase': 'fixture-smoke',
      'operation': '发送失败入口独立冒烟',
      'expected': '503连续触发两次，解除后可发送',
      'pass': false,
      'screenshot': null,
    };
    try {
      final actions = c.read(messagingActionsProvider.notifier);
      for (var i = 0; i < 2; i++) {
        expect(await actions.send('composer-chat', '独立冒烟'), isFalse);
        expect(c.read(messagingActionsProvider).hasError, isTrue);
      }
      fixture.failSend = false;
      expect(await actions.send('composer-chat', '独立冒烟'), isTrue);
      expect(fixture.sent, ['独立冒烟']);
      row.addAll({
        'pass': true,
        'actual': {'attempts': fixture.attempts, 'sent': fixture.sent},
      });
    } catch (e) {
      row['actual'] = '$e';
      rethrow;
    } finally {
      emit(row);
      c.dispose();
      await fixture.dispose();
    }
  });

  testWidgets('meeting chat composer user flow at narrow and desktop viewports', (t) async {
    final budget = File('${output.path}/budget.json');
    if (!budget.existsSync()) {
      budget.writeAsStringSync(
        jsonEncode({'started': DateTime.now().millisecondsSinceEpoch, 'limitMs': 1800000}),
      );
    }
    final started = (jsonDecode(budget.readAsStringSync()) as Map)['started'] as int;
    void checkBudget() {
      if (DateTime.now().millisecondsSinceEpoch - started > 1800000) {
        throw StateError('30-minute cumulative E2E budget exhausted');
      }
    }

    await t.runAsync(() async {
      for (final entry in {
        'Roboto': 'C:/Windows/Fonts/msyh.ttc',
        'Segoe UI Emoji': 'C:/Windows/Fonts/seguiemj.ttf',
      }.entries) {
        final font = File(entry.value);
        if (font.existsSync()) {
          await (FontLoader(
            entry.key,
          )..addFont(Future.value(ByteData.sublistView(await font.readAsBytes())))).load();
        }
      }
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    });
    var number = 0;
    for (final capture in [false, true]) {
      for (final size in [const Size(390, 844), const Size(1024, 768)]) {
        checkBudget();
        t.view.devicePixelRatio = 1;
        t.view.physicalSize = size;
        await t.binding.setSurfaceSize(size);
        final fixture = _Fixture(), c = await fixture.container(), boundary = GlobalKey();
        final l = lookupAppLocalizations(const Locale('zh'));
        final input = find.byKey(const ValueKey('meeting-chat-input'));
        TextEditingController draft() => t.widget<TextField>(input).controller!;
        Future<void> tap(Finder finder) async {
          await t.ensureVisible(finder);
          await t.pumpAndSettle();
          await t.tap(finder);
          await t.pumpAndSettle();
        }

        void aligned() {
          final row = t.getRect(find.byKey(const ValueKey('meeting-chat-composer')));
          final boxes = [
            for (final key in [
              'meeting-chat-attach',
              'meeting-chat-emoji',
              'meeting-chat-input',
              'meeting-chat-send',
            ])
              t.getRect(find.byKey(ValueKey(key))),
          ];
          for (final box in boxes) {
            expect(box.center.dy, closeTo(row.center.dy, 1));
            expect(box.left, greaterThanOrEqualTo(row.left));
            expect(box.right, lessThanOrEqualTo(row.right));
          }
          for (var i = 1; i < boxes.length; i++) {
            expect(boxes[i - 1].right, lessThanOrEqualTo(boxes[i].left));
          }
        }

        Future<void> closeEmoji() => tap(
          find.descendant(of: find.byType(ChatEmojiPicker), matching: find.byTooltip(l.liveClose)),
        );
        Future<void> step(
          String operation,
          String expected,
          Future<void> Function() run, {
          String? shot,
        }) async {
          checkBudget();
          final row = <String, Object?>{
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
            final exception = t.takeException();
            if (exception != null) throw StateError('$exception');
            String preview(String value) =>
                value.characters.length > 80 ? '${value.characters.take(80)}…' : value;
            row['actual'] = {
              'draft': input.evaluate().isEmpty ? null : preview(draft().text),
              'draftLength': input.evaluate().isEmpty ? null : draft().text.characters.length,
              'sent': fixture.sent.map(preview).toList(),
              'attachmentTypes': [...fixture.attachments],
            };
            if (capture && shot != null) {
              final name =
                  'screenshots/${(++number).toString().padLeft(2, '0')}-${size.width.toInt()}-$shot.png';
              await t.runAsync(() async {
                final image =
                    await (boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary)
                        .toImage();
                final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
                final file = File('${output.path}/$name');
                file.parent.createSync(recursive: true);
                file.writeAsBytesSync(bytes!.buffer.asUint8List());
                image.dispose();
              });
              row['screenshot'] = name;
            }
            row['pass'] = true;
          } catch (e) {
            row['actual'] = '$e';
            rethrow;
          } finally {
            emit(row);
          }
        }

        try {
          await t.pumpWidget(
            UncontrolledProviderScope(
              container: c,
              child: RepaintBoundary(
                key: boundary,
                child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.dark().copyWith(
                    textTheme: AppTheme.dark().textTheme.apply(
                      fontFamilyFallback: const ['Segoe UI Emoji'],
                    ),
                  ),
                  locale: const Locale('zh'),
                  localizationsDelegates: localizationsDelegates,
                  supportedLocales: appSupportedLocales,
                  home: Builder(
                    builder: (context) => Scaffold(
                      body: Center(
                        child: TextButton(
                          onPressed: () => roomSheet(context, const RoomChatPanel()),
                          child: Text(l.liveChat),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await t.pumpAndSettle();
          await step('打开会中聊天', '真实聊天抽屉打开，附件、表情、输入、发送同一行，无停止播放和语音按钮', () async {
            await tap(find.text(l.liveChat));
            expect(find.byType(MeetingChatComposer), findsOneWidget);
            expect(find.text(l.imStopPlayback), findsNothing);
            expect(find.byIcon(Icons.mic_none), findsNothing);
            expect(find.text(l.liveChatMessageHint), findsOneWidget);
            expect(find.text(l.liveNoMessages), findsOneWidget);
            expect(find.text('0/2000'), findsNothing);
            aligned();
          }, shot: 'normal-empty');
          await step('键盘弹起布局', '模拟键盘占用后输入行仍在可视区域，图标与输入保持同一行', () async {
            await t.enterText(input, '键盘输入');
            t.view.viewInsets = const FakeViewPadding(bottom: 280);
            await t.pumpAndSettle();
            aligned();
            expect(
              t.getRect(find.byKey(const ValueKey('meeting-chat-composer'))).bottom,
              lessThanOrEqualTo(size.height - 280),
            );
          }, shot: 'keyboard-insets');
          await step('打开表情面板', '表情可从输入光标位置插入，三类标签可见', () async {
            t.view.resetViewInsets();
            await t.enterText(input, 'AB');
            draft().selection = const TextSelection.collapsed(offset: 1);
            await tap(find.byTooltip(l.liveChatEmoji));
            expect(find.byType(ChatEmojiPicker), findsOneWidget);
            expect(find.text(l.liveChatEmojiFaces), findsOneWidget);
            expect(find.text(l.liveChatEmojiGestures), findsOneWidget);
            expect(find.text(l.liveChatEmojiSymbols), findsOneWidget);
          }, shot: 'emoji-open');
          await step('选择并滚动表情', '笑脸插入光标位置，表情列表可以滚动到底部', () async {
            await tap(find.text('😀'));
            expect(draft().text, 'A😀B');
            final grid = find.byType(GridView).first;
            await t.drag(grid, const Offset(0, -220));
            await t.pumpAndSettle();
            expect(find.text('🤔').hitTestable(), findsOneWidget);
          }, shot: 'emoji-scrolled');
          await step('切换表情类别', '手势标签能切换并选择表情', () async {
            await tap(find.text(l.liveChatEmojiGestures));
            await tap(find.text('👍'));
            expect(draft().text, 'A😀👍B');
          }, shot: 'emoji-gestures');
          await step('关闭表情面板', '关闭后返回输入区并保留文字和表情', () async {
            await closeEmoji();
            expect(find.byType(ChatEmojiPicker), findsNothing);
            expect(draft().text, 'A😀👍B');
            aligned();
          }, shot: 'draft');
          await step('发送中防重复操作', '发送中禁用输入、附件和表情，进度显示且保持布局', () async {
            fixture.gate = Completer<void>();
            await t.tap(find.byTooltip(l.liveSend));
            await t.pump();
            await t.pump(const Duration(milliseconds: 100));
            expect(t.widget<TextField>(input).enabled, isFalse);
            expect(
              t.widget<IconButton>(find.byKey(const ValueKey('meeting-chat-emoji'))).onPressed,
              isNull,
            );
            expect(find.byType(CircularProgressIndicator), findsOneWidget);
            aligned();
          }, shot: 'sending');
          await step('发送文字和表情成功', 'SDK收到完整内容，消息回显且草稿清空', () async {
            fixture.gate!.complete();
            fixture.gate = null;
            await t.pumpAndSettle();
            expect(fixture.sent, ['A😀👍B']);
            expect(draft().text, isEmpty);
            expect(find.text('A😀👍B'), findsOneWidget);
          }, shot: 'sent');
          await step('发送失败保留草稿', '确定503显示错误，长文本仍可编辑并重试', () async {
            fixture.failSend = true;
            await t.enterText(input, '长消息用于验证输入框最多三行时附件与表情仍然同一行。' * 8);
            await tap(find.byTooltip(l.liveSend));
            expect(find.text(l.errorUnavailable), findsOneWidget);
            expect(draft().text, isNotEmpty);
            expect(t.widget<TextField>(input).enabled, isTrue);
            aligned();
          }, shot: 'send-error-long-text');
          await step('重试发送成功', '失败解除后原草稿成功发送并清空错误', () async {
            fixture.failSend = false;
            await tap(find.byTooltip(l.liveSend));
            expect(fixture.sent.length, 2);
            expect(draft().text, isEmpty);
            expect(find.text(l.errorUnavailable), findsNothing);
          });
          await step('打开附件菜单', '同一行附件按钮可以打开图片、视频、文件菜单', () async {
            await tap(find.byTooltip(l.liveAttach));
            expect(find.text(l.imImage), findsOneWidget);
            expect(find.text(l.imVideo), findsOneWidget);
            expect(find.text(l.imFile), findsOneWidget);
          }, shot: 'attachment-menu');
          await step('选择文件入口', '选择文件派发到现有附件动作，取消草稿不丢失', () async {
            await tap(find.text(l.imFile));
            expect(fixture.attachments, ['file']);
            expect(find.byType(PopupMenuItem<String>), findsNothing);
          });
          await step('附件操作失败', '附件失败可见，输入行仍可编辑', () async {
            fixture.failAttachment = true;
            await t.enterText(input, '附件失败保留草稿');
            await tap(find.byTooltip(l.liveAttach));
            await tap(find.text(l.imFile));
            expect(find.text(l.errorUnavailable), findsOneWidget);
            expect(draft().text, '附件失败保留草稿');
            expect(t.widget<TextField>(input).enabled, isTrue);
          });
          await step('长度上限和表情边界', '输入仍受原长度限制，超限表情不破坏原草稿', () async {
            fixture.failAttachment = false;
            final maximum = t.widget<TextField>(input).maxLength!;
            await t.enterText(input, '测' * maximum);
            await tap(find.byTooltip(l.liveChatEmoji));
            await tap(find.text('😀'));
            expect(draft().text, '测' * maximum);
            await closeEmoji();
          });
          await step('关闭并重新打开聊天', '真实抽屉可关闭再打开，输入区正常且无停止播放入口', () async {
            await tap(find.byTooltip(l.liveClose));
            expect(find.byType(MeetingChatComposer), findsNothing);
            await tap(find.text(l.liveChat));
            expect(find.byType(MeetingChatComposer), findsOneWidget);
            expect(find.text(l.imStopPlayback), findsNothing);
            expect(draft().text, isEmpty);
          });
        } finally {
          t.view.resetViewInsets();
          await t.pumpWidget(const SizedBox.shrink());
          c.dispose();
          await fixture.dispose();
          await t.pump();
        }
      }
    }
    await t.binding.setSurfaceSize(null);
    t.view.resetPhysicalSize();
    t.view.resetDevicePixelRatio();
    File('${output.path}/execution-finished.json').writeAsStringSync(
      jsonEncode({
        'elapsedMs': DateTime.now().millisecondsSinceEpoch - started,
        'limitMs': 1800000,
      }),
    );
  });
}
