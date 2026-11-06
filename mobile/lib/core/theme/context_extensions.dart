import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import 'app_colors.dart';
import 'app_spacing.dart';

/// Design-token and localization shortcuts for widgets:
/// `context.colors.primary`, `context.spacing.md`, `context.radius.mdAll`,
/// `context.sizes.iconLg`, `context.shadows.card`, `context.l10n.commonOk`.
extension AppContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;

  AppColors get colors => Theme.of(this).extension<AppColors>() ?? AppColors.light;
  AppSpacing get spacing => Theme.of(this).extension<AppSpacing>() ?? AppSpacing.standard;
  AppRadius get radius => Theme.of(this).extension<AppRadius>() ?? AppRadius.standard;
  AppSizes get sizes => Theme.of(this).extension<AppSizes>() ?? AppSizes.standard;
  AppShadows get shadows => Theme.of(this).extension<AppShadows>() ?? AppShadows.light;

  AppLocalizations get l10n => AppLocalizations.of(this);
}
