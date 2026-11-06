import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/context_extensions.dart';
import '../domain/live_models.dart';
import 'live_feedback.dart';
import 'room_controller.dart';

class RoomRecordingBanner extends ConsumerWidget {
  const RoomRecordingBanner(this.current, {super.key});
  final RoomActive current;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final active = current.room.recording?.active == true;
    final error = current.captureError;
    return Padding(
      padding: context.spacing.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                active ? Icons.fiber_manual_record : Icons.radio_button_unchecked,
                size: context.sizes.iconSm,
                color: active ? context.colors.destructive : context.colors.mutedForeground,
              ),
              context.spacing.gapXs,
              Expanded(
                child: Text(
                  !active
                      ? l.liveRecordingOff
                      : !current.self.isHost
                      ? l.liveRecordingShared
                      : switch (current.capture) {
                          'recording' => l.liveRecordingActive,
                          'uploading' => l.liveRecordingUploading,
                          'error' => l.liveRecordingFailed,
                          _ => l.liveRecordingWaiting,
                        },
                ),
              ),
            ],
          ),
          if (current.self.isHost && error != null)
            LiveError(
              switch (error) {
                'audio_frames_unavailable' => l.liveRecordingNoFrames,
                'recording_backlog' => l.liveRecordingBacklog,
                'automatic_recording_unavailable' => l.liveRecordingVersionMismatch,
                _ => l.liveRecordingError(error),
              },
              onRetry: current.busy
                  ? null
                  : () => ref.read(roomControllerProvider.notifier).retryRecording(),
            ),
        ],
      ),
    );
  }
}

class RecordingPanel extends ConsumerWidget {
  const RecordingPanel({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(roomControllerProvider), l = context.l10n;
    if (current is! RoomActive) return const SizedBox.shrink();
    return Column(
      children: [
        ListTile(
          title: Text(l.liveRecordingTitle),
          trailing: IconButton(
            tooltip: l.liveClose,
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ),
        Expanded(
          child: ListView(
            padding: context.spacing.page,
            children: [
              Text(l.liveRoomRecordingHint),
              RoomRecordingBanner(current),
              if (current.error != null) LiveError(current.error!),
            ],
          ),
        ),
      ],
    );
  }
}
