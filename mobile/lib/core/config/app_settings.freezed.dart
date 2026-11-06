// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AppSettings {
  LocaleMode? get localeMode;
  RecordingSource? get defaultRecordingSource;

  /// Transcription language code, `auto` = server detects.
  String? get transcriptionLanguage;

  /// Generate a summary automatically after a recording/import finishes.
  bool? get autoSummary;

  /// Keep the local m4a after it was uploaded successfully.
  bool? get keepLocalAudio;

  /// Set once the onboarding flow finished.
  bool get onboardingCompleted;

  /// Create a copy of AppSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $AppSettingsCopyWith<AppSettings> get copyWith =>
      _$AppSettingsCopyWithImpl<AppSettings>(this as AppSettings, _$identity);

  @override
  bool operator ==(Object other) {
    final _this = this as AppSettings;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AppSettings &&
            (identical(other.localeMode, _this.localeMode) ||
                other.localeMode == _this.localeMode) &&
            (identical(
                  other.defaultRecordingSource,
                  _this.defaultRecordingSource,
                ) ||
                other.defaultRecordingSource == _this.defaultRecordingSource) &&
            (identical(
                  other.transcriptionLanguage,
                  _this.transcriptionLanguage,
                ) ||
                other.transcriptionLanguage == _this.transcriptionLanguage) &&
            (identical(other.autoSummary, _this.autoSummary) ||
                other.autoSummary == _this.autoSummary) &&
            (identical(other.keepLocalAudio, _this.keepLocalAudio) ||
                other.keepLocalAudio == _this.keepLocalAudio) &&
            (identical(other.onboardingCompleted, _this.onboardingCompleted) ||
                other.onboardingCompleted == _this.onboardingCompleted));
  }

  @override
  int get hashCode {
    final _this = this as AppSettings;
    return Object.hash(
      runtimeType,
      _this.localeMode,
      _this.defaultRecordingSource,
      _this.transcriptionLanguage,
      _this.autoSummary,
      _this.keepLocalAudio,
      _this.onboardingCompleted,
    );
  }

  @override
  String toString() {
    final _this = this as AppSettings;
    return 'AppSettings(localeMode: ${_this.localeMode}, defaultRecordingSource: ${_this.defaultRecordingSource}, transcriptionLanguage: ${_this.transcriptionLanguage}, autoSummary: ${_this.autoSummary}, keepLocalAudio: ${_this.keepLocalAudio}, onboardingCompleted: ${_this.onboardingCompleted})';
  }
}

/// @nodoc
abstract mixin class $AppSettingsCopyWith<$Res> {
  factory $AppSettingsCopyWith(
    AppSettings value,
    $Res Function(AppSettings) _then,
  ) = _$AppSettingsCopyWithImpl;
  @useResult
  $Res call({
    LocaleMode? localeMode,
    RecordingSource? defaultRecordingSource,
    String? transcriptionLanguage,
    bool? autoSummary,
    bool? keepLocalAudio,
    bool onboardingCompleted,
  });
}

/// @nodoc
class _$AppSettingsCopyWithImpl<$Res> implements $AppSettingsCopyWith<$Res> {
  _$AppSettingsCopyWithImpl(this._self, this._then);

  final AppSettings _self;
  final $Res Function(AppSettings) _then;

