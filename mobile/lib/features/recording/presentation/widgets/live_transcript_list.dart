import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config_provider.dart';
import '../../../../core/theme/context_extensions.dart';
import '../../domain/recording_state.dart';
import '../../domain/time_format.dart';

/// Live transcript lines with their start time; follows new lines automatically unless the
/// user scrolled up.
class LiveTranscriptList extends ConsumerStatefulWidget {
  const LiveTranscriptList({super.key, required this.transcripts});

  final List<LiveTranscript> transcripts;

  @override
  ConsumerState<LiveTranscriptList> createState() => _LiveTranscriptListState();
}

class _LiveTranscriptListState extends ConsumerState<LiveTranscriptList> {
  final _scroll = ScrollController();

  bool get _atBottom =>
      !_scroll.hasClients || _scroll.position.pixels >= _scroll.position.maxScrollExtent - 1;

  @override
  void didUpdateWidget(LiveTranscriptList old) {
    super.didUpdateWidget(old);
    if (widget.transcripts.length != old.transcripts.length && _atBottom) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scroll.hasClients) return;
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: ref.read(appConfigProvider).recording.transcriptScrollAnimation,
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    if (widget.transcripts.isEmpty) {
      return Center(
        child: Padding(
          padding: spacing.page,
          child: Text(
            context.l10n.recordingTranscriptEmpty,
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium?.copyWith(color: colors.mutedForeground),
          ),
        ),
      );
    }
    return ListView.separated(
      controller: _scroll,
      padding: spacing.card,
      itemCount: widget.transcripts.length,
      separatorBuilder: (_, _) => spacing.gapSm,
      itemBuilder: (context, i) {
        final line = widget.transcripts[i];
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              formatSeconds(line.startSec),
              style: context.textTheme.labelSmall?.copyWith(
                color: colors.primary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            spacing.gapSm,
            Expanded(child: SelectableText(line.text, style: context.textTheme.bodyMedium)),
          ],
        );
      },
    );
  }
}
