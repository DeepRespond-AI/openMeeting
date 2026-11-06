// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'heartbeat_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HeartbeatState {
  /// True while signed in (beats are being sent).
  bool get active;

  /// App is in the foreground (resumed).
  bool get foreground;
  DateTime? get lastSuccessAt;

  /// Last failure (network errors are kept here; they never sign the user out).
  ApiException? get lastError;
  String? get serverVersion;

  /// Create a copy of HeartbeatState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $HeartbeatStateCopyWith<HeartbeatState> get copyWith =>
      _$HeartbeatStateCopyWithImpl<HeartbeatState>(
        this as HeartbeatState,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    final _this = this as HeartbeatState;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is HeartbeatState &&
            (identical(other.active, _this.active) ||
                other.active == _this.active) &&
            (identical(other.foreground, _this.foreground) ||
                other.foreground == _this.foreground) &&
            (identical(other.lastSuccessAt, _this.lastSuccessAt) ||
                other.lastSuccessAt == _this.lastSuccessAt) &&
            (identical(other.lastError, _this.lastError) ||
                other.lastError == _this.lastError) &&
            (identical(other.serverVersion, _this.serverVersion) ||
                other.serverVersion == _this.serverVersion));
  }

  @override
  int get hashCode {
    final _this = this as HeartbeatState;
    return Object.hash(
      runtimeType,
      _this.active,
      _this.foreground,
      _this.lastSuccessAt,
      _this.lastError,
      _this.serverVersion,
    );
  }

  @override
  String toString() {
    final _this = this as HeartbeatState;
    return 'HeartbeatState(active: ${_this.active}, foreground: ${_this.foreground}, lastSuccessAt: ${_this.lastSuccessAt}, lastError: ${_this.lastError}, serverVersion: ${_this.serverVersion})';
  }
}

/// @nodoc
abstract mixin class $HeartbeatStateCopyWith<$Res> {
  factory $HeartbeatStateCopyWith(
    HeartbeatState value,
    $Res Function(HeartbeatState) _then,
  ) = _$HeartbeatStateCopyWithImpl;
  @useResult
  $Res call({
    bool active,
    bool foreground,
    DateTime? lastSuccessAt,
    ApiException? lastError,
    String? serverVersion,
  });
}

