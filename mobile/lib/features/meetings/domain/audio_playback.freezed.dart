// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'audio_playback.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MeetingPlayerState {
  PlayerStatus get status;
  bool get playing;
  Duration get position;
  Duration? get duration;

  /// Index into `AppConfig.player.speeds`.
  int get speedIndex;
  Object? get error;

  /// Create a copy of MeetingPlayerState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $MeetingPlayerStateCopyWith<MeetingPlayerState> get copyWith =>
      _$MeetingPlayerStateCopyWithImpl<MeetingPlayerState>(
        this as MeetingPlayerState,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    final _this = this as MeetingPlayerState;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MeetingPlayerState &&
            (identical(other.status, _this.status) ||
                other.status == _this.status) &&
            (identical(other.playing, _this.playing) ||
                other.playing == _this.playing) &&
            (identical(other.position, _this.position) ||
                other.position == _this.position) &&
            (identical(other.duration, _this.duration) ||
                other.duration == _this.duration) &&
            (identical(other.speedIndex, _this.speedIndex) ||
                other.speedIndex == _this.speedIndex) &&
            const DeepCollectionEquality().equals(other.error, _this.error));
  }

  @override
  int get hashCode {
    final _this = this as MeetingPlayerState;
    return Object.hash(
      runtimeType,
      _this.status,
      _this.playing,
      _this.position,
      _this.duration,
      _this.speedIndex,
      const DeepCollectionEquality().hash(_this.error),
    );
  }

  @override
  String toString() {
    final _this = this as MeetingPlayerState;
    return 'MeetingPlayerState(status: ${_this.status}, playing: ${_this.playing}, position: ${_this.position}, duration: ${_this.duration}, speedIndex: ${_this.speedIndex}, error: ${_this.error})';
  }
}

/// @nodoc
abstract mixin class $MeetingPlayerStateCopyWith<$Res> {
  factory $MeetingPlayerStateCopyWith(
    MeetingPlayerState value,
    $Res Function(MeetingPlayerState) _then,
  ) = _$MeetingPlayerStateCopyWithImpl;
  @useResult
  $Res call({
    PlayerStatus status,
    bool playing,
    Duration position,
    Duration? duration,
    int speedIndex,
    Object? error,
  });
}

