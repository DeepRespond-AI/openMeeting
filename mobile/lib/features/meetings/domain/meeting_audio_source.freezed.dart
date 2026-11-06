// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'meeting_audio_source.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MeetingAudioSource {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is MeetingAudioSource);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'MeetingAudioSource()';
  }
}

/// @nodoc
class $MeetingAudioSourceCopyWith<$Res> {
  $MeetingAudioSourceCopyWith(
    MeetingAudioSource _,
    $Res Function(MeetingAudioSource) __,
  );
}

/// Adds pattern-matching-related methods to [MeetingAudioSource].
extension MeetingAudioSourcePatterns on MeetingAudioSource {
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
    TResult Function(MeetingAudioRedirect value)? redirect,
    TResult Function(MeetingAudioDirect value)? direct,
    TResult Function(MeetingAudioNone value)? none,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case MeetingAudioRedirect() when redirect != null:
        return redirect(_that);
      case MeetingAudioDirect() when direct != null:
        return direct(_that);
      case MeetingAudioNone() when none != null:
        return none(_that);
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
    required TResult Function(MeetingAudioRedirect value) redirect,
    required TResult Function(MeetingAudioDirect value) direct,
    required TResult Function(MeetingAudioNone value) none,
  }) {
    final _that = this;
    switch (_that) {
      case MeetingAudioRedirect():
        return redirect(_that);
      case MeetingAudioDirect():
        return direct(_that);
      case MeetingAudioNone():
        return none(_that);
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
    TResult? Function(MeetingAudioRedirect value)? redirect,
    TResult? Function(MeetingAudioDirect value)? direct,
    TResult? Function(MeetingAudioNone value)? none,
  }) {
    final _that = this;
    switch (_that) {
      case MeetingAudioRedirect() when redirect != null:
        return redirect(_that);
      case MeetingAudioDirect() when direct != null:
        return direct(_that);
      case MeetingAudioNone() when none != null:
        return none(_that);
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
    TResult Function(Uri url)? redirect,
    TResult Function(Uri url, Map<String, String> headers)? direct,
    TResult Function()? none,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case MeetingAudioRedirect() when redirect != null:
        return redirect(_that.url);
      case MeetingAudioDirect() when direct != null:
        return direct(_that.url, _that.headers);
      case MeetingAudioNone() when none != null:
        return none();
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
    required TResult Function(Uri url) redirect,
    required TResult Function(Uri url, Map<String, String> headers) direct,
    required TResult Function() none,
  }) {
    final _that = this;
    switch (_that) {
      case MeetingAudioRedirect():
        return redirect(_that.url);
      case MeetingAudioDirect():
        return direct(_that.url, _that.headers);
      case MeetingAudioNone():
        return none();
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
    TResult? Function(Uri url)? redirect,
    TResult? Function(Uri url, Map<String, String> headers)? direct,
    TResult? Function()? none,
  }) {
    final _that = this;
    switch (_that) {
      case MeetingAudioRedirect() when redirect != null:
        return redirect(_that.url);
      case MeetingAudioDirect() when direct != null:
        return direct(_that.url, _that.headers);
      case MeetingAudioNone() when none != null:
        return none();
      case _:
        return null;
    }
  }
}

/// @nodoc

class MeetingAudioRedirect implements MeetingAudioSource {
  const MeetingAudioRedirect(this.url);

  final Uri url;

  /// Create a copy of MeetingAudioSource
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $MeetingAudioRedirectCopyWith<MeetingAudioRedirect> get copyWith =>
      _$MeetingAudioRedirectCopyWithImpl<MeetingAudioRedirect>(
        this,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MeetingAudioRedirect &&
            (identical(other.url, url) || other.url == url));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, url);
  }

  @override
  String toString() {
    return 'MeetingAudioSource.redirect(url: $url)';
  }
}

/// @nodoc
abstract mixin class $MeetingAudioRedirectCopyWith<$Res>
    implements $MeetingAudioSourceCopyWith<$Res> {
  factory $MeetingAudioRedirectCopyWith(
    MeetingAudioRedirect value,
    $Res Function(MeetingAudioRedirect) _then,
  ) = _$MeetingAudioRedirectCopyWithImpl;
  @useResult
  $Res call({Uri url});
}

/// @nodoc
class _$MeetingAudioRedirectCopyWithImpl<$Res>
    implements $MeetingAudioRedirectCopyWith<$Res> {
  _$MeetingAudioRedirectCopyWithImpl(this._self, this._then);

  final MeetingAudioRedirect _self;
  final $Res Function(MeetingAudioRedirect) _then;

  /// Create a copy of MeetingAudioSource
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? url = null}) {
    return _then(
      MeetingAudioRedirect(
        null == url
            ? _self.url
            : url // ignore: cast_nullable_to_non_nullable
                  as Uri,
      ),
    );
  }
}

/// @nodoc

class MeetingAudioDirect implements MeetingAudioSource {
  const MeetingAudioDirect(this.url, Map<String, String> headers)
    : _headers = headers;

  final Uri url;
  final Map<String, String> _headers;
  Map<String, String> get headers {
    if (_headers is EqualUnmodifiableMapView) return _headers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_headers);
  }

  /// Create a copy of MeetingAudioSource
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $MeetingAudioDirectCopyWith<MeetingAudioDirect> get copyWith =>
      _$MeetingAudioDirectCopyWithImpl<MeetingAudioDirect>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MeetingAudioDirect &&
            (identical(other.url, url) || other.url == url) &&
            const DeepCollectionEquality().equals(other.headers, _headers));
  }

  @override
  int get hashCode {
    return Object.hash(
      runtimeType,
      url,
      const DeepCollectionEquality().hash(_headers),
    );
  }

  @override
  String toString() {
    return 'MeetingAudioSource.direct(url: $url, headers: $headers)';
  }
}

/// @nodoc
abstract mixin class $MeetingAudioDirectCopyWith<$Res>
    implements $MeetingAudioSourceCopyWith<$Res> {
  factory $MeetingAudioDirectCopyWith(
    MeetingAudioDirect value,
    $Res Function(MeetingAudioDirect) _then,
  ) = _$MeetingAudioDirectCopyWithImpl;
  @useResult
  $Res call({Uri url, Map<String, String> headers});
}

/// @nodoc
class _$MeetingAudioDirectCopyWithImpl<$Res>
    implements $MeetingAudioDirectCopyWith<$Res> {
  _$MeetingAudioDirectCopyWithImpl(this._self, this._then);

  final MeetingAudioDirect _self;
  final $Res Function(MeetingAudioDirect) _then;

  /// Create a copy of MeetingAudioSource
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? url = null, Object? headers = null}) {
    return _then(
      MeetingAudioDirect(
        null == url
            ? _self.url
            : url // ignore: cast_nullable_to_non_nullable
                  as Uri,
        null == headers
            ? _self._headers
            : headers // ignore: cast_nullable_to_non_nullable
                  as Map<String, String>,
      ),
    );
  }
}

/// @nodoc

class MeetingAudioNone implements MeetingAudioSource {
  const MeetingAudioNone();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is MeetingAudioNone);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'MeetingAudioSource.none()';
  }
}
