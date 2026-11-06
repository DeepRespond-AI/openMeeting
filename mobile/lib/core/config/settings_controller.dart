import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../utils/server_url.dart';
import 'app_config_provider.dart';
import 'app_enums.dart';
import 'app_settings.dart';
import 'settings_store.dart';

part 'settings_controller.g.dart';

/// Persisted user settings (DEVELOPMENT.md §3, layer 3). The only place settings change.
///
/// State is the raw [AppSettings] (nulls = use config default). Read resolved values
/// through [effectiveSettingsProvider] / [effectiveServerUrlProvider].
@Riverpod(keepAlive: true)
class SettingsController extends _$SettingsController {
  @override
  AppSettings build() => ref.watch(settingsStoreProvider).load();

  Future<void> _update(AppSettings next) async {
    state = next;
    await ref.read(settingsStoreProvider).save(next);
  }

  Future<void> setLocaleMode(LocaleMode mode) => _update(state.copyWith(localeMode: mode));

  Future<void> setDefaultRecordingSource(RecordingSource source) =>
      _update(state.copyWith(defaultRecordingSource: source));

  Future<void> setTranscriptionLanguage(String language) =>
      _update(state.copyWith(transcriptionLanguage: language));

  Future<void> setAutoSummary(bool value) => _update(state.copyWith(autoSummary: value));

  Future<void> setKeepLocalAudio(bool value) => _update(state.copyWith(keepLocalAudio: value));

  Future<void> completeOnboarding() => _update(state.copyWith(onboardingCompleted: true));

  /// Clears every user override (back to config defaults), keeping onboarding state.
  Future<void> resetToDefaults() =>
      _update(AppSettings(onboardingCompleted: state.onboardingCompleted));
}

/// Settings with config defaults applied (user settings > app config).
@Riverpod(keepAlive: true)
EffectiveSettings effectiveSettings(Ref ref) {
  final s = ref.watch(settingsControllerProvider);
  final config = ref.watch(appConfigProvider);
  return EffectiveSettings(
    serverUrl: normalizeServerUrl(config.defaultServerUrl) ?? '',
    localeMode: s.localeMode ?? config.ui.defaultLocaleMode,
    defaultRecordingSource: s.defaultRecordingSource ?? config.recording.defaultSource,
    transcriptionLanguage: s.transcriptionLanguage ?? config.transcription.defaultLanguage,
    autoSummary: s.autoSummary ?? config.features.autoSummaryDefault,
    keepLocalAudio: s.keepLocalAudio ?? config.recording.keepLocalAudioDefault,
    onboardingCompleted: s.onboardingCompleted,
  );
}

/// Effective server base URL ('' = not configured). Narrow provider so that
/// `apiClientProvider` only rebuilds when the URL itself changes.
@Riverpod(keepAlive: true)
String effectiveServerUrl(Ref ref) =>
    ref.watch(effectiveSettingsProvider.select((s) => s.serverUrl));

/// UI locale preference (narrow provider for MaterialApp).
@Riverpod(keepAlive: true)
LocaleMode localeMode(Ref ref) => ref.watch(effectiveSettingsProvider.select((s) => s.localeMode));
