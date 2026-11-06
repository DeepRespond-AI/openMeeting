// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'meeting_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MeetingSummary {
  String get id;
  String get title;
  @JsonKey(name: 'can_manage')
  bool get canManage;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;

  /// Create a copy of MeetingSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $MeetingSummaryCopyWith<MeetingSummary> get copyWith =>
      _$MeetingSummaryCopyWithImpl<MeetingSummary>(
        this as MeetingSummary,
        _$identity,
      );

  /// Serializes this MeetingSummary to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as MeetingSummary;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MeetingSummary &&
            (identical(other.id, _this.id) || other.id == _this.id) &&
            (identical(other.title, _this.title) ||
                other.title == _this.title) &&
            (identical(other.canManage, _this.canManage) ||
                other.canManage == _this.canManage) &&
            (identical(other.createdAt, _this.createdAt) ||
                other.createdAt == _this.createdAt) &&
            (identical(other.updatedAt, _this.updatedAt) ||
                other.updatedAt == _this.updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as MeetingSummary;
    return Object.hash(
      runtimeType,
      _this.id,
      _this.title,
      _this.canManage,
      _this.createdAt,
      _this.updatedAt,
    );
  }

  @override
  String toString() {
    final _this = this as MeetingSummary;
    return 'MeetingSummary(id: ${_this.id}, title: ${_this.title}, canManage: ${_this.canManage}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt})';
  }
}

/// @nodoc
abstract mixin class $MeetingSummaryCopyWith<$Res> {
  factory $MeetingSummaryCopyWith(
    MeetingSummary value,
    $Res Function(MeetingSummary) _then,
  ) = _$MeetingSummaryCopyWithImpl;
  @useResult
  $Res call({
    String id,
    String title,
    @JsonKey(name: 'can_manage') bool canManage,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  });
}

