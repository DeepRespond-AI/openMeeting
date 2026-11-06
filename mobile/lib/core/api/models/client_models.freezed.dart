// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'client_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Capabilities {
  @JsonKey(name: 'server_version')
  String get serverVersion;
  CapabilityUser? get user;
  SttStatus get stt;
  LlmStatus get llm;

  /// Create a copy of Capabilities
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $CapabilitiesCopyWith<Capabilities> get copyWith =>
      _$CapabilitiesCopyWithImpl<Capabilities>(
        this as Capabilities,
        _$identity,
      );

  /// Serializes this Capabilities to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as Capabilities;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Capabilities &&
            (identical(other.serverVersion, _this.serverVersion) ||
                other.serverVersion == _this.serverVersion) &&
            (identical(other.user, _this.user) || other.user == _this.user) &&
            (identical(other.stt, _this.stt) || other.stt == _this.stt) &&
            (identical(other.llm, _this.llm) || other.llm == _this.llm));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as Capabilities;
    return Object.hash(
      runtimeType,
      _this.serverVersion,
      _this.user,
      _this.stt,
      _this.llm,
    );
  }

  @override
  String toString() {
    final _this = this as Capabilities;
    return 'Capabilities(serverVersion: ${_this.serverVersion}, user: ${_this.user}, stt: ${_this.stt}, llm: ${_this.llm})';
  }
}

/// @nodoc
abstract mixin class $CapabilitiesCopyWith<$Res> {
  factory $CapabilitiesCopyWith(
    Capabilities value,
    $Res Function(Capabilities) _then,
  ) = _$CapabilitiesCopyWithImpl;
  @useResult
  $Res call({
    @JsonKey(name: 'server_version') String serverVersion,
    CapabilityUser? user,
    SttStatus stt,
    LlmStatus llm,
  });

  $CapabilityUserCopyWith<$Res>? get user;
  $SttStatusCopyWith<$Res> get stt;
  $LlmStatusCopyWith<$Res> get llm;
}

/// @nodoc
class _$CapabilitiesCopyWithImpl<$Res> implements $CapabilitiesCopyWith<$Res> {
  _$CapabilitiesCopyWithImpl(this._self, this._then);

  final Capabilities _self;
  final $Res Function(Capabilities) _then;

  /// Create a copy of Capabilities
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? serverVersion = null,
    Object? user = freezed,
    Object? stt = null,
    Object? llm = null,
  }) {
    return _then(
      Capabilities(
        serverVersion: null == serverVersion
            ? _self.serverVersion
            : serverVersion // ignore: cast_nullable_to_non_nullable
                  as String,
        user: freezed == user
            ? _self.user
            : user // ignore: cast_nullable_to_non_nullable
                  as CapabilityUser?,
        stt: null == stt
            ? _self.stt
            : stt // ignore: cast_nullable_to_non_nullable
                  as SttStatus,
        llm: null == llm
            ? _self.llm
            : llm // ignore: cast_nullable_to_non_nullable
                  as LlmStatus,
      ),
    );
  }

  /// Create a copy of Capabilities
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CapabilityUserCopyWith<$Res>? get user {
    if (_self.user == null) {
      return null;
    }

    return $CapabilityUserCopyWith<$Res>(_self.user!, (value) {
      return _then(_self.copyWith(user: value));
    });
  }

  /// Create a copy of Capabilities
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SttStatusCopyWith<$Res> get stt {
    return $SttStatusCopyWith<$Res>(_self.stt, (value) {
      return _then(_self.copyWith(stt: value));
    });
  }

  /// Create a copy of Capabilities
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $LlmStatusCopyWith<$Res> get llm {
    return $LlmStatusCopyWith<$Res>(_self.llm, (value) {
      return _then(_self.copyWith(llm: value));
    });
  }
}

