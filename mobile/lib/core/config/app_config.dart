import 'package:freezed_annotation/freezed_annotation.dart';

import 'app_enums.dart';

part 'app_config.freezed.dart';
part 'app_config.g.dart';

/// Build-time / environment configuration, parsed from `assets/config/app_config.<env>.json`.
///
/// Every tunable behaviour value lives here (DEVELOPMENT.md §3). JSON keys equal the Dart field
/// names. All fields are required: a key missing from one of the JSON files fails parsing
/// (covered by `test/core/config/app_config_test.dart`), which keeps dev/test/prod in sync.
///
/// To add a field: update `tool/templates/app_config.json` and existing local JSON files, add it here, run
/// `dart run build_runner build -d`, and read it via `ref.watch(appConfigProvider).<section>.<field>`.
@freezed
abstract class AppConfig with _$AppConfig {
  const factory AppConfig({
    /// `dev` | `test` | `prod`.
    required String env,

    /// The server this build talks to. Fixed per build (`app_config.<env>.json`); users can
    /// neither see nor change it. Empty = misconfigured build (sign-in is impossible).
    required String defaultServerUrl,
    required NetworkConfig network,
    required HeartbeatConfig heartbeat,
    required PollingConfig polling,
    required PaginationConfig pagination,
    required AuthConfigDefaults auth,
    required AudioConfig audio,
    required VadConfig vad,
    required TranscriptionConfig transcription,
    required RecordingConfig recording,
    required FeatureFlags features,
    required UiConfig ui,
    required PlayerConfig player,
    required ImportFileConfig importFile,
    required MeetingsUiConfig meetingsUi,
    required SystemAudioConfig systemAudio,
    required UpdateConfig update,
    required LiveConfig live,
  }) = _AppConfig;

  const AppConfig._();

  factory AppConfig.fromJson(Map<String, dynamic> json) => _$AppConfigFromJson(json);

  bool get isDev => env == 'dev';
}

@freezed
abstract class LiveConfig with _$LiveConfig {
  const factory LiveConfig({
    required int rtcReleaseTimeoutMs,
    required int rtcReleasePollMs,
    required int waitingPollMs,
    required int wsPingMs,
    required int maxReconnects,
    required int reconnectMs,
    required int titleMax,
    required int nameMax,
    required int chatMax,
    required int attachmentMaxBytes,
    required int scheduleRangeDays,
    required int defaultDurationMin,
    required int minDurationMin,
    required int maxDurationMin,
    required int imPageSize,
    required int imTextMax,
    required int voiceLimitSec,
    required int reminderLeadMin,
    required int reminderPollMs,
    required int recordingChunkMs,
    required int recordingMaxPending,
    required int recordingFrameTimeoutMs,
    required int scheduleMaxDays,
    required int noticeDedupLimit,
    required int noticeHistoryLimit,
    required int avatarMaxBytes,
    required List<String> avatarExtensions,
    required int rtcSampleMs,
    required int rtcStaleMs,
    required double rtcSpeakingLevel,
    required int rtcSpeakingHoldMs,
    required int rtcFairRttMs,
    required int rtcPoorRttMs,
    required double rtcFairLossPercent,
    required double rtcPoorLossPercent,
    required int screenTrackTimeoutMs,
  }) = _LiveConfig;
  factory LiveConfig.fromJson(Map<String, dynamic> json) => _$LiveConfigFromJson(json);
}

@freezed
abstract class NetworkConfig with _$NetworkConfig {
  const factory NetworkConfig({
    required int connectTimeoutMs,

    /// Receive/send timeout for ordinary JSON requests.
    required int requestTimeoutMs,

    /// Send/receive timeout for large transfers (audio upload/download, import).
    required int transferTimeoutMs,

    /// Retry policy for idempotent requests and live segment uploads.
    required RetryConfig retry,

    /// Retry policy for the final meeting audio upload.
    required RetryConfig audioUploadRetry,
  }) = _NetworkConfig;

  const NetworkConfig._();

  factory NetworkConfig.fromJson(Map<String, dynamic> json) => _$NetworkConfigFromJson(json);

  Duration get connectTimeout => Duration(milliseconds: connectTimeoutMs);
  Duration get requestTimeout => Duration(milliseconds: requestTimeoutMs);
  Duration get transferTimeout => Duration(milliseconds: transferTimeoutMs);
}

