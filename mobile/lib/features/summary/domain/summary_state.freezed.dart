// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'summary_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SummaryState {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is SummaryState);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'SummaryState()';
  }
}

/// @nodoc
class $SummaryStateCopyWith<$Res> {
  $SummaryStateCopyWith(SummaryState _, $Res Function(SummaryState) __);
}

/// Adds pattern-matching-related methods to [SummaryState].
extension SummaryStatePatterns on SummaryState {
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
    TResult Function(SummaryEmpty value)? empty,
    TResult Function(SummaryGenerating value)? generating,
    TResult Function(SummaryReady value)? ready,
    TResult Function(SummaryFailed value)? failed,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case SummaryEmpty() when empty != null:
        return empty(_that);
      case SummaryGenerating() when generating != null:
        return generating(_that);
      case SummaryReady() when ready != null:
        return ready(_that);
      case SummaryFailed() when failed != null:
        return failed(_that);
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
    required TResult Function(SummaryEmpty value) empty,
    required TResult Function(SummaryGenerating value) generating,
    required TResult Function(SummaryReady value) ready,
    required TResult Function(SummaryFailed value) failed,
  }) {
    final _that = this;
    switch (_that) {
      case SummaryEmpty():
        return empty(_that);
      case SummaryGenerating():
        return generating(_that);
      case SummaryReady():
        return ready(_that);
      case SummaryFailed():
        return failed(_that);
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
    TResult? Function(SummaryEmpty value)? empty,
    TResult? Function(SummaryGenerating value)? generating,
    TResult? Function(SummaryReady value)? ready,
    TResult? Function(SummaryFailed value)? failed,
  }) {
    final _that = this;
    switch (_that) {
      case SummaryEmpty() when empty != null:
        return empty(_that);
      case SummaryGenerating() when generating != null:
        return generating(_that);
      case SummaryReady() when ready != null:
        return ready(_that);
      case SummaryFailed() when failed != null:
        return failed(_that);
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
    TResult Function()? empty,
    TResult Function(String? processId, SummaryDocument? previous, int polls)?
    generating,
    TResult Function(SummaryDocument summary, bool fresh)? ready,
    TResult Function(
      SummaryFailure reason,
      String? message,
      ApiException? error,
      SummaryDocument? previous,
    )?
    failed,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case SummaryEmpty() when empty != null:
        return empty();
      case SummaryGenerating() when generating != null:
        return generating(_that.processId, _that.previous, _that.polls);
      case SummaryReady() when ready != null:
        return ready(_that.summary, _that.fresh);
      case SummaryFailed() when failed != null:
        return failed(_that.reason, _that.message, _that.error, _that.previous);
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
    required TResult Function() empty,
    required TResult Function(
      String? processId,
      SummaryDocument? previous,
      int polls,
    )
    generating,
    required TResult Function(SummaryDocument summary, bool fresh) ready,
    required TResult Function(
      SummaryFailure reason,
      String? message,
      ApiException? error,
      SummaryDocument? previous,
    )
    failed,
  }) {
    final _that = this;
    switch (_that) {
      case SummaryEmpty():
        return empty();
      case SummaryGenerating():
        return generating(_that.processId, _that.previous, _that.polls);
      case SummaryReady():
        return ready(_that.summary, _that.fresh);
      case SummaryFailed():
        return failed(_that.reason, _that.message, _that.error, _that.previous);
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
    TResult? Function()? empty,
    TResult? Function(String? processId, SummaryDocument? previous, int polls)?
    generating,
    TResult? Function(SummaryDocument summary, bool fresh)? ready,
    TResult? Function(
      SummaryFailure reason,
      String? message,
      ApiException? error,
      SummaryDocument? previous,
    )?
    failed,
  }) {
    final _that = this;
    switch (_that) {
      case SummaryEmpty() when empty != null:
        return empty();
      case SummaryGenerating() when generating != null:
        return generating(_that.processId, _that.previous, _that.polls);
      case SummaryReady() when ready != null:
        return ready(_that.summary, _that.fresh);
      case SummaryFailed() when failed != null:
        return failed(_that.reason, _that.message, _that.error, _that.previous);
      case _:
        return null;
    }
  }
}

/// @nodoc

class SummaryEmpty extends SummaryState {
  const SummaryEmpty() : super._();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is SummaryEmpty);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'SummaryState.empty()';
  }
}

/// @nodoc

class SummaryGenerating extends SummaryState {
  const SummaryGenerating({this.processId, this.previous, this.polls = 0})
    : super._();

  final String? processId;
  final SummaryDocument? previous;
  @JsonKey()
  final int polls;

  /// Create a copy of SummaryState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SummaryGeneratingCopyWith<SummaryGenerating> get copyWith =>
      _$SummaryGeneratingCopyWithImpl<SummaryGenerating>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SummaryGenerating &&
            (identical(other.processId, processId) ||
                other.processId == processId) &&
            (identical(other.previous, previous) ||
                other.previous == previous) &&
            (identical(other.polls, polls) || other.polls == polls));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, processId, previous, polls);
  }

  @override
  String toString() {
    return 'SummaryState.generating(processId: $processId, previous: $previous, polls: $polls)';
  }
}

/// @nodoc
abstract mixin class $SummaryGeneratingCopyWith<$Res>
    implements $SummaryStateCopyWith<$Res> {
  factory $SummaryGeneratingCopyWith(
    SummaryGenerating value,
    $Res Function(SummaryGenerating) _then,
  ) = _$SummaryGeneratingCopyWithImpl;
  @useResult
  $Res call({String? processId, SummaryDocument? previous, int polls});

  $SummaryDocumentCopyWith<$Res>? get previous;
}

