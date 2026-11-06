// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'screen_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ScreenState {
  ScreenPhase get phase;
  ScreenFailure? get error;
  Object? get video;

  /// Create a copy of ScreenState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ScreenStateCopyWith<ScreenState> get copyWith =>
      _$ScreenStateCopyWithImpl<ScreenState>(this as ScreenState, _$identity);

  @override
  bool operator ==(Object other) {
    final _this = this as ScreenState;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ScreenState &&
            (identical(other.phase, _this.phase) ||
                other.phase == _this.phase) &&
            (identical(other.error, _this.error) ||
                other.error == _this.error) &&
            const DeepCollectionEquality().equals(other.video, _this.video));
  }

  @override
  int get hashCode {
    final _this = this as ScreenState;
    return Object.hash(
      runtimeType,
      _this.phase,
      _this.error,
      const DeepCollectionEquality().hash(_this.video),
    );
  }

  @override
  String toString() {
    final _this = this as ScreenState;
    return 'ScreenState(phase: ${_this.phase}, error: ${_this.error}, video: ${_this.video})';
  }
}

/// @nodoc
abstract mixin class $ScreenStateCopyWith<$Res> {
  factory $ScreenStateCopyWith(
    ScreenState value,
    $Res Function(ScreenState) _then,
  ) = _$ScreenStateCopyWithImpl;
  @useResult
  $Res call({ScreenPhase phase, ScreenFailure? error, Object? video});
}

/// @nodoc
class _$ScreenStateCopyWithImpl<$Res> implements $ScreenStateCopyWith<$Res> {
  _$ScreenStateCopyWithImpl(this._self, this._then);

  final ScreenState _self;
  final $Res Function(ScreenState) _then;

  /// Create a copy of ScreenState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? phase = null,
    Object? error = freezed,
    Object? video = freezed,
  }) {
    return _then(
      ScreenState(
        phase: null == phase
            ? _self.phase
            : phase // ignore: cast_nullable_to_non_nullable
                  as ScreenPhase,
        error: freezed == error
            ? _self.error
            : error // ignore: cast_nullable_to_non_nullable
                  as ScreenFailure?,
        video: freezed == video ? _self.video : video,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [ScreenState].
extension ScreenStatePatterns on ScreenState {
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
    TResult Function(_ScreenState value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ScreenState() when $default != null:
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
    TResult Function(_ScreenState value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ScreenState():
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
    TResult? Function(_ScreenState value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ScreenState() when $default != null:
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
    TResult Function(ScreenPhase phase, ScreenFailure? error, Object? video)?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ScreenState() when $default != null:
        return $default(_that.phase, _that.error, _that.video);
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
    TResult Function(ScreenPhase phase, ScreenFailure? error, Object? video)
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ScreenState():
        return $default(_that.phase, _that.error, _that.video);
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
    TResult? Function(ScreenPhase phase, ScreenFailure? error, Object? video)?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ScreenState() when $default != null:
        return $default(_that.phase, _that.error, _that.video);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _ScreenState implements ScreenState {
  const _ScreenState({this.phase = ScreenPhase.idle, this.error, this.video});

  @override
  @JsonKey()
  final ScreenPhase phase;
  @override
  final ScreenFailure? error;
  @override
  final Object? video;

  /// Create a copy of ScreenState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ScreenStateCopyWith<_ScreenState> get copyWith =>
      __$ScreenStateCopyWithImpl<_ScreenState>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ScreenState &&
            (identical(other.phase, phase) || other.phase == phase) &&
            (identical(other.error, error) || other.error == error) &&
            const DeepCollectionEquality().equals(other.video, video));
  }

  @override
  int get hashCode {
    return Object.hash(
      runtimeType,
      phase,
      error,
      const DeepCollectionEquality().hash(video),
    );
  }

  @override
  String toString() {
    return 'ScreenState(phase: $phase, error: $error, video: $video)';
  }
}

/// @nodoc
abstract mixin class _$ScreenStateCopyWith<$Res>
    implements $ScreenStateCopyWith<$Res> {
  factory _$ScreenStateCopyWith(
    _ScreenState value,
    $Res Function(_ScreenState) _then,
  ) = __$ScreenStateCopyWithImpl;
  @override
  @useResult
  $Res call({ScreenPhase phase, ScreenFailure? error, Object? video});
}

/// @nodoc
class __$ScreenStateCopyWithImpl<$Res> implements _$ScreenStateCopyWith<$Res> {
  __$ScreenStateCopyWithImpl(this._self, this._then);

  final _ScreenState _self;
  final $Res Function(_ScreenState) _then;

  /// Create a copy of ScreenState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? phase = null,
    Object? error = freezed,
    Object? video = freezed,
  }) {
    return _then(
      _ScreenState(
        phase: null == phase
            ? _self.phase
            : phase // ignore: cast_nullable_to_non_nullable
                  as ScreenPhase,
        error: freezed == error
            ? _self.error
            : error // ignore: cast_nullable_to_non_nullable
                  as ScreenFailure?,
        video: freezed == video ? _self.video : video,
      ),
    );
  }
}
