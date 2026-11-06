// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'update_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UpdateOffer {
  String get id;
  String get version;
  int get build;
  @JsonKey(name: 'full_version')
  String get fullVersion;
  String get notes;
  @JsonKey(name: 'pub_date')
  String? get pubDate;

  /// Must be installed before the app can be used.
  bool get force;
  int? get size;
  String? get sha256;
  @JsonKey(name: 'download_url')
  String? get downloadUrl;
  @JsonKey(name: 'store_url')
  String? get storeUrl;

  /// Create a copy of UpdateOffer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $UpdateOfferCopyWith<UpdateOffer> get copyWith =>
      _$UpdateOfferCopyWithImpl<UpdateOffer>(this as UpdateOffer, _$identity);

  /// Serializes this UpdateOffer to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as UpdateOffer;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is UpdateOffer &&
            (identical(other.id, _this.id) || other.id == _this.id) &&
            (identical(other.version, _this.version) ||
                other.version == _this.version) &&
            (identical(other.build, _this.build) ||
                other.build == _this.build) &&
            (identical(other.fullVersion, _this.fullVersion) ||
                other.fullVersion == _this.fullVersion) &&
            (identical(other.notes, _this.notes) ||
                other.notes == _this.notes) &&
            (identical(other.pubDate, _this.pubDate) ||
                other.pubDate == _this.pubDate) &&
            (identical(other.force, _this.force) ||
                other.force == _this.force) &&
            (identical(other.size, _this.size) || other.size == _this.size) &&
            (identical(other.sha256, _this.sha256) ||
                other.sha256 == _this.sha256) &&
            (identical(other.downloadUrl, _this.downloadUrl) ||
                other.downloadUrl == _this.downloadUrl) &&
            (identical(other.storeUrl, _this.storeUrl) ||
                other.storeUrl == _this.storeUrl));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as UpdateOffer;
    return Object.hash(
      runtimeType,
      _this.id,
      _this.version,
      _this.build,
      _this.fullVersion,
      _this.notes,
      _this.pubDate,
      _this.force,
      _this.size,
      _this.sha256,
      _this.downloadUrl,
      _this.storeUrl,
    );
  }

  @override
  String toString() {
    final _this = this as UpdateOffer;
    return 'UpdateOffer(id: ${_this.id}, version: ${_this.version}, build: ${_this.build}, fullVersion: ${_this.fullVersion}, notes: ${_this.notes}, pubDate: ${_this.pubDate}, force: ${_this.force}, size: ${_this.size}, sha256: ${_this.sha256}, downloadUrl: ${_this.downloadUrl}, storeUrl: ${_this.storeUrl})';
  }
}

/// @nodoc
abstract mixin class $UpdateOfferCopyWith<$Res> {
  factory $UpdateOfferCopyWith(
    UpdateOffer value,
    $Res Function(UpdateOffer) _then,
  ) = _$UpdateOfferCopyWithImpl;
  @useResult
  $Res call({
    String id,
    String version,
    int build,
    @JsonKey(name: 'full_version') String fullVersion,
    String notes,
    @JsonKey(name: 'pub_date') String? pubDate,
    bool force,
    int? size,
    String? sha256,
    @JsonKey(name: 'download_url') String? downloadUrl,
    @JsonKey(name: 'store_url') String? storeUrl,
  });
}

/// @nodoc
class _$UpdateOfferCopyWithImpl<$Res> implements $UpdateOfferCopyWith<$Res> {
  _$UpdateOfferCopyWithImpl(this._self, this._then);

  final UpdateOffer _self;
  final $Res Function(UpdateOffer) _then;

