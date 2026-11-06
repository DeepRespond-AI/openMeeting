import 'dart:convert';

import 'summary_document.dart';

/// Parsing of the arbitrary summary `data` JSON (desktop `lib/summary-content.ts`).
///
/// Shapes, in order of preference:
/// 1. `{"markdown": "...", "format"?: "markdown|html|mixed"}` (current server output and manual edits);
/// 2. `{"summary_json": [BlockNote blocks]}` — flattened to Markdown;
/// 3. legacy `{"<key>": {"title", "blocks": [{"content"}]}, "MeetingName", "_section_order"}`.
abstract final class SummaryContent {
  static const String _markdown = 'markdown';
  static const String _format = 'format';
  static const String _summaryJson = 'summary_json';
  static const String _meetingName = 'MeetingName';
  static const String _sectionOrder = '_section_order';
  static const String _normalizationFallback = 'normalization_fallback';
  static final RegExp _reasoningMarker = RegExp(
    r'</?think(?:ing)?(?:\s+[^>]*)?>',
    caseSensitive: false,
  );

  /// The summary as Markdown, or `null` when [data] has no visible content (or contains
  /// model reasoning markers, which the desktop also refuses to show).
  static String? markdownOf(Object? data) {
    final object = _asMap(data);
    if (object == null || _containsReasoning(object)) return null;
    if (object.containsKey(_markdown)) {
      final md = object[_markdown];
      return md is String && md.trim().isNotEmpty ? md : null;
    }
    if (object.containsKey(_summaryJson)) {
      final md = _blocksToMarkdown(_decodeMaybe(object[_summaryJson]), 0).trim();
      return md.isEmpty ? null : md;
    }
    final md = _legacyToMarkdown(object).trim();
    return md.isEmpty ? null : md;
  }

  /// The summary with its render format: `format` applies to the `markdown` body only;
  /// BlockNote / legacy shapes are flattened to Markdown.
  static SummaryDocument? documentOf(Object? data) {
    final content = markdownOf(data);
    if (content == null) return null;
    final object = _asMap(data)!;
    final format = object.containsKey(_markdown)
        ? SummaryFormat.fromWire(object[_format])
        : SummaryFormat.markdown;
    return SummaryDocument(content: content, format: format);
  }

  /// `MeetingName` stored in a legacy summary (the server may rename meetings).
  static String? meetingNameOf(Object? data) {
    final name = _asMap(data)?[_meetingName];
    return name is String && name.trim().isNotEmpty ? name : null;
  }

  /// True when the server fell back to unnormalized output.
  static bool isNormalizationFallback(Object? data) =>
      _asMap(data)?[_normalizationFallback] == true;

  static Map<String, dynamic>? _asMap(Object? data) {
    final decoded = _decodeMaybe(data);
    return decoded is Map<String, dynamic> ? decoded : null;
  }

  static Object? _decodeMaybe(Object? value) {
    if (value is! String) return value;
    try {
      return jsonDecode(value);
    } on FormatException {
      return value;
    }
  }

  static bool _containsReasoning(Object? value) {
    if (value is List) return value.any(_containsReasoning);
    if (value is! Map) return false;
    for (final entry in value.entries) {
      final v = entry.value;
      if (v is String) {
        if ((entry.key == _markdown || entry.key == 'text' || entry.key == 'content') &&
            _reasoningMarker.hasMatch(v)) {
          return true;
        }
      } else if (_containsReasoning(v)) {
        return true;
      }
    }
    return false;
  }

  // ------------------------------------------------------------------ BlockNote

  static String _inlineText(Object? content) {
    if (content is String) return content;
    if (content is List) return content.map(_inlineText).join();
    if (content is Map) {
      final text = content['text'];
      if (text is String) return text;
      return _inlineText(content['content']);
    }
    return '';
  }

  static String _blocksToMarkdown(Object? blocks, int depth) {
    if (blocks is! List) return '';
    final out = StringBuffer();
    final indent = '  ' * depth;
    var number = 0;
    for (final block in blocks) {
      if (block is! Map) continue;
      final type = block['type'];
      final props = block['props'];
      final text = _inlineText(block['content']).trim();
      number = type == 'numberedListItem' ? number + 1 : 0;
      final line = switch (type) {
        'heading' => '${'#' * _headingLevel(props)} $text',
        'bulletListItem' => '$indent- $text',
        'numberedListItem' => '$indent$number. $text',
        'checkListItem' =>
          '$indent- [${props is Map && props['checked'] == true ? 'x' : ' '}] $text',
        _ => '$indent$text',
      };
      if (text.isNotEmpty) {
        out.writeln(line);
        if (type == 'heading' || type == 'paragraph') out.writeln();
      }
      final children = _blocksToMarkdown(block['children'], depth + 1);
      if (children.isNotEmpty) out.write(children);
    }
    return out.toString();
  }

  static int _headingLevel(Object? props) {
    final level = props is Map ? props['level'] : null;
    return level is int && level > 0 ? level : 1;
  }

  // ------------------------------------------------------------------ legacy sections

  static String _legacyToMarkdown(Map<String, dynamic> object) {
    final sections = <String>[];
    for (final entry in object.entries) {
      if (entry.key == _meetingName || entry.key == _sectionOrder) continue;
      final section = entry.value;
      if (section is! Map) continue;
      final title = section['title'];
      final blocks = section['blocks'];
      if (title is! String || blocks is! List) continue;
      final items = [
        for (final b in blocks)
          if (b is Map && b['content'] is String && (b['content'] as String).trim().isNotEmpty)
            '- ${b['content']}',
      ];
      if (items.isEmpty) continue;
      sections.add('## $title\n\n${items.join('\n')}');
    }
    return sections.join('\n\n');
  }
}
