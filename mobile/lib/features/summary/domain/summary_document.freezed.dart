// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'summary_document.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SummaryDocument {
  String get content;
  SummaryFormat get format;

  /// Create a copy of SummaryDocument
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SummaryDocumentCopyWith<SummaryDocument> get copyWith =>
      _$SummaryDocumentCopyWithImpl<SummaryDocument>(
        this as SummaryDocument,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    final _this = this as SummaryDocument;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SummaryDocument &&
            (identical(other.content, _this.content) ||
                other.content == _this.content) &&
            (identical(other.format, _this.format) ||
                other.format == _this.format));
  }

  @override
  int get hashCode {
    final _this = this as SummaryDocument;
    return Object.hash(runtimeType, _this.content, _this.format);
  }

  @override
  String toString() {
    final _this = this as SummaryDocument;
    return 'SummaryDocument(content: ${_this.content}, format: ${_this.format})';
  }
}

/// @nodoc
abstract mixin class $SummaryDocumentCopyWith<$Res> {
  factory $SummaryDocumentCopyWith(
    SummaryDocument value,
    $Res Function(SummaryDocument) _then,
  ) = _$SummaryDocumentCopyWithImpl;
  @useResult
  $Res call({String content, SummaryFormat format});
}

/// @nodoc
class _$SummaryDocumentCopyWithImpl<$Res>
    implements $SummaryDocumentCopyWith<$Res> {
  _$SummaryDocumentCopyWithImpl(this._self, this._then);

  final SummaryDocument _self;
  final $Res Function(SummaryDocument) _then;

  /// Create a copy of SummaryDocument
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? content = null, Object? format = null}) {
    return _then(
      SummaryDocument(
        content: null == content
            ? _self.content
            : content // ignore: cast_nullable_to_non_nullable
                  as String,
        format: null == format
            ? _self.format
            : format // ignore: cast_nullable_to_non_nullable
                  as SummaryFormat,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [SummaryDocument].
extension SummaryDocumentPatterns on SummaryDocument {
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
    TResult Function(_SummaryDocument value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SummaryDocument() when $default != null:
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
    TResult Function(_SummaryDocument value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SummaryDocument():
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
    TResult? Function(_SummaryDocument value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SummaryDocument() when $default != null:
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
    TResult Function(String content, SummaryFormat format)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SummaryDocument() when $default != null:
        return $default(_that.content, _that.format);
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
    TResult Function(String content, SummaryFormat format) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SummaryDocument():
        return $default(_that.content, _that.format);
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
    TResult? Function(String content, SummaryFormat format)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SummaryDocument() when $default != null:
        return $default(_that.content, _that.format);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _SummaryDocument implements SummaryDocument {
  const _SummaryDocument({
    required this.content,
    this.format = SummaryFormat.markdown,
  });

  @override
  final String content;
  @override
  @JsonKey()
  final SummaryFormat format;

  /// Create a copy of SummaryDocument
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$SummaryDocumentCopyWith<_SummaryDocument> get copyWith =>
      __$SummaryDocumentCopyWithImpl<_SummaryDocument>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _SummaryDocument &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.format, format) || other.format == format));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, content, format);
  }

  @override
  String toString() {
    return 'SummaryDocument(content: $content, format: $format)';
  }
}

/// @nodoc
abstract mixin class _$SummaryDocumentCopyWith<$Res>
    implements $SummaryDocumentCopyWith<$Res> {
  factory _$SummaryDocumentCopyWith(
    _SummaryDocument value,
    $Res Function(_SummaryDocument) _then,
  ) = __$SummaryDocumentCopyWithImpl;
  @override
  @useResult
  $Res call({String content, SummaryFormat format});
}

/// @nodoc
class __$SummaryDocumentCopyWithImpl<$Res>
    implements _$SummaryDocumentCopyWith<$Res> {
  __$SummaryDocumentCopyWithImpl(this._self, this._then);

  final _SummaryDocument _self;
  final $Res Function(_SummaryDocument) _then;

  /// Create a copy of SummaryDocument
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({Object? content = null, Object? format = null}) {
    return _then(
      _SummaryDocument(
        content: null == content
            ? _self.content
            : content // ignore: cast_nullable_to_non_nullable
                  as String,
        format: null == format
            ? _self.format
            : format // ignore: cast_nullable_to_non_nullable
                  as SummaryFormat,
      ),
    );
  }
}
