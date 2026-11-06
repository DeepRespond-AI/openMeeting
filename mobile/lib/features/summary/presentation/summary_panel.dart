import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception_l10n.dart';
import '../../../core/config/app_config_provider.dart';
import '../../../core/heartbeat/heartbeat_controller.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/context_extensions.dart';
import '../../../core/widgets/async_value_view.dart';
import '../domain/summary_document.dart';
import '../domain/summary_state.dart';
import 'summary_controller.dart';
import 'summary_editor_page.dart';
import 'widgets/summary_markdown.dart';

/// Localized explanation of a failed generation.
String describeSummaryFailure(SummaryFailed failed, AppLocalizations l10n) {
  final message = failed.message;
  return switch (failed.reason) {
    // Service internals (the server's error detail) are not shown to users.
    SummaryFailure.llmNotReady => l10n.summaryLlmNotReady,
    SummaryFailure.generation =>
      message == null ? l10n.summaryFailedGeneration : l10n.summaryFailedGenerationDetail(message),
    SummaryFailure.emptyResult => l10n.summaryFailedEmpty,
    SummaryFailure.timeout => l10n.summaryFailedTimeout,
    SummaryFailure.request =>
      failed.error == null
          ? l10n.summaryFailedGeneration
          : l10n.summaryFailedGenerationDetail(failed.error!.describe(l10n)),
  };
}

/// "AI summary" tab: optional custom prompt, generate / regenerate / stop, rendering in the
/// summary's format (Markdown / HTML / mixed), edit (Markdown only), copy and share.
/// The server picks the summary template; users never see it.
class SummaryPanel extends ConsumerStatefulWidget {
  const SummaryPanel({
    super.key,
    required this.meetingId,
    required this.onCopy,
    required this.onShare,
    this.canManage = true,
  });

  final String meetingId;
  final bool canManage;

  /// Copies the summary document (the meeting page adds title / date headers).
  final Future<void> Function(String markdown) onCopy;
  final Future<void> Function(String markdown) onShare;

  @override
  ConsumerState<SummaryPanel> createState() => _SummaryPanelState();
}

class _SummaryPanelState extends ConsumerState<SummaryPanel> {
  final TextEditingController _prompt = TextEditingController();

  @override
  void dispose() {
    _prompt.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    await ref
        .read(summaryControllerProvider(widget.meetingId).notifier)
        .generate(customPrompt: _prompt.text);
  }

  Future<void> _stop() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final duration = ref.read(appConfigProvider).ui.snackBarDuration;
    try {
      await ref.read(summaryControllerProvider(widget.meetingId).notifier).stop();
      messenger.showSnackBar(SnackBar(content: Text(l10n.summaryStopped), duration: duration));
    } on Object catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.summaryStopFailed(describeError(e, l10n))), duration: duration),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = summaryControllerProvider(widget.meetingId);
    final summary = ref.watch(provider);
    final spacing = context.spacing;
    return AsyncValueView(
      value: summary,
      onRetry: () => ref.invalidate(provider),
      data: (state) => ListView(
        padding: context.spacing.page,
        children: [
          if (widget.canManage) const _LlmHint(),
          if (widget.canManage) _Controls(state: state, onGenerate: _generate, onStop: _stop),
          if (widget.canManage && !state.isGenerating)
            Theme(
              data: context.theme.copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.only(bottom: spacing.sm),
                title: Text(
                  context.l10n.summaryCustomPromptLabel,
                  style: context.textTheme.bodyMedium,
                ),
                children: [
                  TextField(
                    controller: _prompt,
                    minLines: 2,
                    maxLines: null,
                    decoration: InputDecoration(hintText: context.l10n.summaryCustomPromptHint),
                  ),
                ],
              ),
            ),
          SizedBox(height: spacing.xs),
          _Body(
            meetingId: widget.meetingId,
            state: state,
            onCopy: widget.onCopy,
            onShare: widget.onShare,
            canManage: widget.canManage,
          ),
        ],
      ),
    );
  }
}

