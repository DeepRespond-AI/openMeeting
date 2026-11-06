// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recording_status.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RecordingStatus {
  bool get recording;
  String? get meetingId;

  /// Create a copy of RecordingStatus
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $RecordingStatusCopyWith<RecordingStatus> get copyWith =>
      _$RecordingStatusCopyWithImpl<RecordingStatus>(
        this as RecordingStatus,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    final _this = this as RecordingStatus;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is RecordingStatus &&
            (identical(other.recording, _this.recording) ||
                other.recording == _this.recording) &&
            (identical(other.meetingId, _this.meetingId) ||
                other.meetingId == _this.meetingId));
  }

  @override
  int get hashCode {
    final _this = this as RecordingStatus;
    return Object.hash(runtimeType, _this.recording, _this.meetingId);
  }

  @override
  String toString() {
    final _this = this as RecordingStatus;
    return 'RecordingStatus(recording: ${_this.recording}, meetingId: ${_this.meetingId})';
  }
}

/// @nodoc
abstract mixin class $RecordingStatusCopyWith<$Res> {
  factory $RecordingStatusCopyWith(
    RecordingStatus value,
    $Res Function(RecordingStatus) _then,
  ) = _$RecordingStatusCopyWithImpl;
  @useResult
  $Res call({bool recording, String? meetingId});
}

/// @nodoc
class _$RecordingStatusCopyWithImpl<$Res>
    implements $RecordingStatusCopyWith<$Res> {
  _$RecordingStatusCopyWithImpl(this._self, this._then);

  final RecordingStatus _self;
  final $Res Function(RecordingStatus) _then;

  /// Create a copy of RecordingStatus
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? recording = null, Object? meetingId = freezed}) {
    return _then(
      RecordingStatus(
        recording: null == recording
            ? _self.recording
            : recording // ignore: cast_nullable_to_non_nullable
                  as bool,
        meetingId: freezed == meetingId
            ? _self.meetingId
            : meetingId // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [RecordingStatus].
extension RecordingStatusPatterns on RecordingStatus {
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
    TResult Function(_RecordingStatus value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _RecordingStatus() when $default != null:
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
    TResult Function(_RecordingStatus value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RecordingStatus():
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
    TResult? Function(_RecordingStatus value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RecordingStatus() when $default != null:
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
    TResult Function(bool recording, String? meetingId)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _RecordingStatus() when $default != null:
        return $default(_that.recording, _that.meetingId);
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
    TResult Function(bool recording, String? meetingId) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RecordingStatus():
        return $default(_that.recording, _that.meetingId);
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
    TResult? Function(bool recording, String? meetingId)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RecordingStatus() when $default != null:
        return $default(_that.recording, _that.meetingId);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _RecordingStatus implements RecordingStatus {
  const _RecordingStatus({this.recording = false, this.meetingId});

  @override
  @JsonKey()
  final bool recording;
  @override
  final String? meetingId;

  /// Create a copy of RecordingStatus
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$RecordingStatusCopyWith<_RecordingStatus> get copyWith =>
      __$RecordingStatusCopyWithImpl<_RecordingStatus>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _RecordingStatus &&
            (identical(other.recording, recording) ||
                other.recording == recording) &&
            (identical(other.meetingId, meetingId) ||
                other.meetingId == meetingId));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, recording, meetingId);
  }

  @override
  String toString() {
    return 'RecordingStatus(recording: $recording, meetingId: $meetingId)';
  }
}

/// @nodoc
abstract mixin class _$RecordingStatusCopyWith<$Res>
    implements $RecordingStatusCopyWith<$Res> {
  factory _$RecordingStatusCopyWith(
    _RecordingStatus value,
    $Res Function(_RecordingStatus) _then,
  ) = __$RecordingStatusCopyWithImpl;
  @override
  @useResult
  $Res call({bool recording, String? meetingId});
}

/// @nodoc
class __$RecordingStatusCopyWithImpl<$Res>
    implements _$RecordingStatusCopyWith<$Res> {
  __$RecordingStatusCopyWithImpl(this._self, this._then);

  final _RecordingStatus _self;
  final $Res Function(_RecordingStatus) _then;

  /// Create a copy of RecordingStatus
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({Object? recording = null, Object? meetingId = freezed}) {
    return _then(
      _RecordingStatus(
        recording: null == recording
            ? _self.recording
            : recording // ignore: cast_nullable_to_non_nullable
                  as bool,
        meetingId: freezed == meetingId
            ? _self.meetingId
            : meetingId // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}
