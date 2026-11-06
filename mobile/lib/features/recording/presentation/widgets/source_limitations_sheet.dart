import 'package:flutter/material.dart';

import '../../../../core/theme/context_extensions.dart';

/// Bottom sheet explaining what system-audio ("内录") capture can and cannot record.
Future<void> showSourceLimitationsSheet(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (context) => const _SourceLimitationsSheet(),
);

class _SourceLimitationsSheet extends StatelessWidget {
  const _SourceLimitationsSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.spacing;
    final items = [
      (Icons.surround_sound_outlined, l10n.recordingLimitationsMix),
      (Icons.phone_disabled_outlined, l10n.recordingLimitationsCalls),
      (Icons.screen_share_outlined, l10n.recordingLimitationsConsent),
      (Icons.phonelink_erase_outlined, l10n.recordingLimitationsDevice),
    ];
    return SafeArea(
      child: SingleChildScrollView(
        padding: spacing.page,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.recordingLimitationsTitle, style: context.textTheme.titleMedium),
            spacing.gapMd,
            for (final (icon, text) in items) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: context.sizes.iconMd, color: context.colors.primary),
                  spacing.gapSm,
                  Expanded(child: Text(text, style: context.textTheme.bodyMedium)),
                ],
              ),
              spacing.gapMd,
            ],
          ],
        ),
      ),
    );
  }
}