/// @nodoc
class _$HeartbeatStateCopyWithImpl<$Res>
    implements $HeartbeatStateCopyWith<$Res> {
  _$HeartbeatStateCopyWithImpl(this._self, this._then);

  final HeartbeatState _self;
  final $Res Function(HeartbeatState) _then;

  /// Create a copy of HeartbeatState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? active = null,
    Object? foreground = null,
    Object? lastSuccessAt = freezed,
    Object? lastError = freezed,
    Object? serverVersion = freezed,
  }) {
    return _then(
      HeartbeatState(
        active: null == active
            ? _self.active
            : active // ignore: cast_nullable_to_non_nullable
                  as bool,
        foreground: null == foreground
            ? _self.foreground
            : foreground // ignore: cast_nullable_to_non_nullable
                  as bool,
        lastSuccessAt: freezed == lastSuccessAt
            ? _self.lastSuccessAt
            : lastSuccessAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        lastError: freezed == lastError
            ? _self.lastError
            : lastError // ignore: cast_nullable_to_non_nullable
                  as ApiException?,
        serverVersion: freezed == serverVersion
            ? _self.serverVersion
            : serverVersion // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [HeartbeatState].
extension HeartbeatStatePatterns on HeartbeatState {
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
    TResult Function(_HeartbeatState value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _HeartbeatState() when $default != null:
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
    TResult Function(_HeartbeatState value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HeartbeatState():
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
    TResult? Function(_HeartbeatState value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HeartbeatState() when $default != null:
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
      bool active,
      bool foreground,
      DateTime? lastSuccessAt,
      ApiException? lastError,
      String? serverVersion,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _HeartbeatState() when $default != null:
        return $default(
          _that.active,
          _that.foreground,
          _that.lastSuccessAt,
          _that.lastError,
          _that.serverVersion,
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
      bool active,
      bool foreground,
      DateTime? lastSuccessAt,
      ApiException? lastError,
      String? serverVersion,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HeartbeatState():
        return $default(
          _that.active,
          _that.foreground,
          _that.lastSuccessAt,
          _that.lastError,
          _that.serverVersion,
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
      bool active,
      bool foreground,
      DateTime? lastSuccessAt,
      ApiException? lastError,
      String? serverVersion,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HeartbeatState() when $default != null:
        return $default(
          _that.active,
          _that.foreground,
          _that.lastSuccessAt,
          _that.lastError,
          _that.serverVersion,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc

class _HeartbeatState extends HeartbeatState {
  const _HeartbeatState({
    this.active = false,
    this.foreground = true,
    this.lastSuccessAt,
    this.lastError,
    this.serverVersion,
  }) : super._();

  /// True while signed in (beats are being sent).
  @override
  @JsonKey()
  final bool active;

  /// App is in the foreground (resumed).
  @override
  @JsonKey()
  final bool foreground;
  @override
  final DateTime? lastSuccessAt;

  /// Last failure (network errors are kept here; they never sign the user out).
  @override
  final ApiException? lastError;
  @override
  final String? serverVersion;

  /// Create a copy of HeartbeatState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$HeartbeatStateCopyWith<_HeartbeatState> get copyWith =>
      __$HeartbeatStateCopyWithImpl<_HeartbeatState>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _HeartbeatState &&
            (identical(other.active, active) || other.active == active) &&
            (identical(other.foreground, foreground) ||
                other.foreground == foreground) &&
            (identical(other.lastSuccessAt, lastSuccessAt) ||
                other.lastSuccessAt == lastSuccessAt) &&
            (identical(other.lastError, lastError) ||
                other.lastError == lastError) &&
            (identical(other.serverVersion, serverVersion) ||
                other.serverVersion == serverVersion));
  }

  @override
  int get hashCode {
    return Object.hash(
      runtimeType,
      active,
      foreground,
      lastSuccessAt,
      lastError,
      serverVersion,
    );
  }

  @override
  String toString() {
    return 'HeartbeatState(active: $active, foreground: $foreground, lastSuccessAt: $lastSuccessAt, lastError: $lastError, serverVersion: $serverVersion)';
  }
}

/// @nodoc
abstract mixin class _$HeartbeatStateCopyWith<$Res>
    implements $HeartbeatStateCopyWith<$Res> {
  factory _$HeartbeatStateCopyWith(
    _HeartbeatState value,
    $Res Function(_HeartbeatState) _then,
  ) = __$HeartbeatStateCopyWithImpl;
  @override
  @useResult
  $Res call({
    bool active,
    bool foreground,
    DateTime? lastSuccessAt,
    ApiException? lastError,
    String? serverVersion,
  });
}

/// @nodoc
class __$HeartbeatStateCopyWithImpl<$Res>
    implements _$HeartbeatStateCopyWith<$Res> {
  __$HeartbeatStateCopyWithImpl(this._self, this._then);

  final _HeartbeatState _self;
  final $Res Function(_HeartbeatState) _then;

  /// Create a copy of HeartbeatState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? active = null,
    Object? foreground = null,
    Object? lastSuccessAt = freezed,
    Object? lastError = freezed,
    Object? serverVersion = freezed,
  }) {
    return _then(
      _HeartbeatState(
        active: null == active
            ? _self.active
            : active // ignore: cast_nullable_to_non_nullable
                  as bool,
        foreground: null == foreground
            ? _self.foreground
            : foreground // ignore: cast_nullable_to_non_nullable
                  as bool,
        lastSuccessAt: freezed == lastSuccessAt
            ? _self.lastSuccessAt
            : lastSuccessAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        lastError: freezed == lastError
            ? _self.lastError
            : lastError // ignore: cast_nullable_to_non_nullable
                  as ApiException?,
        serverVersion: freezed == serverVersion
            ? _self.serverVersion
            : serverVersion // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}
