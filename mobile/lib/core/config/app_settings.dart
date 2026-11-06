import 'package:freezed_annotation/freezed_annotation.dart';

import 'app_enums.dart';

part 'app_settings.freezed.dart';

/// Raw persisted user settings. `null` = "not set by the user" → the [AppConfig]
/// default applies (precedence: user settings > server-provided > app config).
///
/// Feature code normally reads [EffectiveSettings] (`effectiveSettingsProvider`) instead.
@freezed
abstract class AppSettings with _$AppSettings {
  const factory AppSettings({
    LocaleMode? localeMode,
    RecordingSource? defaultRecordingSource,

    /// Transcription language code, `auto` = server detects.
    String? transcriptionLanguage,

    /// Generate a summary automatically after a recording/import finishes.
    bool? autoSummary,

    /// Keep the local m4a after it was uploaded successfully.
    bool? keepLocalAudio,

    /// Set once the onboarding flow finished.
    @Default(false) bool onboardingCompleted,
  }) = _AppSettings;
}

/// Settings with every default resolved (settings > config). [serverUrl] always comes from
/// the build config (empty string = misconfigured build).
@freezed
abstract class EffectiveSettings with _$EffectiveSettings {
  const factory EffectiveSettings({
    /// `AppConfig.defaultServerUrl`, normalized. Never user-editable or shown in the UI.
    required String serverUrl,
    required LocaleMode localeMode,
    required RecordingSource defaultRecordingSource,
    required String transcriptionLanguage,
    required bool autoSummary,
    required bool keepLocalAudio,
    required bool onboardingCompleted,
  }) = _EffectiveSettings;

  const EffectiveSettings._();

  bool get isServerConfigured => serverUrl.isNotEmpty;
}
