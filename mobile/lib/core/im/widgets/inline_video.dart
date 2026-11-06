import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../theme/context_extensions.dart';
import '../../widgets/live_feedback.dart';
import '../messaging_controller.dart';

class ImInlineVideo extends ConsumerStatefulWidget {
  const ImInlineVideo({required this.url, super.key});
  final String url;
  @override
  ConsumerState<ImInlineVideo> createState() => _ImInlineVideoState();
}

class _ImInlineVideoState extends ConsumerState<ImInlineVideo> {
  bool opened = false;
  @override
  Widget build(BuildContext context) {
    if (!opened) {
      return TextButton.icon(
        onPressed: () => setState(() => opened = true),
        icon: const Icon(Icons.play_circle_outline),
        label: Text(context.l10n.imPlay),
      );
    }
    return ref
        .watch(imVideoPlayerProvider(widget.url))
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) =>
              LiveError(error, onRetry: () => ref.invalidate(imVideoPlayerProvider(widget.url))),
          data: (session) => ValueListenableBuilder<VideoPlayerValue>(
            valueListenable: session.controller,
            builder: (context, value, _) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (value.hasError)
                  LiveError(value.errorDescription ?? context.l10n.liveMediaUnavailable),
                AspectRatio(
                  aspectRatio: value.aspectRatio > 0 ? value.aspectRatio : 1,
                  child: VideoPlayer(session.controller),
                ),
                IconButton(
                  tooltip: value.isPlaying ? context.l10n.imPause : context.l10n.imPlay,
                  onPressed: () =>
                      ref.read(messagingActionsProvider.notifier).toggleVideo(widget.url),
                  icon: Icon(value.isPlaying ? Icons.pause : Icons.play_arrow),
                ),
              ],
            ),
          ),
        );
  }
}
