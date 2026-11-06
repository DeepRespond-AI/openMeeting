import 'package:flutter/material.dart';

import '../../../../core/theme/context_extensions.dart';

/// A titled card grouping settings rows.
class SettingsSection extends StatelessWidget {
  const SettingsSection({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.only(left: context.spacing.xxs, bottom: context.spacing.xs),
            child: Text(
              title,
              style: context.textTheme.labelLarge?.copyWith(color: context.colors.mutedForeground),
            ),
          ),
          // Shadow outside, Material inside: ListTile ink needs a Material ancestor.
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: context.radius.lgAll,
              boxShadow: context.shadows.card,
            ),
            child: Material(
              color: context.colors.surface,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: context.radius.lgAll,
                side: BorderSide(color: context.colors.border, width: context.sizes.borderWidth),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < children.length; i++) ...[
                    if (i > 0)
                      Divider(
                        height: context.sizes.borderWidth,
                        thickness: context.sizes.borderWidth,
                        color: context.colors.border,
                      ),
                    children[i],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows a list of options in a bottom sheet; resolves to the picked value (null = dismissed).
Future<T?> showOptionSheet<T>(
  BuildContext context, {
  required String title,
  required List<T> options,
  required T selected,
  required String Function(T) labelOf,
  String Function(T)? subtitleOf,
}) => showModalBottomSheet<T>(
  context: context,
  // Not scroll-controlled: the sheet is capped at the default height and the list scrolls.
  showDragHandle: true,
  builder: (sheetContext) => SafeArea(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: sheetContext.spacing.pageHorizontal,
          child: Text(title, style: sheetContext.textTheme.titleMedium),
        ),
        sheetContext.spacing.gapXs,
        Flexible(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final option in options)
                ListTile(
                  title: Text(labelOf(option)),
                  subtitle: subtitleOf == null ? null : Text(subtitleOf(option)),
                  trailing: option == selected
                      ? Icon(Icons.check, color: sheetContext.colors.primary)
                      : null,
                  onTap: () => Navigator.of(sheetContext).pop(option),
                ),
            ],
          ),
        ),
      ],
    ),
  ),
);