class _LlmHint extends ConsumerWidget {
  const _LlmHint();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final llm = ref.watch(capabilitiesProvider.select((c) => c?.llm));
    if (llm == null || llm.ready) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(bottom: context.spacing.sm),
      child: _Notice(
        icon: Icons.warning_amber_rounded,
        color: context.colors.warning,
        text: context.l10n.summaryLlmNotReady,
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: context.spacing.card,
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: context.radius.mdAll,
        border: Border.all(color: color, width: context.sizes.borderWidth),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: context.sizes.iconMd),
          SizedBox(width: context.spacing.xs),
          Expanded(child: Text(text, style: context.textTheme.bodySmall)),
        ],
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.state, required this.onGenerate, required this.onStop});

  final SummaryState state;
  final Future<void> Function() onGenerate;
  final Future<void> Function() onStop;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasSummary = state.visible != null;
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: state.isGenerating
          ? OutlinedButton.icon(
              onPressed: onStop,
              icon: const Icon(Icons.stop_circle_outlined),
              label: Text(l10n.summaryStop),
            )
          : FilledButton.icon(
              onPressed: onGenerate,
              icon: Icon(hasSummary ? Icons.refresh : Icons.auto_awesome),
              label: Text(hasSummary ? l10n.summaryRegenerate : l10n.summaryGenerate),
            ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.meetingId,
    required this.state,
    required this.onCopy,
    required this.onShare,
    required this.canManage,
  });

  final String meetingId;
  final SummaryState state;
  final bool canManage;
  final Future<void> Function(String markdown) onCopy;
  final Future<void> Function(String markdown) onShare;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.spacing;
    final muted = context.textTheme.bodySmall?.copyWith(color: context.colors.mutedForeground);
    switch (state) {
      case SummaryEmpty():
        return Padding(
          padding: EdgeInsets.symmetric(vertical: spacing.xl),
          child: Column(
            children: [
              Icon(Icons.auto_awesome, size: context.sizes.iconXl, color: context.colors.brand500),
              context.spacing.gapSm,
              Text(l10n.summaryEmptyTitle, style: context.textTheme.titleSmall),
              SizedBox(height: spacing.xxs),
              Text(
                canManage ? l10n.summaryEmptyDescription : l10n.liveSharedSummaryEmpty,
                textAlign: TextAlign.center,
                style: muted,
              ),
            ],
          ),
        );
      case SummaryGenerating(:final previous):
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const LinearProgressIndicator(),
            context.spacing.gapSm,
            Text(l10n.summaryGenerating, style: context.textTheme.titleSmall),
            SizedBox(height: spacing.xxs),
            Text(l10n.summaryGeneratingHint, style: muted),
            if (previous != null) ...[
              context.spacing.gapMd,
              SummaryView(document: previous, dimmed: true),
            ],
          ],
        );
      case SummaryReady(:final summary):
        return _SummaryContent(
          meetingId: meetingId,
          summary: summary,
          onCopy: onCopy,
          onShare: onShare,
          canManage: canManage,
        );
      case final SummaryFailed failed:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Notice(
              icon: Icons.error_outline,
              color: context.colors.destructive,
              text: describeSummaryFailure(failed, l10n),
            ),
            if (failed.previous case final previous?) ...[
              context.spacing.gapMd,
              _SummaryContent(
                meetingId: meetingId,
                summary: previous,
                onCopy: onCopy,
                onShare: onShare,
                canManage: canManage,
              ),
            ],
          ],
        );
    }
  }
}

class _SummaryContent extends StatelessWidget {
  const _SummaryContent({
    required this.meetingId,
    required this.summary,
    required this.onCopy,
    required this.onShare,
    required this.canManage,
  });

  final String meetingId;
  final SummaryDocument summary;
  final bool canManage;
  final Future<void> Function(String markdown) onCopy;
  final Future<void> Function(String markdown) onShare;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.end,
          spacing: context.spacing.xs,
          children: [
            if (canManage && summary.format.isEditable)
              TextButton.icon(
                onPressed: () => openSummaryEditor(context, meetingId, summary.content),
                icon: const Icon(Icons.edit_outlined),
                label: Text(l10n.commonEdit),
              ),
            TextButton.icon(
              onPressed: () => onCopy(summary.content),
              icon: const Icon(Icons.copy_outlined),
              label: Text(l10n.commonCopy),
            ),
            TextButton.icon(
              onPressed: () => onShare(summary.content),
              icon: const Icon(Icons.ios_share),
              label: Text(l10n.commonShare),
            ),
          ],
        ),
        Card(
          child: Padding(
            padding: context.spacing.card,
            child: SummaryView(document: summary),
          ),
        ),
      ],
    );
  }
}
