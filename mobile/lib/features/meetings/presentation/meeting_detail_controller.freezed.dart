// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'meeting_detail_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TranscriptsState {
  List<MeetingTranscript> get items;
  int get totalCount;
  bool get hasMore;
  bool get loadingMore;

  /// Failure of the last [TranscriptsController.loadMore] (first page errors → AsyncError).
  Object? get loadMoreError;

  /// Create a copy of TranscriptsState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TranscriptsStateCopyWith<TranscriptsState> get copyWith =>
      _$TranscriptsStateCopyWithImpl<TranscriptsState>(
        this as TranscriptsState,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    final _this = this as TranscriptsState;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TranscriptsState &&
            const DeepCollectionEquality().equals(other.items, _this.items) &&
            (identical(other.totalCount, _this.totalCount) ||
                other.totalCount == _this.totalCount) &&
            (identical(other.hasMore, _this.hasMore) ||
                other.hasMore == _this.hasMore) &&
            (identical(other.loadingMore, _this.loadingMore) ||
                other.loadingMore == _this.loadingMore) &&
            const DeepCollectionEquality().equals(
              other.loadMoreError,
              _this.loadMoreError,
            ));
  }

  @override
  int get hashCode {
    final _this = this as TranscriptsState;
    return Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_this.items),
      _this.totalCount,
      _this.hasMore,
      _this.loadingMore,
      const DeepCollectionEquality().hash(_this.loadMoreError),
    );
  }

  @override
  String toString() {
    final _this = this as TranscriptsState;
    return 'TranscriptsState(items: ${_this.items}, totalCount: ${_this.totalCount}, hasMore: ${_this.hasMore}, loadingMore: ${_this.loadingMore}, loadMoreError: ${_this.loadMoreError})';
  }
}

/// @nodoc
abstract mixin class $TranscriptsStateCopyWith<$Res> {
  factory $TranscriptsStateCopyWith(
    TranscriptsState value,
    $Res Function(TranscriptsState) _then,
  ) = _$TranscriptsStateCopyWithImpl;
  @useResult
  $Res call({
    List<MeetingTranscript> items,
    int totalCount,
    bool hasMore,
    bool loadingMore,
    Object? loadMoreError,
  });
}

