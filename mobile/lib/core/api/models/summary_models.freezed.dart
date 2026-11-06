// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'summary_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SummaryResponse {
  @JsonKey(unknownEnumValue: SummaryStatus.unknown)
  SummaryStatus get status;
  String? get meetingName;
  @JsonKey(name: 'meeting_id')
  String? get meetingId;
  String? get start;
  String? get end;
  Object? get data;
  String? get error;

  /// Create a copy of SummaryResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SummaryResponseCopyWith<SummaryResponse> get copyWith =>
      _$SummaryResponseCopyWithImpl<SummaryResponse>(
        this as SummaryResponse,
        _$identity,
      );

  /// Serializes this SummaryResponse to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as SummaryResponse;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SummaryResponse &&
            (identical(other.status, _this.status) ||
                other.status == _this.status) &&
            (identical(other.meetingName, _this.meetingName) ||
                other.meetingName == _this.meetingName) &&
            (identical(other.meetingId, _this.meetingId) ||
                other.meetingId == _this.meetingId) &&
            (identical(other.start, _this.start) ||
                other.start == _this.start) &&
            (identical(other.end, _this.end) || other.end == _this.end) &&
            const DeepCollectionEquality().equals(other.data, _this.data) &&
            (identical(other.error, _this.error) ||
                other.error == _this.error));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as SummaryResponse;
    return Object.hash(
      runtimeType,
      _this.status,
      _this.meetingName,
      _this.meetingId,
      _this.start,
      _this.end,
      const DeepCollectionEquality().hash(_this.data),
      _this.error,
    );
  }

  @override
  String toString() {
    final _this = this as SummaryResponse;
    return 'SummaryResponse(status: ${_this.status}, meetingName: ${_this.meetingName}, meetingId: ${_this.meetingId}, start: ${_this.start}, end: ${_this.end}, data: ${_this.data}, error: ${_this.error})';
  }
}

/// @nodoc
abstract mixin class $SummaryResponseCopyWith<$Res> {
  factory $SummaryResponseCopyWith(
    SummaryResponse value,
    $Res Function(SummaryResponse) _then,
  ) = _$SummaryResponseCopyWithImpl;
  @useResult
  $Res call({
    @JsonKey(unknownEnumValue: SummaryStatus.unknown) SummaryStatus status,
    String? meetingName,
    @JsonKey(name: 'meeting_id') String? meetingId,
    String? start,
    String? end,
    Object? data,
    String? error,
  });
}

