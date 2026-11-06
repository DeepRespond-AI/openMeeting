// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'rtc_telemetry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NetworkMetrics {
  double? get rttMs;
  double? get lossPercent;
  DateTime get measuredAt;

  /// Create a copy of NetworkMetrics
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $NetworkMetricsCopyWith<NetworkMetrics> get copyWith =>
      _$NetworkMetricsCopyWithImpl<NetworkMetrics>(
        this as NetworkMetrics,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    final _this = this as NetworkMetrics;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is NetworkMetrics &&
            (identical(other.rttMs, _this.rttMs) ||
                other.rttMs == _this.rttMs) &&
            (identical(other.lossPercent, _this.lossPercent) ||
                other.lossPercent == _this.lossPercent) &&
            (identical(other.measuredAt, _this.measuredAt) ||
                other.measuredAt == _this.measuredAt));
  }

  @override
  int get hashCode {
    final _this = this as NetworkMetrics;
    return Object.hash(
      runtimeType,
      _this.rttMs,
      _this.lossPercent,
      _this.measuredAt,
    );
  }

  @override
  String toString() {
    final _this = this as NetworkMetrics;
    return 'NetworkMetrics(rttMs: ${_this.rttMs}, lossPercent: ${_this.lossPercent}, measuredAt: ${_this.measuredAt})';
  }
}

/// @nodoc
abstract mixin class $NetworkMetricsCopyWith<$Res> {
  factory $NetworkMetricsCopyWith(
    NetworkMetrics value,
    $Res Function(NetworkMetrics) _then,
  ) = _$NetworkMetricsCopyWithImpl;
  @useResult
  $Res call({double? rttMs, double? lossPercent, DateTime measuredAt});
}

