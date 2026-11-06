import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/heartbeat/heartbeat_controller.dart';
import '../../../../core/theme/context_extensions.dart';

/// Warning strip under the app bar: server unreachable, or STT / LLM not ready
/// (from `capabilitiesProvider` and the heartbeat).
class ServerStatusBanner extends ConsumerWidget {
  const ServerStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final offline = ref.watch(
      heartbeatControllerProvider.select((s) => s.lastError?.isConnectivity ?? false),
    );
    final caps = ref.watch(capabilitiesProvider);
    final messages = <String>[
      if (offline) l10n.meetingsOffline,
      if (!offline && caps != null && !caps.stt.ready) l10n.meetingsSttNotReady,
      if (!offline && caps != null && !caps.llm.ready) l10n.meetingsLlmNotReady,
    ];
    if (messages.isEmpty) return const SizedBox.shrink();
    return StatusStrip(messages: messages, color: context.colors.warning);
  }
}

/// A tinted strip with an icon and one line per message.
class StatusStrip extends StatelessWidget {
  const StatusStrip({super.key, required this.messages, required this.color, this.icon});

  final List<String> messages;
  final Color color;
  final IconData? icon;

  /// Opacity of the tinted background / bottom border derived from [color].
  static const double _fillAlpha = 0.12;
  static const double _borderAlpha = 0.4;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: color.withValues(alpha: _fillAlpha),
        border: Border(
          bottom: BorderSide(
            color: color.withValues(alpha: _borderAlpha),
            width: context.sizes.borderWidth,
          ),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: spacing.md, vertical: spacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon ?? Icons.warning_amber_rounded, size: context.sizes.iconMd, color: color),
          SizedBox(width: spacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final m in messages)
                  Text(
                    m,
                    style: context.textTheme.bodySmall?.copyWith(color: context.colors.foreground),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
