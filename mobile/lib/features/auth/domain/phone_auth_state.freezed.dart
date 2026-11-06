// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'phone_auth_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PhoneAuthState {
  PhoneAuthMode get mode;
  LoginMethod get method;
  String get phone;
  String get code;
  String get name;
  String get password;

  /// Repeated new password (register / reset).
  String get confirm;

  /// `POST /auth/sms/send` in flight.
  bool get sending;

  /// Seconds until a new code may be requested (0 = may send).
  int get countdown;

  /// A code was sent for the current mode/phone.
  bool get codeSent;

  /// Login/register request in flight.
  bool get submitting;
  Set<PhoneAuthIssue> get issues;

  /// Last server/network error (shown via `describeError`, server `detail` verbatim).
  ApiException? get error;

  /// `dev_code` of the last send response; only kept when `AppConfig.features.showDevCode`.
  String? get devCode;

  /// Create a copy of PhoneAuthState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PhoneAuthStateCopyWith<PhoneAuthState> get copyWith =>
      _$PhoneAuthStateCopyWithImpl<PhoneAuthState>(
        this as PhoneAuthState,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    final _this = this as PhoneAuthState;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PhoneAuthState &&
            (identical(other.mode, _this.mode) || other.mode == _this.mode) &&
            (identical(other.method, _this.method) ||
                other.method == _this.method) &&
            (identical(other.phone, _this.phone) ||
                other.phone == _this.phone) &&
            (identical(other.code, _this.code) || other.code == _this.code) &&
            (identical(other.name, _this.name) || other.name == _this.name) &&
            (identical(other.password, _this.password) ||
                other.password == _this.password) &&
            (identical(other.confirm, _this.confirm) ||
                other.confirm == _this.confirm) &&
            (identical(other.sending, _this.sending) ||
                other.sending == _this.sending) &&
            (identical(other.countdown, _this.countdown) ||
                other.countdown == _this.countdown) &&
            (identical(other.codeSent, _this.codeSent) ||
                other.codeSent == _this.codeSent) &&
            (identical(other.submitting, _this.submitting) ||
                other.submitting == _this.submitting) &&
            const DeepCollectionEquality().equals(other.issues, _this.issues) &&
            (identical(other.error, _this.error) ||
                other.error == _this.error) &&
            (identical(other.devCode, _this.devCode) ||
                other.devCode == _this.devCode));
  }

  @override
  int get hashCode {
    final _this = this as PhoneAuthState;
    return Object.hash(
      runtimeType,
      _this.mode,
      _this.method,
      _this.phone,
      _this.code,
      _this.name,
      _this.password,
      _this.confirm,
      _this.sending,
      _this.countdown,
      _this.codeSent,
      _this.submitting,
      const DeepCollectionEquality().hash(_this.issues),
      _this.error,
      _this.devCode,
    );
  }

  @override
  String toString() {
    final _this = this as PhoneAuthState;
    return 'PhoneAuthState(mode: ${_this.mode}, method: ${_this.method}, phone: ${_this.phone}, code: ${_this.code}, name: ${_this.name}, password: ${_this.password}, confirm: ${_this.confirm}, sending: ${_this.sending}, countdown: ${_this.countdown}, codeSent: ${_this.codeSent}, submitting: ${_this.submitting}, issues: ${_this.issues}, error: ${_this.error}, devCode: ${_this.devCode})';
  }
}

/// @nodoc
abstract mixin class $PhoneAuthStateCopyWith<$Res> {
  factory $PhoneAuthStateCopyWith(
    PhoneAuthState value,
    $Res Function(PhoneAuthState) _then,
  ) = _$PhoneAuthStateCopyWithImpl;
  @useResult
  $Res call({
    PhoneAuthMode mode,
    LoginMethod method,
    String phone,
    String code,
    String name,
    String password,
    String confirm,
    bool sending,
    int countdown,
    bool codeSent,
    bool submitting,
    Set<PhoneAuthIssue> issues,
    ApiException? error,
    String? devCode,
  });
}

