import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/data/client_info_source.dart';
import '../../../core/theme/context_extensions.dart';
import '../../../core/update/update_controller.dart';
import '../../../core/widgets/brand_logo.dart';
import 'update_widgets.dart';

/// Forced update (route guard sends every route here while one is pending, except during a
/// recording): the only action is updating.
class ForceUpdatePage extends ConsumerWidget {
  const ForceUpdatePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final spacing = context.spacing;
    final state = ref.watch(updateControllerProvider);
    final offer = state.offer;
    final current = ref.watch(clientInfoProvider).value?.appVersion ?? '';
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: context.sizes.maxContentWidth),
              child: ListView(
                shrinkWrap: true,
                padding: spacing.page,
                children: [
                  BrandLogo(height: context.sizes.logoLg),
                  SizedBox(height: spacing.lg),
                  Text(
                    l10n.updateForceTitle,
                    textAlign: TextAlign.center,
                    style: context.textTheme.titleLarge,
                  ),
                  if (offer != null) ...[
                    SizedBox(height: spacing.xs),
                    Text(
                      l10n.updateForceMessage(current, offer.fullVersion),
                      textAlign: TextAlign.center,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.colors.mutedForeground,
                      ),
                    ),
                    if (offer.notes.trim().isNotEmpty) ...[
                      SizedBox(height: spacing.lg),
                      UpdateNotes(
                        notes: offer.notes.trim(),
                        maxHeight: context.sizes.notesMaxHeight,
                      ),
                    ],
                    SizedBox(height: spacing.lg),
                    const UpdateStatusLine(),
                    SizedBox(height: spacing.sm),
                    FilledButton.icon(
                      onPressed: state.busy
                          ? null
                          : () => ref.read(updateControllerProvider.notifier).install(),
                      icon: const Icon(Icons.system_update_outlined),
                      label: Text(updateActionLabel(context, offer)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
