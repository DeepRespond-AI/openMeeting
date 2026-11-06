import 'package:flutter/material.dart';

import '../../../../core/theme/context_extensions.dart';

/// Common layout of an onboarding step: optional leading visual, title, description, content.
class StepScaffold extends StatelessWidget {
  const StepScaffold({
    super.key,
    required this.title,
    required this.description,
    this.leading,
    this.child,
  });

  final String title;
  final String description;
  final Widget? leading;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: context.spacing.xl, vertical: context.spacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (leading != null) ...[leading!, context.spacing.gapXl],
          Text(
            title,
            style: context.textTheme.headlineSmall?.copyWith(
              color: context.colors.foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
          context.spacing.gapXs,
          Text(
            description,
            style: context.textTheme.bodyMedium?.copyWith(color: context.colors.mutedForeground),
          ),
          if (child != null) ...[context.spacing.gapXl, child!],
        ],
      ),
    );
  }
}

/// Round tinted icon used as the visual of a step.
class StepIcon extends StatelessWidget {
  const StepIcon(this.icon, {super.key});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: DecoratedBox(
        decoration: BoxDecoration(color: context.colors.accent, shape: BoxShape.circle),
        child: Padding(
          padding: context.spacing.card,
          child: Icon(icon, size: context.sizes.iconXl, color: context.colors.primary),
        ),
      ),
    );
  }
}