  /// Create a copy of AppSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? localeMode = freezed,
    Object? defaultRecordingSource = freezed,
    Object? transcriptionLanguage = freezed,
    Object? autoSummary = freezed,
    Object? keepLocalAudio = freezed,
    Object? onboardingCompleted = null,
  }) {
    return _then(
      AppSettings(
        localeMode: freezed == localeMode
            ? _self.localeMode
            : localeMode // ignore: cast_nullable_to_non_nullable
                  as LocaleMode?,
        defaultRecordingSource: freezed == defaultRecordingSource
            ? _self.defaultRecordingSource
            : defaultRecordingSource // ignore: cast_nullable_to_non_nullable
                  as RecordingSource?,
        transcriptionLanguage: freezed == transcriptionLanguage
            ? _self.transcriptionLanguage
            : transcriptionLanguage // ignore: cast_nullable_to_non_nullable
                  as String?,
        autoSummary: freezed == autoSummary
            ? _self.autoSummary
            : autoSummary // ignore: cast_nullable_to_non_nullable
                  as bool?,
        keepLocalAudio: freezed == keepLocalAudio
            ? _self.keepLocalAudio
            : keepLocalAudio // ignore: cast_nullable_to_non_nullable
                  as bool?,
        onboardingCompleted: null == onboardingCompleted
            ? _self.onboardingCompleted
            : onboardingCompleted // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [AppSettings].
extension AppSettingsPatterns on AppSettings {
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
    TResult Function(_AppSettings value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AppSettings() when $default != null:
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
    TResult Function(_AppSettings value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AppSettings():
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
    TResult? Function(_AppSettings value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AppSettings() when $default != null:
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
      LocaleMode? localeMode,
      RecordingSource? defaultRecordingSource,
      String? transcriptionLanguage,
      bool? autoSummary,
      bool? keepLocalAudio,
      bool onboardingCompleted,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AppSettings() when $default != null:
        return $default(
          _that.localeMode,
          _that.defaultRecordingSource,
          _that.transcriptionLanguage,
          _that.autoSummary,
          _that.keepLocalAudio,
          _that.onboardingCompleted,
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
      LocaleMode? localeMode,
      RecordingSource? defaultRecordingSource,
      String? transcriptionLanguage,
      bool? autoSummary,
      bool? keepLocalAudio,
      bool onboardingCompleted,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AppSettings():
        return $default(
          _that.localeMode,
          _that.defaultRecordingSource,
          _that.transcriptionLanguage,
          _that.autoSummary,
          _that.keepLocalAudio,
          _that.onboardingCompleted,
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
      LocaleMode? localeMode,
      RecordingSource? defaultRecordingSource,
      String? transcriptionLanguage,
      bool? autoSummary,
      bool? keepLocalAudio,
      bool onboardingCompleted,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AppSettings() when $default != null:
        return $default(
          _that.localeMode,
          _that.defaultRecordingSource,
          _that.transcriptionLanguage,
          _that.autoSummary,
          _that.keepLocalAudio,
          _that.onboardingCompleted,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc

class _AppSettings implements AppSettings {
  const _AppSettings({
    this.localeMode,
    this.defaultRecordingSource,
    this.transcriptionLanguage,
    this.autoSummary,
    this.keepLocalAudio,
    this.onboardingCompleted = false,
  });

  @override
  final LocaleMode? localeMode;
  @override
  final RecordingSource? defaultRecordingSource;

  /// Transcription language code, `auto` = server detects.
  @override
  final String? transcriptionLanguage;

  /// Generate a summary automatically after a recording/import finishes.
  @override
  final bool? autoSummary;

  /// Keep the local m4a after it was uploaded successfully.
  @override
  final bool? keepLocalAudio;

  /// Set once the onboarding flow finished.
  @override
  @JsonKey()
  final bool onboardingCompleted;

  /// Create a copy of AppSettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$AppSettingsCopyWith<_AppSettings> get copyWith =>
      __$AppSettingsCopyWithImpl<_AppSettings>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _AppSettings &&
            (identical(other.localeMode, localeMode) ||
                other.localeMode == localeMode) &&
            (identical(other.defaultRecordingSource, defaultRecordingSource) ||
                other.defaultRecordingSource == defaultRecordingSource) &&
            (identical(other.transcriptionLanguage, transcriptionLanguage) ||
                other.transcriptionLanguage == transcriptionLanguage) &&
            (identical(other.autoSummary, autoSummary) ||
                other.autoSummary == autoSummary) &&
            (identical(other.keepLocalAudio, keepLocalAudio) ||
                other.keepLocalAudio == keepLocalAudio) &&
            (identical(other.onboardingCompleted, onboardingCompleted) ||
                other.onboardingCompleted == onboardingCompleted));
  }

  @override
  int get hashCode {
    return Object.hash(
      runtimeType,
      localeMode,
      defaultRecordingSource,
      transcriptionLanguage,
      autoSummary,
      keepLocalAudio,
      onboardingCompleted,
    );
  }

  @override
  String toString() {
    return 'AppSettings(localeMode: $localeMode, defaultRecordingSource: $defaultRecordingSource, transcriptionLanguage: $transcriptionLanguage, autoSummary: $autoSummary, keepLocalAudio: $keepLocalAudio, onboardingCompleted: $onboardingCompleted)';
  }
}

/// @nodoc
abstract mixin class _$AppSettingsCopyWith<$Res>
    implements $AppSettingsCopyWith<$Res> {
  factory _$AppSettingsCopyWith(
    _AppSettings value,
    $Res Function(_AppSettings) _then,
  ) = __$AppSettingsCopyWithImpl;
  @override
  @useResult
  $Res call({
    LocaleMode? localeMode,
    RecordingSource? defaultRecordingSource,
    String? transcriptionLanguage,
    bool? autoSummary,
    bool? keepLocalAudio,
    bool onboardingCompleted,
  });
}

/// @nodoc
class __$AppSettingsCopyWithImpl<$Res> implements _$AppSettingsCopyWith<$Res> {
  __$AppSettingsCopyWithImpl(this._self, this._then);

  final _AppSettings _self;
  final $Res Function(_AppSettings) _then;

  /// Create a copy of AppSettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? localeMode = freezed,
    Object? defaultRecordingSource = freezed,
    Object? transcriptionLanguage = freezed,
    Object? autoSummary = freezed,
    Object? keepLocalAudio = freezed,
    Object? onboardingCompleted = null,
  }) {
    return _then(
      _AppSettings(
        localeMode: freezed == localeMode
            ? _self.localeMode
            : localeMode // ignore: cast_nullable_to_non_nullable
                  as LocaleMode?,
        defaultRecordingSource: freezed == defaultRecordingSource
            ? _self.defaultRecordingSource
            : defaultRecordingSource // ignore: cast_nullable_to_non_nullable
                  as RecordingSource?,
        transcriptionLanguage: freezed == transcriptionLanguage
            ? _self.transcriptionLanguage
            : transcriptionLanguage // ignore: cast_nullable_to_non_nullable
                  as String?,
        autoSummary: freezed == autoSummary
            ? _self.autoSummary
            : autoSummary // ignore: cast_nullable_to_non_nullable
                  as bool?,
        keepLocalAudio: freezed == keepLocalAudio
            ? _self.keepLocalAudio
            : keepLocalAudio // ignore: cast_nullable_to_non_nullable
                  as bool?,
        onboardingCompleted: null == onboardingCompleted
            ? _self.onboardingCompleted
            : onboardingCompleted // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
mixin _$EffectiveSettings {
  /// `AppConfig.defaultServerUrl`, normalized. Never user-editable or shown in the UI.
  String get serverUrl;
  LocaleMode get localeMode;
  RecordingSource get defaultRecordingSource;
  String get transcriptionLanguage;
  bool get autoSummary;
  bool get keepLocalAudio;
  bool get onboardingCompleted;

  /// Create a copy of EffectiveSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $EffectiveSettingsCopyWith<EffectiveSettings> get copyWith =>
      _$EffectiveSettingsCopyWithImpl<EffectiveSettings>(
        this as EffectiveSettings,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    final _this = this as EffectiveSettings;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is EffectiveSettings &&
            (identical(other.serverUrl, _this.serverUrl) ||
                other.serverUrl == _this.serverUrl) &&
            (identical(other.localeMode, _this.localeMode) ||
                other.localeMode == _this.localeMode) &&
            (identical(
                  other.defaultRecordingSource,
                  _this.defaultRecordingSource,
                ) ||
                other.defaultRecordingSource == _this.defaultRecordingSource) &&
            (identical(
                  other.transcriptionLanguage,
                  _this.transcriptionLanguage,
                ) ||
                other.transcriptionLanguage == _this.transcriptionLanguage) &&
            (identical(other.autoSummary, _this.autoSummary) ||
                other.autoSummary == _this.autoSummary) &&
            (identical(other.keepLocalAudio, _this.keepLocalAudio) ||
                other.keepLocalAudio == _this.keepLocalAudio) &&
            (identical(other.onboardingCompleted, _this.onboardingCompleted) ||
                other.onboardingCompleted == _this.onboardingCompleted));
  }

  @override
  int get hashCode {
    final _this = this as EffectiveSettings;
    return Object.hash(
      runtimeType,
      _this.serverUrl,
      _this.localeMode,
      _this.defaultRecordingSource,
      _this.transcriptionLanguage,
      _this.autoSummary,
      _this.keepLocalAudio,
      _this.onboardingCompleted,
    );
  }

  @override
  String toString() {
    final _this = this as EffectiveSettings;
    return 'EffectiveSettings(serverUrl: ${_this.serverUrl}, localeMode: ${_this.localeMode}, defaultRecordingSource: ${_this.defaultRecordingSource}, transcriptionLanguage: ${_this.transcriptionLanguage}, autoSummary: ${_this.autoSummary}, keepLocalAudio: ${_this.keepLocalAudio}, onboardingCompleted: ${_this.onboardingCompleted})';
  }
}

/// @nodoc
abstract mixin class $EffectiveSettingsCopyWith<$Res> {
  factory $EffectiveSettingsCopyWith(
    EffectiveSettings value,
    $Res Function(EffectiveSettings) _then,
  ) = _$EffectiveSettingsCopyWithImpl;
  @useResult
  $Res call({
    String serverUrl,
    LocaleMode localeMode,
    RecordingSource defaultRecordingSource,
    String transcriptionLanguage,
    bool autoSummary,
    bool keepLocalAudio,
    bool onboardingCompleted,
  });
}

/// @nodoc
class _$EffectiveSettingsCopyWithImpl<$Res>
    implements $EffectiveSettingsCopyWith<$Res> {
  _$EffectiveSettingsCopyWithImpl(this._self, this._then);

  final EffectiveSettings _self;
  final $Res Function(EffectiveSettings) _then;

  /// Create a copy of EffectiveSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? serverUrl = null,
    Object? localeMode = null,
    Object? defaultRecordingSource = null,
    Object? transcriptionLanguage = null,
    Object? autoSummary = null,
    Object? keepLocalAudio = null,
    Object? onboardingCompleted = null,
  }) {
    return _then(
      EffectiveSettings(
        serverUrl: null == serverUrl
            ? _self.serverUrl
            : serverUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        localeMode: null == localeMode
            ? _self.localeMode
            : localeMode // ignore: cast_nullable_to_non_nullable
                  as LocaleMode,
        defaultRecordingSource: null == defaultRecordingSource
            ? _self.defaultRecordingSource
            : defaultRecordingSource // ignore: cast_nullable_to_non_nullable
                  as RecordingSource,
        transcriptionLanguage: null == transcriptionLanguage
            ? _self.transcriptionLanguage
            : transcriptionLanguage // ignore: cast_nullable_to_non_nullable
                  as String,
        autoSummary: null == autoSummary
            ? _self.autoSummary
            : autoSummary // ignore: cast_nullable_to_non_nullable
                  as bool,
        keepLocalAudio: null == keepLocalAudio
            ? _self.keepLocalAudio
            : keepLocalAudio // ignore: cast_nullable_to_non_nullable
                  as bool,
        onboardingCompleted: null == onboardingCompleted
            ? _self.onboardingCompleted
            : onboardingCompleted // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [EffectiveSettings].
extension EffectiveSettingsPatterns on EffectiveSettings {
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
    TResult Function(_EffectiveSettings value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _EffectiveSettings() when $default != null:
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
    TResult Function(_EffectiveSettings value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _EffectiveSettings():
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
    TResult? Function(_EffectiveSettings value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _EffectiveSettings() when $default != null:
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
      String serverUrl,
      LocaleMode localeMode,
      RecordingSource defaultRecordingSource,
      String transcriptionLanguage,
      bool autoSummary,
      bool keepLocalAudio,
      bool onboardingCompleted,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _EffectiveSettings() when $default != null:
        return $default(
          _that.serverUrl,
          _that.localeMode,
          _that.defaultRecordingSource,
          _that.transcriptionLanguage,
          _that.autoSummary,
          _that.keepLocalAudio,
          _that.onboardingCompleted,
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
      String serverUrl,
      LocaleMode localeMode,
      RecordingSource defaultRecordingSource,
      String transcriptionLanguage,
      bool autoSummary,
      bool keepLocalAudio,
      bool onboardingCompleted,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _EffectiveSettings():
        return $default(
          _that.serverUrl,
          _that.localeMode,
          _that.defaultRecordingSource,
          _that.transcriptionLanguage,
          _that.autoSummary,
          _that.keepLocalAudio,
          _that.onboardingCompleted,
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
      String serverUrl,
      LocaleMode localeMode,
      RecordingSource defaultRecordingSource,
      String transcriptionLanguage,
      bool autoSummary,
      bool keepLocalAudio,
      bool onboardingCompleted,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _EffectiveSettings() when $default != null:
        return $default(
          _that.serverUrl,
          _that.localeMode,
          _that.defaultRecordingSource,
          _that.transcriptionLanguage,
          _that.autoSummary,
          _that.keepLocalAudio,
          _that.onboardingCompleted,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc

class _EffectiveSettings extends EffectiveSettings {
  const _EffectiveSettings({
    required this.serverUrl,
    required this.localeMode,
    required this.defaultRecordingSource,
    required this.transcriptionLanguage,
    required this.autoSummary,
    required this.keepLocalAudio,
    required this.onboardingCompleted,
  }) : super._();

  /// `AppConfig.defaultServerUrl`, normalized. Never user-editable or shown in the UI.
  @override
  final String serverUrl;
  @override
  final LocaleMode localeMode;
  @override
  final RecordingSource defaultRecordingSource;
  @override
  final String transcriptionLanguage;
  @override
  final bool autoSummary;
  @override
  final bool keepLocalAudio;
  @override
  final bool onboardingCompleted;

  /// Create a copy of EffectiveSettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$EffectiveSettingsCopyWith<_EffectiveSettings> get copyWith =>
      __$EffectiveSettingsCopyWithImpl<_EffectiveSettings>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _EffectiveSettings &&
            (identical(other.serverUrl, serverUrl) ||
                other.serverUrl == serverUrl) &&
            (identical(other.localeMode, localeMode) ||
                other.localeMode == localeMode) &&
            (identical(other.defaultRecordingSource, defaultRecordingSource) ||
                other.defaultRecordingSource == defaultRecordingSource) &&
            (identical(other.transcriptionLanguage, transcriptionLanguage) ||
                other.transcriptionLanguage == transcriptionLanguage) &&
            (identical(other.autoSummary, autoSummary) ||
                other.autoSummary == autoSummary) &&
            (identical(other.keepLocalAudio, keepLocalAudio) ||
                other.keepLocalAudio == keepLocalAudio) &&
            (identical(other.onboardingCompleted, onboardingCompleted) ||
                other.onboardingCompleted == onboardingCompleted));
  }

  @override
  int get hashCode {
    return Object.hash(
      runtimeType,
      serverUrl,
      localeMode,
      defaultRecordingSource,
      transcriptionLanguage,
      autoSummary,
      keepLocalAudio,
      onboardingCompleted,
    );
  }

  @override
  String toString() {
    return 'EffectiveSettings(serverUrl: $serverUrl, localeMode: $localeMode, defaultRecordingSource: $defaultRecordingSource, transcriptionLanguage: $transcriptionLanguage, autoSummary: $autoSummary, keepLocalAudio: $keepLocalAudio, onboardingCompleted: $onboardingCompleted)';
  }
}

/// @nodoc
abstract mixin class _$EffectiveSettingsCopyWith<$Res>
    implements $EffectiveSettingsCopyWith<$Res> {
  factory _$EffectiveSettingsCopyWith(
    _EffectiveSettings value,
    $Res Function(_EffectiveSettings) _then,
  ) = __$EffectiveSettingsCopyWithImpl;
  @override
  @useResult
  $Res call({
    String serverUrl,
    LocaleMode localeMode,
    RecordingSource defaultRecordingSource,
    String transcriptionLanguage,
    bool autoSummary,
    bool keepLocalAudio,
    bool onboardingCompleted,
  });
}

/// @nodoc
class __$EffectiveSettingsCopyWithImpl<$Res>
    implements _$EffectiveSettingsCopyWith<$Res> {
  __$EffectiveSettingsCopyWithImpl(this._self, this._then);

  final _EffectiveSettings _self;
  final $Res Function(_EffectiveSettings) _then;

  /// Create a copy of EffectiveSettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? serverUrl = null,
    Object? localeMode = null,
    Object? defaultRecordingSource = null,
    Object? transcriptionLanguage = null,
    Object? autoSummary = null,
    Object? keepLocalAudio = null,
    Object? onboardingCompleted = null,
  }) {
    return _then(
      _EffectiveSettings(
        serverUrl: null == serverUrl
            ? _self.serverUrl
            : serverUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        localeMode: null == localeMode
            ? _self.localeMode
            : localeMode // ignore: cast_nullable_to_non_nullable
                  as LocaleMode,
        defaultRecordingSource: null == defaultRecordingSource
            ? _self.defaultRecordingSource
            : defaultRecordingSource // ignore: cast_nullable_to_non_nullable
                  as RecordingSource,
        transcriptionLanguage: null == transcriptionLanguage
            ? _self.transcriptionLanguage
            : transcriptionLanguage // ignore: cast_nullable_to_non_nullable
                  as String,
        autoSummary: null == autoSummary
            ? _self.autoSummary
            : autoSummary // ignore: cast_nullable_to_non_nullable
                  as bool,
        keepLocalAudio: null == keepLocalAudio
            ? _self.keepLocalAudio
            : keepLocalAudio // ignore: cast_nullable_to_non_nullable
                  as bool,
        onboardingCompleted: null == onboardingCompleted
            ? _self.onboardingCompleted
            : onboardingCompleted // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}
