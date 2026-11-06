import 'package:flutter_test/flutter_test.dart';
import 'package:meeting/features/summary/domain/summary_content.dart';
import 'package:meeting/features/summary/domain/summary_document.dart';
import 'package:meeting/features/summary/presentation/widgets/summary_html.dart';

void main() {
  test('markdown field wins', () {
    expect(SummaryContent.markdownOf({'markdown': '## A\n- b'}), '## A\n- b');
    expect(SummaryContent.markdownOf({'markdown': '  '}), isNull);
    expect(SummaryContent.markdownOf(null), isNull);
    expect(SummaryContent.markdownOf('not json'), isNull);
  });

  test('reasoning markers are refused', () {
    expect(SummaryContent.markdownOf({'markdown': '<think>x</think> ok'}), isNull);
  });

  test('BlockNote summary_json is flattened', () {
    final md = SummaryContent.markdownOf({
      'summary_json': [
        {
          'type': 'heading',
          'props': {'level': 2},
          'content': [
            {'type': 'text', 'text': '决策'},
          ],
        },
        {
          'type': 'bulletListItem',
          'content': [
            {'type': 'text', 'text': '上线'},
          ],
          'children': [
            {
              'type': 'bulletListItem',
              'content': [
                {'type': 'text', 'text': '周五'},
              ],
            },
          ],
        },
        {
          'type': 'numberedListItem',
          'content': [
            {'type': 'text', 'text': '一'},
          ],
        },
        {
          'type': 'numberedListItem',
          'content': [
            {'type': 'text', 'text': '二'},
          ],
        },
      ],
    });
    expect(md, '## 决策\n\n- 上线\n  - 周五\n1. 一\n2. 二');
  });

  test('legacy sections', () {
    final md = SummaryContent.markdownOf({
      'MeetingName': '周会',
      '_section_order': ['key'],
      'key': {
        'title': '要点',
        'blocks': [
          {'content': 'A'},
          {'content': ' '},
        ],
      },
      'empty': {'title': '空', 'blocks': <Object>[]},
    });
    expect(md, '## 要点\n\n- A');
    expect(SummaryContent.meetingNameOf({'MeetingName': '周会'}), '周会');
  });

  test('documentOf carries the render format (missing / unknown = markdown)', () {
    expect(
      SummaryContent.documentOf({'markdown': '<p>x</p>', 'format': 'html'}),
      const SummaryDocument(content: '<p>x</p>', format: SummaryFormat.html),
    );
    expect(
      SummaryContent.documentOf({'markdown': 'a', 'format': 'mixed'})?.format,
      SummaryFormat.mixed,
    );
    expect(SummaryContent.documentOf({'markdown': 'a'})?.format, SummaryFormat.markdown);
    expect(
      SummaryContent.documentOf({'markdown': 'a', 'format': 'pdf'})?.format,
      SummaryFormat.markdown,
    );
    expect(SummaryContent.documentOf({'markdown': ' '}), isNull);
    expect(SummaryFormat.html.isEditable, isFalse);
    expect(SummaryFormat.markdown.isEditable, isTrue);
  });

  test('mixed summaries are converted to HTML, keeping embedded tags', () {
    final html = summaryHtmlOf(
      const SummaryDocument(
        content: '## 要点\n\n预算 <mark>已确定</mark>\n\n| a | b |\n| - | - |\n| 1 | 2 |',
        format: SummaryFormat.mixed,
      ),
    );
    expect(html, contains('<h2>要点</h2>'));
    expect(html, contains('<mark>已确定</mark>'));
    expect(html, contains('<table>'));
    const raw = SummaryDocument(content: '<h2>x</h2>', format: SummaryFormat.html);
    expect(summaryHtmlOf(raw), '<h2>x</h2>');
  });
}
