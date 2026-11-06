import 'package:flutter/material.dart';

import '../theme/context_extensions.dart';

/// Asset paths of brand images.
abstract final class BrandAssets {
  static const String logo = 'assets/brand/brand-logo.png';
}

/// The DR brand logo (`assets/brand/brand-logo.png`). Height defaults to `context.sizes.logoSm`.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.height, this.withTagline = false});

  final double? height;

  /// Shows app name + tagline under the logo (splash / login).
  final bool withTagline;

  @override
  Widget build(BuildContext context) {
    final logo = Image.asset(
      BrandAssets.logo,
      height: height ?? context.sizes.logoSm,
      fit: BoxFit.contain,
      semanticLabel: context.l10n.appName,
    );
    if (!withTagline) return logo;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        logo,
        context.spacing.gapMd,
        Text(
          context.l10n.appName,
          style: context.textTheme.headlineSmall?.copyWith(
            color: context.colors.foreground,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: context.spacing.xxs),
        Text(
          context.l10n.appTagline,
          style: context.textTheme.bodyMedium?.copyWith(color: context.colors.mutedForeground),
        ),
      ],
    );
  }
}
