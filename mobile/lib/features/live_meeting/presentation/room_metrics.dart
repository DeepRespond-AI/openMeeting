import 'dart:async';

import 'package:deeprespond_im/deeprespond_im.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/config/app_config_provider.dart';
import '../../../core/im/channel_media.dart';
import '../../../core/im/rtc_telemetry.dart';
import '../domain/live_models.dart';
import 'room_controller.dart';

part 'room_metrics.g.dart';

@Riverpod(keepAlive: true)
Stream<RoomMetrics> roomMetrics(Ref ref) {
  final channel = ref.watch(roomChannelProvider);
  final config = ref.watch(appConfigProvider).live;
  final connected = ref.watch(
    roomControllerProvider.select(
      (s) => s is RoomActive && s.media == 'connected' && s.connection == 'connected',
    ),
  );
  if (channel == null || !connected) return Stream.value(const RoomMetrics());
  final reader = ref.watch(readRtcStatsProvider), sampler = RtcSampler(config);
  final controller = StreamController<RoomMetrics>();
  var disposed = false, busy = false;
  Future<void> sample() async {
    if (busy || disposed) return;
    busy = true;
    final reports = <ChannelTrack, List<RtcStat>>{};
    try {
      final state = ref.read(roomControllerProvider);
      if (state is! RoomActive) return;
      final audible = {
        for (final p in state.room.participants)
          if (p.micOn && !p.mutedByHost && p.userId != null) p.userId!,
      };
      for (final track in channel.currentTracks.where((t) => !isScreenTrack(channel, t))) {
        try {
          reports[track] = await reader(track).timeout(Duration(milliseconds: config.rtcStaleMs));
        } on Object {
          reports[track] = [];
        }
        if (disposed) return;
      }
      if (!disposed) controller.add(sampler.sample(reports, audible, DateTime.now()));
    } finally {
      busy = false;
    }
  }

  final timer = Timer.periodic(
    Duration(milliseconds: config.rtcSampleMs),
    (_) => unawaited(sample()),
  );
  unawaited(sample());
  ref.onDispose(() {
    disposed = true;
    timer.cancel();
    unawaited(controller.close());
  });
  return controller.stream;
}
