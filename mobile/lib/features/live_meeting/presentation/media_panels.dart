import 'dart:async';

import 'package:deeprespond_im/deeprespond_im.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

import '../../../core/config/app_config_provider.dart';
import '../../../core/im/channel_media.dart';
import '../../../core/im/rtc_telemetry.dart';
import '../../../core/theme/context_extensions.dart';
import '../domain/live_models.dart';
import 'room_controller.dart';
import 'screen_controller.dart';

String? screenError(BuildContext context, ScreenFailure? error) => switch (error) {
  null => null,
  ScreenFailure.denied => context.l10n.liveShareDenied,
  ScreenFailure.replaced => context.l10n.liveShareReplaced,
  ScreenFailure.stop => context.l10n.liveShareStopFailed,
  _ => context.l10n.liveShareFailed,
};

/// A publication is shown only after both business ownership and the SDK's
/// admitted track agree on the current claim. Older/replaced frames stay hidden.
ChannelTrack? sharedTrack(
  ChannelHandle? channel,
  List<ChannelTrack> tracks,
  LiveParticipant owner,
) => tracks
    .where(
      (t) =>
          owner.userId != null &&
          t.kind == 'video' &&
          t.username == owner.userId &&
          owner.screenSharing &&
          owner.screenShareId != null &&
          publicationName(channel, t) == 'screen:${owner.screenShareId}',
    )
    .firstOrNull;

class ScreenStage extends ConsumerStatefulWidget {
  const ScreenStage({required this.owner, required this.track, super.key});
  final LiveParticipant owner;
  final Object? track;
  @override
  ConsumerState<ScreenStage> createState() => _ScreenStageState();
}

class _ScreenStageState extends ConsumerState<ScreenStage> {
  Timer? _timer;
  bool _expired = false;
  @override
  void initState() {
    super.initState();
    _wait();
  }

  @override
  void didUpdateWidget(ScreenStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.owner.screenShareId != widget.owner.screenShareId ||
        oldWidget.track != widget.track) {
      _wait();
    }
  }

  void _wait() {
    _timer?.cancel();
    _expired = false;
    if (widget.track == null) {
      _timer = Timer(
        Duration(milliseconds: ref.read(appConfigProvider).live.screenTrackTimeoutMs),
        () {
          if (mounted) setState(() => _expired = true);
        },
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n, track = widget.track;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            dense: true,
            leading: const Icon(Icons.screen_share_outlined),
            title: Text(
              l.liveShareBy(widget.owner.name),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: track is lk.VideoTrack
                ? lk.VideoTrackRenderer(
                    track,
                    fit: lk.VideoViewFit.contain,
                    mirrorMode: lk.VideoViewMirrorMode.off,
                  )
                : Center(
                    child: Padding(
                      padding: context.spacing.page,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!_expired) const CircularProgressIndicator(),
                          context.spacing.gapSm,
                          Text(
                            _expired ? l.liveShareReceiveFailed : l.liveShareWaiting,
                            textAlign: TextAlign.center,
                          ),
                          if (_expired)
                            TextButton(
                              onPressed: () {
                                setState(_wait);
                                unawaited(ref.read(roomControllerProvider.notifier).refresh());
                              },
                              child: Text(l.liveRetry),
                            ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class NetworkBadge extends ConsumerWidget {
  const NetworkBadge({required this.metrics, required this.connected, super.key});
  final NetworkMetrics? metrics;
  final bool connected;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final quality = connected
        ? metrics?.quality(ref.watch(appConfigProvider).live, DateTime.now()) ?? RtcQuality.unknown
        : RtcQuality.unknown;
    final label = switch (quality) {
      RtcQuality.unknown => l.liveNetworkUnknown,
      RtcQuality.good => l.liveNetworkGood,
      RtcQuality.fair => l.liveNetworkFair,
      RtcQuality.poor => l.liveNetworkPoor,
    };
    final color = switch (quality) {
      RtcQuality.unknown => context.colors.mutedForeground,
      RtcQuality.good => context.colors.success,
      RtcQuality.fair => context.colors.warning,
      RtcQuality.poor => context.colors.destructive,
    };
    return TextButton.icon(
      key: const ValueKey('rtc-network'),
      icon: Icon(Icons.network_check, color: color, size: context.sizes.iconSm),
      label: Text(label, style: TextStyle(color: color)),
      onPressed: () => showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l.liveNetwork),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.liveNetworkScope),
              context.spacing.gapMd,
              Text(
                '${l.liveNetworkRtt}: ${quality != RtcQuality.unknown && metrics?.rttMs != null ? '${metrics!.rttMs!.toStringAsFixed(0)} ms' : l.liveNetworkNoData}',
              ),
              Text(
                '${l.liveNetworkLoss}: ${quality != RtcQuality.unknown && metrics?.lossPercent != null ? '${metrics!.lossPercent!.toStringAsFixed(1)}%' : l.liveNetworkNoData}',
              ),
            ],
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l.liveClose))],
        ),
      ),
    );
  }
}
