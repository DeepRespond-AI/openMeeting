// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'onboarding_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$OnboardingState {
  OnboardingStep get step;

  /// `completeOnboarding()` in flight.
  bool get finishing;

  /// Create a copy of OnboardingState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $OnboardingStateCopyWith<OnboardingState> get copyWith =>
      _$OnboardingStateCopyWithImpl<OnboardingState>(
        this as OnboardingState,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    final _this = this as OnboardingState;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is OnboardingState &&
            (identical(other.step, _this.step) || other.step == _this.step) &&
            (identical(other.finishing, _this.finishing) ||
                other.finishing == _this.finishing));
  }

  @override
  int get hashCode {
    final _this = this as OnboardingState;
    return Object.hash(runtimeType, _this.step, _this.finishing);
  }

  @override
  String toString() {
    final _this = this as OnboardingState;
    return 'OnboardingState(step: ${_this.step}, finishing: ${_this.finishing})';
  }
}

/// @nodoc
abstract mixin class $OnboardingStateCopyWith<$Res> {
  factory $OnboardingStateCopyWith(
    OnboardingState value,
    $Res Function(OnboardingState) _then,
  ) = _$OnboardingStateCopyWithImpl;
  @useResult
  $Res call({OnboardingStep step, bool finishing});
}

/// @nodoc
class _$OnboardingStateCopyWithImpl<$Res>
    implements $OnboardingStateCopyWith<$Res> {
  _$OnboardingStateCopyWithImpl(this._self, this._then);

  final OnboardingState _self;
  final $Res Function(OnboardingState) _then;

  /// Create a copy of OnboardingState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? step = null, Object? finishing = null}) {
    return _then(
      OnboardingState(
        step: null == step
            ? _self.step
            : step // ignore: cast_nullable_to_non_nullable
                  as OnboardingStep,
        finishing: null == finishing
            ? _self.finishing
            : finishing // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [OnboardingState].
extension OnboardingStatePatterns on OnboardingState {
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
    TResult Function(_OnboardingState value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _OnboardingState() when $default != null:
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
    TResult Function(_OnboardingState value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _OnboardingState():
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
    TResult? Function(_OnboardingState value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _OnboardingState() when $default != null:
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
    TResult Function(OnboardingStep step, bool finishing)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _OnboardingState() when $default != null:
        return $default(_that.step, _that.finishing);
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
    TResult Function(OnboardingStep step, bool finishing) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _OnboardingState():
        return $default(_that.step, _that.finishing);
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
    TResult? Function(OnboardingStep step, bool finishing)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _OnboardingState() when $default != null:
        return $default(_that.step, _that.finishing);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _OnboardingState extends OnboardingState {
  const _OnboardingState({
    this.step = OnboardingStep.welcome,
    this.finishing = false,
  }) : super._();

  @override
  @JsonKey()
  final OnboardingStep step;

  /// `completeOnboarding()` in flight.
  @override
  @JsonKey()
  final bool finishing;

  /// Create a copy of OnboardingState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$OnboardingStateCopyWith<_OnboardingState> get copyWith =>
      __$OnboardingStateCopyWithImpl<_OnboardingState>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _OnboardingState &&
            (identical(other.step, step) || other.step == step) &&
            (identical(other.finishing, finishing) ||
                other.finishing == finishing));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, step, finishing);
  }

  @override
  String toString() {
    return 'OnboardingState(step: $step, finishing: $finishing)';
  }
}

/// @nodoc
abstract mixin class _$OnboardingStateCopyWith<$Res>
    implements $OnboardingStateCopyWith<$Res> {
  factory _$OnboardingStateCopyWith(
    _OnboardingState value,
    $Res Function(_OnboardingState) _then,
  ) = __$OnboardingStateCopyWithImpl;
  @override
  @useResult
  $Res call({OnboardingStep step, bool finishing});
}

/// @nodoc
class __$OnboardingStateCopyWithImpl<$Res>
    implements _$OnboardingStateCopyWith<$Res> {
  __$OnboardingStateCopyWithImpl(this._self, this._then);

  final _OnboardingState _self;
  final $Res Function(_OnboardingState) _then;

  /// Create a copy of OnboardingState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({Object? step = null, Object? finishing = null}) {
    return _then(
      _OnboardingState(
        step: null == step
            ? _self.step
            : step // ignore: cast_nullable_to_non_nullable
                  as OnboardingStep,
        finishing: null == finishing
            ? _self.finishing
            : finishing // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}
