import 'dart:async';
import 'dart:convert';

import 'package:deeprespond_im/deeprespond_im.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meeting/core/auth/session_controller.dart';
import 'package:meeting/core/im/im_gateway.dart';
import 'package:meeting/core/im/rtc_session_release.dart';
import 'package:meeting/features/live_meeting/data/live_repository_impl.dart';
import 'package:meeting/features/live_meeting/domain/live_models.dart';
import 'package:meeting/features/live_meeting/domain/live_repository.dart';
import 'package:meeting/features/live_meeting/presentation/room_controller.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_config.dart';

class Repo extends Mock implements LiveRepository {}

class Client extends Mock implements DRClient {}

class Channels extends Mock implements ChannelsModule {}

class Handle extends Mock implements ChannelHandle {}

const participant = LiveParticipant(id: 'p', userId: 'u', name: 'Guest', isSelf: true);
const testRoom = LiveRoom(
  id: 'race-room',
  code: '123456',
  title: 'Race room',
  hostId: 'host',
  participants: [participant],
);
const mediaConfig = <String, dynamic>{
  'transport': 'dr-rtc',
  'channelId': 'race-room',
  'ticket': 'fixture',
};

/// SDK/network boundaries are explicit. The real controller owns cleanup,
/// generation checks, join/resume and the actual SDK cancel token.
class RaceHarness {
  final repo = Repo(), client = Client(), channels = Channels();
  final events = StreamController<Map<String, dynamic>>.broadcast();
  final calls = <String>[];
  late ProviderContainer container;
  RoomController get controller => container.read(roomControllerProvider.notifier);
  RoomActive get active => container.read(roomControllerProvider) as RoomActive;

  Future<void> init({int? releaseTimeoutMs, bool autoCleanup = true}) async {
    when(() => client.channels).thenReturn(channels);
    when(() => channels.supported).thenReturn(true);
    when(channels.getCurrentSession).thenAnswer((_) async => null);
    when(() => repo.join(any())).thenAnswer(
      (_) async => {
        'room': jsonDecode(jsonEncode(testRoom.toJson())),
        'self': participant.toJson(),
        'state': 'joined',
        'media': mediaConfig,
      },
    );
    when(() => repo.room(any())).thenAnswer((_) async => testRoom);
    when(() => repo.events(any())).thenAnswer((_) => events.stream);
    when(() => repo.media(any())).thenAnswer((_) async => mediaConfig);
    when(() => repo.action(any(), any())).thenAnswer((_) async {
      calls.add('business-leave');
    });
    final config = loadConfigWithServer('http://server.test');
    container = await createTestContainer(
      config: releaseTimeoutMs == null
          ? config
          : config.copyWith(live: config.live.copyWith(rtcReleaseTimeoutMs: releaseTimeoutMs)),
      secure: {
        'session.token': 'fixture',
        'session.user': '{"id":"u","name":"Guest"}',
        'session.serverUrl': 'http://server.test',
      },
      overrides: [
        liveRepositoryProvider.overrideWithValue(repo),
        imClientProvider.overrideWith((_) async => client),
      ],
    );
    await container.read(sessionControllerProvider.future);
    if (autoCleanup) {
      addTearDown(() async {
        await controller.cleanup();
        await events.close();
      });
    }
  }

  Handle handle(String name, {Future<void>? release}) {
    final h = Handle();
    when(h.leave).thenAnswer((_) async {
      calls.add('leave-$name');
      await release;
      calls.add('left-$name');
    });
    when(() => h.currentTracks).thenReturn([]);
    when(() => h.tracks).thenAnswer((_) => const Stream.empty());
    when(() => h.stream).thenAnswer(
      (_) => Stream.value(
        ChannelSnapshot(
          channel: const RTCChannel({'channel_id': 'race-room'}),
          session: ChannelSession({'session_id': name, 'status': 'joined'}),
          mediaState: 'connected',
        ),
      ),
    );
    return h;
  }
}

Future<void> flush() => Future<void>.delayed(Duration.zero);

