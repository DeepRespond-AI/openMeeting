import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config_provider.dart';
import '../../../../core/theme/context_extensions.dart';
import '../../../../core/update/update_controller.dart';
import '../../../../core/widgets/brand_logo.dart';
import '../../../update/presentation/update_dialog.dart';
import '../settings_providers.dart';
import 'settings_section.dart';

/// 关于: logo, app name, version and "check for updates".
class AboutSection extends ConsumerWidget {
  const AboutSection({super.key});

  Future<void> _checkForUpdates(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final duration = ref.read(appConfigProvider).ui.snackBarDuration;
    final outcome = await ref.read(updateControllerProvider.notifier).check(manual: true);
    if (!context.mounted) return;
    final offer = ref.read(updateControllerProvider).offer;
    switch (outcome) {
      case UpdateCheckOutcome.available when offer != null && !offer.force:
        await showUpdateDialog(context);
      case UpdateCheckOutcome.available || null:
        break; // forced → the route guard shows the update page; null = already busy
      case UpdateCheckOutcome.upToDate || UpdateCheckOutcome.failed:
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              outcome == UpdateCheckOutcome.upToDate ? l10n.updateUpToDate : l10n.updateCheckFailed,
            ),
            duration: duration,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final version = ref.watch(settingsAppVersionProvider).value;
    final checking = ref.watch(
      updateControllerProvider.select((s) => s.phase == UpdatePhase.checking),
    );
    return SettingsSection(
      title: l10n.settingsAboutSection,
      children: [
        Padding(
          padding: context.spacing.card,
          child: Column(
            children: [
              BrandLogo(height: context.sizes.logoLg),
              context.spacing.gapSm,
              Text(l10n.appName, style: context.textTheme.titleMedium),
              if (version != null)
                Text(
                  l10n.settingsVersion(version),
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.mutedForeground,
                  ),
                ),
            ],
          ),
        ),
        ListTile(
          leading: const Icon(Icons.system_update_outlined),
          title: Text(l10n.updateCheck),
          trailing: checking
              ? SizedBox.square(
                  dimension: context.sizes.iconMd,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.chevron_right),
          onTap: checking ? null : () => _checkForUpdates(context, ref),
        ),
      ],
    );
  }
}
