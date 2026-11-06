import 'dart:collection';

import 'package:deeprespond_im/deeprespond_im.dart';
import 'package:deeprespond_im/internal.dart' show ChannelHandleImpl;
import 'package:deeprespond_im_call/deeprespond_im_call.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:meeting/core/im/channel_media.dart';
import 'package:meeting/features/live_meeting/domain/live_models.dart';
import 'package:meeting/features/live_meeting/presentation/media_panels.dart';
import 'package:mocktail/mocktail.dart';

class _Channel extends Mock implements ChannelHandleImpl {}

class _Session extends Mock implements LiveKitSession {}

class _Room extends Mock implements lk.Room {}

class _Local extends Mock implements lk.LocalParticipant {}

class _Pub extends Mock implements lk.LocalTrackPublication<lk.LocalVideoTrack> {}

class _Video extends Mock implements lk.LocalVideoTrack {}

void main() {
  test('camera controls never select a screen publication using camera grants', () async {
    final channel = _Channel(), session = _Session(), room = _Room(), local = _Local();
    final camera = _Pub(), screen = _Pub();
    when(() => channel.mediaSession).thenReturn(session);
    when(() => session.room).thenReturn(room);
    when(() => room.localParticipant).thenReturn(local);
    when(() => screen.name).thenReturn('screen:claim');
    when(() => camera.name).thenReturn('camera');
    when(() => local.videoTrackPublications).thenReturn([screen, camera]);
    when(camera.mute).thenAnswer((_) async {});
    when(camera.unmute).thenAnswer((_) async {});
    await setChannelCamera(channel, false);
    await setChannelCamera(channel, true);
    verify(camera.mute).called(1);
    verify(camera.unmute).called(1);
    verifyNever(screen.mute);
    verifyNever(screen.unmute);
  });
  test('screen viewing checks SDK track, owner identity and exact current claim', () {
    final channel = _Channel(), session = _Session(), room = _Room(), local = _Local();
    final publication = _Pub(), video = _Video();
    when(() => channel.mediaSession).thenReturn(session);
    when(() => session.room).thenReturn(room);
    when(() => room.localParticipant).thenReturn(local);
    when(() => room.remoteParticipants)
        .thenReturn(UnmodifiableMapView<String, lk.RemoteParticipant>({}));
    when(() => local.trackPublications).thenReturn({'screen': publication});
    when(() => publication.track).thenReturn(video);
    when(() => publication.name).thenReturn('screen:current');
    final admitted = ChannelTrack(
      sessionId: 'sdk-admitted',
      username: 'owner',
      kind: 'video',
      track: video,
      local: true,
    );
    const owner = LiveParticipant(
      id: 'participant',
      userId: 'owner',
      name: 'Owner',
      screenSharing: true,
      screenShareId: 'current',
    );
    expect(sharedTrack(channel, [admitted], owner), same(admitted));
    expect(sharedTrack(channel, [admitted], owner.copyWith(screenShareId: 'old')), isNull);
    expect(sharedTrack(channel, [admitted], owner.copyWith(userId: 'other')), isNull);
    expect(sharedTrack(channel, [admitted], owner.copyWith(screenSharing: false)), isNull);
    expect(sharedTrack(channel, [], owner), isNull);
  });
}