/// `maxRetries` = retries AFTER the first attempt (total attempts = 1 + maxRetries), same as
/// the desktop client. The delay before retry `i` (0-based) is `backoffMs[min(i, len - 1)]`.
@freezed
abstract class RetryConfig with _$RetryConfig {
  const factory RetryConfig({required int maxRetries, required List<int> backoffMs}) = _RetryConfig;

  const RetryConfig._();

  factory RetryConfig.fromJson(Map<String, dynamic> json) => _$RetryConfigFromJson(json);

  /// Delay before retry number [retryIndex] (0-based).
  Duration delayFor(int retryIndex) {
    if (backoffMs.isEmpty) return Duration.zero;
    final i = retryIndex < backoffMs.length ? retryIndex : backoffMs.length - 1;
    return Duration(milliseconds: backoffMs[i]);
  }
}

@freezed
abstract class HeartbeatConfig with _$HeartbeatConfig {
  const factory HeartbeatConfig({
    required int intervalSec,

    /// Interval while the app is not in the foreground (unless recording).
    required int backgroundIntervalSec,
  }) = _HeartbeatConfig;

  const HeartbeatConfig._();

  factory HeartbeatConfig.fromJson(Map<String, dynamic> json) => _$HeartbeatConfigFromJson(json);

  Duration get interval => Duration(seconds: intervalSec);
  Duration get backgroundInterval => Duration(seconds: backgroundIntervalSec);
}

@freezed
abstract class PollingConfig with _$PollingConfig {
  const factory PollingConfig({
    required int summaryIntervalSec,
    required int summaryMaxPolls,
    required int jobIntervalSec,
    required int jobMaxConsecutiveErrors,
  }) = _PollingConfig;

  const PollingConfig._();

  factory PollingConfig.fromJson(Map<String, dynamic> json) => _$PollingConfigFromJson(json);

  Duration get summaryInterval => Duration(seconds: summaryIntervalSec);
  Duration get jobInterval => Duration(seconds: jobIntervalSec);
}

@freezed
abstract class PaginationConfig with _$PaginationConfig {
  const factory PaginationConfig({
    required int transcriptPageSize,
    required int meetingSearchDebounceMs,
  }) = _PaginationConfig;

  const PaginationConfig._();

  factory PaginationConfig.fromJson(Map<String, dynamic> json) => _$PaginationConfigFromJson(json);

  Duration get meetingSearchDebounce => Duration(milliseconds: meetingSearchDebounceMs);
}

/// Client-side auth rules. (Server-provided values such as code length and resend
/// interval come from `GET /auth/config` → `AuthConfig`, not from here.)
@freezed
abstract class AuthConfigDefaults with _$AuthConfigDefaults {
  const factory AuthConfigDefaults({
    /// Regex a normalized phone number must match.
    required String phonePattern,
    required int nameMaxLength,

    /// Country-code prefixes stripped during phone normalization (e.g. `+86`, `0086`, `86`).
    required List<String> phonePrefixes,

    /// SMS code length used until `GET /auth/config` answered (server value wins).
    required int defaultCodeLength,

    /// Resend countdown used when neither the send response nor `/auth/config` provide one.
    required int defaultResendIntervalSec,

    /// Password length limits used until `GET /auth/config` answered (server values win).
    required int defaultPasswordMinLength,
    required int defaultPasswordMaxLength,

    /// Digits left visible at the start / end when a phone number is masked (`138****8000`).
    required int phoneMaskPrefixLength,
    required int phoneMaskSuffixLength,
  }) = _AuthConfigDefaults;

  factory AuthConfigDefaults.fromJson(Map<String, dynamic> json) =>
      _$AuthConfigDefaultsFromJson(json);
}

@freezed
abstract class AudioConfig with _$AudioConfig {
  const factory AudioConfig({
    required int sampleRate,
    required int channels,
    required int aacBitrate,
    required int levelUpdateIntervalMs,

    /// dBFS mapped to level 0 (0 dBFS = level 1) for the input level meter.
    required double levelFloorDb,
  }) = _AudioConfig;

  const AudioConfig._();

