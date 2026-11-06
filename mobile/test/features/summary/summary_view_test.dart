import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:meeting/core/theme/app_theme.dart';
import 'package:meeting/features/summary/domain/summary_document.dart';
import 'package:meeting/features/summary/presentation/widgets/summary_markdown.dart';

Future<void> _pump(WidgetTester tester, SummaryDocument document) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(
      body: SingleChildScrollView(child: SummaryView(document: document)),
    ),
  ),
);

void main() {
  testWidgets('HTML summaries render as HTML; blocked content is dropped', (tester) async {
    await _pump(
      tester,
      const SummaryDocument(
        content:
            '<h2 style="color:#1F55F0">要点</h2><p>预算已确定</p>'
            '<table><tr><th>负责人</th></tr><tr><td>张三</td></tr></table>'
            '<img src="https://example.com/x.png"><script>alert(1)</script>',
        format: SummaryFormat.html,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(HtmlWidget), findsOneWidget);
    expect(find.textContaining('要点', findRichText: true), findsOneWidget);
    expect(find.textContaining('张三', findRichText: true), findsOneWidget);
    expect(find.textContaining('alert', findRichText: true), findsNothing);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('mixed summaries render Markdown with embedded HTML', (tester) async {
    await _pump(
      tester,
      const SummaryDocument(content: '## 要点\n\n预算 <mark>已确定</mark>', format: SummaryFormat.mixed),
    );
    await tester.pumpAndSettle();
    expect(find.byType(HtmlWidget), findsOneWidget);
    expect(find.textContaining('已确定', findRichText: true), findsOneWidget);
    expect(find.textContaining('<mark>', findRichText: true), findsNothing);
  });

  testWidgets('Markdown summaries keep the Markdown renderer', (tester) async {
    await _pump(tester, const SummaryDocument(content: '## 要点'));
    await tester.pumpAndSettle();
    expect(find.byType(HtmlWidget), findsNothing);
    expect(find.byType(SummaryMarkdown), findsOneWidget);
  });
}
