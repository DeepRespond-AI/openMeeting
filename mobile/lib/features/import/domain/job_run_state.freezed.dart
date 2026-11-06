// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'job_run_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$JobRunState {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is JobRunState);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'JobRunState()';
  }
}

/// @nodoc
class $JobRunStateCopyWith<$Res> {
  $JobRunStateCopyWith(JobRunState _, $Res Function(JobRunState) __);
}

/// Adds pattern-matching-related methods to [JobRunState].
extension JobRunStatePatterns on JobRunState {
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
  TResult maybeMap<TResult extends Object?>({
    TResult Function(JobIdle value)? idle,
    TResult Function(JobUploading value)? uploading,
    TResult Function(JobSubmitted value)? submitted,
    TResult Function(JobRunning value)? running,
    TResult Function(JobCompleted value)? completed,
    TResult Function(JobFailed value)? failed,
    TResult Function(JobCancelled value)? cancelled,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case JobIdle() when idle != null:
        return idle(_that);
      case JobUploading() when uploading != null:
        return uploading(_that);
      case JobSubmitted() when submitted != null:
        return submitted(_that);
      case JobRunning() when running != null:
        return running(_that);
      case JobCompleted() when completed != null:
        return completed(_that);
      case JobFailed() when failed != null:
        return failed(_that);
      case JobCancelled() when cancelled != null:
        return cancelled(_that);
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
  TResult map<TResult extends Object?>({
    required TResult Function(JobIdle value) idle,
    required TResult Function(JobUploading value) uploading,
    required TResult Function(JobSubmitted value) submitted,
    required TResult Function(JobRunning value) running,
    required TResult Function(JobCompleted value) completed,
    required TResult Function(JobFailed value) failed,
    required TResult Function(JobCancelled value) cancelled,
  }) {
    final _that = this;
    switch (_that) {
      case JobIdle():
        return idle(_that);
      case JobUploading():
        return uploading(_that);
      case JobSubmitted():
        return submitted(_that);
      case JobRunning():
        return running(_that);
      case JobCompleted():
        return completed(_that);
      case JobFailed():
        return failed(_that);
      case JobCancelled():
        return cancelled(_that);
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
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(JobIdle value)? idle,
    TResult? Function(JobUploading value)? uploading,
    TResult? Function(JobSubmitted value)? submitted,
    TResult? Function(JobRunning value)? running,
    TResult? Function(JobCompleted value)? completed,
    TResult? Function(JobFailed value)? failed,
    TResult? Function(JobCancelled value)? cancelled,
  }) {
    final _that = this;
    switch (_that) {
      case JobIdle() when idle != null:
        return idle(_that);
      case JobUploading() when uploading != null:
        return uploading(_that);
      case JobSubmitted() when submitted != null:
        return submitted(_that);
      case JobRunning() when running != null:
        return running(_that);
      case JobCompleted() when completed != null:
        return completed(_that);
      case JobFailed() when failed != null:
        return failed(_that);
      case JobCancelled() when cancelled != null:
        return cancelled(_that);
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
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function(double fraction)? uploading,
    TResult Function(Job job)? submitted,
    TResult Function(Job job)? running,
    TResult Function(Job job)? completed,
    TResult Function(ApiException? error, String? message)? failed,
    TResult Function()? cancelled,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case JobIdle() when idle != null:
        return idle();
      case JobUploading() when uploading != null:
        return uploading(_that.fraction);
      case JobSubmitted() when submitted != null:
        return submitted(_that.job);
      case JobRunning() when running != null:
        return running(_that.job);
      case JobCompleted() when completed != null:
        return completed(_that.job);
      case JobFailed() when failed != null:
        return failed(_that.error, _that.message);
      case JobCancelled() when cancelled != null:
        return cancelled();
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
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function(double fraction) uploading,
    required TResult Function(Job job) submitted,
    required TResult Function(Job job) running,
    required TResult Function(Job job) completed,
    required TResult Function(ApiException? error, String? message) failed,
    required TResult Function() cancelled,
  }) {
    final _that = this;
    switch (_that) {
      case JobIdle():
        return idle();
      case JobUploading():
        return uploading(_that.fraction);
      case JobSubmitted():
        return submitted(_that.job);
      case JobRunning():
        return running(_that.job);
      case JobCompleted():
        return completed(_that.job);
      case JobFailed():
        return failed(_that.error, _that.message);
      case JobCancelled():
        return cancelled();
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
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function(double fraction)? uploading,
    TResult? Function(Job job)? submitted,
    TResult? Function(Job job)? running,
    TResult? Function(Job job)? completed,
    TResult? Function(ApiException? error, String? message)? failed,
    TResult? Function()? cancelled,
  }) {
    final _that = this;
    switch (_that) {
      case JobIdle() when idle != null:
        return idle();
      case JobUploading() when uploading != null:
        return uploading(_that.fraction);
      case JobSubmitted() when submitted != null:
        return submitted(_that.job);
      case JobRunning() when running != null:
        return running(_that.job);
      case JobCompleted() when completed != null:
        return completed(_that.job);
      case JobFailed() when failed != null:
        return failed(_that.error, _that.message);
      case JobCancelled() when cancelled != null:
        return cancelled();
      case _:
        return null;
    }
  }
}

/// @nodoc

class JobIdle extends JobRunState {
  const JobIdle() : super._();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is JobIdle);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'JobRunState.idle()';
  }
}

