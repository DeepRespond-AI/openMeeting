// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AppConfig {
  /// `dev` | `test` | `prod`.
  String get env;

  /// The server this build talks to. Fixed per build (`app_config.<env>.json`); users can
  /// neither see nor change it. Empty = misconfigured build (sign-in is impossible).
  String get defaultServerUrl;
  NetworkConfig get network;
  HeartbeatConfig get heartbeat;
  PollingConfig get polling;
  PaginationConfig get pagination;
  AuthConfigDefaults get auth;
  AudioConfig get audio;
  VadConfig get vad;
  TranscriptionConfig get transcription;
  RecordingConfig get recording;
  FeatureFlags get features;
  UiConfig get ui;
  PlayerConfig get player;
  ImportFileConfig get importFile;
  MeetingsUiConfig get meetingsUi;
  SystemAudioConfig get systemAudio;
  UpdateConfig get update;
  LiveConfig get live;

  /// Create a copy of AppConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $AppConfigCopyWith<AppConfig> get copyWith =>
      _$AppConfigCopyWithImpl<AppConfig>(this as AppConfig, _$identity);

  /// Serializes this AppConfig to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as AppConfig;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AppConfig &&
            (identical(other.env, _this.env) || other.env == _this.env) &&
            (identical(other.defaultServerUrl, _this.defaultServerUrl) ||
                other.defaultServerUrl == _this.defaultServerUrl) &&
            (identical(other.network, _this.network) ||
                other.network == _this.network) &&
            (identical(other.heartbeat, _this.heartbeat) ||
                other.heartbeat == _this.heartbeat) &&
            (identical(other.polling, _this.polling) ||
                other.polling == _this.polling) &&
            (identical(other.pagination, _this.pagination) ||
                other.pagination == _this.pagination) &&
            (identical(other.auth, _this.auth) || other.auth == _this.auth) &&
            (identical(other.audio, _this.audio) ||
                other.audio == _this.audio) &&
            (identical(other.vad, _this.vad) || other.vad == _this.vad) &&
            (identical(other.transcription, _this.transcription) ||
                other.transcription == _this.transcription) &&
            (identical(other.recording, _this.recording) ||
                other.recording == _this.recording) &&
            (identical(other.features, _this.features) ||
                other.features == _this.features) &&
            (identical(other.ui, _this.ui) || other.ui == _this.ui) &&
            (identical(other.player, _this.player) ||
                other.player == _this.player) &&
            (identical(other.importFile, _this.importFile) ||
                other.importFile == _this.importFile) &&
            (identical(other.meetingsUi, _this.meetingsUi) ||
                other.meetingsUi == _this.meetingsUi) &&
            (identical(other.systemAudio, _this.systemAudio) ||
                other.systemAudio == _this.systemAudio) &&
            (identical(other.update, _this.update) ||
                other.update == _this.update) &&
            (identical(other.live, _this.live) || other.live == _this.live));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as AppConfig;
    return Object.hashAll([
      runtimeType,
      _this.env,
      _this.defaultServerUrl,
      _this.network,
      _this.heartbeat,
      _this.polling,
      _this.pagination,
      _this.auth,
      _this.audio,
      _this.vad,
      _this.transcription,
      _this.recording,
      _this.features,
      _this.ui,
      _this.player,
      _this.importFile,
      _this.meetingsUi,
      _this.systemAudio,
      _this.update,
      _this.live,
    ]);
  }

  @override
  String toString() {
    final _this = this as AppConfig;
    return 'AppConfig(env: ${_this.env}, defaultServerUrl: ${_this.defaultServerUrl}, network: ${_this.network}, heartbeat: ${_this.heartbeat}, polling: ${_this.polling}, pagination: ${_this.pagination}, auth: ${_this.auth}, audio: ${_this.audio}, vad: ${_this.vad}, transcription: ${_this.transcription}, recording: ${_this.recording}, features: ${_this.features}, ui: ${_this.ui}, player: ${_this.player}, importFile: ${_this.importFile}, meetingsUi: ${_this.meetingsUi}, systemAudio: ${_this.systemAudio}, update: ${_this.update}, live: ${_this.live})';
  }
}

/// @nodoc
abstract mixin class $AppConfigCopyWith<$Res> {
  factory $AppConfigCopyWith(AppConfig value, $Res Function(AppConfig) _then) =
      _$AppConfigCopyWithImpl;
  @useResult
  $Res call({
    String env,
    String defaultServerUrl,
    NetworkConfig network,
    HeartbeatConfig heartbeat,
    PollingConfig polling,
    PaginationConfig pagination,
    AuthConfigDefaults auth,
    AudioConfig audio,
    VadConfig vad,
    TranscriptionConfig transcription,
    RecordingConfig recording,
    FeatureFlags features,
    UiConfig ui,
    PlayerConfig player,
    ImportFileConfig importFile,
    MeetingsUiConfig meetingsUi,
    SystemAudioConfig systemAudio,
    UpdateConfig update,
    LiveConfig live,
  });

  $NetworkConfigCopyWith<$Res> get network;
  $HeartbeatConfigCopyWith<$Res> get heartbeat;
  $PollingConfigCopyWith<$Res> get polling;
  $PaginationConfigCopyWith<$Res> get pagination;
  $AuthConfigDefaultsCopyWith<$Res> get auth;
  $AudioConfigCopyWith<$Res> get audio;
  $VadConfigCopyWith<$Res> get vad;
  $TranscriptionConfigCopyWith<$Res> get transcription;
  $RecordingConfigCopyWith<$Res> get recording;
  $FeatureFlagsCopyWith<$Res> get features;
  $UiConfigCopyWith<$Res> get ui;
  $PlayerConfigCopyWith<$Res> get player;
  $ImportFileConfigCopyWith<$Res> get importFile;
  $MeetingsUiConfigCopyWith<$Res> get meetingsUi;
  $SystemAudioConfigCopyWith<$Res> get systemAudio;
  $UpdateConfigCopyWith<$Res> get update;
  $LiveConfigCopyWith<$Res> get live;
}

/// @nodoc
class _$AppConfigCopyWithImpl<$Res> implements $AppConfigCopyWith<$Res> {
  _$AppConfigCopyWithImpl(this._self, this._then);

  final AppConfig _self;
  final $Res Function(AppConfig) _then;

  /// Create a copy of AppConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? env = null,
    Object? defaultServerUrl = null,
    Object? network = null,
    Object? heartbeat = null,
    Object? polling = null,
    Object? pagination = null,
    Object? auth = null,
    Object? audio = null,
    Object? vad = null,
    Object? transcription = null,
    Object? recording = null,
    Object? features = null,
    Object? ui = null,
    Object? player = null,
    Object? importFile = null,
    Object? meetingsUi = null,
    Object? systemAudio = null,
    Object? update = null,
    Object? live = null,
  }) {
    return _then(
      AppConfig(
        env: null == env
            ? _self.env
            : env // ignore: cast_nullable_to_non_nullable
                  as String,
        defaultServerUrl: null == defaultServerUrl
            ? _self.defaultServerUrl
            : defaultServerUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        network: null == network
            ? _self.network
            : network // ignore: cast_nullable_to_non_nullable
                  as NetworkConfig,
        heartbeat: null == heartbeat
            ? _self.heartbeat
            : heartbeat // ignore: cast_nullable_to_non_nullable
                  as HeartbeatConfig,
        polling: null == polling
            ? _self.polling
            : polling // ignore: cast_nullable_to_non_nullable
                  as PollingConfig,
        pagination: null == pagination
            ? _self.pagination
            : pagination // ignore: cast_nullable_to_non_nullable
                  as PaginationConfig,
        auth: null == auth
            ? _self.auth
            : auth // ignore: cast_nullable_to_non_nullable
                  as AuthConfigDefaults,
        audio: null == audio
            ? _self.audio
            : audio // ignore: cast_nullable_to_non_nullable
                  as AudioConfig,
        vad: null == vad
            ? _self.vad
            : vad // ignore: cast_nullable_to_non_nullable
                  as VadConfig,
        transcription: null == transcription
            ? _self.transcription
            : transcription // ignore: cast_nullable_to_non_nullable
                  as TranscriptionConfig,
        recording: null == recording
            ? _self.recording
            : recording // ignore: cast_nullable_to_non_nullable
                  as RecordingConfig,
        features: null == features
            ? _self.features
            : features // ignore: cast_nullable_to_non_nullable
                  as FeatureFlags,
        ui: null == ui
            ? _self.ui
            : ui // ignore: cast_nullable_to_non_nullable
                  as UiConfig,
        player: null == player
            ? _self.player
            : player // ignore: cast_nullable_to_non_nullable
                  as PlayerConfig,
        importFile: null == importFile
            ? _self.importFile
            : importFile // ignore: cast_nullable_to_non_nullable
                  as ImportFileConfig,
        meetingsUi: null == meetingsUi
            ? _self.meetingsUi
            : meetingsUi // ignore: cast_nullable_to_non_nullable
                  as MeetingsUiConfig,
        systemAudio: null == systemAudio
            ? _self.systemAudio
            : systemAudio // ignore: cast_nullable_to_non_nullable
                  as SystemAudioConfig,
        update: null == update
            ? _self.update
            : update // ignore: cast_nullable_to_non_nullable
                  as UpdateConfig,
        live: null == live
            ? _self.live
            : live // ignore: cast_nullable_to_non_nullable
                  as LiveConfig,
      ),
    );
  }

  /// Create a copy of AppConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $NetworkConfigCopyWith<$Res> get network {
    return $NetworkConfigCopyWith<$Res>(_self.network, (value) {
      return _then(_self.copyWith(network: value));
    });
  }

  /// Create a copy of AppConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $HeartbeatConfigCopyWith<$Res> get heartbeat {
    return $HeartbeatConfigCopyWith<$Res>(_self.heartbeat, (value) {
      return _then(_self.copyWith(heartbeat: value));
    });
  }

  /// Create a copy of AppConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PollingConfigCopyWith<$Res> get polling {
    return $PollingConfigCopyWith<$Res>(_self.polling, (value) {
      return _then(_self.copyWith(polling: value));
    });
  }

  /// Create a copy of AppConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PaginationConfigCopyWith<$Res> get pagination {
    return $PaginationConfigCopyWith<$Res>(_self.pagination, (value) {
      return _then(_self.copyWith(pagination: value));
    });
  }

  /// Create a copy of AppConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AuthConfigDefaultsCopyWith<$Res> get auth {
    return $AuthConfigDefaultsCopyWith<$Res>(_self.auth, (value) {
      return _then(_self.copyWith(auth: value));
    });
  }

  /// Create a copy of AppConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AudioConfigCopyWith<$Res> get audio {
    return $AudioConfigCopyWith<$Res>(_self.audio, (value) {
      return _then(_self.copyWith(audio: value));
    });
  }

  /// Create a copy of AppConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $VadConfigCopyWith<$Res> get vad {
    return $VadConfigCopyWith<$Res>(_self.vad, (value) {
      return _then(_self.copyWith(vad: value));
    });
  }

  /// Create a copy of AppConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TranscriptionConfigCopyWith<$Res> get transcription {
    return $TranscriptionConfigCopyWith<$Res>(_self.transcription, (value) {
      return _then(_self.copyWith(transcription: value));
    });
  }

  /// Create a copy of AppConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $RecordingConfigCopyWith<$Res> get recording {
    return $RecordingConfigCopyWith<$Res>(_self.recording, (value) {
      return _then(_self.copyWith(recording: value));
    });
  }

  /// Create a copy of AppConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $FeatureFlagsCopyWith<$Res> get features {
    return $FeatureFlagsCopyWith<$Res>(_self.features, (value) {
      return _then(_self.copyWith(features: value));
    });
  }

  /// Create a copy of AppConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $UiConfigCopyWith<$Res> get ui {
    return $UiConfigCopyWith<$Res>(_self.ui, (value) {
      return _then(_self.copyWith(ui: value));
    });
  }

  /// Create a copy of AppConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PlayerConfigCopyWith<$Res> get player {
    return $PlayerConfigCopyWith<$Res>(_self.player, (value) {
      return _then(_self.copyWith(player: value));
    });
  }

  /// Create a copy of AppConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ImportFileConfigCopyWith<$Res> get importFile {
    return $ImportFileConfigCopyWith<$Res>(_self.importFile, (value) {
      return _then(_self.copyWith(importFile: value));
    });
  }

  /// Create a copy of AppConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MeetingsUiConfigCopyWith<$Res> get meetingsUi {
    return $MeetingsUiConfigCopyWith<$Res>(_self.meetingsUi, (value) {
      return _then(_self.copyWith(meetingsUi: value));
    });
  }

  /// Create a copy of AppConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SystemAudioConfigCopyWith<$Res> get systemAudio {
    return $SystemAudioConfigCopyWith<$Res>(_self.systemAudio, (value) {
      return _then(_self.copyWith(systemAudio: value));
    });
  }

  /// Create a copy of AppConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $UpdateConfigCopyWith<$Res> get update {
    return $UpdateConfigCopyWith<$Res>(_self.update, (value) {
      return _then(_self.copyWith(update: value));
    });
  }

  /// Create a copy of AppConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $LiveConfigCopyWith<$Res> get live {
    return $LiveConfigCopyWith<$Res>(_self.live, (value) {
      return _then(_self.copyWith(live: value));
    });
  }
}

/// Adds pattern-matching-related methods to [AppConfig].
extension AppConfigPatterns on AppConfig {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_AppConfig value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AppConfig() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_AppConfig value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AppConfig():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_AppConfig value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AppConfig() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
      String env,
      String defaultServerUrl,
      NetworkConfig network,
      HeartbeatConfig heartbeat,
      PollingConfig polling,
      PaginationConfig pagination,
      AuthConfigDefaults auth,
      AudioConfig audio,
      VadConfig vad,
      TranscriptionConfig transcription,
      RecordingConfig recording,
      FeatureFlags features,
      UiConfig ui,
      PlayerConfig player,
      ImportFileConfig importFile,
      MeetingsUiConfig meetingsUi,
      SystemAudioConfig systemAudio,
      UpdateConfig update,
      LiveConfig live,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AppConfig() when $default != null:
        return $default(
          _that.env,
          _that.defaultServerUrl,
          _that.network,
          _that.heartbeat,
          _that.polling,
          _that.pagination,
          _that.auth,
          _that.audio,
          _that.vad,
          _that.transcription,
          _that.recording,
          _that.features,
          _that.ui,
          _that.player,
          _that.importFile,
          _that.meetingsUi,
          _that.systemAudio,
          _that.update,
          _that.live,
        );
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
      String env,
      String defaultServerUrl,
      NetworkConfig network,
      HeartbeatConfig heartbeat,
      PollingConfig polling,
      PaginationConfig pagination,
      AuthConfigDefaults auth,
      AudioConfig audio,
      VadConfig vad,
      TranscriptionConfig transcription,
      RecordingConfig recording,
      FeatureFlags features,
      UiConfig ui,
      PlayerConfig player,
      ImportFileConfig importFile,
      MeetingsUiConfig meetingsUi,
      SystemAudioConfig systemAudio,
      UpdateConfig update,
      LiveConfig live,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AppConfig():
        return $default(
          _that.env,
          _that.defaultServerUrl,
          _that.network,
          _that.heartbeat,
          _that.polling,
          _that.pagination,
          _that.auth,
          _that.audio,
          _that.vad,
          _that.transcription,
          _that.recording,
          _that.features,
          _that.ui,
          _that.player,
          _that.importFile,
          _that.meetingsUi,
          _that.systemAudio,
          _that.update,
          _that.live,
        );
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
      String env,
      String defaultServerUrl,
      NetworkConfig network,
      HeartbeatConfig heartbeat,
      PollingConfig polling,
      PaginationConfig pagination,
      AuthConfigDefaults auth,
      AudioConfig audio,
      VadConfig vad,
      TranscriptionConfig transcription,
      RecordingConfig recording,
      FeatureFlags features,
      UiConfig ui,
      PlayerConfig player,
      ImportFileConfig importFile,
      MeetingsUiConfig meetingsUi,
      SystemAudioConfig systemAudio,
      UpdateConfig update,
      LiveConfig live,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AppConfig() when $default != null:
        return $default(
          _that.env,
          _that.defaultServerUrl,
          _that.network,
          _that.heartbeat,
          _that.polling,
          _that.pagination,
          _that.auth,
          _that.audio,
          _that.vad,
          _that.transcription,
          _that.recording,
          _that.features,
          _that.ui,
          _that.player,
          _that.importFile,
          _that.meetingsUi,
          _that.systemAudio,
          _that.update,
          _that.live,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _AppConfig extends AppConfig {
  const _AppConfig({
    required this.env,
    required this.defaultServerUrl,
    required this.network,
    required this.heartbeat,
    required this.polling,
    required this.pagination,
    required this.auth,
    required this.audio,
    required this.vad,
    required this.transcription,
    required this.recording,
    required this.features,
    required this.ui,
    required this.player,
    required this.importFile,
    required this.meetingsUi,
    required this.systemAudio,
    required this.update,
    required this.live,
  }) : super._();
  factory _AppConfig.fromJson(Map<String, dynamic> json) =>
      _$AppConfigFromJson(json);

  /// `dev` | `test` | `prod`.
  @override
  final String env;

  /// The server this build talks to. Fixed per build (`app_config.<env>.json`); users can
  /// neither see nor change it. Empty = misconfigured build (sign-in is impossible).
  @override
  final String defaultServerUrl;
  @override
  final NetworkConfig network;
  @override
  final HeartbeatConfig heartbeat;
  @override
  final PollingConfig polling;
  @override
  final PaginationConfig pagination;
  @override
  final AuthConfigDefaults auth;
  @override
  final AudioConfig audio;
  @override
  final VadConfig vad;
  @override
  final TranscriptionConfig transcription;
  @override
  final RecordingConfig recording;
  @override
  final FeatureFlags features;
  @override
  final UiConfig ui;
  @override
  final PlayerConfig player;
  @override
  final ImportFileConfig importFile;
  @override
  final MeetingsUiConfig meetingsUi;
  @override
  final SystemAudioConfig systemAudio;
  @override
  final UpdateConfig update;
  @override
  final LiveConfig live;

  /// Create a copy of AppConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$AppConfigCopyWith<_AppConfig> get copyWith =>
      __$AppConfigCopyWithImpl<_AppConfig>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$AppConfigToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _AppConfig &&
            (identical(other.env, env) || other.env == env) &&
            (identical(other.defaultServerUrl, defaultServerUrl) ||
                other.defaultServerUrl == defaultServerUrl) &&
            (identical(other.network, network) || other.network == network) &&
            (identical(other.heartbeat, heartbeat) ||
                other.heartbeat == heartbeat) &&
            (identical(other.polling, polling) || other.polling == polling) &&
            (identical(other.pagination, pagination) ||
                other.pagination == pagination) &&
            (identical(other.auth, auth) || other.auth == auth) &&
            (identical(other.audio, audio) || other.audio == audio) &&
            (identical(other.vad, vad) || other.vad == vad) &&
            (identical(other.transcription, transcription) ||
                other.transcription == transcription) &&
            (identical(other.recording, recording) ||
                other.recording == recording) &&
            (identical(other.features, features) ||
                other.features == features) &&
            (identical(other.ui, ui) || other.ui == ui) &&
            (identical(other.player, player) || other.player == player) &&
            (identical(other.importFile, importFile) ||
                other.importFile == importFile) &&
            (identical(other.meetingsUi, meetingsUi) ||
                other.meetingsUi == meetingsUi) &&
            (identical(other.systemAudio, systemAudio) ||
                other.systemAudio == systemAudio) &&
            (identical(other.update, update) || other.update == update) &&
            (identical(other.live, live) || other.live == live));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hashAll([
      runtimeType,
      env,
      defaultServerUrl,
      network,
      heartbeat,
      polling,
      pagination,
      auth,
      audio,
      vad,
      transcription,
      recording,
      features,
      ui,
      player,
      importFile,
      meetingsUi,
      systemAudio,
      update,
      live,
    ]);
  }

  @override
  String toString() {
    return 'AppConfig(env: $env, defaultServerUrl: $defaultServerUrl, network: $network, heartbeat: $heartbeat, polling: $polling, pagination: $pagination, auth: $auth, audio: $audio, vad: $vad, transcription: $transcription, recording: $recording, features: $features, ui: $ui, player: $player, importFile: $importFile, meetingsUi: $meetingsUi, systemAudio: $systemAudio, update: $update, live: $live)';
  }
}

/// @nodoc
abstract mixin class _$AppConfigCopyWith<$Res>
    implements $AppConfigCopyWith<$Res> {
  factory _$AppConfigCopyWith(
    _AppConfig value,
    $Res Function(_AppConfig) _then,
  ) = __$AppConfigCopyWithImpl;
  @override
  @useResult
  $Res call({
    String env,
    String defaultServerUrl,
    NetworkConfig network,
    HeartbeatConfig heartbeat,
    PollingConfig polling,
    PaginationConfig pagination,
    AuthConfigDefaults auth,
    AudioConfig audio,
    VadConfig vad,
    TranscriptionConfig transcription,
    RecordingConfig recording,
    FeatureFlags features,
    UiConfig ui,
    PlayerConfig player,
    ImportFileConfig importFile,
    MeetingsUiConfig meetingsUi,
    SystemAudioConfig systemAudio,
    UpdateConfig update,
    LiveConfig live,
  });

  @override
  $NetworkConfigCopyWith<$Res> get network;
  @override
  $HeartbeatConfigCopyWith<$Res> get heartbeat;
  @override
  $PollingConfigCopyWith<$Res> get polling;
  @override
  $PaginationConfigCopyWith<$Res> get pagination;
  @override
  $AuthConfigDefaultsCopyWith<$Res> get auth;
  @override
  $AudioConfigCopyWith<$Res> get audio;
  @override
  $VadConfigCopyWith<$Res> get vad;
  @override
  $TranscriptionConfigCopyWith<$Res> get transcription;
  @override
  $RecordingConfigCopyWith<$Res> get recording;
  @override
  $FeatureFlagsCopyWith<$Res> get features;
  @override
  $UiConfigCopyWith<$Res> get ui;
  @override
  $PlayerConfigCopyWith<$Res> get player;
  @override
  $ImportFileConfigCopyWith<$Res> get importFile;
  @override
  $MeetingsUiConfigCopyWith<$Res> get meetingsUi;
  @override
  $SystemAudioConfigCopyWith<$Res> get systemAudio;
  @override
  $UpdateConfigCopyWith<$Res> get update;
  @override
  $LiveConfigCopyWith<$Res> get live;
}

/// @nodoc
class __$AppConfigCopyWithImpl<$Res> implements _$AppConfigCopyWith<$Res> {
  __$AppConfigCopyWithImpl(this._self, this._then);

  final _AppConfig _self;
  final $Res Function(_AppConfig) _then;

  /// Create a copy of AppConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? env = null,
    Object? defaultServerUrl = null,
    Object? network = null,
    Object? heartbeat = null,
    Object? polling = null,
    Object? pagination = null,
    Object? auth = null,
    Object? audio = null,
    Object? vad = null,
    Object? transcription = null,
    Object? recording = null,
    Object? features = null,
    Object? ui = null,
    Object? player = null,
    Object? importFile = null,
    Object? meetingsUi = null,
    Object? systemAudio = null,
    Object? update = null,
    Object? live = null,
  }) {
    return _then(
      _AppConfig(
        env: null == env
            ? _self.env
            : env // ignore: cast_nullable_to_non_nullable
                  as String,
        defaultServerUrl: null == defaultServerUrl
            ? _self.defaultServerUrl
            : defaultServerUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        network: null == network
            ? _self.network
            : network // ignore: cast_nullable_to_non_nullable
                  as NetworkConfig,
        heartbeat: null == heartbeat
            ? _self.heartbeat
            : heartbeat // ignore: cast_nullable_to_non_nullable
                  as HeartbeatConfig,
        polling: null == polling
            ? _self.polling
            : polling // ignore: cast_nullable_to_non_nullable
                  as PollingConfig,
        pagination: null == pagination
            ? _self.pagination
            : pagination // ignore: cast_nullable_to_non_nullable
                  as PaginationConfig,
        auth: null == auth
            ? _self.auth
            : auth // ignore: cast_nullable_to_non_nullable
                  as AuthConfigDefaults,
        audio: null == audio
            ? _self.audio
            : audio // ignore: cast_nullable_to_non_nullable
                  as AudioConfig,
        vad: null == vad
            ? _self.vad
            : vad // ignore: cast_nullable_to_non_nullable
                  as VadConfig,
        transcription: null == transcription
            ? _self.transcription
            : transcription // ignore: cast_nullable_to_non_nullable
                  as TranscriptionConfig,
        recording: null == recording
            ? _self.recording
            : recording // ignore: cast_nullable_to_non_nullable
                  as RecordingConfig,
        features: null == features
            ? _self.features
            : features // ignore: cast_nullable_to_non_nullable
                  as FeatureFlags,
        ui: null == ui
            ? _self.ui
            : ui // ignore: cast_nullable_to_non_nullable
                  as UiConfig,
        player: null == player
            ? _self.player
            : player // ignore: cast_nullable_to_non_nullable
                  as PlayerConfig,
        importFile: null == importFile
            ? _self.importFile
            : importFile // ignore: cast_nullable_to_non_nullable
                  as ImportFileConfig,
        meetingsUi: null == meetingsUi
            ? _self.meetingsUi
            : meetingsUi // ignore: cast_nullable_to_non_nullable
                  as MeetingsUiConfig,
        systemAudio: null == systemAudio
            ? _self.systemAudio
            : systemAudio // ignore: cast_nullable_to_non_nullable
                  as SystemAudioConfig,
        update: null == update
            ? _self.update
            : update // ignore: cast_nullable_to_non_nullable
                  as UpdateConfig,
        live: null == live
            ? _self.live
            : live // ignore: cast_nullable_to_non_nullable
                  as LiveConfig,
      ),
    );
  }

  /// Create a copy of AppConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $NetworkConfigCopyWith<$Res> get network {
    return $NetworkConfigCopyWith<$Res>(_self.network, (value) {
      return _then(_self.copyWith(network: value));
    });
  }

  /// Create a copy of AppConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $HeartbeatConfigCopyWith<$Res> get heartbeat {
    return $HeartbeatConfigCopyWith<$Res>(_self.heartbeat, (value) {
      return _then(_self.copyWith(heartbeat: value));
    });
  }

  /// Create a copy of AppConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PollingConfigCopyWith<$Res> get polling {
    return $PollingConfigCopyWith<$Res>(_self.polling, (value) {
      return _then(_self.copyWith(polling: value));
    });
  }

  /// Create a copy of AppConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PaginationConfigCopyWith<$Res> get pagination {
    return $PaginationConfigCopyWith<$Res>(_self.pagination, (value) {
      return _then(_self.copyWith(pagination: value));
    });
  }

  /// Create a copy of AppConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AuthConfigDefaultsCopyWith<$Res> get auth {
    return $AuthConfigDefaultsCopyWith<$Res>(_self.auth, (value) {
      return _then(_self.copyWith(auth: value));
    });
  }

  /// Create a copy of AppConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AudioConfigCopyWith<$Res> get audio {
    return $AudioConfigCopyWith<$Res>(_self.audio, (value) {
      return _then(_self.copyWith(audio: value));
    });
  }

  /// Create a copy of AppConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $VadConfigCopyWith<$Res> get vad {
    return $VadConfigCopyWith<$Res>(_self.vad, (value) {
      return _then(_self.copyWith(vad: value));
    });
  }

  /// Create a copy of AppConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TranscriptionConfigCopyWith<$Res> get transcription {
    return $TranscriptionConfigCopyWith<$Res>(_self.transcription, (value) {
      return _then(_self.copyWith(transcription: value));
    });
  }

  /// Create a copy of AppConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $RecordingConfigCopyWith<$Res> get recording {
    return $RecordingConfigCopyWith<$Res>(_self.recording, (value) {
      return _then(_self.copyWith(recording: value));
    });
  }

  /// Create a copy of AppConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $FeatureFlagsCopyWith<$Res> get features {
    return $FeatureFlagsCopyWith<$Res>(_self.features, (value) {
      return _then(_self.copyWith(features: value));
    });
  }

  /// Create a copy of AppConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $UiConfigCopyWith<$Res> get ui {
    return $UiConfigCopyWith<$Res>(_self.ui, (value) {
      return _then(_self.copyWith(ui: value));
    });
  }

  /// Create a copy of AppConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PlayerConfigCopyWith<$Res> get player {
    return $PlayerConfigCopyWith<$Res>(_self.player, (value) {
      return _then(_self.copyWith(player: value));
    });
  }

  /// Create a copy of AppConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ImportFileConfigCopyWith<$Res> get importFile {
    return $ImportFileConfigCopyWith<$Res>(_self.importFile, (value) {
      return _then(_self.copyWith(importFile: value));
    });
  }

  /// Create a copy of AppConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MeetingsUiConfigCopyWith<$Res> get meetingsUi {
    return $MeetingsUiConfigCopyWith<$Res>(_self.meetingsUi, (value) {
      return _then(_self.copyWith(meetingsUi: value));
    });
  }

  /// Create a copy of AppConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SystemAudioConfigCopyWith<$Res> get systemAudio {
    return $SystemAudioConfigCopyWith<$Res>(_self.systemAudio, (value) {
      return _then(_self.copyWith(systemAudio: value));
    });
  }

  /// Create a copy of AppConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $UpdateConfigCopyWith<$Res> get update {
    return $UpdateConfigCopyWith<$Res>(_self.update, (value) {
      return _then(_self.copyWith(update: value));
    });
  }

  /// Create a copy of AppConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $LiveConfigCopyWith<$Res> get live {
    return $LiveConfigCopyWith<$Res>(_self.live, (value) {
      return _then(_self.copyWith(live: value));
    });
  }
}

