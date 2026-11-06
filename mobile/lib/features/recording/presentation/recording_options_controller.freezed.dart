// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recording_options_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RecordingOptions {
  RecordingSource get source;

  /// Language code; `auto` = server detects.
  String get language;

  /// Create a copy of RecordingOptions
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $RecordingOptionsCopyWith<RecordingOptions> get copyWith =>
      _$RecordingOptionsCopyWithImpl<RecordingOptions>(
        this as RecordingOptions,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    final _this = this as RecordingOptions;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is RecordingOptions &&
            (identical(other.source, _this.source) ||
                other.source == _this.source) &&
            (identical(other.language, _this.language) ||
                other.language == _this.language));
  }

  @override
  int get hashCode {
    final _this = this as RecordingOptions;
    return Object.hash(runtimeType, _this.source, _this.language);
  }

  @override
  String toString() {
    final _this = this as RecordingOptions;
    return 'RecordingOptions(source: ${_this.source}, language: ${_this.language})';
  }
}

/// @nodoc
abstract mixin class $RecordingOptionsCopyWith<$Res> {
  factory $RecordingOptionsCopyWith(
    RecordingOptions value,
    $Res Function(RecordingOptions) _then,
  ) = _$RecordingOptionsCopyWithImpl;
  @useResult
  $Res call({RecordingSource source, String language});
}

/// @nodoc
class _$RecordingOptionsCopyWithImpl<$Res>
    implements $RecordingOptionsCopyWith<$Res> {
  _$RecordingOptionsCopyWithImpl(this._self, this._then);

  final RecordingOptions _self;
  final $Res Function(RecordingOptions) _then;

  /// Create a copy of RecordingOptions
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? source = null, Object? language = null}) {
    return _then(
      RecordingOptions(
        source: null == source
            ? _self.source
            : source // ignore: cast_nullable_to_non_nullable
                  as RecordingSource,
        language: null == language
            ? _self.language
            : language // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [RecordingOptions].
extension RecordingOptionsPatterns on RecordingOptions {
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
    TResult Function(_RecordingOptions value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _RecordingOptions() when $default != null:
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
    TResult Function(_RecordingOptions value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RecordingOptions():
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
    TResult? Function(_RecordingOptions value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RecordingOptions() when $default != null:
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
    TResult Function(RecordingSource source, String language)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _RecordingOptions() when $default != null:
        return $default(_that.source, _that.language);
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
    TResult Function(RecordingSource source, String language) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RecordingOptions():
        return $default(_that.source, _that.language);
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
    TResult? Function(RecordingSource source, String language)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RecordingOptions() when $default != null:
        return $default(_that.source, _that.language);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _RecordingOptions implements RecordingOptions {
  const _RecordingOptions({required this.source, required this.language});

  @override
  final RecordingSource source;

  /// Language code; `auto` = server detects.
  @override
  final String language;

  /// Create a copy of RecordingOptions
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$RecordingOptionsCopyWith<_RecordingOptions> get copyWith =>
      __$RecordingOptionsCopyWithImpl<_RecordingOptions>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _RecordingOptions &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.language, language) ||
                other.language == language));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, source, language);
  }

  @override
  String toString() {
    return 'RecordingOptions(source: $source, language: $language)';
  }
}

/// @nodoc
abstract mixin class _$RecordingOptionsCopyWith<$Res>
    implements $RecordingOptionsCopyWith<$Res> {
  factory _$RecordingOptionsCopyWith(
    _RecordingOptions value,
    $Res Function(_RecordingOptions) _then,
  ) = __$RecordingOptionsCopyWithImpl;
  @override
  @useResult
  $Res call({RecordingSource source, String language});
}

/// @nodoc
class __$RecordingOptionsCopyWithImpl<$Res>
    implements _$RecordingOptionsCopyWith<$Res> {
  __$RecordingOptionsCopyWithImpl(this._self, this._then);

  final _RecordingOptions _self;
  final $Res Function(_RecordingOptions) _then;

  /// Create a copy of RecordingOptions
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({Object? source = null, Object? language = null}) {
    return _then(
      _RecordingOptions(
        source: null == source
            ? _self.source
            : source // ignore: cast_nullable_to_non_nullable
                  as RecordingSource,
        language: null == language
            ? _self.language
            : language // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}