  /// Create a copy of UpdateOffer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? version = null,
    Object? build = null,
    Object? fullVersion = null,
    Object? notes = null,
    Object? pubDate = freezed,
    Object? force = null,
    Object? size = freezed,
    Object? sha256 = freezed,
    Object? downloadUrl = freezed,
    Object? storeUrl = freezed,
  }) {
    return _then(
      UpdateOffer(
        id: null == id
            ? _self.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        version: null == version
            ? _self.version
            : version // ignore: cast_nullable_to_non_nullable
                  as String,
        build: null == build
            ? _self.build
            : build // ignore: cast_nullable_to_non_nullable
                  as int,
        fullVersion: null == fullVersion
            ? _self.fullVersion
            : fullVersion // ignore: cast_nullable_to_non_nullable
                  as String,
        notes: null == notes
            ? _self.notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as String,
        pubDate: freezed == pubDate
            ? _self.pubDate
            : pubDate // ignore: cast_nullable_to_non_nullable
                  as String?,
        force: null == force
            ? _self.force
            : force // ignore: cast_nullable_to_non_nullable
                  as bool,
        size: freezed == size
            ? _self.size
            : size // ignore: cast_nullable_to_non_nullable
                  as int?,
        sha256: freezed == sha256
            ? _self.sha256
            : sha256 // ignore: cast_nullable_to_non_nullable
                  as String?,
        downloadUrl: freezed == downloadUrl
            ? _self.downloadUrl
            : downloadUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        storeUrl: freezed == storeUrl
            ? _self.storeUrl
            : storeUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [UpdateOffer].
extension UpdateOfferPatterns on UpdateOffer {
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
    TResult Function(_UpdateOffer value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _UpdateOffer() when $default != null:
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
    TResult Function(_UpdateOffer value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UpdateOffer():
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
    TResult? Function(_UpdateOffer value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UpdateOffer() when $default != null:
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
      String version,
      int build,
      @JsonKey(name: 'full_version') String fullVersion,
      String notes,
      @JsonKey(name: 'pub_date') String? pubDate,
      bool force,
      int? size,
      String? sha256,
      @JsonKey(name: 'download_url') String? downloadUrl,
      @JsonKey(name: 'store_url') String? storeUrl,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _UpdateOffer() when $default != null:
        return $default(
          _that.id,
          _that.version,
          _that.build,
          _that.fullVersion,
          _that.notes,
          _that.pubDate,
          _that.force,
          _that.size,
          _that.sha256,
          _that.downloadUrl,
          _that.storeUrl,
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
      String version,
      int build,
      @JsonKey(name: 'full_version') String fullVersion,
      String notes,
      @JsonKey(name: 'pub_date') String? pubDate,
      bool force,
      int? size,
      String? sha256,
      @JsonKey(name: 'download_url') String? downloadUrl,
      @JsonKey(name: 'store_url') String? storeUrl,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UpdateOffer():
        return $default(
          _that.id,
          _that.version,
          _that.build,
          _that.fullVersion,
          _that.notes,
          _that.pubDate,
          _that.force,
          _that.size,
          _that.sha256,
          _that.downloadUrl,
          _that.storeUrl,
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
      String version,
      int build,
      @JsonKey(name: 'full_version') String fullVersion,
      String notes,
      @JsonKey(name: 'pub_date') String? pubDate,
      bool force,
      int? size,
      String? sha256,
      @JsonKey(name: 'download_url') String? downloadUrl,
      @JsonKey(name: 'store_url') String? storeUrl,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UpdateOffer() when $default != null:
        return $default(
          _that.id,
          _that.version,
          _that.build,
          _that.fullVersion,
          _that.notes,
          _that.pubDate,
          _that.force,
          _that.size,
          _that.sha256,
          _that.downloadUrl,
          _that.storeUrl,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _UpdateOffer implements UpdateOffer {
  const _UpdateOffer({
    required this.id,
    required this.version,
    this.build = 0,
    @JsonKey(name: 'full_version') required this.fullVersion,
    this.notes = '',
    @JsonKey(name: 'pub_date') this.pubDate,
    this.force = false,
    this.size,
    this.sha256,
    @JsonKey(name: 'download_url') this.downloadUrl,
    @JsonKey(name: 'store_url') this.storeUrl,
  });
  factory _UpdateOffer.fromJson(Map<String, dynamic> json) =>
      _$UpdateOfferFromJson(json);

  @override
  final String id;
  @override
  final String version;
  @override
  @JsonKey()
  final int build;
  @override
  @JsonKey(name: 'full_version')
  final String fullVersion;
  @override
  @JsonKey()
  final String notes;
  @override
  @JsonKey(name: 'pub_date')
  final String? pubDate;

  /// Must be installed before the app can be used.
  @override
  @JsonKey()
  final bool force;
  @override
  final int? size;
  @override
  final String? sha256;
  @override
  @JsonKey(name: 'download_url')
  final String? downloadUrl;
  @override
  @JsonKey(name: 'store_url')
  final String? storeUrl;

  /// Create a copy of UpdateOffer
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$UpdateOfferCopyWith<_UpdateOffer> get copyWith =>
      __$UpdateOfferCopyWithImpl<_UpdateOffer>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$UpdateOfferToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _UpdateOffer &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.build, build) || other.build == build) &&
            (identical(other.fullVersion, fullVersion) ||
                other.fullVersion == fullVersion) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.pubDate, pubDate) || other.pubDate == pubDate) &&
            (identical(other.force, force) || other.force == force) &&
            (identical(other.size, size) || other.size == size) &&
            (identical(other.sha256, sha256) || other.sha256 == sha256) &&
            (identical(other.downloadUrl, downloadUrl) ||
                other.downloadUrl == downloadUrl) &&
            (identical(other.storeUrl, storeUrl) ||
                other.storeUrl == storeUrl));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(
      runtimeType,
      id,
      version,
      build,
      fullVersion,
      notes,
      pubDate,
      force,
      size,
      sha256,
      downloadUrl,
      storeUrl,
    );
  }

  @override
  String toString() {
    return 'UpdateOffer(id: $id, version: $version, build: $build, fullVersion: $fullVersion, notes: $notes, pubDate: $pubDate, force: $force, size: $size, sha256: $sha256, downloadUrl: $downloadUrl, storeUrl: $storeUrl)';
  }
}

/// @nodoc
abstract mixin class _$UpdateOfferCopyWith<$Res>
    implements $UpdateOfferCopyWith<$Res> {
  factory _$UpdateOfferCopyWith(
    _UpdateOffer value,
    $Res Function(_UpdateOffer) _then,
  ) = __$UpdateOfferCopyWithImpl;
  @override
  @useResult
  $Res call({
    String id,
    String version,
    int build,
    @JsonKey(name: 'full_version') String fullVersion,
    String notes,
    @JsonKey(name: 'pub_date') String? pubDate,
    bool force,
    int? size,
    String? sha256,
    @JsonKey(name: 'download_url') String? downloadUrl,
    @JsonKey(name: 'store_url') String? storeUrl,
  });
}

/// @nodoc
class __$UpdateOfferCopyWithImpl<$Res> implements _$UpdateOfferCopyWith<$Res> {
  __$UpdateOfferCopyWithImpl(this._self, this._then);

  final _UpdateOffer _self;
  final $Res Function(_UpdateOffer) _then;

  /// Create a copy of UpdateOffer
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? version = null,
    Object? build = null,
    Object? fullVersion = null,
    Object? notes = null,
    Object? pubDate = freezed,
    Object? force = null,
    Object? size = freezed,
    Object? sha256 = freezed,
    Object? downloadUrl = freezed,
    Object? storeUrl = freezed,
  }) {
    return _then(
      _UpdateOffer(
        id: null == id
            ? _self.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        version: null == version
            ? _self.version
            : version // ignore: cast_nullable_to_non_nullable
                  as String,
        build: null == build
            ? _self.build
            : build // ignore: cast_nullable_to_non_nullable
                  as int,
        fullVersion: null == fullVersion
            ? _self.fullVersion
            : fullVersion // ignore: cast_nullable_to_non_nullable
                  as String,
        notes: null == notes
            ? _self.notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as String,
        pubDate: freezed == pubDate
            ? _self.pubDate
            : pubDate // ignore: cast_nullable_to_non_nullable
                  as String?,
        force: null == force
            ? _self.force
            : force // ignore: cast_nullable_to_non_nullable
                  as bool,
        size: freezed == size
            ? _self.size
            : size // ignore: cast_nullable_to_non_nullable
                  as int?,
        sha256: freezed == sha256
            ? _self.sha256
            : sha256 // ignore: cast_nullable_to_non_nullable
                  as String?,
        downloadUrl: freezed == downloadUrl
            ? _self.downloadUrl
            : downloadUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        storeUrl: freezed == storeUrl
            ? _self.storeUrl
            : storeUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
mixin _$UpdateCheckResult {
  UpdateOffer? get update;
  @JsonKey(name: 'min_version')
  String? get minVersion;

  /// Create a copy of UpdateCheckResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $UpdateCheckResultCopyWith<UpdateCheckResult> get copyWith =>
      _$UpdateCheckResultCopyWithImpl<UpdateCheckResult>(
        this as UpdateCheckResult,
        _$identity,
      );

  /// Serializes this UpdateCheckResult to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as UpdateCheckResult;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is UpdateCheckResult &&
            (identical(other.update, _this.update) ||
                other.update == _this.update) &&
            (identical(other.minVersion, _this.minVersion) ||
                other.minVersion == _this.minVersion));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as UpdateCheckResult;
    return Object.hash(runtimeType, _this.update, _this.minVersion);
  }

  @override
  String toString() {
    final _this = this as UpdateCheckResult;
    return 'UpdateCheckResult(update: ${_this.update}, minVersion: ${_this.minVersion})';
  }
}

/// @nodoc
abstract mixin class $UpdateCheckResultCopyWith<$Res> {
  factory $UpdateCheckResultCopyWith(
    UpdateCheckResult value,
    $Res Function(UpdateCheckResult) _then,
  ) = _$UpdateCheckResultCopyWithImpl;
  @useResult
  $Res call({
    UpdateOffer? update,
    @JsonKey(name: 'min_version') String? minVersion,
  });

  $UpdateOfferCopyWith<$Res>? get update;
}

/// @nodoc
class _$UpdateCheckResultCopyWithImpl<$Res>
    implements $UpdateCheckResultCopyWith<$Res> {
  _$UpdateCheckResultCopyWithImpl(this._self, this._then);

  final UpdateCheckResult _self;
  final $Res Function(UpdateCheckResult) _then;

  /// Create a copy of UpdateCheckResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? update = freezed, Object? minVersion = freezed}) {
    return _then(
      UpdateCheckResult(
        update: freezed == update
            ? _self.update
            : update // ignore: cast_nullable_to_non_nullable
                  as UpdateOffer?,
        minVersion: freezed == minVersion
            ? _self.minVersion
            : minVersion // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }

  /// Create a copy of UpdateCheckResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $UpdateOfferCopyWith<$Res>? get update {
    if (_self.update == null) {
      return null;
    }

    return $UpdateOfferCopyWith<$Res>(_self.update!, (value) {
      return _then(_self.copyWith(update: value));
    });
  }
}

/// Adds pattern-matching-related methods to [UpdateCheckResult].
extension UpdateCheckResultPatterns on UpdateCheckResult {
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
    TResult Function(_UpdateCheckResult value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _UpdateCheckResult() when $default != null:
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
    TResult Function(_UpdateCheckResult value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UpdateCheckResult():
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
    TResult? Function(_UpdateCheckResult value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UpdateCheckResult() when $default != null:
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
      UpdateOffer? update,
      @JsonKey(name: 'min_version') String? minVersion,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _UpdateCheckResult() when $default != null:
        return $default(_that.update, _that.minVersion);
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
      UpdateOffer? update,
      @JsonKey(name: 'min_version') String? minVersion,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UpdateCheckResult():
        return $default(_that.update, _that.minVersion);
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
      UpdateOffer? update,
      @JsonKey(name: 'min_version') String? minVersion,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UpdateCheckResult() when $default != null:
        return $default(_that.update, _that.minVersion);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _UpdateCheckResult implements UpdateCheckResult {
  const _UpdateCheckResult({
    this.update,
    @JsonKey(name: 'min_version') this.minVersion,
  });
  factory _UpdateCheckResult.fromJson(Map<String, dynamic> json) =>
      _$UpdateCheckResultFromJson(json);

  @override
  final UpdateOffer? update;
  @override
  @JsonKey(name: 'min_version')
  final String? minVersion;

  /// Create a copy of UpdateCheckResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$UpdateCheckResultCopyWith<_UpdateCheckResult> get copyWith =>
      __$UpdateCheckResultCopyWithImpl<_UpdateCheckResult>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$UpdateCheckResultToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _UpdateCheckResult &&
            (identical(other.update, update) || other.update == update) &&
            (identical(other.minVersion, minVersion) ||
                other.minVersion == minVersion));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(runtimeType, update, minVersion);
  }

  @override
  String toString() {
    return 'UpdateCheckResult(update: $update, minVersion: $minVersion)';
  }
}

/// @nodoc
abstract mixin class _$UpdateCheckResultCopyWith<$Res>
    implements $UpdateCheckResultCopyWith<$Res> {
  factory _$UpdateCheckResultCopyWith(
    _UpdateCheckResult value,
    $Res Function(_UpdateCheckResult) _then,
  ) = __$UpdateCheckResultCopyWithImpl;
  @override
  @useResult
  $Res call({
    UpdateOffer? update,
    @JsonKey(name: 'min_version') String? minVersion,
  });

  @override
  $UpdateOfferCopyWith<$Res>? get update;
}

/// @nodoc
class __$UpdateCheckResultCopyWithImpl<$Res>
    implements _$UpdateCheckResultCopyWith<$Res> {
  __$UpdateCheckResultCopyWithImpl(this._self, this._then);

  final _UpdateCheckResult _self;
  final $Res Function(_UpdateCheckResult) _then;

  /// Create a copy of UpdateCheckResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({Object? update = freezed, Object? minVersion = freezed}) {
    return _then(
      _UpdateCheckResult(
        update: freezed == update
            ? _self.update
            : update // ignore: cast_nullable_to_non_nullable
                  as UpdateOffer?,
        minVersion: freezed == minVersion
            ? _self.minVersion
            : minVersion // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }

  /// Create a copy of UpdateCheckResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $UpdateOfferCopyWith<$Res>? get update {
    if (_self.update == null) {
      return null;
    }

    return $UpdateOfferCopyWith<$Res>(_self.update!, (value) {
      return _then(_self.copyWith(update: value));
    });
  }
}
