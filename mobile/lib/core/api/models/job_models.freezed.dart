// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'job_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Job {
  String get id;
  @JsonKey(unknownEnumValue: JobKind.unknown)
  JobKind get kind;
  @JsonKey(unknownEnumValue: JobStatus.unknown)
  JobStatus get status;

  /// 0..100.
  int get progress;
  String? get message;
  @JsonKey(name: 'meeting_id')
  String? get meetingId;
  String? get error;
  int? get segments;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;

  /// Create a copy of Job
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $JobCopyWith<Job> get copyWith =>
      _$JobCopyWithImpl<Job>(this as Job, _$identity);

  /// Serializes this Job to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as Job;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Job &&
            (identical(other.id, _this.id) || other.id == _this.id) &&
            (identical(other.kind, _this.kind) || other.kind == _this.kind) &&
            (identical(other.status, _this.status) ||
                other.status == _this.status) &&
            (identical(other.progress, _this.progress) ||
                other.progress == _this.progress) &&
            (identical(other.message, _this.message) ||
                other.message == _this.message) &&
            (identical(other.meetingId, _this.meetingId) ||
                other.meetingId == _this.meetingId) &&
            (identical(other.error, _this.error) ||
                other.error == _this.error) &&
            (identical(other.segments, _this.segments) ||
                other.segments == _this.segments) &&
            (identical(other.createdAt, _this.createdAt) ||
                other.createdAt == _this.createdAt) &&
            (identical(other.updatedAt, _this.updatedAt) ||
                other.updatedAt == _this.updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as Job;
    return Object.hash(
      runtimeType,
      _this.id,
      _this.kind,
      _this.status,
      _this.progress,
      _this.message,
      _this.meetingId,
      _this.error,
      _this.segments,
      _this.createdAt,
      _this.updatedAt,
    );
  }

  @override
  String toString() {
    final _this = this as Job;
    return 'Job(id: ${_this.id}, kind: ${_this.kind}, status: ${_this.status}, progress: ${_this.progress}, message: ${_this.message}, meetingId: ${_this.meetingId}, error: ${_this.error}, segments: ${_this.segments}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt})';
  }
}

/// @nodoc
abstract mixin class $JobCopyWith<$Res> {
  factory $JobCopyWith(Job value, $Res Function(Job) _then) = _$JobCopyWithImpl;
  @useResult
  $Res call({
    String id,
    @JsonKey(unknownEnumValue: JobKind.unknown) JobKind kind,
    @JsonKey(unknownEnumValue: JobStatus.unknown) JobStatus status,
    int progress,
    String? message,
    @JsonKey(name: 'meeting_id') String? meetingId,
    String? error,
    int? segments,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  });
}

/// @nodoc
class _$JobCopyWithImpl<$Res> implements $JobCopyWith<$Res> {
  _$JobCopyWithImpl(this._self, this._then);

  final Job _self;
  final $Res Function(Job) _then;