/// @nodoc

class JobUploading extends JobRunState {
  const JobUploading({this.fraction = 0}) : super._();

  @JsonKey()
  final double fraction;

  /// Create a copy of JobRunState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $JobUploadingCopyWith<JobUploading> get copyWith =>
      _$JobUploadingCopyWithImpl<JobUploading>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is JobUploading &&
            (identical(other.fraction, fraction) ||
                other.fraction == fraction));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, fraction);
  }

  @override
  String toString() {
    return 'JobRunState.uploading(fraction: $fraction)';
  }
}

/// @nodoc
abstract mixin class $JobUploadingCopyWith<$Res>
    implements $JobRunStateCopyWith<$Res> {
  factory $JobUploadingCopyWith(
    JobUploading value,
    $Res Function(JobUploading) _then,
  ) = _$JobUploadingCopyWithImpl;
  @useResult
  $Res call({double fraction});
}

/// @nodoc
class _$JobUploadingCopyWithImpl<$Res> implements $JobUploadingCopyWith<$Res> {
  _$JobUploadingCopyWithImpl(this._self, this._then);

  final JobUploading _self;
  final $Res Function(JobUploading) _then;

  /// Create a copy of JobRunState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? fraction = null}) {
    return _then(
      JobUploading(
        fraction: null == fraction
            ? _self.fraction
            : fraction // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc

class JobSubmitted extends JobRunState {
  const JobSubmitted(this.job) : super._();

  final Job job;

  /// Create a copy of JobRunState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $JobSubmittedCopyWith<JobSubmitted> get copyWith =>
      _$JobSubmittedCopyWithImpl<JobSubmitted>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is JobSubmitted &&
            (identical(other.job, job) || other.job == job));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, job);
  }

  @override
  String toString() {
    return 'JobRunState.submitted(job: $job)';
  }
}

/// @nodoc
abstract mixin class $JobSubmittedCopyWith<$Res>
    implements $JobRunStateCopyWith<$Res> {
  factory $JobSubmittedCopyWith(
    JobSubmitted value,
    $Res Function(JobSubmitted) _then,
  ) = _$JobSubmittedCopyWithImpl;
  @useResult
  $Res call({Job job});

  $JobCopyWith<$Res> get job;
}

/// @nodoc
class _$JobSubmittedCopyWithImpl<$Res> implements $JobSubmittedCopyWith<$Res> {
  _$JobSubmittedCopyWithImpl(this._self, this._then);

  final JobSubmitted _self;
  final $Res Function(JobSubmitted) _then;

  /// Create a copy of JobRunState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? job = null}) {
    return _then(
      JobSubmitted(
        null == job
            ? _self.job
            : job // ignore: cast_nullable_to_non_nullable
                  as Job,
      ),
    );
  }

  /// Create a copy of JobRunState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $JobCopyWith<$Res> get job {
    return $JobCopyWith<$Res>(_self.job, (value) {
      return _then(_self.copyWith(job: value));
    });
  }
}

/// @nodoc

class JobRunning extends JobRunState {
  const JobRunning(this.job) : super._();

  final Job job;

  /// Create a copy of JobRunState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $JobRunningCopyWith<JobRunning> get copyWith =>
      _$JobRunningCopyWithImpl<JobRunning>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is JobRunning &&
            (identical(other.job, job) || other.job == job));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, job);
  }

  @override
  String toString() {
    return 'JobRunState.running(job: $job)';
  }
}