/// @nodoc
class _$SummaryGeneratingCopyWithImpl<$Res>
    implements $SummaryGeneratingCopyWith<$Res> {
  _$SummaryGeneratingCopyWithImpl(this._self, this._then);

  final SummaryGenerating _self;
  final $Res Function(SummaryGenerating) _then;

  /// Create a copy of SummaryState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? processId = freezed,
    Object? previous = freezed,
    Object? polls = null,
  }) {
    return _then(
      SummaryGenerating(
        processId: freezed == processId
            ? _self.processId
            : processId // ignore: cast_nullable_to_non_nullable
                  as String?,
        previous: freezed == previous
            ? _self.previous
            : previous // ignore: cast_nullable_to_non_nullable
                  as SummaryDocument?,
        polls: null == polls
            ? _self.polls
            : polls // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }

  /// Create a copy of SummaryState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SummaryDocumentCopyWith<$Res>? get previous {
    if (_self.previous == null) {
      return null;
    }

    return $SummaryDocumentCopyWith<$Res>(_self.previous!, (value) {
      return _then(_self.copyWith(previous: value));
    });
  }
}

/// @nodoc

class SummaryReady extends SummaryState {
  const SummaryReady({required this.summary, this.fresh = false}) : super._();

  final SummaryDocument summary;
  @JsonKey()
  final bool fresh;

  /// Create a copy of SummaryState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SummaryReadyCopyWith<SummaryReady> get copyWith =>
      _$SummaryReadyCopyWithImpl<SummaryReady>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SummaryReady &&
            (identical(other.summary, summary) || other.summary == summary) &&
            (identical(other.fresh, fresh) || other.fresh == fresh));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, summary, fresh);
  }

  @override
  String toString() {
    return 'SummaryState.ready(summary: $summary, fresh: $fresh)';
  }
}

/// @nodoc
abstract mixin class $SummaryReadyCopyWith<$Res>
    implements $SummaryStateCopyWith<$Res> {
  factory $SummaryReadyCopyWith(
    SummaryReady value,
    $Res Function(SummaryReady) _then,
  ) = _$SummaryReadyCopyWithImpl;
  @useResult
  $Res call({SummaryDocument summary, bool fresh});

  $SummaryDocumentCopyWith<$Res> get summary;
}

/// @nodoc
class _$SummaryReadyCopyWithImpl<$Res> implements $SummaryReadyCopyWith<$Res> {
  _$SummaryReadyCopyWithImpl(this._self, this._then);

  final SummaryReady _self;
  final $Res Function(SummaryReady) _then;

  /// Create a copy of SummaryState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? summary = null, Object? fresh = null}) {
    return _then(
      SummaryReady(
        summary: null == summary
            ? _self.summary
            : summary // ignore: cast_nullable_to_non_nullable
                  as SummaryDocument,
        fresh: null == fresh
            ? _self.fresh
            : fresh // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }

  /// Create a copy of SummaryState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SummaryDocumentCopyWith<$Res> get summary {
    return $SummaryDocumentCopyWith<$Res>(_self.summary, (value) {
      return _then(_self.copyWith(summary: value));
    });
  }
}

/// @nodoc

class SummaryFailed extends SummaryState {
  const SummaryFailed({
    required this.reason,
    this.message,
    this.error,
    this.previous,
  }) : super._();

  final SummaryFailure reason;
  final String? message;
  final ApiException? error;
  final SummaryDocument? previous;

  /// Create a copy of SummaryState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SummaryFailedCopyWith<SummaryFailed> get copyWith =>
      _$SummaryFailedCopyWithImpl<SummaryFailed>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SummaryFailed &&
            (identical(other.reason, reason) || other.reason == reason) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.previous, previous) ||
                other.previous == previous));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, reason, message, error, previous);
  }

  @override
  String toString() {
    return 'SummaryState.failed(reason: $reason, message: $message, error: $error, previous: $previous)';
  }
}

/// @nodoc
abstract mixin class $SummaryFailedCopyWith<$Res>
    implements $SummaryStateCopyWith<$Res> {
  factory $SummaryFailedCopyWith(
    SummaryFailed value,
    $Res Function(SummaryFailed) _then,
  ) = _$SummaryFailedCopyWithImpl;
  @useResult
  $Res call({
    SummaryFailure reason,
    String? message,
    ApiException? error,
    SummaryDocument? previous,
  });

  $SummaryDocumentCopyWith<$Res>? get previous;
}

/// @nodoc
class _$SummaryFailedCopyWithImpl<$Res>
    implements $SummaryFailedCopyWith<$Res> {
  _$SummaryFailedCopyWithImpl(this._self, this._then);

  final SummaryFailed _self;
  final $Res Function(SummaryFailed) _then;

  /// Create a copy of SummaryState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? reason = null,
    Object? message = freezed,
    Object? error = freezed,
    Object? previous = freezed,
  }) {
    return _then(
      SummaryFailed(
        reason: null == reason
            ? _self.reason
            : reason // ignore: cast_nullable_to_non_nullable
                  as SummaryFailure,
        message: freezed == message
            ? _self.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String?,
        error: freezed == error
            ? _self.error
            : error // ignore: cast_nullable_to_non_nullable
                  as ApiException?,
        previous: freezed == previous
            ? _self.previous
            : previous // ignore: cast_nullable_to_non_nullable
                  as SummaryDocument?,
      ),
    );
  }

  /// Create a copy of SummaryState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SummaryDocumentCopyWith<$Res>? get previous {
    if (_self.previous == null) {
      return null;
    }

    return $SummaryDocumentCopyWith<$Res>(_self.previous!, (value) {
      return _then(_self.copyWith(previous: value));
    });
  }
}