  /// Create a copy of Job
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? kind = null,
    Object? status = null,
    Object? progress = null,
    Object? message = freezed,
    Object? meetingId = freezed,
    Object? error = freezed,
    Object? segments = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      Job(
        id: null == id
            ? _self.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        kind: null == kind
            ? _self.kind
            : kind // ignore: cast_nullable_to_non_nullable
                  as JobKind,
        status: null == status
            ? _self.status
            : status // ignore: cast_nullable_to_non_nullable
                  as JobStatus,
        progress: null == progress
            ? _self.progress
            : progress // ignore: cast_nullable_to_non_nullable
                  as int,
        message: freezed == message
            ? _self.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String?,
        meetingId: freezed == meetingId
            ? _self.meetingId
            : meetingId // ignore: cast_nullable_to_non_nullable
                  as String?,
        error: freezed == error
            ? _self.error
            : error // ignore: cast_nullable_to_non_nullable
                  as String?,
        segments: freezed == segments
            ? _self.segments
            : segments // ignore: cast_nullable_to_non_nullable
                  as int?,
        createdAt: freezed == createdAt
            ? _self.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        updatedAt: freezed == updatedAt
            ? _self.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [Job].
extension JobPatterns on Job {
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
    TResult Function(_Job value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Job() when $default != null:
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
  TResult map<TResult extends Object?>(TResult Function(_Job value) $default) {
    final _that = this;
    switch (_that) {
      case _Job():
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
    TResult? Function(_Job value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Job() when $default != null:
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
      String id,
      @JsonKey(unknownEnumValue: JobKind.unknown) JobKind kind,
      @JsonKey(unknownEnumValue: JobStatus.unknown) JobStatus status,
      int progress,
      String? message,
      @JsonKey(name: 'meeting_id') String? meetingId,
      String? error,
      int? segments,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Job() when $default != null:
        return $default(
          _that.id,
          _that.kind,
          _that.status,
          _that.progress,
          _that.message,
          _that.meetingId,
          _that.error,
          _that.segments,
          _that.createdAt,
          _that.updatedAt,
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
      String id,
      @JsonKey(unknownEnumValue: JobKind.unknown) JobKind kind,
      @JsonKey(unknownEnumValue: JobStatus.unknown) JobStatus status,
      int progress,
      String? message,
      @JsonKey(name: 'meeting_id') String? meetingId,
      String? error,
      int? segments,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Job():
        return $default(
          _that.id,
          _that.kind,
          _that.status,
          _that.progress,
          _that.message,
          _that.meetingId,
          _that.error,
          _that.segments,
          _that.createdAt,
          _that.updatedAt,
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
      String id,
      @JsonKey(unknownEnumValue: JobKind.unknown) JobKind kind,
      @JsonKey(unknownEnumValue: JobStatus.unknown) JobStatus status,
      int progress,
      String? message,
      @JsonKey(name: 'meeting_id') String? meetingId,
      String? error,
      int? segments,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Job() when $default != null:
        return $default(
          _that.id,
          _that.kind,
          _that.status,
          _that.progress,
          _that.message,
          _that.meetingId,
          _that.error,
          _that.segments,
          _that.createdAt,
          _that.updatedAt,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _Job implements Job {
  const _Job({
    required this.id,
    @JsonKey(unknownEnumValue: JobKind.unknown) required this.kind,
    @JsonKey(unknownEnumValue: JobStatus.unknown) required this.status,
    this.progress = 0,
    this.message,
    @JsonKey(name: 'meeting_id') this.meetingId,
    this.error,
    this.segments,
    @JsonKey(name: 'created_at') this.createdAt,
    @JsonKey(name: 'updated_at') this.updatedAt,
  });
  factory _Job.fromJson(Map<String, dynamic> json) => _$JobFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(unknownEnumValue: JobKind.unknown)
  final JobKind kind;
  @override
  @JsonKey(unknownEnumValue: JobStatus.unknown)
  final JobStatus status;

  /// 0..100.
  @override
  @JsonKey()
  final int progress;
  @override
  final String? message;
  @override
  @JsonKey(name: 'meeting_id')
  final String? meetingId;
  @override
  final String? error;
  @override
  final int? segments;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  /// Create a copy of Job
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$JobCopyWith<_Job> get copyWith =>
      __$JobCopyWithImpl<_Job>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$JobToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Job &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.progress, progress) ||
                other.progress == progress) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.meetingId, meetingId) ||
                other.meetingId == meetingId) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.segments, segments) ||
                other.segments == segments) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(
      runtimeType,
      id,
      kind,
      status,
      progress,
      message,
      meetingId,
      error,
      segments,
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'Job(id: $id, kind: $kind, status: $status, progress: $progress, message: $message, meetingId: $meetingId, error: $error, segments: $segments, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class _$JobCopyWith<$Res> implements $JobCopyWith<$Res> {
  factory _$JobCopyWith(_Job value, $Res Function(_Job) _then) =
      __$JobCopyWithImpl;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(unknownEnumValue: JobKind.unknown) JobKind kind,
    @JsonKey(unknownEnumValue: JobStatus.unknown) JobStatus status,
    int progress,
    String? message,
    @JsonKey(name: 'meeting_id') String? meetingId,
    String? error,
    int? segments,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  });
}

/// @nodoc
class __$JobCopyWithImpl<$Res> implements _$JobCopyWith<$Res> {
  __$JobCopyWithImpl(this._self, this._then);

  final _Job _self;
  final $Res Function(_Job) _then;

  /// Create a copy of Job
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? kind = null,
    Object? status = null,
    Object? progress = null,
    Object? message = freezed,
    Object? meetingId = freezed,
    Object? error = freezed,
    Object? segments = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _Job(
        id: null == id
            ? _self.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        kind: null == kind
            ? _self.kind
            : kind // ignore: cast_nullable_to_non_nullable
                  as JobKind,
        status: null == status
            ? _self.status
            : status // ignore: cast_nullable_to_non_nullable
                  as JobStatus,
        progress: null == progress
            ? _self.progress
            : progress // ignore: cast_nullable_to_non_nullable
                  as int,
        message: freezed == message
            ? _self.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String?,
        meetingId: freezed == meetingId
            ? _self.meetingId
            : meetingId // ignore: cast_nullable_to_non_nullable
                  as String?,
        error: freezed == error
            ? _self.error
            : error // ignore: cast_nullable_to_non_nullable
                  as String?,
        segments: freezed == segments
            ? _self.segments
            : segments // ignore: cast_nullable_to_non_nullable
                  as int?,
        createdAt: freezed == createdAt
            ? _self.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        updatedAt: freezed == updatedAt
            ? _self.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}
