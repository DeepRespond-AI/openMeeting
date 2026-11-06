import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/data/client_info_source.dart';
import '../../../core/theme/context_extensions.dart';
import '../../../core/update/update_controller.dart';
import 'update_widgets.dart';

/// Optional update: version, release notes, "Later" / "Update now" with progress.
/// Not dismissible while downloading.
Future<void> showUpdateDialog(BuildContext context) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (_) => const _UpdateDialog(),
);

class _UpdateDialog extends ConsumerWidget {
  const _UpdateDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final spacing = context.spacing;
    final state = ref.watch(updateControllerProvider);
    final offer = state.offer;
    final current = ref.watch(clientInfoProvider).value?.appVersion;
    if (offer == null) return const SizedBox.shrink();
    return PopScope(
      canPop: !state.busy,
      child: AlertDialog(
        title: Text(l10n.updateDialogTitle(offer.fullVersion)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (current != null)
                Text(
                  l10n.updateCurrentVersion(current),
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.mutedForeground,
                  ),
                ),
              if (offer.notes.trim().isNotEmpty) ...[
                SizedBox(height: spacing.sm),
                UpdateNotes(notes: offer.notes.trim(), maxHeight: context.sizes.notesMaxHeight),
              ],
              SizedBox(height: spacing.sm),
              const UpdateStatusLine(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: state.busy ? null : () => Navigator.of(context).pop(),
            child: Text(l10n.updateLater),
          ),
          FilledButton(
            onPressed: state.busy
                ? null
                : () => ref.read(updateControllerProvider.notifier).install(),
            child: Text(updateActionLabel(context, offer)),
          ),
        ],
      ),
    );
  }
}
