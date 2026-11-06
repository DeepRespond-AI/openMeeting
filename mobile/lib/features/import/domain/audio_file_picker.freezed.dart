// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'audio_file_picker.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PickedAudioFile {
  String get path;
  String get name;

  /// Bytes, when known.
  int? get size;

  /// Create a copy of PickedAudioFile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PickedAudioFileCopyWith<PickedAudioFile> get copyWith =>
      _$PickedAudioFileCopyWithImpl<PickedAudioFile>(
        this as PickedAudioFile,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    final _this = this as PickedAudioFile;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PickedAudioFile &&
            (identical(other.path, _this.path) || other.path == _this.path) &&
            (identical(other.name, _this.name) || other.name == _this.name) &&
            (identical(other.size, _this.size) || other.size == _this.size));
  }

  @override
  int get hashCode {
    final _this = this as PickedAudioFile;
    return Object.hash(runtimeType, _this.path, _this.name, _this.size);
  }

  @override
  String toString() {
    final _this = this as PickedAudioFile;
    return 'PickedAudioFile(path: ${_this.path}, name: ${_this.name}, size: ${_this.size})';
  }
}

/// @nodoc
abstract mixin class $PickedAudioFileCopyWith<$Res> {
  factory $PickedAudioFileCopyWith(
    PickedAudioFile value,
    $Res Function(PickedAudioFile) _then,
  ) = _$PickedAudioFileCopyWithImpl;
  @useResult
  $Res call({String path, String name, int? size});
}

/// @nodoc
class _$PickedAudioFileCopyWithImpl<$Res>
    implements $PickedAudioFileCopyWith<$Res> {
  _$PickedAudioFileCopyWithImpl(this._self, this._then);

  final PickedAudioFile _self;
  final $Res Function(PickedAudioFile) _then;

  /// Create a copy of PickedAudioFile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? path = null,
    Object? name = null,
    Object? size = freezed,
  }) {
    return _then(
      PickedAudioFile(
        path: null == path
            ? _self.path
            : path // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _self.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        size: freezed == size
            ? _self.size
            : size // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [PickedAudioFile].
extension PickedAudioFilePatterns on PickedAudioFile {
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
    TResult Function(_PickedAudioFile value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PickedAudioFile() when $default != null:
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
    TResult Function(_PickedAudioFile value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PickedAudioFile():
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
    TResult? Function(_PickedAudioFile value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PickedAudioFile() when $default != null:
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
    TResult Function(String path, String name, int? size)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PickedAudioFile() when $default != null:
        return $default(_that.path, _that.name, _that.size);
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
    TResult Function(String path, String name, int? size) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PickedAudioFile():
        return $default(_that.path, _that.name, _that.size);
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
    TResult? Function(String path, String name, int? size)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PickedAudioFile() when $default != null:
        return $default(_that.path, _that.name, _that.size);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _PickedAudioFile extends PickedAudioFile {
  const _PickedAudioFile({required this.path, required this.name, this.size})
    : super._();

  @override
  final String path;
  @override
  final String name;

  /// Bytes, when known.
  @override
  final int? size;

  /// Create a copy of PickedAudioFile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PickedAudioFileCopyWith<_PickedAudioFile> get copyWith =>
      __$PickedAudioFileCopyWithImpl<_PickedAudioFile>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PickedAudioFile &&
            (identical(other.path, path) || other.path == path) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.size, size) || other.size == size));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, path, name, size);
  }

  @override
  String toString() {
    return 'PickedAudioFile(path: $path, name: $name, size: $size)';
  }
}

/// @nodoc
abstract mixin class _$PickedAudioFileCopyWith<$Res>
    implements $PickedAudioFileCopyWith<$Res> {
  factory _$PickedAudioFileCopyWith(
    _PickedAudioFile value,
    $Res Function(_PickedAudioFile) _then,
  ) = __$PickedAudioFileCopyWithImpl;
  @override
  @useResult
  $Res call({String path, String name, int? size});
}

/// @nodoc
class __$PickedAudioFileCopyWithImpl<$Res>
    implements _$PickedAudioFileCopyWith<$Res> {
  __$PickedAudioFileCopyWithImpl(this._self, this._then);

  final _PickedAudioFile _self;
  final $Res Function(_PickedAudioFile) _then;

  /// Create a copy of PickedAudioFile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? path = null,
    Object? name = null,
    Object? size = freezed,
  }) {
    return _then(
      _PickedAudioFile(
        path: null == path
            ? _self.path
            : path // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _self.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        size: freezed == size
            ? _self.size
            : size // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}