/// @nodoc
class _$PhoneAuthStateCopyWithImpl<$Res>
    implements $PhoneAuthStateCopyWith<$Res> {
  _$PhoneAuthStateCopyWithImpl(this._self, this._then);

  final PhoneAuthState _self;
  final $Res Function(PhoneAuthState) _then;

  /// Create a copy of PhoneAuthState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? mode = null,
    Object? method = null,
    Object? phone = null,
    Object? code = null,
    Object? name = null,
    Object? password = null,
    Object? confirm = null,
    Object? sending = null,
    Object? countdown = null,
    Object? codeSent = null,
    Object? submitting = null,
    Object? issues = null,
    Object? error = freezed,
    Object? devCode = freezed,
  }) {
    return _then(
      PhoneAuthState(
        mode: null == mode
            ? _self.mode
            : mode // ignore: cast_nullable_to_non_nullable
                  as PhoneAuthMode,
        method: null == method
            ? _self.method
            : method // ignore: cast_nullable_to_non_nullable
                  as LoginMethod,
        phone: null == phone
            ? _self.phone
            : phone // ignore: cast_nullable_to_non_nullable
                  as String,
        code: null == code
            ? _self.code
            : code // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _self.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        password: null == password
            ? _self.password
            : password // ignore: cast_nullable_to_non_nullable
                  as String,
        confirm: null == confirm
            ? _self.confirm
            : confirm // ignore: cast_nullable_to_non_nullable
                  as String,
        sending: null == sending
            ? _self.sending
            : sending // ignore: cast_nullable_to_non_nullable
                  as bool,
        countdown: null == countdown
            ? _self.countdown
            : countdown // ignore: cast_nullable_to_non_nullable
                  as int,
        codeSent: null == codeSent
            ? _self.codeSent
            : codeSent // ignore: cast_nullable_to_non_nullable
                  as bool,
        submitting: null == submitting
            ? _self.submitting
            : submitting // ignore: cast_nullable_to_non_nullable
                  as bool,
        issues: null == issues
            ? _self.issues
            : issues // ignore: cast_nullable_to_non_nullable
                  as Set<PhoneAuthIssue>,
        error: freezed == error
            ? _self.error
            : error // ignore: cast_nullable_to_non_nullable
                  as ApiException?,
        devCode: freezed == devCode
            ? _self.devCode
            : devCode // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [PhoneAuthState].
extension PhoneAuthStatePatterns on PhoneAuthState {
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
    TResult Function(_PhoneAuthState value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PhoneAuthState() when $default != null:
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
    TResult Function(_PhoneAuthState value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PhoneAuthState():
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
    TResult? Function(_PhoneAuthState value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PhoneAuthState() when $default != null:
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
      PhoneAuthMode mode,
      LoginMethod method,
      String phone,
      String code,
      String name,
      String password,
      String confirm,
      bool sending,
      int countdown,
      bool codeSent,
      bool submitting,
      Set<PhoneAuthIssue> issues,
      ApiException? error,
      String? devCode,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PhoneAuthState() when $default != null:
        return $default(
          _that.mode,
          _that.method,
          _that.phone,
          _that.code,
          _that.name,
          _that.password,
          _that.confirm,
          _that.sending,
          _that.countdown,
          _that.codeSent,
          _that.submitting,
          _that.issues,
          _that.error,
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
      PhoneAuthMode mode,
      LoginMethod method,
      String phone,
      String code,
      String name,
      String password,
      String confirm,
      bool sending,
      int countdown,
      bool codeSent,
      bool submitting,
      Set<PhoneAuthIssue> issues,
      ApiException? error,
      String? devCode,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PhoneAuthState():
        return $default(
          _that.mode,
          _that.method,
          _that.phone,
          _that.code,
          _that.name,
          _that.password,
          _that.confirm,
          _that.sending,
          _that.countdown,
          _that.codeSent,
          _that.submitting,
          _that.issues,
          _that.error,
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
      PhoneAuthMode mode,
      LoginMethod method,
      String phone,
      String code,
      String name,
      String password,
      String confirm,
      bool sending,
      int countdown,
      bool codeSent,
      bool submitting,
      Set<PhoneAuthIssue> issues,
      ApiException? error,
      String? devCode,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PhoneAuthState() when $default != null:
        return $default(
          _that.mode,
          _that.method,
          _that.phone,
          _that.code,
          _that.name,
          _that.password,
          _that.confirm,
          _that.sending,
          _that.countdown,
          _that.codeSent,
          _that.submitting,
          _that.issues,
          _that.error,
          _that.devCode,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc

class _PhoneAuthState extends PhoneAuthState {
  const _PhoneAuthState({
    this.mode = PhoneAuthMode.login,
    this.method = LoginMethod.password,
    this.phone = '',
    this.code = '',
    this.name = '',
    this.password = '',
    this.confirm = '',
    this.sending = false,
    this.countdown = 0,
    this.codeSent = false,
    this.submitting = false,
    Set<PhoneAuthIssue> issues = const <PhoneAuthIssue>{},
    this.error,
    this.devCode,
  }) : _issues = issues,
       super._();

  @override
  @JsonKey()
  final PhoneAuthMode mode;
  @override
  @JsonKey()
  final LoginMethod method;
  @override
  @JsonKey()
  final String phone;
  @override
  @JsonKey()
  final String code;
  @override
  @JsonKey()
  final String name;
  @override
  @JsonKey()
  final String password;

  /// Repeated new password (register / reset).
  @override
  @JsonKey()
  final String confirm;

  /// `POST /auth/sms/send` in flight.
  @override
  @JsonKey()
  final bool sending;

  /// Seconds until a new code may be requested (0 = may send).
  @override
  @JsonKey()
  final int countdown;

  /// A code was sent for the current mode/phone.
  @override
  @JsonKey()
  final bool codeSent;

  /// Login/register request in flight.
  @override
  @JsonKey()
  final bool submitting;
  final Set<PhoneAuthIssue> _issues;
  @override
  @JsonKey()
  Set<PhoneAuthIssue> get issues {
    if (_issues is EqualUnmodifiableSetView) return _issues;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_issues);
  }

  /// Last server/network error (shown via `describeError`, server `detail` verbatim).
  @override
  final ApiException? error;

  /// `dev_code` of the last send response; only kept when `AppConfig.features.showDevCode`.
  @override
  final String? devCode;

  /// Create a copy of PhoneAuthState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PhoneAuthStateCopyWith<_PhoneAuthState> get copyWith =>
      __$PhoneAuthStateCopyWithImpl<_PhoneAuthState>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PhoneAuthState &&
            (identical(other.mode, mode) || other.mode == mode) &&
            (identical(other.method, method) || other.method == method) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.password, password) ||
                other.password == password) &&
            (identical(other.confirm, confirm) || other.confirm == confirm) &&
            (identical(other.sending, sending) || other.sending == sending) &&
            (identical(other.countdown, countdown) ||
                other.countdown == countdown) &&
            (identical(other.codeSent, codeSent) ||
                other.codeSent == codeSent) &&
            (identical(other.submitting, submitting) ||
                other.submitting == submitting) &&
            const DeepCollectionEquality().equals(other.issues, _issues) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.devCode, devCode) || other.devCode == devCode));
  }

  @override
  int get hashCode {
    return Object.hash(
      runtimeType,
      mode,
      method,
      phone,
      code,
      name,
      password,
      confirm,
      sending,
      countdown,
      codeSent,
      submitting,
      const DeepCollectionEquality().hash(_issues),
      error,
      devCode,
    );
  }

  @override
  String toString() {
    return 'PhoneAuthState(mode: $mode, method: $method, phone: $phone, code: $code, name: $name, password: $password, confirm: $confirm, sending: $sending, countdown: $countdown, codeSent: $codeSent, submitting: $submitting, issues: $issues, error: $error, devCode: $devCode)';
  }
}

/// @nodoc
abstract mixin class _$PhoneAuthStateCopyWith<$Res>
    implements $PhoneAuthStateCopyWith<$Res> {
  factory _$PhoneAuthStateCopyWith(
    _PhoneAuthState value,
    $Res Function(_PhoneAuthState) _then,
  ) = __$PhoneAuthStateCopyWithImpl;
  @override
  @useResult
  $Res call({
    PhoneAuthMode mode,
    LoginMethod method,
    String phone,
    String code,
    String name,
    String password,
    String confirm,
    bool sending,
    int countdown,
    bool codeSent,
    bool submitting,
    Set<PhoneAuthIssue> issues,
    ApiException? error,
    String? devCode,
  });
}

/// @nodoc
class __$PhoneAuthStateCopyWithImpl<$Res>
    implements _$PhoneAuthStateCopyWith<$Res> {
  __$PhoneAuthStateCopyWithImpl(this._self, this._then);

  final _PhoneAuthState _self;
  final $Res Function(_PhoneAuthState) _then;

  /// Create a copy of PhoneAuthState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? mode = null,
    Object? method = null,
    Object? phone = null,
    Object? code = null,
    Object? name = null,
    Object? password = null,
    Object? confirm = null,
    Object? sending = null,
    Object? countdown = null,
    Object? codeSent = null,
    Object? submitting = null,
    Object? issues = null,
    Object? error = freezed,
    Object? devCode = freezed,
  }) {
    return _then(
      _PhoneAuthState(
        mode: null == mode
            ? _self.mode
            : mode // ignore: cast_nullable_to_non_nullable
                  as PhoneAuthMode,
        method: null == method
            ? _self.method
            : method // ignore: cast_nullable_to_non_nullable
                  as LoginMethod,
        phone: null == phone
            ? _self.phone
            : phone // ignore: cast_nullable_to_non_nullable
                  as String,
        code: null == code
            ? _self.code
            : code // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _self.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        password: null == password
            ? _self.password
            : password // ignore: cast_nullable_to_non_nullable
                  as String,
        confirm: null == confirm
            ? _self.confirm
            : confirm // ignore: cast_nullable_to_non_nullable
                  as String,
        sending: null == sending
            ? _self.sending
            : sending // ignore: cast_nullable_to_non_nullable
                  as bool,
        countdown: null == countdown
            ? _self.countdown
            : countdown // ignore: cast_nullable_to_non_nullable
                  as int,
        codeSent: null == codeSent
            ? _self.codeSent
            : codeSent // ignore: cast_nullable_to_non_nullable
                  as bool,
        submitting: null == submitting
            ? _self.submitting
            : submitting // ignore: cast_nullable_to_non_nullable
                  as bool,
        issues: null == issues
            ? _self._issues
            : issues // ignore: cast_nullable_to_non_nullable
                  as Set<PhoneAuthIssue>,
        error: freezed == error
            ? _self.error
            : error // ignore: cast_nullable_to_non_nullable
                  as ApiException?,
        devCode: freezed == devCode
            ? _self.devCode
            : devCode // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}