  factory AudioConfig.fromJson(Map<String, dynamic> json) => _$AudioConfigFromJson(json);

  Duration get levelUpdateInterval => Duration(milliseconds: levelUpdateIntervalMs);
}

/// Streaming energy VAD parameters (port of server `_energy_vad`).
@freezed
abstract class VadConfig with _$VadConfig {
  const factory VadConfig({
    required int frameMs,
    required double thresholdDbAboveNoise,
    required int noiseFloorPercentile,
    required double noiseFloorWindowSec,
    required int silenceToEndMs,
    required int paddingMs,
    required int minSpeechMs,
    required double maxSegmentSec,
    required double splitSearchWindowSec,

    /// Absolute lower bound of the speech threshold (dBFS), like the server's `-50`.
    required double minThresholdDb,
  }) = _VadConfig;

  factory VadConfig.fromJson(Map<String, dynamic> json) => _$VadConfigFromJson(json);
}

@freezed
abstract class TranscriptionConfig with _$TranscriptionConfig {
  const factory TranscriptionConfig({
    /// `auto` = let the server detect (the `language` query parameter is omitted).
    required String defaultLanguage,

    /// Language codes offered in pickers; the first entry should be `auto`.
    required List<String> languages,

    /// The code meaning "auto-detect" (the `language` query parameter is then omitted).
    required String autoLanguageCode,
  }) = _TranscriptionConfig;

  factory TranscriptionConfig.fromJson(Map<String, dynamic> json) =>
      _$TranscriptionConfigFromJson(json);
}

@freezed
abstract class RecordingConfig with _$RecordingConfig {
  const factory RecordingConfig({
    required RecordingSource defaultSource,

    /// `intl` DateFormat pattern for the generated meeting title suffix.
    required String titleFormat,
    required double systemAudioMicGain,
    required double systemAudioDuckingRatio,
    required bool keepLocalAudioDefault,

    /// Extension of the local AAC recording file (`<meetingId>.<ext>`).
    required String audioFileExtension,

    /// `filename` query value of `PUT /meetings/{id}/audio`.
    required String audioUploadFileName,

    /// `Content-Type` of the audio upload.
    required String audioContentType,

    /// `Content-Type` of a live PCM16 segment upload.
    required String segmentContentType,

    /// Sub-directory of the app support dir holding local recordings.
    required String recordingsDirName,

    /// Sub-directory of the app support dir holding the pending segment queue.
    required String pendingQueueDirName,

    /// Max wait for the audio source's last frames after stop.
    required int stopDrainTimeoutMs,

    /// Number of level samples shown by the live waveform.
    required int waveformBars,
    required int transcriptScrollAnimationMs,

    /// Android notification channel of the recording foreground service.
    required String notificationChannelId,

    /// Android foreground service notification id.
    required int foregroundServiceId,
  }) = _RecordingConfig;

  const RecordingConfig._();

  factory RecordingConfig.fromJson(Map<String, dynamic> json) => _$RecordingConfigFromJson(json);

  Duration get stopDrainTimeout => Duration(milliseconds: stopDrainTimeoutMs);
  Duration get transcriptScrollAnimation => Duration(milliseconds: transcriptScrollAnimationMs);
}

@freezed
abstract class FeatureFlags with _$FeatureFlags {
  const factory FeatureFlags({
    required bool systemAudioCapture,
    required bool importAudio,
    required bool autoSummaryDefault,

    /// Show the `dev_code` returned by `sms/send` (dev servers only).
    required bool showDevCode,
    required bool standaloneMessages,
  }) = _FeatureFlags;

  factory FeatureFlags.fromJson(Map<String, dynamic> json) => _$FeatureFlagsFromJson(json);
}

@freezed
abstract class UiConfig with _$UiConfig {
  const factory UiConfig({required LocaleMode defaultLocaleMode, required int snackBarDurationMs}) =
      _UiConfig;

  const UiConfig._();

  factory UiConfig.fromJson(Map<String, dynamic> json) => _$UiConfigFromJson(json);

  Duration get snackBarDuration => Duration(milliseconds: snackBarDurationMs);
}

