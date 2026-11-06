// Real App, room controller/page/sheet and SDK MessageList/SQLite. Identity,
// business API, media and message HTTP responses are explicit test seams.
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:deeprespond_im/deeprespond_im.dart' hide AuthState;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:meeting/app.dart';
import 'package:meeting/core/api/api_exception.dart';
import 'package:meeting/core/api/models/auth_models.dart';
import 'package:meeting/core/auth/session_controller.dart';
import 'package:meeting/core/config/app_config.dart';
import 'package:meeting/core/config/app_config_provider.dart';
import 'package:meeting/core/heartbeat/heartbeat_controller.dart';
import 'package:meeting/core/im/im_gateway.dart';
import 'package:meeting/core/im/meeting_record_notices.dart';
import 'package:meeting/core/im/messaging_controller.dart';
import 'package:meeting/core/im/widgets/conversation_chat_page.dart';
import 'package:meeting/core/l10n/l10n.dart';
import 'package:meeting/core/router/app_router.dart';
import 'package:meeting/core/update/update_controller.dart';
import 'package:meeting/features/live_meeting/data/live_repository_impl.dart';
import 'package:meeting/features/live_meeting/domain/live_models.dart';
import 'package:meeting/features/live_meeting/domain/live_repository.dart';
import 'package:meeting/features/live_meeting/presentation/reminder_controller.dart';
import 'package:meeting/features/live_meeting/presentation/room_controller.dart';
import 'package:meeting/features/live_meeting/presentation/room_page.dart';
import 'package:meeting/features/live_meeting/presentation/schedules_controller.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/avatar_fixture.dart';
import '../../helpers/initial_chat_fixture.dart';
import '../../helpers/test_config.dart';

class _Repo extends Mock implements LiveRepository {}

class _ChatRoomController extends RoomController {
  // The media transport is an explicit fixture. Chat subscriptions still use
  // the real controller/SDK; opening the sheet requires a ready room UI.
  void connectFixtureMedia() {
    final current = state;
    if (current is! RoomActive) throw StateError('Expected an admitted fixture room');
    state = current.copyWith(media: 'connected');
  }
}

class _Messages extends Mock implements MessagesModule {}

class _Conversations extends Mock implements ConversationsModule {}

class _Auth extends Mock implements AuthModule {}

class _Session extends SessionController {
  @override
  Future<AuthState> build() async => const AuthState.signedIn(User(id: 'mobile', name: '手机用户'));
}

class _Heartbeat extends HeartbeatController {
  @override
  HeartbeatState build() => const HeartbeatState();
}

class _Updates extends UpdateController {
  @override
  UpdateState build() => const UpdateState();
}

class _Schedules extends LiveSchedules {
  @override
  Future<List<LiveSchedule>> build() async => [];
}

class _Upcoming extends UpcomingSchedules {
  @override
  Future<List<LiveSchedule>> build() async => [];
}

class _Reminders extends LiveReminder {
  @override
  LiveSchedule? build() => null;
}

const _self = LiveParticipant(id: 'mobile-seat', userId: 'mobile', name: '手机用户', isSelf: true);
const _room = LiveRoom(
  id: 'room-chat',
  code: '123456',
  title: '会议消息生命周期',
  hostId: 'desktop-seat',
  participants: [_self],
);

Future<void> _wait(WidgetTester t, bool Function() ready, {String Function()? reason}) async {
  for (var i = 0; i < 500 && !ready(); i++) {
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    await t.pump(const Duration(milliseconds: 20));
  }
  expect(ready(), isTrue, reason: reason?.call());
  expect(t.takeException(), isNull);
}

