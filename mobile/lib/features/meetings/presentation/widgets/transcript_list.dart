import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/meeting_models.dart';
import '../../../../core/theme/context_extensions.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../domain/meeting_markdown.dart';
import '../meeting_detail_controller.dart';
import '../meeting_player_controller.dart';

/// Transcript tab: paginated rows (infinite scroll); tapping a timestamp seeks + plays,
/// the row under the playhead is highlighted.
class TranscriptList extends ConsumerWidget {
  const TranscriptList({
    super.key,
    required this.meetingId,
    this.processing = false,
    this.recordingStatus = 'none',
    this.statusError = false,
  });

  final String? recordingStatus;
  final bool statusError;

  final String meetingId;

  /// Background work (import transcription / post-recording sync) is still running: an
  /// empty transcript shows "transcribing in the background" instead of "no transcript".
  final bool processing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = transcriptsControllerProvider(meetingId);
    final controller = ref.read(provider.notifier);
    final l10n = context.l10n;
    final pending = processing || ['queued', 'running'].contains(recordingStatus);
    final failed = ['failed', 'cancelled'].contains(recordingStatus);
    final checking = ![
      'none',
      'completed',
      'failed',
      'cancelled',
      'queued',
      'running',
    ].contains(recordingStatus);
    return AsyncValueView(
      value: ref.watch(provider),
      onRetry: controller.refresh,
      data: (data) {
        if (data.items.isEmpty) {
          return RefreshIndicator(
            onRefresh: controller.refresh,
            child: ListView(
              padding: context.spacing.page,
              children: [
                SizedBox(height: context.spacing.xxl),
                if (pending || checking && !statusError)
                  Center(
                    child: SizedBox.square(
                      dimension: context.sizes.iconXl,
                      child: const CircularProgressIndicator(),
                    ),
                  )
                else
                  Icon(
                    Icons.subject,
                    size: context.sizes.iconXl,
                    color: context.colors.mutedForeground,
                  ),
                context.spacing.gapSm,
                Text(
                  pending
                      ? l10n.meetingsTranscriptProcessing
                      : statusError
                      ? l10n.meetingsTranscriptStatusUnavailable
                      : failed
                      ? l10n.meetingsTranscriptProcessingFailed
                      : checking
                      ? l10n.meetingsTranscriptChecking
                      : l10n.meetingsTranscriptEmpty,
                  textAlign: TextAlign.center,
                  style: context.textTheme.titleSmall,
                ),
                context.spacing.gapXs,
                Text(
                  failed || statusError
                      ? l10n.meetingsTranscriptIncompleteHint
                      : pending || checking
                      ? l10n.meetingsTranscriptProcessingHint
                      : l10n.meetingsTranscriptEmptyHint,
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.mutedForeground,
                  ),
                ),
              ],
            ),
          );
        }
        final footer = data.hasMore || data.loadMoreError != null;
        return RefreshIndicator(
          onRefresh: controller.refresh,
          child: ListView.builder(
            padding: EdgeInsets.symmetric(vertical: context.spacing.xs),
            itemCount: data.items.length + (footer ? 1 : 0),
            itemBuilder: (context, i) {
              if (i >= data.items.length) {
                return _Footer(state: data, onRetry: controller.loadMore);
              }
              if (i == data.items.length - 1 && data.hasMore && data.loadMoreError == null) {
                // Reached the end of what is loaded: fetch the next page.
                scheduleMicrotask(() => unawaited(controller.loadMore()));
              }
              return _TranscriptRow(meetingId: meetingId, transcript: data.items[i]);
            },
          ),
        );
      },
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.state, required this.onRetry});

  final TranscriptsState state;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final style = context.textTheme.bodySmall?.copyWith(color: context.colors.mutedForeground);
    return Padding(
      padding: context.spacing.page,
      child: Center(
        child: state.loadMoreError != null
            ? TextButton(onPressed: onRetry, child: Text(l10n.meetingsTranscriptLoadMoreFailed))
            : Text(
                state.loadingMore
                    ? l10n.meetingsTranscriptLoadingMore
                    : l10n.meetingsTranscriptShowing(state.items.length, state.totalCount),
                style: style,
              ),
      ),
    );
  }
}

class _TranscriptRow extends ConsumerWidget {
  const _TranscriptRow({required this.meetingId, required this.transcript});

  final String meetingId;
  final MeetingTranscript transcript;

  bool _isCurrent(Duration position, bool ready) {
    final start = transcript.audioStartTime;
    if (!ready || start == null) return false;
    final end = transcript.audioEndTime ?? (start + (transcript.duration ?? 0));
    final seconds = position.inMilliseconds / Duration.millisecondsPerSecond;
    return seconds >= start && seconds < end;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = meetingPlayerControllerProvider(meetingId);
    final active = ref.watch(provider.select((p) => _isCurrent(p.position, p.isReady)));
    final canSeek =
        ref.watch(provider.select((p) => p.isReady)) && transcript.audioStartTime != null;
    final colors = context.colors;
    final spacing = context.spacing;
    final label = formatTranscriptTime(transcript.audioStartTime, transcript.timestamp);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: spacing.xs),
      decoration: BoxDecoration(
        color: active ? colors.accent : null,
        borderRadius: context.radius.smAll,
      ),
      padding: EdgeInsets.symmetric(horizontal: spacing.sm, vertical: spacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: context.radius.smAll,
            onTap: canSeek
                ? () => ref.read(provider.notifier).playFrom(transcript.audioStartTime!)
                : null,
            child: Tooltip(
              message: canSeek ? context.l10n.meetingsPlayFrom(label) : '',
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: spacing.xxs),
                child: Text(
                  label,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: canSeek ? colors.primary : colors.mutedForeground,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: spacing.xs),
          Expanded(
            child: SelectableText(
              transcript.text,
              style: context.textTheme.bodyMedium?.copyWith(
                color: active ? colors.onAccent : colors.foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