/// @nodoc
class _$TranscriptsStateCopyWithImpl<$Res>
    implements $TranscriptsStateCopyWith<$Res> {
  _$TranscriptsStateCopyWithImpl(this._self, this._then);

  final TranscriptsState _self;
  final $Res Function(TranscriptsState) _then;

  /// Create a copy of TranscriptsState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? totalCount = null,
    Object? hasMore = null,
    Object? loadingMore = null,
    Object? loadMoreError = freezed,
  }) {
    return _then(
      TranscriptsState(
        items: null == items
            ? _self.items
            : items // ignore: cast_nullable_to_non_nullable
                  as List<MeetingTranscript>,
        totalCount: null == totalCount
            ? _self.totalCount
            : totalCount // ignore: cast_nullable_to_non_nullable
                  as int,
        hasMore: null == hasMore
            ? _self.hasMore
            : hasMore // ignore: cast_nullable_to_non_nullable
                  as bool,
        loadingMore: null == loadingMore
            ? _self.loadingMore
            : loadingMore // ignore: cast_nullable_to_non_nullable
                  as bool,
        loadMoreError: freezed == loadMoreError
            ? _self.loadMoreError
            : loadMoreError,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [TranscriptsState].
extension TranscriptsStatePatterns on TranscriptsState {
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
    TResult Function(_TranscriptsState value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TranscriptsState() when $default != null:
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
    TResult Function(_TranscriptsState value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TranscriptsState():
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
    TResult? Function(_TranscriptsState value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TranscriptsState() when $default != null:
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
      List<MeetingTranscript> items,
      int totalCount,
      bool hasMore,
      bool loadingMore,
      Object? loadMoreError,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TranscriptsState() when $default != null:
        return $default(
          _that.items,
          _that.totalCount,
          _that.hasMore,
          _that.loadingMore,
          _that.loadMoreError,
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
      List<MeetingTranscript> items,
      int totalCount,
      bool hasMore,
      bool loadingMore,
      Object? loadMoreError,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TranscriptsState():
        return $default(
          _that.items,
          _that.totalCount,
          _that.hasMore,
          _that.loadingMore,
          _that.loadMoreError,
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
      List<MeetingTranscript> items,
      int totalCount,
      bool hasMore,
      bool loadingMore,
      Object? loadMoreError,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TranscriptsState() when $default != null:
        return $default(
          _that.items,
          _that.totalCount,
          _that.hasMore,
          _that.loadingMore,
          _that.loadMoreError,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc

class _TranscriptsState implements TranscriptsState {
  const _TranscriptsState({
    List<MeetingTranscript> items = const <MeetingTranscript>[],
    this.totalCount = 0,
    this.hasMore = false,
    this.loadingMore = false,
    this.loadMoreError,
  }) : _items = items;

  final List<MeetingTranscript> _items;
  @override
  @JsonKey()
  List<MeetingTranscript> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  @JsonKey()
  final int totalCount;
  @override
  @JsonKey()
  final bool hasMore;
  @override
  @JsonKey()
  final bool loadingMore;

  /// Failure of the last [TranscriptsController.loadMore] (first page errors → AsyncError).
  @override
  final Object? loadMoreError;

  /// Create a copy of TranscriptsState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$TranscriptsStateCopyWith<_TranscriptsState> get copyWith =>
      __$TranscriptsStateCopyWithImpl<_TranscriptsState>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _TranscriptsState &&
            const DeepCollectionEquality().equals(other.items, _items) &&
            (identical(other.totalCount, totalCount) ||
                other.totalCount == totalCount) &&
            (identical(other.hasMore, hasMore) || other.hasMore == hasMore) &&
            (identical(other.loadingMore, loadingMore) ||
                other.loadingMore == loadingMore) &&
            const DeepCollectionEquality().equals(
              other.loadMoreError,
              loadMoreError,
            ));
  }

  @override
  int get hashCode {
    return Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_items),
      totalCount,
      hasMore,
      loadingMore,
      const DeepCollectionEquality().hash(loadMoreError),
    );
  }

  @override
  String toString() {
    return 'TranscriptsState(items: $items, totalCount: $totalCount, hasMore: $hasMore, loadingMore: $loadingMore, loadMoreError: $loadMoreError)';
  }
}

/// @nodoc
abstract mixin class _$TranscriptsStateCopyWith<$Res>
    implements $TranscriptsStateCopyWith<$Res> {
  factory _$TranscriptsStateCopyWith(
    _TranscriptsState value,
    $Res Function(_TranscriptsState) _then,
  ) = __$TranscriptsStateCopyWithImpl;
  @override
  @useResult
  $Res call({
    List<MeetingTranscript> items,
    int totalCount,
    bool hasMore,
    bool loadingMore,
    Object? loadMoreError,
  });
}

/// @nodoc
class __$TranscriptsStateCopyWithImpl<$Res>
    implements _$TranscriptsStateCopyWith<$Res> {
  __$TranscriptsStateCopyWithImpl(this._self, this._then);

  final _TranscriptsState _self;
  final $Res Function(_TranscriptsState) _then;

  /// Create a copy of TranscriptsState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? items = null,
    Object? totalCount = null,
    Object? hasMore = null,
    Object? loadingMore = null,
    Object? loadMoreError = freezed,
  }) {
    return _then(
      _TranscriptsState(
        items: null == items
            ? _self._items
            : items // ignore: cast_nullable_to_non_nullable
                  as List<MeetingTranscript>,
        totalCount: null == totalCount
            ? _self.totalCount
            : totalCount // ignore: cast_nullable_to_non_nullable
                  as int,
        hasMore: null == hasMore
            ? _self.hasMore
            : hasMore // ignore: cast_nullable_to_non_nullable
                  as bool,
        loadingMore: null == loadingMore
            ? _self.loadingMore
            : loadingMore // ignore: cast_nullable_to_non_nullable
                  as bool,
        loadMoreError: freezed == loadMoreError
            ? _self.loadMoreError
            : loadMoreError,
      ),
    );
  }
}
