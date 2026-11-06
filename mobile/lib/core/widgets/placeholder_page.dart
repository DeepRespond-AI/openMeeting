import 'package:flutter/material.dart';

import '../theme/context_extensions.dart';

/// Temporary page body used by route placeholders until a feature replaces it.
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({super.key, required this.title, this.actions, this.child});

  final String title;
  final List<Widget>? actions;

  /// Optional content; defaults to a "coming soon" message.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      body:
          child ??
          Center(
            child: Text(
              context.l10n.commonComingSoon,
              style: context.textTheme.bodyMedium?.copyWith(color: context.colors.mutedForeground),
            ),
          ),
    );
  }
}
