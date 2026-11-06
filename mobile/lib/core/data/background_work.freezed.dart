// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'background_work.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BackgroundNotice {
  int get id;
  String get meetingId;

  /// Create a copy of BackgroundNotice
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $BackgroundNoticeCopyWith<BackgroundNotice> get copyWith =>
      _$BackgroundNoticeCopyWithImpl<BackgroundNotice>(
        this as BackgroundNotice,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    final _this = this as BackgroundNotice;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is BackgroundNotice &&
            (identical(other.id, _this.id) || other.id == _this.id) &&
            (identical(other.meetingId, _this.meetingId) ||
                other.meetingId == _this.meetingId));
  }

  @override
  int get hashCode {
    final _this = this as BackgroundNotice;
    return Object.hash(runtimeType, _this.id, _this.meetingId);
  }

  @override
  String toString() {
    final _this = this as BackgroundNotice;
    return 'BackgroundNotice(id: ${_this.id}, meetingId: ${_this.meetingId})';
  }
}

/// @nodoc
abstract mixin class $BackgroundNoticeCopyWith<$Res> {
  factory $BackgroundNoticeCopyWith(
    BackgroundNotice value,
    $Res Function(BackgroundNotice) _then,
  ) = _$BackgroundNoticeCopyWithImpl;
  @useResult
  $Res call({int id, String meetingId});
}

