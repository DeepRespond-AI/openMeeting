// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'meetings_list_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MeetingSearchState {
  /// Current (trimmed) query; empty = not searching (the list is shown).
  String get query;
  AsyncValue<List<TranscriptSearchResult>> get results;

  /// Create a copy of MeetingSearchState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $MeetingSearchStateCopyWith<MeetingSearchState> get copyWith =>
      _$MeetingSearchStateCopyWithImpl<MeetingSearchState>(
        this as MeetingSearchState,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    final _this = this as MeetingSearchState;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MeetingSearchState &&
            (identical(other.query, _this.query) ||
                other.query == _this.query) &&
            (identical(other.results, _this.results) ||
                other.results == _this.results));
  }

  @override
  int get hashCode {
    final _this = this as MeetingSearchState;
    return Object.hash(runtimeType, _this.query, _this.results);
  }

  @override
  String toString() {
    final _this = this as MeetingSearchState;
    return 'MeetingSearchState(query: ${_this.query}, results: ${_this.results})';
  }
}

/// @nodoc
abstract mixin class $MeetingSearchStateCopyWith<$Res> {
  factory $MeetingSearchStateCopyWith(
    MeetingSearchState value,
    $Res Function(MeetingSearchState) _then,
  ) = _$MeetingSearchStateCopyWithImpl;
  @useResult
  $Res call({String query, AsyncValue<List<TranscriptSearchResult>> results});
}

/// @nodoc
class _$MeetingSearchStateCopyWithImpl<$Res>
    implements $MeetingSearchStateCopyWith<$Res> {
  _$MeetingSearchStateCopyWithImpl(this._self, this._then);

  final MeetingSearchState _self;
  final $Res Function(MeetingSearchState) _then;

  /// Create a copy of MeetingSearchState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? query = null, Object? results = null}) {
    return _then(
      MeetingSearchState(
        query: null == query
            ? _self.query
            : query // ignore: cast_nullable_to_non_nullable
                  as String,
        results: null == results
            ? _self.results
            : results // ignore: cast_nullable_to_non_nullable
                  as AsyncValue<List<TranscriptSearchResult>>,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [MeetingSearchState].
extension MeetingSearchStatePatterns on MeetingSearchState {
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
    TResult Function(_MeetingSearchState value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _MeetingSearchState() when $default != null:
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
    TResult Function(_MeetingSearchState value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MeetingSearchState():
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
    TResult? Function(_MeetingSearchState value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MeetingSearchState() when $default != null:
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
      String query,
      AsyncValue<List<TranscriptSearchResult>> results,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _MeetingSearchState() when $default != null:
        return $default(_that.query, _that.results);
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
      String query,
      AsyncValue<List<TranscriptSearchResult>> results,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MeetingSearchState():
        return $default(_that.query, _that.results);
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
      String query,
      AsyncValue<List<TranscriptSearchResult>> results,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MeetingSearchState() when $default != null:
        return $default(_that.query, _that.results);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _MeetingSearchState extends MeetingSearchState {
  const _MeetingSearchState({
    this.query = '',
    this.results = const AsyncData<List<TranscriptSearchResult>>(
      <TranscriptSearchResult>[],
    ),
  }) : super._();

  /// Current (trimmed) query; empty = not searching (the list is shown).
  @override
  @JsonKey()
  final String query;
  @override
  @JsonKey()
  final AsyncValue<List<TranscriptSearchResult>> results;

  /// Create a copy of MeetingSearchState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$MeetingSearchStateCopyWith<_MeetingSearchState> get copyWith =>
      __$MeetingSearchStateCopyWithImpl<_MeetingSearchState>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _MeetingSearchState &&
            (identical(other.query, query) || other.query == query) &&
            (identical(other.results, results) || other.results == results));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, query, results);
  }

  @override
  String toString() {
    return 'MeetingSearchState(query: $query, results: $results)';
  }
}

/// @nodoc
abstract mixin class _$MeetingSearchStateCopyWith<$Res>
    implements $MeetingSearchStateCopyWith<$Res> {
  factory _$MeetingSearchStateCopyWith(
    _MeetingSearchState value,
    $Res Function(_MeetingSearchState) _then,
  ) = __$MeetingSearchStateCopyWithImpl;
  @override
  @useResult
  $Res call({String query, AsyncValue<List<TranscriptSearchResult>> results});
}

/// @nodoc
class __$MeetingSearchStateCopyWithImpl<$Res>
    implements _$MeetingSearchStateCopyWith<$Res> {
  __$MeetingSearchStateCopyWithImpl(this._self, this._then);

  final _MeetingSearchState _self;
  final $Res Function(_MeetingSearchState) _then;

  /// Create a copy of MeetingSearchState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({Object? query = null, Object? results = null}) {
    return _then(
      _MeetingSearchState(
        query: null == query
            ? _self.query
            : query // ignore: cast_nullable_to_non_nullable
                  as String,
        results: null == results
            ? _self.results
            : results // ignore: cast_nullable_to_non_nullable
                  as AsyncValue<List<TranscriptSearchResult>>,
      ),
    );
  }
}
