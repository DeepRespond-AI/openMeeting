import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:markdown/markdown.dart' as md;

import '../../../../core/theme/context_extensions.dart';
import '../../domain/summary_document.dart';

/// HTML for a summary body: `html` as-is, `mixed` (Markdown + raw HTML) converted with GFM.
String summaryHtmlOf(SummaryDocument document) => switch (document.format) {
  SummaryFormat.html => document.content,
  SummaryFormat.mixed || SummaryFormat.markdown => md.markdownToHtml(
    document.content,
    extensionSet: md.ExtensionSet.gitHubFlavored,
  ),
};

/// Read-only rendering of HTML / mixed summaries, styled from the theme tokens.
///
/// Model output is untrusted: scripts never run (the renderer has no JS), and embedded content
/// or controls ([_blockedTags]) is dropped. Links are not opened.
class SummaryHtml extends StatelessWidget {
  const SummaryHtml({super.key, required this.document});

  final SummaryDocument document;

  static const Set<String> _blockedTags = {
    'img',
    'picture',
    'video',
    'audio',
    'iframe',
    'frame',
    'object',
    'embed',
    'canvas',
    'svg',
    'form',
    'input',
    'button',
    'select',
    'textarea',
    'script',
    'style',
    'link',
    'meta',
    'base',
  };

  /// Opacity of the `<mark>` highlight over the warning color.
  static const double _markAlpha = 0.3;

  static String _css(Color color) {
    int channel(double v) => (v * 255).round();
    return 'rgba(${channel(color.r)}, ${channel(color.g)}, ${channel(color.b)}, ${color.a})';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final border = '${context.sizes.borderWidth}px solid ${_css(colors.border)}';
    final cellPadding = '${spacing.xxs}px ${spacing.xs}px';
    return SelectionArea(
      child: HtmlWidget(
        summaryHtmlOf(document),
        textStyle: context.textTheme.bodyMedium?.copyWith(color: colors.foreground),
        onTapUrl: (_) => true,
        customWidgetBuilder: (element) =>
            _blockedTags.contains(element.localName) ? const SizedBox.shrink() : null,
        customStylesBuilder: (element) => switch (element.localName) {
          'table' => {'border-collapse': 'collapse', 'border': border},
          'th' => {
            'border': border,
            'padding': cellPadding,
            'background-color': _css(colors.muted),
          },
          'td' => {'border': border, 'padding': cellPadding},
          'blockquote' => {
            'border-left': '${spacing.xxs}px solid ${_css(colors.brand500)}',
            'background-color': _css(colors.brand50),
            'padding': '${spacing.xxs}px ${spacing.sm}px',
            'margin': '${spacing.xs}px 0',
          },
          'code' => {'background-color': _css(colors.muted)},
          'a' => {'color': _css(colors.primary)},
          'mark' => {'background-color': _css(colors.warning.withValues(alpha: _markAlpha))},
          'h1' || 'h2' || 'h3' || 'h4' => {'color': _css(colors.foreground)},
          _ => null,
        },
      ),
    );
  }
}
