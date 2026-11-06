// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'update_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UpdateState implements DiagnosticableTreeMixin {
  /// The release offered by the server; null = up to date (or not checked yet).
  UpdateOffer? get offer;
  UpdatePhase get phase;

  /// Download progress 0..1; null while the size is unknown.
  double? get progress;
  UpdateFailure? get failure;

  /// Create a copy of UpdateState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $UpdateStateCopyWith<UpdateState> get copyWith =>
      _$UpdateStateCopyWithImpl<UpdateState>(this as UpdateState, _$identity);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    final _this = this as UpdateState;
    properties
      ..add(DiagnosticsProperty('type', 'UpdateState'))
      ..add(DiagnosticsProperty('offer', _this.offer))
      ..add(DiagnosticsProperty('phase', _this.phase))
      ..add(DiagnosticsProperty('progress', _this.progress))
      ..add(DiagnosticsProperty('failure', _this.failure));
  }

  @override
  bool operator ==(Object other) {
    final _this = this as UpdateState;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is UpdateState &&
            (identical(other.offer, _this.offer) ||
                other.offer == _this.offer) &&
            (identical(other.phase, _this.phase) ||
                other.phase == _this.phase) &&
            (identical(other.progress, _this.progress) ||
                other.progress == _this.progress) &&
            (identical(other.failure, _this.failure) ||
                other.failure == _this.failure));
  }

  @override
  int get hashCode {
    final _this = this as UpdateState;
    return Object.hash(
      runtimeType,
      _this.offer,
      _this.phase,
      _this.progress,
      _this.failure,
    );
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    final _this = this as UpdateState;
    return 'UpdateState(offer: ${_this.offer}, phase: ${_this.phase}, progress: ${_this.progress}, failure: ${_this.failure})';
  }
}

/// @nodoc
abstract mixin class $UpdateStateCopyWith<$Res> {
  factory $UpdateStateCopyWith(
    UpdateState value,
    $Res Function(UpdateState) _then,
  ) = _$UpdateStateCopyWithImpl;
  @useResult
  $Res call({
    UpdateOffer? offer,
    UpdatePhase phase,
    double? progress,
    UpdateFailure? failure,
  });

  $UpdateOfferCopyWith<$Res>? get offer;
}

/// @nodoc
class _$UpdateStateCopyWithImpl<$Res> implements $UpdateStateCopyWith<$Res> {
  _$UpdateStateCopyWithImpl(this._self, this._then);

  final UpdateState _self;
  final $Res Function(UpdateState) _then;

  /// Create a copy of UpdateState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? offer = freezed,
    Object? phase = null,
    Object? progress = freezed,
    Object? failure = freezed,
  }) {
    return _then(
      UpdateState(
        offer: freezed == offer
            ? _self.offer
            : offer // ignore: cast_nullable_to_non_nullable
                  as UpdateOffer?,
        phase: null == phase
            ? _self.phase
            : phase // ignore: cast_nullable_to_non_nullable
                  as UpdatePhase,
        progress: freezed == progress
            ? _self.progress
            : progress // ignore: cast_nullable_to_non_nullable
                  as double?,
        failure: freezed == failure
            ? _self.failure
            : failure // ignore: cast_nullable_to_non_nullable
                  as UpdateFailure?,
      ),
    );
  }

  /// Create a copy of UpdateState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $UpdateOfferCopyWith<$Res>? get offer {
    if (_self.offer == null) {
      return null;
    }

    return $UpdateOfferCopyWith<$Res>(_self.offer!, (value) {
      return _then(_self.copyWith(offer: value));
    });
  }
}

