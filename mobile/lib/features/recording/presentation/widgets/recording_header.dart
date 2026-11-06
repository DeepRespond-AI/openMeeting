import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config_provider.dart';
import '../../../../core/theme/context_extensions.dart';
import '../../../../core/widgets/text_limit.dart';
import '../../domain/recording_state.dart';
import '../../domain/time_format.dart';
import '../recording_texts.dart';

/// Title (editable once the meeting exists), status chip and elapsed timer.
class RecordingHeader extends ConsumerWidget {
  const RecordingHeader({super.key, required this.state, required this.onRename});

  final RecordingState state;
  final ValueChanged<String> onRename;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final spacing = context.spacing;
    final session = state.session;
    final editable = session != null && (state.isLive || state is RecordingStopping);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                session?.title ?? l10n.recordingNewTitle,
                style: context.textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (editable)
              IconButton(
                tooltip: l10n.recordingRename,
                icon: Icon(Icons.edit_outlined, size: context.sizes.iconMd),
                onPressed: () =>
                    _rename(context, session.title, ref.read(appConfigProvider).live.titleMax),
              ),
            spacing.gapXs,
            _StatusChip(state: state),
          ],
        ),
        spacing.gapSm,
        Text(
          formatElapsed(session?.elapsed ?? Duration.zero),
          style: context.textTheme.displaySmall?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
            color: context.colors.foreground,
          ),
        ),
      ],
    );
  }

  Future<void> _rename(BuildContext context, String current, int maxLength) async {
    final title = await showDialog<String>(
      context: context,
      builder: (context) => _RenameDialog(initial: current, maxLength: maxLength),
    );
    if (title != null) onRename(title);
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.state});

  final RecordingState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final color = switch (state) {
      RecordingActive() => colors.recording,
      RecordingPaused() || RecordingPreparing() || RecordingStopping() => colors.warning,
      RecordingDone() => colors.success,
      RecordingError() => colors.destructive,
      RecordingIdle() => colors.mutedForeground,
    };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: spacing.sm, vertical: spacing.xxs),
      decoration: BoxDecoration(color: colors.muted, borderRadius: context.radius.pillAll),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: spacing.xs,
            height: spacing.xs,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: spacing.xxs),
          Text(
            recordingStatusLabel(state, context.l10n),
            style: context.textTheme.labelMedium?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.initial, required this.maxLength});

  final String initial;
  final int maxLength;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final _controller = TextEditingController(text: widget.initial);
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _controller.text.trim();
    if (title.isEmpty || title.runes.length > widget.maxLength) {
      setState(
        () => _error = title.isEmpty
            ? context.l10n.meetingsTitleEmpty
            : context.l10n.commonTextTooLong(widget.maxLength),
      );
      return;
    }
    Navigator.of(context).pop(title);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.recordingRename),
      content: TextField(
        controller: _controller,
        maxLength: widget.maxLength,
        maxLengthEnforcement: MaxLengthEnforcement.none,
        inputFormatters: [CodePointLengthFormatter(widget.maxLength)],
        buildCounter: codePointCounter(_controller, widget.maxLength),
        autofocus: true,
        decoration: InputDecoration(hintText: l10n.recordingTitleHint, errorText: _error),
        onChanged: (_) => setState(() => _error = null),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.commonCancel)),
        FilledButton(onPressed: _submit, child: Text(l10n.commonSave)),
      ],
    );
  }
}