/// @nodoc
class _$NetworkMetricsCopyWithImpl<$Res>
    implements $NetworkMetricsCopyWith<$Res> {
  _$NetworkMetricsCopyWithImpl(this._self, this._then);

  final NetworkMetrics _self;
  final $Res Function(NetworkMetrics) _then;

  /// Create a copy of NetworkMetrics
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? rttMs = freezed,
    Object? lossPercent = freezed,
    Object? measuredAt = null,
  }) {
    return _then(
      NetworkMetrics(
        rttMs: freezed == rttMs
            ? _self.rttMs
            : rttMs // ignore: cast_nullable_to_non_nullable
                  as double?,
        lossPercent: freezed == lossPercent
            ? _self.lossPercent
            : lossPercent // ignore: cast_nullable_to_non_nullable
                  as double?,
        measuredAt: null == measuredAt
            ? _self.measuredAt
            : measuredAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [NetworkMetrics].
extension NetworkMetricsPatterns on NetworkMetrics {
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
    TResult Function(_NetworkMetrics value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _NetworkMetrics() when $default != null:
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
    TResult Function(_NetworkMetrics value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _NetworkMetrics():
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
    TResult? Function(_NetworkMetrics value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _NetworkMetrics() when $default != null:
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
    TResult Function(double? rttMs, double? lossPercent, DateTime measuredAt)?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _NetworkMetrics() when $default != null:
        return $default(_that.rttMs, _that.lossPercent, _that.measuredAt);
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
    TResult Function(double? rttMs, double? lossPercent, DateTime measuredAt)
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _NetworkMetrics():
        return $default(_that.rttMs, _that.lossPercent, _that.measuredAt);
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
    TResult? Function(double? rttMs, double? lossPercent, DateTime measuredAt)?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _NetworkMetrics() when $default != null:
        return $default(_that.rttMs, _that.lossPercent, _that.measuredAt);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _NetworkMetrics extends NetworkMetrics {
  const _NetworkMetrics({
    this.rttMs,
    this.lossPercent,
    required this.measuredAt,
  }) : super._();

  @override
  final double? rttMs;
  @override
  final double? lossPercent;
  @override
  final DateTime measuredAt;

  /// Create a copy of NetworkMetrics
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$NetworkMetricsCopyWith<_NetworkMetrics> get copyWith =>
      __$NetworkMetricsCopyWithImpl<_NetworkMetrics>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _NetworkMetrics &&
            (identical(other.rttMs, rttMs) || other.rttMs == rttMs) &&
            (identical(other.lossPercent, lossPercent) ||
                other.lossPercent == lossPercent) &&
            (identical(other.measuredAt, measuredAt) ||
                other.measuredAt == measuredAt));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, rttMs, lossPercent, measuredAt);
  }

  @override
  String toString() {
    return 'NetworkMetrics(rttMs: $rttMs, lossPercent: $lossPercent, measuredAt: $measuredAt)';
  }
}

/// @nodoc
abstract mixin class _$NetworkMetricsCopyWith<$Res>
    implements $NetworkMetricsCopyWith<$Res> {
  factory _$NetworkMetricsCopyWith(
    _NetworkMetrics value,
    $Res Function(_NetworkMetrics) _then,
  ) = __$NetworkMetricsCopyWithImpl;
  @override
  @useResult
  $Res call({double? rttMs, double? lossPercent, DateTime measuredAt});
}

/// @nodoc
class __$NetworkMetricsCopyWithImpl<$Res>
    implements _$NetworkMetricsCopyWith<$Res> {
  __$NetworkMetricsCopyWithImpl(this._self, this._then);

  final _NetworkMetrics _self;
  final $Res Function(_NetworkMetrics) _then;

  /// Create a copy of NetworkMetrics
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? rttMs = freezed,
    Object? lossPercent = freezed,
    Object? measuredAt = null,
  }) {
    return _then(
      _NetworkMetrics(
        rttMs: freezed == rttMs
            ? _self.rttMs
            : rttMs // ignore: cast_nullable_to_non_nullable
                  as double?,
        lossPercent: freezed == lossPercent
            ? _self.lossPercent
            : lossPercent // ignore: cast_nullable_to_non_nullable
                  as double?,
        measuredAt: null == measuredAt
            ? _self.measuredAt
            : measuredAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
mixin _$RoomMetrics {
  String? get speaker;
  Map<String, NetworkMetrics> get network;

  /// Create a copy of RoomMetrics
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $RoomMetricsCopyWith<RoomMetrics> get copyWith =>
      _$RoomMetricsCopyWithImpl<RoomMetrics>(this as RoomMetrics, _$identity);

  @override
  bool operator ==(Object other) {
    final _this = this as RoomMetrics;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is RoomMetrics &&
            (identical(other.speaker, _this.speaker) ||
                other.speaker == _this.speaker) &&
            const DeepCollectionEquality().equals(
              other.network,
              _this.network,
            ));
  }

  @override
  int get hashCode {
    final _this = this as RoomMetrics;
    return Object.hash(
      runtimeType,
      _this.speaker,
      const DeepCollectionEquality().hash(_this.network),
    );
  }

  @override
  String toString() {
    final _this = this as RoomMetrics;
    return 'RoomMetrics(speaker: ${_this.speaker}, network: ${_this.network})';
  }
}

/// @nodoc
abstract mixin class $RoomMetricsCopyWith<$Res> {
  factory $RoomMetricsCopyWith(
    RoomMetrics value,
    $Res Function(RoomMetrics) _then,
  ) = _$RoomMetricsCopyWithImpl;
  @useResult
  $Res call({String? speaker, Map<String, NetworkMetrics> network});
}

/// @nodoc
class _$RoomMetricsCopyWithImpl<$Res> implements $RoomMetricsCopyWith<$Res> {
  _$RoomMetricsCopyWithImpl(this._self, this._then);

  final RoomMetrics _self;
  final $Res Function(RoomMetrics) _then;

  /// Create a copy of RoomMetrics
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? speaker = freezed, Object? network = null}) {
    return _then(
      RoomMetrics(
        speaker: freezed == speaker
            ? _self.speaker
            : speaker // ignore: cast_nullable_to_non_nullable
                  as String?,
        network: null == network
            ? _self.network
            : network // ignore: cast_nullable_to_non_nullable
                  as Map<String, NetworkMetrics>,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [RoomMetrics].
extension RoomMetricsPatterns on RoomMetrics {
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
    TResult Function(_RoomMetrics value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _RoomMetrics() when $default != null:
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
    TResult Function(_RoomMetrics value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RoomMetrics():
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
    TResult? Function(_RoomMetrics value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RoomMetrics() when $default != null:
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
    TResult Function(String? speaker, Map<String, NetworkMetrics> network)?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _RoomMetrics() when $default != null:
        return $default(_that.speaker, _that.network);
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
    TResult Function(String? speaker, Map<String, NetworkMetrics> network)
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RoomMetrics():
        return $default(_that.speaker, _that.network);
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
    TResult? Function(String? speaker, Map<String, NetworkMetrics> network)?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RoomMetrics() when $default != null:
        return $default(_that.speaker, _that.network);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _RoomMetrics implements RoomMetrics {
  const _RoomMetrics({
    this.speaker,
    Map<String, NetworkMetrics> network = const {},
  }) : _network = network;

  @override
  final String? speaker;
  final Map<String, NetworkMetrics> _network;
  @override
  @JsonKey()
  Map<String, NetworkMetrics> get network {
    if (_network is EqualUnmodifiableMapView) return _network;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_network);
  }

  /// Create a copy of RoomMetrics
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$RoomMetricsCopyWith<_RoomMetrics> get copyWith =>
      __$RoomMetricsCopyWithImpl<_RoomMetrics>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _RoomMetrics &&
            (identical(other.speaker, speaker) || other.speaker == speaker) &&
            const DeepCollectionEquality().equals(other.network, _network));
  }

  @override
  int get hashCode {
    return Object.hash(
      runtimeType,
      speaker,
      const DeepCollectionEquality().hash(_network),
    );
  }

  @override
  String toString() {
    return 'RoomMetrics(speaker: $speaker, network: $network)';
  }
}

/// @nodoc
abstract mixin class _$RoomMetricsCopyWith<$Res>
    implements $RoomMetricsCopyWith<$Res> {
  factory _$RoomMetricsCopyWith(
    _RoomMetrics value,
    $Res Function(_RoomMetrics) _then,
  ) = __$RoomMetricsCopyWithImpl;
  @override
  @useResult
  $Res call({String? speaker, Map<String, NetworkMetrics> network});
}

/// @nodoc
class __$RoomMetricsCopyWithImpl<$Res> implements _$RoomMetricsCopyWith<$Res> {
  __$RoomMetricsCopyWithImpl(this._self, this._then);

  final _RoomMetrics _self;
  final $Res Function(_RoomMetrics) _then;

  /// Create a copy of RoomMetrics
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({Object? speaker = freezed, Object? network = null}) {
    return _then(
      _RoomMetrics(
        speaker: freezed == speaker
            ? _self.speaker
            : speaker // ignore: cast_nullable_to_non_nullable
                  as String?,
        network: null == network
            ? _self._network
            : network // ignore: cast_nullable_to_non_nullable
                  as Map<String, NetworkMetrics>,
      ),
    );
  }
}
