import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/context_extensions.dart';
import '../../../core/update/update_controller.dart';
import '../../../core/update/update_models.dart';

String describeUpdateFailure(UpdateFailure failure, AppLocalizations l10n) => switch (failure) {
  UpdateFailure.download => l10n.updateFailedDownload,
  UpdateFailure.checksum => l10n.updateFailedChecksum,
  UpdateFailure.permission => l10n.updateFailedPermission,
  UpdateFailure.install => l10n.updateFailedInstall,
  UpdateFailure.store => l10n.updateFailedStore,
  UpdateFailure.syncing => l10n.updateFailedSyncing,
};

/// Label of the install button: in-app update, or the store page (store channel, iOS).
String updateActionLabel(BuildContext context, UpdateOffer offer) {
  final l10n = context.l10n;
  if (offer.storeUrl == null) return l10n.updateNow;
  return Theme.of(context).platform == TargetPlatform.iOS
      ? l10n.updateGoToAppStore
      : l10n.updateGoToStore;
}

/// Release notes in a scrollable tinted box.
class UpdateNotes extends StatelessWidget {
  const UpdateNotes({super.key, required this.notes, required this.maxHeight});

  final String notes;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(context.l10n.updateNotes, style: context.textTheme.titleSmall),
        SizedBox(height: spacing.xs),
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Container(
            padding: EdgeInsets.all(spacing.sm),
            decoration: BoxDecoration(
              color: context.colors.muted,
              borderRadius: context.radius.mdAll,
            ),
            child: SingleChildScrollView(
              child: Text(
                notes,
                style: context.textTheme.bodySmall?.copyWith(color: context.colors.mutedForeground),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Download progress / installer hint and the last failure of [UpdateController.install].
class UpdateStatusLine extends ConsumerWidget {
  const UpdateStatusLine({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final spacing = context.spacing;
    final state = ref.watch(updateControllerProvider);
    final progress = state.progress;
    final failure = state.failure;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.phase == UpdatePhase.downloading || state.phase == UpdatePhase.installing) ...[
          ClipRRect(
            borderRadius: context.radius.pillAll,
            child: LinearProgressIndicator(value: progress, minHeight: spacing.xs),
          ),
          SizedBox(height: spacing.xs),
          Text(
            state.phase == UpdatePhase.installing
                ? l10n.updateInstalling
                : progress == null
                ? l10n.updateDownloadingUnknown
                : l10n.updateDownloading((progress * 100).round()),
            style: context.textTheme.bodySmall,
          ),
        ],
        if (failure != null)
          Text(
            describeUpdateFailure(failure, l10n),
            style: context.textTheme.bodySmall?.copyWith(color: context.colors.destructive),
          ),
      ],
    );
  }
}
