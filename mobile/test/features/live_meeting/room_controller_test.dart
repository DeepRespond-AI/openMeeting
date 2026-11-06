import 'dart:async';
import 'dart:convert';

import 'package:deeprespond_im/deeprespond_im.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meeting/core/api/api_exception.dart';
import 'package:meeting/core/auth/session_controller.dart';
import 'package:meeting/core/im/live_activity.dart';
import 'package:meeting/core/im/rtc_connection_failure.dart';
import 'package:meeting/features/live_meeting/data/live_repository_impl.dart';
import 'package:meeting/features/live_meeting/domain/live_models.dart';
import 'package:meeting/features/live_meeting/domain/live_repository.dart';
import 'package:meeting/features/live_meeting/presentation/room_controller.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_config.dart';

class _Repo extends Mock implements LiveRepository {}

class _Channel extends Mock implements ChannelHandle {}

const me = LiveParticipant(id: 'p1', userId: 'u1', name: 'Host', isHost: true, isSelf: true);
const room = LiveRoom(id: 'r1', code: '123456', title: 'Room', hostId: 'p1', participants: [me]);
Map<String, dynamic> result({bool waiting = false}) => {
  'room': jsonDecode(jsonEncode(room.toJson())),
  'self': me.toJson(),
  'state': waiting ? 'waiting' : 'joined',
  'media': {'transport': 'unavailable'},
};