/// @nodoc
class _$MeetingSummaryCopyWithImpl<$Res>
    implements $MeetingSummaryCopyWith<$Res> {
  _$MeetingSummaryCopyWithImpl(this._self, this._then);

  final MeetingSummary _self;
  final $Res Function(MeetingSummary) _then;

  /// Create a copy of MeetingSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? canManage = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      MeetingSummary(
        id: null == id
            ? _self.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _self.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        canManage: null == canManage
            ? _self.canManage
            : canManage // ignore: cast_nullable_to_non_nullable
                  as bool,
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

/// Adds pattern-matching-related methods to [MeetingSummary].
extension MeetingSummaryPatterns on MeetingSummary {
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
    TResult Function(_MeetingSummary value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _MeetingSummary() when $default != null:
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
    TResult Function(_MeetingSummary value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MeetingSummary():
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
    TResult? Function(_MeetingSummary value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MeetingSummary() when $default != null:
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
      String title,
      @JsonKey(name: 'can_manage') bool canManage,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _MeetingSummary() when $default != null:
        return $default(
          _that.id,
          _that.title,
          _that.canManage,
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
      String title,
      @JsonKey(name: 'can_manage') bool canManage,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MeetingSummary():
        return $default(
          _that.id,
          _that.title,
          _that.canManage,
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
      String title,
      @JsonKey(name: 'can_manage') bool canManage,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MeetingSummary() when $default != null:
        return $default(
          _that.id,
          _that.title,
          _that.canManage,
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
class _MeetingSummary implements MeetingSummary {
  const _MeetingSummary({
    required this.id,
    required this.title,
    @JsonKey(name: 'can_manage') this.canManage = true,
    @JsonKey(name: 'created_at') this.createdAt,
    @JsonKey(name: 'updated_at') this.updatedAt,
  });
  factory _MeetingSummary.fromJson(Map<String, dynamic> json) =>
      _$MeetingSummaryFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  @JsonKey(name: 'can_manage')
  final bool canManage;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  /// Create a copy of MeetingSummary
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$MeetingSummaryCopyWith<_MeetingSummary> get copyWith =>
      __$MeetingSummaryCopyWithImpl<_MeetingSummary>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$MeetingSummaryToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _MeetingSummary &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.canManage, canManage) ||
                other.canManage == canManage) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(runtimeType, id, title, canManage, createdAt, updatedAt);
  }

  @override
  String toString() {
    return 'MeetingSummary(id: $id, title: $title, canManage: $canManage, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class _$MeetingSummaryCopyWith<$Res>
    implements $MeetingSummaryCopyWith<$Res> {
  factory _$MeetingSummaryCopyWith(
    _MeetingSummary value,
    $Res Function(_MeetingSummary) _then,
  ) = __$MeetingSummaryCopyWithImpl;
  @override
  @useResult
  $Res call({
    String id,
    String title,
    @JsonKey(name: 'can_manage') bool canManage,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  });
}

/// @nodoc
class __$MeetingSummaryCopyWithImpl<$Res>
    implements _$MeetingSummaryCopyWith<$Res> {
  __$MeetingSummaryCopyWithImpl(this._self, this._then);

  final _MeetingSummary _self;
  final $Res Function(_MeetingSummary) _then;

  /// Create a copy of MeetingSummary
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? canManage = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _MeetingSummary(
        id: null == id
            ? _self.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _self.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        canManage: null == canManage
            ? _self.canManage
            : canManage // ignore: cast_nullable_to_non_nullable
                  as bool,
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

/// @nodoc
mixin _$MeetingMetadata {
  String get id;
  String get title;
  @JsonKey(name: 'can_manage')
  bool get canManage;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;
  @JsonKey(name: 'folder_path')
  String? get folderPath;
  @JsonKey(name: 'has_audio')
  bool get hasAudio;

  /// Seconds.
  @JsonKey(name: 'audio_duration')
  double? get audioDuration;

  /// Create a copy of MeetingMetadata
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $MeetingMetadataCopyWith<MeetingMetadata> get copyWith =>
      _$MeetingMetadataCopyWithImpl<MeetingMetadata>(
        this as MeetingMetadata,
        _$identity,
      );

  /// Serializes this MeetingMetadata to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as MeetingMetadata;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MeetingMetadata &&
            (identical(other.id, _this.id) || other.id == _this.id) &&
            (identical(other.title, _this.title) ||
                other.title == _this.title) &&
            (identical(other.canManage, _this.canManage) ||
                other.canManage == _this.canManage) &&
            (identical(other.createdAt, _this.createdAt) ||
                other.createdAt == _this.createdAt) &&
            (identical(other.updatedAt, _this.updatedAt) ||
                other.updatedAt == _this.updatedAt) &&
            (identical(other.folderPath, _this.folderPath) ||
                other.folderPath == _this.folderPath) &&
            (identical(other.hasAudio, _this.hasAudio) ||
                other.hasAudio == _this.hasAudio) &&
            (identical(other.audioDuration, _this.audioDuration) ||
                other.audioDuration == _this.audioDuration));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as MeetingMetadata;
    return Object.hash(
      runtimeType,
      _this.id,
      _this.title,
      _this.canManage,
      _this.createdAt,
      _this.updatedAt,
      _this.folderPath,
      _this.hasAudio,
      _this.audioDuration,
    );
  }

  @override
  String toString() {
    final _this = this as MeetingMetadata;
    return 'MeetingMetadata(id: ${_this.id}, title: ${_this.title}, canManage: ${_this.canManage}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt}, folderPath: ${_this.folderPath}, hasAudio: ${_this.hasAudio}, audioDuration: ${_this.audioDuration})';
  }
}

/// @nodoc
abstract mixin class $MeetingMetadataCopyWith<$Res> {
  factory $MeetingMetadataCopyWith(
    MeetingMetadata value,
    $Res Function(MeetingMetadata) _then,
  ) = _$MeetingMetadataCopyWithImpl;
  @useResult
  $Res call({
    String id,
    String title,
    @JsonKey(name: 'can_manage') bool canManage,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @JsonKey(name: 'folder_path') String? folderPath,
    @JsonKey(name: 'has_audio') bool hasAudio,
    @JsonKey(name: 'audio_duration') double? audioDuration,
  });
}

/// @nodoc
class _$MeetingMetadataCopyWithImpl<$Res>
    implements $MeetingMetadataCopyWith<$Res> {
  _$MeetingMetadataCopyWithImpl(this._self, this._then);

  final MeetingMetadata _self;
  final $Res Function(MeetingMetadata) _then;

  /// Create a copy of MeetingMetadata
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? canManage = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? folderPath = freezed,
    Object? hasAudio = null,
    Object? audioDuration = freezed,
  }) {
    return _then(
      MeetingMetadata(
        id: null == id
            ? _self.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _self.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        canManage: null == canManage
            ? _self.canManage
            : canManage // ignore: cast_nullable_to_non_nullable
                  as bool,
        createdAt: freezed == createdAt
            ? _self.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        updatedAt: freezed == updatedAt
            ? _self.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        folderPath: freezed == folderPath
            ? _self.folderPath
            : folderPath // ignore: cast_nullable_to_non_nullable
                  as String?,
        hasAudio: null == hasAudio
            ? _self.hasAudio
            : hasAudio // ignore: cast_nullable_to_non_nullable
                  as bool,
        audioDuration: freezed == audioDuration
            ? _self.audioDuration
            : audioDuration // ignore: cast_nullable_to_non_nullable
                  as double?,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [MeetingMetadata].
extension MeetingMetadataPatterns on MeetingMetadata {
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
    TResult Function(_MeetingMetadata value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _MeetingMetadata() when $default != null:
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
    TResult Function(_MeetingMetadata value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MeetingMetadata():
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
    TResult? Function(_MeetingMetadata value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MeetingMetadata() when $default != null:
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
      String title,
      @JsonKey(name: 'can_manage') bool canManage,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt,
      @JsonKey(name: 'folder_path') String? folderPath,
      @JsonKey(name: 'has_audio') bool hasAudio,
      @JsonKey(name: 'audio_duration') double? audioDuration,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _MeetingMetadata() when $default != null:
        return $default(
          _that.id,
          _that.title,
          _that.canManage,
          _that.createdAt,
          _that.updatedAt,
          _that.folderPath,
          _that.hasAudio,
          _that.audioDuration,
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
      String title,
      @JsonKey(name: 'can_manage') bool canManage,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt,
      @JsonKey(name: 'folder_path') String? folderPath,
      @JsonKey(name: 'has_audio') bool hasAudio,
      @JsonKey(name: 'audio_duration') double? audioDuration,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MeetingMetadata():
        return $default(
          _that.id,
          _that.title,
          _that.canManage,
          _that.createdAt,
          _that.updatedAt,
          _that.folderPath,
          _that.hasAudio,
          _that.audioDuration,
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
      String title,
      @JsonKey(name: 'can_manage') bool canManage,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt,
      @JsonKey(name: 'folder_path') String? folderPath,
      @JsonKey(name: 'has_audio') bool hasAudio,
      @JsonKey(name: 'audio_duration') double? audioDuration,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MeetingMetadata() when $default != null:
        return $default(
          _that.id,
          _that.title,
          _that.canManage,
          _that.createdAt,
          _that.updatedAt,
          _that.folderPath,
          _that.hasAudio,
          _that.audioDuration,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _MeetingMetadata implements MeetingMetadata {
  const _MeetingMetadata({
    required this.id,
    required this.title,
    @JsonKey(name: 'can_manage') this.canManage = true,
    @JsonKey(name: 'created_at') this.createdAt,
    @JsonKey(name: 'updated_at') this.updatedAt,
    @JsonKey(name: 'folder_path') this.folderPath,
    @JsonKey(name: 'has_audio') this.hasAudio = false,
    @JsonKey(name: 'audio_duration') this.audioDuration,
  });
  factory _MeetingMetadata.fromJson(Map<String, dynamic> json) =>
      _$MeetingMetadataFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  @JsonKey(name: 'can_manage')
  final bool canManage;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  @override
  @JsonKey(name: 'folder_path')
  final String? folderPath;
  @override
  @JsonKey(name: 'has_audio')
  final bool hasAudio;

  /// Seconds.
  @override
  @JsonKey(name: 'audio_duration')
  final double? audioDuration;

  /// Create a copy of MeetingMetadata
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$MeetingMetadataCopyWith<_MeetingMetadata> get copyWith =>
      __$MeetingMetadataCopyWithImpl<_MeetingMetadata>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$MeetingMetadataToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _MeetingMetadata &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.canManage, canManage) ||
                other.canManage == canManage) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.folderPath, folderPath) ||
                other.folderPath == folderPath) &&
            (identical(other.hasAudio, hasAudio) ||
                other.hasAudio == hasAudio) &&
            (identical(other.audioDuration, audioDuration) ||
                other.audioDuration == audioDuration));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(
      runtimeType,
      id,
      title,
      canManage,
      createdAt,
      updatedAt,
      folderPath,
      hasAudio,
      audioDuration,
    );
  }

  @override
  String toString() {
    return 'MeetingMetadata(id: $id, title: $title, canManage: $canManage, createdAt: $createdAt, updatedAt: $updatedAt, folderPath: $folderPath, hasAudio: $hasAudio, audioDuration: $audioDuration)';
  }
}

/// @nodoc
abstract mixin class _$MeetingMetadataCopyWith<$Res>
    implements $MeetingMetadataCopyWith<$Res> {
  factory _$MeetingMetadataCopyWith(
    _MeetingMetadata value,
    $Res Function(_MeetingMetadata) _then,
  ) = __$MeetingMetadataCopyWithImpl;
  @override
  @useResult
  $Res call({
    String id,
    String title,
    @JsonKey(name: 'can_manage') bool canManage,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @JsonKey(name: 'folder_path') String? folderPath,
    @JsonKey(name: 'has_audio') bool hasAudio,
    @JsonKey(name: 'audio_duration') double? audioDuration,
  });
}

/// @nodoc
class __$MeetingMetadataCopyWithImpl<$Res>
    implements _$MeetingMetadataCopyWith<$Res> {
  __$MeetingMetadataCopyWithImpl(this._self, this._then);

  final _MeetingMetadata _self;
  final $Res Function(_MeetingMetadata) _then;

  /// Create a copy of MeetingMetadata
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? canManage = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? folderPath = freezed,
    Object? hasAudio = null,
    Object? audioDuration = freezed,
  }) {
    return _then(
      _MeetingMetadata(
        id: null == id
            ? _self.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _self.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        canManage: null == canManage
            ? _self.canManage
            : canManage // ignore: cast_nullable_to_non_nullable
                  as bool,
        createdAt: freezed == createdAt
            ? _self.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        updatedAt: freezed == updatedAt
            ? _self.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        folderPath: freezed == folderPath
            ? _self.folderPath
            : folderPath // ignore: cast_nullable_to_non_nullable
                  as String?,
        hasAudio: null == hasAudio
            ? _self.hasAudio
            : hasAudio // ignore: cast_nullable_to_non_nullable
                  as bool,
        audioDuration: freezed == audioDuration
            ? _self.audioDuration
            : audioDuration // ignore: cast_nullable_to_non_nullable
                  as double?,
      ),
    );
  }
}

/// @nodoc
mixin _$MeetingTranscript {
  String get id;
  String get text;
  String get timestamp;

  /// Seconds from the start of the recording.
  @JsonKey(name: 'audio_start_time')
  double? get audioStartTime;
  @JsonKey(name: 'audio_end_time')
  double? get audioEndTime;
  double? get duration;

  /// Create a copy of MeetingTranscript
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $MeetingTranscriptCopyWith<MeetingTranscript> get copyWith =>
      _$MeetingTranscriptCopyWithImpl<MeetingTranscript>(
        this as MeetingTranscript,
        _$identity,
      );

  /// Serializes this MeetingTranscript to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as MeetingTranscript;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MeetingTranscript &&
            (identical(other.id, _this.id) || other.id == _this.id) &&
            (identical(other.text, _this.text) || other.text == _this.text) &&
            (identical(other.timestamp, _this.timestamp) ||
                other.timestamp == _this.timestamp) &&
            (identical(other.audioStartTime, _this.audioStartTime) ||
                other.audioStartTime == _this.audioStartTime) &&
            (identical(other.audioEndTime, _this.audioEndTime) ||
                other.audioEndTime == _this.audioEndTime) &&
            (identical(other.duration, _this.duration) ||
                other.duration == _this.duration));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as MeetingTranscript;
    return Object.hash(
      runtimeType,
      _this.id,
      _this.text,
      _this.timestamp,
      _this.audioStartTime,
      _this.audioEndTime,
      _this.duration,
    );
  }

  @override
  String toString() {
    final _this = this as MeetingTranscript;
    return 'MeetingTranscript(id: ${_this.id}, text: ${_this.text}, timestamp: ${_this.timestamp}, audioStartTime: ${_this.audioStartTime}, audioEndTime: ${_this.audioEndTime}, duration: ${_this.duration})';
  }
}

/// @nodoc
abstract mixin class $MeetingTranscriptCopyWith<$Res> {
  factory $MeetingTranscriptCopyWith(
    MeetingTranscript value,
    $Res Function(MeetingTranscript) _then,
  ) = _$MeetingTranscriptCopyWithImpl;
  @useResult
  $Res call({
    String id,
    String text,
    String timestamp,
    @JsonKey(name: 'audio_start_time') double? audioStartTime,
    @JsonKey(name: 'audio_end_time') double? audioEndTime,
    double? duration,
  });
}

/// @nodoc
class _$MeetingTranscriptCopyWithImpl<$Res>
    implements $MeetingTranscriptCopyWith<$Res> {
  _$MeetingTranscriptCopyWithImpl(this._self, this._then);

  final MeetingTranscript _self;
  final $Res Function(MeetingTranscript) _then;

  /// Create a copy of MeetingTranscript
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? text = null,
    Object? timestamp = null,
    Object? audioStartTime = freezed,
    Object? audioEndTime = freezed,
    Object? duration = freezed,
  }) {
    return _then(
      MeetingTranscript(
        id: null == id
            ? _self.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        text: null == text
            ? _self.text
            : text // ignore: cast_nullable_to_non_nullable
                  as String,
        timestamp: null == timestamp
            ? _self.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                  as String,
        audioStartTime: freezed == audioStartTime
            ? _self.audioStartTime
            : audioStartTime // ignore: cast_nullable_to_non_nullable
                  as double?,
        audioEndTime: freezed == audioEndTime
            ? _self.audioEndTime
            : audioEndTime // ignore: cast_nullable_to_non_nullable
                  as double?,
        duration: freezed == duration
            ? _self.duration
            : duration // ignore: cast_nullable_to_non_nullable
                  as double?,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [MeetingTranscript].
extension MeetingTranscriptPatterns on MeetingTranscript {
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
    TResult Function(_MeetingTranscript value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _MeetingTranscript() when $default != null:
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
    TResult Function(_MeetingTranscript value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MeetingTranscript():
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
    TResult? Function(_MeetingTranscript value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MeetingTranscript() when $default != null:
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
      String text,
      String timestamp,
      @JsonKey(name: 'audio_start_time') double? audioStartTime,
      @JsonKey(name: 'audio_end_time') double? audioEndTime,
      double? duration,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _MeetingTranscript() when $default != null:
        return $default(
          _that.id,
          _that.text,
          _that.timestamp,
          _that.audioStartTime,
          _that.audioEndTime,
          _that.duration,
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
      String text,
      String timestamp,
      @JsonKey(name: 'audio_start_time') double? audioStartTime,
      @JsonKey(name: 'audio_end_time') double? audioEndTime,
      double? duration,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MeetingTranscript():
        return $default(
          _that.id,
          _that.text,
          _that.timestamp,
          _that.audioStartTime,
          _that.audioEndTime,
          _that.duration,
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
      String text,
      String timestamp,
      @JsonKey(name: 'audio_start_time') double? audioStartTime,
      @JsonKey(name: 'audio_end_time') double? audioEndTime,
      double? duration,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MeetingTranscript() when $default != null:
        return $default(
          _that.id,
          _that.text,
          _that.timestamp,
          _that.audioStartTime,
          _that.audioEndTime,
          _that.duration,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _MeetingTranscript implements MeetingTranscript {
  const _MeetingTranscript({
    required this.id,
    required this.text,
    required this.timestamp,
    @JsonKey(name: 'audio_start_time') this.audioStartTime,
    @JsonKey(name: 'audio_end_time') this.audioEndTime,
    this.duration,
  });
  factory _MeetingTranscript.fromJson(Map<String, dynamic> json) =>
      _$MeetingTranscriptFromJson(json);

  @override
  final String id;
  @override
  final String text;
  @override
  final String timestamp;

  /// Seconds from the start of the recording.
  @override
  @JsonKey(name: 'audio_start_time')
  final double? audioStartTime;
  @override
  @JsonKey(name: 'audio_end_time')
  final double? audioEndTime;
  @override
  final double? duration;

  /// Create a copy of MeetingTranscript
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$MeetingTranscriptCopyWith<_MeetingTranscript> get copyWith =>
      __$MeetingTranscriptCopyWithImpl<_MeetingTranscript>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$MeetingTranscriptToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _MeetingTranscript &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.audioStartTime, audioStartTime) ||
                other.audioStartTime == audioStartTime) &&
            (identical(other.audioEndTime, audioEndTime) ||
                other.audioEndTime == audioEndTime) &&
            (identical(other.duration, duration) ||
                other.duration == duration));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(
      runtimeType,
      id,
      text,
      timestamp,
      audioStartTime,
      audioEndTime,
      duration,
    );
  }

  @override
  String toString() {
    return 'MeetingTranscript(id: $id, text: $text, timestamp: $timestamp, audioStartTime: $audioStartTime, audioEndTime: $audioEndTime, duration: $duration)';
  }
}

/// @nodoc
abstract mixin class _$MeetingTranscriptCopyWith<$Res>
    implements $MeetingTranscriptCopyWith<$Res> {
  factory _$MeetingTranscriptCopyWith(
    _MeetingTranscript value,
    $Res Function(_MeetingTranscript) _then,
  ) = __$MeetingTranscriptCopyWithImpl;
  @override
  @useResult
  $Res call({
    String id,
    String text,
    String timestamp,
    @JsonKey(name: 'audio_start_time') double? audioStartTime,
    @JsonKey(name: 'audio_end_time') double? audioEndTime,
    double? duration,
  });
}

/// @nodoc
class __$MeetingTranscriptCopyWithImpl<$Res>
    implements _$MeetingTranscriptCopyWith<$Res> {
  __$MeetingTranscriptCopyWithImpl(this._self, this._then);

  final _MeetingTranscript _self;
  final $Res Function(_MeetingTranscript) _then;

  /// Create a copy of MeetingTranscript
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? text = null,
    Object? timestamp = null,
    Object? audioStartTime = freezed,
    Object? audioEndTime = freezed,
    Object? duration = freezed,
  }) {
    return _then(
      _MeetingTranscript(
        id: null == id
            ? _self.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        text: null == text
            ? _self.text
            : text // ignore: cast_nullable_to_non_nullable
                  as String,
        timestamp: null == timestamp
            ? _self.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                  as String,
        audioStartTime: freezed == audioStartTime
            ? _self.audioStartTime
            : audioStartTime // ignore: cast_nullable_to_non_nullable
                  as double?,
        audioEndTime: freezed == audioEndTime
            ? _self.audioEndTime
            : audioEndTime // ignore: cast_nullable_to_non_nullable
                  as double?,
        duration: freezed == duration
            ? _self.duration
            : duration // ignore: cast_nullable_to_non_nullable
                  as double?,
      ),
    );
  }
}

/// @nodoc
mixin _$MeetingDetails {
  String get id;
  String get title;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;
  List<MeetingTranscript> get transcripts;

  /// Create a copy of MeetingDetails
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $MeetingDetailsCopyWith<MeetingDetails> get copyWith =>
      _$MeetingDetailsCopyWithImpl<MeetingDetails>(
        this as MeetingDetails,
        _$identity,
      );

  /// Serializes this MeetingDetails to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as MeetingDetails;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MeetingDetails &&
            (identical(other.id, _this.id) || other.id == _this.id) &&
            (identical(other.title, _this.title) ||
                other.title == _this.title) &&
            (identical(other.createdAt, _this.createdAt) ||
                other.createdAt == _this.createdAt) &&
            (identical(other.updatedAt, _this.updatedAt) ||
                other.updatedAt == _this.updatedAt) &&
            const DeepCollectionEquality().equals(
              other.transcripts,
              _this.transcripts,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as MeetingDetails;
    return Object.hash(
      runtimeType,
      _this.id,
      _this.title,
      _this.createdAt,
      _this.updatedAt,
      const DeepCollectionEquality().hash(_this.transcripts),
    );
  }

  @override
  String toString() {
    final _this = this as MeetingDetails;
    return 'MeetingDetails(id: ${_this.id}, title: ${_this.title}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt}, transcripts: ${_this.transcripts})';
  }
}

/// @nodoc
abstract mixin class $MeetingDetailsCopyWith<$Res> {
  factory $MeetingDetailsCopyWith(
    MeetingDetails value,
    $Res Function(MeetingDetails) _then,
  ) = _$MeetingDetailsCopyWithImpl;
  @useResult
  $Res call({
    String id,
    String title,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    List<MeetingTranscript> transcripts,
  });
}

/// @nodoc
class _$MeetingDetailsCopyWithImpl<$Res>
    implements $MeetingDetailsCopyWith<$Res> {
  _$MeetingDetailsCopyWithImpl(this._self, this._then);

  final MeetingDetails _self;
  final $Res Function(MeetingDetails) _then;

  /// Create a copy of MeetingDetails
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? transcripts = null,
  }) {
    return _then(
      MeetingDetails(
        id: null == id
            ? _self.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _self.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        createdAt: freezed == createdAt
            ? _self.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        updatedAt: freezed == updatedAt
            ? _self.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        transcripts: null == transcripts
            ? _self.transcripts
            : transcripts // ignore: cast_nullable_to_non_nullable
                  as List<MeetingTranscript>,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [MeetingDetails].
extension MeetingDetailsPatterns on MeetingDetails {
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
    TResult Function(_MeetingDetails value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _MeetingDetails() when $default != null:
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
    TResult Function(_MeetingDetails value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MeetingDetails():
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
    TResult? Function(_MeetingDetails value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MeetingDetails() when $default != null:
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
      String title,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt,
      List<MeetingTranscript> transcripts,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _MeetingDetails() when $default != null:
        return $default(
          _that.id,
          _that.title,
          _that.createdAt,
          _that.updatedAt,
          _that.transcripts,
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
      String title,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt,
      List<MeetingTranscript> transcripts,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MeetingDetails():
        return $default(
          _that.id,
          _that.title,
          _that.createdAt,
          _that.updatedAt,
          _that.transcripts,
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
      String title,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt,
      List<MeetingTranscript> transcripts,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MeetingDetails() when $default != null:
        return $default(
          _that.id,
          _that.title,
          _that.createdAt,
          _that.updatedAt,
          _that.transcripts,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _MeetingDetails implements MeetingDetails {
  const _MeetingDetails({
    required this.id,
    required this.title,
    @JsonKey(name: 'created_at') this.createdAt,
    @JsonKey(name: 'updated_at') this.updatedAt,
    List<MeetingTranscript> transcripts = const <MeetingTranscript>[],
  }) : _transcripts = transcripts;
  factory _MeetingDetails.fromJson(Map<String, dynamic> json) =>
      _$MeetingDetailsFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  final List<MeetingTranscript> _transcripts;
  @override
  @JsonKey()
  List<MeetingTranscript> get transcripts {
    if (_transcripts is EqualUnmodifiableListView) return _transcripts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_transcripts);
  }

  /// Create a copy of MeetingDetails
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$MeetingDetailsCopyWith<_MeetingDetails> get copyWith =>
      __$MeetingDetailsCopyWithImpl<_MeetingDetails>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$MeetingDetailsToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _MeetingDetails &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            const DeepCollectionEquality().equals(
              other.transcripts,
              _transcripts,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(
      runtimeType,
      id,
      title,
      createdAt,
      updatedAt,
      const DeepCollectionEquality().hash(_transcripts),
    );
  }

  @override
  String toString() {
    return 'MeetingDetails(id: $id, title: $title, createdAt: $createdAt, updatedAt: $updatedAt, transcripts: $transcripts)';
  }
}

/// @nodoc
abstract mixin class _$MeetingDetailsCopyWith<$Res>
    implements $MeetingDetailsCopyWith<$Res> {
  factory _$MeetingDetailsCopyWith(
    _MeetingDetails value,
    $Res Function(_MeetingDetails) _then,
  ) = __$MeetingDetailsCopyWithImpl;
  @override
  @useResult
  $Res call({
    String id,
    String title,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    List<MeetingTranscript> transcripts,
  });
}

/// @nodoc
class __$MeetingDetailsCopyWithImpl<$Res>
    implements _$MeetingDetailsCopyWith<$Res> {
  __$MeetingDetailsCopyWithImpl(this._self, this._then);

  final _MeetingDetails _self;
  final $Res Function(_MeetingDetails) _then;

  /// Create a copy of MeetingDetails
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? transcripts = null,
  }) {
    return _then(
      _MeetingDetails(
        id: null == id
            ? _self.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _self.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        createdAt: freezed == createdAt
            ? _self.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        updatedAt: freezed == updatedAt
            ? _self.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        transcripts: null == transcripts
            ? _self._transcripts
            : transcripts // ignore: cast_nullable_to_non_nullable
                  as List<MeetingTranscript>,
      ),
    );
  }
}

/// @nodoc
mixin _$PaginatedTranscripts {
  List<MeetingTranscript> get transcripts;
  @JsonKey(name: 'total_count')
  int get totalCount;
  @JsonKey(name: 'has_more')
  bool get hasMore;

  /// Create a copy of PaginatedTranscripts
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PaginatedTranscriptsCopyWith<PaginatedTranscripts> get copyWith =>
      _$PaginatedTranscriptsCopyWithImpl<PaginatedTranscripts>(
        this as PaginatedTranscripts,
        _$identity,
      );

  /// Serializes this PaginatedTranscripts to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as PaginatedTranscripts;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PaginatedTranscripts &&
            const DeepCollectionEquality().equals(
              other.transcripts,
              _this.transcripts,
            ) &&
            (identical(other.totalCount, _this.totalCount) ||
                other.totalCount == _this.totalCount) &&
            (identical(other.hasMore, _this.hasMore) ||
                other.hasMore == _this.hasMore));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as PaginatedTranscripts;
    return Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_this.transcripts),
      _this.totalCount,
      _this.hasMore,
    );
  }

  @override
  String toString() {
    final _this = this as PaginatedTranscripts;
    return 'PaginatedTranscripts(transcripts: ${_this.transcripts}, totalCount: ${_this.totalCount}, hasMore: ${_this.hasMore})';
  }
}

/// @nodoc
abstract mixin class $PaginatedTranscriptsCopyWith<$Res> {
  factory $PaginatedTranscriptsCopyWith(
    PaginatedTranscripts value,
    $Res Function(PaginatedTranscripts) _then,
  ) = _$PaginatedTranscriptsCopyWithImpl;
  @useResult
  $Res call({
    List<MeetingTranscript> transcripts,
    @JsonKey(name: 'total_count') int totalCount,
    @JsonKey(name: 'has_more') bool hasMore,
  });
}

/// @nodoc
class _$PaginatedTranscriptsCopyWithImpl<$Res>
    implements $PaginatedTranscriptsCopyWith<$Res> {
  _$PaginatedTranscriptsCopyWithImpl(this._self, this._then);

  final PaginatedTranscripts _self;
  final $Res Function(PaginatedTranscripts) _then;

  /// Create a copy of PaginatedTranscripts
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? transcripts = null,
    Object? totalCount = null,
    Object? hasMore = null,
  }) {
    return _then(
      PaginatedTranscripts(
        transcripts: null == transcripts
            ? _self.transcripts
            : transcripts // ignore: cast_nullable_to_non_nullable
                  as List<MeetingTranscript>,
        totalCount: null == totalCount
            ? _self.totalCount
            : totalCount // ignore: cast_nullable_to_non_nullable
                  as int,
        hasMore: null == hasMore
            ? _self.hasMore
            : hasMore // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [PaginatedTranscripts].
extension PaginatedTranscriptsPatterns on PaginatedTranscripts {
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
    TResult Function(_PaginatedTranscripts value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PaginatedTranscripts() when $default != null:
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
    TResult Function(_PaginatedTranscripts value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PaginatedTranscripts():
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
    TResult? Function(_PaginatedTranscripts value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PaginatedTranscripts() when $default != null:
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
      List<MeetingTranscript> transcripts,
      @JsonKey(name: 'total_count') int totalCount,
      @JsonKey(name: 'has_more') bool hasMore,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PaginatedTranscripts() when $default != null:
        return $default(_that.transcripts, _that.totalCount, _that.hasMore);
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
      List<MeetingTranscript> transcripts,
      @JsonKey(name: 'total_count') int totalCount,
      @JsonKey(name: 'has_more') bool hasMore,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PaginatedTranscripts():
        return $default(_that.transcripts, _that.totalCount, _that.hasMore);
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
      List<MeetingTranscript> transcripts,
      @JsonKey(name: 'total_count') int totalCount,
      @JsonKey(name: 'has_more') bool hasMore,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PaginatedTranscripts() when $default != null:
        return $default(_that.transcripts, _that.totalCount, _that.hasMore);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _PaginatedTranscripts implements PaginatedTranscripts {
  const _PaginatedTranscripts({
    required List<MeetingTranscript> transcripts,
    @JsonKey(name: 'total_count') required this.totalCount,
    @JsonKey(name: 'has_more') required this.hasMore,
  }) : _transcripts = transcripts;
  factory _PaginatedTranscripts.fromJson(Map<String, dynamic> json) =>
      _$PaginatedTranscriptsFromJson(json);

  final List<MeetingTranscript> _transcripts;
  @override
  List<MeetingTranscript> get transcripts {
    if (_transcripts is EqualUnmodifiableListView) return _transcripts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_transcripts);
  }

  @override
  @JsonKey(name: 'total_count')
  final int totalCount;
  @override
  @JsonKey(name: 'has_more')
  final bool hasMore;

  /// Create a copy of PaginatedTranscripts
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PaginatedTranscriptsCopyWith<_PaginatedTranscripts> get copyWith =>
      __$PaginatedTranscriptsCopyWithImpl<_PaginatedTranscripts>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$PaginatedTranscriptsToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PaginatedTranscripts &&
            const DeepCollectionEquality().equals(
              other.transcripts,
              _transcripts,
            ) &&
            (identical(other.totalCount, totalCount) ||
                other.totalCount == totalCount) &&
            (identical(other.hasMore, hasMore) || other.hasMore == hasMore));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_transcripts),
      totalCount,
      hasMore,
    );
  }

  @override
  String toString() {
    return 'PaginatedTranscripts(transcripts: $transcripts, totalCount: $totalCount, hasMore: $hasMore)';
  }
}

/// @nodoc
abstract mixin class _$PaginatedTranscriptsCopyWith<$Res>
    implements $PaginatedTranscriptsCopyWith<$Res> {
  factory _$PaginatedTranscriptsCopyWith(
    _PaginatedTranscripts value,
    $Res Function(_PaginatedTranscripts) _then,
  ) = __$PaginatedTranscriptsCopyWithImpl;
  @override
  @useResult
  $Res call({
    List<MeetingTranscript> transcripts,
    @JsonKey(name: 'total_count') int totalCount,
    @JsonKey(name: 'has_more') bool hasMore,
  });
}

/// @nodoc
class __$PaginatedTranscriptsCopyWithImpl<$Res>
    implements _$PaginatedTranscriptsCopyWith<$Res> {
  __$PaginatedTranscriptsCopyWithImpl(this._self, this._then);

  final _PaginatedTranscripts _self;
  final $Res Function(_PaginatedTranscripts) _then;

  /// Create a copy of PaginatedTranscripts
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? transcripts = null,
    Object? totalCount = null,
    Object? hasMore = null,
  }) {
    return _then(
      _PaginatedTranscripts(
        transcripts: null == transcripts
            ? _self._transcripts
            : transcripts // ignore: cast_nullable_to_non_nullable
                  as List<MeetingTranscript>,
        totalCount: null == totalCount
            ? _self.totalCount
            : totalCount // ignore: cast_nullable_to_non_nullable
                  as int,
        hasMore: null == hasMore
            ? _self.hasMore
            : hasMore // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
mixin _$TranscriptSearchResult {
  String get id;
  String get title;
  String get matchContext;
  String? get timestamp;

  /// Create a copy of TranscriptSearchResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TranscriptSearchResultCopyWith<TranscriptSearchResult> get copyWith =>
      _$TranscriptSearchResultCopyWithImpl<TranscriptSearchResult>(
        this as TranscriptSearchResult,
        _$identity,
      );

  /// Serializes this TranscriptSearchResult to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as TranscriptSearchResult;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TranscriptSearchResult &&
            (identical(other.id, _this.id) || other.id == _this.id) &&
            (identical(other.title, _this.title) ||
                other.title == _this.title) &&
            (identical(other.matchContext, _this.matchContext) ||
                other.matchContext == _this.matchContext) &&
            (identical(other.timestamp, _this.timestamp) ||
                other.timestamp == _this.timestamp));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as TranscriptSearchResult;
    return Object.hash(
      runtimeType,
      _this.id,
      _this.title,
      _this.matchContext,
      _this.timestamp,
    );
  }

  @override
  String toString() {
    final _this = this as TranscriptSearchResult;
    return 'TranscriptSearchResult(id: ${_this.id}, title: ${_this.title}, matchContext: ${_this.matchContext}, timestamp: ${_this.timestamp})';
  }
}

/// @nodoc
abstract mixin class $TranscriptSearchResultCopyWith<$Res> {
  factory $TranscriptSearchResultCopyWith(
    TranscriptSearchResult value,
    $Res Function(TranscriptSearchResult) _then,
  ) = _$TranscriptSearchResultCopyWithImpl;
  @useResult
  $Res call({String id, String title, String matchContext, String? timestamp});
}

/// @nodoc
class _$TranscriptSearchResultCopyWithImpl<$Res>
    implements $TranscriptSearchResultCopyWith<$Res> {
  _$TranscriptSearchResultCopyWithImpl(this._self, this._then);

  final TranscriptSearchResult _self;
  final $Res Function(TranscriptSearchResult) _then;

  /// Create a copy of TranscriptSearchResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? matchContext = null,
    Object? timestamp = freezed,
  }) {
    return _then(
      TranscriptSearchResult(
        id: null == id
            ? _self.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _self.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        matchContext: null == matchContext
            ? _self.matchContext
            : matchContext // ignore: cast_nullable_to_non_nullable
                  as String,
        timestamp: freezed == timestamp
            ? _self.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [TranscriptSearchResult].
extension TranscriptSearchResultPatterns on TranscriptSearchResult {
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
    TResult Function(_TranscriptSearchResult value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TranscriptSearchResult() when $default != null:
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
    TResult Function(_TranscriptSearchResult value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TranscriptSearchResult():
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
    TResult? Function(_TranscriptSearchResult value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TranscriptSearchResult() when $default != null:
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
      String title,
      String matchContext,
      String? timestamp,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TranscriptSearchResult() when $default != null:
        return $default(
          _that.id,
          _that.title,
          _that.matchContext,
          _that.timestamp,
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
      String title,
      String matchContext,
      String? timestamp,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TranscriptSearchResult():
        return $default(
          _that.id,
          _that.title,
          _that.matchContext,
          _that.timestamp,
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
      String title,
      String matchContext,
      String? timestamp,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TranscriptSearchResult() when $default != null:
        return $default(
          _that.id,
          _that.title,
          _that.matchContext,
          _that.timestamp,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _TranscriptSearchResult implements TranscriptSearchResult {
  const _TranscriptSearchResult({
    required this.id,
    required this.title,
    required this.matchContext,
    this.timestamp,
  });
  factory _TranscriptSearchResult.fromJson(Map<String, dynamic> json) =>
      _$TranscriptSearchResultFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final String matchContext;
  @override
  final String? timestamp;

  /// Create a copy of TranscriptSearchResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$TranscriptSearchResultCopyWith<_TranscriptSearchResult> get copyWith =>
      __$TranscriptSearchResultCopyWithImpl<_TranscriptSearchResult>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$TranscriptSearchResultToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _TranscriptSearchResult &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.matchContext, matchContext) ||
                other.matchContext == matchContext) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(runtimeType, id, title, matchContext, timestamp);
  }

  @override
  String toString() {
    return 'TranscriptSearchResult(id: $id, title: $title, matchContext: $matchContext, timestamp: $timestamp)';
  }
}

/// @nodoc
abstract mixin class _$TranscriptSearchResultCopyWith<$Res>
    implements $TranscriptSearchResultCopyWith<$Res> {
  factory _$TranscriptSearchResultCopyWith(
    _TranscriptSearchResult value,
    $Res Function(_TranscriptSearchResult) _then,
  ) = __$TranscriptSearchResultCopyWithImpl;
  @override
  @useResult
  $Res call({String id, String title, String matchContext, String? timestamp});
}

/// @nodoc
class __$TranscriptSearchResultCopyWithImpl<$Res>
    implements _$TranscriptSearchResultCopyWith<$Res> {
  __$TranscriptSearchResultCopyWithImpl(this._self, this._then);

  final _TranscriptSearchResult _self;
  final $Res Function(_TranscriptSearchResult) _then;

  /// Create a copy of TranscriptSearchResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? matchContext = null,
    Object? timestamp = freezed,
  }) {
    return _then(
      _TranscriptSearchResult(
        id: null == id
            ? _self.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _self.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        matchContext: null == matchContext
            ? _self.matchContext
            : matchContext // ignore: cast_nullable_to_non_nullable
                  as String,
        timestamp: freezed == timestamp
            ? _self.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
mixin _$SegmentResult {
  String? get id;
  String get text;
  double? get confidence;
  int get seq;

  /// Create a copy of SegmentResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SegmentResultCopyWith<SegmentResult> get copyWith =>
      _$SegmentResultCopyWithImpl<SegmentResult>(
        this as SegmentResult,
        _$identity,
      );

  /// Serializes this SegmentResult to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as SegmentResult;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SegmentResult &&
            (identical(other.id, _this.id) || other.id == _this.id) &&
            (identical(other.text, _this.text) || other.text == _this.text) &&
            (identical(other.confidence, _this.confidence) ||
                other.confidence == _this.confidence) &&
            (identical(other.seq, _this.seq) || other.seq == _this.seq));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as SegmentResult;
    return Object.hash(
      runtimeType,
      _this.id,
      _this.text,
      _this.confidence,
      _this.seq,
    );
  }

  @override
  String toString() {
    final _this = this as SegmentResult;
    return 'SegmentResult(id: ${_this.id}, text: ${_this.text}, confidence: ${_this.confidence}, seq: ${_this.seq})';
  }
}

/// @nodoc
abstract mixin class $SegmentResultCopyWith<$Res> {
  factory $SegmentResultCopyWith(
    SegmentResult value,
    $Res Function(SegmentResult) _then,
  ) = _$SegmentResultCopyWithImpl;
  @useResult
  $Res call({String? id, String text, double? confidence, int seq});
}

/// @nodoc
class _$SegmentResultCopyWithImpl<$Res>
    implements $SegmentResultCopyWith<$Res> {
  _$SegmentResultCopyWithImpl(this._self, this._then);

  final SegmentResult _self;
  final $Res Function(SegmentResult) _then;

  /// Create a copy of SegmentResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? text = null,
    Object? confidence = freezed,
    Object? seq = null,
  }) {
    return _then(
      SegmentResult(
        id: freezed == id
            ? _self.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String?,
        text: null == text
            ? _self.text
            : text // ignore: cast_nullable_to_non_nullable
                  as String,
        confidence: freezed == confidence
            ? _self.confidence
            : confidence // ignore: cast_nullable_to_non_nullable
                  as double?,
        seq: null == seq
            ? _self.seq
            : seq // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [SegmentResult].
extension SegmentResultPatterns on SegmentResult {
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
    TResult Function(_SegmentResult value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SegmentResult() when $default != null:
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
    TResult Function(_SegmentResult value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SegmentResult():
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
    TResult? Function(_SegmentResult value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SegmentResult() when $default != null:
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
    TResult Function(String? id, String text, double? confidence, int seq)?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SegmentResult() when $default != null:
        return $default(_that.id, _that.text, _that.confidence, _that.seq);
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
    TResult Function(String? id, String text, double? confidence, int seq)
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SegmentResult():
        return $default(_that.id, _that.text, _that.confidence, _that.seq);
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
    TResult? Function(String? id, String text, double? confidence, int seq)?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SegmentResult() when $default != null:
        return $default(_that.id, _that.text, _that.confidence, _that.seq);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _SegmentResult implements SegmentResult {
  const _SegmentResult({
    this.id,
    required this.text,
    this.confidence,
    required this.seq,
  });
  factory _SegmentResult.fromJson(Map<String, dynamic> json) =>
      _$SegmentResultFromJson(json);

  @override
  final String? id;
  @override
  final String text;
  @override
  final double? confidence;
  @override
  final int seq;

  /// Create a copy of SegmentResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$SegmentResultCopyWith<_SegmentResult> get copyWith =>
      __$SegmentResultCopyWithImpl<_SegmentResult>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$SegmentResultToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _SegmentResult &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.confidence, confidence) ||
                other.confidence == confidence) &&
            (identical(other.seq, seq) || other.seq == seq));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(runtimeType, id, text, confidence, seq);
  }

  @override
  String toString() {
    return 'SegmentResult(id: $id, text: $text, confidence: $confidence, seq: $seq)';
  }
}

/// @nodoc
abstract mixin class _$SegmentResultCopyWith<$Res>
    implements $SegmentResultCopyWith<$Res> {
  factory _$SegmentResultCopyWith(
    _SegmentResult value,
    $Res Function(_SegmentResult) _then,
  ) = __$SegmentResultCopyWithImpl;
  @override
  @useResult
  $Res call({String? id, String text, double? confidence, int seq});
}

/// @nodoc
class __$SegmentResultCopyWithImpl<$Res>
    implements _$SegmentResultCopyWith<$Res> {
  __$SegmentResultCopyWithImpl(this._self, this._then);

  final _SegmentResult _self;
  final $Res Function(_SegmentResult) _then;

  /// Create a copy of SegmentResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = freezed,
    Object? text = null,
    Object? confidence = freezed,
    Object? seq = null,
  }) {
    return _then(
      _SegmentResult(
        id: freezed == id
            ? _self.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String?,
        text: null == text
            ? _self.text
            : text // ignore: cast_nullable_to_non_nullable
                  as String,
        confidence: freezed == confidence
            ? _self.confidence
            : confidence // ignore: cast_nullable_to_non_nullable
                  as double?,
        seq: null == seq
            ? _self.seq
            : seq // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
mixin _$AudioUploadResult {
  int get size;
  double? get duration;

  /// Create a copy of AudioUploadResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $AudioUploadResultCopyWith<AudioUploadResult> get copyWith =>
      _$AudioUploadResultCopyWithImpl<AudioUploadResult>(
        this as AudioUploadResult,
        _$identity,
      );

  /// Serializes this AudioUploadResult to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as AudioUploadResult;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AudioUploadResult &&
            (identical(other.size, _this.size) || other.size == _this.size) &&
            (identical(other.duration, _this.duration) ||
                other.duration == _this.duration));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as AudioUploadResult;
    return Object.hash(runtimeType, _this.size, _this.duration);
  }

  @override
  String toString() {
    final _this = this as AudioUploadResult;
    return 'AudioUploadResult(size: ${_this.size}, duration: ${_this.duration})';
  }
}

/// @nodoc
abstract mixin class $AudioUploadResultCopyWith<$Res> {
  factory $AudioUploadResultCopyWith(
    AudioUploadResult value,
    $Res Function(AudioUploadResult) _then,
  ) = _$AudioUploadResultCopyWithImpl;
  @useResult
  $Res call({int size, double? duration});
}

/// @nodoc
class _$AudioUploadResultCopyWithImpl<$Res>
    implements $AudioUploadResultCopyWith<$Res> {
  _$AudioUploadResultCopyWithImpl(this._self, this._then);

  final AudioUploadResult _self;
  final $Res Function(AudioUploadResult) _then;

  /// Create a copy of AudioUploadResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? size = null, Object? duration = freezed}) {
    return _then(
      AudioUploadResult(
        size: null == size
            ? _self.size
            : size // ignore: cast_nullable_to_non_nullable
                  as int,
        duration: freezed == duration
            ? _self.duration
            : duration // ignore: cast_nullable_to_non_nullable
                  as double?,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [AudioUploadResult].
extension AudioUploadResultPatterns on AudioUploadResult {
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
    TResult Function(_AudioUploadResult value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AudioUploadResult() when $default != null:
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
    TResult Function(_AudioUploadResult value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AudioUploadResult():
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
    TResult? Function(_AudioUploadResult value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AudioUploadResult() when $default != null:
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
    TResult Function(int size, double? duration)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AudioUploadResult() when $default != null:
        return $default(_that.size, _that.duration);
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
    TResult Function(int size, double? duration) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AudioUploadResult():
        return $default(_that.size, _that.duration);
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
    TResult? Function(int size, double? duration)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AudioUploadResult() when $default != null:
        return $default(_that.size, _that.duration);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _AudioUploadResult implements AudioUploadResult {
  const _AudioUploadResult({required this.size, this.duration});
  factory _AudioUploadResult.fromJson(Map<String, dynamic> json) =>
      _$AudioUploadResultFromJson(json);

  @override
  final int size;
  @override
  final double? duration;

  /// Create a copy of AudioUploadResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$AudioUploadResultCopyWith<_AudioUploadResult> get copyWith =>
      __$AudioUploadResultCopyWithImpl<_AudioUploadResult>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$AudioUploadResultToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _AudioUploadResult &&
            (identical(other.size, size) || other.size == size) &&
            (identical(other.duration, duration) ||
                other.duration == duration));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(runtimeType, size, duration);
  }

  @override
  String toString() {
    return 'AudioUploadResult(size: $size, duration: $duration)';
  }
}

/// @nodoc
abstract mixin class _$AudioUploadResultCopyWith<$Res>
    implements $AudioUploadResultCopyWith<$Res> {
  factory _$AudioUploadResultCopyWith(
    _AudioUploadResult value,
    $Res Function(_AudioUploadResult) _then,
  ) = __$AudioUploadResultCopyWithImpl;
  @override
  @useResult
  $Res call({int size, double? duration});
}

/// @nodoc
class __$AudioUploadResultCopyWithImpl<$Res>
    implements _$AudioUploadResultCopyWith<$Res> {
  __$AudioUploadResultCopyWithImpl(this._self, this._then);

  final _AudioUploadResult _self;
  final $Res Function(_AudioUploadResult) _then;

  /// Create a copy of AudioUploadResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({Object? size = null, Object? duration = freezed}) {
    return _then(
      _AudioUploadResult(
        size: null == size
            ? _self.size
            : size // ignore: cast_nullable_to_non_nullable
                  as int,
        duration: freezed == duration
            ? _self.duration
            : duration // ignore: cast_nullable_to_non_nullable
                  as double?,
      ),
    );
  }
}

/// @nodoc
mixin _$MeetingNotes {
  @JsonKey(name: 'meeting_id')
  String get meetingId;
  @JsonKey(name: 'notes_markdown')
  String? get notesMarkdown;
  @JsonKey(name: 'notes_json')
  String? get notesJson;
  @JsonKey(name: 'updated_at')
  String? get updatedAt;

  /// Create a copy of MeetingNotes
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $MeetingNotesCopyWith<MeetingNotes> get copyWith =>
      _$MeetingNotesCopyWithImpl<MeetingNotes>(
        this as MeetingNotes,
        _$identity,
      );

  /// Serializes this MeetingNotes to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as MeetingNotes;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MeetingNotes &&
            (identical(other.meetingId, _this.meetingId) ||
                other.meetingId == _this.meetingId) &&
            (identical(other.notesMarkdown, _this.notesMarkdown) ||
                other.notesMarkdown == _this.notesMarkdown) &&
            (identical(other.notesJson, _this.notesJson) ||
                other.notesJson == _this.notesJson) &&
            (identical(other.updatedAt, _this.updatedAt) ||
                other.updatedAt == _this.updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as MeetingNotes;
    return Object.hash(
      runtimeType,
      _this.meetingId,
      _this.notesMarkdown,
      _this.notesJson,
      _this.updatedAt,
    );
  }

  @override
  String toString() {
    final _this = this as MeetingNotes;
    return 'MeetingNotes(meetingId: ${_this.meetingId}, notesMarkdown: ${_this.notesMarkdown}, notesJson: ${_this.notesJson}, updatedAt: ${_this.updatedAt})';
  }
}

/// @nodoc
abstract mixin class $MeetingNotesCopyWith<$Res> {
  factory $MeetingNotesCopyWith(
    MeetingNotes value,
    $Res Function(MeetingNotes) _then,
  ) = _$MeetingNotesCopyWithImpl;
  @useResult
  $Res call({
    @JsonKey(name: 'meeting_id') String meetingId,
    @JsonKey(name: 'notes_markdown') String? notesMarkdown,
    @JsonKey(name: 'notes_json') String? notesJson,
    @JsonKey(name: 'updated_at') String? updatedAt,
  });
}

/// @nodoc
class _$MeetingNotesCopyWithImpl<$Res> implements $MeetingNotesCopyWith<$Res> {
  _$MeetingNotesCopyWithImpl(this._self, this._then);

  final MeetingNotes _self;
  final $Res Function(MeetingNotes) _then;

  /// Create a copy of MeetingNotes
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? meetingId = null,
    Object? notesMarkdown = freezed,
    Object? notesJson = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      MeetingNotes(
        meetingId: null == meetingId
            ? _self.meetingId
            : meetingId // ignore: cast_nullable_to_non_nullable
                  as String,
        notesMarkdown: freezed == notesMarkdown
            ? _self.notesMarkdown
            : notesMarkdown // ignore: cast_nullable_to_non_nullable
                  as String?,
        notesJson: freezed == notesJson
            ? _self.notesJson
            : notesJson // ignore: cast_nullable_to_non_nullable
                  as String?,
        updatedAt: freezed == updatedAt
            ? _self.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [MeetingNotes].
extension MeetingNotesPatterns on MeetingNotes {
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
    TResult Function(_MeetingNotes value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _MeetingNotes() when $default != null:
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
    TResult Function(_MeetingNotes value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MeetingNotes():
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
    TResult? Function(_MeetingNotes value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MeetingNotes() when $default != null:
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
      @JsonKey(name: 'meeting_id') String meetingId,
      @JsonKey(name: 'notes_markdown') String? notesMarkdown,
      @JsonKey(name: 'notes_json') String? notesJson,
      @JsonKey(name: 'updated_at') String? updatedAt,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _MeetingNotes() when $default != null:
        return $default(
          _that.meetingId,
          _that.notesMarkdown,
          _that.notesJson,
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
      @JsonKey(name: 'meeting_id') String meetingId,
      @JsonKey(name: 'notes_markdown') String? notesMarkdown,
      @JsonKey(name: 'notes_json') String? notesJson,
      @JsonKey(name: 'updated_at') String? updatedAt,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MeetingNotes():
        return $default(
          _that.meetingId,
          _that.notesMarkdown,
          _that.notesJson,
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
      @JsonKey(name: 'meeting_id') String meetingId,
      @JsonKey(name: 'notes_markdown') String? notesMarkdown,
      @JsonKey(name: 'notes_json') String? notesJson,
      @JsonKey(name: 'updated_at') String? updatedAt,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MeetingNotes() when $default != null:
        return $default(
          _that.meetingId,
          _that.notesMarkdown,
          _that.notesJson,
          _that.updatedAt,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _MeetingNotes implements MeetingNotes {
  const _MeetingNotes({
    @JsonKey(name: 'meeting_id') required this.meetingId,
    @JsonKey(name: 'notes_markdown') this.notesMarkdown,
    @JsonKey(name: 'notes_json') this.notesJson,
    @JsonKey(name: 'updated_at') this.updatedAt,
  });
  factory _MeetingNotes.fromJson(Map<String, dynamic> json) =>
      _$MeetingNotesFromJson(json);

  @override
  @JsonKey(name: 'meeting_id')
  final String meetingId;
  @override
  @JsonKey(name: 'notes_markdown')
  final String? notesMarkdown;
  @override
  @JsonKey(name: 'notes_json')
  final String? notesJson;
  @override
  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  /// Create a copy of MeetingNotes
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$MeetingNotesCopyWith<_MeetingNotes> get copyWith =>
      __$MeetingNotesCopyWithImpl<_MeetingNotes>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$MeetingNotesToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _MeetingNotes &&
            (identical(other.meetingId, meetingId) ||
                other.meetingId == meetingId) &&
            (identical(other.notesMarkdown, notesMarkdown) ||
                other.notesMarkdown == notesMarkdown) &&
            (identical(other.notesJson, notesJson) ||
                other.notesJson == notesJson) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(
      runtimeType,
      meetingId,
      notesMarkdown,
      notesJson,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'MeetingNotes(meetingId: $meetingId, notesMarkdown: $notesMarkdown, notesJson: $notesJson, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class _$MeetingNotesCopyWith<$Res>
    implements $MeetingNotesCopyWith<$Res> {
  factory _$MeetingNotesCopyWith(
    _MeetingNotes value,
    $Res Function(_MeetingNotes) _then,
  ) = __$MeetingNotesCopyWithImpl;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'meeting_id') String meetingId,
    @JsonKey(name: 'notes_markdown') String? notesMarkdown,
    @JsonKey(name: 'notes_json') String? notesJson,
    @JsonKey(name: 'updated_at') String? updatedAt,
  });
}

/// @nodoc
class __$MeetingNotesCopyWithImpl<$Res>
    implements _$MeetingNotesCopyWith<$Res> {
  __$MeetingNotesCopyWithImpl(this._self, this._then);

  final _MeetingNotes _self;
  final $Res Function(_MeetingNotes) _then;

  /// Create a copy of MeetingNotes
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? meetingId = null,
    Object? notesMarkdown = freezed,
    Object? notesJson = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _MeetingNotes(
        meetingId: null == meetingId
            ? _self.meetingId
            : meetingId // ignore: cast_nullable_to_non_nullable
                  as String,
        notesMarkdown: freezed == notesMarkdown
            ? _self.notesMarkdown
            : notesMarkdown // ignore: cast_nullable_to_non_nullable
                  as String?,
        notesJson: freezed == notesJson
            ? _self.notesJson
            : notesJson // ignore: cast_nullable_to_non_nullable
                  as String?,
        updatedAt: freezed == updatedAt
            ? _self.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}