/// @nodoc
mixin _$LiveConfig {
  int get rtcReleaseTimeoutMs;
  int get rtcReleasePollMs;
  int get waitingPollMs;
  int get wsPingMs;
  int get maxReconnects;
  int get reconnectMs;
  int get titleMax;
  int get nameMax;
  int get chatMax;
  int get attachmentMaxBytes;
  int get scheduleRangeDays;
  int get defaultDurationMin;
  int get minDurationMin;
  int get maxDurationMin;
  int get imPageSize;
  int get imTextMax;
  int get voiceLimitSec;
  int get reminderLeadMin;
  int get reminderPollMs;
  int get recordingChunkMs;
  int get recordingMaxPending;
  int get recordingFrameTimeoutMs;
  int get scheduleMaxDays;
  int get noticeDedupLimit;
  int get noticeHistoryLimit;
  int get avatarMaxBytes;
  List<String> get avatarExtensions;
  int get rtcSampleMs;
  int get rtcStaleMs;
  double get rtcSpeakingLevel;
  int get rtcSpeakingHoldMs;
  int get rtcFairRttMs;
  int get rtcPoorRttMs;
  double get rtcFairLossPercent;
  double get rtcPoorLossPercent;
  int get screenTrackTimeoutMs;

  /// Create a copy of LiveConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $LiveConfigCopyWith<LiveConfig> get copyWith =>
      _$LiveConfigCopyWithImpl<LiveConfig>(this as LiveConfig, _$identity);

  /// Serializes this LiveConfig to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as LiveConfig;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is LiveConfig &&
            (identical(other.rtcReleaseTimeoutMs, _this.rtcReleaseTimeoutMs) ||
                other.rtcReleaseTimeoutMs == _this.rtcReleaseTimeoutMs) &&
            (identical(other.rtcReleasePollMs, _this.rtcReleasePollMs) ||
                other.rtcReleasePollMs == _this.rtcReleasePollMs) &&
            (identical(other.waitingPollMs, _this.waitingPollMs) ||
                other.waitingPollMs == _this.waitingPollMs) &&
            (identical(other.wsPingMs, _this.wsPingMs) ||
                other.wsPingMs == _this.wsPingMs) &&
            (identical(other.maxReconnects, _this.maxReconnects) ||
                other.maxReconnects == _this.maxReconnects) &&
            (identical(other.reconnectMs, _this.reconnectMs) ||
                other.reconnectMs == _this.reconnectMs) &&
            (identical(other.titleMax, _this.titleMax) ||
                other.titleMax == _this.titleMax) &&
            (identical(other.nameMax, _this.nameMax) ||
                other.nameMax == _this.nameMax) &&
            (identical(other.chatMax, _this.chatMax) ||
                other.chatMax == _this.chatMax) &&
            (identical(other.attachmentMaxBytes, _this.attachmentMaxBytes) ||
                other.attachmentMaxBytes == _this.attachmentMaxBytes) &&
            (identical(other.scheduleRangeDays, _this.scheduleRangeDays) ||
                other.scheduleRangeDays == _this.scheduleRangeDays) &&
            (identical(other.defaultDurationMin, _this.defaultDurationMin) ||
                other.defaultDurationMin == _this.defaultDurationMin) &&
            (identical(other.minDurationMin, _this.minDurationMin) ||
                other.minDurationMin == _this.minDurationMin) &&
            (identical(other.maxDurationMin, _this.maxDurationMin) ||
                other.maxDurationMin == _this.maxDurationMin) &&
            (identical(other.imPageSize, _this.imPageSize) ||
                other.imPageSize == _this.imPageSize) &&
            (identical(other.imTextMax, _this.imTextMax) ||
                other.imTextMax == _this.imTextMax) &&
            (identical(other.voiceLimitSec, _this.voiceLimitSec) ||
                other.voiceLimitSec == _this.voiceLimitSec) &&
            (identical(other.reminderLeadMin, _this.reminderLeadMin) ||
                other.reminderLeadMin == _this.reminderLeadMin) &&
            (identical(other.reminderPollMs, _this.reminderPollMs) ||
                other.reminderPollMs == _this.reminderPollMs) &&
            (identical(other.recordingChunkMs, _this.recordingChunkMs) ||
                other.recordingChunkMs == _this.recordingChunkMs) &&
            (identical(other.recordingMaxPending, _this.recordingMaxPending) ||
                other.recordingMaxPending == _this.recordingMaxPending) &&
            (identical(
                  other.recordingFrameTimeoutMs,
                  _this.recordingFrameTimeoutMs,
                ) ||
                other.recordingFrameTimeoutMs ==
                    _this.recordingFrameTimeoutMs) &&
            (identical(other.scheduleMaxDays, _this.scheduleMaxDays) ||
                other.scheduleMaxDays == _this.scheduleMaxDays) &&
            (identical(other.noticeDedupLimit, _this.noticeDedupLimit) ||
                other.noticeDedupLimit == _this.noticeDedupLimit) &&
            (identical(other.noticeHistoryLimit, _this.noticeHistoryLimit) ||
                other.noticeHistoryLimit == _this.noticeHistoryLimit) &&
            (identical(other.avatarMaxBytes, _this.avatarMaxBytes) ||
                other.avatarMaxBytes == _this.avatarMaxBytes) &&
            const DeepCollectionEquality().equals(
              other.avatarExtensions,
              _this.avatarExtensions,
            ) &&
            (identical(other.rtcSampleMs, _this.rtcSampleMs) ||
                other.rtcSampleMs == _this.rtcSampleMs) &&
            (identical(other.rtcStaleMs, _this.rtcStaleMs) ||
                other.rtcStaleMs == _this.rtcStaleMs) &&
            (identical(other.rtcSpeakingLevel, _this.rtcSpeakingLevel) ||
                other.rtcSpeakingLevel == _this.rtcSpeakingLevel) &&
            (identical(other.rtcSpeakingHoldMs, _this.rtcSpeakingHoldMs) ||
                other.rtcSpeakingHoldMs == _this.rtcSpeakingHoldMs) &&
            (identical(other.rtcFairRttMs, _this.rtcFairRttMs) ||
                other.rtcFairRttMs == _this.rtcFairRttMs) &&
            (identical(other.rtcPoorRttMs, _this.rtcPoorRttMs) ||
                other.rtcPoorRttMs == _this.rtcPoorRttMs) &&
            (identical(other.rtcFairLossPercent, _this.rtcFairLossPercent) ||
                other.rtcFairLossPercent == _this.rtcFairLossPercent) &&
            (identical(other.rtcPoorLossPercent, _this.rtcPoorLossPercent) ||
                other.rtcPoorLossPercent == _this.rtcPoorLossPercent) &&
            (identical(
                  other.screenTrackTimeoutMs,
                  _this.screenTrackTimeoutMs,
                ) ||
                other.screenTrackTimeoutMs == _this.screenTrackTimeoutMs));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as LiveConfig;
    return Object.hashAll([
      runtimeType,
      _this.rtcReleaseTimeoutMs,
      _this.rtcReleasePollMs,
      _this.waitingPollMs,
      _this.wsPingMs,
      _this.maxReconnects,
      _this.reconnectMs,
      _this.titleMax,
      _this.nameMax,
      _this.chatMax,
      _this.attachmentMaxBytes,
      _this.scheduleRangeDays,
      _this.defaultDurationMin,
      _this.minDurationMin,
      _this.maxDurationMin,
      _this.imPageSize,
      _this.imTextMax,
      _this.voiceLimitSec,
      _this.reminderLeadMin,
      _this.reminderPollMs,
      _this.recordingChunkMs,
      _this.recordingMaxPending,
      _this.recordingFrameTimeoutMs,
      _this.scheduleMaxDays,
      _this.noticeDedupLimit,
      _this.noticeHistoryLimit,
      _this.avatarMaxBytes,
      const DeepCollectionEquality().hash(_this.avatarExtensions),
      _this.rtcSampleMs,
      _this.rtcStaleMs,
      _this.rtcSpeakingLevel,
      _this.rtcSpeakingHoldMs,
      _this.rtcFairRttMs,
      _this.rtcPoorRttMs,
      _this.rtcFairLossPercent,
      _this.rtcPoorLossPercent,
      _this.screenTrackTimeoutMs,
    ]);
  }

  @override
  String toString() {
    final _this = this as LiveConfig;
    return 'LiveConfig(rtcReleaseTimeoutMs: ${_this.rtcReleaseTimeoutMs}, rtcReleasePollMs: ${_this.rtcReleasePollMs}, waitingPollMs: ${_this.waitingPollMs}, wsPingMs: ${_this.wsPingMs}, maxReconnects: ${_this.maxReconnects}, reconnectMs: ${_this.reconnectMs}, titleMax: ${_this.titleMax}, nameMax: ${_this.nameMax}, chatMax: ${_this.chatMax}, attachmentMaxBytes: ${_this.attachmentMaxBytes}, scheduleRangeDays: ${_this.scheduleRangeDays}, defaultDurationMin: ${_this.defaultDurationMin}, minDurationMin: ${_this.minDurationMin}, maxDurationMin: ${_this.maxDurationMin}, imPageSize: ${_this.imPageSize}, imTextMax: ${_this.imTextMax}, voiceLimitSec: ${_this.voiceLimitSec}, reminderLeadMin: ${_this.reminderLeadMin}, reminderPollMs: ${_this.reminderPollMs}, recordingChunkMs: ${_this.recordingChunkMs}, recordingMaxPending: ${_this.recordingMaxPending}, recordingFrameTimeoutMs: ${_this.recordingFrameTimeoutMs}, scheduleMaxDays: ${_this.scheduleMaxDays}, noticeDedupLimit: ${_this.noticeDedupLimit}, noticeHistoryLimit: ${_this.noticeHistoryLimit}, avatarMaxBytes: ${_this.avatarMaxBytes}, avatarExtensions: ${_this.avatarExtensions}, rtcSampleMs: ${_this.rtcSampleMs}, rtcStaleMs: ${_this.rtcStaleMs}, rtcSpeakingLevel: ${_this.rtcSpeakingLevel}, rtcSpeakingHoldMs: ${_this.rtcSpeakingHoldMs}, rtcFairRttMs: ${_this.rtcFairRttMs}, rtcPoorRttMs: ${_this.rtcPoorRttMs}, rtcFairLossPercent: ${_this.rtcFairLossPercent}, rtcPoorLossPercent: ${_this.rtcPoorLossPercent}, screenTrackTimeoutMs: ${_this.screenTrackTimeoutMs})';
  }
}

/// @nodoc
abstract mixin class $LiveConfigCopyWith<$Res> {
  factory $LiveConfigCopyWith(
    LiveConfig value,
    $Res Function(LiveConfig) _then,
  ) = _$LiveConfigCopyWithImpl;
  @useResult
  $Res call({
    int rtcReleaseTimeoutMs,
    int rtcReleasePollMs,
    int waitingPollMs,
    int wsPingMs,
    int maxReconnects,
    int reconnectMs,
    int titleMax,
    int nameMax,
    int chatMax,
    int attachmentMaxBytes,
    int scheduleRangeDays,
    int defaultDurationMin,
    int minDurationMin,
    int maxDurationMin,
    int imPageSize,
    int imTextMax,
    int voiceLimitSec,
    int reminderLeadMin,
    int reminderPollMs,
    int recordingChunkMs,
    int recordingMaxPending,
    int recordingFrameTimeoutMs,
    int scheduleMaxDays,
    int noticeDedupLimit,
    int noticeHistoryLimit,
    int avatarMaxBytes,
    List<String> avatarExtensions,
    int rtcSampleMs,
    int rtcStaleMs,
    double rtcSpeakingLevel,
    int rtcSpeakingHoldMs,
    int rtcFairRttMs,
    int rtcPoorRttMs,
    double rtcFairLossPercent,
    double rtcPoorLossPercent,
    int screenTrackTimeoutMs,
  });
}

/// @nodoc
class _$LiveConfigCopyWithImpl<$Res> implements $LiveConfigCopyWith<$Res> {
  _$LiveConfigCopyWithImpl(this._self, this._then);

  final LiveConfig _self;
  final $Res Function(LiveConfig) _then;

