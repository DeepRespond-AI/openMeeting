// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AuthState {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is AuthState);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'AuthState()';
  }
}

/// @nodoc
class $AuthStateCopyWith<$Res> {
  $AuthStateCopyWith(AuthState _, $Res Function(AuthState) __);
}

/// Adds pattern-matching-related methods to [AuthState].
extension AuthStatePatterns on AuthState {
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
    TResult Function(AuthUnconfigured value)? unconfigured,
    TResult Function(AuthSignedOut value)? signedOut,
    TResult Function(AuthSignedIn value)? signedIn,
    TResult Function(AuthExpired value)? expired,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case AuthUnconfigured() when unconfigured != null:
        return unconfigured(_that);
      case AuthSignedOut() when signedOut != null:
        return signedOut(_that);
      case AuthSignedIn() when signedIn != null:
        return signedIn(_that);
      case AuthExpired() when expired != null:
        return expired(_that);
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
    required TResult Function(AuthUnconfigured value) unconfigured,
    required TResult Function(AuthSignedOut value) signedOut,
    required TResult Function(AuthSignedIn value) signedIn,
    required TResult Function(AuthExpired value) expired,
  }) {
    final _that = this;
    switch (_that) {
      case AuthUnconfigured():
        return unconfigured(_that);
      case AuthSignedOut():
        return signedOut(_that);
      case AuthSignedIn():
        return signedIn(_that);
      case AuthExpired():
        return expired(_that);
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
    TResult? Function(AuthUnconfigured value)? unconfigured,
    TResult? Function(AuthSignedOut value)? signedOut,
    TResult? Function(AuthSignedIn value)? signedIn,
    TResult? Function(AuthExpired value)? expired,
  }) {
    final _that = this;
    switch (_that) {
      case AuthUnconfigured() when unconfigured != null:
        return unconfigured(_that);
      case AuthSignedOut() when signedOut != null:
        return signedOut(_that);
      case AuthSignedIn() when signedIn != null:
        return signedIn(_that);
      case AuthExpired() when expired != null:
        return expired(_that);
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
    TResult Function()? unconfigured,
    TResult Function()? signedOut,
    TResult Function(User user)? signedIn,
    TResult Function()? expired,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case AuthUnconfigured() when unconfigured != null:
        return unconfigured();
      case AuthSignedOut() when signedOut != null:
        return signedOut();
      case AuthSignedIn() when signedIn != null:
        return signedIn(_that.user);
      case AuthExpired() when expired != null:
        return expired();
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
    required TResult Function() unconfigured,
    required TResult Function() signedOut,
    required TResult Function(User user) signedIn,
    required TResult Function() expired,
  }) {
    final _that = this;
    switch (_that) {
      case AuthUnconfigured():
        return unconfigured();
      case AuthSignedOut():
        return signedOut();
      case AuthSignedIn():
        return signedIn(_that.user);
      case AuthExpired():
        return expired();
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
    TResult? Function()? unconfigured,
    TResult? Function()? signedOut,
    TResult? Function(User user)? signedIn,
    TResult? Function()? expired,
  }) {
    final _that = this;
    switch (_that) {
      case AuthUnconfigured() when unconfigured != null:
        return unconfigured();
      case AuthSignedOut() when signedOut != null:
        return signedOut();
      case AuthSignedIn() when signedIn != null:
        return signedIn(_that.user);
      case AuthExpired() when expired != null:
        return expired();
      case _:
        return null;
    }
  }
}

/// @nodoc

class AuthUnconfigured implements AuthState {
  const AuthUnconfigured();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is AuthUnconfigured);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'AuthState.unconfigured()';
  }
}

/// @nodoc

class AuthSignedOut implements AuthState {
  const AuthSignedOut();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is AuthSignedOut);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'AuthState.signedOut()';
  }
}

/// @nodoc

class AuthSignedIn implements AuthState {
  const AuthSignedIn(this.user);

  final User user;

  /// Create a copy of AuthState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $AuthSignedInCopyWith<AuthSignedIn> get copyWith =>
      _$AuthSignedInCopyWithImpl<AuthSignedIn>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AuthSignedIn &&
            (identical(other.user, user) || other.user == user));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, user);
  }

  @override
  String toString() {
    return 'AuthState.signedIn(user: $user)';
  }
}

/// @nodoc
abstract mixin class $AuthSignedInCopyWith<$Res>
    implements $AuthStateCopyWith<$Res> {
  factory $AuthSignedInCopyWith(
    AuthSignedIn value,
    $Res Function(AuthSignedIn) _then,
  ) = _$AuthSignedInCopyWithImpl;
  @useResult
  $Res call({User user});

  $UserCopyWith<$Res> get user;
}

/// @nodoc
class _$AuthSignedInCopyWithImpl<$Res> implements $AuthSignedInCopyWith<$Res> {
  _$AuthSignedInCopyWithImpl(this._self, this._then);

  final AuthSignedIn _self;
  final $Res Function(AuthSignedIn) _then;

  /// Create a copy of AuthState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? user = null}) {
    return _then(
      AuthSignedIn(
        null == user
            ? _self.user
            : user // ignore: cast_nullable_to_non_nullable
                  as User,
      ),
    );
  }

  /// Create a copy of AuthState
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

class AuthExpired implements AuthState {
  const AuthExpired();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is AuthExpired);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'AuthState.expired()';
  }
}