/// @nodoc
class _$SummaryResponseCopyWithImpl<$Res>
    implements $SummaryResponseCopyWith<$Res> {
  _$SummaryResponseCopyWithImpl(this._self, this._then);

  final SummaryResponse _self;
  final $Res Function(SummaryResponse) _then;

  /// Create a copy of SummaryResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? meetingName = freezed,
    Object? meetingId = freezed,
    Object? start = freezed,
    Object? end = freezed,
    Object? data = freezed,
    Object? error = freezed,
  }) {
    return _then(
      SummaryResponse(
        status: null == status
            ? _self.status
            : status // ignore: cast_nullable_to_non_nullable
                  as SummaryStatus,
        meetingName: freezed == meetingName
            ? _self.meetingName
            : meetingName // ignore: cast_nullable_to_non_nullable
                  as String?,
        meetingId: freezed == meetingId
            ? _self.meetingId
            : meetingId // ignore: cast_nullable_to_non_nullable
                  as String?,
        start: freezed == start
            ? _self.start
            : start // ignore: cast_nullable_to_non_nullable
                  as String?,
        end: freezed == end
            ? _self.end
            : end // ignore: cast_nullable_to_non_nullable
                  as String?,
        data: freezed == data ? _self.data : data,
        error: freezed == error
            ? _self.error
            : error // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [SummaryResponse].
extension SummaryResponsePatterns on SummaryResponse {
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
    TResult Function(_SummaryResponse value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SummaryResponse() when $default != null:
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
    TResult Function(_SummaryResponse value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SummaryResponse():
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
    TResult? Function(_SummaryResponse value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SummaryResponse() when $default != null:
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
      @JsonKey(unknownEnumValue: SummaryStatus.unknown) SummaryStatus status,
      String? meetingName,
      @JsonKey(name: 'meeting_id') String? meetingId,
      String? start,
      String? end,
      Object? data,
      String? error,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SummaryResponse() when $default != null:
        return $default(
          _that.status,
          _that.meetingName,
          _that.meetingId,
          _that.start,
          _that.end,
          _that.data,
          _that.error,
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
      @JsonKey(unknownEnumValue: SummaryStatus.unknown) SummaryStatus status,
      String? meetingName,
      @JsonKey(name: 'meeting_id') String? meetingId,
      String? start,
      String? end,
      Object? data,
      String? error,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SummaryResponse():
        return $default(
          _that.status,
          _that.meetingName,
          _that.meetingId,
          _that.start,
          _that.end,
          _that.data,
          _that.error,
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
      @JsonKey(unknownEnumValue: SummaryStatus.unknown) SummaryStatus status,
      String? meetingName,
      @JsonKey(name: 'meeting_id') String? meetingId,
      String? start,
      String? end,
      Object? data,
      String? error,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SummaryResponse() when $default != null:
        return $default(
          _that.status,
          _that.meetingName,
          _that.meetingId,
          _that.start,
          _that.end,
          _that.data,
          _that.error,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _SummaryResponse implements SummaryResponse {
  const _SummaryResponse({
    @JsonKey(unknownEnumValue: SummaryStatus.unknown) required this.status,
    this.meetingName,
    @JsonKey(name: 'meeting_id') this.meetingId,
    this.start,
    this.end,
    this.data,
    this.error,
  });
  factory _SummaryResponse.fromJson(Map<String, dynamic> json) =>
      _$SummaryResponseFromJson(json);

  @override
  @JsonKey(unknownEnumValue: SummaryStatus.unknown)
  final SummaryStatus status;
  @override
  final String? meetingName;
  @override
  @JsonKey(name: 'meeting_id')
  final String? meetingId;
  @override
  final String? start;
  @override
  final String? end;
  @override
  final Object? data;
  @override
  final String? error;

  /// Create a copy of SummaryResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$SummaryResponseCopyWith<_SummaryResponse> get copyWith =>
      __$SummaryResponseCopyWithImpl<_SummaryResponse>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$SummaryResponseToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _SummaryResponse &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.meetingName, meetingName) ||
                other.meetingName == meetingName) &&
            (identical(other.meetingId, meetingId) ||
                other.meetingId == meetingId) &&
            (identical(other.start, start) || other.start == start) &&
            (identical(other.end, end) || other.end == end) &&
            const DeepCollectionEquality().equals(other.data, data) &&
            (identical(other.error, error) || other.error == error));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(
      runtimeType,
      status,
      meetingName,
      meetingId,
      start,
      end,
      const DeepCollectionEquality().hash(data),
      error,
    );
  }

  @override
  String toString() {
    return 'SummaryResponse(status: $status, meetingName: $meetingName, meetingId: $meetingId, start: $start, end: $end, data: $data, error: $error)';
  }
}

/// @nodoc
abstract mixin class _$SummaryResponseCopyWith<$Res>
    implements $SummaryResponseCopyWith<$Res> {
  factory _$SummaryResponseCopyWith(
    _SummaryResponse value,
    $Res Function(_SummaryResponse) _then,
  ) = __$SummaryResponseCopyWithImpl;
  @override
  @useResult
  $Res call({
    @JsonKey(unknownEnumValue: SummaryStatus.unknown) SummaryStatus status,
    String? meetingName,
    @JsonKey(name: 'meeting_id') String? meetingId,
    String? start,
    String? end,
    Object? data,
    String? error,
  });
}

/// @nodoc
class __$SummaryResponseCopyWithImpl<$Res>
    implements _$SummaryResponseCopyWith<$Res> {
  __$SummaryResponseCopyWithImpl(this._self, this._then);

  final _SummaryResponse _self;
  final $Res Function(_SummaryResponse) _then;

  /// Create a copy of SummaryResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? status = null,
    Object? meetingName = freezed,
    Object? meetingId = freezed,
    Object? start = freezed,
    Object? end = freezed,
    Object? data = freezed,
    Object? error = freezed,
  }) {
    return _then(
      _SummaryResponse(
        status: null == status
            ? _self.status
            : status // ignore: cast_nullable_to_non_nullable
                  as SummaryStatus,
        meetingName: freezed == meetingName
            ? _self.meetingName
            : meetingName // ignore: cast_nullable_to_non_nullable
                  as String?,
        meetingId: freezed == meetingId
            ? _self.meetingId
            : meetingId // ignore: cast_nullable_to_non_nullable
                  as String?,
        start: freezed == start
            ? _self.start
            : start // ignore: cast_nullable_to_non_nullable
                  as String?,
        end: freezed == end
            ? _self.end
            : end // ignore: cast_nullable_to_non_nullable
                  as String?,
        data: freezed == data ? _self.data : data,
        error: freezed == error
            ? _self.error
            : error // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
mixin _$ProcessStarted {
  String get message;
  @JsonKey(name: 'process_id')
  String get processId;

  /// Create a copy of ProcessStarted
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ProcessStartedCopyWith<ProcessStarted> get copyWith =>
      _$ProcessStartedCopyWithImpl<ProcessStarted>(
        this as ProcessStarted,
        _$identity,
      );

  /// Serializes this ProcessStarted to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as ProcessStarted;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ProcessStarted &&
            (identical(other.message, _this.message) ||
                other.message == _this.message) &&
            (identical(other.processId, _this.processId) ||
                other.processId == _this.processId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as ProcessStarted;
    return Object.hash(runtimeType, _this.message, _this.processId);
  }

  @override
  String toString() {
    final _this = this as ProcessStarted;
    return 'ProcessStarted(message: ${_this.message}, processId: ${_this.processId})';
  }
}

/// @nodoc
abstract mixin class $ProcessStartedCopyWith<$Res> {
  factory $ProcessStartedCopyWith(
    ProcessStarted value,
    $Res Function(ProcessStarted) _then,
  ) = _$ProcessStartedCopyWithImpl;
  @useResult
  $Res call({String message, @JsonKey(name: 'process_id') String processId});
}

/// @nodoc
class _$ProcessStartedCopyWithImpl<$Res>
    implements $ProcessStartedCopyWith<$Res> {
  _$ProcessStartedCopyWithImpl(this._self, this._then);

  final ProcessStarted _self;
  final $Res Function(ProcessStarted) _then;

  /// Create a copy of ProcessStarted
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null, Object? processId = null}) {
    return _then(
      ProcessStarted(
        message: null == message
            ? _self.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
        processId: null == processId
            ? _self.processId
            : processId // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [ProcessStarted].
extension ProcessStartedPatterns on ProcessStarted {
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
    TResult Function(_ProcessStarted value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ProcessStarted() when $default != null:
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
    TResult Function(_ProcessStarted value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ProcessStarted():
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
    TResult? Function(_ProcessStarted value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ProcessStarted() when $default != null:
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
      String message,
      @JsonKey(name: 'process_id') String processId,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ProcessStarted() when $default != null:
        return $default(_that.message, _that.processId);
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
      String message,
      @JsonKey(name: 'process_id') String processId,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ProcessStarted():
        return $default(_that.message, _that.processId);
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
      String message,
      @JsonKey(name: 'process_id') String processId,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ProcessStarted() when $default != null:
        return $default(_that.message, _that.processId);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _ProcessStarted implements ProcessStarted {
  const _ProcessStarted({
    required this.message,
    @JsonKey(name: 'process_id') required this.processId,
  });
  factory _ProcessStarted.fromJson(Map<String, dynamic> json) =>
      _$ProcessStartedFromJson(json);

  @override
  final String message;
  @override
  @JsonKey(name: 'process_id')
  final String processId;

  /// Create a copy of ProcessStarted
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ProcessStartedCopyWith<_ProcessStarted> get copyWith =>
      __$ProcessStartedCopyWithImpl<_ProcessStarted>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ProcessStartedToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ProcessStarted &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.processId, processId) ||
                other.processId == processId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(runtimeType, message, processId);
  }

  @override
  String toString() {
    return 'ProcessStarted(message: $message, processId: $processId)';
  }
}

/// @nodoc
abstract mixin class _$ProcessStartedCopyWith<$Res>
    implements $ProcessStartedCopyWith<$Res> {
  factory _$ProcessStartedCopyWith(
    _ProcessStarted value,
    $Res Function(_ProcessStarted) _then,
  ) = __$ProcessStartedCopyWithImpl;
  @override
  @useResult
  $Res call({String message, @JsonKey(name: 'process_id') String processId});
}

/// @nodoc
class __$ProcessStartedCopyWithImpl<$Res>
    implements _$ProcessStartedCopyWith<$Res> {
  __$ProcessStartedCopyWithImpl(this._self, this._then);

  final _ProcessStarted _self;
  final $Res Function(_ProcessStarted) _then;

  /// Create a copy of ProcessStarted
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({Object? message = null, Object? processId = null}) {
    return _then(
      _ProcessStarted(
        message: null == message
            ? _self.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
        processId: null == processId
            ? _self.processId
            : processId // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
mixin _$SummaryLanguage {
  String? get language;
  @JsonKey(name: 'detected_language')
  String? get detectedLanguage;

  /// Create a copy of SummaryLanguage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SummaryLanguageCopyWith<SummaryLanguage> get copyWith =>
      _$SummaryLanguageCopyWithImpl<SummaryLanguage>(
        this as SummaryLanguage,
        _$identity,
      );

  /// Serializes this SummaryLanguage to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as SummaryLanguage;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SummaryLanguage &&
            (identical(other.language, _this.language) ||
                other.language == _this.language) &&
            (identical(other.detectedLanguage, _this.detectedLanguage) ||
                other.detectedLanguage == _this.detectedLanguage));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as SummaryLanguage;
    return Object.hash(runtimeType, _this.language, _this.detectedLanguage);
  }

  @override
  String toString() {
    final _this = this as SummaryLanguage;
    return 'SummaryLanguage(language: ${_this.language}, detectedLanguage: ${_this.detectedLanguage})';
  }
}

/// @nodoc
abstract mixin class $SummaryLanguageCopyWith<$Res> {
  factory $SummaryLanguageCopyWith(
    SummaryLanguage value,
    $Res Function(SummaryLanguage) _then,
  ) = _$SummaryLanguageCopyWithImpl;
  @useResult
  $Res call({
    String? language,
    @JsonKey(name: 'detected_language') String? detectedLanguage,
  });
}

/// @nodoc
class _$SummaryLanguageCopyWithImpl<$Res>
    implements $SummaryLanguageCopyWith<$Res> {
  _$SummaryLanguageCopyWithImpl(this._self, this._then);

  final SummaryLanguage _self;
  final $Res Function(SummaryLanguage) _then;

  /// Create a copy of SummaryLanguage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? language = freezed, Object? detectedLanguage = freezed}) {
    return _then(
      SummaryLanguage(
        language: freezed == language
            ? _self.language
            : language // ignore: cast_nullable_to_non_nullable
                  as String?,
        detectedLanguage: freezed == detectedLanguage
            ? _self.detectedLanguage
            : detectedLanguage // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [SummaryLanguage].
extension SummaryLanguagePatterns on SummaryLanguage {
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
    TResult Function(_SummaryLanguage value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SummaryLanguage() when $default != null:
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
    TResult Function(_SummaryLanguage value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SummaryLanguage():
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
    TResult? Function(_SummaryLanguage value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SummaryLanguage() when $default != null:
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
      String? language,
      @JsonKey(name: 'detected_language') String? detectedLanguage,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SummaryLanguage() when $default != null:
        return $default(_that.language, _that.detectedLanguage);
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
      String? language,
      @JsonKey(name: 'detected_language') String? detectedLanguage,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SummaryLanguage():
        return $default(_that.language, _that.detectedLanguage);
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
      String? language,
      @JsonKey(name: 'detected_language') String? detectedLanguage,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SummaryLanguage() when $default != null:
        return $default(_that.language, _that.detectedLanguage);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _SummaryLanguage implements SummaryLanguage {
  const _SummaryLanguage({
    this.language,
    @JsonKey(name: 'detected_language') this.detectedLanguage,
  });
  factory _SummaryLanguage.fromJson(Map<String, dynamic> json) =>
      _$SummaryLanguageFromJson(json);

  @override
  final String? language;
  @override
  @JsonKey(name: 'detected_language')
  final String? detectedLanguage;

  /// Create a copy of SummaryLanguage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$SummaryLanguageCopyWith<_SummaryLanguage> get copyWith =>
      __$SummaryLanguageCopyWithImpl<_SummaryLanguage>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$SummaryLanguageToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _SummaryLanguage &&
            (identical(other.language, language) ||
                other.language == language) &&
            (identical(other.detectedLanguage, detectedLanguage) ||
                other.detectedLanguage == detectedLanguage));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(runtimeType, language, detectedLanguage);
  }

  @override
  String toString() {
    return 'SummaryLanguage(language: $language, detectedLanguage: $detectedLanguage)';
  }
}

/// @nodoc
abstract mixin class _$SummaryLanguageCopyWith<$Res>
    implements $SummaryLanguageCopyWith<$Res> {
  factory _$SummaryLanguageCopyWith(
    _SummaryLanguage value,
    $Res Function(_SummaryLanguage) _then,
  ) = __$SummaryLanguageCopyWithImpl;
  @override
  @useResult
  $Res call({
    String? language,
    @JsonKey(name: 'detected_language') String? detectedLanguage,
  });
}

/// @nodoc
class __$SummaryLanguageCopyWithImpl<$Res>
    implements _$SummaryLanguageCopyWith<$Res> {
  __$SummaryLanguageCopyWithImpl(this._self, this._then);

  final _SummaryLanguage _self;
  final $Res Function(_SummaryLanguage) _then;

  /// Create a copy of SummaryLanguage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({Object? language = freezed, Object? detectedLanguage = freezed}) {
    return _then(
      _SummaryLanguage(
        language: freezed == language
            ? _self.language
            : language // ignore: cast_nullable_to_non_nullable
                  as String?,
        detectedLanguage: freezed == detectedLanguage
            ? _self.detectedLanguage
            : detectedLanguage // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}
