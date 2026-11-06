/// Microphone permission status as the onboarding needs it.
enum MicPermission {
  granted,

  /// Not granted yet; asking again may show the system prompt.
  denied,

  /// The system will not prompt again; only the system settings can grant it.
  permanentlyDenied,

  /// Blocked by parental controls / device policy.
  restricted,
}

/// Platform microphone permission (behind an interface so tests can fake it).
abstract interface class MicrophonePermissionRepository {
  Future<MicPermission> status();

  /// Shows the system prompt when possible and returns the resulting status.
  Future<MicPermission> request();

  /// Opens the app's page in the system settings. Returns false if it could not be opened.
  Future<bool> openSystemSettings();
}
