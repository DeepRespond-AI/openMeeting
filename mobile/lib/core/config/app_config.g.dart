// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppConfig _$AppConfigFromJson(Map<String, dynamic> json) => _AppConfig(
  env: json['env'] as String,
  defaultServerUrl: json['defaultServerUrl'] as String,
  network: NetworkConfig.fromJson(json['network'] as Map<String, dynamic>),
  heartbeat: HeartbeatConfig.fromJson(
    json['heartbeat'] as Map<String, dynamic>,
  ),
  polling: PollingConfig.fromJson(json['polling'] as Map<String, dynamic>),
  pagination: PaginationConfig.fromJson(
    json['pagination'] as Map<String, dynamic>,
  ),
  auth: AuthConfigDefaults.fromJson(json['auth'] as Map<String, dynamic>),
  audio: AudioConfig.fromJson(json['audio'] as Map<String, dynamic>),
  vad: VadConfig.fromJson(json['vad'] as Map<String, dynamic>),
  transcription: TranscriptionConfig.fromJson(
    json['transcription'] as Map<String, dynamic>,
  ),
  recording: RecordingConfig.fromJson(
    json['recording'] as Map<String, dynamic>,
  ),
  features: FeatureFlags.fromJson(json['features'] as Map<String, dynamic>),
  ui: UiConfig.fromJson(json['ui'] as Map<String, dynamic>),
  player: PlayerConfig.fromJson(json['player'] as Map<String, dynamic>),
  importFile: ImportFileConfig.fromJson(
    json['importFile'] as Map<String, dynamic>,
  ),
  meetingsUi: MeetingsUiConfig.fromJson(
    json['meetingsUi'] as Map<String, dynamic>,
  ),
  systemAudio: SystemAudioConfig.fromJson(
    json['systemAudio'] as Map<String, dynamic>,
  ),
  update: UpdateConfig.fromJson(json['update'] as Map<String, dynamic>),
  live: LiveConfig.fromJson(json['live'] as Map<String, dynamic>),
);

Map<String, dynamic> _$AppConfigToJson(_AppConfig instance) =>
    <String, dynamic>{
      'env': instance.env,
      'defaultServerUrl': instance.defaultServerUrl,
      'network': instance.network.toJson(),
      'heartbeat': instance.heartbeat.toJson(),
      'polling': instance.polling.toJson(),
      'pagination': instance.pagination.toJson(),
      'auth': instance.auth.toJson(),
      'audio': instance.audio.toJson(),
      'vad': instance.vad.toJson(),
      'transcription': instance.transcription.toJson(),
      'recording': instance.recording.toJson(),
      'features': instance.features.toJson(),
      'ui': instance.ui.toJson(),
      'player': instance.player.toJson(),
      'importFile': instance.importFile.toJson(),
      'meetingsUi': instance.meetingsUi.toJson(),
      'systemAudio': instance.systemAudio.toJson(),
      'update': instance.update.toJson(),
      'live': instance.live.toJson(),
    };

