import 'dart:async';

import 'package:deeprespond_im/deeprespond_im.dart';
import 'package:meeting/core/im/screen_capture.dart';
import 'package:meeting/features/live_meeting/data/live_repository_impl.dart';
import 'package:meeting/features/live_meeting/domain/live_models.dart';
import 'package:meeting/features/live_meeting/domain/live_repository.dart';
import 'package:meeting/features/live_meeting/presentation/room_controller.dart';
import 'package:mocktail/mocktail.dart';

class CoreChannel extends Mock implements ChannelHandle {}

class CoreRepo extends Mock implements LiveRepository {}

const coreSelf = LiveParticipant(
  id: 'self',
  userId: 'self-id',
  name: '林小明',
  isSelf: true,
  isHost: true,
  micOn: true,
);
const corePeer = LiveParticipant(id: 'peer', userId: 'peer-id', name: '张同学', micOn: true);
const coreRoom = LiveRoom(
  id: 'core-room',
  code: '123456',
  title: '核心功能会议：项目复盘与下周安排',
  hostId: 'self',
  participants: [coreSelf, corePeer],
  recording: LiveRecording(active: true, epoch: 1),
);

class CoreRoomController extends RoomController {
  @override
  LiveRoomState build() =>
      const RoomActive(room: coreRoom, self: coreSelf, media: 'connected', connection: 'connected');
  @override
  Future<void> refresh() async {
    if (state is RoomActive) {
      applyRoom(await ref.read(liveRepositoryProvider).room(coreRoom.id));
    }
  }

  @override
  void applyRoom(LiveRoom room) {
    final current = state;
    if (current is RoomActive) {
      state = current.copyWith(room: room, self: room.participants.where((p) => p.isSelf).first);
    }
  }

  void replace(LiveRoomState next) => state = next;
  @override
  Future<bool> settings(Map<String, Object?> values) async {
    final current = state as RoomActive;
    applyRoom(
      current.room.copyWith(
        title: values['title'] as String,
        pwdEnabled: values['pwdEnabled'] as bool,
        waitRoom: values['waitRoom'] as bool,
      ),
    );
    return true;
  }

  @override
  Future<bool> leave({bool end = false}) async {
    state = const RoomEnded();
    return true;
  }
}

class CoreCapture implements ScreenCapture {
  @override
  final Object video = Object();
  @override
  void Function()? onEnded;
  int published = 0, closed = 0;
  bool failPublish = false;
  String? lastClaim;
  Completer<void>? publishGate;
  @override
  Future<void> publish(ChannelHandle channel, String claim) async {
    published++;
    lastClaim = claim;
    if (publishGate != null) await publishGate!.future;
    if (failPublish) throw StateError('fixture publish failure');
  }

  @override
  Future<void> dispose() async {
    closed++;
    onEnded = null;
  }
}

class CoreMediaFixture {
  CoreMediaFixture() {
    when(() => channel.currentTracks).thenReturn([]);
    when(() => channel.tracks).thenAnswer((_) => const Stream.empty());
    when(() => repo.startScreenShare(any())).thenAnswer((_) async {
      starts++;
      if (claimGate != null) await claimGate!.future;
      if (failClaim) throw StateError('fixture admission denied');
      room = room.copyWith(
        participants: [
          coreSelf.copyWith(screenSharing: true, screenShareId: claim),
          corePeer,
        ],
      );
      return claim;
    });
    when(() => repo.room(any())).thenAnswer((_) async => room);
    when(() => repo.stopScreenShare(any(), any())).thenAnswer((call) async {
      stops.add(call.positionalArguments[1] as String);
      room = coreRoom;
    });
    when(() => repo.schedules(any(), any())).thenAnswer((_) async => []);
  }
  static const claim = '12345678-abcd-4000-8000-123456789012';
  final channel = CoreChannel(), repo = CoreRepo(), capture = CoreCapture();
  var room = coreRoom;
  int starts = 0;
  bool failClaim = false, denyCapture = false;
  final stops = <String>[];
  Completer<void>? claimGate;
  Completer<ScreenCapture>? captureGate;
  Future<ScreenCapture> acquire(String title, String body) async {
    if (denyCapture) throw const ScreenCaptureDenied();
    return captureGate?.future ?? Future.value(capture);
  }
}
