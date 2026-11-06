import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config_provider.dart';
import '../../../../core/config/app_enums.dart';
import '../../../../core/theme/context_extensions.dart';
import '../../data/audio_sources.dart';
import '../../domain/audio_source.dart';
import '../recording_options_controller.dart';
import 'source_limitations_sheet.dart';

/// Source (麦克风 / 内录) and transcription language pickers; locked while [enabled] is false.
class RecordingOptionChips extends ConsumerWidget {
  const RecordingOptionChips({super.key, required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final spacing = context.spacing;
    final options = ref.watch(recordingOptionsControllerProvider);
    final controller = ref.read(recordingOptionsControllerProvider.notifier);
    final config = ref.watch(appConfigProvider);
    final systemAvailability = ref.watch(audioSourceAvailabilityProvider(RecordingSource.system));
    final systemSupported = switch (systemAvailability) {
      AsyncData(:final value) => value != AudioSourceAvailability.unsupported,
      _ => false,
    };
    final showSystem = config.features.systemAudioCapture;

    // The system source was the default but is not available here → fall back.
    if (systemAvailability.hasValue &&
        !systemSupported &&
        options.source == RecordingSource.system) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => controller.setSource(RecordingSource.microphone),
      );
    }

    final labelStyle = context.textTheme.labelMedium?.copyWith(
      color: context.colors.mutedForeground,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.recordingSourceLabel, style: labelStyle),
        spacing.gapXs,
        Wrap(
          spacing: spacing.xs,
          runSpacing: spacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ChoiceChip(
              avatar: const Icon(Icons.mic_none),
              label: Text(l10n.recordingSourceMicrophone),
              selected: options.source == RecordingSource.microphone,
              onSelected: enabled ? (_) => controller.setSource(RecordingSource.microphone) : null,
            ),
            if (showSystem)
              ChoiceChip(
                avatar: const Icon(Icons.surround_sound_outlined),
                label: Text(l10n.recordingSourceSystem),
                selected: options.source == RecordingSource.system,
                onSelected: enabled && systemSupported
                    ? (_) => controller.setSource(RecordingSource.system)
                    : null,
              ),
            if (showSystem)
              TextButton.icon(
                onPressed: () => showSourceLimitationsSheet(context),
                icon: Icon(Icons.info_outline, size: context.sizes.iconSm),
                label: Text(l10n.recordingSourceLimitationsLink),
              ),
          ],
        ),
        if (showSystem && systemAvailability.hasValue)
          Padding(
            padding: EdgeInsets.only(top: spacing.xxs),
            child: switch (systemAvailability.value) {
              AudioSourceAvailability.unsupported => Text(
                l10n.recordingSourceUnsupported,
                style: labelStyle,
              ),
              AudioSourceAvailability.needsPermission
                  when options.source == RecordingSource.system =>
                Text(l10n.recordingSourceNeedsPermission, style: labelStyle),
              _ => const SizedBox.shrink(),
            },
          ),
        spacing.gapSm,
        Text(l10n.recordingLanguageLabel, style: labelStyle),
        spacing.gapXs,
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final code in config.transcription.languages)
                Padding(
                  padding: EdgeInsetsDirectional.only(end: spacing.xs),
                  child: ChoiceChip(
                    label: Text(l10n.transcriptionLanguageName(code)),
                    selected: options.language == code,
                    onSelected: enabled ? (_) => controller.setLanguage(code) : null,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