/// App upgrades (server/API.md §1.8).
@freezed
abstract class UpdateConfig with _$UpdateConfig {
  const factory UpdateConfig({
    /// Minimum time between background update checks (start-up, resume, while in use).
    required int checkIntervalMin,

    /// An optional update is offered again after this long when the user chose "Later".
    required int promptCooldownHours,

    /// File name of the downloaded APK in the app cache (Android `direct` channel).
    required String apkFileName,
  }) = _UpdateConfig;

  const UpdateConfig._();

  factory UpdateConfig.fromJson(Map<String, dynamic> json) => _$UpdateConfigFromJson(json);

  Duration get checkInterval => Duration(minutes: checkIntervalMin);
  Duration get promptCooldown => Duration(hours: promptCooldownHours);
}

/// Meeting audio playback (desktop `MeetingAudioPlayer`).
@freezed
abstract class PlayerConfig with _$PlayerConfig {
  const factory PlayerConfig({
    /// Playback rates cycled by the speed button; the first one is the initial rate.
    required List<double> speeds,

    /// Seconds jumped by the back / forward buttons.
    required int skipSeconds,
  }) = _PlayerConfig;

  const PlayerConfig._();

  factory PlayerConfig.fromJson(Map<String, dynamic> json) => _$PlayerConfigFromJson(json);

  Duration get skip => Duration(seconds: skipSeconds);
}

/// Audio import (`POST /jobs/import`).
@freezed
abstract class ImportFileConfig with _$ImportFileConfig {
  const factory ImportFileConfig({
    /// File extensions (no dot) offered by the picker (desktop `AUDIO_EXTENSIONS`).
    required List<String> allowedExtensions,
  }) = _ImportFileConfig;

  factory ImportFileConfig.fromJson(Map<String, dynamic> json) => _$ImportFileConfigFromJson(json);
}

/// Meetings list presentation.
@freezed
abstract class MeetingsUiConfig with _$MeetingsUiConfig {
  const factory MeetingsUiConfig({
    /// Dates younger than this many days are shown relative ("3 days ago"), older ones absolute.
    required int relativeDateMaxDays,
  }) = _MeetingsUiConfig;

  factory MeetingsUiConfig.fromJson(Map<String, dynamic> json) => _$MeetingsUiConfigFromJson(json);
}

/// System-audio ("内录") capture tunables, passed to the `system_audio_capture` plugin.
/// Output format comes from [AudioConfig]; mic gain / ducking ratio from [RecordingConfig].
@freezed
abstract class SystemAudioConfig with _$SystemAudioConfig {
  const factory SystemAudioConfig({
    /// Mixer frame duration (ms).
    required int frameMs,

    /// Mixer latency absorbing bursty delivery of the system/mic inputs (ms).
    required int jitterBufferMs,

    /// Per-input backlog cap; older samples are dropped beyond it (ms).
    required int maxBufferMs,

    /// Mic RMS (0..1) above which system audio is ducked.
    required double micActiveRmsThreshold,
    required int duckingAttackMs,
    required int duckingReleaseMs,

    /// Soft-clip knee (0..1) for the mixed signal.
    required double softClipKnee,

    /// dBFS mapped to level 0 for the level meter.
    required double levelFloorDb,

    /// Android AudioPlaybackCapture usages: `media`, `game`, `unknown`.
    required List<String> androidCaptureUsages,

    /// Android mic source: `voiceRecognition` | `mic` | `voiceCommunication` | `camcorder`.
    required String androidMicSource,

    /// Capture rate used when the device refuses `audio.sampleRate` directly.
    required int androidFallbackCaptureSampleRate,
    required String androidNotificationChannelId,
    required int androidNotificationId,

    /// iOS broadcast extension chunk length (ms).
    required int iosChunkMs,

    /// iOS: wait this long for the user to start the broadcast before giving up.
    required int iosStartTimeoutMs,

    /// iOS: wait this long for the extension to confirm it stopped.
    required int iosStopTimeoutMs,
    required int iosPollIntervalMs,

    /// iOS: unread chunks the extension keeps before dropping the oldest.
    required int iosMaxPendingChunks,

    /// iOS: keep the app running in the background with a silent audio session while capturing.
    required bool iosKeepAliveInBackground,
  }) = _SystemAudioConfig;

  factory SystemAudioConfig.fromJson(Map<String, dynamic> json) =>
      _$SystemAudioConfigFromJson(json);
}
