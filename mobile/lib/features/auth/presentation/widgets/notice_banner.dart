import 'package:flutter/material.dart';

import '../../../../core/theme/context_extensions.dart';

enum NoticeTone { info, warning, error }

/// Small tinted banner with an icon, a message and an optional action
/// (registration closed, SMS not ready, session expired ...).
class NoticeBanner extends StatelessWidget {
  const NoticeBanner({
    super.key,
    required this.message,
    this.tone = NoticeTone.info,
    this.actionLabel,
    this.onAction,
  });

  const NoticeBanner.warning({Key? key, required String message})
    : this(key: key, message: message, tone: NoticeTone.warning);

  const NoticeBanner.error({
    Key? key,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) : this(
         key: key,
         message: message,
         tone: NoticeTone.error,
         actionLabel: actionLabel,
         onAction: onAction,
       );

  final String message;
  final NoticeTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (Color fg, IconData icon) = switch (tone) {
      NoticeTone.info => (colors.primary, Icons.info_outline),
      NoticeTone.warning => (colors.warning, Icons.warning_amber_rounded),
      NoticeTone.error => (colors.destructive, Icons.error_outline),
    };
    final bg = tone == NoticeTone.info ? colors.accent : colors.muted;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: context.radius.mdAll,
        border: Border.all(color: fg, width: context.sizes.borderWidth),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.spacing.sm, vertical: context.spacing.xs),
        child: Row(
          children: [
            Icon(icon, color: fg, size: context.sizes.iconMd),
            context.spacing.gapXs,
            Expanded(
              child: Text(
                message,
                style: context.textTheme.bodySmall?.copyWith(color: colors.foreground),
              ),
            ),
            if (actionLabel != null && onAction != null)
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ),
      ),
    );
  }
}