void main() {
  late AppConfig config;
  setUpAll(() async {
    AvatarFixture.register();
    registerFallbackValue(<String, Object?>{});
    registerFallbackValue(DateTime(2026));
    config = await loadAppConfig(env: 'dev');
  });
  for (final waiting in [false, true]) {
    testWidgets(
      'room receives before chat opens and after closing, minimizing and rejoining (waiting=$waiting)',
      (t) async {
        final f = (await t.runAsync(() => InitialChatFixture.create(seedLatest: false, count: 0)))!;
        addTearDown(f.dispose);
        final identity = AvatarFixture(),
            repo = _Repo(),
            messages = _Messages(),
            conversations = _Conversations(),
            auth = _Auth();
        addTearDown(identity.dispose);
        identity.profile('desktop', name: '桌面用户');
        when(() => identity.client.messages).thenReturn(messages);
        when(() => identity.client.conversations).thenReturn(conversations);
        when(() => identity.client.auth).thenReturn(auth);
        when(() => identity.client.config).thenReturn(const ClientConfig({}));
        when(() => auth.currentUser).thenReturn(const CurrentUser('mobile', 'fixture'));
        when(() => messages.open(any())).thenAnswer((_) => f.open());
        final view = ConversationView({
          'conversation_key': 'first-message-chat',
          'conversation_id': 'first-message-chat',
        });
        when(() => conversations.refresh(any())).thenAnswer((_) async => view);
        when(() => conversations.get(any())).thenAnswer((_) async => view);
        when(() => conversations.remove(any())).thenAnswer((_) async {});
        final events = StreamController<Map<String, dynamic>>.broadcast();
        addTearDown(events.close);
        var waitForAdmission = waiting, chatAttempts = 0;
        when(() => repo.join(any())).thenAnswer(
          (_) async => {
            'room': _room.toJson(),
            'self': _self.toJson(),
            'state': waitForAdmission ? 'waiting' : 'joined',
            'media': {'transport': 'unavailable'},
          },
        );
        when(() => repo.room(any())).thenAnswer((_) async => _room);
        when(() => repo.peek(any())).thenAnswer((_) async => _room);
        when(() => repo.media(any())).thenAnswer((_) async => {'transport': 'unavailable'});
        when(() => repo.events(any())).thenAnswer((_) => events.stream);
        when(() => repo.action(any(), any(), values: any(named: 'values')))
            .thenAnswer((_) async {});
        when(() => repo.chatSession(any())).thenAnswer((_) async {
          chatAttempts++;
          // Independently exercise recovery without ever opening the sheet.
          if (chatAttempts == 1) {
            throw const ApiException(kind: ApiErrorKind.unavailable, statusCode: 503);
          }
          return {'transport': 'dr-im-group', 'groupId': 'group-room-chat'};
        });
        final testConfig = config.copyWith(
          network: config.network.copyWith(
            retry: config.network.retry.copyWith(maxRetries: 1, backoffMs: [0]),
          ),
        );
        final router = GoRouter(
          routes: [
            GoRoute(path: '/', builder: (_, _) => const LiveRoomPage()),
            GoRoute(
              path: '/meetings',
              builder: (_, _) => const Scaffold(body: Text('会议已最小化')),
            ),
          ],
        );
        addTearDown(router.dispose);
        final c = await createTestContainer(
          config: testConfig,
          prefs: {'settings.localeMode': 'zh', 'settings.onboardingCompleted': true},
          overrides: [
            sessionControllerProvider.overrideWith(_Session.new),
            heartbeatControllerProvider.overrideWith(_Heartbeat.new),
            updateControllerProvider.overrideWith(_Updates.new),
            liveReminderProvider.overrideWith(_Reminders.new),
            meetingRecordNoticesProvider.overrideWith((_) => const Stream.empty()),
            liveSchedulesProvider.overrideWith(_Schedules.new),
            upcomingSchedulesProvider.overrideWith(_Upcoming.new),
            liveRepositoryProvider.overrideWithValue(repo),
            roomControllerProvider.overrideWith(_ChatRoomController.new),
            imClientProvider.overrideWith((_) async => identity.client),
            appRouterProvider.overrideWithValue(router),
            imConversationProvider('first-message-chat').overrideWith((_) async => view),
          ],
        );
        await c.read(sessionControllerProvider.future);
        final controller = c.read(roomControllerProvider.notifier);
        final boundary = GlobalKey();
        await t.pumpWidget(
          UncontrolledProviderScope(
            container: c,
            child: RepaintBoundary(key: boundary, child: const App()),
          ),
        );
        addTearDown(() async {
          await t.pumpWidget(const SizedBox());
          await t.pump();
        });
        await t.runAsync(() => controller.join('123456'));
        await t.pump();
        if (waiting) {
          expect(chatAttempts, 0);
          expect(f.lists, isEmpty);
          waitForAdmission = false;
          await t.runAsync(controller.pollWaiting);
        }
        events.add({
          'type': 'connection_state',
          'data': {'state': 'connected'},
        });
        await _wait(
          t,
          () => f.lists.length == 1 && f.lists.single.snapshot.loading == MessageListLoading.none,
          reason: () =>
              'room=${c.read(roomControllerProvider)}; session=${c.read(roomChatSessionProvider)}; attempts=$chatAttempts; lists=${f.lists.length}',
        );
        expect(chatAttempts, 2);
        expect(find.byType(ConversationChatPage), findsNothing);
        expect(f.viewingReports.last.viewing, isFalse);
        expect(f.readCalls, 0);
        f.count = 1;
        await t.runAsync(() => f.write([incoming(1)]));
        await _wait(
          t,
          () => c.read(imMessagesProvider(view.conversationKey)).value?.items.length == 1,
        );
        expect(find.text('桌面消息-1'), findsNothing);

        Future<void> openChat(int count) async {
          await _wait(t, () {
            final current = c.read(roomControllerProvider);
            return current is RoomActive &&
                current.connection == 'connected' &&
                const {'unavailable', 'connected'}.contains(current.media);
          });
          (controller as _ChatRoomController).connectFixtureMedia();
          await t.pumpAndSettle();
          expect(find.byType(RoomToolbar), findsOneWidget);
          await t.tap(find.text(lookupAppLocalizations(const Locale('zh')).liveChat));
          await t.pumpAndSettle();
          await _wait(t, () => find.text('桌面消息-$count').evaluate().isNotEmpty);
          expect(f.lists.where((list) => !list.disposed), hasLength(1));
        }

        Future<void> closeChat() async {
          router.pop();
          await t.pumpAndSettle();
        }

        await openChat(1);
        expect(f.viewingReports.last.viewing, isTrue);
        expect(f.readCalls, greaterThan(0));
        await closeChat();
        expect(f.viewingReports.last.viewing, isFalse);
        final readsBeforeBackgroundMessage = f.readCalls;
        expect(f.lists.single.disposed, isFalse);
        f.count = 2;
        await t.runAsync(() => f.write([incoming(2)]));
        await _wait(
          t,
          () => c.read(imMessagesProvider(view.conversationKey)).value?.items.length == 2,
        );
        expect(f.readCalls, readsBeforeBackgroundMessage);
        await openChat(2);
        expect(find.text('桌面消息-1'), findsOneWidget);
        await closeChat();
        await t.tap(find.byKey(const ValueKey('minimize-live-meeting')));
        await t.pumpAndSettle();
        f.count = 3;
        await t.runAsync(() => f.write([incoming(3)]));
        await _wait(
          t,
          () => c.read(imMessagesProvider(view.conversationKey)).value?.items.length == 3,
        );
        expect(f.lists.single.disposed, isFalse);
        router.go('/');
        await t.pumpAndSettle();
        await openChat(3);
        expect(find.text('桌面消息-1'), findsOneWidget);
        expect(find.text('桌面消息-2'), findsOneWidget);
        if (const bool.fromEnvironment('ROOM_CHAT_CAPTURE')) {
          await t.runAsync(() async {
            final image =
                await (boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary)
                    .toImage();
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            await File('${Directory.systemTemp.path}/room-chat-$waiting.png')
                .writeAsBytes(data!.buffer.asUint8List());
            image.dispose();
          });
        }
        await closeChat();
        await t.runAsync(controller.leave);
        await t.pumpAndSettle();
        await _wait(t, () => f.lists.single.disposed);
        await t.runAsync(() => controller.join('123456'));
        events.add({
          'type': 'connection_state',
          'data': {'state': 'connected'},
        });
        await _wait(
          t,
          () => f.lists.length == 2 && f.lists.last.snapshot.loading == MessageListLoading.none,
        );
        f.count = 4;
        await t.runAsync(() => f.write([incoming(4)]));
        await _wait(
          t,
          () => c.read(imMessagesProvider(view.conversationKey)).value?.items.last.seq == 4,
        );
        await openChat(4);
        expect(chatAttempts, 3);
        await closeChat();
        await t.runAsync(controller.leave);
        await t.pumpWidget(const SizedBox());
        await t.pump();
        c.dispose();
      },
    );
  }
}
