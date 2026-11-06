import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../../../../core/theme/context_extensions.dart';
import '../../domain/summary_document.dart';
import 'summary_html.dart';

/// Markdown styled from the app theme tokens.
MarkdownStyleSheet summaryMarkdownStyle(BuildContext context) {
  final colors = context.colors;
  final spacing = context.spacing;
  final text = context.textTheme;
  final body = text.bodyMedium?.copyWith(color: colors.foreground);
  return MarkdownStyleSheet.fromTheme(context.theme).copyWith(
    p: body,
    listBullet: body,
    h1: text.titleLarge?.copyWith(color: colors.foreground, fontWeight: FontWeight.w700),
    h2: text.titleMedium?.copyWith(color: colors.foreground, fontWeight: FontWeight.w700),
    h3: text.titleSmall?.copyWith(color: colors.foreground, fontWeight: FontWeight.w600),
    h1Padding: EdgeInsets.only(top: spacing.sm),
    h2Padding: EdgeInsets.only(top: spacing.sm),
    h3Padding: EdgeInsets.only(top: spacing.xs),
    blockSpacing: spacing.xs,
    a: body?.copyWith(color: colors.primary),
    strong: body?.copyWith(fontWeight: FontWeight.w600),
    code: text.bodySmall?.copyWith(color: colors.onSecondary, backgroundColor: colors.muted),
    codeblockDecoration: BoxDecoration(color: colors.muted, borderRadius: context.radius.smAll),
    blockquote: body?.copyWith(color: colors.mutedForeground),
    blockquoteDecoration: BoxDecoration(
      color: colors.brand50,
      border: Border(
        left: BorderSide(color: colors.brand500, width: spacing.xxs),
      ),
    ),
    tableBorder: TableBorder.all(color: colors.border, width: context.sizes.borderWidth),
    tableHead: body?.copyWith(fontWeight: FontWeight.w600),
    tableBody: body,
    horizontalRuleDecoration: BoxDecoration(
      border: Border(
        top: BorderSide(color: colors.border, width: context.sizes.borderWidth),
      ),
    ),
  );
}

/// Read-only rendering of a summary in its format (Markdown, HTML or mixed).
class SummaryView extends StatelessWidget {
  const SummaryView({super.key, required this.document, this.dimmed = false});

  final SummaryDocument document;

  /// Rendered greyed out (previous summary while regenerating).
  final bool dimmed;

  static const double _dimmedOpacity = 0.5;

  @override
  Widget build(BuildContext context) {
    final body = switch (document.format) {
      SummaryFormat.markdown => SummaryMarkdown(markdown: document.content),
      SummaryFormat.html || SummaryFormat.mixed => SummaryHtml(document: document),
    };
    return dimmed ? Opacity(opacity: _dimmedOpacity, child: body) : body;
  }
}

/// Read-only rendering of a Markdown summary (also the editor preview).
class SummaryMarkdown extends StatelessWidget {
  const SummaryMarkdown({super.key, required this.markdown});

  final String markdown;

  @override
  Widget build(BuildContext context) =>
      MarkdownBody(data: markdown, selectable: true, styleSheet: summaryMarkdownStyle(context));
}
