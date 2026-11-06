import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_enums.dart';
import '../../../core/theme/context_extensions.dart';
import '../../meetings/domain/meeting_detail_route.dart';
import '../domain/recording_state.dart';
import 'recording_controller.dart';
import 'recording_levels_controller.dart';
import 'recording_options_controller.dart';
import 'recording_texts.dart';
import 'widgets/level_waveform.dart';
import 'widgets/live_transcript_list.dart';
import 'widgets/record_button.dart';
import 'widgets/recording_header.dart';
import 'widgets/recording_option_chips.dart';

/// Live recording screen: header (title, status, timer), waveform, source/language chips,
/// live transcript and the record/pause controls. All state lives in [RecordingController].
class RecordingPage extends ConsumerWidget {
  const RecordingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final spacing = context.spacing;
    final state = ref.watch(recordingControllerProvider);
    final controller = ref.read(recordingControllerProvider.notifier);

    ref.listen(recordingControllerProvider, (previous, next) {
      if (next case RecordingDone(:final meetingId, :final autoSummary)) {
        controller.reset();
        context.go(MeetingDetailRoute.location(meetingId, autoSummary: autoSummary));
      }
    });

    final session = state.session;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navRecording)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: context.sizes.maxContentWidth),
            child: Padding(
              padding: spacing.page,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Card(
                    child: Column(
                      children: [
                        RecordingHeader(state: state, onRename: controller.rename),
                        spacing.gapSm,
                        LevelWaveform(
                          levels: ref.watch(recordingLevelsControllerProvider),
                          active: state is RecordingActive,
                        ),
                      ],
                    ),
                  ),
                  spacing.gapMd,
                  if (!state.isBusy && state is! RecordingError) ...[
                    RecordingOptionChips(enabled: !state.isBusy),
                    spacing.gapMd,
                  ],
                  _StatusBanner(state: state),
                  Expanded(
                    child: _Card(
                      padding: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: EdgeInsets.fromLTRB(spacing.md, spacing.sm, spacing.md, 0),
                            child: Text(
                              l10n.recordingTranscriptTitle,
                              style: context.textTheme.titleSmall,
                            ),
                          ),
                          Expanded(
                            child: LiveTranscriptList(
                              transcripts: session?.transcripts ?? const [],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  spacing.gapLg,
                  _Controls(state: state),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding ?? context.spacing.card,
    decoration: BoxDecoration(
      color: context.colors.surface,
      borderRadius: context.radius.lgAll,
      border: Border.all(color: context.colors.border, width: context.sizes.borderWidth),
      boxShadow: context.shadows.card,
    ),
    child: child,
  );
}

/// Record / stop button with pause-resume beside it.
class _Controls extends ConsumerWidget {
  const _Controls({required this.state});

  final RecordingState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(recordingControllerProvider.notifier);
    final l10n = context.l10n;
    final live = state.isLive;
    final busy = state is RecordingPreparing || state is RecordingStopping;
    final sideWidth = context.sizes.recordButton;

    Widget side(Widget? child) => SizedBox(
      width: sideWidth,
      child: Center(child: child),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        side(null),
        RecordButton(
          live: live,
          busy: busy,
          onPressed: switch (state) {
            RecordingIdle() => controller.start,
            RecordingActive() || RecordingPaused() => controller.stop,
            _ => null,
          },
        ),
        side(switch (state) {
          RecordingActive() => IconButton.filledTonal(
            tooltip: l10n.recordingPause,
            iconSize: context.sizes.iconLg,
            icon: const Icon(Icons.pause_rounded),
            onPressed: controller.pause,
          ),
          RecordingPaused() => IconButton.filledTonal(
            tooltip: l10n.recordingResume,
            iconSize: context.sizes.iconLg,
            icon: const Icon(Icons.play_arrow_rounded),
            onPressed: controller.resume,
          ),
          _ => null,
        }),
      ],
    );
  }
}

/// Context line above the transcript: interruption hint, pending uploads, stopping
/// progress, or an error with recovery actions.
class _StatusBanner extends ConsumerWidget {
  const _StatusBanner({required this.state});

  final RecordingState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final spacing = context.spacing;
    final controller = ref.read(recordingControllerProvider.notifier);
    final pending = state.session?.pendingUploads ?? 0;

    final Widget? content = switch (state) {
      RecordingPaused(interrupted: true) => _BannerText(
        icon: Icons.phone_paused_outlined,
        color: colors.warning,
        text: l10n.recordingInterruptedHint,
      ),
      RecordingStopping() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LinearProgressIndicator(),
          spacing.gapXs,
          Text(l10n.recordingStoppingHint, style: context.textTheme.bodySmall),
        ],
      ),
      RecordingError(:final error) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BannerText(
            icon: Icons.error_outline,
            color: colors.destructive,
            text: l10n.recordingErrorStartTitle,
          ),
          Padding(
            padding: EdgeInsets.only(top: spacing.xxs),
            child: Text(describeRecordingError(error, l10n), style: context.textTheme.bodySmall),
          ),
          spacing.gapXs,
          Wrap(
            spacing: spacing.xs,
            children: [
              if (ref.read(recordingOptionsControllerProvider).source == RecordingSource.system)
                FilledButton(
                  onPressed: () {
                    ref
                        .read(recordingOptionsControllerProvider.notifier)
                        .setSource(RecordingSource.microphone);
                    controller.reset();
                  },
                  child: Text(l10n.recordingUseMicrophone),
                ),
              TextButton(onPressed: controller.reset, child: Text(l10n.commonClose)),
            ],
          ),
        ],
      ),
      _ when pending > 0 => _BannerText(
        icon: Icons.cloud_off_outlined,
        color: colors.warning,
        text: l10n.recordingPendingUploads(pending),
      ),
      _ => null,
    };
    if (content == null) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(bottom: spacing.md),
      child: content,
    );
  }
}

class _BannerText extends StatelessWidget {
  const _BannerText({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: color, size: context.sizes.iconMd),
      context.spacing.gapXs,
      Expanded(
        child: Text(text, style: context.textTheme.bodyMedium?.copyWith(color: color)),
      ),
    ],
  );
}