/// Adds pattern-matching-related methods to [Capabilities].
extension CapabilitiesPatterns on Capabilities {
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
    TResult Function(_Capabilities value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Capabilities() when $default != null:
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
    TResult Function(_Capabilities value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Capabilities():
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
    TResult? Function(_Capabilities value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Capabilities() when $default != null:
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
      @JsonKey(name: 'server_version') String serverVersion,
      CapabilityUser? user,
      SttStatus stt,
      LlmStatus llm,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Capabilities() when $default != null:
        return $default(_that.serverVersion, _that.user, _that.stt, _that.llm);
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
      @JsonKey(name: 'server_version') String serverVersion,
      CapabilityUser? user,
      SttStatus stt,
      LlmStatus llm,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Capabilities():
        return $default(_that.serverVersion, _that.user, _that.stt, _that.llm);
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
      @JsonKey(name: 'server_version') String serverVersion,
      CapabilityUser? user,
      SttStatus stt,
      LlmStatus llm,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Capabilities() when $default != null:
        return $default(_that.serverVersion, _that.user, _that.stt, _that.llm);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _Capabilities implements Capabilities {
  const _Capabilities({
    @JsonKey(name: 'server_version') required this.serverVersion,
    this.user,
    required this.stt,
    required this.llm,
  });
  factory _Capabilities.fromJson(Map<String, dynamic> json) =>
      _$CapabilitiesFromJson(json);

  @override
  @JsonKey(name: 'server_version')
  final String serverVersion;
  @override
  final CapabilityUser? user;
  @override
  final SttStatus stt;
  @override
  final LlmStatus llm;

  /// Create a copy of Capabilities
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$CapabilitiesCopyWith<_Capabilities> get copyWith =>
      __$CapabilitiesCopyWithImpl<_Capabilities>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$CapabilitiesToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Capabilities &&
            (identical(other.serverVersion, serverVersion) ||
                other.serverVersion == serverVersion) &&
            (identical(other.user, user) || other.user == user) &&
            (identical(other.stt, stt) || other.stt == stt) &&
            (identical(other.llm, llm) || other.llm == llm));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(runtimeType, serverVersion, user, stt, llm);
  }

  @override
  String toString() {
    return 'Capabilities(serverVersion: $serverVersion, user: $user, stt: $stt, llm: $llm)';
  }
}

/// @nodoc
abstract mixin class _$CapabilitiesCopyWith<$Res>
    implements $CapabilitiesCopyWith<$Res> {
  factory _$CapabilitiesCopyWith(
    _Capabilities value,
    $Res Function(_Capabilities) _then,
  ) = __$CapabilitiesCopyWithImpl;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'server_version') String serverVersion,
    CapabilityUser? user,
    SttStatus stt,
    LlmStatus llm,
  });

  @override
  $CapabilityUserCopyWith<$Res>? get user;
  @override
  $SttStatusCopyWith<$Res> get stt;
  @override
  $LlmStatusCopyWith<$Res> get llm;
}

/// @nodoc
class __$CapabilitiesCopyWithImpl<$Res>
    implements _$CapabilitiesCopyWith<$Res> {
  __$CapabilitiesCopyWithImpl(this._self, this._then);

  final _Capabilities _self;
  final $Res Function(_Capabilities) _then;

  /// Create a copy of Capabilities
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? serverVersion = null,
    Object? user = freezed,
    Object? stt = null,
    Object? llm = null,
  }) {
    return _then(
      _Capabilities(
        serverVersion: null == serverVersion
            ? _self.serverVersion
            : serverVersion // ignore: cast_nullable_to_non_nullable
                  as String,
        user: freezed == user
            ? _self.user
            : user // ignore: cast_nullable_to_non_nullable
                  as CapabilityUser?,
        stt: null == stt
            ? _self.stt
            : stt // ignore: cast_nullable_to_non_nullable
                  as SttStatus,
        llm: null == llm
            ? _self.llm
            : llm // ignore: cast_nullable_to_non_nullable
                  as LlmStatus,
      ),
    );
  }

  /// Create a copy of Capabilities
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CapabilityUserCopyWith<$Res>? get user {
    if (_self.user == null) {
      return null;
    }

    return $CapabilityUserCopyWith<$Res>(_self.user!, (value) {
      return _then(_self.copyWith(user: value));
    });
  }

  /// Create a copy of Capabilities
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SttStatusCopyWith<$Res> get stt {
    return $SttStatusCopyWith<$Res>(_self.stt, (value) {
      return _then(_self.copyWith(stt: value));
    });
  }

  /// Create a copy of Capabilities
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $LlmStatusCopyWith<$Res> get llm {
    return $LlmStatusCopyWith<$Res>(_self.llm, (value) {
      return _then(_self.copyWith(llm: value));
    });
  }
}

