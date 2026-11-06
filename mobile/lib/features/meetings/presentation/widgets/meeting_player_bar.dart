import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config_provider.dart';
import '../../../../core/theme/context_extensions.dart';
import '../../domain/audio_playback.dart';
import '../meeting_formatting.dart';
import '../meeting_player_controller.dart';

/// Compact audio player (desktop `MeetingAudioPlayer`): back / play / forward, seek bar,
/// time labels and a speed button cycling through `AppConfig.player.speeds`.
class MeetingPlayerBar extends ConsumerWidget {
  const MeetingPlayerBar({super.key, required this.meetingId});

  final String meetingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = meetingPlayerControllerProvider(meetingId);
    final player = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final config = ref.watch(appConfigProvider.select((c) => c.player));
    final l10n = context.l10n;
    final colors = context.colors;
    final spacing = context.spacing;

    Widget message(String text, {VoidCallback? onRetry}) => Row(
      children: [
        Icon(Icons.headphones_outlined, size: context.sizes.iconMd, color: colors.mutedForeground),
        SizedBox(width: spacing.xs),
        Expanded(
          child: Text(
            text,
            style: context.textTheme.bodySmall?.copyWith(color: colors.mutedForeground),
          ),
        ),
        if (onRetry != null) TextButton(onPressed: onRetry, child: Text(l10n.commonRetry)),
      ],
    );

    final Widget body = switch (player.status) {
      PlayerStatus.idle => TextButton.icon(
        onPressed: controller.togglePlay,
        icon: const Icon(Icons.play_arrow),
        label: Text(l10n.meetingsAudioPlay),
      ),
      PlayerStatus.loading => message(l10n.meetingsAudioLoading),
      PlayerStatus.unavailable => message(l10n.meetingsAudioUnavailable),
      PlayerStatus.error => message(l10n.meetingsAudioLoadFailed, onRetry: controller.load),
      PlayerStatus.ready => _ReadyPlayer(
        state: player,
        controller: controller,
        skipSeconds: config.skipSeconds,
        speeds: config.speeds,
      ),
    };

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          bottom: BorderSide(color: colors.border, width: context.sizes.borderWidth),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: spacing.sm, vertical: spacing.xxs),
      child: body,
    );
  }
}

class _ReadyPlayer extends StatelessWidget {
  const _ReadyPlayer({
    required this.state,
    required this.controller,
    required this.skipSeconds,
    required this.speeds,
  });

  final MeetingPlayerState state;
  final MeetingPlayerController controller;
  final int skipSeconds;
  final List<double> speeds;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final duration = state.duration ?? Duration.zero;
    final maxMs = duration.inMilliseconds.toDouble();
    final posMs = state.position.inMilliseconds.toDouble().clamp(0.0, maxMs);
    final speed = speeds.isEmpty ? null : speeds[state.speedIndex % speeds.length];
    final timeStyle = context.textTheme.labelSmall?.copyWith(
      color: colors.mutedForeground,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Row(
      children: [
        IconButton(
          tooltip: l10n.meetingsAudioBack(skipSeconds),
          icon: const Icon(Icons.replay_10),
          onPressed: () => controller.skip(forward: false),
        ),
        IconButton.filled(
          tooltip: state.playing ? l10n.meetingsAudioPause : l10n.meetingsAudioPlay,
          icon: Icon(state.playing ? Icons.pause : Icons.play_arrow),
          onPressed: controller.togglePlay,
        ),
        IconButton(
          tooltip: l10n.meetingsAudioForward(skipSeconds),
          icon: const Icon(Icons.forward_10),
          onPressed: () => controller.skip(forward: true),
        ),
        Text(formatPlayerTime(state.position), style: timeStyle),
        Expanded(
          child: Semantics(
            label: l10n.meetingsAudioPosition,
            child: Slider(
              value: maxMs <= 0 ? 0 : posMs,
              max: maxMs <= 0 ? 1 : maxMs,
              onChanged: maxMs <= 0
                  ? null
                  : (v) => controller.seek(Duration(milliseconds: v.round())),
            ),
          ),
        ),
        Text(formatPlayerTime(duration), style: timeStyle),
        if (speed != null)
          TextButton(
            onPressed: controller.cycleSpeed,
            child: Tooltip(
              message: l10n.meetingsAudioSpeed,
              child: Text(l10n.meetingsAudioSpeedValue(_speedLabel(speed))),
            ),
          ),
      ],
    );
  }

  static String _speedLabel(double speed) =>
      speed == speed.roundToDouble() ? speed.toInt().toString() : speed.toString();
}
