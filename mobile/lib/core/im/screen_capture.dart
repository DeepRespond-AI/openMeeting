import 'dart:io';

import 'package:deeprespond_im/deeprespond_im.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'channel_media.dart';

part 'screen_capture.g.dart';

abstract interface class ScreenCapture {
  Object get video;
  set onEnded(void Function()? callback);
  Future<void> publish(ChannelHandle channel, String claim);
  Future<void> dispose();
}

typedef CaptureScreen = Future<ScreenCapture> Function(String title, String body);

@Riverpod(keepAlive: true)
CaptureScreen captureScreen(Ref ref) => NativeScreenCapture.create;

/// Matches the desktop alpha SDK's camera-source + `screen:<claim>` contract.
/// Keep the single internal constructor call here until Dart SDK exposes screen
/// publication. Pin LiveKit/IM versions; never patch installed packages.
class NativeScreenCapture implements ScreenCapture {
  NativeScreenCapture(this.track, this.stream);
  final lk.LocalVideoTrack track;
  final rtc.MediaStream stream;
  lk.LocalParticipant? _publisher;
  String? _sid;
  bool _closed = false;
  static const _service = MethodChannel('meeting/screen-share');

  static Future<ScreenCapture> create(String title, String body) async {
    rtc.MediaStream? stream;
    try {
      if (Platform.isAndroid) {
        if (!await rtc.Helper.requestCapturePermission()) throw const ScreenCaptureDenied();
        await _service.invokeMethod<void>('start', {'title': title, 'body': body});
      }
      stream = await rtc.navigator.mediaDevices.getDisplayMedia({'video': true, 'audio': false});
      final video = stream.getVideoTracks().first;
      // ignore: invalid_use_of_internal_member
      final track = lk.LocalVideoTrack(
        lk.TrackSource.camera,
        stream,
        video,
        const lk.ScreenShareCaptureOptions(),
      );
      return NativeScreenCapture(track, stream);
    } on Object {
      if (stream != null) {
        for (final track in stream.getTracks()) {
          await track.stop();
        }
        await stream.dispose();
      }
      if (Platform.isAndroid) await _service.invokeMethod<void>('stop');
      rethrow;
    }
  }

  @override
  Object get video => track;
  @override
  set onEnded(void Function()? callback) => track.mediaStreamTrack.onEnded = callback;
  @override
  Future<void> publish(ChannelHandle channel, String claim) async {
    if (_closed || !RegExp(r'^[A-Za-z0-9-]{1,64}$').hasMatch(claim)) {
      throw StateError('screen claim invalid');
    }
    final publisher = channelRoom(channel)?.localParticipant;
    if (publisher == null) throw StateError('SDK media session unavailable');
    _publisher = publisher;
    final publication = await publisher.publishVideoTrack(
      track,
      publishOptions: lk.VideoPublishOptions(name: 'screen:$claim', simulcast: false),
    );
    _sid = publication.sid;
    if (_closed) await publisher.removePublishedTrack(publication.sid);
  }

  @override
  Future<void> dispose() async {
    if (_closed) return;
    _closed = true;
    onEnded = null;
    // Stop pixels before any network operation, including disconnected unpublish.
    try {
      await track.mediaStreamTrack.stop();
      if (_sid != null) await _publisher?.removePublishedTrack(_sid!);
    } finally {
      try {
        await track.stop();
        await track.dispose();
        await stream.dispose();
      } finally {
        if (Platform.isAndroid) await _service.invokeMethod<void>('stop');
      }
    }
  }
}

class ScreenCaptureDenied implements Exception {
  const ScreenCaptureDenied();
}
