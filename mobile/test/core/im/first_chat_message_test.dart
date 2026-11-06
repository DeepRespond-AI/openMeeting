import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:deeprespond_im/deeprespond_im.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meeting/core/auth/session_controller.dart';
import 'package:meeting/core/config/app_config.dart';
import 'package:meeting/core/config/app_config_provider.dart';
import 'package:meeting/core/im/im_gateway.dart';
import 'package:meeting/core/im/messaging_controller.dart';
import 'package:meeting/core/im/widgets/conversation_chat_page.dart';
import 'package:meeting/core/l10n/l10n.dart';
import 'package:meeting/core/theme/app_theme.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/avatar_fixture.dart';
import '../../helpers/initial_chat_fixture.dart';
import '../../helpers/test_config.dart';

class _Messages extends Mock implements MessagesModule {}

class _Auth extends Mock implements AuthModule {}

late AppConfig _config;

Future<void> waitForUi(WidgetTester t, bool Function() ready) async {
  for (var i = 0; i < 100 && !ready(); i++) {
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    await t.pump();
  }
  expect(ready(), isTrue);
}

Future<ProviderContainer> messagesContainer(InitialChatFixture f) async {
  final client = AvatarClient(), messages = _Messages();
  when(() => client.messages).thenReturn(messages);
  when(() => messages.open(any())).thenAnswer((_) => f.open());
  final c = await createTestContainer(
    config: _config,
    overrides: [imClientProvider.overrideWith((_) async => client)],
  );
  final keep = c.listen(imMessagesProvider('first-message-chat'), (_, _) {});
  addTearDown(keep.close);
  return c;
}

