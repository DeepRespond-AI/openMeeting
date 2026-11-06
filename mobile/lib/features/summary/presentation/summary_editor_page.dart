import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception_l10n.dart';
import '../../../core/config/app_config_provider.dart';
import '../../../core/theme/context_extensions.dart';
import 'summary_controller.dart';
import 'widgets/summary_markdown.dart';

/// Opens the full-screen Markdown editor for a meeting summary.
Future<void> openSummaryEditor(BuildContext context, String meetingId, String markdown) =>
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => SummaryEditorPage(meetingId: meetingId, initialMarkdown: markdown),
      ),
    );

/// Markdown text editor with a preview tab; saves with `PUT {"summary":{"markdown": md}}`.
class SummaryEditorPage extends ConsumerStatefulWidget {
  const SummaryEditorPage({super.key, required this.meetingId, required this.initialMarkdown});

  final String meetingId;
  final String initialMarkdown;

  @override
  ConsumerState<SummaryEditorPage> createState() => _SummaryEditorPageState();
}

class _SummaryEditorPageState extends ConsumerState<SummaryEditorPage> {
  late final TextEditingController _text = TextEditingController(text: widget.initialMarkdown);
  bool _saving = false;

  bool get _dirty => _text.text != widget.initialMarkdown;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final duration = ref.read(appConfigProvider).ui.snackBarDuration;
    setState(() => _saving = true);
    try {
      await ref.read(summaryControllerProvider(widget.meetingId).notifier).save(_text.text);
      messenger.showSnackBar(SnackBar(content: Text(l10n.summarySaved), duration: duration));
      navigator.pop();
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.summarySaveFailed(describeError(e, l10n))),
          duration: duration,
          backgroundColor: context.colors.destructive,
        ),
      );
    }
  }

  Future<bool> _confirmDiscard() async {
    final l10n = context.l10n;
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.summaryDiscardTitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.summaryDiscard),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _text,
      builder: (context, value, _) => PopScope(
        canPop: !_dirty || _saving,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          final navigator = Navigator.of(context);
          if (await _confirmDiscard()) navigator.pop();
        },
        child: DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: Text(l10n.summaryEdit),
              actions: [
                TextButton(
                  onPressed: _saving || value.text.trim().isEmpty ? null : _save,
                  child: Text(_saving ? l10n.commonSaving : l10n.commonSave),
                ),
              ],
              bottom: TabBar(
                tabs: [
                  Tab(text: l10n.summaryEditTab),
                  Tab(text: l10n.summaryPreviewTab),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                Padding(
                  padding: context.spacing.page,
                  child: TextField(
                    controller: _text,
                    expands: true,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    textAlignVertical: TextAlignVertical.top,
                    style: context.textTheme.bodyMedium,
                    decoration: InputDecoration(hintText: l10n.summaryEditHint),
                  ),
                ),
                SingleChildScrollView(
                  padding: context.spacing.page,
                  child: SummaryMarkdown(markdown: value.text),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
