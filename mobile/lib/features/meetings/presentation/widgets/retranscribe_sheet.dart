import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_exception.dart';
import '../../../../core/api/api_exception_l10n.dart';
import '../../../../core/config/app_config_provider.dart';
import '../../../../core/config/settings_controller.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/context_extensions.dart';
import '../../../import/domain/job_run_state.dart';
import '../retranscribe_controller.dart';

/// Opens the retranscription bottom sheet (desktop `RetranscribeDialog`).
Future<void> showRetranscribeSheet(BuildContext context, String meetingId) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => RetranscribeSheet(meetingId: meetingId),
    );

/// Text for a failed job (409 → "already running").
String describeJobFailure(JobFailed failed, AppLocalizations l10n) {
  final error = failed.error;
  if (error != null && error.kind == ApiErrorKind.conflict) {
    return l10n.meetingsRetranscribeAlreadyRunning;
  }
  return failed.message ?? (error ?? const ApiException(kind: ApiErrorKind.unknown)).describe(l10n);
}

class RetranscribeSheet extends ConsumerStatefulWidget {
  const RetranscribeSheet({super.key, required this.meetingId});

  final String meetingId;

  @override
  ConsumerState<RetranscribeSheet> createState() => _RetranscribeSheetState();
}

class _RetranscribeSheetState extends ConsumerState<RetranscribeSheet> {
  late String _language = ref.read(effectiveSettingsProvider).transcriptionLanguage;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.spacing;
    final provider = retranscribeControllerProvider(widget.meetingId);
    final run = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final languages = ref.watch(appConfigProvider.select((c) => c.transcription.languages));
    final language = languages.contains(_language) ? _language : languages.first;

    final Widget status = switch (run) {
      JobUploading() => const LinearProgressIndicator(),
      JobRunning(:final job) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(value: job.progress / 100),
          SizedBox(height: spacing.xxs),
          Text(
            job.message ?? l10n.meetingsRetranscribeRunning,
            style: context.textTheme.bodySmall?.copyWith(color: context.colors.mutedForeground),
          ),
        ],
      ),
      JobCompleted(:final job) => Text(
        l10n.meetingsRetranscribeComplete(job.segments ?? 0),
        style: context.textTheme.bodyMedium?.copyWith(color: context.colors.success),
      ),
      final JobFailed failed => Text(
        describeJobFailure(failed, l10n),
        style: context.textTheme.bodyMedium?.copyWith(color: context.colors.destructive),
      ),
      JobCancelled() => Text(l10n.meetingsRetranscribeCancelled),
      JobIdle() || JobSubmitted() => const SizedBox.shrink(), // submitted: import only
    };

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          spacing.lg,
          0,
          spacing.lg,
          spacing.lg + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.meetingsRetranscribeTitle, style: context.textTheme.titleMedium),
            SizedBox(height: spacing.xs),
            Text(
              l10n.meetingsRetranscribeDescription,
              style: context.textTheme.bodySmall?.copyWith(color: context.colors.mutedForeground),
            ),
            context.spacing.gapMd,
            DropdownButtonFormField<String>(
              initialValue: language,
              decoration: InputDecoration(labelText: l10n.meetingsTranscriptionLanguage),
              items: [
                for (final code in languages)
                  DropdownMenuItem(value: code, child: Text(l10n.meetingsLanguageName(code))),
              ],
              onChanged: run.isActive ? null : (v) => setState(() => _language = v ?? language),
            ),
            SizedBox(height: spacing.xs),
            Text(
              l10n.meetingsRetranscribeHint,
              style: context.textTheme.bodySmall?.copyWith(color: context.colors.mutedForeground),
            ),
            context.spacing.gapMd,
            status,
            context.spacing.gapMd,
            if (run.isActive)
              OutlinedButton(
                onPressed: run is JobRunning ? controller.cancel : null,
                child: Text(l10n.commonCancel),
              )
            else
              FilledButton(
                onPressed: () => controller.start(language),
                child: Text(run is JobFailed ? l10n.commonRetry : l10n.meetingsRetranscribeStart),
              ),
          ],
        ),
      ),
    );
  }
}
