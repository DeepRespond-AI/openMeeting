import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/context_extensions.dart';
import '../../../../core/widgets/live_feedback.dart';
import '../../data/recording_download.dart';
import '../meeting_player_controller.dart';

class RecordingDownload extends ConsumerWidget {
  const RecordingDownload({required this.meetingId, super.key});
  final String meetingId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final download = ref.watch(recordingDownloadControllerProvider(meetingId));
    final actions = ref.read(recordingDownloadControllerProvider(meetingId).notifier);
    final l = context.l10n;
    return Card(
      child: Padding(
        padding: context.spacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (download.isLoading) const LinearProgressIndicator(),
            if (download.hasError) LiveError(download.error!, onRetry: actions.download),
            if (download.value != null) Text(l.liveAudioSaved),
            TextButton.icon(
              key: const ValueKey('download-recording'),
              onPressed: download.isLoading
                  ? null
                  : () async {
                      if (!await actions.download() || !context.mounted) return;
                      final file = ref.read(recordingDownloadControllerProvider(meetingId)).value;
                      if (file != null) {
                        await ref
                            .read(meetingPlayerControllerProvider(meetingId).notifier)
                            .load(localFile: file.uri);
                      }
                    },
              icon: const Icon(Icons.download),
              label: Text(download.isLoading ? l.liveDownloadingAudio : l.liveDownloadAudio),
            ),
            if (download.value != null)
              TextButton.icon(
                key: const ValueKey('export-recording'),
                onPressed: download.isLoading ? null : actions.export,
                icon: const Icon(Icons.ios_share),
                label: Text(l.liveExportAudio),
              ),
          ],
        ),
      ),
    );
  }
}
