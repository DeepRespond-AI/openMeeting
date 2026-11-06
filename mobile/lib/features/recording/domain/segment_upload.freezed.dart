// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'segment_upload.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SegmentUpload {
  String get meetingId;

  /// 0-based, increasing per meeting; the server dedups on `(meeting_id, seq)`.
  int get seq;
  double get startSec;
  double get endSec;

  /// Transcription language; `null` = auto-detect (query parameter omitted).
  String? get language;

  /// Create a copy of SegmentUpload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SegmentUploadCopyWith<SegmentUpload> get copyWith =>
      _$SegmentUploadCopyWithImpl<SegmentUpload>(
        this as SegmentUpload,
        _$identity,
      );

  /// Serializes this SegmentUpload to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as SegmentUpload;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SegmentUpload &&
            (identical(other.meetingId, _this.meetingId) ||
                other.meetingId == _this.meetingId) &&
            (identical(other.seq, _this.seq) || other.seq == _this.seq) &&
            (identical(other.startSec, _this.startSec) ||
                other.startSec == _this.startSec) &&
            (identical(other.endSec, _this.endSec) ||
                other.endSec == _this.endSec) &&
            (identical(other.language, _this.language) ||
                other.language == _this.language));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as SegmentUpload;
    return Object.hash(
      runtimeType,
      _this.meetingId,
      _this.seq,
      _this.startSec,
      _this.endSec,
      _this.language,
    );
  }

  @override
  String toString() {
    final _this = this as SegmentUpload;
    return 'SegmentUpload(meetingId: ${_this.meetingId}, seq: ${_this.seq}, startSec: ${_this.startSec}, endSec: ${_this.endSec}, language: ${_this.language})';
  }
}

/// @nodoc
abstract mixin class $SegmentUploadCopyWith<$Res> {
  factory $SegmentUploadCopyWith(
    SegmentUpload value,
    $Res Function(SegmentUpload) _then,
  ) = _$SegmentUploadCopyWithImpl;
  @useResult
  $Res call({
    String meetingId,
    int seq,
    double startSec,
    double endSec,
    String? language,
  });
}

