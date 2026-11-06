import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/meeting_recording.dart';
import '../../../../core/theme/context_extensions.dart';
import '../../../../core/widgets/live_feedback.dart';

class RoomRecordingStatus extends ConsumerWidget {
  const RoomRecordingStatus({required this.meetingId, this.canManage = true, super.key});
  final String meetingId;
  final bool canManage;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(meetingRecordingProvider(meetingId)), l = context.l10n;
    final retry = ref.watch(recordingRetryProvider(meetingId));
    return data.when(
      loading: () => const SizedBox.shrink(),
      error: (error, _) =>
          LiveError(error, onRetry: () => ref.invalidate(meetingRecordingProvider(meetingId))),
      data: (value) {
        final status = value['status'];
        if (status == null || status == 'none') return const SizedBox.shrink();
        return Card(
          child: Padding(
            padding: context.spacing.card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  status == 'completed'
                      ? l.liveRecordingProcessed
                      : status == 'failed' || status == 'cancelled'
                      ? l.liveRecordingFailed
                      : l.liveRecordingProcessing,
                ),
                if (status == 'queued' || status == 'running') const LinearProgressIndicator(),
                if (value['error'] case final String error) LiveError(error),
                if (retry.hasError) LiveError(retry.error!),
                if ((status == 'failed' || status == 'cancelled') && canManage)
                  TextButton.icon(
                    onPressed: retry.isLoading
                        ? null
                        : () => ref.read(recordingRetryProvider(meetingId).notifier).retry(),
                    icon: const Icon(Icons.refresh),
                    label: Text(l.liveRetry),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
