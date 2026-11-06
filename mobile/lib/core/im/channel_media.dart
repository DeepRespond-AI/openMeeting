import 'package:deeprespond_im/deeprespond_im.dart';
import 'package:deeprespond_im/internal.dart' show ChannelHandleImpl;
import 'package:deeprespond_im_call/deeprespond_im_call.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:livekit_client/livekit_client.dart' as lk;

/// Compatibility boundary for the pinned alpha.2 SDK, matching its own video
/// views. Uses only the SDK-admitted session, never a second RTC connection.
lk.Room? channelRoom(ChannelHandle? channel) {
  if (channel is! ChannelHandleImpl) return null;
  final session = channel.mediaSession;
  return session is LiveKitSession ? session.room : null;
}

String? publicationName(ChannelHandle? channel, ChannelTrack track) {
  final room = channelRoom(channel);
  if (room == null) return null;
  final participants = <lk.Participant<lk.TrackPublication>>[
    if (room.localParticipant != null) room.localParticipant!,
    ...room.remoteParticipants.values,
  ];
  for (final participant in participants) {
    for (final publication in participant.trackPublications.values) {
      if (identical(publication.track, track.track)) return publication.name;
    }
  }
  return null;
}

bool isScreenTrack(ChannelHandle? channel, ChannelTrack track) =>
    publicationName(channel, track)?.startsWith('screen:') ?? false;

Future<void> setChannelCamera(ChannelHandle channel, bool enabled) async {
  final participant = channelRoom(channel)?.localParticipant;
  if (participant == null) return channel.setCameraEnabled(enabled);
  final existing = participant.videoTrackPublications
      .where((p) => !p.name.startsWith('screen:'))
      .firstOrNull;
  if (enabled) {
    if (existing != null) {
      await existing.unmute();
    } else {
      final track = await lk.LocalVideoTrack.createCameraTrack();
      try {
        await participant.publishVideoTrack(
          track,
          publishOptions: const lk.VideoPublishOptions(name: 'camera'),
        );
      } on Object {
        await track.stop();
        await track.dispose();
        rethrow;
      }
    }
  } else if (existing != null) {
    await existing.mute();
  }
}

Future<void> switchChannelCamera(ChannelHandle channel) async {
  final participant = channelRoom(channel)?.localParticipant;
  if (participant == null) return channel.switchCamera();
  final track = participant.videoTrackPublications
      .where((p) => !p.name.startsWith('screen:'))
      .firstOrNull
      ?.track;
  if (track != null) await rtc.Helper.switchCamera(track.mediaStreamTrack);
}
