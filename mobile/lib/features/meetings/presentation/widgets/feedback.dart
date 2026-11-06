import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config_provider.dart';
import '../../../../core/theme/context_extensions.dart';
import '../../../../core/widgets/text_limit.dart';

/// Shows a floating SnackBar for `AppConfig.ui.snackBarDuration`.
void showSnack(BuildContext context, WidgetRef ref, String message, {bool error = false}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: ref.read(appConfigProvider).ui.snackBarDuration,
        backgroundColor: error ? context.colors.destructive : null,
      ),
    );
}

/// Confirmation dialog; resolves to `true` when confirmed.
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(dialogContext.l10n.commonCancel),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: dialogContext.colors.destructive,
                  foregroundColor: dialogContext.colors.onDestructive,
                )
              : null,
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Single-line text prompt (rename). Resolves to the trimmed text, or `null` when cancelled.
Future<String?> promptText(
  BuildContext context, {
  required String title,
  required String initialValue,
  required String hint,
  required String emptyError,
  required int maxLength,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _PromptDialog(
      title: title,
      initialValue: initialValue,
      hint: hint,
      emptyError: emptyError,
      maxLength: maxLength,
    ),
  );
}

class _PromptDialog extends StatefulWidget {
  const _PromptDialog({
    required this.title,
    required this.initialValue,
    required this.hint,
    required this.emptyError,
    required this.maxLength,
  });

  final String title;
  final String initialValue;
  final String hint;
  final String emptyError;
  final int maxLength;

  @override
  State<_PromptDialog> createState() => _PromptDialogState();
}

class _PromptDialogState extends State<_PromptDialog> {
  late final TextEditingController _controller = TextEditingController(text: widget.initialValue);
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.runes.length > widget.maxLength) {
      setState(() => _error = context.l10n.commonTextTooLong(widget.maxLength));
      return;
    }
    if (value.isEmpty) {
      setState(() => _error = widget.emptyError);
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        maxLength: widget.maxLength,
        maxLengthEnforcement: MaxLengthEnforcement.none,
        inputFormatters: [CodePointLengthFormatter(widget.maxLength)],
        buildCounter: codePointCounter(_controller, widget.maxLength),
        onChanged: (_) => setState(() => _error = null),
        autofocus: true,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(hintText: widget.hint, errorText: _error),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.commonCancel),
        ),
        FilledButton(onPressed: _submit, child: Text(context.l10n.commonSave)),
      ],
    );
  }
}