/// @nodoc
abstract mixin class $JobRunningCopyWith<$Res>
    implements $JobRunStateCopyWith<$Res> {
  factory $JobRunningCopyWith(
    JobRunning value,
    $Res Function(JobRunning) _then,
  ) = _$JobRunningCopyWithImpl;
  @useResult
  $Res call({Job job});

  $JobCopyWith<$Res> get job;
}

/// @nodoc
class _$JobRunningCopyWithImpl<$Res> implements $JobRunningCopyWith<$Res> {
  _$JobRunningCopyWithImpl(this._self, this._then);

  final JobRunning _self;
  final $Res Function(JobRunning) _then;

  /// Create a copy of JobRunState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? job = null}) {
    return _then(
      JobRunning(
        null == job
            ? _self.job
            : job // ignore: cast_nullable_to_non_nullable
                  as Job,
      ),
    );
  }

  /// Create a copy of JobRunState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $JobCopyWith<$Res> get job {
    return $JobCopyWith<$Res>(_self.job, (value) {
      return _then(_self.copyWith(job: value));
    });
  }
}

/// @nodoc

class JobCompleted extends JobRunState {
  const JobCompleted(this.job) : super._();

  final Job job;

  /// Create a copy of JobRunState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $JobCompletedCopyWith<JobCompleted> get copyWith =>
      _$JobCompletedCopyWithImpl<JobCompleted>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is JobCompleted &&
            (identical(other.job, job) || other.job == job));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, job);
  }

  @override
  String toString() {
    return 'JobRunState.completed(job: $job)';
  }
}

/// @nodoc
abstract mixin class $JobCompletedCopyWith<$Res>
    implements $JobRunStateCopyWith<$Res> {
  factory $JobCompletedCopyWith(
    JobCompleted value,
    $Res Function(JobCompleted) _then,
  ) = _$JobCompletedCopyWithImpl;
  @useResult
  $Res call({Job job});

  $JobCopyWith<$Res> get job;
}

/// @nodoc
class _$JobCompletedCopyWithImpl<$Res> implements $JobCompletedCopyWith<$Res> {
  _$JobCompletedCopyWithImpl(this._self, this._then);

  final JobCompleted _self;
  final $Res Function(JobCompleted) _then;

  /// Create a copy of JobRunState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? job = null}) {
    return _then(
      JobCompleted(
        null == job
            ? _self.job
            : job // ignore: cast_nullable_to_non_nullable
                  as Job,
      ),
    );
  }

  /// Create a copy of JobRunState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $JobCopyWith<$Res> get job {
    return $JobCopyWith<$Res>(_self.job, (value) {
      return _then(_self.copyWith(job: value));
    });
  }
}

/// @nodoc

class JobFailed extends JobRunState {
  const JobFailed({this.error, this.message}) : super._();

  final ApiException? error;
  final String? message;

  /// Create a copy of JobRunState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $JobFailedCopyWith<JobFailed> get copyWith =>
      _$JobFailedCopyWithImpl<JobFailed>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is JobFailed &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, error, message);
  }

  @override
  String toString() {
    return 'JobRunState.failed(error: $error, message: $message)';
  }
}

/// @nodoc
abstract mixin class $JobFailedCopyWith<$Res>
    implements $JobRunStateCopyWith<$Res> {
  factory $JobFailedCopyWith(JobFailed value, $Res Function(JobFailed) _then) =
      _$JobFailedCopyWithImpl;
  @useResult
  $Res call({ApiException? error, String? message});
}

/// @nodoc
class _$JobFailedCopyWithImpl<$Res> implements $JobFailedCopyWith<$Res> {
  _$JobFailedCopyWithImpl(this._self, this._then);

  final JobFailed _self;
  final $Res Function(JobFailed) _then;

  /// Create a copy of JobRunState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? error = freezed, Object? message = freezed}) {
    return _then(
      JobFailed(
        error: freezed == error
            ? _self.error
            : error // ignore: cast_nullable_to_non_nullable
                  as ApiException?,
        message: freezed == message
            ? _self.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class JobCancelled extends JobRunState {
  const JobCancelled() : super._();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is JobCancelled);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'JobRunState.cancelled()';
  }
}