void main() {
  setUpAll(() => registerFallbackValue(<String, Object?>{}));
  test('RTC join deadline has a distinct UI key without hiding other SDK failures', () async {
    final c = await createTestContainer();
    final controller = c.read(roomControllerProvider.notifier);
    expect(
      controller.failure(
        DRException(
          code: LocalErrorCode.invalidState,
          details: const {'reason': 'join_deadline_exceeded'},
          source: ErrorSource.local,
        ),
      ),
      rtcJoinTimedOut,
    );
    expect(
      controller.failure(
        DRException(code: 'unavailable', message: '媒体房间准备中', source: ErrorSource.http, status: 503),
      ),
      '媒体房间准备中',
    );
  });
  test('repeated media retry makes one request and ignores results after leaving', () async {
    final repo = _Repo();
    final events = StreamController<Map<String, dynamic>>.broadcast();
    final media = Completer<Map<String, dynamic>>();
    when(() => repo.join(any())).thenAnswer((_) async => result());
    when(() => repo.room(any())).thenAnswer((_) async => room);
    when(() => repo.events(any())).thenAnswer((_) => events.stream);
    when(() => repo.media(any())).thenAnswer((_) => media.future);
    final c = await createTestContainer(
      config: loadConfigWithServer('http://server.test'),
      secure: {
        'session.token': 'unit-test-token',
        'session.user': '{"id":"u1","name":"Host"}',
        'session.serverUrl': 'http://server.test',
      },
      overrides: [liveRepositoryProvider.overrideWithValue(repo)],
    );
    await c.read(sessionControllerProvider.future);
    final controller = c.read(roomControllerProvider.notifier);
    await controller.join('123456');
    await Future<void>.delayed(Duration.zero);
    final first = controller.retryMedia();
    await Future<void>.delayed(Duration.zero);
    await controller.retryMedia();
    verify(() => repo.media(room.id)).called(1);
    expect((c.read(roomControllerProvider) as RoomActive).media, 'connecting');
    await controller.cleanup();
    media.complete({'transport': 'unavailable'});
    await first;
    expect(c.read(roomChannelProvider), null);
    // A stale response must not change the room after cleanup invalidates it.
    expect((c.read(roomControllerProvider) as RoomActive).media, 'connecting');
    await events.close();
  });
  test('failed retry leaves room active with a retryable media error', () async {
    final repo = _Repo();
    final events = StreamController<Map<String, dynamic>>.broadcast();
    when(() => repo.join(any())).thenAnswer((_) async => result());
    when(() => repo.room(any())).thenAnswer((_) async => room);
    when(() => repo.events(any())).thenAnswer((_) => events.stream);
    when(() => repo.media(any())).thenThrow(
      const ApiException(kind: ApiErrorKind.unavailable, statusCode: 503, message: '音视频服务暂不可用'),
    );
    final c = await createTestContainer(
      config: loadConfigWithServer('http://server.test'),
      secure: {
        'session.token': 'unit-test-token',
        'session.user': '{"id":"u1","name":"Host"}',
        'session.serverUrl': 'http://server.test',
      },
      overrides: [liveRepositoryProvider.overrideWithValue(repo)],
    );
    await c.read(sessionControllerProvider.future);
    final controller = c.read(roomControllerProvider.notifier);
    await controller.join('123456');
    await Future<void>.delayed(Duration.zero);
    await controller.retryMedia();
    final active = c.read(roomControllerProvider) as RoomActive;
    expect(active.media, 'error');
    expect(active.error, '音视频服务暂不可用');
    await controller.retryMedia();
    verify(() => repo.media(room.id)).called(2);
    await controller.cleanup();
    await events.close();
  });
  for (final message in ['会议尚未开始，请等待房主进入后重试', '会议号不存在']) {
    test('failed join preserves server feedback: $message', () async {
      final repo = _Repo();
      when(() => repo.join(any()))
          .thenThrow(ApiException(kind: ApiErrorKind.notFound, statusCode: 404, message: message));
      final c = await createTestContainer(
        config: loadConfigWithServer('http://server.test'),
        secure: {
          'session.token': 'unit-test-token',
          'session.user': '{"id":"u1","name":"Guest"}',
          'session.serverUrl': 'http://server.test',
        },
        overrides: [liveRepositoryProvider.overrideWithValue(repo)],
      );
      await c.read(sessionControllerProvider.future);
      await c.read(roomControllerProvider.notifier).join('123456');
      expect((c.read(roomControllerProvider) as RoomFailed).message, message);
      expect(c.read(liveActivityProvider), false);
      verifyNever(
        () => repo.create(
          title: any(named: 'title'),
          scheduledId: any(named: 'scheduledId'),
        ),
      );
    });
  }
  test('joining does not publish devices before native permission succeeds', () async {
    final repo = _Repo();
    final events = StreamController<Map<String, dynamic>>.broadcast();
    when(() => repo.join(any())).thenAnswer((_) async => result());
    when(() => repo.room(any())).thenAnswer((_) async => room);
    when(() => repo.chats(any(), after: any(named: 'after'))).thenAnswer((_) async => []);
    when(() => repo.events(any())).thenAnswer((_) => events.stream);
    final c = await createTestContainer(
      config: loadConfigWithServer('http://server.test'),
      secure: {
        'session.token': 'unit-test-token',
        'session.user': jsonEncode({'id': 'u1', 'name': '😀' * 32}),
        'session.serverUrl': 'http://server.test',
      },
      overrides: [liveRepositoryProvider.overrideWithValue(repo)],
    );
    await c.read(sessionControllerProvider.future);
    await c.read(roomControllerProvider.notifier).join('123456', mic: true, cam: true);
    final request = verify(() => repo.join(captureAny())).captured.single as Map<String, Object?>;
    expect(request['micOn'], false);
    expect(request['camOn'], false);
    expect(request['name'], '😀' * 20);
    expect(c.read(currentUserProvider)?.name, '😀' * 32);
    expect(c.read(roomControllerProvider), isA<RoomActive>());
    await c.read(roomControllerProvider.notifier).cleanup();
    await events.close();
  });
  test('native microphone rejection rolls server flag back and preserves room', () async {
    final repo = _Repo(), channel = _Channel();
    final events = StreamController<Map<String, dynamic>>.broadcast();
    final writes = <Map<String, Object?>>[];
    when(() => repo.join(any())).thenAnswer((_) async => result());
    when(() => repo.room(any())).thenAnswer((_) async => room);
    when(() => repo.chats(any(), after: any(named: 'after'))).thenAnswer((_) async => []);
    when(() => repo.events(any())).thenAnswer((_) => events.stream);
    when(() => repo.self(any(), any())).thenAnswer((call) async {
      writes.add(call.positionalArguments[1] as Map<String, Object?>);
    });
    when(() => channel.setMicrophoneEnabled(true)).thenThrow(StateError('permission denied'));
    when(() => channel.setMicrophoneEnabled(false)).thenAnswer((_) async {});
    when(() => channel.setCameraEnabled(false)).thenAnswer((_) async {});
    final c = await createTestContainer(
      config: loadConfigWithServer('http://server.test'),
      secure: {
        'session.token': 'unit-test-token',
        'session.user': '{"id":"u1","name":"Host"}',
        'session.serverUrl': 'http://server.test',
      },
      overrides: [liveRepositoryProvider.overrideWithValue(repo)],
    );
    await c.read(sessionControllerProvider.future);
    final controller = c.read(roomControllerProvider.notifier);
    await controller.join('123456');
    await Future<void>.delayed(Duration.zero);
    c.read(roomChannelProvider.notifier).set(channel);
    expect(await controller.mic(true), false);
    expect(writes, [
      {'micOn': true},
      {'micOn': false},
    ]);
    expect((c.read(roomControllerProvider) as RoomActive).error, contains('permission denied'));
    await controller.cleanup();
    await events.close();
  });
  test('waiting room missing on server terminates polling and update exemption', () async {
    final repo = _Repo();
    when(() => repo.join(any())).thenAnswer((_) async => result(waiting: true));
    when(() => repo.peek(any())).thenThrow(const ApiException(kind: ApiErrorKind.notFound));
    final c = await createTestContainer(
      config: loadConfigWithServer('http://server.test'),
      secure: {
        'session.token': 'unit-test-token',
        'session.user': '{"id":"u1","name":"Host"}',
        'session.serverUrl': 'http://server.test',
      },
      overrides: [liveRepositoryProvider.overrideWithValue(repo)],
    );
    await c.read(sessionControllerProvider.future);
    final controller = c.read(roomControllerProvider.notifier);
    await controller.join('123456');
    expect(c.read(liveActivityProvider), true);
    await controller.pollWaiting();
    expect(c.read(roomControllerProvider), isA<RoomEnded>());
    expect(c.read(liveActivityProvider), false);
  });
  test('host cannot submit a hand request', () async {
    final repo = _Repo();
    final events = StreamController<Map<String, dynamic>>.broadcast();
    when(() => repo.join(any())).thenAnswer((_) async => result());
    when(() => repo.room(any())).thenAnswer((_) async => room);
    when(() => repo.chats(any(), after: any(named: 'after'))).thenAnswer((_) async => []);
    when(() => repo.events(any())).thenAnswer((_) => events.stream);
    final c = await createTestContainer(
      config: loadConfigWithServer('http://server.test'),
      secure: {
        'session.token': 'unit-test-token',
        'session.user': '{"id":"u1","name":"Host"}',
        'session.serverUrl': 'http://server.test',
      },
      overrides: [liveRepositoryProvider.overrideWithValue(repo)],
    );
    await c.read(sessionControllerProvider.future);
    final controller = c.read(roomControllerProvider.notifier);
    await controller.join('123456');
    expect(await controller.hand(), false);
    verifyNever(() => repo.self(any(), any()));
    expect((c.read(roomControllerProvider) as RoomActive).self.handRaised, false);
    await controller.cleanup();
    await events.close();
  });
  test('approval event unlocks guest microphone without publishing until guest chooses', () async {
    final repo = _Repo(), channel = _Channel();
    final events = StreamController<Map<String, dynamic>>.broadcast();
    var guest = const LiveParticipant(
      id: 'guest',
      userId: 'u1',
      name: 'Guest',
      isSelf: true,
      mutedByHost: true,
      handRaised: true,
    );
    LiveRoom snapshot() => room.copyWith(participants: [me.copyWith(isSelf: false), guest]);
    when(() => repo.join(any())).thenAnswer(
      (_) async => {
        'room': snapshot().toJson(),
        'self': guest.toJson(),
        'state': 'joined',
        'media': {'transport': 'unavailable'},
      },
    );
    when(() => repo.room(any())).thenAnswer((_) async => snapshot());
    when(() => repo.chats(any(), after: any(named: 'after'))).thenAnswer((_) async => []);
    when(() => repo.events(any())).thenAnswer((_) => events.stream);
    when(() => repo.self(any(), any())).thenAnswer((call) async {
      final patch = call.positionalArguments[1] as Map<String, Object?>;
      guest = guest.copyWith(micOn: patch['micOn'] as bool? ?? guest.micOn);
    });
    when(() => channel.setMicrophoneEnabled(any())).thenAnswer((_) async {});
    final c = await createTestContainer(
      config: loadConfigWithServer('http://server.test'),
      secure: {
        'session.token': 'unit-test-token',
        'session.user': '{"id":"u1","name":"Guest"}',
        'session.serverUrl': 'http://server.test',
      },
      overrides: [liveRepositoryProvider.overrideWithValue(repo)],
    );
    await c.read(sessionControllerProvider.future);
    final controller = c.read(roomControllerProvider.notifier);
    await controller.join('123456');
    c.read(roomChannelProvider.notifier).set(channel);
    expect(await controller.mic(true), false);
    verifyNever(() => channel.setMicrophoneEnabled(true));
    guest = guest.copyWith(mutedByHost: false, handRaised: false);
    events.add({
      'type': 'participant_updated',
      'data': {'participant': guest.toJson()},
    });
    await Future<void>.delayed(Duration.zero);
    final approved = c.read(roomControllerProvider) as RoomActive;
    expect(approved.self.mutedByHost, false);
    expect(approved.self.micOn, false);
    verifyNever(() => channel.setMicrophoneEnabled(true));
    expect(await controller.mic(true), true);
    verify(() => channel.setMicrophoneEnabled(true)).called(1);
    expect((c.read(roomControllerProvider) as RoomActive).self.micOn, true);
    await controller.cleanup();
    await events.close();
  });
  test('late join completion after reset cannot resurrect the room', () async {
    final repo = _Repo(), pending = Completer<Map<String, dynamic>>();
    when(() => repo.join(any())).thenAnswer((_) => pending.future);
    final c = await createTestContainer(
      config: loadConfigWithServer('http://server.test'),
      secure: {
        'session.token': 'unit-test-token',
        'session.user': '{"id":"u1","name":"Host"}',
        'session.serverUrl': 'http://server.test',
      },
      overrides: [liveRepositoryProvider.overrideWithValue(repo)],
    );
    await c.read(sessionControllerProvider.future);
    final controller = c.read(roomControllerProvider.notifier);
    final joining = controller.join('123456');
    await Future<void>.delayed(Duration.zero);
    expect(c.read(roomControllerProvider), isA<RoomJoining>());
    controller.reset();
    pending.complete(result());
    await joining;
    expect(c.read(roomControllerProvider), isA<RoomIdle>());
    expect(c.read(liveActivityProvider), false);
  });
}