void main() {
  setUpAll(() {
    registerFallbackValue(<String, Object?>{});
    registerFallbackValue(const ChannelJoinOptions());
    registerFallbackValue(DRCancelToken());
  });

  test(
    'next business room opens immediately while only RTC waits for old attach release',
    () async {
      final h = RaceHarness();
      await h.init();
      final old = Completer<ChannelHandle>(), close = Completer<void>();
      final oldHandle = h.handle('old', release: close.future), next = h.handle('new');
      DRCancelToken? firstCancel;
      var joins = 0;
      when(() => h.channels.join(any(), options: any(named: 'options'))).thenAnswer((call) {
        joins++;
        final options = call.namedArguments[#options] as ChannelJoinOptions;
        if (joins == 1) {
          firstCancel = options.cancel;
          return old.future;
        }
        return Future.value(next);
      });
      final nextRoom = testRoom.copyWith(id: 'next-room', code: '654321');
      when(() => h.repo.room(nextRoom.id)).thenAnswer((_) async => nextRoom);
      when(() => h.repo.join(any())).thenAnswer((call) async {
        final second = (call.positionalArguments.first as Map)['code'] == '654321';
        return {
          'room': jsonDecode(jsonEncode((second ? nextRoom : testRoom).toJson())),
          'self': participant.toJson(),
          'state': 'joined',
          'media': {...mediaConfig, 'channelId': second ? nextRoom.id : testRoom.id},
        };
      });
      await h.controller.join('123456');
      await flush();
      expect(joins, 1);
      h.controller.reset();
      final rejoin = h.controller.join('654321');
      await rejoin.timeout(const Duration(seconds: 1));
      await flush();
      expect(h.active.room.id, 'next-room');
      expect(firstCancel!.isCancelled, true);
      expect(joins, 1);
      old.complete(oldHandle);
      await flush();
      expect(h.calls, contains('leave-old'));
      expect(joins, 1);
      close.complete();
      await rejoin;
      await flush();
      expect(joins, 2);
      expect(h.container.read(roomChannelProvider), same(next));
      expect(h.active.media, 'connected');
      expect(h.calls.where((c) => c == 'leave-new'), isEmpty);
    },
  );

  test('member leave while SDK join is pending then rejoin gets a fresh attach', () async {
    final h = RaceHarness();
    await h.init();
    final pending = Completer<ChannelHandle>();
    final old = h.handle('old'), next = h.handle('next');
    var joins = 0;
    when(() => h.channels.join(any(), options: any(named: 'options')))
        .thenAnswer((_) => ++joins == 1 ? pending.future : Future.value(next));
    await h.controller.join('123456');
    await flush();
    final leaving = h.controller.leave();
    await flush();
    expect(h.calls, contains('business-leave'));
    expect(await leaving.timeout(const Duration(seconds: 1)), true);
    expect(h.container.read(roomControllerProvider), isA<RoomEnded>());
    await h.controller.join('123456');
    expect(h.active.room.id, testRoom.id);
    expect(joins, 1);
    pending.complete(old);
    await flush();
    expect(joins, 2);
    expect(h.container.read(roomChannelProvider), same(next));
  });

  test('cancelled session lookup cannot start a late SDK join', () async {
    final h = RaceHarness();
    await h.init();
    final query = Completer<ChannelSession?>();
    when(h.channels.getCurrentSession).thenAnswer((_) => query.future);
    await h.controller.join('123456');
    await flush();
    await h.controller.cleanup();
    query.complete(null);
    await flush();
    verifyNever(() => h.channels.join(any(), options: any(named: 'options')));
    expect(h.container.read(roomChannelProvider), null);
  });

  test('repeated cleanup awaits old SDK close without blocking business join', () async {
    final h = RaceHarness();
    await h.init();
    final closing = Completer<void>();
    var joins = 0;
    final old = h.handle('old', release: closing.future), next = h.handle('new');
    when(() => h.channels.join(any(), options: any(named: 'options')))
        .thenAnswer((_) async => ++joins == 1 ? old : next);
    await h.controller.join('123456');
    await flush();
    h.controller.reset();
    final repeated = h.controller.cleanup();
    final joining = h.controller.join('123456');
    await h.controller.join('123456');
    await flush();
    expect(joins, 1);
    closing.complete();
    await repeated;
    await joining;
    await flush();
    expect(joins, 2);
    expect(h.calls.where((c) => c == 'leave-old').length, 1);
    expect(h.container.read(roomChannelProvider), same(next));
  });

  test('leaving session is polled then joined only after release', () async {
    final h = RaceHarness();
    await h.init();
    final config = loadConfigWithServer('http://server.test');
    // Real production default poll interval is used; just one poll is needed.
    var queries = 0, joins = 0;
    when(h.channels.getCurrentSession).thenAnswer(
      (_) async => ++queries == 1
          ? const ChannelSession({'status': 'leaving', 'channel_id': 'race-room'})
          : null,
    );
    final next = h.handle('next');
    when(() => h.channels.join(any(), options: any(named: 'options'))).thenAnswer((_) async {
      joins++;
      return next;
    });
    await h.controller.join('123456');
    await flush();
    expect(h.active.media, 'releasing');
    expect(joins, 0);
    await Future<void>.delayed(Duration(milliseconds: config.live.rtcReleasePollMs + 20));
    expect(joins, 1);
    expect(h.active.media, 'connected');
  });

  test('active session on another channel is preserved without join or resume', () async {
    final h = RaceHarness();
    await h.init();
    when(h.channels.getCurrentSession).thenAnswer(
      (_) async => const ChannelSession({'status': 'joined', 'channel_id': 'other-room'}),
    );
    await h.controller.join('123456');
    await flush();
    expect(h.active.media, 'error');
    verifyNever(() => h.channels.join(any(), options: any(named: 'options')));
    verifyNever(
      () => h.channels.resume(
        channelId: any(named: 'channelId'),
        sessionId: any(named: 'sessionId'),
        cancel: any(named: 'cancel'),
      ),
    );
  });

  test('valid same-room session resumes instead of reserving another seat', () async {
    final h = RaceHarness();
    await h.init();
    final next = h.handle('resumed');
    when(h.channels.getCurrentSession).thenAnswer(
      (_) async =>
          const ChannelSession({'status': 'joined', 'channel_id': 'race-room', 'session_id': 's'}),
    );
    when(
      () => h.channels.resume(
        channelId: 'race-room',
        sessionId: 's',
        cancel: any(named: 'cancel'),
      ),
    ).thenAnswer((_) async => next);
    await h.controller.join('123456');
    await flush();
    expect(h.active.media, 'connected');
    verifyNever(() => h.channels.join(any(), options: any(named: 'options')));
  });

  test('release poll is bounded and cancelled lookup cannot be revived', () {
    fakeAsync((time) {
      final channels = Channels();
      var calls = 0;
      Object? failure;
      when(channels.getCurrentSession).thenAnswer((_) async {
        calls++;
        return const ChannelSession({'status': 'leaving'});
      });
      unawaited(
        waitForRtcRelease(
          channels,
          cancel: DRCancelToken(),
          timeout: const Duration(seconds: 15),
          pollInterval: const Duration(milliseconds: 400),
          onReleasing: () {},
        ).catchError((Object e) {
          failure = e;
          return null;
        }),
      );
      time.elapse(const Duration(seconds: 15));
      expect(failure, isA<RtcReleaseTimeout>());
      final stopped = calls;
      time.elapse(const Duration(seconds: 15));
      expect(calls, stopped);
      final token = DRCancelToken();
      final pending = Completer<ChannelSession?>();
      failure = null;
      when(channels.getCurrentSession).thenAnswer((_) => pending.future);
      unawaited(
        waitForRtcRelease(
          channels,
          cancel: token,
          timeout: const Duration(seconds: 15),
          pollInterval: const Duration(milliseconds: 400),
          onReleasing: () {},
        ).catchError((Object e) {
          failure = e;
          return null;
        }),
      );
      token.cancel();
      time.flushMicrotasks();
      expect(failure, isA<DRException>());
      pending.complete(null);
      time.flushMicrotasks();
      expect(failure, isA<DRException>());
      expect(time.pendingTimers, isEmpty);
    });
  });
}