/// @nodoc
class _$SegmentUploadCopyWithImpl<$Res>
    implements $SegmentUploadCopyWith<$Res> {
  _$SegmentUploadCopyWithImpl(this._self, this._then);

  final SegmentUpload _self;
  final $Res Function(SegmentUpload) _then;

  /// Create a copy of SegmentUpload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? meetingId = null,
    Object? seq = null,
    Object? startSec = null,
    Object? endSec = null,
    Object? language = freezed,
  }) {
    return _then(
      SegmentUpload(
        meetingId: null == meetingId
            ? _self.meetingId
            : meetingId // ignore: cast_nullable_to_non_nullable
                  as String,
        seq: null == seq
            ? _self.seq
            : seq // ignore: cast_nullable_to_non_nullable
                  as int,
        startSec: null == startSec
            ? _self.startSec
            : startSec // ignore: cast_nullable_to_non_nullable
                  as double,
        endSec: null == endSec
            ? _self.endSec
            : endSec // ignore: cast_nullable_to_non_nullable
                  as double,
        language: freezed == language
            ? _self.language
            : language // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [SegmentUpload].
extension SegmentUploadPatterns on SegmentUpload {
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
    TResult Function(_SegmentUpload value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SegmentUpload() when $default != null:
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
    TResult Function(_SegmentUpload value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SegmentUpload():
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
    TResult? Function(_SegmentUpload value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SegmentUpload() when $default != null:
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
      String meetingId,
      int seq,
      double startSec,
      double endSec,
      String? language,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SegmentUpload() when $default != null:
        return $default(
          _that.meetingId,
          _that.seq,
          _that.startSec,
          _that.endSec,
          _that.language,
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
      String meetingId,
      int seq,
      double startSec,
      double endSec,
      String? language,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SegmentUpload():
        return $default(
          _that.meetingId,
          _that.seq,
          _that.startSec,
          _that.endSec,
          _that.language,
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
      String meetingId,
      int seq,
      double startSec,
      double endSec,
      String? language,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SegmentUpload() when $default != null:
        return $default(
          _that.meetingId,
          _that.seq,
          _that.startSec,
          _that.endSec,
          _that.language,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _SegmentUpload implements SegmentUpload {
  const _SegmentUpload({
    required this.meetingId,
    required this.seq,
    required this.startSec,
    required this.endSec,
    this.language,
  });
  factory _SegmentUpload.fromJson(Map<String, dynamic> json) =>
      _$SegmentUploadFromJson(json);

  @override
  final String meetingId;

  /// 0-based, increasing per meeting; the server dedups on `(meeting_id, seq)`.
  @override
  final int seq;
  @override
  final double startSec;
  @override
  final double endSec;

  /// Transcription language; `null` = auto-detect (query parameter omitted).
  @override
  final String? language;

  /// Create a copy of SegmentUpload
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$SegmentUploadCopyWith<_SegmentUpload> get copyWith =>
      __$SegmentUploadCopyWithImpl<_SegmentUpload>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$SegmentUploadToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _SegmentUpload &&
            (identical(other.meetingId, meetingId) ||
                other.meetingId == meetingId) &&
            (identical(other.seq, seq) || other.seq == seq) &&
            (identical(other.startSec, startSec) ||
                other.startSec == startSec) &&
            (identical(other.endSec, endSec) || other.endSec == endSec) &&
            (identical(other.language, language) ||
                other.language == language));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(runtimeType, meetingId, seq, startSec, endSec, language);
  }

  @override
  String toString() {
    return 'SegmentUpload(meetingId: $meetingId, seq: $seq, startSec: $startSec, endSec: $endSec, language: $language)';
  }
}

/// @nodoc
abstract mixin class _$SegmentUploadCopyWith<$Res>
    implements $SegmentUploadCopyWith<$Res> {
  factory _$SegmentUploadCopyWith(
    _SegmentUpload value,
    $Res Function(_SegmentUpload) _then,
  ) = __$SegmentUploadCopyWithImpl;
  @override
  @useResult
  $Res call({
    String meetingId,
    int seq,
    double startSec,
    double endSec,
    String? language,
  });
}

/// @nodoc
class __$SegmentUploadCopyWithImpl<$Res>
    implements _$SegmentUploadCopyWith<$Res> {
  __$SegmentUploadCopyWithImpl(this._self, this._then);

  final _SegmentUpload _self;
  final $Res Function(_SegmentUpload) _then;

  /// Create a copy of SegmentUpload
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? meetingId = null,
    Object? seq = null,
    Object? startSec = null,
    Object? endSec = null,
    Object? language = freezed,
  }) {
    return _then(
      _SegmentUpload(
        meetingId: null == meetingId
            ? _self.meetingId
            : meetingId // ignore: cast_nullable_to_non_nullable
                  as String,
        seq: null == seq
            ? _self.seq
            : seq // ignore: cast_nullable_to_non_nullable
                  as int,
        startSec: null == startSec
            ? _self.startSec
            : startSec // ignore: cast_nullable_to_non_nullable
                  as double,
        endSec: null == endSec
            ? _self.endSec
            : endSec // ignore: cast_nullable_to_non_nullable
                  as double,
        language: freezed == language
            ? _self.language
            : language // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
mixin _$SegmentUploadResult {
  SegmentUpload get upload;

  /// Transcribed text ('' when the server heard nothing).
  String get text;

  /// Stored transcript id; `null` when nothing was stored.
  String? get transcriptId;

  /// Create a copy of SegmentUploadResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SegmentUploadResultCopyWith<SegmentUploadResult> get copyWith =>
      _$SegmentUploadResultCopyWithImpl<SegmentUploadResult>(
        this as SegmentUploadResult,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    final _this = this as SegmentUploadResult;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SegmentUploadResult &&
            (identical(other.upload, _this.upload) ||
                other.upload == _this.upload) &&
            (identical(other.text, _this.text) || other.text == _this.text) &&
            (identical(other.transcriptId, _this.transcriptId) ||
                other.transcriptId == _this.transcriptId));
  }

  @override
  int get hashCode {
    final _this = this as SegmentUploadResult;
    return Object.hash(
      runtimeType,
      _this.upload,
      _this.text,
      _this.transcriptId,
    );
  }

  @override
  String toString() {
    final _this = this as SegmentUploadResult;
    return 'SegmentUploadResult(upload: ${_this.upload}, text: ${_this.text}, transcriptId: ${_this.transcriptId})';
  }
}

/// @nodoc
abstract mixin class $SegmentUploadResultCopyWith<$Res> {
  factory $SegmentUploadResultCopyWith(
    SegmentUploadResult value,
    $Res Function(SegmentUploadResult) _then,
  ) = _$SegmentUploadResultCopyWithImpl;
  @useResult
  $Res call({SegmentUpload upload, String text, String? transcriptId});

  $SegmentUploadCopyWith<$Res> get upload;
}

/// @nodoc
class _$SegmentUploadResultCopyWithImpl<$Res>
    implements $SegmentUploadResultCopyWith<$Res> {
  _$SegmentUploadResultCopyWithImpl(this._self, this._then);

  final SegmentUploadResult _self;
  final $Res Function(SegmentUploadResult) _then;

  /// Create a copy of SegmentUploadResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? upload = null,
    Object? text = null,
    Object? transcriptId = freezed,
  }) {
    return _then(
      SegmentUploadResult(
        upload: null == upload
            ? _self.upload
            : upload // ignore: cast_nullable_to_non_nullable
                  as SegmentUpload,
        text: null == text
            ? _self.text
            : text // ignore: cast_nullable_to_non_nullable
                  as String,
        transcriptId: freezed == transcriptId
            ? _self.transcriptId
            : transcriptId // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }

  /// Create a copy of SegmentUploadResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SegmentUploadCopyWith<$Res> get upload {
    return $SegmentUploadCopyWith<$Res>(_self.upload, (value) {
      return _then(_self.copyWith(upload: value));
    });
  }
}

/// Adds pattern-matching-related methods to [SegmentUploadResult].
extension SegmentUploadResultPatterns on SegmentUploadResult {
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
    TResult Function(_SegmentUploadResult value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SegmentUploadResult() when $default != null:
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
    TResult Function(_SegmentUploadResult value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SegmentUploadResult():
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
    TResult? Function(_SegmentUploadResult value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SegmentUploadResult() when $default != null:
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
    TResult Function(SegmentUpload upload, String text, String? transcriptId)?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SegmentUploadResult() when $default != null:
        return $default(_that.upload, _that.text, _that.transcriptId);
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
    TResult Function(SegmentUpload upload, String text, String? transcriptId)
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SegmentUploadResult():
        return $default(_that.upload, _that.text, _that.transcriptId);
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
    TResult? Function(SegmentUpload upload, String text, String? transcriptId)?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SegmentUploadResult() when $default != null:
        return $default(_that.upload, _that.text, _that.transcriptId);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _SegmentUploadResult implements SegmentUploadResult {
  const _SegmentUploadResult({
    required this.upload,
    required this.text,
    this.transcriptId,
  });

  @override
  final SegmentUpload upload;

  /// Transcribed text ('' when the server heard nothing).
  @override
  final String text;

  /// Stored transcript id; `null` when nothing was stored.
  @override
  final String? transcriptId;

  /// Create a copy of SegmentUploadResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$SegmentUploadResultCopyWith<_SegmentUploadResult> get copyWith =>
      __$SegmentUploadResultCopyWithImpl<_SegmentUploadResult>(
        this,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _SegmentUploadResult &&
            (identical(other.upload, upload) || other.upload == upload) &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.transcriptId, transcriptId) ||
                other.transcriptId == transcriptId));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, upload, text, transcriptId);
  }

  @override
  String toString() {
    return 'SegmentUploadResult(upload: $upload, text: $text, transcriptId: $transcriptId)';
  }
}

/// @nodoc
abstract mixin class _$SegmentUploadResultCopyWith<$Res>
    implements $SegmentUploadResultCopyWith<$Res> {
  factory _$SegmentUploadResultCopyWith(
    _SegmentUploadResult value,
    $Res Function(_SegmentUploadResult) _then,
  ) = __$SegmentUploadResultCopyWithImpl;
  @override
  @useResult
  $Res call({SegmentUpload upload, String text, String? transcriptId});

  @override
  $SegmentUploadCopyWith<$Res> get upload;
}

/// @nodoc
class __$SegmentUploadResultCopyWithImpl<$Res>
    implements _$SegmentUploadResultCopyWith<$Res> {
  __$SegmentUploadResultCopyWithImpl(this._self, this._then);

  final _SegmentUploadResult _self;
  final $Res Function(_SegmentUploadResult) _then;

  /// Create a copy of SegmentUploadResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? upload = null,
    Object? text = null,
    Object? transcriptId = freezed,
  }) {
    return _then(
      _SegmentUploadResult(
        upload: null == upload
            ? _self.upload
            : upload // ignore: cast_nullable_to_non_nullable
                  as SegmentUpload,
        text: null == text
            ? _self.text
            : text // ignore: cast_nullable_to_non_nullable
                  as String,
        transcriptId: freezed == transcriptId
            ? _self.transcriptId
            : transcriptId // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }

  /// Create a copy of SegmentUploadResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SegmentUploadCopyWith<$Res> get upload {
    return $SegmentUploadCopyWith<$Res>(_self.upload, (value) {
      return _then(_self.copyWith(upload: value));
    });
  }
}