  /// Create a copy of LiveConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? rtcReleaseTimeoutMs = null,
    Object? rtcReleasePollMs = null,
    Object? waitingPollMs = null,
    Object? wsPingMs = null,
    Object? maxReconnects = null,
    Object? reconnectMs = null,
    Object? titleMax = null,
    Object? nameMax = null,
    Object? chatMax = null,
    Object? attachmentMaxBytes = null,
    Object? scheduleRangeDays = null,
    Object? defaultDurationMin = null,
    Object? minDurationMin = null,
    Object? maxDurationMin = null,
    Object? imPageSize = null,
    Object? imTextMax = null,
    Object? voiceLimitSec = null,
    Object? reminderLeadMin = null,
    Object? reminderPollMs = null,
    Object? recordingChunkMs = null,
    Object? recordingMaxPending = null,
    Object? recordingFrameTimeoutMs = null,
    Object? scheduleMaxDays = null,
    Object? noticeDedupLimit = null,
    Object? noticeHistoryLimit = null,
    Object? avatarMaxBytes = null,
    Object? avatarExtensions = null,
    Object? rtcSampleMs = null,
    Object? rtcStaleMs = null,
    Object? rtcSpeakingLevel = null,
    Object? rtcSpeakingHoldMs = null,
    Object? rtcFairRttMs = null,
    Object? rtcPoorRttMs = null,
    Object? rtcFairLossPercent = null,
    Object? rtcPoorLossPercent = null,
    Object? screenTrackTimeoutMs = null,
  }) {
    return _then(
      LiveConfig(
        rtcReleaseTimeoutMs: null == rtcReleaseTimeoutMs
            ? _self.rtcReleaseTimeoutMs
            : rtcReleaseTimeoutMs // ignore: cast_nullable_to_non_nullable
                  as int,
        rtcReleasePollMs: null == rtcReleasePollMs
            ? _self.rtcReleasePollMs
            : rtcReleasePollMs // ignore: cast_nullable_to_non_nullable
                  as int,
        waitingPollMs: null == waitingPollMs
            ? _self.waitingPollMs
            : waitingPollMs // ignore: cast_nullable_to_non_nullable
                  as int,
        wsPingMs: null == wsPingMs
            ? _self.wsPingMs
            : wsPingMs // ignore: cast_nullable_to_non_nullable
                  as int,
        maxReconnects: null == maxReconnects
            ? _self.maxReconnects
            : maxReconnects // ignore: cast_nullable_to_non_nullable
                  as int,
        reconnectMs: null == reconnectMs
            ? _self.reconnectMs
            : reconnectMs // ignore: cast_nullable_to_non_nullable
                  as int,
        titleMax: null == titleMax
            ? _self.titleMax
            : titleMax // ignore: cast_nullable_to_non_nullable
                  as int,
        nameMax: null == nameMax
            ? _self.nameMax
            : nameMax // ignore: cast_nullable_to_non_nullable
                  as int,
        chatMax: null == chatMax
            ? _self.chatMax
            : chatMax // ignore: cast_nullable_to_non_nullable
                  as int,
        attachmentMaxBytes: null == attachmentMaxBytes
            ? _self.attachmentMaxBytes
            : attachmentMaxBytes // ignore: cast_nullable_to_non_nullable
                  as int,
        scheduleRangeDays: null == scheduleRangeDays
            ? _self.scheduleRangeDays
            : scheduleRangeDays // ignore: cast_nullable_to_non_nullable
                  as int,
        defaultDurationMin: null == defaultDurationMin
            ? _self.defaultDurationMin
            : defaultDurationMin // ignore: cast_nullable_to_non_nullable
                  as int,
        minDurationMin: null == minDurationMin
            ? _self.minDurationMin
            : minDurationMin // ignore: cast_nullable_to_non_nullable
                  as int,
        maxDurationMin: null == maxDurationMin
            ? _self.maxDurationMin
            : maxDurationMin // ignore: cast_nullable_to_non_nullable
                  as int,
        imPageSize: null == imPageSize
            ? _self.imPageSize
            : imPageSize // ignore: cast_nullable_to_non_nullable
                  as int,
        imTextMax: null == imTextMax
            ? _self.imTextMax
            : imTextMax // ignore: cast_nullable_to_non_nullable
                  as int,
        voiceLimitSec: null == voiceLimitSec
            ? _self.voiceLimitSec
            : voiceLimitSec // ignore: cast_nullable_to_non_nullable
                  as int,
        reminderLeadMin: null == reminderLeadMin
            ? _self.reminderLeadMin
            : reminderLeadMin // ignore: cast_nullable_to_non_nullable
                  as int,
        reminderPollMs: null == reminderPollMs
            ? _self.reminderPollMs
            : reminderPollMs // ignore: cast_nullable_to_non_nullable
                  as int,
        recordingChunkMs: null == recordingChunkMs
            ? _self.recordingChunkMs
            : recordingChunkMs // ignore: cast_nullable_to_non_nullable
                  as int,
        recordingMaxPending: null == recordingMaxPending
            ? _self.recordingMaxPending
            : recordingMaxPending // ignore: cast_nullable_to_non_nullable
                  as int,
        recordingFrameTimeoutMs: null == recordingFrameTimeoutMs
            ? _self.recordingFrameTimeoutMs
            : recordingFrameTimeoutMs // ignore: cast_nullable_to_non_nullable
                  as int,
        scheduleMaxDays: null == scheduleMaxDays
            ? _self.scheduleMaxDays
            : scheduleMaxDays // ignore: cast_nullable_to_non_nullable
                  as int,
        noticeDedupLimit: null == noticeDedupLimit
            ? _self.noticeDedupLimit
            : noticeDedupLimit // ignore: cast_nullable_to_non_nullable
                  as int,
        noticeHistoryLimit: null == noticeHistoryLimit
            ? _self.noticeHistoryLimit
            : noticeHistoryLimit // ignore: cast_nullable_to_non_nullable
                  as int,
        avatarMaxBytes: null == avatarMaxBytes
            ? _self.avatarMaxBytes
            : avatarMaxBytes // ignore: cast_nullable_to_non_nullable
                  as int,
        avatarExtensions: null == avatarExtensions
            ? _self.avatarExtensions
            : avatarExtensions // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        rtcSampleMs: null == rtcSampleMs
            ? _self.rtcSampleMs
            : rtcSampleMs // ignore: cast_nullable_to_non_nullable
                  as int,
        rtcStaleMs: null == rtcStaleMs
            ? _self.rtcStaleMs
            : rtcStaleMs // ignore: cast_nullable_to_non_nullable
                  as int,
        rtcSpeakingLevel: null == rtcSpeakingLevel
            ? _self.rtcSpeakingLevel
            : rtcSpeakingLevel // ignore: cast_nullable_to_non_nullable
                  as double,
        rtcSpeakingHoldMs: null == rtcSpeakingHoldMs
            ? _self.rtcSpeakingHoldMs
            : rtcSpeakingHoldMs // ignore: cast_nullable_to_non_nullable
                  as int,
        rtcFairRttMs: null == rtcFairRttMs
            ? _self.rtcFairRttMs
            : rtcFairRttMs // ignore: cast_nullable_to_non_nullable
                  as int,
        rtcPoorRttMs: null == rtcPoorRttMs
            ? _self.rtcPoorRttMs
            : rtcPoorRttMs // ignore: cast_nullable_to_non_nullable
                  as int,
        rtcFairLossPercent: null == rtcFairLossPercent
            ? _self.rtcFairLossPercent
            : rtcFairLossPercent // ignore: cast_nullable_to_non_nullable
                  as double,
        rtcPoorLossPercent: null == rtcPoorLossPercent
            ? _self.rtcPoorLossPercent
            : rtcPoorLossPercent // ignore: cast_nullable_to_non_nullable
                  as double,
        screenTrackTimeoutMs: null == screenTrackTimeoutMs
            ? _self.screenTrackTimeoutMs
            : screenTrackTimeoutMs // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [LiveConfig].
extension LiveConfigPatterns on LiveConfig {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_LiveConfig value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _LiveConfig() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_LiveConfig value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LiveConfig():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_LiveConfig value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LiveConfig() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
      int rtcReleaseTimeoutMs,
      int rtcReleasePollMs,
      int waitingPollMs,
      int wsPingMs,
      int maxReconnects,
      int reconnectMs,
      int titleMax,
      int nameMax,
      int chatMax,
      int attachmentMaxBytes,
      int scheduleRangeDays,
      int defaultDurationMin,
      int minDurationMin,
      int maxDurationMin,
      int imPageSize,
      int imTextMax,
      int voiceLimitSec,
      int reminderLeadMin,
      int reminderPollMs,
      int recordingChunkMs,
      int recordingMaxPending,
      int recordingFrameTimeoutMs,
      int scheduleMaxDays,
      int noticeDedupLimit,
      int noticeHistoryLimit,
      int avatarMaxBytes,
      List<String> avatarExtensions,
      int rtcSampleMs,
      int rtcStaleMs,
      double rtcSpeakingLevel,
      int rtcSpeakingHoldMs,
      int rtcFairRttMs,
      int rtcPoorRttMs,
      double rtcFairLossPercent,
      double rtcPoorLossPercent,
      int screenTrackTimeoutMs,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _LiveConfig() when $default != null:
        return $default(
          _that.rtcReleaseTimeoutMs,
          _that.rtcReleasePollMs,
          _that.waitingPollMs,
          _that.wsPingMs,
          _that.maxReconnects,
          _that.reconnectMs,
          _that.titleMax,
          _that.nameMax,
          _that.chatMax,
          _that.attachmentMaxBytes,
          _that.scheduleRangeDays,
          _that.defaultDurationMin,
          _that.minDurationMin,
          _that.maxDurationMin,
          _that.imPageSize,
          _that.imTextMax,
          _that.voiceLimitSec,
          _that.reminderLeadMin,
          _that.reminderPollMs,
          _that.recordingChunkMs,
          _that.recordingMaxPending,
          _that.recordingFrameTimeoutMs,
          _that.scheduleMaxDays,
          _that.noticeDedupLimit,
          _that.noticeHistoryLimit,
          _that.avatarMaxBytes,
          _that.avatarExtensions,
          _that.rtcSampleMs,
          _that.rtcStaleMs,
          _that.rtcSpeakingLevel,
          _that.rtcSpeakingHoldMs,
          _that.rtcFairRttMs,
          _that.rtcPoorRttMs,
          _that.rtcFairLossPercent,
          _that.rtcPoorLossPercent,
          _that.screenTrackTimeoutMs,
        );
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
      int rtcReleaseTimeoutMs,
      int rtcReleasePollMs,
      int waitingPollMs,
      int wsPingMs,
      int maxReconnects,
      int reconnectMs,
      int titleMax,
      int nameMax,
      int chatMax,
      int attachmentMaxBytes,
      int scheduleRangeDays,
      int defaultDurationMin,
      int minDurationMin,
      int maxDurationMin,
      int imPageSize,
      int imTextMax,
      int voiceLimitSec,
      int reminderLeadMin,
      int reminderPollMs,
      int recordingChunkMs,
      int recordingMaxPending,
      int recordingFrameTimeoutMs,
      int scheduleMaxDays,
      int noticeDedupLimit,
      int noticeHistoryLimit,
      int avatarMaxBytes,
      List<String> avatarExtensions,
      int rtcSampleMs,
      int rtcStaleMs,
      double rtcSpeakingLevel,
      int rtcSpeakingHoldMs,
      int rtcFairRttMs,
      int rtcPoorRttMs,
      double rtcFairLossPercent,
      double rtcPoorLossPercent,
      int screenTrackTimeoutMs,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LiveConfig():
        return $default(
          _that.rtcReleaseTimeoutMs,
          _that.rtcReleasePollMs,
          _that.waitingPollMs,
          _that.wsPingMs,
          _that.maxReconnects,
          _that.reconnectMs,
          _that.titleMax,
          _that.nameMax,
          _that.chatMax,
          _that.attachmentMaxBytes,
          _that.scheduleRangeDays,
          _that.defaultDurationMin,
          _that.minDurationMin,
          _that.maxDurationMin,
          _that.imPageSize,
          _that.imTextMax,
          _that.voiceLimitSec,
          _that.reminderLeadMin,
          _that.reminderPollMs,
          _that.recordingChunkMs,
          _that.recordingMaxPending,
          _that.recordingFrameTimeoutMs,
          _that.scheduleMaxDays,
          _that.noticeDedupLimit,
          _that.noticeHistoryLimit,
          _that.avatarMaxBytes,
          _that.avatarExtensions,
          _that.rtcSampleMs,
          _that.rtcStaleMs,
          _that.rtcSpeakingLevel,
          _that.rtcSpeakingHoldMs,
          _that.rtcFairRttMs,
          _that.rtcPoorRttMs,
          _that.rtcFairLossPercent,
          _that.rtcPoorLossPercent,
          _that.screenTrackTimeoutMs,
        );
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
      int rtcReleaseTimeoutMs,
      int rtcReleasePollMs,
      int waitingPollMs,
      int wsPingMs,
      int maxReconnects,
      int reconnectMs,
      int titleMax,
      int nameMax,
      int chatMax,
      int attachmentMaxBytes,
      int scheduleRangeDays,
      int defaultDurationMin,
      int minDurationMin,
      int maxDurationMin,
      int imPageSize,
      int imTextMax,
      int voiceLimitSec,
      int reminderLeadMin,
      int reminderPollMs,
      int recordingChunkMs,
      int recordingMaxPending,
      int recordingFrameTimeoutMs,
      int scheduleMaxDays,
      int noticeDedupLimit,
      int noticeHistoryLimit,
      int avatarMaxBytes,
      List<String> avatarExtensions,
      int rtcSampleMs,
      int rtcStaleMs,
      double rtcSpeakingLevel,
      int rtcSpeakingHoldMs,
      int rtcFairRttMs,
      int rtcPoorRttMs,
      double rtcFairLossPercent,
      double rtcPoorLossPercent,
      int screenTrackTimeoutMs,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LiveConfig() when $default != null:
        return $default(
          _that.rtcReleaseTimeoutMs,
          _that.rtcReleasePollMs,
          _that.waitingPollMs,
          _that.wsPingMs,
          _that.maxReconnects,
          _that.reconnectMs,
          _that.titleMax,
          _that.nameMax,
          _that.chatMax,
          _that.attachmentMaxBytes,
          _that.scheduleRangeDays,
          _that.defaultDurationMin,
          _that.minDurationMin,
          _that.maxDurationMin,
          _that.imPageSize,
          _that.imTextMax,
          _that.voiceLimitSec,
          _that.reminderLeadMin,
          _that.reminderPollMs,
          _that.recordingChunkMs,
          _that.recordingMaxPending,
          _that.recordingFrameTimeoutMs,
          _that.scheduleMaxDays,
          _that.noticeDedupLimit,
          _that.noticeHistoryLimit,
          _that.avatarMaxBytes,
          _that.avatarExtensions,
          _that.rtcSampleMs,
          _that.rtcStaleMs,
          _that.rtcSpeakingLevel,
          _that.rtcSpeakingHoldMs,
          _that.rtcFairRttMs,
          _that.rtcPoorRttMs,
          _that.rtcFairLossPercent,
          _that.rtcPoorLossPercent,
          _that.screenTrackTimeoutMs,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _LiveConfig implements LiveConfig {
  const _LiveConfig({
    required this.rtcReleaseTimeoutMs,
    required this.rtcReleasePollMs,
    required this.waitingPollMs,
    required this.wsPingMs,
    required this.maxReconnects,
    required this.reconnectMs,
    required this.titleMax,
    required this.nameMax,
    required this.chatMax,
    required this.attachmentMaxBytes,
    required this.scheduleRangeDays,
    required this.defaultDurationMin,
    required this.minDurationMin,
    required this.maxDurationMin,
    required this.imPageSize,
    required this.imTextMax,
    required this.voiceLimitSec,
    required this.reminderLeadMin,
    required this.reminderPollMs,
    required this.recordingChunkMs,
    required this.recordingMaxPending,
    required this.recordingFrameTimeoutMs,
    required this.scheduleMaxDays,
    required this.noticeDedupLimit,
    required this.noticeHistoryLimit,
    required this.avatarMaxBytes,
    required List<String> avatarExtensions,
    required this.rtcSampleMs,
    required this.rtcStaleMs,
    required this.rtcSpeakingLevel,
    required this.rtcSpeakingHoldMs,
    required this.rtcFairRttMs,
    required this.rtcPoorRttMs,
    required this.rtcFairLossPercent,
    required this.rtcPoorLossPercent,
    required this.screenTrackTimeoutMs,
  }) : _avatarExtensions = avatarExtensions;
  factory _LiveConfig.fromJson(Map<String, dynamic> json) =>
      _$LiveConfigFromJson(json);

  @override
  final int rtcReleaseTimeoutMs;
  @override
  final int rtcReleasePollMs;
  @override
  final int waitingPollMs;
  @override
  final int wsPingMs;
  @override
  final int maxReconnects;
  @override
  final int reconnectMs;
  @override
  final int titleMax;
  @override
  final int nameMax;
  @override
  final int chatMax;
  @override
  final int attachmentMaxBytes;
  @override
  final int scheduleRangeDays;
  @override
  final int defaultDurationMin;
  @override
  final int minDurationMin;
  @override
  final int maxDurationMin;
  @override
  final int imPageSize;
  @override
  final int imTextMax;
  @override
  final int voiceLimitSec;
  @override
  final int reminderLeadMin;
  @override
  final int reminderPollMs;
  @override
  final int recordingChunkMs;
  @override
  final int recordingMaxPending;
  @override
  final int recordingFrameTimeoutMs;
  @override
  final int scheduleMaxDays;
  @override
  final int noticeDedupLimit;
  @override
  final int noticeHistoryLimit;
  @override
  final int avatarMaxBytes;
  final List<String> _avatarExtensions;
  @override
  List<String> get avatarExtensions {
    if (_avatarExtensions is EqualUnmodifiableListView)
      return _avatarExtensions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_avatarExtensions);
  }

  @override
  final int rtcSampleMs;
  @override
  final int rtcStaleMs;
  @override
  final double rtcSpeakingLevel;
  @override
  final int rtcSpeakingHoldMs;
  @override
  final int rtcFairRttMs;
  @override
  final int rtcPoorRttMs;
  @override
  final double rtcFairLossPercent;
  @override
  final double rtcPoorLossPercent;
  @override
  final int screenTrackTimeoutMs;

  /// Create a copy of LiveConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$LiveConfigCopyWith<_LiveConfig> get copyWith =>
      __$LiveConfigCopyWithImpl<_LiveConfig>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$LiveConfigToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _LiveConfig &&
            (identical(other.rtcReleaseTimeoutMs, rtcReleaseTimeoutMs) ||
                other.rtcReleaseTimeoutMs == rtcReleaseTimeoutMs) &&
            (identical(other.rtcReleasePollMs, rtcReleasePollMs) ||
                other.rtcReleasePollMs == rtcReleasePollMs) &&
            (identical(other.waitingPollMs, waitingPollMs) ||
                other.waitingPollMs == waitingPollMs) &&
            (identical(other.wsPingMs, wsPingMs) ||
                other.wsPingMs == wsPingMs) &&
            (identical(other.maxReconnects, maxReconnects) ||
                other.maxReconnects == maxReconnects) &&
            (identical(other.reconnectMs, reconnectMs) ||
                other.reconnectMs == reconnectMs) &&
            (identical(other.titleMax, titleMax) ||
                other.titleMax == titleMax) &&
            (identical(other.nameMax, nameMax) || other.nameMax == nameMax) &&
            (identical(other.chatMax, chatMax) || other.chatMax == chatMax) &&
            (identical(other.attachmentMaxBytes, attachmentMaxBytes) ||
                other.attachmentMaxBytes == attachmentMaxBytes) &&
            (identical(other.scheduleRangeDays, scheduleRangeDays) ||
                other.scheduleRangeDays == scheduleRangeDays) &&
            (identical(other.defaultDurationMin, defaultDurationMin) ||
                other.defaultDurationMin == defaultDurationMin) &&
            (identical(other.minDurationMin, minDurationMin) ||
                other.minDurationMin == minDurationMin) &&
            (identical(other.maxDurationMin, maxDurationMin) ||
                other.maxDurationMin == maxDurationMin) &&
            (identical(other.imPageSize, imPageSize) ||
                other.imPageSize == imPageSize) &&
            (identical(other.imTextMax, imTextMax) ||
                other.imTextMax == imTextMax) &&
            (identical(other.voiceLimitSec, voiceLimitSec) ||
                other.voiceLimitSec == voiceLimitSec) &&
            (identical(other.reminderLeadMin, reminderLeadMin) ||
                other.reminderLeadMin == reminderLeadMin) &&
            (identical(other.reminderPollMs, reminderPollMs) ||
                other.reminderPollMs == reminderPollMs) &&
            (identical(other.recordingChunkMs, recordingChunkMs) ||
                other.recordingChunkMs == recordingChunkMs) &&
            (identical(other.recordingMaxPending, recordingMaxPending) ||
                other.recordingMaxPending == recordingMaxPending) &&
            (identical(
                  other.recordingFrameTimeoutMs,
                  recordingFrameTimeoutMs,
                ) ||
                other.recordingFrameTimeoutMs == recordingFrameTimeoutMs) &&
            (identical(other.scheduleMaxDays, scheduleMaxDays) ||
                other.scheduleMaxDays == scheduleMaxDays) &&
            (identical(other.noticeDedupLimit, noticeDedupLimit) ||
                other.noticeDedupLimit == noticeDedupLimit) &&
            (identical(other.noticeHistoryLimit, noticeHistoryLimit) ||
                other.noticeHistoryLimit == noticeHistoryLimit) &&
            (identical(other.avatarMaxBytes, avatarMaxBytes) ||
                other.avatarMaxBytes == avatarMaxBytes) &&
            const DeepCollectionEquality().equals(
              other.avatarExtensions,
              _avatarExtensions,
            ) &&
            (identical(other.rtcSampleMs, rtcSampleMs) ||
                other.rtcSampleMs == rtcSampleMs) &&
            (identical(other.rtcStaleMs, rtcStaleMs) ||
                other.rtcStaleMs == rtcStaleMs) &&
            (identical(other.rtcSpeakingLevel, rtcSpeakingLevel) ||
                other.rtcSpeakingLevel == rtcSpeakingLevel) &&
            (identical(other.rtcSpeakingHoldMs, rtcSpeakingHoldMs) ||
                other.rtcSpeakingHoldMs == rtcSpeakingHoldMs) &&
            (identical(other.rtcFairRttMs, rtcFairRttMs) ||
                other.rtcFairRttMs == rtcFairRttMs) &&
            (identical(other.rtcPoorRttMs, rtcPoorRttMs) ||
                other.rtcPoorRttMs == rtcPoorRttMs) &&
            (identical(other.rtcFairLossPercent, rtcFairLossPercent) ||
                other.rtcFairLossPercent == rtcFairLossPercent) &&
            (identical(other.rtcPoorLossPercent, rtcPoorLossPercent) ||
                other.rtcPoorLossPercent == rtcPoorLossPercent) &&
            (identical(other.screenTrackTimeoutMs, screenTrackTimeoutMs) ||
                other.screenTrackTimeoutMs == screenTrackTimeoutMs));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hashAll([
      runtimeType,
      rtcReleaseTimeoutMs,
      rtcReleasePollMs,
      waitingPollMs,
      wsPingMs,
      maxReconnects,
      reconnectMs,
      titleMax,
      nameMax,
      chatMax,
      attachmentMaxBytes,
      scheduleRangeDays,
      defaultDurationMin,
      minDurationMin,
      maxDurationMin,
      imPageSize,
      imTextMax,
      voiceLimitSec,
      reminderLeadMin,
      reminderPollMs,
      recordingChunkMs,
      recordingMaxPending,
      recordingFrameTimeoutMs,
      scheduleMaxDays,
      noticeDedupLimit,
      noticeHistoryLimit,
      avatarMaxBytes,
      const DeepCollectionEquality().hash(_avatarExtensions),
      rtcSampleMs,
      rtcStaleMs,
      rtcSpeakingLevel,
      rtcSpeakingHoldMs,
      rtcFairRttMs,
      rtcPoorRttMs,
      rtcFairLossPercent,
      rtcPoorLossPercent,
      screenTrackTimeoutMs,
    ]);
  }

  @override
  String toString() {
    return 'LiveConfig(rtcReleaseTimeoutMs: $rtcReleaseTimeoutMs, rtcReleasePollMs: $rtcReleasePollMs, waitingPollMs: $waitingPollMs, wsPingMs: $wsPingMs, maxReconnects: $maxReconnects, reconnectMs: $reconnectMs, titleMax: $titleMax, nameMax: $nameMax, chatMax: $chatMax, attachmentMaxBytes: $attachmentMaxBytes, scheduleRangeDays: $scheduleRangeDays, defaultDurationMin: $defaultDurationMin, minDurationMin: $minDurationMin, maxDurationMin: $maxDurationMin, imPageSize: $imPageSize, imTextMax: $imTextMax, voiceLimitSec: $voiceLimitSec, reminderLeadMin: $reminderLeadMin, reminderPollMs: $reminderPollMs, recordingChunkMs: $recordingChunkMs, recordingMaxPending: $recordingMaxPending, recordingFrameTimeoutMs: $recordingFrameTimeoutMs, scheduleMaxDays: $scheduleMaxDays, noticeDedupLimit: $noticeDedupLimit, noticeHistoryLimit: $noticeHistoryLimit, avatarMaxBytes: $avatarMaxBytes, avatarExtensions: $avatarExtensions, rtcSampleMs: $rtcSampleMs, rtcStaleMs: $rtcStaleMs, rtcSpeakingLevel: $rtcSpeakingLevel, rtcSpeakingHoldMs: $rtcSpeakingHoldMs, rtcFairRttMs: $rtcFairRttMs, rtcPoorRttMs: $rtcPoorRttMs, rtcFairLossPercent: $rtcFairLossPercent, rtcPoorLossPercent: $rtcPoorLossPercent, screenTrackTimeoutMs: $screenTrackTimeoutMs)';
  }
}

/// @nodoc
abstract mixin class _$LiveConfigCopyWith<$Res>
    implements $LiveConfigCopyWith<$Res> {
  factory _$LiveConfigCopyWith(
    _LiveConfig value,
    $Res Function(_LiveConfig) _then,
  ) = __$LiveConfigCopyWithImpl;
  @override
  @useResult
  $Res call({
    int rtcReleaseTimeoutMs,
    int rtcReleasePollMs,
    int waitingPollMs,
    int wsPingMs,
    int maxReconnects,
    int reconnectMs,
    int titleMax,
    int nameMax,
    int chatMax,
    int attachmentMaxBytes,
    int scheduleRangeDays,
    int defaultDurationMin,
    int minDurationMin,
    int maxDurationMin,
    int imPageSize,
    int imTextMax,
    int voiceLimitSec,
    int reminderLeadMin,
    int reminderPollMs,
    int recordingChunkMs,
    int recordingMaxPending,
    int recordingFrameTimeoutMs,
    int scheduleMaxDays,
    int noticeDedupLimit,
    int noticeHistoryLimit,
    int avatarMaxBytes,
    List<String> avatarExtensions,
    int rtcSampleMs,
    int rtcStaleMs,
    double rtcSpeakingLevel,
    int rtcSpeakingHoldMs,
    int rtcFairRttMs,
    int rtcPoorRttMs,
    double rtcFairLossPercent,
    double rtcPoorLossPercent,
    int screenTrackTimeoutMs,
  });
}

/// @nodoc
class __$LiveConfigCopyWithImpl<$Res> implements _$LiveConfigCopyWith<$Res> {
  __$LiveConfigCopyWithImpl(this._self, this._then);

  final _LiveConfig _self;
  final $Res Function(_LiveConfig) _then;

  /// Create a copy of LiveConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? rtcReleaseTimeoutMs = null,
    Object? rtcReleasePollMs = null,
    Object? waitingPollMs = null,
    Object? wsPingMs = null,
    Object? maxReconnects = null,
    Object? reconnectMs = null,
    Object? titleMax = null,
    Object? nameMax = null,
    Object? chatMax = null,
    Object? attachmentMaxBytes = null,
    Object? scheduleRangeDays = null,
    Object? defaultDurationMin = null,
    Object? minDurationMin = null,
    Object? maxDurationMin = null,
    Object? imPageSize = null,
    Object? imTextMax = null,
    Object? voiceLimitSec = null,
    Object? reminderLeadMin = null,
    Object? reminderPollMs = null,
    Object? recordingChunkMs = null,
    Object? recordingMaxPending = null,
    Object? recordingFrameTimeoutMs = null,
    Object? scheduleMaxDays = null,
    Object? noticeDedupLimit = null,
    Object? noticeHistoryLimit = null,
    Object? avatarMaxBytes = null,
    Object? avatarExtensions = null,
    Object? rtcSampleMs = null,
    Object? rtcStaleMs = null,
    Object? rtcSpeakingLevel = null,
    Object? rtcSpeakingHoldMs = null,
    Object? rtcFairRttMs = null,
    Object? rtcPoorRttMs = null,
    Object? rtcFairLossPercent = null,
    Object? rtcPoorLossPercent = null,
    Object? screenTrackTimeoutMs = null,
  }) {
    return _then(
      _LiveConfig(
        rtcReleaseTimeoutMs: null == rtcReleaseTimeoutMs
            ? _self.rtcReleaseTimeoutMs
            : rtcReleaseTimeoutMs // ignore: cast_nullable_to_non_nullable
                  as int,
        rtcReleasePollMs: null == rtcReleasePollMs
            ? _self.rtcReleasePollMs
            : rtcReleasePollMs // ignore: cast_nullable_to_non_nullable
                  as int,
        waitingPollMs: null == waitingPollMs
            ? _self.waitingPollMs
            : waitingPollMs // ignore: cast_nullable_to_non_nullable
                  as int,
        wsPingMs: null == wsPingMs
            ? _self.wsPingMs
            : wsPingMs // ignore: cast_nullable_to_non_nullable
                  as int,
        maxReconnects: null == maxReconnects
            ? _self.maxReconnects
            : maxReconnects // ignore: cast_nullable_to_non_nullable
                  as int,
        reconnectMs: null == reconnectMs
            ? _self.reconnectMs
            : reconnectMs // ignore: cast_nullable_to_non_nullable
                  as int,
        titleMax: null == titleMax
            ? _self.titleMax
            : titleMax // ignore: cast_nullable_to_non_nullable
                  as int,
        nameMax: null == nameMax
            ? _self.nameMax
            : nameMax // ignore: cast_nullable_to_non_nullable
                  as int,
        chatMax: null == chatMax
            ? _self.chatMax
            : chatMax // ignore: cast_nullable_to_non_nullable
                  as int,
        attachmentMaxBytes: null == attachmentMaxBytes
            ? _self.attachmentMaxBytes
            : attachmentMaxBytes // ignore: cast_nullable_to_non_nullable
                  as int,
        scheduleRangeDays: null == scheduleRangeDays
            ? _self.scheduleRangeDays
            : scheduleRangeDays // ignore: cast_nullable_to_non_nullable
                  as int,
        defaultDurationMin: null == defaultDurationMin
            ? _self.defaultDurationMin
            : defaultDurationMin // ignore: cast_nullable_to_non_nullable
                  as int,
        minDurationMin: null == minDurationMin
            ? _self.minDurationMin
            : minDurationMin // ignore: cast_nullable_to_non_nullable
                  as int,
        maxDurationMin: null == maxDurationMin
            ? _self.maxDurationMin
            : maxDurationMin // ignore: cast_nullable_to_non_nullable
                  as int,
        imPageSize: null == imPageSize
            ? _self.imPageSize
            : imPageSize // ignore: cast_nullable_to_non_nullable
                  as int,
        imTextMax: null == imTextMax
            ? _self.imTextMax
            : imTextMax // ignore: cast_nullable_to_non_nullable
                  as int,
        voiceLimitSec: null == voiceLimitSec
            ? _self.voiceLimitSec
            : voiceLimitSec // ignore: cast_nullable_to_non_nullable
                  as int,
        reminderLeadMin: null == reminderLeadMin
            ? _self.reminderLeadMin
            : reminderLeadMin // ignore: cast_nullable_to_non_nullable
                  as int,
        reminderPollMs: null == reminderPollMs
            ? _self.reminderPollMs
            : reminderPollMs // ignore: cast_nullable_to_non_nullable
                  as int,
        recordingChunkMs: null == recordingChunkMs
            ? _self.recordingChunkMs
            : recordingChunkMs // ignore: cast_nullable_to_non_nullable
                  as int,
        recordingMaxPending: null == recordingMaxPending
            ? _self.recordingMaxPending
            : recordingMaxPending // ignore: cast_nullable_to_non_nullable
                  as int,
        recordingFrameTimeoutMs: null == recordingFrameTimeoutMs
            ? _self.recordingFrameTimeoutMs
            : recordingFrameTimeoutMs // ignore: cast_nullable_to_non_nullable
                  as int,
        scheduleMaxDays: null == scheduleMaxDays
            ? _self.scheduleMaxDays
            : scheduleMaxDays // ignore: cast_nullable_to_non_nullable
                  as int,
        noticeDedupLimit: null == noticeDedupLimit
            ? _self.noticeDedupLimit
            : noticeDedupLimit // ignore: cast_nullable_to_non_nullable
                  as int,
        noticeHistoryLimit: null == noticeHistoryLimit
            ? _self.noticeHistoryLimit
            : noticeHistoryLimit // ignore: cast_nullable_to_non_nullable
                  as int,
        avatarMaxBytes: null == avatarMaxBytes
            ? _self.avatarMaxBytes
            : avatarMaxBytes // ignore: cast_nullable_to_non_nullable
                  as int,
        avatarExtensions: null == avatarExtensions
            ? _self._avatarExtensions
            : avatarExtensions // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        rtcSampleMs: null == rtcSampleMs
            ? _self.rtcSampleMs
            : rtcSampleMs // ignore: cast_nullable_to_non_nullable
                  as int,
        rtcStaleMs: null == rtcStaleMs
            ? _self.rtcStaleMs
            : rtcStaleMs // ignore: cast_nullable_to_non_nullable
                  as int,
        rtcSpeakingLevel: null == rtcSpeakingLevel
            ? _self.rtcSpeakingLevel
            : rtcSpeakingLevel // ignore: cast_nullable_to_non_nullable
                  as double,
        rtcSpeakingHoldMs: null == rtcSpeakingHoldMs
            ? _self.rtcSpeakingHoldMs
            : rtcSpeakingHoldMs // ignore: cast_nullable_to_non_nullable
                  as int,
        rtcFairRttMs: null == rtcFairRttMs
            ? _self.rtcFairRttMs
            : rtcFairRttMs // ignore: cast_nullable_to_non_nullable
                  as int,
        rtcPoorRttMs: null == rtcPoorRttMs
            ? _self.rtcPoorRttMs
            : rtcPoorRttMs // ignore: cast_nullable_to_non_nullable
                  as int,
        rtcFairLossPercent: null == rtcFairLossPercent
            ? _self.rtcFairLossPercent
            : rtcFairLossPercent // ignore: cast_nullable_to_non_nullable
                  as double,
        rtcPoorLossPercent: null == rtcPoorLossPercent
            ? _self.rtcPoorLossPercent
            : rtcPoorLossPercent // ignore: cast_nullable_to_non_nullable
                  as double,
        screenTrackTimeoutMs: null == screenTrackTimeoutMs
            ? _self.screenTrackTimeoutMs
            : screenTrackTimeoutMs // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
mixin _$NetworkConfig {
  int get connectTimeoutMs;

  /// Receive/send timeout for ordinary JSON requests.
  int get requestTimeoutMs;

  /// Send/receive timeout for large transfers (audio upload/download, import).
  int get transferTimeoutMs;

  /// Retry policy for idempotent requests and live segment uploads.
  RetryConfig get retry;

  /// Retry policy for the final meeting audio upload.
  RetryConfig get audioUploadRetry;

  /// Create a copy of NetworkConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $NetworkConfigCopyWith<NetworkConfig> get copyWith =>
      _$NetworkConfigCopyWithImpl<NetworkConfig>(
        this as NetworkConfig,
        _$identity,
      );

  /// Serializes this NetworkConfig to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as NetworkConfig;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is NetworkConfig &&
            (identical(other.connectTimeoutMs, _this.connectTimeoutMs) ||
                other.connectTimeoutMs == _this.connectTimeoutMs) &&
            (identical(other.requestTimeoutMs, _this.requestTimeoutMs) ||
                other.requestTimeoutMs == _this.requestTimeoutMs) &&
            (identical(other.transferTimeoutMs, _this.transferTimeoutMs) ||
                other.transferTimeoutMs == _this.transferTimeoutMs) &&
            (identical(other.retry, _this.retry) ||
                other.retry == _this.retry) &&
            (identical(other.audioUploadRetry, _this.audioUploadRetry) ||
                other.audioUploadRetry == _this.audioUploadRetry));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as NetworkConfig;
    return Object.hash(
      runtimeType,
      _this.connectTimeoutMs,
      _this.requestTimeoutMs,
      _this.transferTimeoutMs,
      _this.retry,
      _this.audioUploadRetry,
    );
  }

  @override
  String toString() {
    final _this = this as NetworkConfig;
    return 'NetworkConfig(connectTimeoutMs: ${_this.connectTimeoutMs}, requestTimeoutMs: ${_this.requestTimeoutMs}, transferTimeoutMs: ${_this.transferTimeoutMs}, retry: ${_this.retry}, audioUploadRetry: ${_this.audioUploadRetry})';
  }
}

/// @nodoc
abstract mixin class $NetworkConfigCopyWith<$Res> {
  factory $NetworkConfigCopyWith(
    NetworkConfig value,
    $Res Function(NetworkConfig) _then,
  ) = _$NetworkConfigCopyWithImpl;
  @useResult
  $Res call({
    int connectTimeoutMs,
    int requestTimeoutMs,
    int transferTimeoutMs,
    RetryConfig retry,
    RetryConfig audioUploadRetry,
  });

  $RetryConfigCopyWith<$Res> get retry;
  $RetryConfigCopyWith<$Res> get audioUploadRetry;
}

/// @nodoc
class _$NetworkConfigCopyWithImpl<$Res>
    implements $NetworkConfigCopyWith<$Res> {
  _$NetworkConfigCopyWithImpl(this._self, this._then);

  final NetworkConfig _self;
  final $Res Function(NetworkConfig) _then;

  /// Create a copy of NetworkConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? connectTimeoutMs = null,
    Object? requestTimeoutMs = null,
    Object? transferTimeoutMs = null,
    Object? retry = null,
    Object? audioUploadRetry = null,
  }) {
    return _then(
      NetworkConfig(
        connectTimeoutMs: null == connectTimeoutMs
            ? _self.connectTimeoutMs
            : connectTimeoutMs // ignore: cast_nullable_to_non_nullable
                  as int,
        requestTimeoutMs: null == requestTimeoutMs
            ? _self.requestTimeoutMs
            : requestTimeoutMs // ignore: cast_nullable_to_non_nullable
                  as int,
        transferTimeoutMs: null == transferTimeoutMs
            ? _self.transferTimeoutMs
            : transferTimeoutMs // ignore: cast_nullable_to_non_nullable
                  as int,
        retry: null == retry
            ? _self.retry
            : retry // ignore: cast_nullable_to_non_nullable
                  as RetryConfig,
        audioUploadRetry: null == audioUploadRetry
            ? _self.audioUploadRetry
            : audioUploadRetry // ignore: cast_nullable_to_non_nullable
                  as RetryConfig,
      ),
    );
  }

  /// Create a copy of NetworkConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $RetryConfigCopyWith<$Res> get retry {
    return $RetryConfigCopyWith<$Res>(_self.retry, (value) {
      return _then(_self.copyWith(retry: value));
    });
  }

  /// Create a copy of NetworkConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $RetryConfigCopyWith<$Res> get audioUploadRetry {
    return $RetryConfigCopyWith<$Res>(_self.audioUploadRetry, (value) {
      return _then(_self.copyWith(audioUploadRetry: value));
    });
  }
}

/// Adds pattern-matching-related methods to [NetworkConfig].
extension NetworkConfigPatterns on NetworkConfig {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_NetworkConfig value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _NetworkConfig() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_NetworkConfig value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _NetworkConfig():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_NetworkConfig value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _NetworkConfig() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
      int connectTimeoutMs,
      int requestTimeoutMs,
      int transferTimeoutMs,
      RetryConfig retry,
      RetryConfig audioUploadRetry,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _NetworkConfig() when $default != null:
        return $default(
          _that.connectTimeoutMs,
          _that.requestTimeoutMs,
          _that.transferTimeoutMs,
          _that.retry,
          _that.audioUploadRetry,
        );
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
      int connectTimeoutMs,
      int requestTimeoutMs,
      int transferTimeoutMs,
      RetryConfig retry,
      RetryConfig audioUploadRetry,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _NetworkConfig():
        return $default(
          _that.connectTimeoutMs,
          _that.requestTimeoutMs,
          _that.transferTimeoutMs,
          _that.retry,
          _that.audioUploadRetry,
        );
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
      int connectTimeoutMs,
      int requestTimeoutMs,
      int transferTimeoutMs,
      RetryConfig retry,
      RetryConfig audioUploadRetry,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _NetworkConfig() when $default != null:
        return $default(
          _that.connectTimeoutMs,
          _that.requestTimeoutMs,
          _that.transferTimeoutMs,
          _that.retry,
          _that.audioUploadRetry,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _NetworkConfig extends NetworkConfig {
  const _NetworkConfig({
    required this.connectTimeoutMs,
    required this.requestTimeoutMs,
    required this.transferTimeoutMs,
    required this.retry,
    required this.audioUploadRetry,
  }) : super._();
  factory _NetworkConfig.fromJson(Map<String, dynamic> json) =>
      _$NetworkConfigFromJson(json);

  @override
  final int connectTimeoutMs;

  /// Receive/send timeout for ordinary JSON requests.
  @override
  final int requestTimeoutMs;

  /// Send/receive timeout for large transfers (audio upload/download, import).
  @override
  final int transferTimeoutMs;

  /// Retry policy for idempotent requests and live segment uploads.
  @override
  final RetryConfig retry;

  /// Retry policy for the final meeting audio upload.
  @override
  final RetryConfig audioUploadRetry;

  /// Create a copy of NetworkConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$NetworkConfigCopyWith<_NetworkConfig> get copyWith =>
      __$NetworkConfigCopyWithImpl<_NetworkConfig>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$NetworkConfigToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _NetworkConfig &&
            (identical(other.connectTimeoutMs, connectTimeoutMs) ||
                other.connectTimeoutMs == connectTimeoutMs) &&
            (identical(other.requestTimeoutMs, requestTimeoutMs) ||
                other.requestTimeoutMs == requestTimeoutMs) &&
            (identical(other.transferTimeoutMs, transferTimeoutMs) ||
                other.transferTimeoutMs == transferTimeoutMs) &&
            (identical(other.retry, retry) || other.retry == retry) &&
            (identical(other.audioUploadRetry, audioUploadRetry) ||
                other.audioUploadRetry == audioUploadRetry));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(
      runtimeType,
      connectTimeoutMs,
      requestTimeoutMs,
      transferTimeoutMs,
      retry,
      audioUploadRetry,
    );
  }

  @override
  String toString() {
    return 'NetworkConfig(connectTimeoutMs: $connectTimeoutMs, requestTimeoutMs: $requestTimeoutMs, transferTimeoutMs: $transferTimeoutMs, retry: $retry, audioUploadRetry: $audioUploadRetry)';
  }
}

/// @nodoc
abstract mixin class _$NetworkConfigCopyWith<$Res>
    implements $NetworkConfigCopyWith<$Res> {
  factory _$NetworkConfigCopyWith(
    _NetworkConfig value,
    $Res Function(_NetworkConfig) _then,
  ) = __$NetworkConfigCopyWithImpl;
  @override
  @useResult
  $Res call({
    int connectTimeoutMs,
    int requestTimeoutMs,
    int transferTimeoutMs,
    RetryConfig retry,
    RetryConfig audioUploadRetry,
  });

  @override
  $RetryConfigCopyWith<$Res> get retry;
  @override
  $RetryConfigCopyWith<$Res> get audioUploadRetry;
}

/// @nodoc
class __$NetworkConfigCopyWithImpl<$Res>
    implements _$NetworkConfigCopyWith<$Res> {
  __$NetworkConfigCopyWithImpl(this._self, this._then);

  final _NetworkConfig _self;
  final $Res Function(_NetworkConfig) _then;

  /// Create a copy of NetworkConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? connectTimeoutMs = null,
    Object? requestTimeoutMs = null,
    Object? transferTimeoutMs = null,
    Object? retry = null,
    Object? audioUploadRetry = null,
  }) {
    return _then(
      _NetworkConfig(
        connectTimeoutMs: null == connectTimeoutMs
            ? _self.connectTimeoutMs
            : connectTimeoutMs // ignore: cast_nullable_to_non_nullable
                  as int,
        requestTimeoutMs: null == requestTimeoutMs
            ? _self.requestTimeoutMs
            : requestTimeoutMs // ignore: cast_nullable_to_non_nullable
                  as int,
        transferTimeoutMs: null == transferTimeoutMs
            ? _self.transferTimeoutMs
            : transferTimeoutMs // ignore: cast_nullable_to_non_nullable
                  as int,
        retry: null == retry
            ? _self.retry
            : retry // ignore: cast_nullable_to_non_nullable
                  as RetryConfig,
        audioUploadRetry: null == audioUploadRetry
            ? _self.audioUploadRetry
            : audioUploadRetry // ignore: cast_nullable_to_non_nullable
                  as RetryConfig,
      ),
    );
  }

  /// Create a copy of NetworkConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $RetryConfigCopyWith<$Res> get retry {
    return $RetryConfigCopyWith<$Res>(_self.retry, (value) {
      return _then(_self.copyWith(retry: value));
    });
  }

  /// Create a copy of NetworkConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $RetryConfigCopyWith<$Res> get audioUploadRetry {
    return $RetryConfigCopyWith<$Res>(_self.audioUploadRetry, (value) {
      return _then(_self.copyWith(audioUploadRetry: value));
    });
  }
}

/// @nodoc
mixin _$RetryConfig {
  int get maxRetries;
  List<int> get backoffMs;

  /// Create a copy of RetryConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $RetryConfigCopyWith<RetryConfig> get copyWith =>
      _$RetryConfigCopyWithImpl<RetryConfig>(this as RetryConfig, _$identity);

  /// Serializes this RetryConfig to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as RetryConfig;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is RetryConfig &&
            (identical(other.maxRetries, _this.maxRetries) ||
                other.maxRetries == _this.maxRetries) &&
            const DeepCollectionEquality().equals(
              other.backoffMs,
              _this.backoffMs,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as RetryConfig;
    return Object.hash(
      runtimeType,
      _this.maxRetries,
      const DeepCollectionEquality().hash(_this.backoffMs),
    );
  }

  @override
  String toString() {
    final _this = this as RetryConfig;
    return 'RetryConfig(maxRetries: ${_this.maxRetries}, backoffMs: ${_this.backoffMs})';
  }
}

/// @nodoc
abstract mixin class $RetryConfigCopyWith<$Res> {
  factory $RetryConfigCopyWith(
    RetryConfig value,
    $Res Function(RetryConfig) _then,
  ) = _$RetryConfigCopyWithImpl;
  @useResult
  $Res call({int maxRetries, List<int> backoffMs});
}

/// @nodoc
class _$RetryConfigCopyWithImpl<$Res> implements $RetryConfigCopyWith<$Res> {
  _$RetryConfigCopyWithImpl(this._self, this._then);

  final RetryConfig _self;
  final $Res Function(RetryConfig) _then;

  /// Create a copy of RetryConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? maxRetries = null, Object? backoffMs = null}) {
    return _then(
      RetryConfig(
        maxRetries: null == maxRetries
            ? _self.maxRetries
            : maxRetries // ignore: cast_nullable_to_non_nullable
                  as int,
        backoffMs: null == backoffMs
            ? _self.backoffMs
            : backoffMs // ignore: cast_nullable_to_non_nullable
                  as List<int>,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [RetryConfig].
extension RetryConfigPatterns on RetryConfig {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_RetryConfig value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _RetryConfig() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_RetryConfig value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RetryConfig():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_RetryConfig value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RetryConfig() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(int maxRetries, List<int> backoffMs)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _RetryConfig() when $default != null:
        return $default(_that.maxRetries, _that.backoffMs);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(int maxRetries, List<int> backoffMs) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RetryConfig():
        return $default(_that.maxRetries, _that.backoffMs);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(int maxRetries, List<int> backoffMs)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RetryConfig() when $default != null:
        return $default(_that.maxRetries, _that.backoffMs);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _RetryConfig extends RetryConfig {
  const _RetryConfig({required this.maxRetries, required List<int> backoffMs})
    : _backoffMs = backoffMs,
      super._();
  factory _RetryConfig.fromJson(Map<String, dynamic> json) =>
      _$RetryConfigFromJson(json);

  @override
  final int maxRetries;
  final List<int> _backoffMs;
  @override
  List<int> get backoffMs {
    if (_backoffMs is EqualUnmodifiableListView) return _backoffMs;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_backoffMs);
  }

  /// Create a copy of RetryConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$RetryConfigCopyWith<_RetryConfig> get copyWith =>
      __$RetryConfigCopyWithImpl<_RetryConfig>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$RetryConfigToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _RetryConfig &&
            (identical(other.maxRetries, maxRetries) ||
                other.maxRetries == maxRetries) &&
            const DeepCollectionEquality().equals(other.backoffMs, _backoffMs));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(
      runtimeType,
      maxRetries,
      const DeepCollectionEquality().hash(_backoffMs),
    );
  }

  @override
  String toString() {
    return 'RetryConfig(maxRetries: $maxRetries, backoffMs: $backoffMs)';
  }
}

/// @nodoc
abstract mixin class _$RetryConfigCopyWith<$Res>
    implements $RetryConfigCopyWith<$Res> {
  factory _$RetryConfigCopyWith(
    _RetryConfig value,
    $Res Function(_RetryConfig) _then,
  ) = __$RetryConfigCopyWithImpl;
  @override
  @useResult
  $Res call({int maxRetries, List<int> backoffMs});
}

/// @nodoc
class __$RetryConfigCopyWithImpl<$Res> implements _$RetryConfigCopyWith<$Res> {
  __$RetryConfigCopyWithImpl(this._self, this._then);

  final _RetryConfig _self;
  final $Res Function(_RetryConfig) _then;

