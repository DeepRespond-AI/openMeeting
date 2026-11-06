import 'package:freezed_annotation/freezed_annotation.dart';

part 'summary_document.freezed.dart';

/// How a summary body is rendered (server/API.md §1.6 `format`; missing = [markdown]).
enum SummaryFormat {
  /// GitHub-flavored Markdown without HTML.
  markdown('markdown'),

  /// HTML fragment styled with inline `style` attributes.
  html('html'),

  /// Markdown with embedded raw HTML.
  mixed('mixed');

  const SummaryFormat(this.wire);

  /// Value of the `format` field.
  final String wire;

  static SummaryFormat fromWire(Object? value) =>
      values.firstWhere((f) => f.wire == value, orElse: () => markdown);

  /// Only plain Markdown summaries are edited in the app (HTML / mixed are read-only, as on desktop).
  bool get isEditable => this == markdown;
}

/// A summary body plus the format it must be rendered with.
@freezed
abstract class SummaryDocument with _$SummaryDocument {
  const factory SummaryDocument({
    required String content,
    @Default(SummaryFormat.markdown) SummaryFormat format,
  }) = _SummaryDocument;
}
