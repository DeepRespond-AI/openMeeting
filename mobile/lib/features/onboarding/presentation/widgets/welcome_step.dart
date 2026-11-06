import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_enums.dart';
import '../../../../core/config/settings_controller.dart';
import '../../../../core/theme/context_extensions.dart';
import '../../../../core/widgets/brand_logo.dart';
import 'step_scaffold.dart';

/// Step 1: logo, tagline and the UI language (system / 中文 / English).
class WelcomeStep extends ConsumerWidget {
  const WelcomeStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final mode = ref.watch(localeModeProvider);
    return StepScaffold(
      leading: Padding(
        padding: EdgeInsets.only(top: context.spacing.xxl),
        child: BrandLogo(height: context.sizes.logoLg, withTagline: true),
      ),
      title: l10n.onboardingWelcomeTitle,
      description: l10n.onboardingWelcomeBody,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.languageLabel, style: context.textTheme.titleSmall),
          context.spacing.gapXs,
          SegmentedButton<LocaleMode>(
            segments: [
              ButtonSegment(value: LocaleMode.system, label: Text(l10n.languageSystem)),
              ButtonSegment(value: LocaleMode.zh, label: Text(l10n.languageZh)),
              ButtonSegment(value: LocaleMode.en, label: Text(l10n.languageEn)),
            ],
            selected: {mode},
            showSelectedIcon: false,
            onSelectionChanged: (s) =>
                ref.read(settingsControllerProvider.notifier).setLocaleMode(s.first),
          ),
        ],
      ),
    );
  }
}