  /// Create a copy of RetryConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({Object? maxRetries = null, Object? backoffMs = null}) {
    return _then(
      _RetryConfig(
        maxRetries: null == maxRetries
            ? _self.maxRetries
            : maxRetries // ignore: cast_nullable_to_non_nullable
                  as int,
        backoffMs: null == backoffMs
            ? _self._backoffMs
            : backoffMs // ignore: cast_nullable_to_non_nullable
                  as List<int>,
      ),
    );
  }
}

/// @nodoc
mixin _$HeartbeatConfig {
  int get intervalSec;

  /// Interval while the app is not in the foreground (unless recording).
  int get backgroundIntervalSec;

  /// Create a copy of HeartbeatConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $HeartbeatConfigCopyWith<HeartbeatConfig> get copyWith =>
      _$HeartbeatConfigCopyWithImpl<HeartbeatConfig>(
        this as HeartbeatConfig,
        _$identity,
      );

  /// Serializes this HeartbeatConfig to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as HeartbeatConfig;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is HeartbeatConfig &&
            (identical(other.intervalSec, _this.intervalSec) ||
                other.intervalSec == _this.intervalSec) &&
            (identical(
                  other.backgroundIntervalSec,
                  _this.backgroundIntervalSec,
                ) ||
                other.backgroundIntervalSec == _this.backgroundIntervalSec));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as HeartbeatConfig;
    return Object.hash(
      runtimeType,
      _this.intervalSec,
      _this.backgroundIntervalSec,
    );
  }

  @override
  String toString() {
    final _this = this as HeartbeatConfig;
    return 'HeartbeatConfig(intervalSec: ${_this.intervalSec}, backgroundIntervalSec: ${_this.backgroundIntervalSec})';
  }
}

/// @nodoc
abstract mixin class $HeartbeatConfigCopyWith<$Res> {
  factory $HeartbeatConfigCopyWith(
    HeartbeatConfig value,
    $Res Function(HeartbeatConfig) _then,
  ) = _$HeartbeatConfigCopyWithImpl;
  @useResult
  $Res call({int intervalSec, int backgroundIntervalSec});
}

