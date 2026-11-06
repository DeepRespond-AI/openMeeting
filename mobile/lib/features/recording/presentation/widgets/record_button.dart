import 'package:flutter/material.dart';

import '../../../../core/theme/context_extensions.dart';

/// The big round button: brand gradient with a mic when idle, red with a stop square while
/// recording, a spinner while [busy].
class RecordButton extends StatelessWidget {
  const RecordButton({super.key, required this.live, required this.busy, required this.onPressed});

  final bool live;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final size = context.sizes.recordButton;
    final l10n = context.l10n;
    final enabled = onPressed != null && !busy;
    return Semantics(
      button: true,
      label: live ? l10n.recordingStop : l10n.recordingStart,
      child: Tooltip(
        message: live ? l10n.recordingStop : l10n.recordingStart,
        child: Material(
          type: MaterialType.transparency,
          child: Ink(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: live ? null : colors.brandGradient,
              color: live ? colors.recording : null,
              boxShadow: context.shadows.elevated,
            ),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: enabled ? onPressed : null,
              child: Center(
                child: busy
                    ? SizedBox.square(
                        dimension: context.sizes.iconLg,
                        child: CircularProgressIndicator(color: colors.onPrimary),
                      )
                    : Icon(
                        live ? Icons.stop_rounded : Icons.mic_rounded,
                        size: context.sizes.iconXl,
                        color: colors.onPrimary,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
