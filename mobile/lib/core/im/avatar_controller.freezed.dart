// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'avatar_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AvatarEditState {
  AvatarPhase get phase;
  double? get progress;
  AvatarFailure? get failure;

  /// Create a copy of AvatarEditState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $AvatarEditStateCopyWith<AvatarEditState> get copyWith =>
      _$AvatarEditStateCopyWithImpl<AvatarEditState>(
        this as AvatarEditState,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    final _this = this as AvatarEditState;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AvatarEditState &&
            (identical(other.phase, _this.phase) ||
                other.phase == _this.phase) &&
            (identical(other.progress, _this.progress) ||
                other.progress == _this.progress) &&
            (identical(other.failure, _this.failure) ||
                other.failure == _this.failure));
  }

  @override
  int get hashCode {
    final _this = this as AvatarEditState;
    return Object.hash(runtimeType, _this.phase, _this.progress, _this.failure);
  }

  @override
  String toString() {
    final _this = this as AvatarEditState;
    return 'AvatarEditState(phase: ${_this.phase}, progress: ${_this.progress}, failure: ${_this.failure})';
  }
}

/// @nodoc
abstract mixin class $AvatarEditStateCopyWith<$Res> {
  factory $AvatarEditStateCopyWith(
    AvatarEditState value,
    $Res Function(AvatarEditState) _then,
  ) = _$AvatarEditStateCopyWithImpl;
  @useResult
  $Res call({AvatarPhase phase, double? progress, AvatarFailure? failure});
}

/// @nodoc
class _$AvatarEditStateCopyWithImpl<$Res>
    implements $AvatarEditStateCopyWith<$Res> {
  _$AvatarEditStateCopyWithImpl(this._self, this._then);

  final AvatarEditState _self;
  final $Res Function(AvatarEditState) _then;

  /// Create a copy of AvatarEditState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? phase = null,
    Object? progress = freezed,
    Object? failure = freezed,
  }) {
    return _then(
      AvatarEditState(
        phase: null == phase
            ? _self.phase
            : phase // ignore: cast_nullable_to_non_nullable
                  as AvatarPhase,
        progress: freezed == progress
            ? _self.progress
            : progress // ignore: cast_nullable_to_non_nullable
                  as double?,
        failure: freezed == failure
            ? _self.failure
            : failure // ignore: cast_nullable_to_non_nullable
                  as AvatarFailure?,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [AvatarEditState].
extension AvatarEditStatePatterns on AvatarEditState {
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
    TResult Function(_AvatarEditState value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AvatarEditState() when $default != null:
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
    TResult Function(_AvatarEditState value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AvatarEditState():
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
    TResult? Function(_AvatarEditState value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AvatarEditState() when $default != null:
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
      AvatarPhase phase,
      double? progress,
      AvatarFailure? failure,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AvatarEditState() when $default != null:
        return $default(_that.phase, _that.progress, _that.failure);
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
      AvatarPhase phase,
      double? progress,
      AvatarFailure? failure,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AvatarEditState():
        return $default(_that.phase, _that.progress, _that.failure);
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
      AvatarPhase phase,
      double? progress,
      AvatarFailure? failure,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AvatarEditState() when $default != null:
        return $default(_that.phase, _that.progress, _that.failure);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _AvatarEditState extends AvatarEditState {
  const _AvatarEditState({
    this.phase = AvatarPhase.idle,
    this.progress,
    this.failure,
  }) : super._();

  @override
  @JsonKey()
  final AvatarPhase phase;
  @override
  final double? progress;
  @override
  final AvatarFailure? failure;

  /// Create a copy of AvatarEditState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$AvatarEditStateCopyWith<_AvatarEditState> get copyWith =>
      __$AvatarEditStateCopyWithImpl<_AvatarEditState>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _AvatarEditState &&
            (identical(other.phase, phase) || other.phase == phase) &&
            (identical(other.progress, progress) ||
                other.progress == progress) &&
            (identical(other.failure, failure) || other.failure == failure));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, phase, progress, failure);
  }

  @override
  String toString() {
    return 'AvatarEditState(phase: $phase, progress: $progress, failure: $failure)';
  }
}

/// @nodoc
abstract mixin class _$AvatarEditStateCopyWith<$Res>
    implements $AvatarEditStateCopyWith<$Res> {
  factory _$AvatarEditStateCopyWith(
    _AvatarEditState value,
    $Res Function(_AvatarEditState) _then,
  ) = __$AvatarEditStateCopyWithImpl;
  @override
  @useResult
  $Res call({AvatarPhase phase, double? progress, AvatarFailure? failure});
}

/// @nodoc
class __$AvatarEditStateCopyWithImpl<$Res>
    implements _$AvatarEditStateCopyWith<$Res> {
  __$AvatarEditStateCopyWithImpl(this._self, this._then);

  final _AvatarEditState _self;
  final $Res Function(_AvatarEditState) _then;

  /// Create a copy of AvatarEditState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? phase = null,
    Object? progress = freezed,
    Object? failure = freezed,
  }) {
    return _then(
      _AvatarEditState(
        phase: null == phase
            ? _self.phase
            : phase // ignore: cast_nullable_to_non_nullable
                  as AvatarPhase,
        progress: freezed == progress
            ? _self.progress
            : progress // ignore: cast_nullable_to_non_nullable
                  as double?,
        failure: freezed == failure
            ? _self.failure
            : failure // ignore: cast_nullable_to_non_nullable
                  as AvatarFailure?,
      ),
    );
  }
}