_LiveConfig _$LiveConfigFromJson(Map<String, dynamic> json) => _LiveConfig(
  rtcReleaseTimeoutMs: (json['rtcReleaseTimeoutMs'] as num).toInt(),
  rtcReleasePollMs: (json['rtcReleasePollMs'] as num).toInt(),
  waitingPollMs: (json['waitingPollMs'] as num).toInt(),
  wsPingMs: (json['wsPingMs'] as num).toInt(),
  maxReconnects: (json['maxReconnects'] as num).toInt(),
  reconnectMs: (json['reconnectMs'] as num).toInt(),
  titleMax: (json['titleMax'] as num).toInt(),
  nameMax: (json['nameMax'] as num).toInt(),
  chatMax: (json['chatMax'] as num).toInt(),
  attachmentMaxBytes: (json['attachmentMaxBytes'] as num).toInt(),
  scheduleRangeDays: (json['scheduleRangeDays'] as num).toInt(),
  defaultDurationMin: (json['defaultDurationMin'] as num).toInt(),
  minDurationMin: (json['minDurationMin'] as num).toInt(),
  maxDurationMin: (json['maxDurationMin'] as num).toInt(),
  imPageSize: (json['imPageSize'] as num).toInt(),
  imTextMax: (json['imTextMax'] as num).toInt(),
  voiceLimitSec: (json['voiceLimitSec'] as num).toInt(),
  reminderLeadMin: (json['reminderLeadMin'] as num).toInt(),
  reminderPollMs: (json['reminderPollMs'] as num).toInt(),
  recordingChunkMs: (json['recordingChunkMs'] as num).toInt(),
  recordingMaxPending: (json['recordingMaxPending'] as num).toInt(),
  recordingFrameTimeoutMs: (json['recordingFrameTimeoutMs'] as num).toInt(),
  scheduleMaxDays: (json['scheduleMaxDays'] as num).toInt(),
  noticeDedupLimit: (json['noticeDedupLimit'] as num).toInt(),
  noticeHistoryLimit: (json['noticeHistoryLimit'] as num).toInt(),
  avatarMaxBytes: (json['avatarMaxBytes'] as num).toInt(),
  avatarExtensions: (json['avatarExtensions'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  rtcSampleMs: (json['rtcSampleMs'] as num).toInt(),
  rtcStaleMs: (json['rtcStaleMs'] as num).toInt(),
  rtcSpeakingLevel: (json['rtcSpeakingLevel'] as num).toDouble(),
  rtcSpeakingHoldMs: (json['rtcSpeakingHoldMs'] as num).toInt(),
  rtcFairRttMs: (json['rtcFairRttMs'] as num).toInt(),
  rtcPoorRttMs: (json['rtcPoorRttMs'] as num).toInt(),
  rtcFairLossPercent: (json['rtcFairLossPercent'] as num).toDouble(),
  rtcPoorLossPercent: (json['rtcPoorLossPercent'] as num).toDouble(),
  screenTrackTimeoutMs: (json['screenTrackTimeoutMs'] as num).toInt(),
);

Map<String, dynamic> _$LiveConfigToJson(_LiveConfig instance) =>
    <String, dynamic>{
      'rtcReleaseTimeoutMs': instance.rtcReleaseTimeoutMs,
      'rtcReleasePollMs': instance.rtcReleasePollMs,
      'waitingPollMs': instance.waitingPollMs,
      'wsPingMs': instance.wsPingMs,
      'maxReconnects': instance.maxReconnects,
      'reconnectMs': instance.reconnectMs,
      'titleMax': instance.titleMax,
      'nameMax': instance.nameMax,
      'chatMax': instance.chatMax,
      'attachmentMaxBytes': instance.attachmentMaxBytes,
      'scheduleRangeDays': instance.scheduleRangeDays,
      'defaultDurationMin': instance.defaultDurationMin,
      'minDurationMin': instance.minDurationMin,
      'maxDurationMin': instance.maxDurationMin,
      'imPageSize': instance.imPageSize,
      'imTextMax': instance.imTextMax,
      'voiceLimitSec': instance.voiceLimitSec,
      'reminderLeadMin': instance.reminderLeadMin,
      'reminderPollMs': instance.reminderPollMs,
      'recordingChunkMs': instance.recordingChunkMs,
      'recordingMaxPending': instance.recordingMaxPending,
      'recordingFrameTimeoutMs': instance.recordingFrameTimeoutMs,
      'scheduleMaxDays': instance.scheduleMaxDays,
      'noticeDedupLimit': instance.noticeDedupLimit,
      'noticeHistoryLimit': instance.noticeHistoryLimit,
      'avatarMaxBytes': instance.avatarMaxBytes,
      'avatarExtensions': instance.avatarExtensions,
      'rtcSampleMs': instance.rtcSampleMs,
      'rtcStaleMs': instance.rtcStaleMs,
      'rtcSpeakingLevel': instance.rtcSpeakingLevel,
      'rtcSpeakingHoldMs': instance.rtcSpeakingHoldMs,
      'rtcFairRttMs': instance.rtcFairRttMs,
      'rtcPoorRttMs': instance.rtcPoorRttMs,
      'rtcFairLossPercent': instance.rtcFairLossPercent,
      'rtcPoorLossPercent': instance.rtcPoorLossPercent,
      'screenTrackTimeoutMs': instance.screenTrackTimeoutMs,
    };

_NetworkConfig _$NetworkConfigFromJson(Map<String, dynamic> json) =>
    _NetworkConfig(
      connectTimeoutMs: (json['connectTimeoutMs'] as num).toInt(),
      requestTimeoutMs: (json['requestTimeoutMs'] as num).toInt(),
      transferTimeoutMs: (json['transferTimeoutMs'] as num).toInt(),
      retry: RetryConfig.fromJson(json['retry'] as Map<String, dynamic>),
      audioUploadRetry: RetryConfig.fromJson(
        json['audioUploadRetry'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$NetworkConfigToJson(_NetworkConfig instance) =>
    <String, dynamic>{
      'connectTimeoutMs': instance.connectTimeoutMs,
      'requestTimeoutMs': instance.requestTimeoutMs,
      'transferTimeoutMs': instance.transferTimeoutMs,
      'retry': instance.retry.toJson(),
      'audioUploadRetry': instance.audioUploadRetry.toJson(),
    };

_RetryConfig _$RetryConfigFromJson(Map<String, dynamic> json) => _RetryConfig(
  maxRetries: (json['maxRetries'] as num).toInt(),
  backoffMs: (json['backoffMs'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toList(),
);

Map<String, dynamic> _$RetryConfigToJson(_RetryConfig instance) =>
    <String, dynamic>{
      'maxRetries': instance.maxRetries,
      'backoffMs': instance.backoffMs,
    };

_HeartbeatConfig _$HeartbeatConfigFromJson(Map<String, dynamic> json) =>
    _HeartbeatConfig(
      intervalSec: (json['intervalSec'] as num).toInt(),
      backgroundIntervalSec: (json['backgroundIntervalSec'] as num).toInt(),
    );

Map<String, dynamic> _$HeartbeatConfigToJson(_HeartbeatConfig instance) =>
    <String, dynamic>{
      'intervalSec': instance.intervalSec,
      'backgroundIntervalSec': instance.backgroundIntervalSec,
    };

_PollingConfig _$PollingConfigFromJson(Map<String, dynamic> json) =>
    _PollingConfig(
      summaryIntervalSec: (json['summaryIntervalSec'] as num).toInt(),
      summaryMaxPolls: (json['summaryMaxPolls'] as num).toInt(),
      jobIntervalSec: (json['jobIntervalSec'] as num).toInt(),
      jobMaxConsecutiveErrors: (json['jobMaxConsecutiveErrors'] as num).toInt(),
    );

Map<String, dynamic> _$PollingConfigToJson(_PollingConfig instance) =>
    <String, dynamic>{
      'summaryIntervalSec': instance.summaryIntervalSec,
      'summaryMaxPolls': instance.summaryMaxPolls,
      'jobIntervalSec': instance.jobIntervalSec,
      'jobMaxConsecutiveErrors': instance.jobMaxConsecutiveErrors,
    };

_PaginationConfig _$PaginationConfigFromJson(Map<String, dynamic> json) =>
    _PaginationConfig(
      transcriptPageSize: (json['transcriptPageSize'] as num).toInt(),
      meetingSearchDebounceMs: (json['meetingSearchDebounceMs'] as num).toInt(),
    );

Map<String, dynamic> _$PaginationConfigToJson(_PaginationConfig instance) =>
    <String, dynamic>{
      'transcriptPageSize': instance.transcriptPageSize,
      'meetingSearchDebounceMs': instance.meetingSearchDebounceMs,
    };

_AuthConfigDefaults _$AuthConfigDefaultsFromJson(
  Map<String, dynamic> json,
) => _AuthConfigDefaults(
  phonePattern: json['phonePattern'] as String,
  nameMaxLength: (json['nameMaxLength'] as num).toInt(),
  phonePrefixes: (json['phonePrefixes'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  defaultCodeLength: (json['defaultCodeLength'] as num).toInt(),
  defaultResendIntervalSec: (json['defaultResendIntervalSec'] as num).toInt(),
  defaultPasswordMinLength: (json['defaultPasswordMinLength'] as num).toInt(),
  defaultPasswordMaxLength: (json['defaultPasswordMaxLength'] as num).toInt(),
  phoneMaskPrefixLength: (json['phoneMaskPrefixLength'] as num).toInt(),
  phoneMaskSuffixLength: (json['phoneMaskSuffixLength'] as num).toInt(),
);

Map<String, dynamic> _$AuthConfigDefaultsToJson(_AuthConfigDefaults instance) =>
    <String, dynamic>{
      'phonePattern': instance.phonePattern,
      'nameMaxLength': instance.nameMaxLength,
      'phonePrefixes': instance.phonePrefixes,
      'defaultCodeLength': instance.defaultCodeLength,
      'defaultResendIntervalSec': instance.defaultResendIntervalSec,
      'defaultPasswordMinLength': instance.defaultPasswordMinLength,
      'defaultPasswordMaxLength': instance.defaultPasswordMaxLength,
      'phoneMaskPrefixLength': instance.phoneMaskPrefixLength,
      'phoneMaskSuffixLength': instance.phoneMaskSuffixLength,
    };

_AudioConfig _$AudioConfigFromJson(Map<String, dynamic> json) => _AudioConfig(
  sampleRate: (json['sampleRate'] as num).toInt(),
  channels: (json['channels'] as num).toInt(),
  aacBitrate: (json['aacBitrate'] as num).toInt(),
  levelUpdateIntervalMs: (json['levelUpdateIntervalMs'] as num).toInt(),
  levelFloorDb: (json['levelFloorDb'] as num).toDouble(),
);

Map<String, dynamic> _$AudioConfigToJson(_AudioConfig instance) =>
    <String, dynamic>{
      'sampleRate': instance.sampleRate,
      'channels': instance.channels,
      'aacBitrate': instance.aacBitrate,
      'levelUpdateIntervalMs': instance.levelUpdateIntervalMs,
      'levelFloorDb': instance.levelFloorDb,
    };

_VadConfig _$VadConfigFromJson(Map<String, dynamic> json) => _VadConfig(
  frameMs: (json['frameMs'] as num).toInt(),
  thresholdDbAboveNoise: (json['thresholdDbAboveNoise'] as num).toDouble(),
  noiseFloorPercentile: (json['noiseFloorPercentile'] as num).toInt(),
  noiseFloorWindowSec: (json['noiseFloorWindowSec'] as num).toDouble(),
  silenceToEndMs: (json['silenceToEndMs'] as num).toInt(),
  paddingMs: (json['paddingMs'] as num).toInt(),
  minSpeechMs: (json['minSpeechMs'] as num).toInt(),
  maxSegmentSec: (json['maxSegmentSec'] as num).toDouble(),
  splitSearchWindowSec: (json['splitSearchWindowSec'] as num).toDouble(),
  minThresholdDb: (json['minThresholdDb'] as num).toDouble(),
);

Map<String, dynamic> _$VadConfigToJson(_VadConfig instance) =>
    <String, dynamic>{
      'frameMs': instance.frameMs,
      'thresholdDbAboveNoise': instance.thresholdDbAboveNoise,
      'noiseFloorPercentile': instance.noiseFloorPercentile,
      'noiseFloorWindowSec': instance.noiseFloorWindowSec,
      'silenceToEndMs': instance.silenceToEndMs,
      'paddingMs': instance.paddingMs,
      'minSpeechMs': instance.minSpeechMs,
      'maxSegmentSec': instance.maxSegmentSec,
      'splitSearchWindowSec': instance.splitSearchWindowSec,
      'minThresholdDb': instance.minThresholdDb,
    };

_TranscriptionConfig _$TranscriptionConfigFromJson(Map<String, dynamic> json) =>
    _TranscriptionConfig(
      defaultLanguage: json['defaultLanguage'] as String,
      languages: (json['languages'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      autoLanguageCode: json['autoLanguageCode'] as String,
    );

Map<String, dynamic> _$TranscriptionConfigToJson(
  _TranscriptionConfig instance,
) => <String, dynamic>{
  'defaultLanguage': instance.defaultLanguage,
  'languages': instance.languages,
  'autoLanguageCode': instance.autoLanguageCode,
};

_RecordingConfig _$RecordingConfigFromJson(
  Map<String, dynamic> json,
) => _RecordingConfig(
  defaultSource: $enumDecode(_$RecordingSourceEnumMap, json['defaultSource']),
  titleFormat: json['titleFormat'] as String,
  systemAudioMicGain: (json['systemAudioMicGain'] as num).toDouble(),
  systemAudioDuckingRatio: (json['systemAudioDuckingRatio'] as num).toDouble(),
  keepLocalAudioDefault: json['keepLocalAudioDefault'] as bool,
  audioFileExtension: json['audioFileExtension'] as String,
  audioUploadFileName: json['audioUploadFileName'] as String,
  audioContentType: json['audioContentType'] as String,
  segmentContentType: json['segmentContentType'] as String,
  recordingsDirName: json['recordingsDirName'] as String,
  pendingQueueDirName: json['pendingQueueDirName'] as String,
  stopDrainTimeoutMs: (json['stopDrainTimeoutMs'] as num).toInt(),
  waveformBars: (json['waveformBars'] as num).toInt(),
  transcriptScrollAnimationMs: (json['transcriptScrollAnimationMs'] as num)
      .toInt(),
  notificationChannelId: json['notificationChannelId'] as String,
  foregroundServiceId: (json['foregroundServiceId'] as num).toInt(),
);

Map<String, dynamic> _$RecordingConfigToJson(_RecordingConfig instance) =>
    <String, dynamic>{
      'defaultSource': _$RecordingSourceEnumMap[instance.defaultSource]!,
      'titleFormat': instance.titleFormat,
      'systemAudioMicGain': instance.systemAudioMicGain,
      'systemAudioDuckingRatio': instance.systemAudioDuckingRatio,
      'keepLocalAudioDefault': instance.keepLocalAudioDefault,
      'audioFileExtension': instance.audioFileExtension,
      'audioUploadFileName': instance.audioUploadFileName,
      'audioContentType': instance.audioContentType,
      'segmentContentType': instance.segmentContentType,
      'recordingsDirName': instance.recordingsDirName,
      'pendingQueueDirName': instance.pendingQueueDirName,
      'stopDrainTimeoutMs': instance.stopDrainTimeoutMs,
      'waveformBars': instance.waveformBars,
      'transcriptScrollAnimationMs': instance.transcriptScrollAnimationMs,
      'notificationChannelId': instance.notificationChannelId,
      'foregroundServiceId': instance.foregroundServiceId,
    };

const _$RecordingSourceEnumMap = {
  RecordingSource.microphone: 'microphone',
  RecordingSource.system: 'system',
};

_FeatureFlags _$FeatureFlagsFromJson(Map<String, dynamic> json) =>
    _FeatureFlags(
      systemAudioCapture: json['systemAudioCapture'] as bool,
      importAudio: json['importAudio'] as bool,
      autoSummaryDefault: json['autoSummaryDefault'] as bool,
      showDevCode: json['showDevCode'] as bool,
      standaloneMessages: json['standaloneMessages'] as bool,
    );

Map<String, dynamic> _$FeatureFlagsToJson(_FeatureFlags instance) =>
    <String, dynamic>{
      'systemAudioCapture': instance.systemAudioCapture,
      'importAudio': instance.importAudio,
      'autoSummaryDefault': instance.autoSummaryDefault,
      'showDevCode': instance.showDevCode,
      'standaloneMessages': instance.standaloneMessages,
    };

_UiConfig _$UiConfigFromJson(Map<String, dynamic> json) => _UiConfig(
  defaultLocaleMode: $enumDecode(
    _$LocaleModeEnumMap,
    json['defaultLocaleMode'],
  ),
  snackBarDurationMs: (json['snackBarDurationMs'] as num).toInt(),
);

Map<String, dynamic> _$UiConfigToJson(_UiConfig instance) => <String, dynamic>{
  'defaultLocaleMode': _$LocaleModeEnumMap[instance.defaultLocaleMode]!,
  'snackBarDurationMs': instance.snackBarDurationMs,
};

const _$LocaleModeEnumMap = {
  LocaleMode.system: 'system',
  LocaleMode.zh: 'zh',
  LocaleMode.en: 'en',
};

_UpdateConfig _$UpdateConfigFromJson(Map<String, dynamic> json) =>
    _UpdateConfig(
      checkIntervalMin: (json['checkIntervalMin'] as num).toInt(),
      promptCooldownHours: (json['promptCooldownHours'] as num).toInt(),
      apkFileName: json['apkFileName'] as String,
    );

Map<String, dynamic> _$UpdateConfigToJson(_UpdateConfig instance) =>
    <String, dynamic>{
      'checkIntervalMin': instance.checkIntervalMin,
      'promptCooldownHours': instance.promptCooldownHours,
      'apkFileName': instance.apkFileName,
    };

_PlayerConfig _$PlayerConfigFromJson(Map<String, dynamic> json) =>
    _PlayerConfig(
      speeds: (json['speeds'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
      skipSeconds: (json['skipSeconds'] as num).toInt(),
    );

Map<String, dynamic> _$PlayerConfigToJson(_PlayerConfig instance) =>
    <String, dynamic>{
      'speeds': instance.speeds,
      'skipSeconds': instance.skipSeconds,
    };

_ImportFileConfig _$ImportFileConfigFromJson(Map<String, dynamic> json) =>
    _ImportFileConfig(
      allowedExtensions: (json['allowedExtensions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$ImportFileConfigToJson(_ImportFileConfig instance) =>
    <String, dynamic>{'allowedExtensions': instance.allowedExtensions};

_MeetingsUiConfig _$MeetingsUiConfigFromJson(Map<String, dynamic> json) =>
    _MeetingsUiConfig(
      relativeDateMaxDays: (json['relativeDateMaxDays'] as num).toInt(),
    );

Map<String, dynamic> _$MeetingsUiConfigToJson(_MeetingsUiConfig instance) =>
    <String, dynamic>{'relativeDateMaxDays': instance.relativeDateMaxDays};

_SystemAudioConfig _$SystemAudioConfigFromJson(Map<String, dynamic> json) =>
    _SystemAudioConfig(
      frameMs: (json['frameMs'] as num).toInt(),
      jitterBufferMs: (json['jitterBufferMs'] as num).toInt(),
      maxBufferMs: (json['maxBufferMs'] as num).toInt(),
      micActiveRmsThreshold: (json['micActiveRmsThreshold'] as num).toDouble(),
      duckingAttackMs: (json['duckingAttackMs'] as num).toInt(),
      duckingReleaseMs: (json['duckingReleaseMs'] as num).toInt(),
      softClipKnee: (json['softClipKnee'] as num).toDouble(),
      levelFloorDb: (json['levelFloorDb'] as num).toDouble(),
      androidCaptureUsages: (json['androidCaptureUsages'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      androidMicSource: json['androidMicSource'] as String,
      androidFallbackCaptureSampleRate:
          (json['androidFallbackCaptureSampleRate'] as num).toInt(),
      androidNotificationChannelId:
          json['androidNotificationChannelId'] as String,
      androidNotificationId: (json['androidNotificationId'] as num).toInt(),
      iosChunkMs: (json['iosChunkMs'] as num).toInt(),
      iosStartTimeoutMs: (json['iosStartTimeoutMs'] as num).toInt(),
      iosStopTimeoutMs: (json['iosStopTimeoutMs'] as num).toInt(),
      iosPollIntervalMs: (json['iosPollIntervalMs'] as num).toInt(),
      iosMaxPendingChunks: (json['iosMaxPendingChunks'] as num).toInt(),
      iosKeepAliveInBackground: json['iosKeepAliveInBackground'] as bool,
    );

Map<String, dynamic> _$SystemAudioConfigToJson(
  _SystemAudioConfig instance,
) => <String, dynamic>{
  'frameMs': instance.frameMs,
  'jitterBufferMs': instance.jitterBufferMs,
  'maxBufferMs': instance.maxBufferMs,
  'micActiveRmsThreshold': instance.micActiveRmsThreshold,
  'duckingAttackMs': instance.duckingAttackMs,
  'duckingReleaseMs': instance.duckingReleaseMs,
  'softClipKnee': instance.softClipKnee,
  'levelFloorDb': instance.levelFloorDb,
  'androidCaptureUsages': instance.androidCaptureUsages,
  'androidMicSource': instance.androidMicSource,
  'androidFallbackCaptureSampleRate': instance.androidFallbackCaptureSampleRate,
  'androidNotificationChannelId': instance.androidNotificationChannelId,
  'androidNotificationId': instance.androidNotificationId,
  'iosChunkMs': instance.iosChunkMs,
  'iosStartTimeoutMs': instance.iosStartTimeoutMs,
  'iosStopTimeoutMs': instance.iosStopTimeoutMs,
  'iosPollIntervalMs': instance.iosPollIntervalMs,
  'iosMaxPendingChunks': instance.iosMaxPendingChunks,
  'iosKeepAliveInBackground': instance.iosKeepAliveInBackground,
};