/// @nodoc
mixin _$CapabilityUser {
  String get id;
  String? get name;
  String? get phone;

  /// Create a copy of CapabilityUser
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $CapabilityUserCopyWith<CapabilityUser> get copyWith =>
      _$CapabilityUserCopyWithImpl<CapabilityUser>(
        this as CapabilityUser,
        _$identity,
      );

  /// Serializes this CapabilityUser to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as CapabilityUser;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is CapabilityUser &&
            (identical(other.id, _this.id) || other.id == _this.id) &&
            (identical(other.name, _this.name) || other.name == _this.name) &&
            (identical(other.phone, _this.phone) ||
                other.phone == _this.phone));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as CapabilityUser;
    return Object.hash(runtimeType, _this.id, _this.name, _this.phone);
  }

  @override
  String toString() {
    final _this = this as CapabilityUser;
    return 'CapabilityUser(id: ${_this.id}, name: ${_this.name}, phone: ${_this.phone})';
  }
}

/// @nodoc
abstract mixin class $CapabilityUserCopyWith<$Res> {
  factory $CapabilityUserCopyWith(
    CapabilityUser value,
    $Res Function(CapabilityUser) _then,
  ) = _$CapabilityUserCopyWithImpl;
  @useResult
  $Res call({String id, String? name, String? phone});
}

