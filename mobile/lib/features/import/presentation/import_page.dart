import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/api_exception_l10n.dart';
import '../../../core/config/app_config_provider.dart';
import '../../../core/config/settings_controller.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/context_extensions.dart';
import '../../../core/widgets/text_limit.dart';
import '../../meetings/domain/meeting_detail_route.dart';
import '../domain/job_run_state.dart';
import 'import_controller.dart';

/// Bytes per megabyte for the file size label.
const int _bytesPerMb = 1024 * 1024;

/// Import an audio file as a new meeting: pick → title / language → upload with progress →
/// open the meeting. The server transcribes it in the background (`BackgroundImports`).
class ImportPage extends ConsumerStatefulWidget {
  const ImportPage({super.key});

  @override
  ConsumerState<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends ConsumerState<ImportPage> {
  final TextEditingController _title = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  String _failureText(JobFailed failed, AppLocalizations l10n) =>
      failed.message ??
      (failed.error ?? const ApiException(kind: ApiErrorKind.unknown)).describe(l10n);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.spacing;
    final config = ref.watch(appConfigProvider);
    final state = ref.watch(importControllerProvider);
    final controller = ref.read(importControllerProvider.notifier);

    ref.listen(importControllerProvider, (prev, next) {
      // Picking a file fills in the default title.
      if (prev?.file != next.file && next.title != _title.text) _title.text = next.title;
      final run = next.run;
      if (prev?.run == run) return;
      if (run is JobSubmitted) {
        final meetingId = run.job.meetingId;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.importUploadedBackground),
            duration: config.ui.snackBarDuration,
          ),
        );
        if (meetingId != null) {
          final autoSummary = ref.read(effectiveSettingsProvider).autoSummary;
          context.go(MeetingDetailRoute.location(meetingId, autoSummary: autoSummary));
        }
      }
    });

    if (!config.features.importAudio) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.navImport)),
        body: Center(child: Text(l10n.importDisabled)),
      );
    }

    final run = state.run;
    final busy = run.isActive;
    final file = state.file;

    return PopScope(
      canPop: !busy,
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.navImport)),
        body: ListView(
          padding: spacing.page,
          children: [
            Text(
              l10n.importDescription,
              style: context.textTheme.bodyMedium?.copyWith(color: context.colors.mutedForeground),
            ),
            context.spacing.gapMd,
            _FileCard(
              fileName: file?.name,
              fileSize: file?.size,
              formats: config.importFile.allowedExtensions.join(', '),
              onPick: busy ? null : controller.pickFile,
            ),
            if (file != null) ...[
              context.spacing.gapMd,
              TextField(
                controller: _title,
                maxLength: config.live.titleMax,
                maxLengthEnforcement: MaxLengthEnforcement.none,
                inputFormatters: [CodePointLengthFormatter(config.live.titleMax)],
                buildCounter: codePointCounter(_title, config.live.titleMax),
                enabled: !busy,
                onChanged: controller.setTitle,
                decoration: InputDecoration(
                  labelText: l10n.importMeetingTitle,
                  hintText: l10n.importTitleHint,
                ),
              ),
              context.spacing.gapMd,
              DropdownButtonFormField<String>(
                initialValue: config.transcription.languages.contains(state.language)
                    ? state.language
                    : config.transcription.languages.first,
                decoration: InputDecoration(labelText: l10n.meetingsTranscriptionLanguage),
                items: [
                  for (final code in config.transcription.languages)
                    DropdownMenuItem(value: code, child: Text(l10n.meetingsLanguageName(code))),
                ],
                onChanged: busy
                    ? null
                    : (v) {
                        if (v != null) controller.setLanguage(v);
                      },
              ),
              SizedBox(height: spacing.xs),
              Text(
                l10n.importLanguageHint,
                style: context.textTheme.bodySmall?.copyWith(color: context.colors.mutedForeground),
              ),
            ],
            context.spacing.gapLg,
            if (run case JobUploading(:final fraction)) _UploadProgress(fraction: fraction),
            if (run is JobFailed)
              Text(
                l10n.importFailedDetail(_failureText(run, l10n)),
                style: context.textTheme.bodyMedium?.copyWith(color: context.colors.destructive),
              ),
            if (run is JobCancelled)
              Text(
                l10n.importCancelled,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colors.mutedForeground,
                ),
              ),
            context.spacing.gapMd,
            if (busy)
              OutlinedButton(onPressed: controller.cancel, child: Text(l10n.commonCancel))
            else
              FilledButton.icon(
                onPressed: state.canStart ? controller.start : null,
                icon: const Icon(Icons.cloud_upload_outlined),
                label: Text(run is JobFailed ? l10n.commonRetry : l10n.importStart),
              ),
          ],
        ),
      ),
    );
  }
}

class _FileCard extends StatelessWidget {
  const _FileCard({
    required this.fileName,
    required this.fileSize,
    required this.formats,
    required this.onPick,
  });

  final String? fileName;
  final int? fileSize;
  final String formats;
  final VoidCallback? onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final muted = context.textTheme.bodySmall?.copyWith(color: colors.mutedForeground);
    final name = fileName;
    final size = fileSize;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPick,
        child: Padding(
          padding: context.spacing.card,
          child: Row(
            children: [
              Container(
                width: context.sizes.touchTarget,
                height: context.sizes.touchTarget,
                decoration: BoxDecoration(
                  color: colors.brand50,
                  borderRadius: context.radius.mdAll,
                ),
                child: Icon(Icons.audio_file_outlined, color: colors.brand600),
              ),
              SizedBox(width: context.spacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name ?? l10n.importPickFile,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.titleSmall,
                    ),
                    SizedBox(height: context.spacing.xxs),
                    Text(
                      name == null
                          ? l10n.importSupportedFormats(formats)
                          : size == null
                          ? l10n.importChangeFile
                          : l10n.importFileSize((size / _bytesPerMb).toStringAsFixed(1)),
                      style: muted,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colors.mutedForeground),
            ],
          ),
        ),
      ),
    );
  }
}

/// Upload progress; once uploaded the page is left and the server transcribes in the background.
class _UploadProgress extends StatelessWidget {
  const _UploadProgress({required this.fraction});

  /// 0..1.
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final progress = fraction.clamp(0.0, 1.0);
    // Every byte is sent: waiting for the server to accept the file.
    final sent = progress >= 1;
    return Padding(
      padding: EdgeInsets.only(bottom: context.spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: context.radius.pillAll,
            child: LinearProgressIndicator(
              value: sent ? null : progress,
              minHeight: context.spacing.xs,
            ),
          ),
          SizedBox(height: context.spacing.xs),
          Row(
            children: [
              Expanded(
                child: Text(
                  sent ? l10n.importSubmitting : l10n.importUploading,
                  style: context.textTheme.bodySmall,
                ),
              ),
              if (!sent)
                Text(
                  l10n.meetingsJobProgress((progress * 100).round()),
                  style: context.textTheme.bodySmall,
                ),
            ],
          ),
          SizedBox(height: context.spacing.xxs),
          Text(
            l10n.importBackgroundHint,
            style: context.textTheme.bodySmall?.copyWith(color: context.colors.mutedForeground),
          ),
        ],
      ),
    );
  }
}