/// @nodoc
class _$BackgroundNoticeCopyWithImpl<$Res>
    implements $BackgroundNoticeCopyWith<$Res> {
  _$BackgroundNoticeCopyWithImpl(this._self, this._then);

  final BackgroundNotice _self;
  final $Res Function(BackgroundNotice) _then;

  /// Create a copy of BackgroundNotice
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? meetingId = null}) {
    return _then(
      _self.copyWith(
        id: null == id
            ? _self.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        meetingId: null == meetingId
            ? _self.meetingId
            : meetingId // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [BackgroundNotice].
extension BackgroundNoticePatterns on BackgroundNotice {
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
    TResult Function(ImportTranscribedNotice value)? importTranscribed,
    TResult Function(ImportFailedNotice value)? importFailed,
    TResult Function(RecordingUploadFailedNotice value)? recordingUploadFailed,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case ImportTranscribedNotice() when importTranscribed != null:
        return importTranscribed(_that);
      case ImportFailedNotice() when importFailed != null:
        return importFailed(_that);
      case RecordingUploadFailedNotice() when recordingUploadFailed != null:
        return recordingUploadFailed(_that);
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
    required TResult Function(ImportTranscribedNotice value) importTranscribed,
    required TResult Function(ImportFailedNotice value) importFailed,
    required TResult Function(RecordingUploadFailedNotice value)
    recordingUploadFailed,
  }) {
    final _that = this;
    switch (_that) {
      case ImportTranscribedNotice():
        return importTranscribed(_that);
      case ImportFailedNotice():
        return importFailed(_that);
      case RecordingUploadFailedNotice():
        return recordingUploadFailed(_that);
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
    TResult? Function(ImportTranscribedNotice value)? importTranscribed,
    TResult? Function(ImportFailedNotice value)? importFailed,
    TResult? Function(RecordingUploadFailedNotice value)? recordingUploadFailed,
  }) {
    final _that = this;
    switch (_that) {
      case ImportTranscribedNotice() when importTranscribed != null:
        return importTranscribed(_that);
      case ImportFailedNotice() when importFailed != null:
        return importFailed(_that);
      case RecordingUploadFailedNotice() when recordingUploadFailed != null:
        return recordingUploadFailed(_that);
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
    TResult Function(int id, String meetingId, String title, int segments)?
    importTranscribed,
    TResult Function(int id, String meetingId, String title, String? message)?
    importFailed,
    TResult Function(int id, String meetingId)? recordingUploadFailed,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case ImportTranscribedNotice() when importTranscribed != null:
        return importTranscribed(
          _that.id,
          _that.meetingId,
          _that.title,
          _that.segments,
        );
      case ImportFailedNotice() when importFailed != null:
        return importFailed(
          _that.id,
          _that.meetingId,
          _that.title,
          _that.message,
        );
      case RecordingUploadFailedNotice() when recordingUploadFailed != null:
        return recordingUploadFailed(_that.id, _that.meetingId);
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
    required TResult Function(
      int id,
      String meetingId,
      String title,
      int segments,
    )
    importTranscribed,
    required TResult Function(
      int id,
      String meetingId,
      String title,
      String? message,
    )
    importFailed,
    required TResult Function(int id, String meetingId) recordingUploadFailed,
  }) {
    final _that = this;
    switch (_that) {
      case ImportTranscribedNotice():
        return importTranscribed(
          _that.id,
          _that.meetingId,
          _that.title,
          _that.segments,
        );
      case ImportFailedNotice():
        return importFailed(
          _that.id,
          _that.meetingId,
          _that.title,
          _that.message,
        );
      case RecordingUploadFailedNotice():
        return recordingUploadFailed(_that.id, _that.meetingId);
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
    TResult? Function(int id, String meetingId, String title, int segments)?
    importTranscribed,
    TResult? Function(int id, String meetingId, String title, String? message)?
    importFailed,
    TResult? Function(int id, String meetingId)? recordingUploadFailed,
  }) {
    final _that = this;
    switch (_that) {
      case ImportTranscribedNotice() when importTranscribed != null:
        return importTranscribed(
          _that.id,
          _that.meetingId,
          _that.title,
          _that.segments,
        );
      case ImportFailedNotice() when importFailed != null:
        return importFailed(
          _that.id,
          _that.meetingId,
          _that.title,
          _that.message,
        );
      case RecordingUploadFailedNotice() when recordingUploadFailed != null:
        return recordingUploadFailed(_that.id, _that.meetingId);
      case _:
        return null;
    }
  }
}

/// @nodoc

class ImportTranscribedNotice implements BackgroundNotice {
  const ImportTranscribedNotice({
    required this.id,
    required this.meetingId,
    required this.title,
    required this.segments,
  });

  @override
  final int id;
  @override
  final String meetingId;
  final String title;
  final int segments;

  /// Create a copy of BackgroundNotice
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ImportTranscribedNoticeCopyWith<ImportTranscribedNotice> get copyWith =>
      _$ImportTranscribedNoticeCopyWithImpl<ImportTranscribedNotice>(
        this,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ImportTranscribedNotice &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.meetingId, meetingId) ||
                other.meetingId == meetingId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.segments, segments) ||
                other.segments == segments));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, id, meetingId, title, segments);
  }

  @override
  String toString() {
    return 'BackgroundNotice.importTranscribed(id: $id, meetingId: $meetingId, title: $title, segments: $segments)';
  }
}

/// @nodoc
abstract mixin class $ImportTranscribedNoticeCopyWith<$Res>
    implements $BackgroundNoticeCopyWith<$Res> {
  factory $ImportTranscribedNoticeCopyWith(
    ImportTranscribedNotice value,
    $Res Function(ImportTranscribedNotice) _then,
  ) = _$ImportTranscribedNoticeCopyWithImpl;
  @override
  @useResult
  $Res call({int id, String meetingId, String title, int segments});
}