/// @nodoc
class _$CapabilityUserCopyWithImpl<$Res>
    implements $CapabilityUserCopyWith<$Res> {
  _$CapabilityUserCopyWithImpl(this._self, this._then);

  final CapabilityUser _self;
  final $Res Function(CapabilityUser) _then;

  /// Create a copy of CapabilityUser
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = freezed,
    Object? phone = freezed,
  }) {
    return _then(
      CapabilityUser(
        id: null == id
            ? _self.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: freezed == name
            ? _self.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String?,
        phone: freezed == phone
            ? _self.phone
            : phone // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [CapabilityUser].
extension CapabilityUserPatterns on CapabilityUser {
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
    TResult Function(_CapabilityUser value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _CapabilityUser() when $default != null:
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
    TResult Function(_CapabilityUser value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CapabilityUser():
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
    TResult? Function(_CapabilityUser value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CapabilityUser() when $default != null:
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
    TResult Function(String id, String? name, String? phone)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _CapabilityUser() when $default != null:
        return $default(_that.id, _that.name, _that.phone);
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
    TResult Function(String id, String? name, String? phone) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CapabilityUser():
        return $default(_that.id, _that.name, _that.phone);
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
    TResult? Function(String id, String? name, String? phone)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CapabilityUser() when $default != null:
        return $default(_that.id, _that.name, _that.phone);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _CapabilityUser implements CapabilityUser {
  const _CapabilityUser({required this.id, this.name, this.phone});
  factory _CapabilityUser.fromJson(Map<String, dynamic> json) =>
      _$CapabilityUserFromJson(json);

  @override
  final String id;
  @override
  final String? name;
  @override
  final String? phone;

  /// Create a copy of CapabilityUser
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$CapabilityUserCopyWith<_CapabilityUser> get copyWith =>
      __$CapabilityUserCopyWithImpl<_CapabilityUser>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$CapabilityUserToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _CapabilityUser &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.phone, phone) || other.phone == phone));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(runtimeType, id, name, phone);
  }

  @override
  String toString() {
    return 'CapabilityUser(id: $id, name: $name, phone: $phone)';
  }
}

/// @nodoc
abstract mixin class _$CapabilityUserCopyWith<$Res>
    implements $CapabilityUserCopyWith<$Res> {
  factory _$CapabilityUserCopyWith(
    _CapabilityUser value,
    $Res Function(_CapabilityUser) _then,
  ) = __$CapabilityUserCopyWithImpl;
  @override
  @useResult
  $Res call({String id, String? name, String? phone});
}

/// @nodoc
class __$CapabilityUserCopyWithImpl<$Res>
    implements _$CapabilityUserCopyWith<$Res> {
  __$CapabilityUserCopyWithImpl(this._self, this._then);

  final _CapabilityUser _self;
  final $Res Function(_CapabilityUser) _then;

  /// Create a copy of CapabilityUser
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? name = freezed,
    Object? phone = freezed,
  }) {
    return _then(
      _CapabilityUser(
        id: null == id
            ? _self.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: freezed == name
            ? _self.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String?,
        phone: freezed == phone
            ? _self.phone
            : phone // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
mixin _$SttStatus {
  String? get engine;
  String? get model;
  bool get ready;
  String? get error;

  /// Create a copy of SttStatus
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SttStatusCopyWith<SttStatus> get copyWith =>
      _$SttStatusCopyWithImpl<SttStatus>(this as SttStatus, _$identity);

  /// Serializes this SttStatus to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as SttStatus;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SttStatus &&
            (identical(other.engine, _this.engine) ||
                other.engine == _this.engine) &&
            (identical(other.model, _this.model) ||
                other.model == _this.model) &&
            (identical(other.ready, _this.ready) ||
                other.ready == _this.ready) &&
            (identical(other.error, _this.error) ||
                other.error == _this.error));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as SttStatus;
    return Object.hash(
      runtimeType,
      _this.engine,
      _this.model,
      _this.ready,
      _this.error,
    );
  }

  @override
  String toString() {
    final _this = this as SttStatus;
    return 'SttStatus(engine: ${_this.engine}, model: ${_this.model}, ready: ${_this.ready}, error: ${_this.error})';
  }
}

/// @nodoc
abstract mixin class $SttStatusCopyWith<$Res> {
  factory $SttStatusCopyWith(SttStatus value, $Res Function(SttStatus) _then) =
      _$SttStatusCopyWithImpl;
  @useResult
  $Res call({String? engine, String? model, bool ready, String? error});
}

/// @nodoc
class _$SttStatusCopyWithImpl<$Res> implements $SttStatusCopyWith<$Res> {
  _$SttStatusCopyWithImpl(this._self, this._then);

  final SttStatus _self;
  final $Res Function(SttStatus) _then;

  /// Create a copy of SttStatus
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? engine = freezed,
    Object? model = freezed,
    Object? ready = null,
    Object? error = freezed,
  }) {
    return _then(
      SttStatus(
        engine: freezed == engine
            ? _self.engine
            : engine // ignore: cast_nullable_to_non_nullable
                  as String?,
        model: freezed == model
            ? _self.model
            : model // ignore: cast_nullable_to_non_nullable
                  as String?,
        ready: null == ready
            ? _self.ready
            : ready // ignore: cast_nullable_to_non_nullable
                  as bool,
        error: freezed == error
            ? _self.error
            : error // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [SttStatus].
extension SttStatusPatterns on SttStatus {
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
    TResult Function(_SttStatus value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SttStatus() when $default != null:
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
    TResult Function(_SttStatus value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SttStatus():
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
    TResult? Function(_SttStatus value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SttStatus() when $default != null:
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
    TResult Function(String? engine, String? model, bool ready, String? error)?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SttStatus() when $default != null:
        return $default(_that.engine, _that.model, _that.ready, _that.error);
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
    TResult Function(String? engine, String? model, bool ready, String? error)
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SttStatus():
        return $default(_that.engine, _that.model, _that.ready, _that.error);
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
    TResult? Function(String? engine, String? model, bool ready, String? error)?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SttStatus() when $default != null:
        return $default(_that.engine, _that.model, _that.ready, _that.error);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _SttStatus implements SttStatus {
  const _SttStatus({this.engine, this.model, required this.ready, this.error});
  factory _SttStatus.fromJson(Map<String, dynamic> json) =>
      _$SttStatusFromJson(json);

  @override
  final String? engine;
  @override
  final String? model;
  @override
  final bool ready;
  @override
  final String? error;

  /// Create a copy of SttStatus
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$SttStatusCopyWith<_SttStatus> get copyWith =>
      __$SttStatusCopyWithImpl<_SttStatus>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$SttStatusToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _SttStatus &&
            (identical(other.engine, engine) || other.engine == engine) &&
            (identical(other.model, model) || other.model == model) &&
            (identical(other.ready, ready) || other.ready == ready) &&
            (identical(other.error, error) || other.error == error));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(runtimeType, engine, model, ready, error);
  }

  @override
  String toString() {
    return 'SttStatus(engine: $engine, model: $model, ready: $ready, error: $error)';
  }
}

/// @nodoc
abstract mixin class _$SttStatusCopyWith<$Res>
    implements $SttStatusCopyWith<$Res> {
  factory _$SttStatusCopyWith(
    _SttStatus value,
    $Res Function(_SttStatus) _then,
  ) = __$SttStatusCopyWithImpl;
  @override
  @useResult
  $Res call({String? engine, String? model, bool ready, String? error});
}

/// @nodoc
class __$SttStatusCopyWithImpl<$Res> implements _$SttStatusCopyWith<$Res> {
  __$SttStatusCopyWithImpl(this._self, this._then);

  final _SttStatus _self;
  final $Res Function(_SttStatus) _then;

  /// Create a copy of SttStatus
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? engine = freezed,
    Object? model = freezed,
    Object? ready = null,
    Object? error = freezed,
  }) {
    return _then(
      _SttStatus(
        engine: freezed == engine
            ? _self.engine
            : engine // ignore: cast_nullable_to_non_nullable
                  as String?,
        model: freezed == model
            ? _self.model
            : model // ignore: cast_nullable_to_non_nullable
                  as String?,
        ready: null == ready
            ? _self.ready
            : ready // ignore: cast_nullable_to_non_nullable
                  as bool,
        error: freezed == error
            ? _self.error
            : error // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
mixin _$LlmStatus {
  String? get name;
  String? get model;
  bool get ready;
  String? get error;

  /// Create a copy of LlmStatus
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $LlmStatusCopyWith<LlmStatus> get copyWith =>
      _$LlmStatusCopyWithImpl<LlmStatus>(this as LlmStatus, _$identity);

  /// Serializes this LlmStatus to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as LlmStatus;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is LlmStatus &&
            (identical(other.name, _this.name) || other.name == _this.name) &&
            (identical(other.model, _this.model) ||
                other.model == _this.model) &&
            (identical(other.ready, _this.ready) ||
                other.ready == _this.ready) &&
            (identical(other.error, _this.error) ||
                other.error == _this.error));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as LlmStatus;
    return Object.hash(
      runtimeType,
      _this.name,
      _this.model,
      _this.ready,
      _this.error,
    );
  }

  @override
  String toString() {
    final _this = this as LlmStatus;
    return 'LlmStatus(name: ${_this.name}, model: ${_this.model}, ready: ${_this.ready}, error: ${_this.error})';
  }
}

/// @nodoc
abstract mixin class $LlmStatusCopyWith<$Res> {
  factory $LlmStatusCopyWith(LlmStatus value, $Res Function(LlmStatus) _then) =
      _$LlmStatusCopyWithImpl;
  @useResult
  $Res call({String? name, String? model, bool ready, String? error});
}

/// @nodoc
class _$LlmStatusCopyWithImpl<$Res> implements $LlmStatusCopyWith<$Res> {
  _$LlmStatusCopyWithImpl(this._self, this._then);

  final LlmStatus _self;
  final $Res Function(LlmStatus) _then;

  /// Create a copy of LlmStatus
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = freezed,
    Object? model = freezed,
    Object? ready = null,
    Object? error = freezed,
  }) {
    return _then(
      LlmStatus(
        name: freezed == name
            ? _self.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String?,
        model: freezed == model
            ? _self.model
            : model // ignore: cast_nullable_to_non_nullable
                  as String?,
        ready: null == ready
            ? _self.ready
            : ready // ignore: cast_nullable_to_non_nullable
                  as bool,
        error: freezed == error
            ? _self.error
            : error // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [LlmStatus].
extension LlmStatusPatterns on LlmStatus {
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
    TResult Function(_LlmStatus value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _LlmStatus() when $default != null:
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
    TResult Function(_LlmStatus value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LlmStatus():
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
    TResult? Function(_LlmStatus value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LlmStatus() when $default != null:
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
    TResult Function(String? name, String? model, bool ready, String? error)?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _LlmStatus() when $default != null:
        return $default(_that.name, _that.model, _that.ready, _that.error);
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
    TResult Function(String? name, String? model, bool ready, String? error)
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LlmStatus():
        return $default(_that.name, _that.model, _that.ready, _that.error);
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
    TResult? Function(String? name, String? model, bool ready, String? error)?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LlmStatus() when $default != null:
        return $default(_that.name, _that.model, _that.ready, _that.error);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _LlmStatus implements LlmStatus {
  const _LlmStatus({this.name, this.model, required this.ready, this.error});
  factory _LlmStatus.fromJson(Map<String, dynamic> json) =>
      _$LlmStatusFromJson(json);

  @override
  final String? name;
  @override
  final String? model;
  @override
  final bool ready;
  @override
  final String? error;

  /// Create a copy of LlmStatus
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$LlmStatusCopyWith<_LlmStatus> get copyWith =>
      __$LlmStatusCopyWithImpl<_LlmStatus>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$LlmStatusToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _LlmStatus &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.model, model) || other.model == model) &&
            (identical(other.ready, ready) || other.ready == ready) &&
            (identical(other.error, error) || other.error == error));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(runtimeType, name, model, ready, error);
  }

  @override
  String toString() {
    return 'LlmStatus(name: $name, model: $model, ready: $ready, error: $error)';
  }
}

/// @nodoc
abstract mixin class _$LlmStatusCopyWith<$Res>
    implements $LlmStatusCopyWith<$Res> {
  factory _$LlmStatusCopyWith(
    _LlmStatus value,
    $Res Function(_LlmStatus) _then,
  ) = __$LlmStatusCopyWithImpl;
  @override
  @useResult
  $Res call({String? name, String? model, bool ready, String? error});
}

/// @nodoc
class __$LlmStatusCopyWithImpl<$Res> implements _$LlmStatusCopyWith<$Res> {
  __$LlmStatusCopyWithImpl(this._self, this._then);

  final _LlmStatus _self;
  final $Res Function(_LlmStatus) _then;

  /// Create a copy of LlmStatus
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? name = freezed,
    Object? model = freezed,
    Object? ready = null,
    Object? error = freezed,
  }) {
    return _then(
      _LlmStatus(
        name: freezed == name
            ? _self.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String?,
        model: freezed == model
            ? _self.model
            : model // ignore: cast_nullable_to_non_nullable
                  as String?,
        ready: null == ready
            ? _self.ready
            : ready // ignore: cast_nullable_to_non_nullable
                  as bool,
        error: freezed == error
            ? _self.error
            : error // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
mixin _$HeartbeatResult {
  @JsonKey(name: 'server_time')
  String? get serverTime;
  @JsonKey(name: 'server_version')
  String? get serverVersion;

  /// Create a copy of HeartbeatResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $HeartbeatResultCopyWith<HeartbeatResult> get copyWith =>
      _$HeartbeatResultCopyWithImpl<HeartbeatResult>(
        this as HeartbeatResult,
        _$identity,
      );

  /// Serializes this HeartbeatResult to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as HeartbeatResult;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is HeartbeatResult &&
            (identical(other.serverTime, _this.serverTime) ||
                other.serverTime == _this.serverTime) &&
            (identical(other.serverVersion, _this.serverVersion) ||
                other.serverVersion == _this.serverVersion));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as HeartbeatResult;
    return Object.hash(runtimeType, _this.serverTime, _this.serverVersion);
  }

  @override
  String toString() {
    final _this = this as HeartbeatResult;
    return 'HeartbeatResult(serverTime: ${_this.serverTime}, serverVersion: ${_this.serverVersion})';
  }
}

/// @nodoc
abstract mixin class $HeartbeatResultCopyWith<$Res> {
  factory $HeartbeatResultCopyWith(
    HeartbeatResult value,
    $Res Function(HeartbeatResult) _then,
  ) = _$HeartbeatResultCopyWithImpl;
  @useResult
  $Res call({
    @JsonKey(name: 'server_time') String? serverTime,
    @JsonKey(name: 'server_version') String? serverVersion,
  });
}

/// @nodoc
class _$HeartbeatResultCopyWithImpl<$Res>
    implements $HeartbeatResultCopyWith<$Res> {
  _$HeartbeatResultCopyWithImpl(this._self, this._then);

  final HeartbeatResult _self;
  final $Res Function(HeartbeatResult) _then;

  /// Create a copy of HeartbeatResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? serverTime = freezed, Object? serverVersion = freezed}) {
    return _then(
      HeartbeatResult(
        serverTime: freezed == serverTime
            ? _self.serverTime
            : serverTime // ignore: cast_nullable_to_non_nullable
                  as String?,
        serverVersion: freezed == serverVersion
            ? _self.serverVersion
            : serverVersion // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [HeartbeatResult].
extension HeartbeatResultPatterns on HeartbeatResult {
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
    TResult Function(_HeartbeatResult value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _HeartbeatResult() when $default != null:
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
    TResult Function(_HeartbeatResult value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HeartbeatResult():
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
    TResult? Function(_HeartbeatResult value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HeartbeatResult() when $default != null:
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
      @JsonKey(name: 'server_time') String? serverTime,
      @JsonKey(name: 'server_version') String? serverVersion,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _HeartbeatResult() when $default != null:
        return $default(_that.serverTime, _that.serverVersion);
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
      @JsonKey(name: 'server_time') String? serverTime,
      @JsonKey(name: 'server_version') String? serverVersion,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HeartbeatResult():
        return $default(_that.serverTime, _that.serverVersion);
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
      @JsonKey(name: 'server_time') String? serverTime,
      @JsonKey(name: 'server_version') String? serverVersion,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HeartbeatResult() when $default != null:
        return $default(_that.serverTime, _that.serverVersion);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _HeartbeatResult implements HeartbeatResult {
  const _HeartbeatResult({
    @JsonKey(name: 'server_time') this.serverTime,
    @JsonKey(name: 'server_version') this.serverVersion,
  });
  factory _HeartbeatResult.fromJson(Map<String, dynamic> json) =>
      _$HeartbeatResultFromJson(json);

  @override
  @JsonKey(name: 'server_time')
  final String? serverTime;
  @override
  @JsonKey(name: 'server_version')
  final String? serverVersion;

  /// Create a copy of HeartbeatResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$HeartbeatResultCopyWith<_HeartbeatResult> get copyWith =>
      __$HeartbeatResultCopyWithImpl<_HeartbeatResult>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$HeartbeatResultToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _HeartbeatResult &&
            (identical(other.serverTime, serverTime) ||
                other.serverTime == serverTime) &&
            (identical(other.serverVersion, serverVersion) ||
                other.serverVersion == serverVersion));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(runtimeType, serverTime, serverVersion);
  }

  @override
  String toString() {
    return 'HeartbeatResult(serverTime: $serverTime, serverVersion: $serverVersion)';
  }
}

/// @nodoc
abstract mixin class _$HeartbeatResultCopyWith<$Res>
    implements $HeartbeatResultCopyWith<$Res> {
  factory _$HeartbeatResultCopyWith(
    _HeartbeatResult value,
    $Res Function(_HeartbeatResult) _then,
  ) = __$HeartbeatResultCopyWithImpl;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'server_time') String? serverTime,
    @JsonKey(name: 'server_version') String? serverVersion,
  });
}

/// @nodoc
class __$HeartbeatResultCopyWithImpl<$Res>
    implements _$HeartbeatResultCopyWith<$Res> {
  __$HeartbeatResultCopyWithImpl(this._self, this._then);

  final _HeartbeatResult _self;
  final $Res Function(_HeartbeatResult) _then;

  /// Create a copy of HeartbeatResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({Object? serverTime = freezed, Object? serverVersion = freezed}) {
    return _then(
      _HeartbeatResult(
        serverTime: freezed == serverTime
            ? _self.serverTime
            : serverTime // ignore: cast_nullable_to_non_nullable
                  as String?,
        serverVersion: freezed == serverVersion
            ? _self.serverVersion
            : serverVersion // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}