/// @nodoc
class _$MeetingPlayerStateCopyWithImpl<$Res>
    implements $MeetingPlayerStateCopyWith<$Res> {
  _$MeetingPlayerStateCopyWithImpl(this._self, this._then);

  final MeetingPlayerState _self;
  final $Res Function(MeetingPlayerState) _then;

  /// Create a copy of MeetingPlayerState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? playing = null,
    Object? position = null,
    Object? duration = freezed,
    Object? speedIndex = null,
    Object? error = freezed,
  }) {
    return _then(
      MeetingPlayerState(
        status: null == status
            ? _self.status
            : status // ignore: cast_nullable_to_non_nullable
                  as PlayerStatus,
        playing: null == playing
            ? _self.playing
            : playing // ignore: cast_nullable_to_non_nullable
                  as bool,
        position: null == position
            ? _self.position
            : position // ignore: cast_nullable_to_non_nullable
                  as Duration,
        duration: freezed == duration
            ? _self.duration
            : duration // ignore: cast_nullable_to_non_nullable
                  as Duration?,
        speedIndex: null == speedIndex
            ? _self.speedIndex
            : speedIndex // ignore: cast_nullable_to_non_nullable
                  as int,
        error: freezed == error ? _self.error : error,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [MeetingPlayerState].
extension MeetingPlayerStatePatterns on MeetingPlayerState {
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
    TResult Function(_MeetingPlayerState value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _MeetingPlayerState() when $default != null:
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
    TResult Function(_MeetingPlayerState value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MeetingPlayerState():
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
    TResult? Function(_MeetingPlayerState value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MeetingPlayerState() when $default != null:
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
      PlayerStatus status,
      bool playing,
      Duration position,
      Duration? duration,
      int speedIndex,
      Object? error,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _MeetingPlayerState() when $default != null:
        return $default(
          _that.status,
          _that.playing,
          _that.position,
          _that.duration,
          _that.speedIndex,
          _that.error,
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
      PlayerStatus status,
      bool playing,
      Duration position,
      Duration? duration,
      int speedIndex,
      Object? error,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MeetingPlayerState():
        return $default(
          _that.status,
          _that.playing,
          _that.position,
          _that.duration,
          _that.speedIndex,
          _that.error,
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
      PlayerStatus status,
      bool playing,
      Duration position,
      Duration? duration,
      int speedIndex,
      Object? error,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MeetingPlayerState() when $default != null:
        return $default(
          _that.status,
          _that.playing,
          _that.position,
          _that.duration,
          _that.speedIndex,
          _that.error,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc

class _MeetingPlayerState extends MeetingPlayerState {
  const _MeetingPlayerState({
    this.status = PlayerStatus.idle,
    this.playing = false,
    this.position = Duration.zero,
    this.duration,
    this.speedIndex = 0,
    this.error,
  }) : super._();

  @override
  @JsonKey()
  final PlayerStatus status;
  @override
  @JsonKey()
  final bool playing;
  @override
  @JsonKey()
  final Duration position;
  @override
  final Duration? duration;

  /// Index into `AppConfig.player.speeds`.
  @override
  @JsonKey()
  final int speedIndex;
  @override
  final Object? error;

  /// Create a copy of MeetingPlayerState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$MeetingPlayerStateCopyWith<_MeetingPlayerState> get copyWith =>
      __$MeetingPlayerStateCopyWithImpl<_MeetingPlayerState>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _MeetingPlayerState &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.playing, playing) || other.playing == playing) &&
            (identical(other.position, position) ||
                other.position == position) &&
            (identical(other.duration, duration) ||
                other.duration == duration) &&
            (identical(other.speedIndex, speedIndex) ||
                other.speedIndex == speedIndex) &&
            const DeepCollectionEquality().equals(other.error, error));
  }

  @override
  int get hashCode {
    return Object.hash(
      runtimeType,
      status,
      playing,
      position,
      duration,
      speedIndex,
      const DeepCollectionEquality().hash(error),
    );
  }

  @override
  String toString() {
    return 'MeetingPlayerState(status: $status, playing: $playing, position: $position, duration: $duration, speedIndex: $speedIndex, error: $error)';
  }
}

/// @nodoc
abstract mixin class _$MeetingPlayerStateCopyWith<$Res>
    implements $MeetingPlayerStateCopyWith<$Res> {
  factory _$MeetingPlayerStateCopyWith(
    _MeetingPlayerState value,
    $Res Function(_MeetingPlayerState) _then,
  ) = __$MeetingPlayerStateCopyWithImpl;
  @override
  @useResult
  $Res call({
    PlayerStatus status,
    bool playing,
    Duration position,
    Duration? duration,
    int speedIndex,
    Object? error,
  });
}

/// @nodoc
class __$MeetingPlayerStateCopyWithImpl<$Res>
    implements _$MeetingPlayerStateCopyWith<$Res> {
  __$MeetingPlayerStateCopyWithImpl(this._self, this._then);

  final _MeetingPlayerState _self;
  final $Res Function(_MeetingPlayerState) _then;

  /// Create a copy of MeetingPlayerState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? status = null,
    Object? playing = null,
    Object? position = null,
    Object? duration = freezed,
    Object? speedIndex = null,
    Object? error = freezed,
  }) {
    return _then(
      _MeetingPlayerState(
        status: null == status
            ? _self.status
            : status // ignore: cast_nullable_to_non_nullable
                  as PlayerStatus,
        playing: null == playing
            ? _self.playing
            : playing // ignore: cast_nullable_to_non_nullable
                  as bool,
        position: null == position
            ? _self.position
            : position // ignore: cast_nullable_to_non_nullable
                  as Duration,
        duration: freezed == duration
            ? _self.duration
            : duration // ignore: cast_nullable_to_non_nullable
                  as Duration?,
        speedIndex: null == speedIndex
            ? _self.speedIndex
            : speedIndex // ignore: cast_nullable_to_non_nullable
                  as int,
        error: freezed == error ? _self.error : error,
      ),
    );
  }
}