/// @nodoc
class _$HeartbeatConfigCopyWithImpl<$Res>
    implements $HeartbeatConfigCopyWith<$Res> {
  _$HeartbeatConfigCopyWithImpl(this._self, this._then);

  final HeartbeatConfig _self;
  final $Res Function(HeartbeatConfig) _then;

  /// Create a copy of HeartbeatConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? intervalSec = null,
    Object? backgroundIntervalSec = null,
  }) {
    return _then(
      HeartbeatConfig(
        intervalSec: null == intervalSec
            ? _self.intervalSec
            : intervalSec // ignore: cast_nullable_to_non_nullable
                  as int,
        backgroundIntervalSec: null == backgroundIntervalSec
            ? _self.backgroundIntervalSec
            : backgroundIntervalSec // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [HeartbeatConfig].
extension HeartbeatConfigPatterns on HeartbeatConfig {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_HeartbeatConfig value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _HeartbeatConfig() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_HeartbeatConfig value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HeartbeatConfig():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_HeartbeatConfig value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HeartbeatConfig() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(int intervalSec, int backgroundIntervalSec)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _HeartbeatConfig() when $default != null:
        return $default(_that.intervalSec, _that.backgroundIntervalSec);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(int intervalSec, int backgroundIntervalSec) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HeartbeatConfig():
        return $default(_that.intervalSec, _that.backgroundIntervalSec);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(int intervalSec, int backgroundIntervalSec)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HeartbeatConfig() when $default != null:
        return $default(_that.intervalSec, _that.backgroundIntervalSec);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _HeartbeatConfig extends HeartbeatConfig {
  const _HeartbeatConfig({
    required this.intervalSec,
    required this.backgroundIntervalSec,
  }) : super._();
  factory _HeartbeatConfig.fromJson(Map<String, dynamic> json) =>
      _$HeartbeatConfigFromJson(json);

  @override
  final int intervalSec;

  /// Interval while the app is not in the foreground (unless recording).
  @override
  final int backgroundIntervalSec;

  /// Create a copy of HeartbeatConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$HeartbeatConfigCopyWith<_HeartbeatConfig> get copyWith =>
      __$HeartbeatConfigCopyWithImpl<_HeartbeatConfig>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$HeartbeatConfigToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _HeartbeatConfig &&
            (identical(other.intervalSec, intervalSec) ||
                other.intervalSec == intervalSec) &&
            (identical(other.backgroundIntervalSec, backgroundIntervalSec) ||
                other.backgroundIntervalSec == backgroundIntervalSec));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(runtimeType, intervalSec, backgroundIntervalSec);
  }

  @override
  String toString() {
    return 'HeartbeatConfig(intervalSec: $intervalSec, backgroundIntervalSec: $backgroundIntervalSec)';
  }
}

/// @nodoc
abstract mixin class _$HeartbeatConfigCopyWith<$Res>
    implements $HeartbeatConfigCopyWith<$Res> {
  factory _$HeartbeatConfigCopyWith(
    _HeartbeatConfig value,
    $Res Function(_HeartbeatConfig) _then,
  ) = __$HeartbeatConfigCopyWithImpl;
  @override
  @useResult
  $Res call({int intervalSec, int backgroundIntervalSec});
}

/// @nodoc
class __$HeartbeatConfigCopyWithImpl<$Res>
    implements _$HeartbeatConfigCopyWith<$Res> {
  __$HeartbeatConfigCopyWithImpl(this._self, this._then);

  final _HeartbeatConfig _self;
  final $Res Function(_HeartbeatConfig) _then;

  /// Create a copy of HeartbeatConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? intervalSec = null,
    Object? backgroundIntervalSec = null,
  }) {
    return _then(
      _HeartbeatConfig(
        intervalSec: null == intervalSec
            ? _self.intervalSec
            : intervalSec // ignore: cast_nullable_to_non_nullable
                  as int,
        backgroundIntervalSec: null == backgroundIntervalSec
            ? _self.backgroundIntervalSec
            : backgroundIntervalSec // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
mixin _$PollingConfig {
  int get summaryIntervalSec;
  int get summaryMaxPolls;
  int get jobIntervalSec;
  int get jobMaxConsecutiveErrors;

  /// Create a copy of PollingConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PollingConfigCopyWith<PollingConfig> get copyWith =>
      _$PollingConfigCopyWithImpl<PollingConfig>(
        this as PollingConfig,
        _$identity,
      );

  /// Serializes this PollingConfig to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as PollingConfig;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PollingConfig &&
            (identical(other.summaryIntervalSec, _this.summaryIntervalSec) ||
                other.summaryIntervalSec == _this.summaryIntervalSec) &&
            (identical(other.summaryMaxPolls, _this.summaryMaxPolls) ||
                other.summaryMaxPolls == _this.summaryMaxPolls) &&
            (identical(other.jobIntervalSec, _this.jobIntervalSec) ||
                other.jobIntervalSec == _this.jobIntervalSec) &&
            (identical(
                  other.jobMaxConsecutiveErrors,
                  _this.jobMaxConsecutiveErrors,
                ) ||
                other.jobMaxConsecutiveErrors ==
                    _this.jobMaxConsecutiveErrors));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as PollingConfig;
    return Object.hash(
      runtimeType,
      _this.summaryIntervalSec,
      _this.summaryMaxPolls,
      _this.jobIntervalSec,
      _this.jobMaxConsecutiveErrors,
    );
  }

  @override
  String toString() {
    final _this = this as PollingConfig;
    return 'PollingConfig(summaryIntervalSec: ${_this.summaryIntervalSec}, summaryMaxPolls: ${_this.summaryMaxPolls}, jobIntervalSec: ${_this.jobIntervalSec}, jobMaxConsecutiveErrors: ${_this.jobMaxConsecutiveErrors})';
  }
}

/// @nodoc
abstract mixin class $PollingConfigCopyWith<$Res> {
  factory $PollingConfigCopyWith(
    PollingConfig value,
    $Res Function(PollingConfig) _then,
  ) = _$PollingConfigCopyWithImpl;
  @useResult
  $Res call({
    int summaryIntervalSec,
    int summaryMaxPolls,
    int jobIntervalSec,
    int jobMaxConsecutiveErrors,
  });
}

/// @nodoc
class _$PollingConfigCopyWithImpl<$Res>
    implements $PollingConfigCopyWith<$Res> {
  _$PollingConfigCopyWithImpl(this._self, this._then);

  final PollingConfig _self;
  final $Res Function(PollingConfig) _then;

  /// Create a copy of PollingConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? summaryIntervalSec = null,
    Object? summaryMaxPolls = null,
    Object? jobIntervalSec = null,
    Object? jobMaxConsecutiveErrors = null,
  }) {
    return _then(
      PollingConfig(
        summaryIntervalSec: null == summaryIntervalSec
            ? _self.summaryIntervalSec
            : summaryIntervalSec // ignore: cast_nullable_to_non_nullable
                  as int,
        summaryMaxPolls: null == summaryMaxPolls
            ? _self.summaryMaxPolls
            : summaryMaxPolls // ignore: cast_nullable_to_non_nullable
                  as int,
        jobIntervalSec: null == jobIntervalSec
            ? _self.jobIntervalSec
            : jobIntervalSec // ignore: cast_nullable_to_non_nullable
                  as int,
        jobMaxConsecutiveErrors: null == jobMaxConsecutiveErrors
            ? _self.jobMaxConsecutiveErrors
            : jobMaxConsecutiveErrors // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [PollingConfig].
extension PollingConfigPatterns on PollingConfig {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_PollingConfig value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PollingConfig() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_PollingConfig value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PollingConfig():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_PollingConfig value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PollingConfig() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
      int summaryIntervalSec,
      int summaryMaxPolls,
      int jobIntervalSec,
      int jobMaxConsecutiveErrors,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PollingConfig() when $default != null:
        return $default(
          _that.summaryIntervalSec,
          _that.summaryMaxPolls,
          _that.jobIntervalSec,
          _that.jobMaxConsecutiveErrors,
        );
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
      int summaryIntervalSec,
      int summaryMaxPolls,
      int jobIntervalSec,
      int jobMaxConsecutiveErrors,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PollingConfig():
        return $default(
          _that.summaryIntervalSec,
          _that.summaryMaxPolls,
          _that.jobIntervalSec,
          _that.jobMaxConsecutiveErrors,
        );
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
      int summaryIntervalSec,
      int summaryMaxPolls,
      int jobIntervalSec,
      int jobMaxConsecutiveErrors,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PollingConfig() when $default != null:
        return $default(
          _that.summaryIntervalSec,
          _that.summaryMaxPolls,
          _that.jobIntervalSec,
          _that.jobMaxConsecutiveErrors,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _PollingConfig extends PollingConfig {
  const _PollingConfig({
    required this.summaryIntervalSec,
    required this.summaryMaxPolls,
    required this.jobIntervalSec,
    required this.jobMaxConsecutiveErrors,
  }) : super._();
  factory _PollingConfig.fromJson(Map<String, dynamic> json) =>
      _$PollingConfigFromJson(json);

  @override
  final int summaryIntervalSec;
  @override
  final int summaryMaxPolls;
  @override
  final int jobIntervalSec;
  @override
  final int jobMaxConsecutiveErrors;

  /// Create a copy of PollingConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PollingConfigCopyWith<_PollingConfig> get copyWith =>
      __$PollingConfigCopyWithImpl<_PollingConfig>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$PollingConfigToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PollingConfig &&
            (identical(other.summaryIntervalSec, summaryIntervalSec) ||
                other.summaryIntervalSec == summaryIntervalSec) &&
            (identical(other.summaryMaxPolls, summaryMaxPolls) ||
                other.summaryMaxPolls == summaryMaxPolls) &&
            (identical(other.jobIntervalSec, jobIntervalSec) ||
                other.jobIntervalSec == jobIntervalSec) &&
            (identical(
                  other.jobMaxConsecutiveErrors,
                  jobMaxConsecutiveErrors,
                ) ||
                other.jobMaxConsecutiveErrors == jobMaxConsecutiveErrors));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(
      runtimeType,
      summaryIntervalSec,
      summaryMaxPolls,
      jobIntervalSec,
      jobMaxConsecutiveErrors,
    );
  }

  @override
  String toString() {
    return 'PollingConfig(summaryIntervalSec: $summaryIntervalSec, summaryMaxPolls: $summaryMaxPolls, jobIntervalSec: $jobIntervalSec, jobMaxConsecutiveErrors: $jobMaxConsecutiveErrors)';
  }
}

/// @nodoc
abstract mixin class _$PollingConfigCopyWith<$Res>
    implements $PollingConfigCopyWith<$Res> {
  factory _$PollingConfigCopyWith(
    _PollingConfig value,
    $Res Function(_PollingConfig) _then,
  ) = __$PollingConfigCopyWithImpl;
  @override
  @useResult
  $Res call({
    int summaryIntervalSec,
    int summaryMaxPolls,
    int jobIntervalSec,
    int jobMaxConsecutiveErrors,
  });
}

/// @nodoc
class __$PollingConfigCopyWithImpl<$Res>
    implements _$PollingConfigCopyWith<$Res> {
  __$PollingConfigCopyWithImpl(this._self, this._then);

  final _PollingConfig _self;
  final $Res Function(_PollingConfig) _then;

  /// Create a copy of PollingConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? summaryIntervalSec = null,
    Object? summaryMaxPolls = null,
    Object? jobIntervalSec = null,
    Object? jobMaxConsecutiveErrors = null,
  }) {
    return _then(
      _PollingConfig(
        summaryIntervalSec: null == summaryIntervalSec
            ? _self.summaryIntervalSec
            : summaryIntervalSec // ignore: cast_nullable_to_non_nullable
                  as int,
        summaryMaxPolls: null == summaryMaxPolls
            ? _self.summaryMaxPolls
            : summaryMaxPolls // ignore: cast_nullable_to_non_nullable
                  as int,
        jobIntervalSec: null == jobIntervalSec
            ? _self.jobIntervalSec
            : jobIntervalSec // ignore: cast_nullable_to_non_nullable
                  as int,
        jobMaxConsecutiveErrors: null == jobMaxConsecutiveErrors
            ? _self.jobMaxConsecutiveErrors
            : jobMaxConsecutiveErrors // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
mixin _$PaginationConfig {
  int get transcriptPageSize;
  int get meetingSearchDebounceMs;

  /// Create a copy of PaginationConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PaginationConfigCopyWith<PaginationConfig> get copyWith =>
      _$PaginationConfigCopyWithImpl<PaginationConfig>(
        this as PaginationConfig,
        _$identity,
      );

  /// Serializes this PaginationConfig to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as PaginationConfig;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PaginationConfig &&
            (identical(other.transcriptPageSize, _this.transcriptPageSize) ||
                other.transcriptPageSize == _this.transcriptPageSize) &&
            (identical(
                  other.meetingSearchDebounceMs,
                  _this.meetingSearchDebounceMs,
                ) ||
                other.meetingSearchDebounceMs ==
                    _this.meetingSearchDebounceMs));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as PaginationConfig;
    return Object.hash(
      runtimeType,
      _this.transcriptPageSize,
      _this.meetingSearchDebounceMs,
    );
  }

  @override
  String toString() {
    final _this = this as PaginationConfig;
    return 'PaginationConfig(transcriptPageSize: ${_this.transcriptPageSize}, meetingSearchDebounceMs: ${_this.meetingSearchDebounceMs})';
  }
}

/// @nodoc
abstract mixin class $PaginationConfigCopyWith<$Res> {
  factory $PaginationConfigCopyWith(
    PaginationConfig value,
    $Res Function(PaginationConfig) _then,
  ) = _$PaginationConfigCopyWithImpl;
  @useResult
  $Res call({int transcriptPageSize, int meetingSearchDebounceMs});
}

/// @nodoc
class _$PaginationConfigCopyWithImpl<$Res>
    implements $PaginationConfigCopyWith<$Res> {
  _$PaginationConfigCopyWithImpl(this._self, this._then);

  final PaginationConfig _self;
  final $Res Function(PaginationConfig) _then;

  /// Create a copy of PaginationConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? transcriptPageSize = null,
    Object? meetingSearchDebounceMs = null,
  }) {
    return _then(
      PaginationConfig(
        transcriptPageSize: null == transcriptPageSize
            ? _self.transcriptPageSize
            : transcriptPageSize // ignore: cast_nullable_to_non_nullable
                  as int,
        meetingSearchDebounceMs: null == meetingSearchDebounceMs
            ? _self.meetingSearchDebounceMs
            : meetingSearchDebounceMs // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [PaginationConfig].
extension PaginationConfigPatterns on PaginationConfig {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_PaginationConfig value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PaginationConfig() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_PaginationConfig value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PaginationConfig():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_PaginationConfig value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PaginationConfig() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(int transcriptPageSize, int meetingSearchDebounceMs)?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PaginationConfig() when $default != null:
        return $default(
          _that.transcriptPageSize,
          _that.meetingSearchDebounceMs,
        );
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(int transcriptPageSize, int meetingSearchDebounceMs)
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PaginationConfig():
        return $default(
          _that.transcriptPageSize,
          _that.meetingSearchDebounceMs,
        );
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(int transcriptPageSize, int meetingSearchDebounceMs)?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PaginationConfig() when $default != null:
        return $default(
          _that.transcriptPageSize,
          _that.meetingSearchDebounceMs,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _PaginationConfig extends PaginationConfig {
  const _PaginationConfig({
    required this.transcriptPageSize,
    required this.meetingSearchDebounceMs,
  }) : super._();
  factory _PaginationConfig.fromJson(Map<String, dynamic> json) =>
      _$PaginationConfigFromJson(json);

  @override
  final int transcriptPageSize;
  @override
  final int meetingSearchDebounceMs;

  /// Create a copy of PaginationConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PaginationConfigCopyWith<_PaginationConfig> get copyWith =>
      __$PaginationConfigCopyWithImpl<_PaginationConfig>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$PaginationConfigToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PaginationConfig &&
            (identical(other.transcriptPageSize, transcriptPageSize) ||
                other.transcriptPageSize == transcriptPageSize) &&
            (identical(
                  other.meetingSearchDebounceMs,
                  meetingSearchDebounceMs,
                ) ||
                other.meetingSearchDebounceMs == meetingSearchDebounceMs));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(
      runtimeType,
      transcriptPageSize,
      meetingSearchDebounceMs,
    );
  }

  @override
  String toString() {
    return 'PaginationConfig(transcriptPageSize: $transcriptPageSize, meetingSearchDebounceMs: $meetingSearchDebounceMs)';
  }
}

/// @nodoc
abstract mixin class _$PaginationConfigCopyWith<$Res>
    implements $PaginationConfigCopyWith<$Res> {
  factory _$PaginationConfigCopyWith(
    _PaginationConfig value,
    $Res Function(_PaginationConfig) _then,
  ) = __$PaginationConfigCopyWithImpl;
  @override
  @useResult
  $Res call({int transcriptPageSize, int meetingSearchDebounceMs});
}

/// @nodoc
class __$PaginationConfigCopyWithImpl<$Res>
    implements _$PaginationConfigCopyWith<$Res> {
  __$PaginationConfigCopyWithImpl(this._self, this._then);

  final _PaginationConfig _self;
  final $Res Function(_PaginationConfig) _then;

  /// Create a copy of PaginationConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? transcriptPageSize = null,
    Object? meetingSearchDebounceMs = null,
  }) {
    return _then(
      _PaginationConfig(
        transcriptPageSize: null == transcriptPageSize
            ? _self.transcriptPageSize
            : transcriptPageSize // ignore: cast_nullable_to_non_nullable
                  as int,
        meetingSearchDebounceMs: null == meetingSearchDebounceMs
            ? _self.meetingSearchDebounceMs
            : meetingSearchDebounceMs // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
mixin _$AuthConfigDefaults {
  /// Regex a normalized phone number must match.
  String get phonePattern;
  int get nameMaxLength;

  /// Country-code prefixes stripped during phone normalization (e.g. `+86`, `0086`, `86`).
  List<String> get phonePrefixes;

  /// SMS code length used until `GET /auth/config` answered (server value wins).
  int get defaultCodeLength;

  /// Resend countdown used when neither the send response nor `/auth/config` provide one.
  int get defaultResendIntervalSec;

  /// Password length limits used until `GET /auth/config` answered (server values win).
  int get defaultPasswordMinLength;
  int get defaultPasswordMaxLength;

  /// Digits left visible at the start / end when a phone number is masked (`138****8000`).
  int get phoneMaskPrefixLength;
  int get phoneMaskSuffixLength;

  /// Create a copy of AuthConfigDefaults
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $AuthConfigDefaultsCopyWith<AuthConfigDefaults> get copyWith =>
      _$AuthConfigDefaultsCopyWithImpl<AuthConfigDefaults>(
        this as AuthConfigDefaults,
        _$identity,
      );

  /// Serializes this AuthConfigDefaults to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as AuthConfigDefaults;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AuthConfigDefaults &&
            (identical(other.phonePattern, _this.phonePattern) ||
                other.phonePattern == _this.phonePattern) &&
            (identical(other.nameMaxLength, _this.nameMaxLength) ||
                other.nameMaxLength == _this.nameMaxLength) &&
            const DeepCollectionEquality().equals(
              other.phonePrefixes,
              _this.phonePrefixes,
            ) &&
            (identical(other.defaultCodeLength, _this.defaultCodeLength) ||
                other.defaultCodeLength == _this.defaultCodeLength) &&
            (identical(
                  other.defaultResendIntervalSec,
                  _this.defaultResendIntervalSec,
                ) ||
                other.defaultResendIntervalSec ==
                    _this.defaultResendIntervalSec) &&
            (identical(
                  other.defaultPasswordMinLength,
                  _this.defaultPasswordMinLength,
                ) ||
                other.defaultPasswordMinLength ==
                    _this.defaultPasswordMinLength) &&
            (identical(
                  other.defaultPasswordMaxLength,
                  _this.defaultPasswordMaxLength,
                ) ||
                other.defaultPasswordMaxLength ==
                    _this.defaultPasswordMaxLength) &&
            (identical(
                  other.phoneMaskPrefixLength,
                  _this.phoneMaskPrefixLength,
                ) ||
                other.phoneMaskPrefixLength == _this.phoneMaskPrefixLength) &&
            (identical(
                  other.phoneMaskSuffixLength,
                  _this.phoneMaskSuffixLength,
                ) ||
                other.phoneMaskSuffixLength == _this.phoneMaskSuffixLength));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as AuthConfigDefaults;
    return Object.hash(
      runtimeType,
      _this.phonePattern,
      _this.nameMaxLength,
      const DeepCollectionEquality().hash(_this.phonePrefixes),
      _this.defaultCodeLength,
      _this.defaultResendIntervalSec,
      _this.defaultPasswordMinLength,
      _this.defaultPasswordMaxLength,
      _this.phoneMaskPrefixLength,
      _this.phoneMaskSuffixLength,
    );
  }

  @override
  String toString() {
    final _this = this as AuthConfigDefaults;
    return 'AuthConfigDefaults(phonePattern: ${_this.phonePattern}, nameMaxLength: ${_this.nameMaxLength}, phonePrefixes: ${_this.phonePrefixes}, defaultCodeLength: ${_this.defaultCodeLength}, defaultResendIntervalSec: ${_this.defaultResendIntervalSec}, defaultPasswordMinLength: ${_this.defaultPasswordMinLength}, defaultPasswordMaxLength: ${_this.defaultPasswordMaxLength}, phoneMaskPrefixLength: ${_this.phoneMaskPrefixLength}, phoneMaskSuffixLength: ${_this.phoneMaskSuffixLength})';
  }
}

/// @nodoc
abstract mixin class $AuthConfigDefaultsCopyWith<$Res> {
  factory $AuthConfigDefaultsCopyWith(
    AuthConfigDefaults value,
    $Res Function(AuthConfigDefaults) _then,
  ) = _$AuthConfigDefaultsCopyWithImpl;
  @useResult
  $Res call({
    String phonePattern,
    int nameMaxLength,
    List<String> phonePrefixes,
    int defaultCodeLength,
    int defaultResendIntervalSec,
    int defaultPasswordMinLength,
    int defaultPasswordMaxLength,
    int phoneMaskPrefixLength,
    int phoneMaskSuffixLength,
  });
}

/// @nodoc
class _$AuthConfigDefaultsCopyWithImpl<$Res>
    implements $AuthConfigDefaultsCopyWith<$Res> {
  _$AuthConfigDefaultsCopyWithImpl(this._self, this._then);

  final AuthConfigDefaults _self;
  final $Res Function(AuthConfigDefaults) _then;

  /// Create a copy of AuthConfigDefaults
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? phonePattern = null,
    Object? nameMaxLength = null,
    Object? phonePrefixes = null,
    Object? defaultCodeLength = null,
    Object? defaultResendIntervalSec = null,
    Object? defaultPasswordMinLength = null,
    Object? defaultPasswordMaxLength = null,
    Object? phoneMaskPrefixLength = null,
    Object? phoneMaskSuffixLength = null,
  }) {
    return _then(
      AuthConfigDefaults(
        phonePattern: null == phonePattern
            ? _self.phonePattern
            : phonePattern // ignore: cast_nullable_to_non_nullable
                  as String,
        nameMaxLength: null == nameMaxLength
            ? _self.nameMaxLength
            : nameMaxLength // ignore: cast_nullable_to_non_nullable
                  as int,
        phonePrefixes: null == phonePrefixes
            ? _self.phonePrefixes
            : phonePrefixes // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        defaultCodeLength: null == defaultCodeLength
            ? _self.defaultCodeLength
            : defaultCodeLength // ignore: cast_nullable_to_non_nullable
                  as int,
        defaultResendIntervalSec: null == defaultResendIntervalSec
            ? _self.defaultResendIntervalSec
            : defaultResendIntervalSec // ignore: cast_nullable_to_non_nullable
                  as int,
        defaultPasswordMinLength: null == defaultPasswordMinLength
            ? _self.defaultPasswordMinLength
            : defaultPasswordMinLength // ignore: cast_nullable_to_non_nullable
                  as int,
        defaultPasswordMaxLength: null == defaultPasswordMaxLength
            ? _self.defaultPasswordMaxLength
            : defaultPasswordMaxLength // ignore: cast_nullable_to_non_nullable
                  as int,
        phoneMaskPrefixLength: null == phoneMaskPrefixLength
            ? _self.phoneMaskPrefixLength
            : phoneMaskPrefixLength // ignore: cast_nullable_to_non_nullable
                  as int,
        phoneMaskSuffixLength: null == phoneMaskSuffixLength
            ? _self.phoneMaskSuffixLength
            : phoneMaskSuffixLength // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [AuthConfigDefaults].
extension AuthConfigDefaultsPatterns on AuthConfigDefaults {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_AuthConfigDefaults value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AuthConfigDefaults() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_AuthConfigDefaults value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AuthConfigDefaults():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_AuthConfigDefaults value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AuthConfigDefaults() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
      String phonePattern,
      int nameMaxLength,
      List<String> phonePrefixes,
      int defaultCodeLength,
      int defaultResendIntervalSec,
      int defaultPasswordMinLength,
      int defaultPasswordMaxLength,
      int phoneMaskPrefixLength,
      int phoneMaskSuffixLength,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AuthConfigDefaults() when $default != null:
        return $default(
          _that.phonePattern,
          _that.nameMaxLength,
          _that.phonePrefixes,
          _that.defaultCodeLength,
          _that.defaultResendIntervalSec,
          _that.defaultPasswordMinLength,
          _that.defaultPasswordMaxLength,
          _that.phoneMaskPrefixLength,
          _that.phoneMaskSuffixLength,
        );
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
      String phonePattern,
      int nameMaxLength,
      List<String> phonePrefixes,
      int defaultCodeLength,
      int defaultResendIntervalSec,
      int defaultPasswordMinLength,
      int defaultPasswordMaxLength,
      int phoneMaskPrefixLength,
      int phoneMaskSuffixLength,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AuthConfigDefaults():
        return $default(
          _that.phonePattern,
          _that.nameMaxLength,
          _that.phonePrefixes,
          _that.defaultCodeLength,
          _that.defaultResendIntervalSec,
          _that.defaultPasswordMinLength,
          _that.defaultPasswordMaxLength,
          _that.phoneMaskPrefixLength,
          _that.phoneMaskSuffixLength,
        );
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
      String phonePattern,
      int nameMaxLength,
      List<String> phonePrefixes,
      int defaultCodeLength,
      int defaultResendIntervalSec,
      int defaultPasswordMinLength,
      int defaultPasswordMaxLength,
      int phoneMaskPrefixLength,
      int phoneMaskSuffixLength,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AuthConfigDefaults() when $default != null:
        return $default(
          _that.phonePattern,
          _that.nameMaxLength,
          _that.phonePrefixes,
          _that.defaultCodeLength,
          _that.defaultResendIntervalSec,
          _that.defaultPasswordMinLength,
          _that.defaultPasswordMaxLength,
          _that.phoneMaskPrefixLength,
          _that.phoneMaskSuffixLength,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _AuthConfigDefaults implements AuthConfigDefaults {
  const _AuthConfigDefaults({
    required this.phonePattern,
    required this.nameMaxLength,
    required List<String> phonePrefixes,
    required this.defaultCodeLength,
    required this.defaultResendIntervalSec,
    required this.defaultPasswordMinLength,
    required this.defaultPasswordMaxLength,
    required this.phoneMaskPrefixLength,
    required this.phoneMaskSuffixLength,
  }) : _phonePrefixes = phonePrefixes;
  factory _AuthConfigDefaults.fromJson(Map<String, dynamic> json) =>
      _$AuthConfigDefaultsFromJson(json);

  /// Regex a normalized phone number must match.
  @override
  final String phonePattern;
  @override
  final int nameMaxLength;

  /// Country-code prefixes stripped during phone normalization (e.g. `+86`, `0086`, `86`).
  final List<String> _phonePrefixes;

  /// Country-code prefixes stripped during phone normalization (e.g. `+86`, `0086`, `86`).
  @override
  List<String> get phonePrefixes {
    if (_phonePrefixes is EqualUnmodifiableListView) return _phonePrefixes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_phonePrefixes);
  }

  /// SMS code length used until `GET /auth/config` answered (server value wins).
  @override
  final int defaultCodeLength;

  /// Resend countdown used when neither the send response nor `/auth/config` provide one.
  @override
  final int defaultResendIntervalSec;

  /// Password length limits used until `GET /auth/config` answered (server values win).
  @override
  final int defaultPasswordMinLength;
  @override
  final int defaultPasswordMaxLength;

  /// Digits left visible at the start / end when a phone number is masked (`138****8000`).
  @override
  final int phoneMaskPrefixLength;
  @override
  final int phoneMaskSuffixLength;

  /// Create a copy of AuthConfigDefaults
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$AuthConfigDefaultsCopyWith<_AuthConfigDefaults> get copyWith =>
      __$AuthConfigDefaultsCopyWithImpl<_AuthConfigDefaults>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$AuthConfigDefaultsToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _AuthConfigDefaults &&
            (identical(other.phonePattern, phonePattern) ||
                other.phonePattern == phonePattern) &&
            (identical(other.nameMaxLength, nameMaxLength) ||
                other.nameMaxLength == nameMaxLength) &&
            const DeepCollectionEquality().equals(
              other.phonePrefixes,
              _phonePrefixes,
            ) &&
            (identical(other.defaultCodeLength, defaultCodeLength) ||
                other.defaultCodeLength == defaultCodeLength) &&
            (identical(
                  other.defaultResendIntervalSec,
                  defaultResendIntervalSec,
                ) ||
                other.defaultResendIntervalSec == defaultResendIntervalSec) &&
            (identical(
                  other.defaultPasswordMinLength,
                  defaultPasswordMinLength,
                ) ||
                other.defaultPasswordMinLength == defaultPasswordMinLength) &&
            (identical(
                  other.defaultPasswordMaxLength,
                  defaultPasswordMaxLength,
                ) ||
                other.defaultPasswordMaxLength == defaultPasswordMaxLength) &&
            (identical(other.phoneMaskPrefixLength, phoneMaskPrefixLength) ||
                other.phoneMaskPrefixLength == phoneMaskPrefixLength) &&
            (identical(other.phoneMaskSuffixLength, phoneMaskSuffixLength) ||
                other.phoneMaskSuffixLength == phoneMaskSuffixLength));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(
      runtimeType,
      phonePattern,
      nameMaxLength,
      const DeepCollectionEquality().hash(_phonePrefixes),
      defaultCodeLength,
      defaultResendIntervalSec,
      defaultPasswordMinLength,
      defaultPasswordMaxLength,
      phoneMaskPrefixLength,
      phoneMaskSuffixLength,
    );
  }

  @override
  String toString() {
    return 'AuthConfigDefaults(phonePattern: $phonePattern, nameMaxLength: $nameMaxLength, phonePrefixes: $phonePrefixes, defaultCodeLength: $defaultCodeLength, defaultResendIntervalSec: $defaultResendIntervalSec, defaultPasswordMinLength: $defaultPasswordMinLength, defaultPasswordMaxLength: $defaultPasswordMaxLength, phoneMaskPrefixLength: $phoneMaskPrefixLength, phoneMaskSuffixLength: $phoneMaskSuffixLength)';
  }
}

/// @nodoc
abstract mixin class _$AuthConfigDefaultsCopyWith<$Res>
    implements $AuthConfigDefaultsCopyWith<$Res> {
  factory _$AuthConfigDefaultsCopyWith(
    _AuthConfigDefaults value,
    $Res Function(_AuthConfigDefaults) _then,
  ) = __$AuthConfigDefaultsCopyWithImpl;
  @override
  @useResult
  $Res call({
    String phonePattern,
    int nameMaxLength,
    List<String> phonePrefixes,
    int defaultCodeLength,
    int defaultResendIntervalSec,
    int defaultPasswordMinLength,
    int defaultPasswordMaxLength,
    int phoneMaskPrefixLength,
    int phoneMaskSuffixLength,
  });
}

/// @nodoc
class __$AuthConfigDefaultsCopyWithImpl<$Res>
    implements _$AuthConfigDefaultsCopyWith<$Res> {
  __$AuthConfigDefaultsCopyWithImpl(this._self, this._then);

  final _AuthConfigDefaults _self;
  final $Res Function(_AuthConfigDefaults) _then;

  /// Create a copy of AuthConfigDefaults
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? phonePattern = null,
    Object? nameMaxLength = null,
    Object? phonePrefixes = null,
    Object? defaultCodeLength = null,
    Object? defaultResendIntervalSec = null,
    Object? defaultPasswordMinLength = null,
    Object? defaultPasswordMaxLength = null,
    Object? phoneMaskPrefixLength = null,
    Object? phoneMaskSuffixLength = null,
  }) {
    return _then(
      _AuthConfigDefaults(
        phonePattern: null == phonePattern
            ? _self.phonePattern
            : phonePattern // ignore: cast_nullable_to_non_nullable
                  as String,
        nameMaxLength: null == nameMaxLength
            ? _self.nameMaxLength
            : nameMaxLength // ignore: cast_nullable_to_non_nullable
                  as int,
        phonePrefixes: null == phonePrefixes
            ? _self._phonePrefixes
            : phonePrefixes // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        defaultCodeLength: null == defaultCodeLength
            ? _self.defaultCodeLength
            : defaultCodeLength // ignore: cast_nullable_to_non_nullable
                  as int,
        defaultResendIntervalSec: null == defaultResendIntervalSec
            ? _self.defaultResendIntervalSec
            : defaultResendIntervalSec // ignore: cast_nullable_to_non_nullable
                  as int,
        defaultPasswordMinLength: null == defaultPasswordMinLength
            ? _self.defaultPasswordMinLength
            : defaultPasswordMinLength // ignore: cast_nullable_to_non_nullable
                  as int,
        defaultPasswordMaxLength: null == defaultPasswordMaxLength
            ? _self.defaultPasswordMaxLength
            : defaultPasswordMaxLength // ignore: cast_nullable_to_non_nullable
                  as int,
        phoneMaskPrefixLength: null == phoneMaskPrefixLength
            ? _self.phoneMaskPrefixLength
            : phoneMaskPrefixLength // ignore: cast_nullable_to_non_nullable
                  as int,
        phoneMaskSuffixLength: null == phoneMaskSuffixLength
            ? _self.phoneMaskSuffixLength
            : phoneMaskSuffixLength // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
mixin _$AudioConfig {
  int get sampleRate;
  int get channels;
  int get aacBitrate;
  int get levelUpdateIntervalMs;

  /// dBFS mapped to level 0 (0 dBFS = level 1) for the input level meter.
  double get levelFloorDb;

  /// Create a copy of AudioConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $AudioConfigCopyWith<AudioConfig> get copyWith =>
      _$AudioConfigCopyWithImpl<AudioConfig>(this as AudioConfig, _$identity);

  /// Serializes this AudioConfig to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as AudioConfig;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AudioConfig &&
            (identical(other.sampleRate, _this.sampleRate) ||
                other.sampleRate == _this.sampleRate) &&
            (identical(other.channels, _this.channels) ||
                other.channels == _this.channels) &&
            (identical(other.aacBitrate, _this.aacBitrate) ||
                other.aacBitrate == _this.aacBitrate) &&
            (identical(
                  other.levelUpdateIntervalMs,
                  _this.levelUpdateIntervalMs,
                ) ||
                other.levelUpdateIntervalMs == _this.levelUpdateIntervalMs) &&
            (identical(other.levelFloorDb, _this.levelFloorDb) ||
                other.levelFloorDb == _this.levelFloorDb));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as AudioConfig;
    return Object.hash(
      runtimeType,
      _this.sampleRate,
      _this.channels,
      _this.aacBitrate,
      _this.levelUpdateIntervalMs,
      _this.levelFloorDb,
    );
  }

  @override
  String toString() {
    final _this = this as AudioConfig;
    return 'AudioConfig(sampleRate: ${_this.sampleRate}, channels: ${_this.channels}, aacBitrate: ${_this.aacBitrate}, levelUpdateIntervalMs: ${_this.levelUpdateIntervalMs}, levelFloorDb: ${_this.levelFloorDb})';
  }
}

/// @nodoc
abstract mixin class $AudioConfigCopyWith<$Res> {
  factory $AudioConfigCopyWith(
    AudioConfig value,
    $Res Function(AudioConfig) _then,
  ) = _$AudioConfigCopyWithImpl;
  @useResult
  $Res call({
    int sampleRate,
    int channels,
    int aacBitrate,
    int levelUpdateIntervalMs,
    double levelFloorDb,
  });
}

/// @nodoc
class _$AudioConfigCopyWithImpl<$Res> implements $AudioConfigCopyWith<$Res> {
  _$AudioConfigCopyWithImpl(this._self, this._then);

  final AudioConfig _self;
  final $Res Function(AudioConfig) _then;

  /// Create a copy of AudioConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sampleRate = null,
    Object? channels = null,
    Object? aacBitrate = null,
    Object? levelUpdateIntervalMs = null,
    Object? levelFloorDb = null,
  }) {
    return _then(
      AudioConfig(
        sampleRate: null == sampleRate
            ? _self.sampleRate
            : sampleRate // ignore: cast_nullable_to_non_nullable
                  as int,
        channels: null == channels
            ? _self.channels
            : channels // ignore: cast_nullable_to_non_nullable
                  as int,
        aacBitrate: null == aacBitrate
            ? _self.aacBitrate
            : aacBitrate // ignore: cast_nullable_to_non_nullable
                  as int,
        levelUpdateIntervalMs: null == levelUpdateIntervalMs
            ? _self.levelUpdateIntervalMs
            : levelUpdateIntervalMs // ignore: cast_nullable_to_non_nullable
                  as int,
        levelFloorDb: null == levelFloorDb
            ? _self.levelFloorDb
            : levelFloorDb // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [AudioConfig].
extension AudioConfigPatterns on AudioConfig {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_AudioConfig value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AudioConfig() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_AudioConfig value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AudioConfig():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_AudioConfig value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AudioConfig() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
      int sampleRate,
      int channels,
      int aacBitrate,
      int levelUpdateIntervalMs,
      double levelFloorDb,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AudioConfig() when $default != null:
        return $default(
          _that.sampleRate,
          _that.channels,
          _that.aacBitrate,
          _that.levelUpdateIntervalMs,
          _that.levelFloorDb,
        );
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
      int sampleRate,
      int channels,
      int aacBitrate,
      int levelUpdateIntervalMs,
      double levelFloorDb,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AudioConfig():
        return $default(
          _that.sampleRate,
          _that.channels,
          _that.aacBitrate,
          _that.levelUpdateIntervalMs,
          _that.levelFloorDb,
        );
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
      int sampleRate,
      int channels,
      int aacBitrate,
      int levelUpdateIntervalMs,
      double levelFloorDb,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AudioConfig() when $default != null:
        return $default(
          _that.sampleRate,
          _that.channels,
          _that.aacBitrate,
          _that.levelUpdateIntervalMs,
          _that.levelFloorDb,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _AudioConfig extends AudioConfig {
  const _AudioConfig({
    required this.sampleRate,
    required this.channels,
    required this.aacBitrate,
    required this.levelUpdateIntervalMs,
    required this.levelFloorDb,
  }) : super._();
  factory _AudioConfig.fromJson(Map<String, dynamic> json) =>
      _$AudioConfigFromJson(json);

  @override
  final int sampleRate;
  @override
  final int channels;
  @override
  final int aacBitrate;
  @override
  final int levelUpdateIntervalMs;

  /// dBFS mapped to level 0 (0 dBFS = level 1) for the input level meter.
  @override
  final double levelFloorDb;

  /// Create a copy of AudioConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$AudioConfigCopyWith<_AudioConfig> get copyWith =>
      __$AudioConfigCopyWithImpl<_AudioConfig>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$AudioConfigToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _AudioConfig &&
            (identical(other.sampleRate, sampleRate) ||
                other.sampleRate == sampleRate) &&
            (identical(other.channels, channels) ||
                other.channels == channels) &&
            (identical(other.aacBitrate, aacBitrate) ||
                other.aacBitrate == aacBitrate) &&
            (identical(other.levelUpdateIntervalMs, levelUpdateIntervalMs) ||
                other.levelUpdateIntervalMs == levelUpdateIntervalMs) &&
            (identical(other.levelFloorDb, levelFloorDb) ||
                other.levelFloorDb == levelFloorDb));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(
      runtimeType,
      sampleRate,
      channels,
      aacBitrate,
      levelUpdateIntervalMs,
      levelFloorDb,
    );
  }

  @override
  String toString() {
    return 'AudioConfig(sampleRate: $sampleRate, channels: $channels, aacBitrate: $aacBitrate, levelUpdateIntervalMs: $levelUpdateIntervalMs, levelFloorDb: $levelFloorDb)';
  }
}

/// @nodoc
abstract mixin class _$AudioConfigCopyWith<$Res>
    implements $AudioConfigCopyWith<$Res> {
  factory _$AudioConfigCopyWith(
    _AudioConfig value,
    $Res Function(_AudioConfig) _then,
  ) = __$AudioConfigCopyWithImpl;
  @override
  @useResult
  $Res call({
    int sampleRate,
    int channels,
    int aacBitrate,
    int levelUpdateIntervalMs,
    double levelFloorDb,
  });
}

/// @nodoc
class __$AudioConfigCopyWithImpl<$Res> implements _$AudioConfigCopyWith<$Res> {
  __$AudioConfigCopyWithImpl(this._self, this._then);

  final _AudioConfig _self;
  final $Res Function(_AudioConfig) _then;

  /// Create a copy of AudioConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? sampleRate = null,
    Object? channels = null,
    Object? aacBitrate = null,
    Object? levelUpdateIntervalMs = null,
    Object? levelFloorDb = null,
  }) {
    return _then(
      _AudioConfig(
        sampleRate: null == sampleRate
            ? _self.sampleRate
            : sampleRate // ignore: cast_nullable_to_non_nullable
                  as int,
        channels: null == channels
            ? _self.channels
            : channels // ignore: cast_nullable_to_non_nullable
                  as int,
        aacBitrate: null == aacBitrate
            ? _self.aacBitrate
            : aacBitrate // ignore: cast_nullable_to_non_nullable
                  as int,
        levelUpdateIntervalMs: null == levelUpdateIntervalMs
            ? _self.levelUpdateIntervalMs
            : levelUpdateIntervalMs // ignore: cast_nullable_to_non_nullable
                  as int,
        levelFloorDb: null == levelFloorDb
            ? _self.levelFloorDb
            : levelFloorDb // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
mixin _$VadConfig {
  int get frameMs;
  double get thresholdDbAboveNoise;
  int get noiseFloorPercentile;
  double get noiseFloorWindowSec;
  int get silenceToEndMs;
  int get paddingMs;
  int get minSpeechMs;
  double get maxSegmentSec;
  double get splitSearchWindowSec;

  /// Absolute lower bound of the speech threshold (dBFS), like the server's `-50`.
  double get minThresholdDb;

  /// Create a copy of VadConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $VadConfigCopyWith<VadConfig> get copyWith =>
      _$VadConfigCopyWithImpl<VadConfig>(this as VadConfig, _$identity);

  /// Serializes this VadConfig to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as VadConfig;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is VadConfig &&
            (identical(other.frameMs, _this.frameMs) ||
                other.frameMs == _this.frameMs) &&
            (identical(
                  other.thresholdDbAboveNoise,
                  _this.thresholdDbAboveNoise,
                ) ||
                other.thresholdDbAboveNoise == _this.thresholdDbAboveNoise) &&
            (identical(
                  other.noiseFloorPercentile,
                  _this.noiseFloorPercentile,
                ) ||
                other.noiseFloorPercentile == _this.noiseFloorPercentile) &&
            (identical(other.noiseFloorWindowSec, _this.noiseFloorWindowSec) ||
                other.noiseFloorWindowSec == _this.noiseFloorWindowSec) &&
            (identical(other.silenceToEndMs, _this.silenceToEndMs) ||
                other.silenceToEndMs == _this.silenceToEndMs) &&
            (identical(other.paddingMs, _this.paddingMs) ||
                other.paddingMs == _this.paddingMs) &&
            (identical(other.minSpeechMs, _this.minSpeechMs) ||
                other.minSpeechMs == _this.minSpeechMs) &&
            (identical(other.maxSegmentSec, _this.maxSegmentSec) ||
                other.maxSegmentSec == _this.maxSegmentSec) &&
            (identical(
                  other.splitSearchWindowSec,
                  _this.splitSearchWindowSec,
                ) ||
                other.splitSearchWindowSec == _this.splitSearchWindowSec) &&
            (identical(other.minThresholdDb, _this.minThresholdDb) ||
                other.minThresholdDb == _this.minThresholdDb));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as VadConfig;
    return Object.hash(
      runtimeType,
      _this.frameMs,
      _this.thresholdDbAboveNoise,
      _this.noiseFloorPercentile,
      _this.noiseFloorWindowSec,
      _this.silenceToEndMs,
      _this.paddingMs,
      _this.minSpeechMs,
      _this.maxSegmentSec,
      _this.splitSearchWindowSec,
      _this.minThresholdDb,
    );
  }

  @override
  String toString() {
    final _this = this as VadConfig;
    return 'VadConfig(frameMs: ${_this.frameMs}, thresholdDbAboveNoise: ${_this.thresholdDbAboveNoise}, noiseFloorPercentile: ${_this.noiseFloorPercentile}, noiseFloorWindowSec: ${_this.noiseFloorWindowSec}, silenceToEndMs: ${_this.silenceToEndMs}, paddingMs: ${_this.paddingMs}, minSpeechMs: ${_this.minSpeechMs}, maxSegmentSec: ${_this.maxSegmentSec}, splitSearchWindowSec: ${_this.splitSearchWindowSec}, minThresholdDb: ${_this.minThresholdDb})';
  }
}

/// @nodoc
abstract mixin class $VadConfigCopyWith<$Res> {
  factory $VadConfigCopyWith(VadConfig value, $Res Function(VadConfig) _then) =
      _$VadConfigCopyWithImpl;
  @useResult
  $Res call({
    int frameMs,
    double thresholdDbAboveNoise,
    int noiseFloorPercentile,
    double noiseFloorWindowSec,
    int silenceToEndMs,
    int paddingMs,
    int minSpeechMs,
    double maxSegmentSec,
    double splitSearchWindowSec,
    double minThresholdDb,
  });
}

/// @nodoc
class _$VadConfigCopyWithImpl<$Res> implements $VadConfigCopyWith<$Res> {
  _$VadConfigCopyWithImpl(this._self, this._then);

  final VadConfig _self;
  final $Res Function(VadConfig) _then;

  /// Create a copy of VadConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? frameMs = null,
    Object? thresholdDbAboveNoise = null,
    Object? noiseFloorPercentile = null,
    Object? noiseFloorWindowSec = null,
    Object? silenceToEndMs = null,
    Object? paddingMs = null,
    Object? minSpeechMs = null,
    Object? maxSegmentSec = null,
    Object? splitSearchWindowSec = null,
    Object? minThresholdDb = null,
  }) {
    return _then(
      VadConfig(
        frameMs: null == frameMs
            ? _self.frameMs
            : frameMs // ignore: cast_nullable_to_non_nullable
                  as int,
        thresholdDbAboveNoise: null == thresholdDbAboveNoise
            ? _self.thresholdDbAboveNoise
            : thresholdDbAboveNoise // ignore: cast_nullable_to_non_nullable
                  as double,
        noiseFloorPercentile: null == noiseFloorPercentile
            ? _self.noiseFloorPercentile
            : noiseFloorPercentile // ignore: cast_nullable_to_non_nullable
                  as int,
        noiseFloorWindowSec: null == noiseFloorWindowSec
            ? _self.noiseFloorWindowSec
            : noiseFloorWindowSec // ignore: cast_nullable_to_non_nullable
                  as double,
        silenceToEndMs: null == silenceToEndMs
            ? _self.silenceToEndMs
            : silenceToEndMs // ignore: cast_nullable_to_non_nullable
                  as int,
        paddingMs: null == paddingMs
            ? _self.paddingMs
            : paddingMs // ignore: cast_nullable_to_non_nullable
                  as int,
        minSpeechMs: null == minSpeechMs
            ? _self.minSpeechMs
            : minSpeechMs // ignore: cast_nullable_to_non_nullable
                  as int,
        maxSegmentSec: null == maxSegmentSec
            ? _self.maxSegmentSec
            : maxSegmentSec // ignore: cast_nullable_to_non_nullable
                  as double,
        splitSearchWindowSec: null == splitSearchWindowSec
            ? _self.splitSearchWindowSec
            : splitSearchWindowSec // ignore: cast_nullable_to_non_nullable
                  as double,
        minThresholdDb: null == minThresholdDb
            ? _self.minThresholdDb
            : minThresholdDb // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [VadConfig].
extension VadConfigPatterns on VadConfig {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_VadConfig value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _VadConfig() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_VadConfig value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _VadConfig():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_VadConfig value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _VadConfig() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
      int frameMs,
      double thresholdDbAboveNoise,
      int noiseFloorPercentile,
      double noiseFloorWindowSec,
      int silenceToEndMs,
      int paddingMs,
      int minSpeechMs,
      double maxSegmentSec,
      double splitSearchWindowSec,
      double minThresholdDb,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _VadConfig() when $default != null:
        return $default(
          _that.frameMs,
          _that.thresholdDbAboveNoise,
          _that.noiseFloorPercentile,
          _that.noiseFloorWindowSec,
          _that.silenceToEndMs,
          _that.paddingMs,
          _that.minSpeechMs,
          _that.maxSegmentSec,
          _that.splitSearchWindowSec,
          _that.minThresholdDb,
        );
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
      int frameMs,
      double thresholdDbAboveNoise,
      int noiseFloorPercentile,
      double noiseFloorWindowSec,
      int silenceToEndMs,
      int paddingMs,
      int minSpeechMs,
      double maxSegmentSec,
      double splitSearchWindowSec,
      double minThresholdDb,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _VadConfig():
        return $default(
          _that.frameMs,
          _that.thresholdDbAboveNoise,
          _that.noiseFloorPercentile,
          _that.noiseFloorWindowSec,
          _that.silenceToEndMs,
          _that.paddingMs,
          _that.minSpeechMs,
          _that.maxSegmentSec,
          _that.splitSearchWindowSec,
          _that.minThresholdDb,
        );
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
      int frameMs,
      double thresholdDbAboveNoise,
      int noiseFloorPercentile,
      double noiseFloorWindowSec,
      int silenceToEndMs,
      int paddingMs,
      int minSpeechMs,
      double maxSegmentSec,
      double splitSearchWindowSec,
      double minThresholdDb,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _VadConfig() when $default != null:
        return $default(
          _that.frameMs,
          _that.thresholdDbAboveNoise,
          _that.noiseFloorPercentile,
          _that.noiseFloorWindowSec,
          _that.silenceToEndMs,
          _that.paddingMs,
          _that.minSpeechMs,
          _that.maxSegmentSec,
          _that.splitSearchWindowSec,
          _that.minThresholdDb,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _VadConfig implements VadConfig {
  const _VadConfig({
    required this.frameMs,
    required this.thresholdDbAboveNoise,
    required this.noiseFloorPercentile,
    required this.noiseFloorWindowSec,
    required this.silenceToEndMs,
    required this.paddingMs,
    required this.minSpeechMs,
    required this.maxSegmentSec,
    required this.splitSearchWindowSec,
    required this.minThresholdDb,
  });
  factory _VadConfig.fromJson(Map<String, dynamic> json) =>
      _$VadConfigFromJson(json);

  @override
  final int frameMs;
  @override
  final double thresholdDbAboveNoise;
  @override
  final int noiseFloorPercentile;
  @override
  final double noiseFloorWindowSec;
  @override
  final int silenceToEndMs;
  @override
  final int paddingMs;
  @override
  final int minSpeechMs;
  @override
  final double maxSegmentSec;
  @override
  final double splitSearchWindowSec;

  /// Absolute lower bound of the speech threshold (dBFS), like the server's `-50`.
  @override
  final double minThresholdDb;

  /// Create a copy of VadConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$VadConfigCopyWith<_VadConfig> get copyWith =>
      __$VadConfigCopyWithImpl<_VadConfig>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$VadConfigToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _VadConfig &&
            (identical(other.frameMs, frameMs) || other.frameMs == frameMs) &&
            (identical(other.thresholdDbAboveNoise, thresholdDbAboveNoise) ||
                other.thresholdDbAboveNoise == thresholdDbAboveNoise) &&
            (identical(other.noiseFloorPercentile, noiseFloorPercentile) ||
                other.noiseFloorPercentile == noiseFloorPercentile) &&
            (identical(other.noiseFloorWindowSec, noiseFloorWindowSec) ||
                other.noiseFloorWindowSec == noiseFloorWindowSec) &&
            (identical(other.silenceToEndMs, silenceToEndMs) ||
                other.silenceToEndMs == silenceToEndMs) &&
            (identical(other.paddingMs, paddingMs) ||
                other.paddingMs == paddingMs) &&
            (identical(other.minSpeechMs, minSpeechMs) ||
                other.minSpeechMs == minSpeechMs) &&
            (identical(other.maxSegmentSec, maxSegmentSec) ||
                other.maxSegmentSec == maxSegmentSec) &&
            (identical(other.splitSearchWindowSec, splitSearchWindowSec) ||
                other.splitSearchWindowSec == splitSearchWindowSec) &&
            (identical(other.minThresholdDb, minThresholdDb) ||
                other.minThresholdDb == minThresholdDb));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(
      runtimeType,
      frameMs,
      thresholdDbAboveNoise,
      noiseFloorPercentile,
      noiseFloorWindowSec,
      silenceToEndMs,
      paddingMs,
      minSpeechMs,
      maxSegmentSec,
      splitSearchWindowSec,
      minThresholdDb,
    );
  }

  @override
  String toString() {
    return 'VadConfig(frameMs: $frameMs, thresholdDbAboveNoise: $thresholdDbAboveNoise, noiseFloorPercentile: $noiseFloorPercentile, noiseFloorWindowSec: $noiseFloorWindowSec, silenceToEndMs: $silenceToEndMs, paddingMs: $paddingMs, minSpeechMs: $minSpeechMs, maxSegmentSec: $maxSegmentSec, splitSearchWindowSec: $splitSearchWindowSec, minThresholdDb: $minThresholdDb)';
  }
}

/// @nodoc
abstract mixin class _$VadConfigCopyWith<$Res>
    implements $VadConfigCopyWith<$Res> {
  factory _$VadConfigCopyWith(
    _VadConfig value,
    $Res Function(_VadConfig) _then,
  ) = __$VadConfigCopyWithImpl;
  @override
  @useResult
  $Res call({
    int frameMs,
    double thresholdDbAboveNoise,
    int noiseFloorPercentile,
    double noiseFloorWindowSec,
    int silenceToEndMs,
    int paddingMs,
    int minSpeechMs,
    double maxSegmentSec,
    double splitSearchWindowSec,
    double minThresholdDb,
  });
}

/// @nodoc
class __$VadConfigCopyWithImpl<$Res> implements _$VadConfigCopyWith<$Res> {
  __$VadConfigCopyWithImpl(this._self, this._then);

  final _VadConfig _self;
  final $Res Function(_VadConfig) _then;

  /// Create a copy of VadConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? frameMs = null,
    Object? thresholdDbAboveNoise = null,
    Object? noiseFloorPercentile = null,
    Object? noiseFloorWindowSec = null,
    Object? silenceToEndMs = null,
    Object? paddingMs = null,
    Object? minSpeechMs = null,
    Object? maxSegmentSec = null,
    Object? splitSearchWindowSec = null,
    Object? minThresholdDb = null,
  }) {
    return _then(
      _VadConfig(
        frameMs: null == frameMs
            ? _self.frameMs
            : frameMs // ignore: cast_nullable_to_non_nullable
                  as int,
        thresholdDbAboveNoise: null == thresholdDbAboveNoise
            ? _self.thresholdDbAboveNoise
            : thresholdDbAboveNoise // ignore: cast_nullable_to_non_nullable
                  as double,
        noiseFloorPercentile: null == noiseFloorPercentile
            ? _self.noiseFloorPercentile
            : noiseFloorPercentile // ignore: cast_nullable_to_non_nullable
                  as int,
        noiseFloorWindowSec: null == noiseFloorWindowSec
            ? _self.noiseFloorWindowSec
            : noiseFloorWindowSec // ignore: cast_nullable_to_non_nullable
                  as double,
        silenceToEndMs: null == silenceToEndMs
            ? _self.silenceToEndMs
            : silenceToEndMs // ignore: cast_nullable_to_non_nullable
                  as int,
        paddingMs: null == paddingMs
            ? _self.paddingMs
            : paddingMs // ignore: cast_nullable_to_non_nullable
                  as int,
        minSpeechMs: null == minSpeechMs
            ? _self.minSpeechMs
            : minSpeechMs // ignore: cast_nullable_to_non_nullable
                  as int,
        maxSegmentSec: null == maxSegmentSec
            ? _self.maxSegmentSec
            : maxSegmentSec // ignore: cast_nullable_to_non_nullable
                  as double,
        splitSearchWindowSec: null == splitSearchWindowSec
            ? _self.splitSearchWindowSec
            : splitSearchWindowSec // ignore: cast_nullable_to_non_nullable
                  as double,
        minThresholdDb: null == minThresholdDb
            ? _self.minThresholdDb
            : minThresholdDb // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
mixin _$TranscriptionConfig {
  /// `auto` = let the server detect (the `language` query parameter is omitted).
  String get defaultLanguage;

  /// Language codes offered in pickers; the first entry should be `auto`.
  List<String> get languages;

  /// The code meaning "auto-detect" (the `language` query parameter is then omitted).
  String get autoLanguageCode;

  /// Create a copy of TranscriptionConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TranscriptionConfigCopyWith<TranscriptionConfig> get copyWith =>
      _$TranscriptionConfigCopyWithImpl<TranscriptionConfig>(
        this as TranscriptionConfig,
        _$identity,
      );

  /// Serializes this TranscriptionConfig to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as TranscriptionConfig;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TranscriptionConfig &&
            (identical(other.defaultLanguage, _this.defaultLanguage) ||
                other.defaultLanguage == _this.defaultLanguage) &&
            const DeepCollectionEquality().equals(
              other.languages,
              _this.languages,
            ) &&
            (identical(other.autoLanguageCode, _this.autoLanguageCode) ||
                other.autoLanguageCode == _this.autoLanguageCode));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as TranscriptionConfig;
    return Object.hash(
      runtimeType,
      _this.defaultLanguage,
      const DeepCollectionEquality().hash(_this.languages),
      _this.autoLanguageCode,
    );
  }

  @override
  String toString() {
    final _this = this as TranscriptionConfig;
    return 'TranscriptionConfig(defaultLanguage: ${_this.defaultLanguage}, languages: ${_this.languages}, autoLanguageCode: ${_this.autoLanguageCode})';
  }
}

/// @nodoc
abstract mixin class $TranscriptionConfigCopyWith<$Res> {
  factory $TranscriptionConfigCopyWith(
    TranscriptionConfig value,
    $Res Function(TranscriptionConfig) _then,
  ) = _$TranscriptionConfigCopyWithImpl;
  @useResult
  $Res call({
    String defaultLanguage,
    List<String> languages,
    String autoLanguageCode,
  });
}

/// @nodoc
class _$TranscriptionConfigCopyWithImpl<$Res>
    implements $TranscriptionConfigCopyWith<$Res> {
  _$TranscriptionConfigCopyWithImpl(this._self, this._then);

  final TranscriptionConfig _self;
  final $Res Function(TranscriptionConfig) _then;

  /// Create a copy of TranscriptionConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? defaultLanguage = null,
    Object? languages = null,
    Object? autoLanguageCode = null,
  }) {
    return _then(
      TranscriptionConfig(
        defaultLanguage: null == defaultLanguage
            ? _self.defaultLanguage
            : defaultLanguage // ignore: cast_nullable_to_non_nullable
                  as String,
        languages: null == languages
            ? _self.languages
            : languages // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        autoLanguageCode: null == autoLanguageCode
            ? _self.autoLanguageCode
            : autoLanguageCode // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [TranscriptionConfig].
extension TranscriptionConfigPatterns on TranscriptionConfig {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_TranscriptionConfig value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TranscriptionConfig() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_TranscriptionConfig value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TranscriptionConfig():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_TranscriptionConfig value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TranscriptionConfig() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
      String defaultLanguage,
      List<String> languages,
      String autoLanguageCode,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TranscriptionConfig() when $default != null:
        return $default(
          _that.defaultLanguage,
          _that.languages,
          _that.autoLanguageCode,
        );
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
      String defaultLanguage,
      List<String> languages,
      String autoLanguageCode,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TranscriptionConfig():
        return $default(
          _that.defaultLanguage,
          _that.languages,
          _that.autoLanguageCode,
        );
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
      String defaultLanguage,
      List<String> languages,
      String autoLanguageCode,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TranscriptionConfig() when $default != null:
        return $default(
          _that.defaultLanguage,
          _that.languages,
          _that.autoLanguageCode,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _TranscriptionConfig implements TranscriptionConfig {
  const _TranscriptionConfig({
    required this.defaultLanguage,
    required List<String> languages,
    required this.autoLanguageCode,
  }) : _languages = languages;
  factory _TranscriptionConfig.fromJson(Map<String, dynamic> json) =>
      _$TranscriptionConfigFromJson(json);

  /// `auto` = let the server detect (the `language` query parameter is omitted).
  @override
  final String defaultLanguage;

  /// Language codes offered in pickers; the first entry should be `auto`.
  final List<String> _languages;

  /// Language codes offered in pickers; the first entry should be `auto`.
  @override
  List<String> get languages {
    if (_languages is EqualUnmodifiableListView) return _languages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_languages);
  }

  /// The code meaning "auto-detect" (the `language` query parameter is then omitted).
  @override
  final String autoLanguageCode;

  /// Create a copy of TranscriptionConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$TranscriptionConfigCopyWith<_TranscriptionConfig> get copyWith =>
      __$TranscriptionConfigCopyWithImpl<_TranscriptionConfig>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$TranscriptionConfigToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _TranscriptionConfig &&
            (identical(other.defaultLanguage, defaultLanguage) ||
                other.defaultLanguage == defaultLanguage) &&
            const DeepCollectionEquality().equals(
              other.languages,
              _languages,
            ) &&
            (identical(other.autoLanguageCode, autoLanguageCode) ||
                other.autoLanguageCode == autoLanguageCode));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(
      runtimeType,
      defaultLanguage,
      const DeepCollectionEquality().hash(_languages),
      autoLanguageCode,
    );
  }

  @override
  String toString() {
    return 'TranscriptionConfig(defaultLanguage: $defaultLanguage, languages: $languages, autoLanguageCode: $autoLanguageCode)';
  }
}

/// @nodoc
abstract mixin class _$TranscriptionConfigCopyWith<$Res>
    implements $TranscriptionConfigCopyWith<$Res> {
  factory _$TranscriptionConfigCopyWith(
    _TranscriptionConfig value,
    $Res Function(_TranscriptionConfig) _then,
  ) = __$TranscriptionConfigCopyWithImpl;
  @override
  @useResult
  $Res call({
    String defaultLanguage,
    List<String> languages,
    String autoLanguageCode,
  });
}

/// @nodoc
class __$TranscriptionConfigCopyWithImpl<$Res>
    implements _$TranscriptionConfigCopyWith<$Res> {
  __$TranscriptionConfigCopyWithImpl(this._self, this._then);

  final _TranscriptionConfig _self;
  final $Res Function(_TranscriptionConfig) _then;

  /// Create a copy of TranscriptionConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? defaultLanguage = null,
    Object? languages = null,
    Object? autoLanguageCode = null,
  }) {
    return _then(
      _TranscriptionConfig(
        defaultLanguage: null == defaultLanguage
            ? _self.defaultLanguage
            : defaultLanguage // ignore: cast_nullable_to_non_nullable
                  as String,
        languages: null == languages
            ? _self._languages
            : languages // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        autoLanguageCode: null == autoLanguageCode
            ? _self.autoLanguageCode
            : autoLanguageCode // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
mixin _$RecordingConfig {
  RecordingSource get defaultSource;

  /// `intl` DateFormat pattern for the generated meeting title suffix.
  String get titleFormat;
  double get systemAudioMicGain;
  double get systemAudioDuckingRatio;
  bool get keepLocalAudioDefault;

  /// Extension of the local AAC recording file (`<meetingId>.<ext>`).
  String get audioFileExtension;

  /// `filename` query value of `PUT /meetings/{id}/audio`.
  String get audioUploadFileName;

  /// `Content-Type` of the audio upload.
  String get audioContentType;

  /// `Content-Type` of a live PCM16 segment upload.
  String get segmentContentType;

  /// Sub-directory of the app support dir holding local recordings.
  String get recordingsDirName;

  /// Sub-directory of the app support dir holding the pending segment queue.
  String get pendingQueueDirName;

  /// Max wait for the audio source's last frames after stop.
  int get stopDrainTimeoutMs;

  /// Number of level samples shown by the live waveform.
  int get waveformBars;
  int get transcriptScrollAnimationMs;

  /// Android notification channel of the recording foreground service.
  String get notificationChannelId;

  /// Android foreground service notification id.
  int get foregroundServiceId;

  /// Create a copy of RecordingConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $RecordingConfigCopyWith<RecordingConfig> get copyWith =>
      _$RecordingConfigCopyWithImpl<RecordingConfig>(
        this as RecordingConfig,
        _$identity,
      );

  /// Serializes this RecordingConfig to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as RecordingConfig;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is RecordingConfig &&
            (identical(other.defaultSource, _this.defaultSource) ||
                other.defaultSource == _this.defaultSource) &&
            (identical(other.titleFormat, _this.titleFormat) ||
                other.titleFormat == _this.titleFormat) &&
            (identical(other.systemAudioMicGain, _this.systemAudioMicGain) ||
                other.systemAudioMicGain == _this.systemAudioMicGain) &&
            (identical(
                  other.systemAudioDuckingRatio,
                  _this.systemAudioDuckingRatio,
                ) ||
                other.systemAudioDuckingRatio ==
                    _this.systemAudioDuckingRatio) &&
            (identical(
                  other.keepLocalAudioDefault,
                  _this.keepLocalAudioDefault,
                ) ||
                other.keepLocalAudioDefault == _this.keepLocalAudioDefault) &&
            (identical(other.audioFileExtension, _this.audioFileExtension) ||
                other.audioFileExtension == _this.audioFileExtension) &&
            (identical(other.audioUploadFileName, _this.audioUploadFileName) ||
                other.audioUploadFileName == _this.audioUploadFileName) &&
            (identical(other.audioContentType, _this.audioContentType) ||
                other.audioContentType == _this.audioContentType) &&
            (identical(other.segmentContentType, _this.segmentContentType) ||
                other.segmentContentType == _this.segmentContentType) &&
            (identical(other.recordingsDirName, _this.recordingsDirName) ||
                other.recordingsDirName == _this.recordingsDirName) &&
            (identical(other.pendingQueueDirName, _this.pendingQueueDirName) ||
                other.pendingQueueDirName == _this.pendingQueueDirName) &&
            (identical(other.stopDrainTimeoutMs, _this.stopDrainTimeoutMs) ||
                other.stopDrainTimeoutMs == _this.stopDrainTimeoutMs) &&
            (identical(other.waveformBars, _this.waveformBars) ||
                other.waveformBars == _this.waveformBars) &&
            (identical(
                  other.transcriptScrollAnimationMs,
                  _this.transcriptScrollAnimationMs,
                ) ||
                other.transcriptScrollAnimationMs ==
                    _this.transcriptScrollAnimationMs) &&
            (identical(
                  other.notificationChannelId,
                  _this.notificationChannelId,
                ) ||
                other.notificationChannelId == _this.notificationChannelId) &&
            (identical(other.foregroundServiceId, _this.foregroundServiceId) ||
                other.foregroundServiceId == _this.foregroundServiceId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as RecordingConfig;
    return Object.hash(
      runtimeType,
      _this.defaultSource,
      _this.titleFormat,
      _this.systemAudioMicGain,
      _this.systemAudioDuckingRatio,
      _this.keepLocalAudioDefault,
      _this.audioFileExtension,
      _this.audioUploadFileName,
      _this.audioContentType,
      _this.segmentContentType,
      _this.recordingsDirName,
      _this.pendingQueueDirName,
      _this.stopDrainTimeoutMs,
      _this.waveformBars,
      _this.transcriptScrollAnimationMs,
      _this.notificationChannelId,
      _this.foregroundServiceId,
    );
  }

  @override
  String toString() {
    final _this = this as RecordingConfig;
    return 'RecordingConfig(defaultSource: ${_this.defaultSource}, titleFormat: ${_this.titleFormat}, systemAudioMicGain: ${_this.systemAudioMicGain}, systemAudioDuckingRatio: ${_this.systemAudioDuckingRatio}, keepLocalAudioDefault: ${_this.keepLocalAudioDefault}, audioFileExtension: ${_this.audioFileExtension}, audioUploadFileName: ${_this.audioUploadFileName}, audioContentType: ${_this.audioContentType}, segmentContentType: ${_this.segmentContentType}, recordingsDirName: ${_this.recordingsDirName}, pendingQueueDirName: ${_this.pendingQueueDirName}, stopDrainTimeoutMs: ${_this.stopDrainTimeoutMs}, waveformBars: ${_this.waveformBars}, transcriptScrollAnimationMs: ${_this.transcriptScrollAnimationMs}, notificationChannelId: ${_this.notificationChannelId}, foregroundServiceId: ${_this.foregroundServiceId})';
  }
}

/// @nodoc
abstract mixin class $RecordingConfigCopyWith<$Res> {
  factory $RecordingConfigCopyWith(
    RecordingConfig value,
    $Res Function(RecordingConfig) _then,
  ) = _$RecordingConfigCopyWithImpl;
  @useResult
  $Res call({
    RecordingSource defaultSource,
    String titleFormat,
    double systemAudioMicGain,
    double systemAudioDuckingRatio,
    bool keepLocalAudioDefault,
    String audioFileExtension,
    String audioUploadFileName,
    String audioContentType,
    String segmentContentType,
    String recordingsDirName,
    String pendingQueueDirName,
    int stopDrainTimeoutMs,
    int waveformBars,
    int transcriptScrollAnimationMs,
    String notificationChannelId,
    int foregroundServiceId,
  });
}

/// @nodoc
class _$RecordingConfigCopyWithImpl<$Res>
    implements $RecordingConfigCopyWith<$Res> {
  _$RecordingConfigCopyWithImpl(this._self, this._then);

  final RecordingConfig _self;
  final $Res Function(RecordingConfig) _then;

  /// Create a copy of RecordingConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? defaultSource = null,
    Object? titleFormat = null,
    Object? systemAudioMicGain = null,
    Object? systemAudioDuckingRatio = null,
    Object? keepLocalAudioDefault = null,
    Object? audioFileExtension = null,
    Object? audioUploadFileName = null,
    Object? audioContentType = null,
    Object? segmentContentType = null,
    Object? recordingsDirName = null,
    Object? pendingQueueDirName = null,
    Object? stopDrainTimeoutMs = null,
    Object? waveformBars = null,
    Object? transcriptScrollAnimationMs = null,
    Object? notificationChannelId = null,
    Object? foregroundServiceId = null,
  }) {
    return _then(
      RecordingConfig(
        defaultSource: null == defaultSource
            ? _self.defaultSource
            : defaultSource // ignore: cast_nullable_to_non_nullable
                  as RecordingSource,
        titleFormat: null == titleFormat
            ? _self.titleFormat
            : titleFormat // ignore: cast_nullable_to_non_nullable
                  as String,
        systemAudioMicGain: null == systemAudioMicGain
            ? _self.systemAudioMicGain
            : systemAudioMicGain // ignore: cast_nullable_to_non_nullable
                  as double,
        systemAudioDuckingRatio: null == systemAudioDuckingRatio
            ? _self.systemAudioDuckingRatio
            : systemAudioDuckingRatio // ignore: cast_nullable_to_non_nullable
                  as double,
        keepLocalAudioDefault: null == keepLocalAudioDefault
            ? _self.keepLocalAudioDefault
            : keepLocalAudioDefault // ignore: cast_nullable_to_non_nullable
                  as bool,
        audioFileExtension: null == audioFileExtension
            ? _self.audioFileExtension
            : audioFileExtension // ignore: cast_nullable_to_non_nullable
                  as String,
        audioUploadFileName: null == audioUploadFileName
            ? _self.audioUploadFileName
            : audioUploadFileName // ignore: cast_nullable_to_non_nullable
                  as String,
        audioContentType: null == audioContentType
            ? _self.audioContentType
            : audioContentType // ignore: cast_nullable_to_non_nullable
                  as String,
        segmentContentType: null == segmentContentType
            ? _self.segmentContentType
            : segmentContentType // ignore: cast_nullable_to_non_nullable
                  as String,
        recordingsDirName: null == recordingsDirName
            ? _self.recordingsDirName
            : recordingsDirName // ignore: cast_nullable_to_non_nullable
                  as String,
        pendingQueueDirName: null == pendingQueueDirName
            ? _self.pendingQueueDirName
            : pendingQueueDirName // ignore: cast_nullable_to_non_nullable
                  as String,
        stopDrainTimeoutMs: null == stopDrainTimeoutMs
            ? _self.stopDrainTimeoutMs
            : stopDrainTimeoutMs // ignore: cast_nullable_to_non_nullable
                  as int,
        waveformBars: null == waveformBars
            ? _self.waveformBars
            : waveformBars // ignore: cast_nullable_to_non_nullable
                  as int,
        transcriptScrollAnimationMs: null == transcriptScrollAnimationMs
            ? _self.transcriptScrollAnimationMs
            : transcriptScrollAnimationMs // ignore: cast_nullable_to_non_nullable
                  as int,
        notificationChannelId: null == notificationChannelId
            ? _self.notificationChannelId
            : notificationChannelId // ignore: cast_nullable_to_non_nullable
                  as String,
        foregroundServiceId: null == foregroundServiceId
            ? _self.foregroundServiceId
            : foregroundServiceId // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [RecordingConfig].
extension RecordingConfigPatterns on RecordingConfig {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_RecordingConfig value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _RecordingConfig() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_RecordingConfig value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RecordingConfig():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_RecordingConfig value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RecordingConfig() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
      RecordingSource defaultSource,
      String titleFormat,
      double systemAudioMicGain,
      double systemAudioDuckingRatio,
      bool keepLocalAudioDefault,
      String audioFileExtension,
      String audioUploadFileName,
      String audioContentType,
      String segmentContentType,
      String recordingsDirName,
      String pendingQueueDirName,
      int stopDrainTimeoutMs,
      int waveformBars,
      int transcriptScrollAnimationMs,
      String notificationChannelId,
      int foregroundServiceId,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _RecordingConfig() when $default != null:
        return $default(
          _that.defaultSource,
          _that.titleFormat,
          _that.systemAudioMicGain,
          _that.systemAudioDuckingRatio,
          _that.keepLocalAudioDefault,
          _that.audioFileExtension,
          _that.audioUploadFileName,
          _that.audioContentType,
          _that.segmentContentType,
          _that.recordingsDirName,
          _that.pendingQueueDirName,
          _that.stopDrainTimeoutMs,
          _that.waveformBars,
          _that.transcriptScrollAnimationMs,
          _that.notificationChannelId,
          _that.foregroundServiceId,
        );
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
      RecordingSource defaultSource,
      String titleFormat,
      double systemAudioMicGain,
      double systemAudioDuckingRatio,
      bool keepLocalAudioDefault,
      String audioFileExtension,
      String audioUploadFileName,
      String audioContentType,
      String segmentContentType,
      String recordingsDirName,
      String pendingQueueDirName,
      int stopDrainTimeoutMs,
      int waveformBars,
      int transcriptScrollAnimationMs,
      String notificationChannelId,
      int foregroundServiceId,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RecordingConfig():
        return $default(
          _that.defaultSource,
          _that.titleFormat,
          _that.systemAudioMicGain,
          _that.systemAudioDuckingRatio,
          _that.keepLocalAudioDefault,
          _that.audioFileExtension,
          _that.audioUploadFileName,
          _that.audioContentType,
          _that.segmentContentType,
          _that.recordingsDirName,
          _that.pendingQueueDirName,
          _that.stopDrainTimeoutMs,
          _that.waveformBars,
          _that.transcriptScrollAnimationMs,
          _that.notificationChannelId,
          _that.foregroundServiceId,
        );
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
      RecordingSource defaultSource,
      String titleFormat,
      double systemAudioMicGain,
      double systemAudioDuckingRatio,
      bool keepLocalAudioDefault,
      String audioFileExtension,
      String audioUploadFileName,
      String audioContentType,
      String segmentContentType,
      String recordingsDirName,
      String pendingQueueDirName,
      int stopDrainTimeoutMs,
      int waveformBars,
      int transcriptScrollAnimationMs,
      String notificationChannelId,
      int foregroundServiceId,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RecordingConfig() when $default != null:
        return $default(
          _that.defaultSource,
          _that.titleFormat,
          _that.systemAudioMicGain,
          _that.systemAudioDuckingRatio,
          _that.keepLocalAudioDefault,
          _that.audioFileExtension,
          _that.audioUploadFileName,
          _that.audioContentType,
          _that.segmentContentType,
          _that.recordingsDirName,
          _that.pendingQueueDirName,
          _that.stopDrainTimeoutMs,
          _that.waveformBars,
          _that.transcriptScrollAnimationMs,
          _that.notificationChannelId,
          _that.foregroundServiceId,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _RecordingConfig extends RecordingConfig {
  const _RecordingConfig({
    required this.defaultSource,
    required this.titleFormat,
    required this.systemAudioMicGain,
    required this.systemAudioDuckingRatio,
    required this.keepLocalAudioDefault,
    required this.audioFileExtension,
    required this.audioUploadFileName,
    required this.audioContentType,
    required this.segmentContentType,
    required this.recordingsDirName,
    required this.pendingQueueDirName,
    required this.stopDrainTimeoutMs,
    required this.waveformBars,
    required this.transcriptScrollAnimationMs,
    required this.notificationChannelId,
    required this.foregroundServiceId,
  }) : super._();
  factory _RecordingConfig.fromJson(Map<String, dynamic> json) =>
      _$RecordingConfigFromJson(json);

  @override
  final RecordingSource defaultSource;

  /// `intl` DateFormat pattern for the generated meeting title suffix.
  @override
  final String titleFormat;
  @override
  final double systemAudioMicGain;
  @override
  final double systemAudioDuckingRatio;
  @override
  final bool keepLocalAudioDefault;

  /// Extension of the local AAC recording file (`<meetingId>.<ext>`).
  @override
  final String audioFileExtension;

  /// `filename` query value of `PUT /meetings/{id}/audio`.
  @override
  final String audioUploadFileName;

  /// `Content-Type` of the audio upload.
  @override
  final String audioContentType;

  /// `Content-Type` of a live PCM16 segment upload.
  @override
  final String segmentContentType;

  /// Sub-directory of the app support dir holding local recordings.
  @override
  final String recordingsDirName;

  /// Sub-directory of the app support dir holding the pending segment queue.
  @override
  final String pendingQueueDirName;

  /// Max wait for the audio source's last frames after stop.
  @override
  final int stopDrainTimeoutMs;

  /// Number of level samples shown by the live waveform.
  @override
  final int waveformBars;
  @override
  final int transcriptScrollAnimationMs;

  /// Android notification channel of the recording foreground service.
  @override
  final String notificationChannelId;

  /// Android foreground service notification id.
  @override
  final int foregroundServiceId;

  /// Create a copy of RecordingConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$RecordingConfigCopyWith<_RecordingConfig> get copyWith =>
      __$RecordingConfigCopyWithImpl<_RecordingConfig>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$RecordingConfigToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _RecordingConfig &&
            (identical(other.defaultSource, defaultSource) ||
                other.defaultSource == defaultSource) &&
            (identical(other.titleFormat, titleFormat) ||
                other.titleFormat == titleFormat) &&
            (identical(other.systemAudioMicGain, systemAudioMicGain) ||
                other.systemAudioMicGain == systemAudioMicGain) &&
            (identical(
                  other.systemAudioDuckingRatio,
                  systemAudioDuckingRatio,
                ) ||
                other.systemAudioDuckingRatio == systemAudioDuckingRatio) &&
            (identical(other.keepLocalAudioDefault, keepLocalAudioDefault) ||
                other.keepLocalAudioDefault == keepLocalAudioDefault) &&
            (identical(other.audioFileExtension, audioFileExtension) ||
                other.audioFileExtension == audioFileExtension) &&
            (identical(other.audioUploadFileName, audioUploadFileName) ||
                other.audioUploadFileName == audioUploadFileName) &&
            (identical(other.audioContentType, audioContentType) ||
                other.audioContentType == audioContentType) &&
            (identical(other.segmentContentType, segmentContentType) ||
                other.segmentContentType == segmentContentType) &&
            (identical(other.recordingsDirName, recordingsDirName) ||
                other.recordingsDirName == recordingsDirName) &&
            (identical(other.pendingQueueDirName, pendingQueueDirName) ||
                other.pendingQueueDirName == pendingQueueDirName) &&
            (identical(other.stopDrainTimeoutMs, stopDrainTimeoutMs) ||
                other.stopDrainTimeoutMs == stopDrainTimeoutMs) &&
            (identical(other.waveformBars, waveformBars) ||
                other.waveformBars == waveformBars) &&
            (identical(
                  other.transcriptScrollAnimationMs,
                  transcriptScrollAnimationMs,
                ) ||
                other.transcriptScrollAnimationMs ==
                    transcriptScrollAnimationMs) &&
            (identical(other.notificationChannelId, notificationChannelId) ||
                other.notificationChannelId == notificationChannelId) &&
            (identical(other.foregroundServiceId, foregroundServiceId) ||
                other.foregroundServiceId == foregroundServiceId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(
      runtimeType,
      defaultSource,
      titleFormat,
      systemAudioMicGain,
      systemAudioDuckingRatio,
      keepLocalAudioDefault,
      audioFileExtension,
      audioUploadFileName,
      audioContentType,
      segmentContentType,
      recordingsDirName,
      pendingQueueDirName,
      stopDrainTimeoutMs,
      waveformBars,
      transcriptScrollAnimationMs,
      notificationChannelId,
      foregroundServiceId,
    );
  }

  @override
  String toString() {
    return 'RecordingConfig(defaultSource: $defaultSource, titleFormat: $titleFormat, systemAudioMicGain: $systemAudioMicGain, systemAudioDuckingRatio: $systemAudioDuckingRatio, keepLocalAudioDefault: $keepLocalAudioDefault, audioFileExtension: $audioFileExtension, audioUploadFileName: $audioUploadFileName, audioContentType: $audioContentType, segmentContentType: $segmentContentType, recordingsDirName: $recordingsDirName, pendingQueueDirName: $pendingQueueDirName, stopDrainTimeoutMs: $stopDrainTimeoutMs, waveformBars: $waveformBars, transcriptScrollAnimationMs: $transcriptScrollAnimationMs, notificationChannelId: $notificationChannelId, foregroundServiceId: $foregroundServiceId)';
  }
}

/// @nodoc
abstract mixin class _$RecordingConfigCopyWith<$Res>
    implements $RecordingConfigCopyWith<$Res> {
  factory _$RecordingConfigCopyWith(
    _RecordingConfig value,
    $Res Function(_RecordingConfig) _then,
  ) = __$RecordingConfigCopyWithImpl;
  @override
  @useResult
  $Res call({
    RecordingSource defaultSource,
    String titleFormat,
    double systemAudioMicGain,
    double systemAudioDuckingRatio,
    bool keepLocalAudioDefault,
    String audioFileExtension,
    String audioUploadFileName,
    String audioContentType,
    String segmentContentType,
    String recordingsDirName,
    String pendingQueueDirName,
    int stopDrainTimeoutMs,
    int waveformBars,
    int transcriptScrollAnimationMs,
    String notificationChannelId,
    int foregroundServiceId,
  });
}

/// @nodoc
class __$RecordingConfigCopyWithImpl<$Res>
    implements _$RecordingConfigCopyWith<$Res> {
  __$RecordingConfigCopyWithImpl(this._self, this._then);

  final _RecordingConfig _self;
  final $Res Function(_RecordingConfig) _then;

  /// Create a copy of RecordingConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? defaultSource = null,
    Object? titleFormat = null,
    Object? systemAudioMicGain = null,
    Object? systemAudioDuckingRatio = null,
    Object? keepLocalAudioDefault = null,
    Object? audioFileExtension = null,
    Object? audioUploadFileName = null,
    Object? audioContentType = null,
    Object? segmentContentType = null,
    Object? recordingsDirName = null,
    Object? pendingQueueDirName = null,
    Object? stopDrainTimeoutMs = null,
    Object? waveformBars = null,
    Object? transcriptScrollAnimationMs = null,
    Object? notificationChannelId = null,
    Object? foregroundServiceId = null,
  }) {
    return _then(
      _RecordingConfig(
        defaultSource: null == defaultSource
            ? _self.defaultSource
            : defaultSource // ignore: cast_nullable_to_non_nullable
                  as RecordingSource,
        titleFormat: null == titleFormat
            ? _self.titleFormat
            : titleFormat // ignore: cast_nullable_to_non_nullable
                  as String,
        systemAudioMicGain: null == systemAudioMicGain
            ? _self.systemAudioMicGain
            : systemAudioMicGain // ignore: cast_nullable_to_non_nullable
                  as double,
        systemAudioDuckingRatio: null == systemAudioDuckingRatio
            ? _self.systemAudioDuckingRatio
            : systemAudioDuckingRatio // ignore: cast_nullable_to_non_nullable
                  as double,
        keepLocalAudioDefault: null == keepLocalAudioDefault
            ? _self.keepLocalAudioDefault
            : keepLocalAudioDefault // ignore: cast_nullable_to_non_nullable
                  as bool,
        audioFileExtension: null == audioFileExtension
            ? _self.audioFileExtension
            : audioFileExtension // ignore: cast_nullable_to_non_nullable
                  as String,
        audioUploadFileName: null == audioUploadFileName
            ? _self.audioUploadFileName
            : audioUploadFileName // ignore: cast_nullable_to_non_nullable
                  as String,
        audioContentType: null == audioContentType
            ? _self.audioContentType
            : audioContentType // ignore: cast_nullable_to_non_nullable
                  as String,
        segmentContentType: null == segmentContentType
            ? _self.segmentContentType
            : segmentContentType // ignore: cast_nullable_to_non_nullable
                  as String,
        recordingsDirName: null == recordingsDirName
            ? _self.recordingsDirName
            : recordingsDirName // ignore: cast_nullable_to_non_nullable
                  as String,
        pendingQueueDirName: null == pendingQueueDirName
            ? _self.pendingQueueDirName
            : pendingQueueDirName // ignore: cast_nullable_to_non_nullable
                  as String,
        stopDrainTimeoutMs: null == stopDrainTimeoutMs
            ? _self.stopDrainTimeoutMs
            : stopDrainTimeoutMs // ignore: cast_nullable_to_non_nullable
                  as int,
        waveformBars: null == waveformBars
            ? _self.waveformBars
            : waveformBars // ignore: cast_nullable_to_non_nullable
                  as int,
        transcriptScrollAnimationMs: null == transcriptScrollAnimationMs
            ? _self.transcriptScrollAnimationMs
            : transcriptScrollAnimationMs // ignore: cast_nullable_to_non_nullable
                  as int,
        notificationChannelId: null == notificationChannelId
            ? _self.notificationChannelId
            : notificationChannelId // ignore: cast_nullable_to_non_nullable
                  as String,
        foregroundServiceId: null == foregroundServiceId
            ? _self.foregroundServiceId
            : foregroundServiceId // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
mixin _$FeatureFlags {
  bool get systemAudioCapture;
  bool get importAudio;
  bool get autoSummaryDefault;

  /// Show the `dev_code` returned by `sms/send` (dev servers only).
  bool get showDevCode;
  bool get standaloneMessages;

  /// Create a copy of FeatureFlags
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $FeatureFlagsCopyWith<FeatureFlags> get copyWith =>
      _$FeatureFlagsCopyWithImpl<FeatureFlags>(
        this as FeatureFlags,
        _$identity,
      );

  /// Serializes this FeatureFlags to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as FeatureFlags;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is FeatureFlags &&
            (identical(other.systemAudioCapture, _this.systemAudioCapture) ||
                other.systemAudioCapture == _this.systemAudioCapture) &&
            (identical(other.importAudio, _this.importAudio) ||
                other.importAudio == _this.importAudio) &&
            (identical(other.autoSummaryDefault, _this.autoSummaryDefault) ||
                other.autoSummaryDefault == _this.autoSummaryDefault) &&
            (identical(other.showDevCode, _this.showDevCode) ||
                other.showDevCode == _this.showDevCode) &&
            (identical(other.standaloneMessages, _this.standaloneMessages) ||
                other.standaloneMessages == _this.standaloneMessages));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as FeatureFlags;
    return Object.hash(
      runtimeType,
      _this.systemAudioCapture,
      _this.importAudio,
      _this.autoSummaryDefault,
      _this.showDevCode,
      _this.standaloneMessages,
    );
  }

  @override
  String toString() {
    final _this = this as FeatureFlags;
    return 'FeatureFlags(systemAudioCapture: ${_this.systemAudioCapture}, importAudio: ${_this.importAudio}, autoSummaryDefault: ${_this.autoSummaryDefault}, showDevCode: ${_this.showDevCode}, standaloneMessages: ${_this.standaloneMessages})';
  }
}

/// @nodoc
abstract mixin class $FeatureFlagsCopyWith<$Res> {
  factory $FeatureFlagsCopyWith(
    FeatureFlags value,
    $Res Function(FeatureFlags) _then,
  ) = _$FeatureFlagsCopyWithImpl;
  @useResult
  $Res call({
    bool systemAudioCapture,
    bool importAudio,
    bool autoSummaryDefault,
    bool showDevCode,
    bool standaloneMessages,
  });
}

/// @nodoc
class _$FeatureFlagsCopyWithImpl<$Res> implements $FeatureFlagsCopyWith<$Res> {
  _$FeatureFlagsCopyWithImpl(this._self, this._then);

  final FeatureFlags _self;
  final $Res Function(FeatureFlags) _then;

  /// Create a copy of FeatureFlags
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? systemAudioCapture = null,
    Object? importAudio = null,
    Object? autoSummaryDefault = null,
    Object? showDevCode = null,
    Object? standaloneMessages = null,
  }) {
    return _then(
      FeatureFlags(
        systemAudioCapture: null == systemAudioCapture
            ? _self.systemAudioCapture
            : systemAudioCapture // ignore: cast_nullable_to_non_nullable
                  as bool,
        importAudio: null == importAudio
            ? _self.importAudio
            : importAudio // ignore: cast_nullable_to_non_nullable
                  as bool,
        autoSummaryDefault: null == autoSummaryDefault
            ? _self.autoSummaryDefault
            : autoSummaryDefault // ignore: cast_nullable_to_non_nullable
                  as bool,
        showDevCode: null == showDevCode
            ? _self.showDevCode
            : showDevCode // ignore: cast_nullable_to_non_nullable
                  as bool,
        standaloneMessages: null == standaloneMessages
            ? _self.standaloneMessages
            : standaloneMessages // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [FeatureFlags].
extension FeatureFlagsPatterns on FeatureFlags {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_FeatureFlags value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _FeatureFlags() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_FeatureFlags value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FeatureFlags():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_FeatureFlags value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FeatureFlags() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
      bool systemAudioCapture,
      bool importAudio,
      bool autoSummaryDefault,
      bool showDevCode,
      bool standaloneMessages,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _FeatureFlags() when $default != null:
        return $default(
          _that.systemAudioCapture,
          _that.importAudio,
          _that.autoSummaryDefault,
          _that.showDevCode,
          _that.standaloneMessages,
        );
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
      bool systemAudioCapture,
      bool importAudio,
      bool autoSummaryDefault,
      bool showDevCode,
      bool standaloneMessages,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FeatureFlags():
        return $default(
          _that.systemAudioCapture,
          _that.importAudio,
          _that.autoSummaryDefault,
          _that.showDevCode,
          _that.standaloneMessages,
        );
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
      bool systemAudioCapture,
      bool importAudio,
      bool autoSummaryDefault,
      bool showDevCode,
      bool standaloneMessages,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FeatureFlags() when $default != null:
        return $default(
          _that.systemAudioCapture,
          _that.importAudio,
          _that.autoSummaryDefault,
          _that.showDevCode,
          _that.standaloneMessages,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _FeatureFlags implements FeatureFlags {
  const _FeatureFlags({
    required this.systemAudioCapture,
    required this.importAudio,
    required this.autoSummaryDefault,
    required this.showDevCode,
    required this.standaloneMessages,
  });
  factory _FeatureFlags.fromJson(Map<String, dynamic> json) =>
      _$FeatureFlagsFromJson(json);

  @override
  final bool systemAudioCapture;
  @override
  final bool importAudio;
  @override
  final bool autoSummaryDefault;

  /// Show the `dev_code` returned by `sms/send` (dev servers only).
  @override
  final bool showDevCode;
  @override
  final bool standaloneMessages;

  /// Create a copy of FeatureFlags
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$FeatureFlagsCopyWith<_FeatureFlags> get copyWith =>
      __$FeatureFlagsCopyWithImpl<_FeatureFlags>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$FeatureFlagsToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _FeatureFlags &&
            (identical(other.systemAudioCapture, systemAudioCapture) ||
                other.systemAudioCapture == systemAudioCapture) &&
            (identical(other.importAudio, importAudio) ||
                other.importAudio == importAudio) &&
            (identical(other.autoSummaryDefault, autoSummaryDefault) ||
                other.autoSummaryDefault == autoSummaryDefault) &&
            (identical(other.showDevCode, showDevCode) ||
                other.showDevCode == showDevCode) &&
            (identical(other.standaloneMessages, standaloneMessages) ||
                other.standaloneMessages == standaloneMessages));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(
      runtimeType,
      systemAudioCapture,
      importAudio,
      autoSummaryDefault,
      showDevCode,
      standaloneMessages,
    );
  }

  @override
  String toString() {
    return 'FeatureFlags(systemAudioCapture: $systemAudioCapture, importAudio: $importAudio, autoSummaryDefault: $autoSummaryDefault, showDevCode: $showDevCode, standaloneMessages: $standaloneMessages)';
  }
}

/// @nodoc
abstract mixin class _$FeatureFlagsCopyWith<$Res>
    implements $FeatureFlagsCopyWith<$Res> {
  factory _$FeatureFlagsCopyWith(
    _FeatureFlags value,
    $Res Function(_FeatureFlags) _then,
  ) = __$FeatureFlagsCopyWithImpl;
  @override
  @useResult
  $Res call({
    bool systemAudioCapture,
    bool importAudio,
    bool autoSummaryDefault,
    bool showDevCode,
    bool standaloneMessages,
  });
}

/// @nodoc
class __$FeatureFlagsCopyWithImpl<$Res>
    implements _$FeatureFlagsCopyWith<$Res> {
  __$FeatureFlagsCopyWithImpl(this._self, this._then);

  final _FeatureFlags _self;
  final $Res Function(_FeatureFlags) _then;

  /// Create a copy of FeatureFlags
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? systemAudioCapture = null,
    Object? importAudio = null,
    Object? autoSummaryDefault = null,
    Object? showDevCode = null,
    Object? standaloneMessages = null,
  }) {
    return _then(
      _FeatureFlags(
        systemAudioCapture: null == systemAudioCapture
            ? _self.systemAudioCapture
            : systemAudioCapture // ignore: cast_nullable_to_non_nullable
                  as bool,
        importAudio: null == importAudio
            ? _self.importAudio
            : importAudio // ignore: cast_nullable_to_non_nullable
                  as bool,
        autoSummaryDefault: null == autoSummaryDefault
            ? _self.autoSummaryDefault
            : autoSummaryDefault // ignore: cast_nullable_to_non_nullable
                  as bool,
        showDevCode: null == showDevCode
            ? _self.showDevCode
            : showDevCode // ignore: cast_nullable_to_non_nullable
                  as bool,
        standaloneMessages: null == standaloneMessages
            ? _self.standaloneMessages
            : standaloneMessages // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
mixin _$UiConfig {
  LocaleMode get defaultLocaleMode;
  int get snackBarDurationMs;

  /// Create a copy of UiConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $UiConfigCopyWith<UiConfig> get copyWith =>
      _$UiConfigCopyWithImpl<UiConfig>(this as UiConfig, _$identity);

  /// Serializes this UiConfig to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as UiConfig;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is UiConfig &&
            (identical(other.defaultLocaleMode, _this.defaultLocaleMode) ||
                other.defaultLocaleMode == _this.defaultLocaleMode) &&
            (identical(other.snackBarDurationMs, _this.snackBarDurationMs) ||
                other.snackBarDurationMs == _this.snackBarDurationMs));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as UiConfig;
    return Object.hash(
      runtimeType,
      _this.defaultLocaleMode,
      _this.snackBarDurationMs,
    );
  }

  @override
  String toString() {
    final _this = this as UiConfig;
    return 'UiConfig(defaultLocaleMode: ${_this.defaultLocaleMode}, snackBarDurationMs: ${_this.snackBarDurationMs})';
  }
}

/// @nodoc
abstract mixin class $UiConfigCopyWith<$Res> {
  factory $UiConfigCopyWith(UiConfig value, $Res Function(UiConfig) _then) =
      _$UiConfigCopyWithImpl;
  @useResult
  $Res call({LocaleMode defaultLocaleMode, int snackBarDurationMs});
}

/// @nodoc
class _$UiConfigCopyWithImpl<$Res> implements $UiConfigCopyWith<$Res> {
  _$UiConfigCopyWithImpl(this._self, this._then);

  final UiConfig _self;
  final $Res Function(UiConfig) _then;

  /// Create a copy of UiConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? defaultLocaleMode = null,
    Object? snackBarDurationMs = null,
  }) {
    return _then(
      UiConfig(
        defaultLocaleMode: null == defaultLocaleMode
            ? _self.defaultLocaleMode
            : defaultLocaleMode // ignore: cast_nullable_to_non_nullable
                  as LocaleMode,
        snackBarDurationMs: null == snackBarDurationMs
            ? _self.snackBarDurationMs
            : snackBarDurationMs // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [UiConfig].
extension UiConfigPatterns on UiConfig {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_UiConfig value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _UiConfig() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_UiConfig value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UiConfig():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_UiConfig value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UiConfig() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(LocaleMode defaultLocaleMode, int snackBarDurationMs)?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _UiConfig() when $default != null:
        return $default(_that.defaultLocaleMode, _that.snackBarDurationMs);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(LocaleMode defaultLocaleMode, int snackBarDurationMs)
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UiConfig():
        return $default(_that.defaultLocaleMode, _that.snackBarDurationMs);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(LocaleMode defaultLocaleMode, int snackBarDurationMs)?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UiConfig() when $default != null:
        return $default(_that.defaultLocaleMode, _that.snackBarDurationMs);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _UiConfig extends UiConfig {
  const _UiConfig({
    required this.defaultLocaleMode,
    required this.snackBarDurationMs,
  }) : super._();
  factory _UiConfig.fromJson(Map<String, dynamic> json) =>
      _$UiConfigFromJson(json);

  @override
  final LocaleMode defaultLocaleMode;
  @override
  final int snackBarDurationMs;

  /// Create a copy of UiConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$UiConfigCopyWith<_UiConfig> get copyWith =>
      __$UiConfigCopyWithImpl<_UiConfig>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$UiConfigToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _UiConfig &&
            (identical(other.defaultLocaleMode, defaultLocaleMode) ||
                other.defaultLocaleMode == defaultLocaleMode) &&
            (identical(other.snackBarDurationMs, snackBarDurationMs) ||
                other.snackBarDurationMs == snackBarDurationMs));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(runtimeType, defaultLocaleMode, snackBarDurationMs);
  }

  @override
  String toString() {
    return 'UiConfig(defaultLocaleMode: $defaultLocaleMode, snackBarDurationMs: $snackBarDurationMs)';
  }
}

/// @nodoc
abstract mixin class _$UiConfigCopyWith<$Res>
    implements $UiConfigCopyWith<$Res> {
  factory _$UiConfigCopyWith(_UiConfig value, $Res Function(_UiConfig) _then) =
      __$UiConfigCopyWithImpl;
  @override
  @useResult
  $Res call({LocaleMode defaultLocaleMode, int snackBarDurationMs});
}

/// @nodoc
class __$UiConfigCopyWithImpl<$Res> implements _$UiConfigCopyWith<$Res> {
  __$UiConfigCopyWithImpl(this._self, this._then);

  final _UiConfig _self;
  final $Res Function(_UiConfig) _then;

  /// Create a copy of UiConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? defaultLocaleMode = null,
    Object? snackBarDurationMs = null,
  }) {
    return _then(
      _UiConfig(
        defaultLocaleMode: null == defaultLocaleMode
            ? _self.defaultLocaleMode
            : defaultLocaleMode // ignore: cast_nullable_to_non_nullable
                  as LocaleMode,
        snackBarDurationMs: null == snackBarDurationMs
            ? _self.snackBarDurationMs
            : snackBarDurationMs // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
mixin _$UpdateConfig {
  /// Minimum time between background update checks (start-up, resume, while in use).
  int get checkIntervalMin;

  /// An optional update is offered again after this long when the user chose "Later".
  int get promptCooldownHours;

  /// File name of the downloaded APK in the app cache (Android `direct` channel).
  String get apkFileName;

  /// Create a copy of UpdateConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $UpdateConfigCopyWith<UpdateConfig> get copyWith =>
      _$UpdateConfigCopyWithImpl<UpdateConfig>(
        this as UpdateConfig,
        _$identity,
      );

  /// Serializes this UpdateConfig to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as UpdateConfig;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is UpdateConfig &&
            (identical(other.checkIntervalMin, _this.checkIntervalMin) ||
                other.checkIntervalMin == _this.checkIntervalMin) &&
            (identical(other.promptCooldownHours, _this.promptCooldownHours) ||
                other.promptCooldownHours == _this.promptCooldownHours) &&
            (identical(other.apkFileName, _this.apkFileName) ||
                other.apkFileName == _this.apkFileName));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as UpdateConfig;
    return Object.hash(
      runtimeType,
      _this.checkIntervalMin,
      _this.promptCooldownHours,
      _this.apkFileName,
    );
  }

  @override
  String toString() {
    final _this = this as UpdateConfig;
    return 'UpdateConfig(checkIntervalMin: ${_this.checkIntervalMin}, promptCooldownHours: ${_this.promptCooldownHours}, apkFileName: ${_this.apkFileName})';
  }
}

/// @nodoc
abstract mixin class $UpdateConfigCopyWith<$Res> {
  factory $UpdateConfigCopyWith(
    UpdateConfig value,
    $Res Function(UpdateConfig) _then,
  ) = _$UpdateConfigCopyWithImpl;
  @useResult
  $Res call({
    int checkIntervalMin,
    int promptCooldownHours,
    String apkFileName,
  });
}

/// @nodoc
class _$UpdateConfigCopyWithImpl<$Res> implements $UpdateConfigCopyWith<$Res> {
  _$UpdateConfigCopyWithImpl(this._self, this._then);

  final UpdateConfig _self;
  final $Res Function(UpdateConfig) _then;

  /// Create a copy of UpdateConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? checkIntervalMin = null,
    Object? promptCooldownHours = null,
    Object? apkFileName = null,
  }) {
    return _then(
      UpdateConfig(
        checkIntervalMin: null == checkIntervalMin
            ? _self.checkIntervalMin
            : checkIntervalMin // ignore: cast_nullable_to_non_nullable
                  as int,
        promptCooldownHours: null == promptCooldownHours
            ? _self.promptCooldownHours
            : promptCooldownHours // ignore: cast_nullable_to_non_nullable
                  as int,
        apkFileName: null == apkFileName
            ? _self.apkFileName
            : apkFileName // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [UpdateConfig].
extension UpdateConfigPatterns on UpdateConfig {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_UpdateConfig value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _UpdateConfig() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_UpdateConfig value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UpdateConfig():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_UpdateConfig value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UpdateConfig() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
      int checkIntervalMin,
      int promptCooldownHours,
      String apkFileName,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _UpdateConfig() when $default != null:
        return $default(
          _that.checkIntervalMin,
          _that.promptCooldownHours,
          _that.apkFileName,
        );
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
      int checkIntervalMin,
      int promptCooldownHours,
      String apkFileName,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UpdateConfig():
        return $default(
          _that.checkIntervalMin,
          _that.promptCooldownHours,
          _that.apkFileName,
        );
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
      int checkIntervalMin,
      int promptCooldownHours,
      String apkFileName,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UpdateConfig() when $default != null:
        return $default(
          _that.checkIntervalMin,
          _that.promptCooldownHours,
          _that.apkFileName,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _UpdateConfig extends UpdateConfig {
  const _UpdateConfig({
    required this.checkIntervalMin,
    required this.promptCooldownHours,
    required this.apkFileName,
  }) : super._();
  factory _UpdateConfig.fromJson(Map<String, dynamic> json) =>
      _$UpdateConfigFromJson(json);

  /// Minimum time between background update checks (start-up, resume, while in use).
  @override
  final int checkIntervalMin;

  /// An optional update is offered again after this long when the user chose "Later".
  @override
  final int promptCooldownHours;

  /// File name of the downloaded APK in the app cache (Android `direct` channel).
  @override
  final String apkFileName;

  /// Create a copy of UpdateConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$UpdateConfigCopyWith<_UpdateConfig> get copyWith =>
      __$UpdateConfigCopyWithImpl<_UpdateConfig>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$UpdateConfigToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _UpdateConfig &&
            (identical(other.checkIntervalMin, checkIntervalMin) ||
                other.checkIntervalMin == checkIntervalMin) &&
            (identical(other.promptCooldownHours, promptCooldownHours) ||
                other.promptCooldownHours == promptCooldownHours) &&
            (identical(other.apkFileName, apkFileName) ||
                other.apkFileName == apkFileName));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(
      runtimeType,
      checkIntervalMin,
      promptCooldownHours,
      apkFileName,
    );
  }

  @override
  String toString() {
    return 'UpdateConfig(checkIntervalMin: $checkIntervalMin, promptCooldownHours: $promptCooldownHours, apkFileName: $apkFileName)';
  }
}

/// @nodoc
abstract mixin class _$UpdateConfigCopyWith<$Res>
    implements $UpdateConfigCopyWith<$Res> {
  factory _$UpdateConfigCopyWith(
    _UpdateConfig value,
    $Res Function(_UpdateConfig) _then,
  ) = __$UpdateConfigCopyWithImpl;
  @override
  @useResult
  $Res call({
    int checkIntervalMin,
    int promptCooldownHours,
    String apkFileName,
  });
}

/// @nodoc
class __$UpdateConfigCopyWithImpl<$Res>
    implements _$UpdateConfigCopyWith<$Res> {
  __$UpdateConfigCopyWithImpl(this._self, this._then);

  final _UpdateConfig _self;
  final $Res Function(_UpdateConfig) _then;

  /// Create a copy of UpdateConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? checkIntervalMin = null,
    Object? promptCooldownHours = null,
    Object? apkFileName = null,
  }) {
    return _then(
      _UpdateConfig(
        checkIntervalMin: null == checkIntervalMin
            ? _self.checkIntervalMin
            : checkIntervalMin // ignore: cast_nullable_to_non_nullable
                  as int,
        promptCooldownHours: null == promptCooldownHours
            ? _self.promptCooldownHours
            : promptCooldownHours // ignore: cast_nullable_to_non_nullable
                  as int,
        apkFileName: null == apkFileName
            ? _self.apkFileName
            : apkFileName // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
mixin _$PlayerConfig {
  /// Playback rates cycled by the speed button; the first one is the initial rate.
  List<double> get speeds;

  /// Seconds jumped by the back / forward buttons.
  int get skipSeconds;

  /// Create a copy of PlayerConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PlayerConfigCopyWith<PlayerConfig> get copyWith =>
      _$PlayerConfigCopyWithImpl<PlayerConfig>(
        this as PlayerConfig,
        _$identity,
      );

  /// Serializes this PlayerConfig to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as PlayerConfig;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PlayerConfig &&
            const DeepCollectionEquality().equals(other.speeds, _this.speeds) &&
            (identical(other.skipSeconds, _this.skipSeconds) ||
                other.skipSeconds == _this.skipSeconds));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as PlayerConfig;
    return Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_this.speeds),
      _this.skipSeconds,
    );
  }

  @override
  String toString() {
    final _this = this as PlayerConfig;
    return 'PlayerConfig(speeds: ${_this.speeds}, skipSeconds: ${_this.skipSeconds})';
  }
}

/// @nodoc
abstract mixin class $PlayerConfigCopyWith<$Res> {
  factory $PlayerConfigCopyWith(
    PlayerConfig value,
    $Res Function(PlayerConfig) _then,
  ) = _$PlayerConfigCopyWithImpl;
  @useResult
  $Res call({List<double> speeds, int skipSeconds});
}

/// @nodoc
class _$PlayerConfigCopyWithImpl<$Res> implements $PlayerConfigCopyWith<$Res> {
  _$PlayerConfigCopyWithImpl(this._self, this._then);

  final PlayerConfig _self;
  final $Res Function(PlayerConfig) _then;

  /// Create a copy of PlayerConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? speeds = null, Object? skipSeconds = null}) {
    return _then(
      PlayerConfig(
        speeds: null == speeds
            ? _self.speeds
            : speeds // ignore: cast_nullable_to_non_nullable
                  as List<double>,
        skipSeconds: null == skipSeconds
            ? _self.skipSeconds
            : skipSeconds // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [PlayerConfig].
extension PlayerConfigPatterns on PlayerConfig {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_PlayerConfig value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PlayerConfig() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_PlayerConfig value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PlayerConfig():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_PlayerConfig value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PlayerConfig() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(List<double> speeds, int skipSeconds)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PlayerConfig() when $default != null:
        return $default(_that.speeds, _that.skipSeconds);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(List<double> speeds, int skipSeconds) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PlayerConfig():
        return $default(_that.speeds, _that.skipSeconds);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(List<double> speeds, int skipSeconds)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PlayerConfig() when $default != null:
        return $default(_that.speeds, _that.skipSeconds);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _PlayerConfig extends PlayerConfig {
  const _PlayerConfig({required List<double> speeds, required this.skipSeconds})
    : _speeds = speeds,
      super._();
  factory _PlayerConfig.fromJson(Map<String, dynamic> json) =>
      _$PlayerConfigFromJson(json);

  /// Playback rates cycled by the speed button; the first one is the initial rate.
  final List<double> _speeds;

  /// Playback rates cycled by the speed button; the first one is the initial rate.
  @override
  List<double> get speeds {
    if (_speeds is EqualUnmodifiableListView) return _speeds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_speeds);
  }

  /// Seconds jumped by the back / forward buttons.
  @override
  final int skipSeconds;

  /// Create a copy of PlayerConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PlayerConfigCopyWith<_PlayerConfig> get copyWith =>
      __$PlayerConfigCopyWithImpl<_PlayerConfig>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$PlayerConfigToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PlayerConfig &&
            const DeepCollectionEquality().equals(other.speeds, _speeds) &&
            (identical(other.skipSeconds, skipSeconds) ||
                other.skipSeconds == skipSeconds));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_speeds),
      skipSeconds,
    );
  }

  @override
  String toString() {
    return 'PlayerConfig(speeds: $speeds, skipSeconds: $skipSeconds)';
  }
}

/// @nodoc
abstract mixin class _$PlayerConfigCopyWith<$Res>
    implements $PlayerConfigCopyWith<$Res> {
  factory _$PlayerConfigCopyWith(
    _PlayerConfig value,
    $Res Function(_PlayerConfig) _then,
  ) = __$PlayerConfigCopyWithImpl;
  @override
  @useResult
  $Res call({List<double> speeds, int skipSeconds});
}

/// @nodoc
class __$PlayerConfigCopyWithImpl<$Res>
    implements _$PlayerConfigCopyWith<$Res> {
  __$PlayerConfigCopyWithImpl(this._self, this._then);

  final _PlayerConfig _self;
  final $Res Function(_PlayerConfig) _then;

  /// Create a copy of PlayerConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({Object? speeds = null, Object? skipSeconds = null}) {
    return _then(
      _PlayerConfig(
        speeds: null == speeds
            ? _self._speeds
            : speeds // ignore: cast_nullable_to_non_nullable
                  as List<double>,
        skipSeconds: null == skipSeconds
            ? _self.skipSeconds
            : skipSeconds // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
mixin _$ImportFileConfig {
  /// File extensions (no dot) offered by the picker (desktop `AUDIO_EXTENSIONS`).
  List<String> get allowedExtensions;

  /// Create a copy of ImportFileConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ImportFileConfigCopyWith<ImportFileConfig> get copyWith =>
      _$ImportFileConfigCopyWithImpl<ImportFileConfig>(
        this as ImportFileConfig,
        _$identity,
      );

  /// Serializes this ImportFileConfig to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as ImportFileConfig;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ImportFileConfig &&
            const DeepCollectionEquality().equals(
              other.allowedExtensions,
              _this.allowedExtensions,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as ImportFileConfig;
    return Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_this.allowedExtensions),
    );
  }

  @override
  String toString() {
    final _this = this as ImportFileConfig;
    return 'ImportFileConfig(allowedExtensions: ${_this.allowedExtensions})';
  }
}

/// @nodoc
abstract mixin class $ImportFileConfigCopyWith<$Res> {
  factory $ImportFileConfigCopyWith(
    ImportFileConfig value,
    $Res Function(ImportFileConfig) _then,
  ) = _$ImportFileConfigCopyWithImpl;
  @useResult
  $Res call({List<String> allowedExtensions});
}

/// @nodoc
class _$ImportFileConfigCopyWithImpl<$Res>
    implements $ImportFileConfigCopyWith<$Res> {
  _$ImportFileConfigCopyWithImpl(this._self, this._then);

  final ImportFileConfig _self;
  final $Res Function(ImportFileConfig) _then;

  /// Create a copy of ImportFileConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? allowedExtensions = null}) {
    return _then(
      ImportFileConfig(
        allowedExtensions: null == allowedExtensions
            ? _self.allowedExtensions
            : allowedExtensions // ignore: cast_nullable_to_non_nullable
                  as List<String>,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [ImportFileConfig].
extension ImportFileConfigPatterns on ImportFileConfig {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_ImportFileConfig value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ImportFileConfig() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_ImportFileConfig value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ImportFileConfig():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_ImportFileConfig value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ImportFileConfig() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(List<String> allowedExtensions)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ImportFileConfig() when $default != null:
        return $default(_that.allowedExtensions);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(List<String> allowedExtensions) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ImportFileConfig():
        return $default(_that.allowedExtensions);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(List<String> allowedExtensions)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ImportFileConfig() when $default != null:
        return $default(_that.allowedExtensions);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _ImportFileConfig implements ImportFileConfig {
  const _ImportFileConfig({required List<String> allowedExtensions})
    : _allowedExtensions = allowedExtensions;
  factory _ImportFileConfig.fromJson(Map<String, dynamic> json) =>
      _$ImportFileConfigFromJson(json);

  /// File extensions (no dot) offered by the picker (desktop `AUDIO_EXTENSIONS`).
  final List<String> _allowedExtensions;

  /// File extensions (no dot) offered by the picker (desktop `AUDIO_EXTENSIONS`).
  @override
  List<String> get allowedExtensions {
    if (_allowedExtensions is EqualUnmodifiableListView)
      return _allowedExtensions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_allowedExtensions);
  }

  /// Create a copy of ImportFileConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ImportFileConfigCopyWith<_ImportFileConfig> get copyWith =>
      __$ImportFileConfigCopyWithImpl<_ImportFileConfig>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ImportFileConfigToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ImportFileConfig &&
            const DeepCollectionEquality().equals(
              other.allowedExtensions,
              _allowedExtensions,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_allowedExtensions),
    );
  }

  @override
  String toString() {
    return 'ImportFileConfig(allowedExtensions: $allowedExtensions)';
  }
}

/// @nodoc
abstract mixin class _$ImportFileConfigCopyWith<$Res>
    implements $ImportFileConfigCopyWith<$Res> {
  factory _$ImportFileConfigCopyWith(
    _ImportFileConfig value,
    $Res Function(_ImportFileConfig) _then,
  ) = __$ImportFileConfigCopyWithImpl;
  @override
  @useResult
  $Res call({List<String> allowedExtensions});
}

/// @nodoc
class __$ImportFileConfigCopyWithImpl<$Res>
    implements _$ImportFileConfigCopyWith<$Res> {
  __$ImportFileConfigCopyWithImpl(this._self, this._then);

  final _ImportFileConfig _self;
  final $Res Function(_ImportFileConfig) _then;

  /// Create a copy of ImportFileConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({Object? allowedExtensions = null}) {
    return _then(
      _ImportFileConfig(
        allowedExtensions: null == allowedExtensions
            ? _self._allowedExtensions
            : allowedExtensions // ignore: cast_nullable_to_non_nullable
                  as List<String>,
      ),
    );
  }
}

/// @nodoc
mixin _$MeetingsUiConfig {
  /// Dates younger than this many days are shown relative ("3 days ago"), older ones absolute.
  int get relativeDateMaxDays;

  /// Create a copy of MeetingsUiConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $MeetingsUiConfigCopyWith<MeetingsUiConfig> get copyWith =>
      _$MeetingsUiConfigCopyWithImpl<MeetingsUiConfig>(
        this as MeetingsUiConfig,
        _$identity,
      );

  /// Serializes this MeetingsUiConfig to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as MeetingsUiConfig;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MeetingsUiConfig &&
            (identical(other.relativeDateMaxDays, _this.relativeDateMaxDays) ||
                other.relativeDateMaxDays == _this.relativeDateMaxDays));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as MeetingsUiConfig;
    return Object.hash(runtimeType, _this.relativeDateMaxDays);
  }

  @override
  String toString() {
    final _this = this as MeetingsUiConfig;
    return 'MeetingsUiConfig(relativeDateMaxDays: ${_this.relativeDateMaxDays})';
  }
}

/// @nodoc
abstract mixin class $MeetingsUiConfigCopyWith<$Res> {
  factory $MeetingsUiConfigCopyWith(
    MeetingsUiConfig value,
    $Res Function(MeetingsUiConfig) _then,
  ) = _$MeetingsUiConfigCopyWithImpl;
  @useResult
  $Res call({int relativeDateMaxDays});
}

/// @nodoc
class _$MeetingsUiConfigCopyWithImpl<$Res>
    implements $MeetingsUiConfigCopyWith<$Res> {
  _$MeetingsUiConfigCopyWithImpl(this._self, this._then);

  final MeetingsUiConfig _self;
  final $Res Function(MeetingsUiConfig) _then;

  /// Create a copy of MeetingsUiConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? relativeDateMaxDays = null}) {
    return _then(
      MeetingsUiConfig(
        relativeDateMaxDays: null == relativeDateMaxDays
            ? _self.relativeDateMaxDays
            : relativeDateMaxDays // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [MeetingsUiConfig].
extension MeetingsUiConfigPatterns on MeetingsUiConfig {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_MeetingsUiConfig value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _MeetingsUiConfig() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_MeetingsUiConfig value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MeetingsUiConfig():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_MeetingsUiConfig value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MeetingsUiConfig() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(int relativeDateMaxDays)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _MeetingsUiConfig() when $default != null:
        return $default(_that.relativeDateMaxDays);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(int relativeDateMaxDays) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MeetingsUiConfig():
        return $default(_that.relativeDateMaxDays);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(int relativeDateMaxDays)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MeetingsUiConfig() when $default != null:
        return $default(_that.relativeDateMaxDays);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _MeetingsUiConfig implements MeetingsUiConfig {
  const _MeetingsUiConfig({required this.relativeDateMaxDays});
  factory _MeetingsUiConfig.fromJson(Map<String, dynamic> json) =>
      _$MeetingsUiConfigFromJson(json);

  /// Dates younger than this many days are shown relative ("3 days ago"), older ones absolute.
  @override
  final int relativeDateMaxDays;

  /// Create a copy of MeetingsUiConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$MeetingsUiConfigCopyWith<_MeetingsUiConfig> get copyWith =>
      __$MeetingsUiConfigCopyWithImpl<_MeetingsUiConfig>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$MeetingsUiConfigToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _MeetingsUiConfig &&
            (identical(other.relativeDateMaxDays, relativeDateMaxDays) ||
                other.relativeDateMaxDays == relativeDateMaxDays));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(runtimeType, relativeDateMaxDays);
  }

  @override
  String toString() {
    return 'MeetingsUiConfig(relativeDateMaxDays: $relativeDateMaxDays)';
  }
}

/// @nodoc
abstract mixin class _$MeetingsUiConfigCopyWith<$Res>
    implements $MeetingsUiConfigCopyWith<$Res> {
  factory _$MeetingsUiConfigCopyWith(
    _MeetingsUiConfig value,
    $Res Function(_MeetingsUiConfig) _then,
  ) = __$MeetingsUiConfigCopyWithImpl;
  @override
  @useResult
  $Res call({int relativeDateMaxDays});
}

/// @nodoc
class __$MeetingsUiConfigCopyWithImpl<$Res>
    implements _$MeetingsUiConfigCopyWith<$Res> {
  __$MeetingsUiConfigCopyWithImpl(this._self, this._then);

  final _MeetingsUiConfig _self;
  final $Res Function(_MeetingsUiConfig) _then;

  /// Create a copy of MeetingsUiConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({Object? relativeDateMaxDays = null}) {
    return _then(
      _MeetingsUiConfig(
        relativeDateMaxDays: null == relativeDateMaxDays
            ? _self.relativeDateMaxDays
            : relativeDateMaxDays // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
mixin _$SystemAudioConfig {
  /// Mixer frame duration (ms).
  int get frameMs;

  /// Mixer latency absorbing bursty delivery of the system/mic inputs (ms).
  int get jitterBufferMs;

  /// Per-input backlog cap; older samples are dropped beyond it (ms).
  int get maxBufferMs;

  /// Mic RMS (0..1) above which system audio is ducked.
  double get micActiveRmsThreshold;
  int get duckingAttackMs;
  int get duckingReleaseMs;

  /// Soft-clip knee (0..1) for the mixed signal.
  double get softClipKnee;

  /// dBFS mapped to level 0 for the level meter.
  double get levelFloorDb;

  /// Android AudioPlaybackCapture usages: `media`, `game`, `unknown`.
  List<String> get androidCaptureUsages;

  /// Android mic source: `voiceRecognition` | `mic` | `voiceCommunication` | `camcorder`.
  String get androidMicSource;

  /// Capture rate used when the device refuses `audio.sampleRate` directly.
  int get androidFallbackCaptureSampleRate;
  String get androidNotificationChannelId;
  int get androidNotificationId;

  /// iOS broadcast extension chunk length (ms).
  int get iosChunkMs;

  /// iOS: wait this long for the user to start the broadcast before giving up.
  int get iosStartTimeoutMs;

  /// iOS: wait this long for the extension to confirm it stopped.
  int get iosStopTimeoutMs;
  int get iosPollIntervalMs;

  /// iOS: unread chunks the extension keeps before dropping the oldest.
  int get iosMaxPendingChunks;

  /// iOS: keep the app running in the background with a silent audio session while capturing.
  bool get iosKeepAliveInBackground;

  /// Create a copy of SystemAudioConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SystemAudioConfigCopyWith<SystemAudioConfig> get copyWith =>
      _$SystemAudioConfigCopyWithImpl<SystemAudioConfig>(
        this as SystemAudioConfig,
        _$identity,
      );

  /// Serializes this SystemAudioConfig to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as SystemAudioConfig;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SystemAudioConfig &&
            (identical(other.frameMs, _this.frameMs) ||
                other.frameMs == _this.frameMs) &&
            (identical(other.jitterBufferMs, _this.jitterBufferMs) ||
                other.jitterBufferMs == _this.jitterBufferMs) &&
            (identical(other.maxBufferMs, _this.maxBufferMs) ||
                other.maxBufferMs == _this.maxBufferMs) &&
            (identical(
                  other.micActiveRmsThreshold,
                  _this.micActiveRmsThreshold,
                ) ||
                other.micActiveRmsThreshold == _this.micActiveRmsThreshold) &&
            (identical(other.duckingAttackMs, _this.duckingAttackMs) ||
                other.duckingAttackMs == _this.duckingAttackMs) &&
            (identical(other.duckingReleaseMs, _this.duckingReleaseMs) ||
                other.duckingReleaseMs == _this.duckingReleaseMs) &&
            (identical(other.softClipKnee, _this.softClipKnee) ||
                other.softClipKnee == _this.softClipKnee) &&
            (identical(other.levelFloorDb, _this.levelFloorDb) ||
                other.levelFloorDb == _this.levelFloorDb) &&
            const DeepCollectionEquality().equals(
              other.androidCaptureUsages,
              _this.androidCaptureUsages,
            ) &&
            (identical(other.androidMicSource, _this.androidMicSource) ||
                other.androidMicSource == _this.androidMicSource) &&
            (identical(
                  other.androidFallbackCaptureSampleRate,
                  _this.androidFallbackCaptureSampleRate,
                ) ||
                other.androidFallbackCaptureSampleRate ==
                    _this.androidFallbackCaptureSampleRate) &&
            (identical(
                  other.androidNotificationChannelId,
                  _this.androidNotificationChannelId,
                ) ||
                other.androidNotificationChannelId ==
                    _this.androidNotificationChannelId) &&
            (identical(
                  other.androidNotificationId,
                  _this.androidNotificationId,
                ) ||
                other.androidNotificationId == _this.androidNotificationId) &&
            (identical(other.iosChunkMs, _this.iosChunkMs) ||
                other.iosChunkMs == _this.iosChunkMs) &&
            (identical(other.iosStartTimeoutMs, _this.iosStartTimeoutMs) ||
                other.iosStartTimeoutMs == _this.iosStartTimeoutMs) &&
            (identical(other.iosStopTimeoutMs, _this.iosStopTimeoutMs) ||
                other.iosStopTimeoutMs == _this.iosStopTimeoutMs) &&
            (identical(other.iosPollIntervalMs, _this.iosPollIntervalMs) ||
                other.iosPollIntervalMs == _this.iosPollIntervalMs) &&
            (identical(other.iosMaxPendingChunks, _this.iosMaxPendingChunks) ||
                other.iosMaxPendingChunks == _this.iosMaxPendingChunks) &&
            (identical(
                  other.iosKeepAliveInBackground,
                  _this.iosKeepAliveInBackground,
                ) ||
                other.iosKeepAliveInBackground ==
                    _this.iosKeepAliveInBackground));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as SystemAudioConfig;
    return Object.hashAll([
      runtimeType,
      _this.frameMs,
      _this.jitterBufferMs,
      _this.maxBufferMs,
      _this.micActiveRmsThreshold,
      _this.duckingAttackMs,
      _this.duckingReleaseMs,
      _this.softClipKnee,
      _this.levelFloorDb,
      const DeepCollectionEquality().hash(_this.androidCaptureUsages),
      _this.androidMicSource,
      _this.androidFallbackCaptureSampleRate,
      _this.androidNotificationChannelId,
      _this.androidNotificationId,
      _this.iosChunkMs,
      _this.iosStartTimeoutMs,
      _this.iosStopTimeoutMs,
      _this.iosPollIntervalMs,
      _this.iosMaxPendingChunks,
      _this.iosKeepAliveInBackground,
    ]);
  }

  @override
  String toString() {
    final _this = this as SystemAudioConfig;
    return 'SystemAudioConfig(frameMs: ${_this.frameMs}, jitterBufferMs: ${_this.jitterBufferMs}, maxBufferMs: ${_this.maxBufferMs}, micActiveRmsThreshold: ${_this.micActiveRmsThreshold}, duckingAttackMs: ${_this.duckingAttackMs}, duckingReleaseMs: ${_this.duckingReleaseMs}, softClipKnee: ${_this.softClipKnee}, levelFloorDb: ${_this.levelFloorDb}, androidCaptureUsages: ${_this.androidCaptureUsages}, androidMicSource: ${_this.androidMicSource}, androidFallbackCaptureSampleRate: ${_this.androidFallbackCaptureSampleRate}, androidNotificationChannelId: ${_this.androidNotificationChannelId}, androidNotificationId: ${_this.androidNotificationId}, iosChunkMs: ${_this.iosChunkMs}, iosStartTimeoutMs: ${_this.iosStartTimeoutMs}, iosStopTimeoutMs: ${_this.iosStopTimeoutMs}, iosPollIntervalMs: ${_this.iosPollIntervalMs}, iosMaxPendingChunks: ${_this.iosMaxPendingChunks}, iosKeepAliveInBackground: ${_this.iosKeepAliveInBackground})';
  }
}

/// @nodoc
abstract mixin class $SystemAudioConfigCopyWith<$Res> {
  factory $SystemAudioConfigCopyWith(
    SystemAudioConfig value,
    $Res Function(SystemAudioConfig) _then,
  ) = _$SystemAudioConfigCopyWithImpl;
  @useResult
  $Res call({
    int frameMs,
    int jitterBufferMs,
    int maxBufferMs,
    double micActiveRmsThreshold,
    int duckingAttackMs,
    int duckingReleaseMs,
    double softClipKnee,
    double levelFloorDb,
    List<String> androidCaptureUsages,
    String androidMicSource,
    int androidFallbackCaptureSampleRate,
    String androidNotificationChannelId,
    int androidNotificationId,
    int iosChunkMs,
    int iosStartTimeoutMs,
    int iosStopTimeoutMs,
    int iosPollIntervalMs,
    int iosMaxPendingChunks,
    bool iosKeepAliveInBackground,
  });
}

/// @nodoc
class _$SystemAudioConfigCopyWithImpl<$Res>
    implements $SystemAudioConfigCopyWith<$Res> {
  _$SystemAudioConfigCopyWithImpl(this._self, this._then);

  final SystemAudioConfig _self;
  final $Res Function(SystemAudioConfig) _then;

  /// Create a copy of SystemAudioConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? frameMs = null,
    Object? jitterBufferMs = null,
    Object? maxBufferMs = null,
    Object? micActiveRmsThreshold = null,
    Object? duckingAttackMs = null,
    Object? duckingReleaseMs = null,
    Object? softClipKnee = null,
    Object? levelFloorDb = null,
    Object? androidCaptureUsages = null,
    Object? androidMicSource = null,
    Object? androidFallbackCaptureSampleRate = null,
    Object? androidNotificationChannelId = null,
    Object? androidNotificationId = null,
    Object? iosChunkMs = null,
    Object? iosStartTimeoutMs = null,
    Object? iosStopTimeoutMs = null,
    Object? iosPollIntervalMs = null,
    Object? iosMaxPendingChunks = null,
    Object? iosKeepAliveInBackground = null,
  }) {
    return _then(
      SystemAudioConfig(
        frameMs: null == frameMs
            ? _self.frameMs
            : frameMs // ignore: cast_nullable_to_non_nullable
                  as int,
        jitterBufferMs: null == jitterBufferMs
            ? _self.jitterBufferMs
            : jitterBufferMs // ignore: cast_nullable_to_non_nullable
                  as int,
        maxBufferMs: null == maxBufferMs
            ? _self.maxBufferMs
            : maxBufferMs // ignore: cast_nullable_to_non_nullable
                  as int,
        micActiveRmsThreshold: null == micActiveRmsThreshold
            ? _self.micActiveRmsThreshold
            : micActiveRmsThreshold // ignore: cast_nullable_to_non_nullable
                  as double,
        duckingAttackMs: null == duckingAttackMs
            ? _self.duckingAttackMs
            : duckingAttackMs // ignore: cast_nullable_to_non_nullable
                  as int,
        duckingReleaseMs: null == duckingReleaseMs
            ? _self.duckingReleaseMs
            : duckingReleaseMs // ignore: cast_nullable_to_non_nullable
                  as int,
        softClipKnee: null == softClipKnee
            ? _self.softClipKnee
            : softClipKnee // ignore: cast_nullable_to_non_nullable
                  as double,
        levelFloorDb: null == levelFloorDb
            ? _self.levelFloorDb
            : levelFloorDb // ignore: cast_nullable_to_non_nullable
                  as double,
        androidCaptureUsages: null == androidCaptureUsages
            ? _self.androidCaptureUsages
            : androidCaptureUsages // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        androidMicSource: null == androidMicSource
            ? _self.androidMicSource
            : androidMicSource // ignore: cast_nullable_to_non_nullable
                  as String,
        androidFallbackCaptureSampleRate:
            null == androidFallbackCaptureSampleRate
            ? _self.androidFallbackCaptureSampleRate
            : androidFallbackCaptureSampleRate // ignore: cast_nullable_to_non_nullable
                  as int,
        androidNotificationChannelId: null == androidNotificationChannelId
            ? _self.androidNotificationChannelId
            : androidNotificationChannelId // ignore: cast_nullable_to_non_nullable
                  as String,
        androidNotificationId: null == androidNotificationId
            ? _self.androidNotificationId
            : androidNotificationId // ignore: cast_nullable_to_non_nullable
                  as int,
        iosChunkMs: null == iosChunkMs
            ? _self.iosChunkMs
            : iosChunkMs // ignore: cast_nullable_to_non_nullable
                  as int,
        iosStartTimeoutMs: null == iosStartTimeoutMs
            ? _self.iosStartTimeoutMs
            : iosStartTimeoutMs // ignore: cast_nullable_to_non_nullable
                  as int,
        iosStopTimeoutMs: null == iosStopTimeoutMs
            ? _self.iosStopTimeoutMs
            : iosStopTimeoutMs // ignore: cast_nullable_to_non_nullable
                  as int,
        iosPollIntervalMs: null == iosPollIntervalMs
            ? _self.iosPollIntervalMs
            : iosPollIntervalMs // ignore: cast_nullable_to_non_nullable
                  as int,
        iosMaxPendingChunks: null == iosMaxPendingChunks
            ? _self.iosMaxPendingChunks
            : iosMaxPendingChunks // ignore: cast_nullable_to_non_nullable
                  as int,
        iosKeepAliveInBackground: null == iosKeepAliveInBackground
            ? _self.iosKeepAliveInBackground
            : iosKeepAliveInBackground // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [SystemAudioConfig].
extension SystemAudioConfigPatterns on SystemAudioConfig {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_SystemAudioConfig value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SystemAudioConfig() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_SystemAudioConfig value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SystemAudioConfig():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_SystemAudioConfig value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SystemAudioConfig() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
      int frameMs,
      int jitterBufferMs,
      int maxBufferMs,
      double micActiveRmsThreshold,
      int duckingAttackMs,
      int duckingReleaseMs,
      double softClipKnee,
      double levelFloorDb,
      List<String> androidCaptureUsages,
      String androidMicSource,
      int androidFallbackCaptureSampleRate,
      String androidNotificationChannelId,
      int androidNotificationId,
      int iosChunkMs,
      int iosStartTimeoutMs,
      int iosStopTimeoutMs,
      int iosPollIntervalMs,
      int iosMaxPendingChunks,
      bool iosKeepAliveInBackground,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SystemAudioConfig() when $default != null:
        return $default(
          _that.frameMs,
          _that.jitterBufferMs,
          _that.maxBufferMs,
          _that.micActiveRmsThreshold,
          _that.duckingAttackMs,
          _that.duckingReleaseMs,
          _that.softClipKnee,
          _that.levelFloorDb,
          _that.androidCaptureUsages,
          _that.androidMicSource,
          _that.androidFallbackCaptureSampleRate,
          _that.androidNotificationChannelId,
          _that.androidNotificationId,
          _that.iosChunkMs,
          _that.iosStartTimeoutMs,
          _that.iosStopTimeoutMs,
          _that.iosPollIntervalMs,
          _that.iosMaxPendingChunks,
          _that.iosKeepAliveInBackground,
        );
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
      int frameMs,
      int jitterBufferMs,
      int maxBufferMs,
      double micActiveRmsThreshold,
      int duckingAttackMs,
      int duckingReleaseMs,
      double softClipKnee,
      double levelFloorDb,
      List<String> androidCaptureUsages,
      String androidMicSource,
      int androidFallbackCaptureSampleRate,
      String androidNotificationChannelId,
      int androidNotificationId,
      int iosChunkMs,
      int iosStartTimeoutMs,
      int iosStopTimeoutMs,
      int iosPollIntervalMs,
      int iosMaxPendingChunks,
      bool iosKeepAliveInBackground,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SystemAudioConfig():
        return $default(
          _that.frameMs,
          _that.jitterBufferMs,
          _that.maxBufferMs,
          _that.micActiveRmsThreshold,
          _that.duckingAttackMs,
          _that.duckingReleaseMs,
          _that.softClipKnee,
          _that.levelFloorDb,
          _that.androidCaptureUsages,
          _that.androidMicSource,
          _that.androidFallbackCaptureSampleRate,
          _that.androidNotificationChannelId,
          _that.androidNotificationId,
          _that.iosChunkMs,
          _that.iosStartTimeoutMs,
          _that.iosStopTimeoutMs,
          _that.iosPollIntervalMs,
          _that.iosMaxPendingChunks,
          _that.iosKeepAliveInBackground,
        );
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
      int frameMs,
      int jitterBufferMs,
      int maxBufferMs,
      double micActiveRmsThreshold,
      int duckingAttackMs,
      int duckingReleaseMs,
      double softClipKnee,
      double levelFloorDb,
      List<String> androidCaptureUsages,
      String androidMicSource,
      int androidFallbackCaptureSampleRate,
      String androidNotificationChannelId,
      int androidNotificationId,
      int iosChunkMs,
      int iosStartTimeoutMs,
      int iosStopTimeoutMs,
      int iosPollIntervalMs,
      int iosMaxPendingChunks,
      bool iosKeepAliveInBackground,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SystemAudioConfig() when $default != null:
        return $default(
          _that.frameMs,
          _that.jitterBufferMs,
          _that.maxBufferMs,
          _that.micActiveRmsThreshold,
          _that.duckingAttackMs,
          _that.duckingReleaseMs,
          _that.softClipKnee,
          _that.levelFloorDb,
          _that.androidCaptureUsages,
          _that.androidMicSource,
          _that.androidFallbackCaptureSampleRate,
          _that.androidNotificationChannelId,
          _that.androidNotificationId,
          _that.iosChunkMs,
          _that.iosStartTimeoutMs,
          _that.iosStopTimeoutMs,
          _that.iosPollIntervalMs,
          _that.iosMaxPendingChunks,
          _that.iosKeepAliveInBackground,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _SystemAudioConfig implements SystemAudioConfig {
  const _SystemAudioConfig({
    required this.frameMs,
    required this.jitterBufferMs,
    required this.maxBufferMs,
    required this.micActiveRmsThreshold,
    required this.duckingAttackMs,
    required this.duckingReleaseMs,
    required this.softClipKnee,
    required this.levelFloorDb,
    required List<String> androidCaptureUsages,
    required this.androidMicSource,
    required this.androidFallbackCaptureSampleRate,
    required this.androidNotificationChannelId,
    required this.androidNotificationId,
    required this.iosChunkMs,
    required this.iosStartTimeoutMs,
    required this.iosStopTimeoutMs,
    required this.iosPollIntervalMs,
    required this.iosMaxPendingChunks,
    required this.iosKeepAliveInBackground,
  }) : _androidCaptureUsages = androidCaptureUsages;
  factory _SystemAudioConfig.fromJson(Map<String, dynamic> json) =>
      _$SystemAudioConfigFromJson(json);

  /// Mixer frame duration (ms).
  @override
  final int frameMs;

  /// Mixer latency absorbing bursty delivery of the system/mic inputs (ms).
  @override
  final int jitterBufferMs;

  /// Per-input backlog cap; older samples are dropped beyond it (ms).
  @override
  final int maxBufferMs;

  /// Mic RMS (0..1) above which system audio is ducked.
  @override
  final double micActiveRmsThreshold;
  @override
  final int duckingAttackMs;
  @override
  final int duckingReleaseMs;

  /// Soft-clip knee (0..1) for the mixed signal.
  @override
  final double softClipKnee;

  /// dBFS mapped to level 0 for the level meter.
  @override
  final double levelFloorDb;

  /// Android AudioPlaybackCapture usages: `media`, `game`, `unknown`.
  final List<String> _androidCaptureUsages;

  /// Android AudioPlaybackCapture usages: `media`, `game`, `unknown`.
  @override
  List<String> get androidCaptureUsages {
    if (_androidCaptureUsages is EqualUnmodifiableListView)
      return _androidCaptureUsages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_androidCaptureUsages);
  }

  /// Android mic source: `voiceRecognition` | `mic` | `voiceCommunication` | `camcorder`.
  @override
  final String androidMicSource;

  /// Capture rate used when the device refuses `audio.sampleRate` directly.
  @override
  final int androidFallbackCaptureSampleRate;
  @override
  final String androidNotificationChannelId;
  @override
  final int androidNotificationId;

  /// iOS broadcast extension chunk length (ms).
  @override
  final int iosChunkMs;

  /// iOS: wait this long for the user to start the broadcast before giving up.
  @override
  final int iosStartTimeoutMs;

  /// iOS: wait this long for the extension to confirm it stopped.
  @override
  final int iosStopTimeoutMs;
  @override
  final int iosPollIntervalMs;

  /// iOS: unread chunks the extension keeps before dropping the oldest.
  @override
  final int iosMaxPendingChunks;

  /// iOS: keep the app running in the background with a silent audio session while capturing.
  @override
  final bool iosKeepAliveInBackground;

  /// Create a copy of SystemAudioConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$SystemAudioConfigCopyWith<_SystemAudioConfig> get copyWith =>
      __$SystemAudioConfigCopyWithImpl<_SystemAudioConfig>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$SystemAudioConfigToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _SystemAudioConfig &&
            (identical(other.frameMs, frameMs) || other.frameMs == frameMs) &&
            (identical(other.jitterBufferMs, jitterBufferMs) ||
                other.jitterBufferMs == jitterBufferMs) &&
            (identical(other.maxBufferMs, maxBufferMs) ||
                other.maxBufferMs == maxBufferMs) &&
            (identical(other.micActiveRmsThreshold, micActiveRmsThreshold) ||
                other.micActiveRmsThreshold == micActiveRmsThreshold) &&
            (identical(other.duckingAttackMs, duckingAttackMs) ||
                other.duckingAttackMs == duckingAttackMs) &&
            (identical(other.duckingReleaseMs, duckingReleaseMs) ||
                other.duckingReleaseMs == duckingReleaseMs) &&
            (identical(other.softClipKnee, softClipKnee) ||
                other.softClipKnee == softClipKnee) &&
            (identical(other.levelFloorDb, levelFloorDb) ||
                other.levelFloorDb == levelFloorDb) &&
            const DeepCollectionEquality().equals(
              other.androidCaptureUsages,
              _androidCaptureUsages,
            ) &&
            (identical(other.androidMicSource, androidMicSource) ||
                other.androidMicSource == androidMicSource) &&
            (identical(
                  other.androidFallbackCaptureSampleRate,
                  androidFallbackCaptureSampleRate,
                ) ||
                other.androidFallbackCaptureSampleRate ==
                    androidFallbackCaptureSampleRate) &&
            (identical(
                  other.androidNotificationChannelId,
                  androidNotificationChannelId,
                ) ||
                other.androidNotificationChannelId ==
                    androidNotificationChannelId) &&
            (identical(other.androidNotificationId, androidNotificationId) ||
                other.androidNotificationId == androidNotificationId) &&
            (identical(other.iosChunkMs, iosChunkMs) ||
                other.iosChunkMs == iosChunkMs) &&
            (identical(other.iosStartTimeoutMs, iosStartTimeoutMs) ||
                other.iosStartTimeoutMs == iosStartTimeoutMs) &&
            (identical(other.iosStopTimeoutMs, iosStopTimeoutMs) ||
                other.iosStopTimeoutMs == iosStopTimeoutMs) &&
            (identical(other.iosPollIntervalMs, iosPollIntervalMs) ||
                other.iosPollIntervalMs == iosPollIntervalMs) &&
            (identical(other.iosMaxPendingChunks, iosMaxPendingChunks) ||
                other.iosMaxPendingChunks == iosMaxPendingChunks) &&
            (identical(
                  other.iosKeepAliveInBackground,
                  iosKeepAliveInBackground,
                ) ||
                other.iosKeepAliveInBackground == iosKeepAliveInBackground));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hashAll([
      runtimeType,
      frameMs,
      jitterBufferMs,
      maxBufferMs,
      micActiveRmsThreshold,
      duckingAttackMs,
      duckingReleaseMs,
      softClipKnee,
      levelFloorDb,
      const DeepCollectionEquality().hash(_androidCaptureUsages),
      androidMicSource,
      androidFallbackCaptureSampleRate,
      androidNotificationChannelId,
      androidNotificationId,
      iosChunkMs,
      iosStartTimeoutMs,
      iosStopTimeoutMs,
      iosPollIntervalMs,
      iosMaxPendingChunks,
      iosKeepAliveInBackground,
    ]);
  }

  @override
  String toString() {
    return 'SystemAudioConfig(frameMs: $frameMs, jitterBufferMs: $jitterBufferMs, maxBufferMs: $maxBufferMs, micActiveRmsThreshold: $micActiveRmsThreshold, duckingAttackMs: $duckingAttackMs, duckingReleaseMs: $duckingReleaseMs, softClipKnee: $softClipKnee, levelFloorDb: $levelFloorDb, androidCaptureUsages: $androidCaptureUsages, androidMicSource: $androidMicSource, androidFallbackCaptureSampleRate: $androidFallbackCaptureSampleRate, androidNotificationChannelId: $androidNotificationChannelId, androidNotificationId: $androidNotificationId, iosChunkMs: $iosChunkMs, iosStartTimeoutMs: $iosStartTimeoutMs, iosStopTimeoutMs: $iosStopTimeoutMs, iosPollIntervalMs: $iosPollIntervalMs, iosMaxPendingChunks: $iosMaxPendingChunks, iosKeepAliveInBackground: $iosKeepAliveInBackground)';
  }
}

/// @nodoc
abstract mixin class _$SystemAudioConfigCopyWith<$Res>
    implements $SystemAudioConfigCopyWith<$Res> {
  factory _$SystemAudioConfigCopyWith(
    _SystemAudioConfig value,
    $Res Function(_SystemAudioConfig) _then,
  ) = __$SystemAudioConfigCopyWithImpl;
  @override
  @useResult
  $Res call({
    int frameMs,
    int jitterBufferMs,
    int maxBufferMs,
    double micActiveRmsThreshold,
    int duckingAttackMs,
    int duckingReleaseMs,
    double softClipKnee,
    double levelFloorDb,
    List<String> androidCaptureUsages,
    String androidMicSource,
    int androidFallbackCaptureSampleRate,
    String androidNotificationChannelId,
    int androidNotificationId,
    int iosChunkMs,
    int iosStartTimeoutMs,
    int iosStopTimeoutMs,
    int iosPollIntervalMs,
    int iosMaxPendingChunks,
    bool iosKeepAliveInBackground,
  });
}

/// @nodoc
class __$SystemAudioConfigCopyWithImpl<$Res>
    implements _$SystemAudioConfigCopyWith<$Res> {
  __$SystemAudioConfigCopyWithImpl(this._self, this._then);

  final _SystemAudioConfig _self;
  final $Res Function(_SystemAudioConfig) _then;

  /// Create a copy of SystemAudioConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? frameMs = null,
    Object? jitterBufferMs = null,
    Object? maxBufferMs = null,
    Object? micActiveRmsThreshold = null,
    Object? duckingAttackMs = null,
    Object? duckingReleaseMs = null,
    Object? softClipKnee = null,
    Object? levelFloorDb = null,
    Object? androidCaptureUsages = null,
    Object? androidMicSource = null,
    Object? androidFallbackCaptureSampleRate = null,
    Object? androidNotificationChannelId = null,
    Object? androidNotificationId = null,
    Object? iosChunkMs = null,
    Object? iosStartTimeoutMs = null,
    Object? iosStopTimeoutMs = null,
    Object? iosPollIntervalMs = null,
    Object? iosMaxPendingChunks = null,
    Object? iosKeepAliveInBackground = null,
  }) {
    return _then(
      _SystemAudioConfig(
        frameMs: null == frameMs
            ? _self.frameMs
            : frameMs // ignore: cast_nullable_to_non_nullable
                  as int,
        jitterBufferMs: null == jitterBufferMs
            ? _self.jitterBufferMs
            : jitterBufferMs // ignore: cast_nullable_to_non_nullable
                  as int,
        maxBufferMs: null == maxBufferMs
            ? _self.maxBufferMs
            : maxBufferMs // ignore: cast_nullable_to_non_nullable
                  as int,
        micActiveRmsThreshold: null == micActiveRmsThreshold
            ? _self.micActiveRmsThreshold
            : micActiveRmsThreshold // ignore: cast_nullable_to_non_nullable
                  as double,
        duckingAttackMs: null == duckingAttackMs
            ? _self.duckingAttackMs
            : duckingAttackMs // ignore: cast_nullable_to_non_nullable
                  as int,
        duckingReleaseMs: null == duckingReleaseMs
            ? _self.duckingReleaseMs
            : duckingReleaseMs // ignore: cast_nullable_to_non_nullable
                  as int,
        softClipKnee: null == softClipKnee
            ? _self.softClipKnee
            : softClipKnee // ignore: cast_nullable_to_non_nullable
                  as double,
        levelFloorDb: null == levelFloorDb
            ? _self.levelFloorDb
            : levelFloorDb // ignore: cast_nullable_to_non_nullable
                  as double,
        androidCaptureUsages: null == androidCaptureUsages
            ? _self._androidCaptureUsages
            : androidCaptureUsages // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        androidMicSource: null == androidMicSource
            ? _self.androidMicSource
            : androidMicSource // ignore: cast_nullable_to_non_nullable
                  as String,
        androidFallbackCaptureSampleRate:
            null == androidFallbackCaptureSampleRate
            ? _self.androidFallbackCaptureSampleRate
            : androidFallbackCaptureSampleRate // ignore: cast_nullable_to_non_nullable
                  as int,
        androidNotificationChannelId: null == androidNotificationChannelId
            ? _self.androidNotificationChannelId
            : androidNotificationChannelId // ignore: cast_nullable_to_non_nullable
                  as String,
        androidNotificationId: null == androidNotificationId
            ? _self.androidNotificationId
            : androidNotificationId // ignore: cast_nullable_to_non_nullable
                  as int,
        iosChunkMs: null == iosChunkMs
            ? _self.iosChunkMs
            : iosChunkMs // ignore: cast_nullable_to_non_nullable
                  as int,
        iosStartTimeoutMs: null == iosStartTimeoutMs
            ? _self.iosStartTimeoutMs
            : iosStartTimeoutMs // ignore: cast_nullable_to_non_nullable
                  as int,
        iosStopTimeoutMs: null == iosStopTimeoutMs
            ? _self.iosStopTimeoutMs
            : iosStopTimeoutMs // ignore: cast_nullable_to_non_nullable
                  as int,
        iosPollIntervalMs: null == iosPollIntervalMs
            ? _self.iosPollIntervalMs
            : iosPollIntervalMs // ignore: cast_nullable_to_non_nullable
                  as int,
        iosMaxPendingChunks: null == iosMaxPendingChunks
            ? _self.iosMaxPendingChunks
            : iosMaxPendingChunks // ignore: cast_nullable_to_non_nullable
                  as int,
        iosKeepAliveInBackground: null == iosKeepAliveInBackground
            ? _self.iosKeepAliveInBackground
            : iosKeepAliveInBackground // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}
