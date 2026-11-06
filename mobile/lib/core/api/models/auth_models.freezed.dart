// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$User {
  String get id;
  String? get phone;
  String get name;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @JsonKey(name: 'last_login_at')
  DateTime? get lastLoginAt;

  /// False for accounts created before passwords existed (SMS-code login only).
  @JsonKey(name: 'has_password')
  bool get hasPassword;

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $UserCopyWith<User> get copyWith =>
      _$UserCopyWithImpl<User>(this as User, _$identity);

  /// Serializes this User to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as User;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is User &&
            (identical(other.id, _this.id) || other.id == _this.id) &&
            (identical(other.phone, _this.phone) ||
                other.phone == _this.phone) &&
            (identical(other.name, _this.name) || other.name == _this.name) &&
            (identical(other.createdAt, _this.createdAt) ||
                other.createdAt == _this.createdAt) &&
            (identical(other.lastLoginAt, _this.lastLoginAt) ||
                other.lastLoginAt == _this.lastLoginAt) &&
            (identical(other.hasPassword, _this.hasPassword) ||
                other.hasPassword == _this.hasPassword));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as User;
    return Object.hash(
      runtimeType,
      _this.id,
      _this.phone,
      _this.name,
      _this.createdAt,
      _this.lastLoginAt,
      _this.hasPassword,
    );
  }

  @override
  String toString() {
    final _this = this as User;
    return 'User(id: ${_this.id}, phone: ${_this.phone}, name: ${_this.name}, createdAt: ${_this.createdAt}, lastLoginAt: ${_this.lastLoginAt}, hasPassword: ${_this.hasPassword})';
  }
}

/// @nodoc
abstract mixin class $UserCopyWith<$Res> {
  factory $UserCopyWith(User value, $Res Function(User) _then) =
      _$UserCopyWithImpl;
  @useResult
  $Res call({
    String id,
    String? phone,
    String name,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'last_login_at') DateTime? lastLoginAt,
    @JsonKey(name: 'has_password') bool hasPassword,
  });
}

/// @nodoc
class _$UserCopyWithImpl<$Res> implements $UserCopyWith<$Res> {
  _$UserCopyWithImpl(this._self, this._then);

