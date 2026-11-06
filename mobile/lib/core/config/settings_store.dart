import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_enums.dart';
import 'app_settings.dart';

part 'settings_store.g.dart';

/// The process-wide [SharedPreferences] instance.
///
/// Loaded in `main()` (`SharedPreferences.getInstance()`) and injected with
/// `sharedPreferencesProvider.overrideWithValue(prefs)` so settings are synchronous.
/// Tests: `SharedPreferences.setMockInitialValues({...})` then override the same way.
@Riverpod(keepAlive: true)
SharedPreferences sharedPreferences(Ref ref) => throw UnimplementedError(
  'sharedPreferencesProvider must be overridden with the instance loaded in main()',
);

/// Persists [AppSettings] in shared_preferences. Only [SettingsController] uses it.
class SettingsStore {
  SettingsStore(this._prefs);

  final SharedPreferences _prefs;

  // Storage keys (internal, not tunables).
  /// User-entered server URL of older builds; removed on the next save.
  static const _kLegacyServerUrl = 'settings.serverUrl';
  static const _kLocaleMode = 'settings.localeMode';
  static const _kRecordingSource = 'settings.defaultRecordingSource';
  static const _kTranscriptionLanguage = 'settings.transcriptionLanguage';
  static const _kAutoSummary = 'settings.autoSummary';
  static const _kKeepLocalAudio = 'settings.keepLocalAudio';
  static const _kOnboardingCompleted = 'settings.onboardingCompleted';

  AppSettings load() {
    final locale = _prefs.getString(_kLocaleMode);
    final source = _prefs.getString(_kRecordingSource);
    return AppSettings(
      localeMode: locale == null ? null : enumByName(LocaleMode.values, locale, LocaleMode.system),
      defaultRecordingSource: source == null
          ? null
          : enumByName(RecordingSource.values, source, RecordingSource.microphone),
      transcriptionLanguage: _prefs.getString(_kTranscriptionLanguage),
      autoSummary: _prefs.getBool(_kAutoSummary),
      keepLocalAudio: _prefs.getBool(_kKeepLocalAudio),
      onboardingCompleted: _prefs.getBool(_kOnboardingCompleted) ?? false,
    );
  }

  Future<void> save(AppSettings s) async {
    await Future.wait<void>([
      _prefs.remove(_kLegacyServerUrl),
      _setString(_kLocaleMode, s.localeMode?.name),
      _setString(_kRecordingSource, s.defaultRecordingSource?.name),
      _setString(_kTranscriptionLanguage, s.transcriptionLanguage),
      _setBool(_kAutoSummary, s.autoSummary),
      _setBool(_kKeepLocalAudio, s.keepLocalAudio),
      _setBool(_kOnboardingCompleted, s.onboardingCompleted),
    ]);
  }

  Future<void> _setString(String key, String? value) async {
    if (value == null) {
      await _prefs.remove(key);
    } else {
      await _prefs.setString(key, value);
    }
  }

  Future<void> _setBool(String key, bool? value) async {
    if (value == null) {
      await _prefs.remove(key);
    } else {
      await _prefs.setBool(key, value);
    }
  }
}

@Riverpod(keepAlive: true)
SettingsStore settingsStore(Ref ref) => SettingsStore(ref.watch(sharedPreferencesProvider));
