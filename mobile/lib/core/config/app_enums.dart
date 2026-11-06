/// Enums shared by [AppConfig] (JSON) and the persisted user settings.
///
/// The enum *names* are the wire/storage values (`microphone`, `system`, `zh` ...),
/// so do not rename members without migrating `assets/config/*.json` and stored prefs.
library;

/// Where recorded audio comes from. `system` = system playback mixed with the mic.
enum RecordingSource { microphone, system }

/// UI language preference. `system` follows the device locale (zh if the device is Chinese, else en).
enum LocaleMode { system, zh, en }

/// Looks up an enum value by [name], returning [fallback] for unknown/missing values.
T enumByName<T extends Enum>(List<T> values, String? name, T fallback) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}