/// Adds pattern-matching-related methods to [UpdateState].
extension UpdateStatePatterns on UpdateState {
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
    TResult Function(_UpdateState value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _UpdateState() when $default != null:
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
    TResult Function(_UpdateState value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UpdateState():
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
    TResult? Function(_UpdateState value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UpdateState() when $default != null:
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
      UpdateOffer? offer,
      UpdatePhase phase,
      double? progress,
      UpdateFailure? failure,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _UpdateState() when $default != null:
        return $default(
          _that.offer,
          _that.phase,
          _that.progress,
          _that.failure,
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
      UpdateOffer? offer,
      UpdatePhase phase,
      double? progress,
      UpdateFailure? failure,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UpdateState():
        return $default(
          _that.offer,
          _that.phase,
          _that.progress,
          _that.failure,
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
      UpdateOffer? offer,
      UpdatePhase phase,
      double? progress,
      UpdateFailure? failure,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UpdateState() when $default != null:
        return $default(
          _that.offer,
          _that.phase,
          _that.progress,
          _that.failure,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc

class _UpdateState extends UpdateState with DiagnosticableTreeMixin {
  const _UpdateState({
    this.offer,
    this.phase = UpdatePhase.idle,
    this.progress,
    this.failure,
  }) : super._();

  /// The release offered by the server; null = up to date (or not checked yet).
  @override
  final UpdateOffer? offer;
  @override
  @JsonKey()
  final UpdatePhase phase;

  /// Download progress 0..1; null while the size is unknown.
  @override
  final double? progress;
  @override
  final UpdateFailure? failure;

  /// Create a copy of UpdateState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$UpdateStateCopyWith<_UpdateState> get copyWith =>
      __$UpdateStateCopyWithImpl<_UpdateState>(this, _$identity);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'UpdateState'))
      ..add(DiagnosticsProperty('offer', offer))
      ..add(DiagnosticsProperty('phase', phase))
      ..add(DiagnosticsProperty('progress', progress))
      ..add(DiagnosticsProperty('failure', failure));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _UpdateState &&
            (identical(other.offer, offer) || other.offer == offer) &&
            (identical(other.phase, phase) || other.phase == phase) &&
            (identical(other.progress, progress) ||
                other.progress == progress) &&
            (identical(other.failure, failure) || other.failure == failure));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, offer, phase, progress, failure);
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'UpdateState(offer: $offer, phase: $phase, progress: $progress, failure: $failure)';
  }
}

/// @nodoc
abstract mixin class _$UpdateStateCopyWith<$Res>
    implements $UpdateStateCopyWith<$Res> {
  factory _$UpdateStateCopyWith(
    _UpdateState value,
    $Res Function(_UpdateState) _then,
  ) = __$UpdateStateCopyWithImpl;
  @override
  @useResult
  $Res call({
    UpdateOffer? offer,
    UpdatePhase phase,
    double? progress,
    UpdateFailure? failure,
  });

  @override
  $UpdateOfferCopyWith<$Res>? get offer;
}

/// @nodoc
class __$UpdateStateCopyWithImpl<$Res> implements _$UpdateStateCopyWith<$Res> {
  __$UpdateStateCopyWithImpl(this._self, this._then);

  final _UpdateState _self;
  final $Res Function(_UpdateState) _then;

  /// Create a copy of UpdateState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? offer = freezed,
    Object? phase = null,
    Object? progress = freezed,
    Object? failure = freezed,
  }) {
    return _then(
      _UpdateState(
        offer: freezed == offer
            ? _self.offer
            : offer // ignore: cast_nullable_to_non_nullable
                  as UpdateOffer?,
        phase: null == phase
            ? _self.phase
            : phase // ignore: cast_nullable_to_non_nullable
                  as UpdatePhase,
        progress: freezed == progress
            ? _self.progress
            : progress // ignore: cast_nullable_to_non_nullable
                  as double?,
        failure: freezed == failure
            ? _self.failure
            : failure // ignore: cast_nullable_to_non_nullable
                  as UpdateFailure?,
      ),
    );
  }

  /// Create a copy of UpdateState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $UpdateOfferCopyWith<$Res>? get offer {
    if (_self.offer == null) {
      return null;
    }

    return $UpdateOfferCopyWith<$Res>(_self.offer!, (value) {
      return _then(_self.copyWith(offer: value));
    });
  }
}
