import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config_provider.dart';
import '../../../../core/config/app_enums.dart';
import '../../../../core/config/settings_controller.dart';
import '../../../../core/theme/context_extensions.dart';
import '../../../../core/widgets/app_switch_list_tile.dart';
import 'settings_section.dart';

/// 偏好: language, default recording source, transcription language, auto summary,
/// keep local audio. (Summary templates are picked by the server.)
class PreferencesSection extends ConsumerWidget {
  const PreferencesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(effectiveSettingsProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    final config = ref.watch(appConfigProvider);

    return SettingsSection(
      title: l10n.settingsPreferencesSection,
      children: [
        Padding(
          padding: context.spacing.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.languageLabel, style: context.textTheme.titleSmall),
              context.spacing.gapXs,
              SegmentedButton<LocaleMode>(
                segments: [
                  ButtonSegment(value: LocaleMode.system, label: Text(l10n.languageSystem)),
                  ButtonSegment(value: LocaleMode.zh, label: Text(l10n.languageZh)),
                  ButtonSegment(value: LocaleMode.en, label: Text(l10n.languageEn)),
                ],
                selected: {settings.localeMode},
                showSelectedIcon: false,
                onSelectionChanged: (s) => controller.setLocaleMode(s.first),
              ),
            ],
          ),
        ),
        _RecordingSourcePicker(
          selected: settings.defaultRecordingSource,
          systemAudioAvailable: config.features.systemAudioCapture,
          onChanged: controller.setDefaultRecordingSource,
        ),
        ListTile(
          leading: const Icon(Icons.translate),
          title: Text(l10n.settingsTranscriptionLanguage),
          subtitle: Text(l10n.transcriptionLanguageName(settings.transcriptionLanguage)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            final picked = await showOptionSheet<String>(
              context,
              title: l10n.settingsTranscriptionLanguage,
              options: config.transcription.languages,
              selected: settings.transcriptionLanguage,
              labelOf: l10n.transcriptionLanguageName,
            );
            if (picked != null) await controller.setTranscriptionLanguage(picked);
          },
        ),
        AppSwitchListTile(
          secondary: const Icon(Icons.auto_awesome_outlined),
          title: Text(l10n.settingsAutoSummary),
          subtitle: Text(l10n.settingsAutoSummaryHint),
          value: settings.autoSummary,
          onChanged: controller.setAutoSummary,
        ),
        AppSwitchListTile(
          secondary: const Icon(Icons.sd_storage_outlined),
          title: Text(l10n.settingsKeepLocalAudio),
          subtitle: Text(l10n.settingsKeepLocalAudioHint),
          value: settings.keepLocalAudio,
          onChanged: controller.setKeepLocalAudio,
        ),
      ],
    );
  }
}

class _RecordingSourcePicker extends StatelessWidget {
  const _RecordingSourcePicker({
    required this.selected,
    required this.systemAudioAvailable,
    required this.onChanged,
  });

  final RecordingSource selected;
  final bool systemAudioAvailable;
  final ValueChanged<RecordingSource> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isIos = Theme.of(context).platform == TargetPlatform.iOS;
    return Padding(
      padding: EdgeInsets.only(top: context.spacing.sm, bottom: context.spacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: context.spacing.pageHorizontal,
            child: Text(l10n.settingsDefaultSource, style: context.textTheme.titleSmall),
          ),
          RadioGroup<RecordingSource>(
            groupValue: selected,
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
            child: Column(
              children: [
                RadioListTile<RecordingSource>(
                  value: RecordingSource.microphone,
                  title: Text(l10n.settingsSourceMicrophone),
                  subtitle: Text(l10n.settingsSourceMicrophoneHint),
                ),
                if (systemAudioAvailable)
                  RadioListTile<RecordingSource>(
                    value: RecordingSource.system,
                    title: Text(l10n.settingsSourceSystem),
                    subtitle: Text(
                      isIos
                          ? l10n.settingsSourceSystemHintIos
                          : l10n.settingsSourceSystemHintAndroid,
                    ),
                    isThreeLine: true,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