Future<MessageListSnapshot> waitForMessages(
  ProviderContainer c,
  bool Function(MessageListSnapshot) ready,
) async {
  for (var i = 0; i < 500; i++) {
    final snapshot = c.read(imMessagesProvider('first-message-chat')).value;
    if (snapshot != null && ready(snapshot)) return snapshot;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  throw StateError('message snapshot did not become ready');
}

void main() {
  setUpAll(() async {
    AvatarFixture.register();
    _config = await loadAppConfig(env: 'dev');
  });
  for (final cache in ['tail', 'preview', 'empty']) {
    testWidgets('opening chat includes the first desktop message (cache=$cache)', (t) async {
      final f = await t.runAsync(
        () => InitialChatFixture.create(seedLatest: cache != 'empty', seedRange: cache == 'tail'),
      );
      addTearDown(f!.dispose);
      final identity = AvatarFixture(), messages = _Messages(), auth = _Auth();
      addTearDown(identity.dispose);
      identity.profile('desktop', name: '桌面用户');
      when(() => identity.client.auth).thenReturn(auth);
      when(() => auth.currentUser).thenReturn(const CurrentUser('mobile', 'fixture'));
      when(() => identity.client.messages).thenReturn(messages);
      when(() => messages.open(any())).thenAnswer((_) => f.open());
      when(() => identity.client.config).thenReturn(const ClientConfig({}));
      final c = await createTestContainer(
        config: _config,
        overrides: [
          imClientProvider.overrideWith((_) async => identity.client),
          imConversationProvider('first-message-chat').overrideWith((_) async => null),
          currentUserProvider.overrideWithValue(null),
        ],
      );
      final boundary = GlobalKey();
      final app = UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('zh'),
          localizationsDelegates: localizationsDelegates,
          supportedLocales: appSupportedLocales,
          home: RepaintBoundary(
            key: boundary,
            child: const ConversationChatPage(conversationKey: 'first-message-chat', meeting: true),
          ),
        ),
      );
      await t.pumpWidget(app);
      addTearDown(() async {
        await t.pumpWidget(const SizedBox());
        await t.pump();
      });
      await waitForUi(t, () => find.text('桌面消息-1').evaluate().isNotEmpty);
      expect(f.lists.single.snapshot.error, isNull);
      expect(find.text('桌面消息-1'), findsOneWidget);
      expect(find.text('桌面消息-2'), findsOneWidget);
      expect(
        c.read(imMessagesProvider('first-message-chat')).requireValue.items.map((m) => m.seq),
        [1, 2],
      );
      f.count = 3;
      await t.runAsync(() => f.write([incoming(3)]));
      await waitForUi(t, () => find.text('桌面消息-3').evaluate().isNotEmpty);
      expect(find.text('桌面消息-1'), findsOneWidget);
      expect(find.text('桌面消息-2'), findsOneWidget);
      if (const bool.fromEnvironment('FIRST_CHAT_CAPTURE')) {
        await t.pumpAndSettle();
        await t.runAsync(() async {
          final image =
              await (boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary)
                  .toImage();
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          await File('${Directory.systemTemp.path}/first-chat-$cache.png')
              .writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }
      await t.pumpWidget(const SizedBox());
      await t.pump();
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await t.pumpWidget(app);
      await waitForUi(t, () => find.text('桌面消息-1').evaluate().isNotEmpty);
      expect(find.text('桌面消息-2'), findsOneWidget);
      expect(find.text('桌面消息-3'), findsOneWidget);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    });
  }

  test('initial fill stays bounded; explicit older loading still works', () async {
    final f = await InitialChatFixture.create(count: 80);
    addTearDown(f.dispose);
    final c = await messagesContainer(f);
    await waitForMessages(c, (s) => s.items.length > 1);
    final list = await c.read(imMessageListProvider('first-message-chat').future);
    expect(list.snapshot.items.first.seq, greaterThan(1));
    expect(list.snapshot.items.last.seq, 80);
    expect(list.snapshot.items.length, lessThanOrEqualTo(51));
    expect(list.snapshot.hasOlder, isTrue);
    await list.loadOlder();
    expect(list.snapshot.items.first.seq, 1);
    expect(list.snapshot.items.last.seq, 80);
  });

  test('fresh empty chat displays its very first incoming message', () async {
    final f = await InitialChatFixture.create(seedLatest: false, count: 0);
    addTearDown(f.dispose);
    final c = await messagesContainer(f);
    await waitForMessages(c, (s) => s.loading == MessageListLoading.none);
    final list = await c.read(imMessageListProvider('first-message-chat').future);
    expect(list.snapshot.items, isEmpty);
    final received = list.stream.firstWhere((s) => s.items.isNotEmpty);
    await f.write([incoming(1)]);
    expect((await received).items.single.seq, 1);
  });

  test('catch-up failure is exposed instead of leaving the chat loading forever', () async {
    final f = await InitialChatFixture.create()
      ..failCatchUp = true;
    addTearDown(f.dispose);
    final c = await messagesContainer(f);
    final snapshot = await waitForMessages(c, (s) => s.error != null);
    expect(snapshot.error, isNotNull);
    expect(snapshot.loading, MessageListLoading.none);
  });

  test('cached messages stay visible while initial catch-up is pending', () async {
    final f = await InitialChatFixture.create();
    f.catchUpGate = Completer<void>();
    addTearDown(f.dispose);
    final c = await messagesContainer(f);
    final cached = await waitForMessages(c, (s) => s.items.isNotEmpty);
    expect(cached.items.single.seq, 2);
    expect(cached.loading, MessageListLoading.initial);
    f.catchUpGate!.complete();
    final filled = await waitForMessages(c, (s) => s.items.length == 2);
    expect(filled.items.map((m) => m.seq), [1, 2]);
  });

  test('leaving during initial catch-up disposes the SDK list', () async {
    final f = await InitialChatFixture.create();
    f.catchUpGate = Completer<void>();
    addTearDown(f.dispose);
    final c = await messagesContainer(f);
    final pending = c.read(imMessageListProvider('first-message-chat').future);
    final completion = pending.then<Object?>((_) => null, onError: (Object error) => error);
    while (f.catchUpCalls == 0) {
      await Future<void>.delayed(Duration.zero);
    }
    c.invalidate(imMessageListProvider('first-message-chat'));
    expect(f.lists.first.disposed, isTrue);
    f.catchUpGate!.complete();
    await completion;
  });
}
