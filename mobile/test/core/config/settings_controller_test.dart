import 'package:flutter_test/flutter_test.dart';
import 'package:meeting/core/config/app_enums.dart';
import 'package:meeting/core/config/settings_controller.dart';
import 'package:meeting/core/config/settings_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_config.dart';

void main() {
  test('effective settings fall back to AppConfig defaults', () async {
    final c = await createTestContainer(config: loadConfigFile('dev'));
    final s = c.read(effectiveSettingsProvider);
    final config = loadConfigFile('dev');
    expect(s.serverUrl, config.defaultServerUrl);
    expect(s.localeMode, LocaleMode.system);
    expect(s.defaultRecordingSource, RecordingSource.microphone);
    expect(s.transcriptionLanguage, 'auto');
    expect(s.autoSummary, config.features.autoSummaryDefault);
    expect(s.keepLocalAudio, config.recording.keepLocalAudioDefault);
    expect(s.onboardingCompleted, isFalse);
  });

  test('the config default server URL is used until the user sets one', () async {
    final prod = loadConfigFile('prod');
    final c = await createTestContainer(config: prod);
    expect(c.read(effectiveServerUrlProvider), prod.defaultServerUrl);
    expect(c.read(effectiveSettingsProvider).isServerConfigured, prod.defaultServerUrl.isNotEmpty);
  });

  test('no server is configured when the config has no default URL', () async {
    final c = await createTestContainer(config: loadConfigWithoutServer());
    expect(c.read(effectiveServerUrlProvider), isEmpty);
    expect(c.read(effectiveSettingsProvider).isServerConfigured, isFalse);
  });

  test('user settings override config and are persisted', () async {
    final c = await createTestContainer();
    final n = c.read(settingsControllerProvider.notifier);
    await n.setLocaleMode(LocaleMode.en);
    await n.setDefaultRecordingSource(RecordingSource.system);
    await n.setTranscriptionLanguage('zh');
    await n.setAutoSummary(false);
    await n.setKeepLocalAudio(false);
    await n.completeOnboarding();

    final s = c.read(effectiveSettingsProvider);
    // The server URL is fixed by the build config, never by the user.
    expect(s.serverUrl, loadConfigFile('dev').defaultServerUrl);
    expect(s.localeMode, LocaleMode.en);
    expect(c.read(localeModeProvider), LocaleMode.en);
    expect(s.defaultRecordingSource, RecordingSource.system);
    expect(s.transcriptionLanguage, 'zh');
    expect(s.autoSummary, isFalse);
    expect(s.keepLocalAudio, isFalse);
    expect(s.onboardingCompleted, isTrue);

    // A new store over the same SharedPreferences (= app restart) sees the same values.
    final reloaded = SettingsStore(await SharedPreferences.getInstance()).load();
    expect(reloaded, c.read(settingsControllerProvider));
  });

  test('loads persisted values at startup and ignores unknown enum values', () async {
    final c = await createTestContainer(
      prefs: const {
        'settings.serverUrl': 'http://saved.test',
        'settings.localeMode': 'zh',
        'settings.defaultRecordingSource': 'bogus',
        'settings.onboardingCompleted': true,
      },
    );
    final s = c.read(effectiveSettingsProvider);
    expect(s.serverUrl, loadConfigFile('dev').defaultServerUrl, reason: 'legacy URL ignored');
    expect(s.localeMode, LocaleMode.zh);
    expect(s.defaultRecordingSource, RecordingSource.microphone);
    expect(s.onboardingCompleted, isTrue);
  });

  test('resetToDefaults keeps onboarding; saving drops a legacy server URL', () async {
    final c = await createTestContainer(prefs: const {'settings.serverUrl': 'http://a.test'});
    final n = c.read(settingsControllerProvider.notifier);
    expect(c.read(effectiveServerUrlProvider), loadConfigFile('dev').defaultServerUrl);

    await n.completeOnboarding();
    await n.setLocaleMode(LocaleMode.en);
    await n.resetToDefaults();
    expect(c.read(effectiveSettingsProvider).localeMode, LocaleMode.system);
    expect(c.read(effectiveSettingsProvider).onboardingCompleted, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('settings.localeMode'), isNull);
    expect(prefs.getString('settings.serverUrl'), isNull);
  });
}