  final User _self;
  final $Res Function(User) _then;

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? phone = freezed,
    Object? name = null,
    Object? createdAt = freezed,
    Object? lastLoginAt = freezed,
    Object? hasPassword = null,
  }) {
    return _then(
      User(
        id: null == id
            ? _self.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        phone: freezed == phone
            ? _self.phone
            : phone // ignore: cast_nullable_to_non_nullable
                  as String?,
        name: null == name
            ? _self.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        createdAt: freezed == createdAt
            ? _self.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        lastLoginAt: freezed == lastLoginAt
            ? _self.lastLoginAt
            : lastLoginAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        hasPassword: null == hasPassword
            ? _self.hasPassword
            : hasPassword // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [User].
extension UserPatterns on User {
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
    TResult Function(_User value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _User() when $default != null:
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
  TResult map<TResult extends Object?>(TResult Function(_User value) $default) {
    final _that = this;
    switch (_that) {
      case _User():
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
    TResult? Function(_User value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _User() when $default != null:
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
      String? phone,
      String name,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'last_login_at') DateTime? lastLoginAt,
      @JsonKey(name: 'has_password') bool hasPassword,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _User() when $default != null:
        return $default(
          _that.id,
          _that.phone,
          _that.name,
          _that.createdAt,
          _that.lastLoginAt,
          _that.hasPassword,
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
      String? phone,
      String name,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'last_login_at') DateTime? lastLoginAt,
      @JsonKey(name: 'has_password') bool hasPassword,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _User():
        return $default(
          _that.id,
          _that.phone,
          _that.name,
          _that.createdAt,
          _that.lastLoginAt,
          _that.hasPassword,
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
      String? phone,
      String name,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'last_login_at') DateTime? lastLoginAt,
      @JsonKey(name: 'has_password') bool hasPassword,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _User() when $default != null:
        return $default(
          _that.id,
          _that.phone,
          _that.name,
          _that.createdAt,
          _that.lastLoginAt,
          _that.hasPassword,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _User implements User {
  const _User({
    required this.id,
    this.phone,
    required this.name,
    @JsonKey(name: 'created_at') this.createdAt,
    @JsonKey(name: 'last_login_at') this.lastLoginAt,
    @JsonKey(name: 'has_password') this.hasPassword = false,
  });
  factory _User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  @override
  final String id;
  @override
  final String? phone;
  @override
  final String name;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @override
  @JsonKey(name: 'last_login_at')
  final DateTime? lastLoginAt;

  /// False for accounts created before passwords existed (SMS-code login only).
  @override
  @JsonKey(name: 'has_password')
  final bool hasPassword;

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$UserCopyWith<_User> get copyWith =>
      __$UserCopyWithImpl<_User>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$UserToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _User &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.lastLoginAt, lastLoginAt) ||
                other.lastLoginAt == lastLoginAt) &&
            (identical(other.hasPassword, hasPassword) ||
                other.hasPassword == hasPassword));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(
      runtimeType,
      id,
      phone,
      name,
      createdAt,
      lastLoginAt,
      hasPassword,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, phone: $phone, name: $name, createdAt: $createdAt, lastLoginAt: $lastLoginAt, hasPassword: $hasPassword)';
  }
}

/// @nodoc
abstract mixin class _$UserCopyWith<$Res> implements $UserCopyWith<$Res> {
  factory _$UserCopyWith(_User value, $Res Function(_User) _then) =
      __$UserCopyWithImpl;
  @override
  @useResult
  $Res call({
    String id,
    String? phone,
    String name,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'last_login_at') DateTime? lastLoginAt,
    @JsonKey(name: 'has_password') bool hasPassword,
  });
}

/// @nodoc
class __$UserCopyWithImpl<$Res> implements _$UserCopyWith<$Res> {
  __$UserCopyWithImpl(this._self, this._then);

  final _User _self;
  final $Res Function(_User) _then;

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? phone = freezed,
    Object? name = null,
    Object? createdAt = freezed,
    Object? lastLoginAt = freezed,
    Object? hasPassword = null,
  }) {
    return _then(
      _User(
        id: null == id
            ? _self.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        phone: freezed == phone
            ? _self.phone
            : phone // ignore: cast_nullable_to_non_nullable
                  as String?,
        name: null == name
            ? _self.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        createdAt: freezed == createdAt
            ? _self.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        lastLoginAt: freezed == lastLoginAt
            ? _self.lastLoginAt
            : lastLoginAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        hasPassword: null == hasPassword
            ? _self.hasPassword
            : hasPassword // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
mixin _$AuthConfig {
  @JsonKey(name: 'registration_open')
  bool get registrationOpen;
  @JsonKey(name: 'sms_ready')
  bool get smsReady;
  @JsonKey(name: 'code_length')
  int get codeLength;
  @JsonKey(name: 'resend_interval_sec')
  int get resendIntervalSec;

  /// Password length limits; null on older servers (`AppConfig.auth` defaults apply).
  @JsonKey(name: 'password_min_length')
  int? get passwordMinLength;
  @JsonKey(name: 'password_max_length')
  int? get passwordMaxLength;
  @JsonKey(name: 'server_version')
  String get serverVersion;

  /// Create a copy of AuthConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $AuthConfigCopyWith<AuthConfig> get copyWith =>
      _$AuthConfigCopyWithImpl<AuthConfig>(this as AuthConfig, _$identity);

  /// Serializes this AuthConfig to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as AuthConfig;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AuthConfig &&
            (identical(other.registrationOpen, _this.registrationOpen) ||
                other.registrationOpen == _this.registrationOpen) &&
            (identical(other.smsReady, _this.smsReady) ||
                other.smsReady == _this.smsReady) &&
            (identical(other.codeLength, _this.codeLength) ||
                other.codeLength == _this.codeLength) &&
            (identical(other.resendIntervalSec, _this.resendIntervalSec) ||
                other.resendIntervalSec == _this.resendIntervalSec) &&
            (identical(other.passwordMinLength, _this.passwordMinLength) ||
                other.passwordMinLength == _this.passwordMinLength) &&
            (identical(other.passwordMaxLength, _this.passwordMaxLength) ||
                other.passwordMaxLength == _this.passwordMaxLength) &&
            (identical(other.serverVersion, _this.serverVersion) ||
                other.serverVersion == _this.serverVersion));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as AuthConfig;
    return Object.hash(
      runtimeType,
      _this.registrationOpen,
      _this.smsReady,
      _this.codeLength,
      _this.resendIntervalSec,
      _this.passwordMinLength,
      _this.passwordMaxLength,
      _this.serverVersion,
    );
  }

  @override
  String toString() {
    final _this = this as AuthConfig;
    return 'AuthConfig(registrationOpen: ${_this.registrationOpen}, smsReady: ${_this.smsReady}, codeLength: ${_this.codeLength}, resendIntervalSec: ${_this.resendIntervalSec}, passwordMinLength: ${_this.passwordMinLength}, passwordMaxLength: ${_this.passwordMaxLength}, serverVersion: ${_this.serverVersion})';
  }
}

/// @nodoc
abstract mixin class $AuthConfigCopyWith<$Res> {
  factory $AuthConfigCopyWith(
    AuthConfig value,
    $Res Function(AuthConfig) _then,
  ) = _$AuthConfigCopyWithImpl;
  @useResult
  $Res call({
    @JsonKey(name: 'registration_open') bool registrationOpen,
    @JsonKey(name: 'sms_ready') bool smsReady,
    @JsonKey(name: 'code_length') int codeLength,
    @JsonKey(name: 'resend_interval_sec') int resendIntervalSec,
    @JsonKey(name: 'password_min_length') int? passwordMinLength,
    @JsonKey(name: 'password_max_length') int? passwordMaxLength,
    @JsonKey(name: 'server_version') String serverVersion,
  });
}

/// @nodoc
class _$AuthConfigCopyWithImpl<$Res> implements $AuthConfigCopyWith<$Res> {
  _$AuthConfigCopyWithImpl(this._self, this._then);

  final AuthConfig _self;
  final $Res Function(AuthConfig) _then;

  /// Create a copy of AuthConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? registrationOpen = null,
    Object? smsReady = null,
    Object? codeLength = null,
    Object? resendIntervalSec = null,
    Object? passwordMinLength = freezed,
    Object? passwordMaxLength = freezed,
    Object? serverVersion = null,
  }) {
    return _then(
      AuthConfig(
        registrationOpen: null == registrationOpen
            ? _self.registrationOpen
            : registrationOpen // ignore: cast_nullable_to_non_nullable
                  as bool,
        smsReady: null == smsReady
            ? _self.smsReady
            : smsReady // ignore: cast_nullable_to_non_nullable
                  as bool,
        codeLength: null == codeLength
            ? _self.codeLength
            : codeLength // ignore: cast_nullable_to_non_nullable
                  as int,
        resendIntervalSec: null == resendIntervalSec
            ? _self.resendIntervalSec
            : resendIntervalSec // ignore: cast_nullable_to_non_nullable
                  as int,
        passwordMinLength: freezed == passwordMinLength
            ? _self.passwordMinLength
            : passwordMinLength // ignore: cast_nullable_to_non_nullable
                  as int?,
        passwordMaxLength: freezed == passwordMaxLength
            ? _self.passwordMaxLength
            : passwordMaxLength // ignore: cast_nullable_to_non_nullable
                  as int?,
        serverVersion: null == serverVersion
            ? _self.serverVersion
            : serverVersion // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [AuthConfig].
extension AuthConfigPatterns on AuthConfig {
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
    TResult Function(_AuthConfig value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AuthConfig() when $default != null:
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
    TResult Function(_AuthConfig value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AuthConfig():
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
    TResult? Function(_AuthConfig value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AuthConfig() when $default != null:
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
      @JsonKey(name: 'registration_open') bool registrationOpen,
      @JsonKey(name: 'sms_ready') bool smsReady,
      @JsonKey(name: 'code_length') int codeLength,
      @JsonKey(name: 'resend_interval_sec') int resendIntervalSec,
      @JsonKey(name: 'password_min_length') int? passwordMinLength,
      @JsonKey(name: 'password_max_length') int? passwordMaxLength,
      @JsonKey(name: 'server_version') String serverVersion,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AuthConfig() when $default != null:
        return $default(
          _that.registrationOpen,
          _that.smsReady,
          _that.codeLength,
          _that.resendIntervalSec,
          _that.passwordMinLength,
          _that.passwordMaxLength,
          _that.serverVersion,
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
      @JsonKey(name: 'registration_open') bool registrationOpen,
      @JsonKey(name: 'sms_ready') bool smsReady,
      @JsonKey(name: 'code_length') int codeLength,
      @JsonKey(name: 'resend_interval_sec') int resendIntervalSec,
      @JsonKey(name: 'password_min_length') int? passwordMinLength,
      @JsonKey(name: 'password_max_length') int? passwordMaxLength,
      @JsonKey(name: 'server_version') String serverVersion,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AuthConfig():
        return $default(
          _that.registrationOpen,
          _that.smsReady,
          _that.codeLength,
          _that.resendIntervalSec,
          _that.passwordMinLength,
          _that.passwordMaxLength,
          _that.serverVersion,
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
      @JsonKey(name: 'registration_open') bool registrationOpen,
      @JsonKey(name: 'sms_ready') bool smsReady,
      @JsonKey(name: 'code_length') int codeLength,
      @JsonKey(name: 'resend_interval_sec') int resendIntervalSec,
      @JsonKey(name: 'password_min_length') int? passwordMinLength,
      @JsonKey(name: 'password_max_length') int? passwordMaxLength,
      @JsonKey(name: 'server_version') String serverVersion,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AuthConfig() when $default != null:
        return $default(
          _that.registrationOpen,
          _that.smsReady,
          _that.codeLength,
          _that.resendIntervalSec,
          _that.passwordMinLength,
          _that.passwordMaxLength,
          _that.serverVersion,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _AuthConfig implements AuthConfig {
  const _AuthConfig({
    @JsonKey(name: 'registration_open') required this.registrationOpen,
    @JsonKey(name: 'sms_ready') required this.smsReady,
    @JsonKey(name: 'code_length') required this.codeLength,
    @JsonKey(name: 'resend_interval_sec') required this.resendIntervalSec,
    @JsonKey(name: 'password_min_length') this.passwordMinLength,
    @JsonKey(name: 'password_max_length') this.passwordMaxLength,
    @JsonKey(name: 'server_version') required this.serverVersion,
  });
  factory _AuthConfig.fromJson(Map<String, dynamic> json) =>
      _$AuthConfigFromJson(json);

  @override
  @JsonKey(name: 'registration_open')
  final bool registrationOpen;
  @override
  @JsonKey(name: 'sms_ready')
  final bool smsReady;
  @override
  @JsonKey(name: 'code_length')
  final int codeLength;
  @override
  @JsonKey(name: 'resend_interval_sec')
  final int resendIntervalSec;

  /// Password length limits; null on older servers (`AppConfig.auth` defaults apply).
  @override
  @JsonKey(name: 'password_min_length')
  final int? passwordMinLength;
  @override
  @JsonKey(name: 'password_max_length')
  final int? passwordMaxLength;
  @override
  @JsonKey(name: 'server_version')
  final String serverVersion;

  /// Create a copy of AuthConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$AuthConfigCopyWith<_AuthConfig> get copyWith =>
      __$AuthConfigCopyWithImpl<_AuthConfig>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$AuthConfigToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _AuthConfig &&
            (identical(other.registrationOpen, registrationOpen) ||
                other.registrationOpen == registrationOpen) &&
            (identical(other.smsReady, smsReady) ||
                other.smsReady == smsReady) &&
            (identical(other.codeLength, codeLength) ||
                other.codeLength == codeLength) &&
            (identical(other.resendIntervalSec, resendIntervalSec) ||
                other.resendIntervalSec == resendIntervalSec) &&
            (identical(other.passwordMinLength, passwordMinLength) ||
                other.passwordMinLength == passwordMinLength) &&
            (identical(other.passwordMaxLength, passwordMaxLength) ||
                other.passwordMaxLength == passwordMaxLength) &&
            (identical(other.serverVersion, serverVersion) ||
                other.serverVersion == serverVersion));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(
      runtimeType,
      registrationOpen,
      smsReady,
      codeLength,
      resendIntervalSec,
      passwordMinLength,
      passwordMaxLength,
      serverVersion,
    );
  }

  @override
  String toString() {
    return 'AuthConfig(registrationOpen: $registrationOpen, smsReady: $smsReady, codeLength: $codeLength, resendIntervalSec: $resendIntervalSec, passwordMinLength: $passwordMinLength, passwordMaxLength: $passwordMaxLength, serverVersion: $serverVersion)';
  }
}

/// @nodoc
abstract mixin class _$AuthConfigCopyWith<$Res>
    implements $AuthConfigCopyWith<$Res> {
  factory _$AuthConfigCopyWith(
    _AuthConfig value,
    $Res Function(_AuthConfig) _then,
  ) = __$AuthConfigCopyWithImpl;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'registration_open') bool registrationOpen,
    @JsonKey(name: 'sms_ready') bool smsReady,
    @JsonKey(name: 'code_length') int codeLength,
    @JsonKey(name: 'resend_interval_sec') int resendIntervalSec,
    @JsonKey(name: 'password_min_length') int? passwordMinLength,
    @JsonKey(name: 'password_max_length') int? passwordMaxLength,
    @JsonKey(name: 'server_version') String serverVersion,
  });
}

/// @nodoc
class __$AuthConfigCopyWithImpl<$Res> implements _$AuthConfigCopyWith<$Res> {
  __$AuthConfigCopyWithImpl(this._self, this._then);

  final _AuthConfig _self;
  final $Res Function(_AuthConfig) _then;

  /// Create a copy of AuthConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? registrationOpen = null,
    Object? smsReady = null,
    Object? codeLength = null,
    Object? resendIntervalSec = null,
    Object? passwordMinLength = freezed,
    Object? passwordMaxLength = freezed,
    Object? serverVersion = null,
  }) {
    return _then(
      _AuthConfig(
        registrationOpen: null == registrationOpen
            ? _self.registrationOpen
            : registrationOpen // ignore: cast_nullable_to_non_nullable
                  as bool,
        smsReady: null == smsReady
            ? _self.smsReady
            : smsReady // ignore: cast_nullable_to_non_nullable
                  as bool,
        codeLength: null == codeLength
            ? _self.codeLength
            : codeLength // ignore: cast_nullable_to_non_nullable
                  as int,
        resendIntervalSec: null == resendIntervalSec
            ? _self.resendIntervalSec
            : resendIntervalSec // ignore: cast_nullable_to_non_nullable
                  as int,
        passwordMinLength: freezed == passwordMinLength
            ? _self.passwordMinLength
            : passwordMinLength // ignore: cast_nullable_to_non_nullable
                  as int?,
        passwordMaxLength: freezed == passwordMaxLength
            ? _self.passwordMaxLength
            : passwordMaxLength // ignore: cast_nullable_to_non_nullable
                  as int?,
        serverVersion: null == serverVersion
            ? _self.serverVersion
            : serverVersion // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
mixin _$SendCodeResult {
  bool get sent;
  @JsonKey(name: 'resend_after_sec')
  int get resendAfterSec;
  @JsonKey(name: 'expires_in_sec')
  int get expiresInSec;
  @JsonKey(name: 'dev_code')
  String? get devCode;

  /// Create a copy of SendCodeResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SendCodeResultCopyWith<SendCodeResult> get copyWith =>
      _$SendCodeResultCopyWithImpl<SendCodeResult>(
        this as SendCodeResult,
        _$identity,
      );

  /// Serializes this SendCodeResult to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as SendCodeResult;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SendCodeResult &&
            (identical(other.sent, _this.sent) || other.sent == _this.sent) &&
            (identical(other.resendAfterSec, _this.resendAfterSec) ||
                other.resendAfterSec == _this.resendAfterSec) &&
            (identical(other.expiresInSec, _this.expiresInSec) ||
                other.expiresInSec == _this.expiresInSec) &&
            (identical(other.devCode, _this.devCode) ||
                other.devCode == _this.devCode));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as SendCodeResult;
    return Object.hash(
      runtimeType,
      _this.sent,
      _this.resendAfterSec,
      _this.expiresInSec,
      _this.devCode,
    );
  }

  @override
  String toString() {
    final _this = this as SendCodeResult;
    return 'SendCodeResult(sent: ${_this.sent}, resendAfterSec: ${_this.resendAfterSec}, expiresInSec: ${_this.expiresInSec}, devCode: ${_this.devCode})';
  }
}

/// @nodoc
abstract mixin class $SendCodeResultCopyWith<$Res> {
  factory $SendCodeResultCopyWith(
    SendCodeResult value,
    $Res Function(SendCodeResult) _then,
  ) = _$SendCodeResultCopyWithImpl;
  @useResult
  $Res call({
    bool sent,
    @JsonKey(name: 'resend_after_sec') int resendAfterSec,
    @JsonKey(name: 'expires_in_sec') int expiresInSec,
    @JsonKey(name: 'dev_code') String? devCode,
  });
}

/// @nodoc
class _$SendCodeResultCopyWithImpl<$Res>
    implements $SendCodeResultCopyWith<$Res> {
  _$SendCodeResultCopyWithImpl(this._self, this._then);

  final SendCodeResult _self;
  final $Res Function(SendCodeResult) _then;

  /// Create a copy of SendCodeResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sent = null,
    Object? resendAfterSec = null,
    Object? expiresInSec = null,
    Object? devCode = freezed,
  }) {
    return _then(
      SendCodeResult(
        sent: null == sent
            ? _self.sent
            : sent // ignore: cast_nullable_to_non_nullable
                  as bool,
        resendAfterSec: null == resendAfterSec
            ? _self.resendAfterSec
            : resendAfterSec // ignore: cast_nullable_to_non_nullable
                  as int,
        expiresInSec: null == expiresInSec
            ? _self.expiresInSec
            : expiresInSec // ignore: cast_nullable_to_non_nullable
                  as int,
        devCode: freezed == devCode
            ? _self.devCode
            : devCode // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [SendCodeResult].
extension SendCodeResultPatterns on SendCodeResult {
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
    TResult Function(_SendCodeResult value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SendCodeResult() when $default != null:
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
    TResult Function(_SendCodeResult value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SendCodeResult():
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
    TResult? Function(_SendCodeResult value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SendCodeResult() when $default != null:
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
      bool sent,
      @JsonKey(name: 'resend_after_sec') int resendAfterSec,
      @JsonKey(name: 'expires_in_sec') int expiresInSec,
      @JsonKey(name: 'dev_code') String? devCode,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SendCodeResult() when $default != null:
        return $default(
          _that.sent,
          _that.resendAfterSec,
          _that.expiresInSec,
          _that.devCode,
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
      bool sent,
      @JsonKey(name: 'resend_after_sec') int resendAfterSec,
      @JsonKey(name: 'expires_in_sec') int expiresInSec,
      @JsonKey(name: 'dev_code') String? devCode,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SendCodeResult():
        return $default(
          _that.sent,
          _that.resendAfterSec,
          _that.expiresInSec,
          _that.devCode,
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
      bool sent,
      @JsonKey(name: 'resend_after_sec') int resendAfterSec,
      @JsonKey(name: 'expires_in_sec') int expiresInSec,
      @JsonKey(name: 'dev_code') String? devCode,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SendCodeResult() when $default != null:
        return $default(
          _that.sent,
          _that.resendAfterSec,
          _that.expiresInSec,
          _that.devCode,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _SendCodeResult implements SendCodeResult {
  const _SendCodeResult({
    required this.sent,
    @JsonKey(name: 'resend_after_sec') required this.resendAfterSec,
    @JsonKey(name: 'expires_in_sec') required this.expiresInSec,
    @JsonKey(name: 'dev_code') this.devCode,
  });
  factory _SendCodeResult.fromJson(Map<String, dynamic> json) =>
      _$SendCodeResultFromJson(json);

  @override
  final bool sent;
  @override
  @JsonKey(name: 'resend_after_sec')
  final int resendAfterSec;
  @override
  @JsonKey(name: 'expires_in_sec')
  final int expiresInSec;
  @override
  @JsonKey(name: 'dev_code')
  final String? devCode;

  /// Create a copy of SendCodeResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$SendCodeResultCopyWith<_SendCodeResult> get copyWith =>
      __$SendCodeResultCopyWithImpl<_SendCodeResult>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$SendCodeResultToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _SendCodeResult &&
            (identical(other.sent, sent) || other.sent == sent) &&
            (identical(other.resendAfterSec, resendAfterSec) ||
                other.resendAfterSec == resendAfterSec) &&
            (identical(other.expiresInSec, expiresInSec) ||
                other.expiresInSec == expiresInSec) &&
            (identical(other.devCode, devCode) || other.devCode == devCode));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(
      runtimeType,
      sent,
      resendAfterSec,
      expiresInSec,
      devCode,
    );
  }

  @override
  String toString() {
    return 'SendCodeResult(sent: $sent, resendAfterSec: $resendAfterSec, expiresInSec: $expiresInSec, devCode: $devCode)';
  }
}

/// @nodoc
abstract mixin class _$SendCodeResultCopyWith<$Res>
    implements $SendCodeResultCopyWith<$Res> {
  factory _$SendCodeResultCopyWith(
    _SendCodeResult value,
    $Res Function(_SendCodeResult) _then,
  ) = __$SendCodeResultCopyWithImpl;
  @override
  @useResult
  $Res call({
    bool sent,
    @JsonKey(name: 'resend_after_sec') int resendAfterSec,
    @JsonKey(name: 'expires_in_sec') int expiresInSec,
    @JsonKey(name: 'dev_code') String? devCode,
  });
}

/// @nodoc
class __$SendCodeResultCopyWithImpl<$Res>
    implements _$SendCodeResultCopyWith<$Res> {
  __$SendCodeResultCopyWithImpl(this._self, this._then);

  final _SendCodeResult _self;
  final $Res Function(_SendCodeResult) _then;

  /// Create a copy of SendCodeResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? sent = null,
    Object? resendAfterSec = null,
    Object? expiresInSec = null,
    Object? devCode = freezed,
  }) {
    return _then(
      _SendCodeResult(
        sent: null == sent
            ? _self.sent
            : sent // ignore: cast_nullable_to_non_nullable
                  as bool,
        resendAfterSec: null == resendAfterSec
            ? _self.resendAfterSec
            : resendAfterSec // ignore: cast_nullable_to_non_nullable
                  as int,
        expiresInSec: null == expiresInSec
            ? _self.expiresInSec
            : expiresInSec // ignore: cast_nullable_to_non_nullable
                  as int,
        devCode: freezed == devCode
            ? _self.devCode
            : devCode // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
mixin _$AuthResult {
  String get token;
  @JsonKey(name: 'expires_at')
  DateTime? get expiresAt;
  User get user;

  /// Create a copy of AuthResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $AuthResultCopyWith<AuthResult> get copyWith =>
      _$AuthResultCopyWithImpl<AuthResult>(this as AuthResult, _$identity);

  /// Serializes this AuthResult to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as AuthResult;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AuthResult &&
            (identical(other.token, _this.token) ||
                other.token == _this.token) &&
            (identical(other.expiresAt, _this.expiresAt) ||
                other.expiresAt == _this.expiresAt) &&
            (identical(other.user, _this.user) || other.user == _this.user));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as AuthResult;
    return Object.hash(runtimeType, _this.token, _this.expiresAt, _this.user);
  }

  @override
  String toString() {
    final _this = this as AuthResult;
    return 'AuthResult(token: ${_this.token}, expiresAt: ${_this.expiresAt}, user: ${_this.user})';
  }
}

/// @nodoc
abstract mixin class $AuthResultCopyWith<$Res> {
  factory $AuthResultCopyWith(
    AuthResult value,
    $Res Function(AuthResult) _then,
  ) = _$AuthResultCopyWithImpl;
  @useResult
  $Res call({
    String token,
    @JsonKey(name: 'expires_at') DateTime? expiresAt,
    User user,
  });

  $UserCopyWith<$Res> get user;
}

/// @nodoc
class _$AuthResultCopyWithImpl<$Res> implements $AuthResultCopyWith<$Res> {
  _$AuthResultCopyWithImpl(this._self, this._then);

  final AuthResult _self;
  final $Res Function(AuthResult) _then;

  /// Create a copy of AuthResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? token = null,
    Object? expiresAt = freezed,
    Object? user = null,
  }) {
    return _then(
      AuthResult(
        token: null == token
            ? _self.token
            : token // ignore: cast_nullable_to_non_nullable
                  as String,
        expiresAt: freezed == expiresAt
            ? _self.expiresAt
            : expiresAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        user: null == user
            ? _self.user
            : user // ignore: cast_nullable_to_non_nullable
                  as User,
      ),
    );
  }

  /// Create a copy of AuthResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $UserCopyWith<$Res> get user {
    return $UserCopyWith<$Res>(_self.user, (value) {
      return _then(_self.copyWith(user: value));
    });
  }
}

/// Adds pattern-matching-related methods to [AuthResult].
extension AuthResultPatterns on AuthResult {
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
    TResult Function(_AuthResult value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AuthResult() when $default != null:
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
    TResult Function(_AuthResult value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AuthResult():
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
    TResult? Function(_AuthResult value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AuthResult() when $default != null:
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
      String token,
      @JsonKey(name: 'expires_at') DateTime? expiresAt,
      User user,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AuthResult() when $default != null:
        return $default(_that.token, _that.expiresAt, _that.user);
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
      String token,
      @JsonKey(name: 'expires_at') DateTime? expiresAt,
      User user,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AuthResult():
        return $default(_that.token, _that.expiresAt, _that.user);
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
      String token,
      @JsonKey(name: 'expires_at') DateTime? expiresAt,
      User user,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AuthResult() when $default != null:
        return $default(_that.token, _that.expiresAt, _that.user);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _AuthResult implements AuthResult {
  const _AuthResult({
    required this.token,
    @JsonKey(name: 'expires_at') this.expiresAt,
    required this.user,
  });
  factory _AuthResult.fromJson(Map<String, dynamic> json) =>
      _$AuthResultFromJson(json);

  @override
  final String token;
  @override
  @JsonKey(name: 'expires_at')
  final DateTime? expiresAt;
  @override
  final User user;

  /// Create a copy of AuthResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$AuthResultCopyWith<_AuthResult> get copyWith =>
      __$AuthResultCopyWithImpl<_AuthResult>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$AuthResultToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _AuthResult &&
            (identical(other.token, token) || other.token == token) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt) &&
            (identical(other.user, user) || other.user == user));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(runtimeType, token, expiresAt, user);
  }

  @override
  String toString() {
    return 'AuthResult(token: $token, expiresAt: $expiresAt, user: $user)';
  }
}

/// @nodoc
abstract mixin class _$AuthResultCopyWith<$Res>
    implements $AuthResultCopyWith<$Res> {
  factory _$AuthResultCopyWith(
    _AuthResult value,
    $Res Function(_AuthResult) _then,
  ) = __$AuthResultCopyWithImpl;
  @override
  @useResult
  $Res call({
    String token,
    @JsonKey(name: 'expires_at') DateTime? expiresAt,
    User user,
  });

  @override
  $UserCopyWith<$Res> get user;
}

/// @nodoc
class __$AuthResultCopyWithImpl<$Res> implements _$AuthResultCopyWith<$Res> {
  __$AuthResultCopyWithImpl(this._self, this._then);

  final _AuthResult _self;
  final $Res Function(_AuthResult) _then;

  /// Create a copy of AuthResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? token = null,
    Object? expiresAt = freezed,
    Object? user = null,
  }) {
    return _then(
      _AuthResult(
        token: null == token
            ? _self.token
            : token // ignore: cast_nullable_to_non_nullable
                  as String,
        expiresAt: freezed == expiresAt
            ? _self.expiresAt
            : expiresAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        user: null == user
            ? _self.user
            : user // ignore: cast_nullable_to_non_nullable
                  as User,
      ),
    );
  }

  /// Create a copy of AuthResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $UserCopyWith<$Res> get user {
    return $UserCopyWith<$Res>(_self.user, (value) {
      return _then(_self.copyWith(user: value));
    });
  }
}

/// @nodoc
mixin _$ClientInfo {
  @JsonKey(name: 'client_id')
  String get clientId;
  String get hostname;

  /// `android` | `ios`.
  String get os;
  @JsonKey(name: 'app_version')
  String get appVersion;

  /// Create a copy of ClientInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ClientInfoCopyWith<ClientInfo> get copyWith =>
      _$ClientInfoCopyWithImpl<ClientInfo>(this as ClientInfo, _$identity);

  /// Serializes this ClientInfo to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as ClientInfo;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ClientInfo &&
            (identical(other.clientId, _this.clientId) ||
                other.clientId == _this.clientId) &&
            (identical(other.hostname, _this.hostname) ||
                other.hostname == _this.hostname) &&
            (identical(other.os, _this.os) || other.os == _this.os) &&
            (identical(other.appVersion, _this.appVersion) ||
                other.appVersion == _this.appVersion));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as ClientInfo;
    return Object.hash(
      runtimeType,
      _this.clientId,
      _this.hostname,
      _this.os,
      _this.appVersion,
    );
  }

  @override
  String toString() {
    final _this = this as ClientInfo;
    return 'ClientInfo(clientId: ${_this.clientId}, hostname: ${_this.hostname}, os: ${_this.os}, appVersion: ${_this.appVersion})';
  }
}

/// @nodoc
abstract mixin class $ClientInfoCopyWith<$Res> {
  factory $ClientInfoCopyWith(
    ClientInfo value,
    $Res Function(ClientInfo) _then,
  ) = _$ClientInfoCopyWithImpl;
  @useResult
  $Res call({
    @JsonKey(name: 'client_id') String clientId,
    String hostname,
    String os,
    @JsonKey(name: 'app_version') String appVersion,
  });
}

/// @nodoc
class _$ClientInfoCopyWithImpl<$Res> implements $ClientInfoCopyWith<$Res> {
  _$ClientInfoCopyWithImpl(this._self, this._then);

  final ClientInfo _self;
  final $Res Function(ClientInfo) _then;

  /// Create a copy of ClientInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? clientId = null,
    Object? hostname = null,
    Object? os = null,
    Object? appVersion = null,
  }) {
    return _then(
      ClientInfo(
        clientId: null == clientId
            ? _self.clientId
            : clientId // ignore: cast_nullable_to_non_nullable
                  as String,
        hostname: null == hostname
            ? _self.hostname
            : hostname // ignore: cast_nullable_to_non_nullable
                  as String,
        os: null == os
            ? _self.os
            : os // ignore: cast_nullable_to_non_nullable
                  as String,
        appVersion: null == appVersion
            ? _self.appVersion
            : appVersion // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [ClientInfo].
extension ClientInfoPatterns on ClientInfo {
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
    TResult Function(_ClientInfo value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ClientInfo() when $default != null:
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
    TResult Function(_ClientInfo value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ClientInfo():
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
    TResult? Function(_ClientInfo value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ClientInfo() when $default != null:
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
      @JsonKey(name: 'client_id') String clientId,
      String hostname,
      String os,
      @JsonKey(name: 'app_version') String appVersion,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ClientInfo() when $default != null:
        return $default(
          _that.clientId,
          _that.hostname,
          _that.os,
          _that.appVersion,
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
      @JsonKey(name: 'client_id') String clientId,
      String hostname,
      String os,
      @JsonKey(name: 'app_version') String appVersion,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ClientInfo():
        return $default(
          _that.clientId,
          _that.hostname,
          _that.os,
          _that.appVersion,
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
      @JsonKey(name: 'client_id') String clientId,
      String hostname,
      String os,
      @JsonKey(name: 'app_version') String appVersion,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ClientInfo() when $default != null:
        return $default(
          _that.clientId,
          _that.hostname,
          _that.os,
          _that.appVersion,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _ClientInfo implements ClientInfo {
  const _ClientInfo({
    @JsonKey(name: 'client_id') required this.clientId,
    required this.hostname,
    required this.os,
    @JsonKey(name: 'app_version') required this.appVersion,
  });
  factory _ClientInfo.fromJson(Map<String, dynamic> json) =>
      _$ClientInfoFromJson(json);

  @override
  @JsonKey(name: 'client_id')
  final String clientId;
  @override
  final String hostname;

  /// `android` | `ios`.
  @override
  final String os;
  @override
  @JsonKey(name: 'app_version')
  final String appVersion;

  /// Create a copy of ClientInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ClientInfoCopyWith<_ClientInfo> get copyWith =>
      __$ClientInfoCopyWithImpl<_ClientInfo>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ClientInfoToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ClientInfo &&
            (identical(other.clientId, clientId) ||
                other.clientId == clientId) &&
            (identical(other.hostname, hostname) ||
                other.hostname == hostname) &&
            (identical(other.os, os) || other.os == os) &&
            (identical(other.appVersion, appVersion) ||
                other.appVersion == appVersion));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(runtimeType, clientId, hostname, os, appVersion);
  }

  @override
  String toString() {
    return 'ClientInfo(clientId: $clientId, hostname: $hostname, os: $os, appVersion: $appVersion)';
  }
}

/// @nodoc
abstract mixin class _$ClientInfoCopyWith<$Res>
    implements $ClientInfoCopyWith<$Res> {
  factory _$ClientInfoCopyWith(
    _ClientInfo value,
    $Res Function(_ClientInfo) _then,
  ) = __$ClientInfoCopyWithImpl;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'client_id') String clientId,
    String hostname,
    String os,
    @JsonKey(name: 'app_version') String appVersion,
  });
}

/// @nodoc
class __$ClientInfoCopyWithImpl<$Res> implements _$ClientInfoCopyWith<$Res> {
  __$ClientInfoCopyWithImpl(this._self, this._then);

  final _ClientInfo _self;
  final $Res Function(_ClientInfo) _then;

  /// Create a copy of ClientInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? clientId = null,
    Object? hostname = null,
    Object? os = null,
    Object? appVersion = null,
  }) {
    return _then(
      _ClientInfo(
        clientId: null == clientId
            ? _self.clientId
            : clientId // ignore: cast_nullable_to_non_nullable
                  as String,
        hostname: null == hostname
            ? _self.hostname
            : hostname // ignore: cast_nullable_to_non_nullable
                  as String,
        os: null == os
            ? _self.os
            : os // ignore: cast_nullable_to_non_nullable
                  as String,
        appVersion: null == appVersion
            ? _self.appVersion
            : appVersion // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}