/// @nodoc
class _$ImportTranscribedNoticeCopyWithImpl<$Res>
    implements $ImportTranscribedNoticeCopyWith<$Res> {
  _$ImportTranscribedNoticeCopyWithImpl(this._self, this._then);

  final ImportTranscribedNotice _self;
  final $Res Function(ImportTranscribedNotice) _then;

  /// Create a copy of BackgroundNotice
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? meetingId = null,
    Object? title = null,
    Object? segments = null,
  }) {
    return _then(
      ImportTranscribedNotice(
        id: null == id
            ? _self.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        meetingId: null == meetingId
            ? _self.meetingId
            : meetingId // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _self.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        segments: null == segments
            ? _self.segments
            : segments // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class ImportFailedNotice implements BackgroundNotice {
  const ImportFailedNotice({
    required this.id,
    required this.meetingId,
    required this.title,
    this.message,
  });

  @override
  final int id;
  @override
  final String meetingId;
  final String title;
  final String? message;

  /// Create a copy of BackgroundNotice
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ImportFailedNoticeCopyWith<ImportFailedNotice> get copyWith =>
      _$ImportFailedNoticeCopyWithImpl<ImportFailedNotice>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ImportFailedNotice &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.meetingId, meetingId) ||
                other.meetingId == meetingId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, id, meetingId, title, message);
  }

  @override
  String toString() {
    return 'BackgroundNotice.importFailed(id: $id, meetingId: $meetingId, title: $title, message: $message)';
  }
}

/// @nodoc
abstract mixin class $ImportFailedNoticeCopyWith<$Res>
    implements $BackgroundNoticeCopyWith<$Res> {
  factory $ImportFailedNoticeCopyWith(
    ImportFailedNotice value,
    $Res Function(ImportFailedNotice) _then,
  ) = _$ImportFailedNoticeCopyWithImpl;
  @override
  @useResult
  $Res call({int id, String meetingId, String title, String? message});
}

/// @nodoc
class _$ImportFailedNoticeCopyWithImpl<$Res>
    implements $ImportFailedNoticeCopyWith<$Res> {
  _$ImportFailedNoticeCopyWithImpl(this._self, this._then);

  final ImportFailedNotice _self;
  final $Res Function(ImportFailedNotice) _then;

  /// Create a copy of BackgroundNotice
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? meetingId = null,
    Object? title = null,
    Object? message = freezed,
  }) {
    return _then(
      ImportFailedNotice(
        id: null == id
            ? _self.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        meetingId: null == meetingId
            ? _self.meetingId
            : meetingId // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _self.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        message: freezed == message
            ? _self.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class RecordingUploadFailedNotice implements BackgroundNotice {
  const RecordingUploadFailedNotice({
    required this.id,
    required this.meetingId,
  });

  @override
  final int id;
  @override
  final String meetingId;

  /// Create a copy of BackgroundNotice
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $RecordingUploadFailedNoticeCopyWith<RecordingUploadFailedNotice>
  get copyWith =>
      _$RecordingUploadFailedNoticeCopyWithImpl<RecordingUploadFailedNotice>(
        this,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is RecordingUploadFailedNotice &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.meetingId, meetingId) ||
                other.meetingId == meetingId));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, id, meetingId);
  }

  @override
  String toString() {
    return 'BackgroundNotice.recordingUploadFailed(id: $id, meetingId: $meetingId)';
  }
}

/// @nodoc
abstract mixin class $RecordingUploadFailedNoticeCopyWith<$Res>
    implements $BackgroundNoticeCopyWith<$Res> {
  factory $RecordingUploadFailedNoticeCopyWith(
    RecordingUploadFailedNotice value,
    $Res Function(RecordingUploadFailedNotice) _then,
  ) = _$RecordingUploadFailedNoticeCopyWithImpl;
  @override
  @useResult
  $Res call({int id, String meetingId});
}

/// @nodoc
class _$RecordingUploadFailedNoticeCopyWithImpl<$Res>
    implements $RecordingUploadFailedNoticeCopyWith<$Res> {
  _$RecordingUploadFailedNoticeCopyWithImpl(this._self, this._then);

  final RecordingUploadFailedNotice _self;
  final $Res Function(RecordingUploadFailedNotice) _then;

  /// Create a copy of BackgroundNotice
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({Object? id = null, Object? meetingId = null}) {
    return _then(
      RecordingUploadFailedNotice(
        id: null == id
            ? _self.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        meetingId: null == meetingId
            ? _self.meetingId
            : meetingId // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}
