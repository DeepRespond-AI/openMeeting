// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'live_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LiveParticipant {
  String get id;
  String? get userId;
  String get name;
  bool get isHost;
  bool get isSelf;
  bool get micOn;
  bool get mutedByHost;
  bool get camOn;
  bool get handRaised;
  bool get screenSharing;
  String? get screenShareId;

  /// Create a copy of LiveParticipant
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $LiveParticipantCopyWith<LiveParticipant> get copyWith =>
      _$LiveParticipantCopyWithImpl<LiveParticipant>(
        this as LiveParticipant,
        _$identity,
      );

  /// Serializes this LiveParticipant to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as LiveParticipant;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is LiveParticipant &&
            (identical(other.id, _this.id) || other.id == _this.id) &&
            (identical(other.userId, _this.userId) ||
                other.userId == _this.userId) &&
            (identical(other.name, _this.name) || other.name == _this.name) &&
            (identical(other.isHost, _this.isHost) ||
                other.isHost == _this.isHost) &&
            (identical(other.isSelf, _this.isSelf) ||
                other.isSelf == _this.isSelf) &&
            (identical(other.micOn, _this.micOn) ||
                other.micOn == _this.micOn) &&
            (identical(other.mutedByHost, _this.mutedByHost) ||
                other.mutedByHost == _this.mutedByHost) &&
            (identical(other.camOn, _this.camOn) ||
                other.camOn == _this.camOn) &&
            (identical(other.handRaised, _this.handRaised) ||
                other.handRaised == _this.handRaised) &&
            (identical(other.screenSharing, _this.screenSharing) ||
                other.screenSharing == _this.screenSharing) &&
            (identical(other.screenShareId, _this.screenShareId) ||
                other.screenShareId == _this.screenShareId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as LiveParticipant;
    return Object.hash(
      runtimeType,
      _this.id,
      _this.userId,
      _this.name,
      _this.isHost,
      _this.isSelf,
      _this.micOn,
      _this.mutedByHost,
      _this.camOn,
      _this.handRaised,
      _this.screenSharing,
      _this.screenShareId,
    );
  }

  @override
  String toString() {
    final _this = this as LiveParticipant;
    return 'LiveParticipant(id: ${_this.id}, userId: ${_this.userId}, name: ${_this.name}, isHost: ${_this.isHost}, isSelf: ${_this.isSelf}, micOn: ${_this.micOn}, mutedByHost: ${_this.mutedByHost}, camOn: ${_this.camOn}, handRaised: ${_this.handRaised}, screenSharing: ${_this.screenSharing}, screenShareId: ${_this.screenShareId})';
  }
}

/// @nodoc
abstract mixin class $LiveParticipantCopyWith<$Res> {
  factory $LiveParticipantCopyWith(
    LiveParticipant value,
    $Res Function(LiveParticipant) _then,
  ) = _$LiveParticipantCopyWithImpl;
  @useResult
  $Res call({
    String id,
    String? userId,
    String name,
    bool isHost,
    bool isSelf,
    bool micOn,
    bool mutedByHost,
    bool camOn,
    bool handRaised,
    bool screenSharing,
    String? screenShareId,
  });
}

/// @nodoc
class _$LiveParticipantCopyWithImpl<$Res>
    implements $LiveParticipantCopyWith<$Res> {
  _$LiveParticipantCopyWithImpl(this._self, this._then);

  final LiveParticipant _self;
  final $Res Function(LiveParticipant) _then;

  /// Create a copy of LiveParticipant
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = freezed,
    Object? name = null,
    Object? isHost = null,
    Object? isSelf = null,
    Object? micOn = null,
    Object? mutedByHost = null,
    Object? camOn = null,
    Object? handRaised = null,
    Object? screenSharing = null,
    Object? screenShareId = freezed,
  }) {
    return _then(
      LiveParticipant(
        id: null == id
            ? _self.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: freezed == userId
            ? _self.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String?,
        name: null == name
            ? _self.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        isHost: null == isHost
            ? _self.isHost
            : isHost // ignore: cast_nullable_to_non_nullable
                  as bool,
        isSelf: null == isSelf
            ? _self.isSelf
            : isSelf // ignore: cast_nullable_to_non_nullable
                  as bool,
        micOn: null == micOn
            ? _self.micOn
            : micOn // ignore: cast_nullable_to_non_nullable
                  as bool,
        mutedByHost: null == mutedByHost
            ? _self.mutedByHost
            : mutedByHost // ignore: cast_nullable_to_non_nullable
                  as bool,
        camOn: null == camOn
            ? _self.camOn
            : camOn // ignore: cast_nullable_to_non_nullable
                  as bool,
        handRaised: null == handRaised
            ? _self.handRaised
            : handRaised // ignore: cast_nullable_to_non_nullable
                  as bool,
        screenSharing: null == screenSharing
            ? _self.screenSharing
            : screenSharing // ignore: cast_nullable_to_non_nullable
                  as bool,
        screenShareId: freezed == screenShareId
            ? _self.screenShareId
            : screenShareId // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [LiveParticipant].
extension LiveParticipantPatterns on LiveParticipant {
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
    TResult Function(_LiveParticipant value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _LiveParticipant() when $default != null:
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
    TResult Function(_LiveParticipant value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LiveParticipant():
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
    TResult? Function(_LiveParticipant value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LiveParticipant() when $default != null:
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
      String? userId,
      String name,
      bool isHost,
      bool isSelf,
      bool micOn,
      bool mutedByHost,
      bool camOn,
      bool handRaised,
      bool screenSharing,
      String? screenShareId,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _LiveParticipant() when $default != null:
        return $default(
          _that.id,
          _that.userId,
          _that.name,
          _that.isHost,
          _that.isSelf,
          _that.micOn,
          _that.mutedByHost,
          _that.camOn,
          _that.handRaised,
          _that.screenSharing,
          _that.screenShareId,
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
      String? userId,
      String name,
      bool isHost,
      bool isSelf,
      bool micOn,
      bool mutedByHost,
      bool camOn,
      bool handRaised,
      bool screenSharing,
      String? screenShareId,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LiveParticipant():
        return $default(
          _that.id,
          _that.userId,
          _that.name,
          _that.isHost,
          _that.isSelf,
          _that.micOn,
          _that.mutedByHost,
          _that.camOn,
          _that.handRaised,
          _that.screenSharing,
          _that.screenShareId,
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
      String? userId,
      String name,
      bool isHost,
      bool isSelf,
      bool micOn,
      bool mutedByHost,
      bool camOn,
      bool handRaised,
      bool screenSharing,
      String? screenShareId,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LiveParticipant() when $default != null:
        return $default(
          _that.id,
          _that.userId,
          _that.name,
          _that.isHost,
          _that.isSelf,
          _that.micOn,
          _that.mutedByHost,
          _that.camOn,
          _that.handRaised,
          _that.screenSharing,
          _that.screenShareId,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _LiveParticipant implements LiveParticipant {
  const _LiveParticipant({
    required this.id,
    this.userId,
    required this.name,
    this.isHost = false,
    this.isSelf = false,
    this.micOn = false,
    this.mutedByHost = false,
    this.camOn = false,
    this.handRaised = false,
    this.screenSharing = false,
    this.screenShareId,
  });
  factory _LiveParticipant.fromJson(Map<String, dynamic> json) =>
      _$LiveParticipantFromJson(json);

  @override
  final String id;
  @override
  final String? userId;
  @override
  final String name;
  @override
  @JsonKey()
  final bool isHost;
  @override
  @JsonKey()
  final bool isSelf;
  @override
  @JsonKey()
  final bool micOn;
  @override
  @JsonKey()
  final bool mutedByHost;
  @override
  @JsonKey()
  final bool camOn;
  @override
  @JsonKey()
  final bool handRaised;
  @override
  @JsonKey()
  final bool screenSharing;
  @override
  final String? screenShareId;

  /// Create a copy of LiveParticipant
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$LiveParticipantCopyWith<_LiveParticipant> get copyWith =>
      __$LiveParticipantCopyWithImpl<_LiveParticipant>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$LiveParticipantToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _LiveParticipant &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.isHost, isHost) || other.isHost == isHost) &&
            (identical(other.isSelf, isSelf) || other.isSelf == isSelf) &&
            (identical(other.micOn, micOn) || other.micOn == micOn) &&
            (identical(other.mutedByHost, mutedByHost) ||
                other.mutedByHost == mutedByHost) &&
            (identical(other.camOn, camOn) || other.camOn == camOn) &&
            (identical(other.handRaised, handRaised) ||
                other.handRaised == handRaised) &&
            (identical(other.screenSharing, screenSharing) ||
                other.screenSharing == screenSharing) &&
            (identical(other.screenShareId, screenShareId) ||
                other.screenShareId == screenShareId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(
      runtimeType,
      id,
      userId,
      name,
      isHost,
      isSelf,
      micOn,
      mutedByHost,
      camOn,
      handRaised,
      screenSharing,
      screenShareId,
    );
  }

  @override
  String toString() {
    return 'LiveParticipant(id: $id, userId: $userId, name: $name, isHost: $isHost, isSelf: $isSelf, micOn: $micOn, mutedByHost: $mutedByHost, camOn: $camOn, handRaised: $handRaised, screenSharing: $screenSharing, screenShareId: $screenShareId)';
  }
}

/// @nodoc
abstract mixin class _$LiveParticipantCopyWith<$Res>
    implements $LiveParticipantCopyWith<$Res> {
  factory _$LiveParticipantCopyWith(
    _LiveParticipant value,
    $Res Function(_LiveParticipant) _then,
  ) = __$LiveParticipantCopyWithImpl;
  @override
  @useResult
  $Res call({
    String id,
    String? userId,
    String name,
    bool isHost,
    bool isSelf,
    bool micOn,
    bool mutedByHost,
    bool camOn,
    bool handRaised,
    bool screenSharing,
    String? screenShareId,
  });
}

/// @nodoc
class __$LiveParticipantCopyWithImpl<$Res>
    implements _$LiveParticipantCopyWith<$Res> {
  __$LiveParticipantCopyWithImpl(this._self, this._then);

  final _LiveParticipant _self;
  final $Res Function(_LiveParticipant) _then;

  /// Create a copy of LiveParticipant
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? userId = freezed,
    Object? name = null,
    Object? isHost = null,
    Object? isSelf = null,
    Object? micOn = null,
    Object? mutedByHost = null,
    Object? camOn = null,
    Object? handRaised = null,
    Object? screenSharing = null,
    Object? screenShareId = freezed,
  }) {
    return _then(
      _LiveParticipant(
        id: null == id
            ? _self.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: freezed == userId
            ? _self.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String?,
        name: null == name
            ? _self.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        isHost: null == isHost
            ? _self.isHost
            : isHost // ignore: cast_nullable_to_non_nullable
                  as bool,
        isSelf: null == isSelf
            ? _self.isSelf
            : isSelf // ignore: cast_nullable_to_non_nullable
                  as bool,
        micOn: null == micOn
            ? _self.micOn
            : micOn // ignore: cast_nullable_to_non_nullable
                  as bool,
        mutedByHost: null == mutedByHost
            ? _self.mutedByHost
            : mutedByHost // ignore: cast_nullable_to_non_nullable
                  as bool,
        camOn: null == camOn
            ? _self.camOn
            : camOn // ignore: cast_nullable_to_non_nullable
                  as bool,
        handRaised: null == handRaised
            ? _self.handRaised
            : handRaised // ignore: cast_nullable_to_non_nullable
                  as bool,
        screenSharing: null == screenSharing
            ? _self.screenSharing
            : screenSharing // ignore: cast_nullable_to_non_nullable
                  as bool,
        screenShareId: freezed == screenShareId
            ? _self.screenShareId
            : screenShareId // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
mixin _$LiveWaiting {
  String get participantId;
  String get name;

  /// Create a copy of LiveWaiting
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $LiveWaitingCopyWith<LiveWaiting> get copyWith =>
      _$LiveWaitingCopyWithImpl<LiveWaiting>(this as LiveWaiting, _$identity);

  /// Serializes this LiveWaiting to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as LiveWaiting;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is LiveWaiting &&
            (identical(other.participantId, _this.participantId) ||
                other.participantId == _this.participantId) &&
            (identical(other.name, _this.name) || other.name == _this.name));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as LiveWaiting;
    return Object.hash(runtimeType, _this.participantId, _this.name);
  }

  @override
  String toString() {
    final _this = this as LiveWaiting;
    return 'LiveWaiting(participantId: ${_this.participantId}, name: ${_this.name})';
  }
}

/// @nodoc
abstract mixin class $LiveWaitingCopyWith<$Res> {
  factory $LiveWaitingCopyWith(
    LiveWaiting value,
    $Res Function(LiveWaiting) _then,
  ) = _$LiveWaitingCopyWithImpl;
  @useResult
  $Res call({String participantId, String name});
}

/// @nodoc
class _$LiveWaitingCopyWithImpl<$Res> implements $LiveWaitingCopyWith<$Res> {
  _$LiveWaitingCopyWithImpl(this._self, this._then);

  final LiveWaiting _self;
  final $Res Function(LiveWaiting) _then;

  /// Create a copy of LiveWaiting
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? participantId = null, Object? name = null}) {
    return _then(
      LiveWaiting(
        participantId: null == participantId
            ? _self.participantId
            : participantId // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _self.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [LiveWaiting].
extension LiveWaitingPatterns on LiveWaiting {
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
    TResult Function(_LiveWaiting value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _LiveWaiting() when $default != null:
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
    TResult Function(_LiveWaiting value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LiveWaiting():
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
    TResult? Function(_LiveWaiting value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LiveWaiting() when $default != null:
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
    TResult Function(String participantId, String name)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _LiveWaiting() when $default != null:
        return $default(_that.participantId, _that.name);
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
    TResult Function(String participantId, String name) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LiveWaiting():
        return $default(_that.participantId, _that.name);
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
    TResult? Function(String participantId, String name)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LiveWaiting() when $default != null:
        return $default(_that.participantId, _that.name);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _LiveWaiting implements LiveWaiting {
  const _LiveWaiting({required this.participantId, required this.name});
  factory _LiveWaiting.fromJson(Map<String, dynamic> json) =>
      _$LiveWaitingFromJson(json);

  @override
  final String participantId;
  @override
  final String name;

  /// Create a copy of LiveWaiting
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$LiveWaitingCopyWith<_LiveWaiting> get copyWith =>
      __$LiveWaitingCopyWithImpl<_LiveWaiting>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$LiveWaitingToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _LiveWaiting &&
            (identical(other.participantId, participantId) ||
                other.participantId == participantId) &&
            (identical(other.name, name) || other.name == name));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(runtimeType, participantId, name);
  }

  @override
  String toString() {
    return 'LiveWaiting(participantId: $participantId, name: $name)';
  }
}

/// @nodoc
abstract mixin class _$LiveWaitingCopyWith<$Res>
    implements $LiveWaitingCopyWith<$Res> {
  factory _$LiveWaitingCopyWith(
    _LiveWaiting value,
    $Res Function(_LiveWaiting) _then,
  ) = __$LiveWaitingCopyWithImpl;
  @override
  @useResult
  $Res call({String participantId, String name});
}

/// @nodoc
class __$LiveWaitingCopyWithImpl<$Res> implements _$LiveWaitingCopyWith<$Res> {
  __$LiveWaitingCopyWithImpl(this._self, this._then);

  final _LiveWaiting _self;
  final $Res Function(_LiveWaiting) _then;

  /// Create a copy of LiveWaiting
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({Object? participantId = null, Object? name = null}) {
    return _then(
      _LiveWaiting(
        participantId: null == participantId
            ? _self.participantId
            : participantId // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _self.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
mixin _$LiveRoom {
  String get id;
  String get code;
  String get title;
  String get hostId;
  String? get hostUserId;
  String get status;
  bool get pwdEnabled;
  bool get waitRoom;
  List<LiveParticipant> get participants;
  List<LiveWaiting> get waiting;
  DateTime? get startedAt;
  String? get meetingId;
  LiveRecording? get recording;

  /// Create a copy of LiveRoom
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $LiveRoomCopyWith<LiveRoom> get copyWith =>
      _$LiveRoomCopyWithImpl<LiveRoom>(this as LiveRoom, _$identity);

  /// Serializes this LiveRoom to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as LiveRoom;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is LiveRoom &&
            (identical(other.id, _this.id) || other.id == _this.id) &&
            (identical(other.code, _this.code) || other.code == _this.code) &&
            (identical(other.title, _this.title) ||
                other.title == _this.title) &&
            (identical(other.hostId, _this.hostId) ||
                other.hostId == _this.hostId) &&
            (identical(other.hostUserId, _this.hostUserId) ||
                other.hostUserId == _this.hostUserId) &&
            (identical(other.status, _this.status) ||
                other.status == _this.status) &&
            (identical(other.pwdEnabled, _this.pwdEnabled) ||
                other.pwdEnabled == _this.pwdEnabled) &&
            (identical(other.waitRoom, _this.waitRoom) ||
                other.waitRoom == _this.waitRoom) &&
            const DeepCollectionEquality().equals(
              other.participants,
              _this.participants,
            ) &&
            const DeepCollectionEquality().equals(
              other.waiting,
              _this.waiting,
            ) &&
            (identical(other.startedAt, _this.startedAt) ||
                other.startedAt == _this.startedAt) &&
            (identical(other.meetingId, _this.meetingId) ||
                other.meetingId == _this.meetingId) &&
            (identical(other.recording, _this.recording) ||
                other.recording == _this.recording));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as LiveRoom;
    return Object.hash(
      runtimeType,
      _this.id,
      _this.code,
      _this.title,
      _this.hostId,
      _this.hostUserId,
      _this.status,
      _this.pwdEnabled,
      _this.waitRoom,
      const DeepCollectionEquality().hash(_this.participants),
      const DeepCollectionEquality().hash(_this.waiting),
      _this.startedAt,
      _this.meetingId,
      _this.recording,
    );
  }

  @override
  String toString() {
    final _this = this as LiveRoom;
    return 'LiveRoom(id: ${_this.id}, code: ${_this.code}, title: ${_this.title}, hostId: ${_this.hostId}, hostUserId: ${_this.hostUserId}, status: ${_this.status}, pwdEnabled: ${_this.pwdEnabled}, waitRoom: ${_this.waitRoom}, participants: ${_this.participants}, waiting: ${_this.waiting}, startedAt: ${_this.startedAt}, meetingId: ${_this.meetingId}, recording: ${_this.recording})';
  }
}

/// @nodoc
abstract mixin class $LiveRoomCopyWith<$Res> {
  factory $LiveRoomCopyWith(LiveRoom value, $Res Function(LiveRoom) _then) =
      _$LiveRoomCopyWithImpl;
  @useResult
  $Res call({
    String id,
    String code,
    String title,
    String hostId,
    String? hostUserId,
    String status,
    bool pwdEnabled,
    bool waitRoom,
    List<LiveParticipant> participants,
    List<LiveWaiting> waiting,
    DateTime? startedAt,
    String? meetingId,
    LiveRecording? recording,
  });

  $LiveRecordingCopyWith<$Res>? get recording;
}

/// @nodoc
class _$LiveRoomCopyWithImpl<$Res> implements $LiveRoomCopyWith<$Res> {
  _$LiveRoomCopyWithImpl(this._self, this._then);

  final LiveRoom _self;
  final $Res Function(LiveRoom) _then;

  /// Create a copy of LiveRoom
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? code = null,
    Object? title = null,
    Object? hostId = null,
    Object? hostUserId = freezed,
    Object? status = null,
    Object? pwdEnabled = null,
    Object? waitRoom = null,
    Object? participants = null,
    Object? waiting = null,
    Object? startedAt = freezed,
    Object? meetingId = freezed,
    Object? recording = freezed,
  }) {
    return _then(
      LiveRoom(
        id: null == id
            ? _self.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        code: null == code
            ? _self.code
            : code // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _self.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        hostId: null == hostId
            ? _self.hostId
            : hostId // ignore: cast_nullable_to_non_nullable
                  as String,
        hostUserId: freezed == hostUserId
            ? _self.hostUserId
            : hostUserId // ignore: cast_nullable_to_non_nullable
                  as String?,
        status: null == status
            ? _self.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        pwdEnabled: null == pwdEnabled
            ? _self.pwdEnabled
            : pwdEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        waitRoom: null == waitRoom
            ? _self.waitRoom
            : waitRoom // ignore: cast_nullable_to_non_nullable
                  as bool,
        participants: null == participants
            ? _self.participants
            : participants // ignore: cast_nullable_to_non_nullable
                  as List<LiveParticipant>,
        waiting: null == waiting
            ? _self.waiting
            : waiting // ignore: cast_nullable_to_non_nullable
                  as List<LiveWaiting>,
        startedAt: freezed == startedAt
            ? _self.startedAt
            : startedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        meetingId: freezed == meetingId
            ? _self.meetingId
            : meetingId // ignore: cast_nullable_to_non_nullable
                  as String?,
        recording: freezed == recording
            ? _self.recording
            : recording // ignore: cast_nullable_to_non_nullable
                  as LiveRecording?,
      ),
    );
  }

  /// Create a copy of LiveRoom
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $LiveRecordingCopyWith<$Res>? get recording {
    if (_self.recording == null) {
      return null;
    }

    return $LiveRecordingCopyWith<$Res>(_self.recording!, (value) {
      return _then(_self.copyWith(recording: value));
    });
  }
}

/// Adds pattern-matching-related methods to [LiveRoom].
extension LiveRoomPatterns on LiveRoom {
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
    TResult Function(_LiveRoom value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _LiveRoom() when $default != null:
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
    TResult Function(_LiveRoom value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LiveRoom():
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
    TResult? Function(_LiveRoom value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LiveRoom() when $default != null:
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
      String code,
      String title,
      String hostId,
      String? hostUserId,
      String status,
      bool pwdEnabled,
      bool waitRoom,
      List<LiveParticipant> participants,
      List<LiveWaiting> waiting,
      DateTime? startedAt,
      String? meetingId,
      LiveRecording? recording,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _LiveRoom() when $default != null:
        return $default(
          _that.id,
          _that.code,
          _that.title,
          _that.hostId,
          _that.hostUserId,
          _that.status,
          _that.pwdEnabled,
          _that.waitRoom,
          _that.participants,
          _that.waiting,
          _that.startedAt,
          _that.meetingId,
          _that.recording,
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
      String code,
      String title,
      String hostId,
      String? hostUserId,
      String status,
      bool pwdEnabled,
      bool waitRoom,
      List<LiveParticipant> participants,
      List<LiveWaiting> waiting,
      DateTime? startedAt,
      String? meetingId,
      LiveRecording? recording,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LiveRoom():
        return $default(
          _that.id,
          _that.code,
          _that.title,
          _that.hostId,
          _that.hostUserId,
          _that.status,
          _that.pwdEnabled,
          _that.waitRoom,
          _that.participants,
          _that.waiting,
          _that.startedAt,
          _that.meetingId,
          _that.recording,
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
      String code,
      String title,
      String hostId,
      String? hostUserId,
      String status,
      bool pwdEnabled,
      bool waitRoom,
      List<LiveParticipant> participants,
      List<LiveWaiting> waiting,
      DateTime? startedAt,
      String? meetingId,
      LiveRecording? recording,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LiveRoom() when $default != null:
        return $default(
          _that.id,
          _that.code,
          _that.title,
          _that.hostId,
          _that.hostUserId,
          _that.status,
          _that.pwdEnabled,
          _that.waitRoom,
          _that.participants,
          _that.waiting,
          _that.startedAt,
          _that.meetingId,
          _that.recording,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _LiveRoom implements LiveRoom {
  const _LiveRoom({
    required this.id,
    required this.code,
    required this.title,
    required this.hostId,
    this.hostUserId,
    this.status = 'active',
    this.pwdEnabled = false,
    this.waitRoom = false,
    List<LiveParticipant> participants = const [],
    List<LiveWaiting> waiting = const [],
    this.startedAt,
    this.meetingId,
    this.recording,
  }) : _participants = participants,
       _waiting = waiting;
  factory _LiveRoom.fromJson(Map<String, dynamic> json) =>
      _$LiveRoomFromJson(json);

  @override
  final String id;
  @override
  final String code;
  @override
  final String title;
  @override
  final String hostId;
  @override
  final String? hostUserId;
  @override
  @JsonKey()
  final String status;
  @override
  @JsonKey()
  final bool pwdEnabled;
  @override
  @JsonKey()
  final bool waitRoom;
  final List<LiveParticipant> _participants;
  @override
  @JsonKey()
  List<LiveParticipant> get participants {
    if (_participants is EqualUnmodifiableListView) return _participants;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_participants);
  }

  final List<LiveWaiting> _waiting;
  @override
  @JsonKey()
  List<LiveWaiting> get waiting {
    if (_waiting is EqualUnmodifiableListView) return _waiting;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_waiting);
  }

  @override
  final DateTime? startedAt;
  @override
  final String? meetingId;
  @override
  final LiveRecording? recording;

  /// Create a copy of LiveRoom
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$LiveRoomCopyWith<_LiveRoom> get copyWith =>
      __$LiveRoomCopyWithImpl<_LiveRoom>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$LiveRoomToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _LiveRoom &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.hostId, hostId) || other.hostId == hostId) &&
            (identical(other.hostUserId, hostUserId) ||
                other.hostUserId == hostUserId) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.pwdEnabled, pwdEnabled) ||
                other.pwdEnabled == pwdEnabled) &&
            (identical(other.waitRoom, waitRoom) ||
                other.waitRoom == waitRoom) &&
            const DeepCollectionEquality().equals(
              other.participants,
              _participants,
            ) &&
            const DeepCollectionEquality().equals(other.waiting, _waiting) &&
            (identical(other.startedAt, startedAt) ||
                other.startedAt == startedAt) &&
            (identical(other.meetingId, meetingId) ||
                other.meetingId == meetingId) &&
            (identical(other.recording, recording) ||
                other.recording == recording));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(
      runtimeType,
      id,
      code,
      title,
      hostId,
      hostUserId,
      status,
      pwdEnabled,
      waitRoom,
      const DeepCollectionEquality().hash(_participants),
      const DeepCollectionEquality().hash(_waiting),
      startedAt,
      meetingId,
      recording,
    );
  }

  @override
  String toString() {
    return 'LiveRoom(id: $id, code: $code, title: $title, hostId: $hostId, hostUserId: $hostUserId, status: $status, pwdEnabled: $pwdEnabled, waitRoom: $waitRoom, participants: $participants, waiting: $waiting, startedAt: $startedAt, meetingId: $meetingId, recording: $recording)';
  }
}

/// @nodoc
abstract mixin class _$LiveRoomCopyWith<$Res>
    implements $LiveRoomCopyWith<$Res> {
  factory _$LiveRoomCopyWith(_LiveRoom value, $Res Function(_LiveRoom) _then) =
      __$LiveRoomCopyWithImpl;
  @override
  @useResult
  $Res call({
    String id,
    String code,
    String title,
    String hostId,
    String? hostUserId,
    String status,
    bool pwdEnabled,
    bool waitRoom,
    List<LiveParticipant> participants,
    List<LiveWaiting> waiting,
    DateTime? startedAt,
    String? meetingId,
    LiveRecording? recording,
  });

  @override
  $LiveRecordingCopyWith<$Res>? get recording;
}

/// @nodoc
class __$LiveRoomCopyWithImpl<$Res> implements _$LiveRoomCopyWith<$Res> {
  __$LiveRoomCopyWithImpl(this._self, this._then);

  final _LiveRoom _self;
  final $Res Function(_LiveRoom) _then;

  /// Create a copy of LiveRoom
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? code = null,
    Object? title = null,
    Object? hostId = null,
    Object? hostUserId = freezed,
    Object? status = null,
    Object? pwdEnabled = null,
    Object? waitRoom = null,
    Object? participants = null,
    Object? waiting = null,
    Object? startedAt = freezed,
    Object? meetingId = freezed,
    Object? recording = freezed,
  }) {
    return _then(
      _LiveRoom(
        id: null == id
            ? _self.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        code: null == code
            ? _self.code
            : code // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _self.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        hostId: null == hostId
            ? _self.hostId
            : hostId // ignore: cast_nullable_to_non_nullable
                  as String,
        hostUserId: freezed == hostUserId
            ? _self.hostUserId
            : hostUserId // ignore: cast_nullable_to_non_nullable
                  as String?,
        status: null == status
            ? _self.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        pwdEnabled: null == pwdEnabled
            ? _self.pwdEnabled
            : pwdEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        waitRoom: null == waitRoom
            ? _self.waitRoom
            : waitRoom // ignore: cast_nullable_to_non_nullable
                  as bool,
        participants: null == participants
            ? _self._participants
            : participants // ignore: cast_nullable_to_non_nullable
                  as List<LiveParticipant>,
        waiting: null == waiting
            ? _self._waiting
            : waiting // ignore: cast_nullable_to_non_nullable
                  as List<LiveWaiting>,
        startedAt: freezed == startedAt
            ? _self.startedAt
            : startedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        meetingId: freezed == meetingId
            ? _self.meetingId
            : meetingId // ignore: cast_nullable_to_non_nullable
                  as String?,
        recording: freezed == recording
            ? _self.recording
            : recording // ignore: cast_nullable_to_non_nullable
                  as LiveRecording?,
      ),
    );
  }

  /// Create a copy of LiveRoom
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $LiveRecordingCopyWith<$Res>? get recording {
    if (_self.recording == null) {
      return null;
    }

    return $LiveRecordingCopyWith<$Res>(_self.recording!, (value) {
      return _then(_self.copyWith(recording: value));
    });
  }
}

/// @nodoc
mixin _$LiveSender {
  String get id;
  String get name;
  bool get isSelf;

  /// Create a copy of LiveSender
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $LiveSenderCopyWith<LiveSender> get copyWith =>
      _$LiveSenderCopyWithImpl<LiveSender>(this as LiveSender, _$identity);

  /// Serializes this LiveSender to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as LiveSender;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is LiveSender &&
            (identical(other.id, _this.id) || other.id == _this.id) &&
            (identical(other.name, _this.name) || other.name == _this.name) &&
            (identical(other.isSelf, _this.isSelf) ||
                other.isSelf == _this.isSelf));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as LiveSender;
    return Object.hash(runtimeType, _this.id, _this.name, _this.isSelf);
  }

  @override
  String toString() {
    final _this = this as LiveSender;
    return 'LiveSender(id: ${_this.id}, name: ${_this.name}, isSelf: ${_this.isSelf})';
  }
}

/// @nodoc
abstract mixin class $LiveSenderCopyWith<$Res> {
  factory $LiveSenderCopyWith(
    LiveSender value,
    $Res Function(LiveSender) _then,
  ) = _$LiveSenderCopyWithImpl;
  @useResult
  $Res call({String id, String name, bool isSelf});
}

/// @nodoc
class _$LiveSenderCopyWithImpl<$Res> implements $LiveSenderCopyWith<$Res> {
  _$LiveSenderCopyWithImpl(this._self, this._then);

  final LiveSender _self;
  final $Res Function(LiveSender) _then;

  /// Create a copy of LiveSender
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? name = null, Object? isSelf = null}) {
    return _then(
      LiveSender(
        id: null == id
            ? _self.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _self.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        isSelf: null == isSelf
            ? _self.isSelf
            : isSelf // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [LiveSender].
extension LiveSenderPatterns on LiveSender {
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
    TResult Function(_LiveSender value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _LiveSender() when $default != null:
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
    TResult Function(_LiveSender value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LiveSender():
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
    TResult? Function(_LiveSender value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LiveSender() when $default != null:
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
    TResult Function(String id, String name, bool isSelf)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _LiveSender() when $default != null:
        return $default(_that.id, _that.name, _that.isSelf);
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
    TResult Function(String id, String name, bool isSelf) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LiveSender():
        return $default(_that.id, _that.name, _that.isSelf);
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
    TResult? Function(String id, String name, bool isSelf)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LiveSender() when $default != null:
        return $default(_that.id, _that.name, _that.isSelf);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _LiveSender implements LiveSender {
  const _LiveSender({
    required this.id,
    required this.name,
    this.isSelf = false,
  });
  factory _LiveSender.fromJson(Map<String, dynamic> json) =>
      _$LiveSenderFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  @JsonKey()
  final bool isSelf;

  /// Create a copy of LiveSender
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$LiveSenderCopyWith<_LiveSender> get copyWith =>
      __$LiveSenderCopyWithImpl<_LiveSender>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$LiveSenderToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _LiveSender &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.isSelf, isSelf) || other.isSelf == isSelf));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(runtimeType, id, name, isSelf);
  }

  @override
  String toString() {
    return 'LiveSender(id: $id, name: $name, isSelf: $isSelf)';
  }
}

/// @nodoc
abstract mixin class _$LiveSenderCopyWith<$Res>
    implements $LiveSenderCopyWith<$Res> {
  factory _$LiveSenderCopyWith(
    _LiveSender value,
    $Res Function(_LiveSender) _then,
  ) = __$LiveSenderCopyWithImpl;
  @override
  @useResult
  $Res call({String id, String name, bool isSelf});
}

/// @nodoc
class __$LiveSenderCopyWithImpl<$Res> implements _$LiveSenderCopyWith<$Res> {
  __$LiveSenderCopyWithImpl(this._self, this._then);

  final _LiveSender _self;
  final $Res Function(_LiveSender) _then;

  /// Create a copy of LiveSender
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({Object? id = null, Object? name = null, Object? isSelf = null}) {
    return _then(
      _LiveSender(
        id: null == id
            ? _self.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _self.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        isSelf: null == isSelf
            ? _self.isSelf
            : isSelf // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
mixin _$LiveAttachment {
  String get id;
  String get name;
  int get size;

  /// Create a copy of LiveAttachment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $LiveAttachmentCopyWith<LiveAttachment> get copyWith =>
      _$LiveAttachmentCopyWithImpl<LiveAttachment>(
        this as LiveAttachment,
        _$identity,
      );

  /// Serializes this LiveAttachment to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as LiveAttachment;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is LiveAttachment &&
            (identical(other.id, _this.id) || other.id == _this.id) &&
            (identical(other.name, _this.name) || other.name == _this.name) &&
            (identical(other.size, _this.size) || other.size == _this.size));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as LiveAttachment;
    return Object.hash(runtimeType, _this.id, _this.name, _this.size);
  }

  @override
  String toString() {
    final _this = this as LiveAttachment;
    return 'LiveAttachment(id: ${_this.id}, name: ${_this.name}, size: ${_this.size})';
  }
}

/// @nodoc
abstract mixin class $LiveAttachmentCopyWith<$Res> {
  factory $LiveAttachmentCopyWith(
    LiveAttachment value,
    $Res Function(LiveAttachment) _then,
  ) = _$LiveAttachmentCopyWithImpl;
  @useResult
  $Res call({String id, String name, int size});
}

/// @nodoc
class _$LiveAttachmentCopyWithImpl<$Res>
    implements $LiveAttachmentCopyWith<$Res> {
  _$LiveAttachmentCopyWithImpl(this._self, this._then);

  final LiveAttachment _self;
  final $Res Function(LiveAttachment) _then;

  /// Create a copy of LiveAttachment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? name = null, Object? size = null}) {
    return _then(
      LiveAttachment(
        id: null == id
            ? _self.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _self.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        size: null == size
            ? _self.size
            : size // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [LiveAttachment].
extension LiveAttachmentPatterns on LiveAttachment {
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
    TResult Function(_LiveAttachment value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _LiveAttachment() when $default != null:
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
    TResult Function(_LiveAttachment value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LiveAttachment():
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
    TResult? Function(_LiveAttachment value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LiveAttachment() when $default != null:
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
    TResult Function(String id, String name, int size)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _LiveAttachment() when $default != null:
        return $default(_that.id, _that.name, _that.size);
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
    TResult Function(String id, String name, int size) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LiveAttachment():
        return $default(_that.id, _that.name, _that.size);
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
    TResult? Function(String id, String name, int size)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LiveAttachment() when $default != null:
        return $default(_that.id, _that.name, _that.size);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _LiveAttachment implements LiveAttachment {
  const _LiveAttachment({
    required this.id,
    required this.name,
    required this.size,
  });
  factory _LiveAttachment.fromJson(Map<String, dynamic> json) =>
      _$LiveAttachmentFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final int size;

  /// Create a copy of LiveAttachment
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$LiveAttachmentCopyWith<_LiveAttachment> get copyWith =>
      __$LiveAttachmentCopyWithImpl<_LiveAttachment>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$LiveAttachmentToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _LiveAttachment &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.size, size) || other.size == size));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(runtimeType, id, name, size);
  }

  @override
  String toString() {
    return 'LiveAttachment(id: $id, name: $name, size: $size)';
  }
}

/// @nodoc
abstract mixin class _$LiveAttachmentCopyWith<$Res>
    implements $LiveAttachmentCopyWith<$Res> {
  factory _$LiveAttachmentCopyWith(
    _LiveAttachment value,
    $Res Function(_LiveAttachment) _then,
  ) = __$LiveAttachmentCopyWithImpl;
  @override
  @useResult
  $Res call({String id, String name, int size});
}

/// @nodoc
class __$LiveAttachmentCopyWithImpl<$Res>
    implements _$LiveAttachmentCopyWith<$Res> {
  __$LiveAttachmentCopyWithImpl(this._self, this._then);

  final _LiveAttachment _self;
  final $Res Function(_LiveAttachment) _then;

  /// Create a copy of LiveAttachment
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({Object? id = null, Object? name = null, Object? size = null}) {
    return _then(
      _LiveAttachment(
        id: null == id
            ? _self.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _self.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        size: null == size
            ? _self.size
            : size // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
mixin _$LiveChat {
  String get id;
  LiveSender get sender;
  String get text;
  LiveAttachment? get attachment;
  DateTime? get createdAt;

  /// Create a copy of LiveChat
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $LiveChatCopyWith<LiveChat> get copyWith =>
      _$LiveChatCopyWithImpl<LiveChat>(this as LiveChat, _$identity);

  /// Serializes this LiveChat to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as LiveChat;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is LiveChat &&
            (identical(other.id, _this.id) || other.id == _this.id) &&
            (identical(other.sender, _this.sender) ||
                other.sender == _this.sender) &&
            (identical(other.text, _this.text) || other.text == _this.text) &&
            (identical(other.attachment, _this.attachment) ||
                other.attachment == _this.attachment) &&
            (identical(other.createdAt, _this.createdAt) ||
                other.createdAt == _this.createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as LiveChat;
    return Object.hash(
      runtimeType,
      _this.id,
      _this.sender,
      _this.text,
      _this.attachment,
      _this.createdAt,
    );
  }

  @override
  String toString() {
    final _this = this as LiveChat;
    return 'LiveChat(id: ${_this.id}, sender: ${_this.sender}, text: ${_this.text}, attachment: ${_this.attachment}, createdAt: ${_this.createdAt})';
  }
}

/// @nodoc
abstract mixin class $LiveChatCopyWith<$Res> {
  factory $LiveChatCopyWith(LiveChat value, $Res Function(LiveChat) _then) =
      _$LiveChatCopyWithImpl;
  @useResult
  $Res call({
    String id,
    LiveSender sender,
    String text,
    LiveAttachment? attachment,
    DateTime? createdAt,
  });

  $LiveSenderCopyWith<$Res> get sender;
  $LiveAttachmentCopyWith<$Res>? get attachment;
}

/// @nodoc
class _$LiveChatCopyWithImpl<$Res> implements $LiveChatCopyWith<$Res> {
  _$LiveChatCopyWithImpl(this._self, this._then);

  final LiveChat _self;
  final $Res Function(LiveChat) _then;

  /// Create a copy of LiveChat
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? sender = null,
    Object? text = null,
    Object? attachment = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(
      LiveChat(
        id: null == id
            ? _self.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        sender: null == sender
            ? _self.sender
            : sender // ignore: cast_nullable_to_non_nullable
                  as LiveSender,
        text: null == text
            ? _self.text
            : text // ignore: cast_nullable_to_non_nullable
                  as String,
        attachment: freezed == attachment
            ? _self.attachment
            : attachment // ignore: cast_nullable_to_non_nullable
                  as LiveAttachment?,
        createdAt: freezed == createdAt
            ? _self.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }

  /// Create a copy of LiveChat
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $LiveSenderCopyWith<$Res> get sender {
    return $LiveSenderCopyWith<$Res>(_self.sender, (value) {
      return _then(_self.copyWith(sender: value));
    });
  }

  /// Create a copy of LiveChat
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $LiveAttachmentCopyWith<$Res>? get attachment {
    if (_self.attachment == null) {
      return null;
    }

    return $LiveAttachmentCopyWith<$Res>(_self.attachment!, (value) {
      return _then(_self.copyWith(attachment: value));
    });
  }
}

/// Adds pattern-matching-related methods to [LiveChat].
extension LiveChatPatterns on LiveChat {
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
    TResult Function(_LiveChat value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _LiveChat() when $default != null:
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
    TResult Function(_LiveChat value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LiveChat():
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
    TResult? Function(_LiveChat value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LiveChat() when $default != null:
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
      LiveSender sender,
      String text,
      LiveAttachment? attachment,
      DateTime? createdAt,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _LiveChat() when $default != null:
        return $default(
          _that.id,
          _that.sender,
          _that.text,
          _that.attachment,
          _that.createdAt,
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
      LiveSender sender,
      String text,
      LiveAttachment? attachment,
      DateTime? createdAt,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LiveChat():
        return $default(
          _that.id,
          _that.sender,
          _that.text,
          _that.attachment,
          _that.createdAt,
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
      LiveSender sender,
      String text,
      LiveAttachment? attachment,
      DateTime? createdAt,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LiveChat() when $default != null:
        return $default(
          _that.id,
          _that.sender,
          _that.text,
          _that.attachment,
          _that.createdAt,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _LiveChat implements LiveChat {
  const _LiveChat({
    required this.id,
    required this.sender,
    this.text = '',
    this.attachment,
    this.createdAt,
  });
  factory _LiveChat.fromJson(Map<String, dynamic> json) =>
      _$LiveChatFromJson(json);

  @override
  final String id;
  @override
  final LiveSender sender;
  @override
  @JsonKey()
  final String text;
  @override
  final LiveAttachment? attachment;
  @override
  final DateTime? createdAt;

  /// Create a copy of LiveChat
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$LiveChatCopyWith<_LiveChat> get copyWith =>
      __$LiveChatCopyWithImpl<_LiveChat>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$LiveChatToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _LiveChat &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.sender, sender) || other.sender == sender) &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.attachment, attachment) ||
                other.attachment == attachment) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(runtimeType, id, sender, text, attachment, createdAt);
  }

  @override
  String toString() {
    return 'LiveChat(id: $id, sender: $sender, text: $text, attachment: $attachment, createdAt: $createdAt)';
  }
}

/// @nodoc
abstract mixin class _$LiveChatCopyWith<$Res>
    implements $LiveChatCopyWith<$Res> {
  factory _$LiveChatCopyWith(_LiveChat value, $Res Function(_LiveChat) _then) =
      __$LiveChatCopyWithImpl;
  @override
  @useResult
  $Res call({
    String id,
    LiveSender sender,
    String text,
    LiveAttachment? attachment,
    DateTime? createdAt,
  });

  @override
  $LiveSenderCopyWith<$Res> get sender;
  @override
  $LiveAttachmentCopyWith<$Res>? get attachment;
}

/// @nodoc
class __$LiveChatCopyWithImpl<$Res> implements _$LiveChatCopyWith<$Res> {
  __$LiveChatCopyWithImpl(this._self, this._then);

  final _LiveChat _self;
  final $Res Function(_LiveChat) _then;

  /// Create a copy of LiveChat
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? sender = null,
    Object? text = null,
    Object? attachment = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(
      _LiveChat(
        id: null == id
            ? _self.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        sender: null == sender
            ? _self.sender
            : sender // ignore: cast_nullable_to_non_nullable
                  as LiveSender,
        text: null == text
            ? _self.text
            : text // ignore: cast_nullable_to_non_nullable
                  as String,
        attachment: freezed == attachment
            ? _self.attachment
            : attachment // ignore: cast_nullable_to_non_nullable
                  as LiveAttachment?,
        createdAt: freezed == createdAt
            ? _self.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }

  /// Create a copy of LiveChat
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $LiveSenderCopyWith<$Res> get sender {
    return $LiveSenderCopyWith<$Res>(_self.sender, (value) {
      return _then(_self.copyWith(sender: value));
    });
  }

  /// Create a copy of LiveChat
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $LiveAttachmentCopyWith<$Res>? get attachment {
    if (_self.attachment == null) {
      return null;
    }

    return $LiveAttachmentCopyWith<$Res>(_self.attachment!, (value) {
      return _then(_self.copyWith(attachment: value));
    });
  }
}

/// @nodoc
mixin _$LiveSchedule {
  String get id;
  String get code;
  String get title;
  DateTime get startAt;
  int get durationMin;
  bool get pwdEnabled;
  String? get pwd;
  bool get waitRoom;
  bool get remind;
  bool get cancelled;
  String? get meetingId;
  String? get activeRoomId;
  Map<String, dynamic> get host;

  /// Create a copy of LiveSchedule
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $LiveScheduleCopyWith<LiveSchedule> get copyWith =>
      _$LiveScheduleCopyWithImpl<LiveSchedule>(
        this as LiveSchedule,
        _$identity,
      );

  /// Serializes this LiveSchedule to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as LiveSchedule;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is LiveSchedule &&
            (identical(other.id, _this.id) || other.id == _this.id) &&
            (identical(other.code, _this.code) || other.code == _this.code) &&
            (identical(other.title, _this.title) ||
                other.title == _this.title) &&
            (identical(other.startAt, _this.startAt) ||
                other.startAt == _this.startAt) &&
            (identical(other.durationMin, _this.durationMin) ||
                other.durationMin == _this.durationMin) &&
            (identical(other.pwdEnabled, _this.pwdEnabled) ||
                other.pwdEnabled == _this.pwdEnabled) &&
            (identical(other.pwd, _this.pwd) || other.pwd == _this.pwd) &&
            (identical(other.waitRoom, _this.waitRoom) ||
                other.waitRoom == _this.waitRoom) &&
            (identical(other.remind, _this.remind) ||
                other.remind == _this.remind) &&
            (identical(other.cancelled, _this.cancelled) ||
                other.cancelled == _this.cancelled) &&
            (identical(other.meetingId, _this.meetingId) ||
                other.meetingId == _this.meetingId) &&
            (identical(other.activeRoomId, _this.activeRoomId) ||
                other.activeRoomId == _this.activeRoomId) &&
            const DeepCollectionEquality().equals(other.host, _this.host));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as LiveSchedule;
    return Object.hash(
      runtimeType,
      _this.id,
      _this.code,
      _this.title,
      _this.startAt,
      _this.durationMin,
      _this.pwdEnabled,
      _this.pwd,
      _this.waitRoom,
      _this.remind,
      _this.cancelled,
      _this.meetingId,
      _this.activeRoomId,
      const DeepCollectionEquality().hash(_this.host),
    );
  }

  @override
  String toString() {
    final _this = this as LiveSchedule;
    return 'LiveSchedule(id: ${_this.id}, code: ${_this.code}, title: ${_this.title}, startAt: ${_this.startAt}, durationMin: ${_this.durationMin}, pwdEnabled: ${_this.pwdEnabled}, pwd: ${_this.pwd}, waitRoom: ${_this.waitRoom}, remind: ${_this.remind}, cancelled: ${_this.cancelled}, meetingId: ${_this.meetingId}, activeRoomId: ${_this.activeRoomId}, host: ${_this.host})';
  }
}

/// @nodoc
abstract mixin class $LiveScheduleCopyWith<$Res> {
  factory $LiveScheduleCopyWith(
    LiveSchedule value,
    $Res Function(LiveSchedule) _then,
  ) = _$LiveScheduleCopyWithImpl;
  @useResult
  $Res call({
    String id,
    String code,
    String title,
    DateTime startAt,
    int durationMin,
    bool pwdEnabled,
    String? pwd,
    bool waitRoom,
    bool remind,
    bool cancelled,
    String? meetingId,
    String? activeRoomId,
    Map<String, dynamic> host,
  });
}

/// @nodoc
class _$LiveScheduleCopyWithImpl<$Res> implements $LiveScheduleCopyWith<$Res> {
  _$LiveScheduleCopyWithImpl(this._self, this._then);

  final LiveSchedule _self;
  final $Res Function(LiveSchedule) _then;

  /// Create a copy of LiveSchedule
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? code = null,
    Object? title = null,
    Object? startAt = null,
    Object? durationMin = null,
    Object? pwdEnabled = null,
    Object? pwd = freezed,
    Object? waitRoom = null,
    Object? remind = null,
    Object? cancelled = null,
    Object? meetingId = freezed,
    Object? activeRoomId = freezed,
    Object? host = null,
  }) {
    return _then(
      LiveSchedule(
        id: null == id
            ? _self.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        code: null == code
            ? _self.code
            : code // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _self.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        startAt: null == startAt
            ? _self.startAt
            : startAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        durationMin: null == durationMin
            ? _self.durationMin
            : durationMin // ignore: cast_nullable_to_non_nullable
                  as int,
        pwdEnabled: null == pwdEnabled
            ? _self.pwdEnabled
            : pwdEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        pwd: freezed == pwd
            ? _self.pwd
            : pwd // ignore: cast_nullable_to_non_nullable
                  as String?,
        waitRoom: null == waitRoom
            ? _self.waitRoom
            : waitRoom // ignore: cast_nullable_to_non_nullable
                  as bool,
        remind: null == remind
            ? _self.remind
            : remind // ignore: cast_nullable_to_non_nullable
                  as bool,
        cancelled: null == cancelled
            ? _self.cancelled
            : cancelled // ignore: cast_nullable_to_non_nullable
                  as bool,
        meetingId: freezed == meetingId
            ? _self.meetingId
            : meetingId // ignore: cast_nullable_to_non_nullable
                  as String?,
        activeRoomId: freezed == activeRoomId
            ? _self.activeRoomId
            : activeRoomId // ignore: cast_nullable_to_non_nullable
                  as String?,
        host: null == host
            ? _self.host
            : host // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [LiveSchedule].
extension LiveSchedulePatterns on LiveSchedule {
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
    TResult Function(_LiveSchedule value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _LiveSchedule() when $default != null:
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
    TResult Function(_LiveSchedule value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LiveSchedule():
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
    TResult? Function(_LiveSchedule value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LiveSchedule() when $default != null:
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
      String code,
      String title,
      DateTime startAt,
      int durationMin,
      bool pwdEnabled,
      String? pwd,
      bool waitRoom,
      bool remind,
      bool cancelled,
      String? meetingId,
      String? activeRoomId,
      Map<String, dynamic> host,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _LiveSchedule() when $default != null:
        return $default(
          _that.id,
          _that.code,
          _that.title,
          _that.startAt,
          _that.durationMin,
          _that.pwdEnabled,
          _that.pwd,
          _that.waitRoom,
          _that.remind,
          _that.cancelled,
          _that.meetingId,
          _that.activeRoomId,
          _that.host,
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
      String code,
      String title,
      DateTime startAt,
      int durationMin,
      bool pwdEnabled,
      String? pwd,
      bool waitRoom,
      bool remind,
      bool cancelled,
      String? meetingId,
      String? activeRoomId,
      Map<String, dynamic> host,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LiveSchedule():
        return $default(
          _that.id,
          _that.code,
          _that.title,
          _that.startAt,
          _that.durationMin,
          _that.pwdEnabled,
          _that.pwd,
          _that.waitRoom,
          _that.remind,
          _that.cancelled,
          _that.meetingId,
          _that.activeRoomId,
          _that.host,
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
      String code,
      String title,
      DateTime startAt,
      int durationMin,
      bool pwdEnabled,
      String? pwd,
      bool waitRoom,
      bool remind,
      bool cancelled,
      String? meetingId,
      String? activeRoomId,
      Map<String, dynamic> host,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LiveSchedule() when $default != null:
        return $default(
          _that.id,
          _that.code,
          _that.title,
          _that.startAt,
          _that.durationMin,
          _that.pwdEnabled,
          _that.pwd,
          _that.waitRoom,
          _that.remind,
          _that.cancelled,
          _that.meetingId,
          _that.activeRoomId,
          _that.host,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _LiveSchedule implements LiveSchedule {
  const _LiveSchedule({
    required this.id,
    required this.code,
    required this.title,
    required this.startAt,
    required this.durationMin,
    this.pwdEnabled = false,
    this.pwd,
    this.waitRoom = false,
    this.remind = false,
    this.cancelled = false,
    this.meetingId,
    this.activeRoomId,
    Map<String, dynamic> host = const {},
  }) : _host = host;
  factory _LiveSchedule.fromJson(Map<String, dynamic> json) =>
      _$LiveScheduleFromJson(json);

  @override
  final String id;
  @override
  final String code;
  @override
  final String title;
  @override
  final DateTime startAt;
  @override
  final int durationMin;
  @override
  @JsonKey()
  final bool pwdEnabled;
  @override
  final String? pwd;
  @override
  @JsonKey()
  final bool waitRoom;
  @override
  @JsonKey()
  final bool remind;
  @override
  @JsonKey()
  final bool cancelled;
  @override
  final String? meetingId;
  @override
  final String? activeRoomId;
  final Map<String, dynamic> _host;
  @override
  @JsonKey()
  Map<String, dynamic> get host {
    if (_host is EqualUnmodifiableMapView) return _host;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_host);
  }

  /// Create a copy of LiveSchedule
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$LiveScheduleCopyWith<_LiveSchedule> get copyWith =>
      __$LiveScheduleCopyWithImpl<_LiveSchedule>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$LiveScheduleToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _LiveSchedule &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.startAt, startAt) || other.startAt == startAt) &&
            (identical(other.durationMin, durationMin) ||
                other.durationMin == durationMin) &&
            (identical(other.pwdEnabled, pwdEnabled) ||
                other.pwdEnabled == pwdEnabled) &&
            (identical(other.pwd, pwd) || other.pwd == pwd) &&
            (identical(other.waitRoom, waitRoom) ||
                other.waitRoom == waitRoom) &&
            (identical(other.remind, remind) || other.remind == remind) &&
            (identical(other.cancelled, cancelled) ||
                other.cancelled == cancelled) &&
            (identical(other.meetingId, meetingId) ||
                other.meetingId == meetingId) &&
            (identical(other.activeRoomId, activeRoomId) ||
                other.activeRoomId == activeRoomId) &&
            const DeepCollectionEquality().equals(other.host, _host));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(
      runtimeType,
      id,
      code,
      title,
      startAt,
      durationMin,
      pwdEnabled,
      pwd,
      waitRoom,
      remind,
      cancelled,
      meetingId,
      activeRoomId,
      const DeepCollectionEquality().hash(_host),
    );
  }

  @override
  String toString() {
    return 'LiveSchedule(id: $id, code: $code, title: $title, startAt: $startAt, durationMin: $durationMin, pwdEnabled: $pwdEnabled, pwd: $pwd, waitRoom: $waitRoom, remind: $remind, cancelled: $cancelled, meetingId: $meetingId, activeRoomId: $activeRoomId, host: $host)';
  }
}

/// @nodoc
abstract mixin class _$LiveScheduleCopyWith<$Res>
    implements $LiveScheduleCopyWith<$Res> {
  factory _$LiveScheduleCopyWith(
    _LiveSchedule value,
    $Res Function(_LiveSchedule) _then,
  ) = __$LiveScheduleCopyWithImpl;
  @override
  @useResult
  $Res call({
    String id,
    String code,
    String title,
    DateTime startAt,
    int durationMin,
    bool pwdEnabled,
    String? pwd,
    bool waitRoom,
    bool remind,
    bool cancelled,
    String? meetingId,
    String? activeRoomId,
    Map<String, dynamic> host,
  });
}

/// @nodoc
class __$LiveScheduleCopyWithImpl<$Res>
    implements _$LiveScheduleCopyWith<$Res> {
  __$LiveScheduleCopyWithImpl(this._self, this._then);

  final _LiveSchedule _self;
  final $Res Function(_LiveSchedule) _then;

  /// Create a copy of LiveSchedule
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? code = null,
    Object? title = null,
    Object? startAt = null,
    Object? durationMin = null,
    Object? pwdEnabled = null,
    Object? pwd = freezed,
    Object? waitRoom = null,
    Object? remind = null,
    Object? cancelled = null,
    Object? meetingId = freezed,
    Object? activeRoomId = freezed,
    Object? host = null,
  }) {
    return _then(
      _LiveSchedule(
        id: null == id
            ? _self.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        code: null == code
            ? _self.code
            : code // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _self.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        startAt: null == startAt
            ? _self.startAt
            : startAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        durationMin: null == durationMin
            ? _self.durationMin
            : durationMin // ignore: cast_nullable_to_non_nullable
                  as int,
        pwdEnabled: null == pwdEnabled
            ? _self.pwdEnabled
            : pwdEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        pwd: freezed == pwd
            ? _self.pwd
            : pwd // ignore: cast_nullable_to_non_nullable
                  as String?,
        waitRoom: null == waitRoom
            ? _self.waitRoom
            : waitRoom // ignore: cast_nullable_to_non_nullable
                  as bool,
        remind: null == remind
            ? _self.remind
            : remind // ignore: cast_nullable_to_non_nullable
                  as bool,
        cancelled: null == cancelled
            ? _self.cancelled
            : cancelled // ignore: cast_nullable_to_non_nullable
                  as bool,
        meetingId: freezed == meetingId
            ? _self.meetingId
            : meetingId // ignore: cast_nullable_to_non_nullable
                  as String?,
        activeRoomId: freezed == activeRoomId
            ? _self.activeRoomId
            : activeRoomId // ignore: cast_nullable_to_non_nullable
                  as String?,
        host: null == host
            ? _self._host
            : host // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>,
      ),
    );
  }
}

/// @nodoc
mixin _$LiveRecording {
  bool get active;
  int get epoch;
  DateTime? get startedAt;
  List<LiveRecordingRequest> get requests;

  /// Create a copy of LiveRecording
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $LiveRecordingCopyWith<LiveRecording> get copyWith =>
      _$LiveRecordingCopyWithImpl<LiveRecording>(
        this as LiveRecording,
        _$identity,
      );

  /// Serializes this LiveRecording to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as LiveRecording;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is LiveRecording &&
            (identical(other.active, _this.active) ||
                other.active == _this.active) &&
            (identical(other.epoch, _this.epoch) ||
                other.epoch == _this.epoch) &&
            (identical(other.startedAt, _this.startedAt) ||
                other.startedAt == _this.startedAt) &&
            const DeepCollectionEquality().equals(
              other.requests,
              _this.requests,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as LiveRecording;
    return Object.hash(
      runtimeType,
      _this.active,
      _this.epoch,
      _this.startedAt,
      const DeepCollectionEquality().hash(_this.requests),
    );
  }

  @override
  String toString() {
    final _this = this as LiveRecording;
    return 'LiveRecording(active: ${_this.active}, epoch: ${_this.epoch}, startedAt: ${_this.startedAt}, requests: ${_this.requests})';
  }
}

/// @nodoc
abstract mixin class $LiveRecordingCopyWith<$Res> {
  factory $LiveRecordingCopyWith(
    LiveRecording value,
    $Res Function(LiveRecording) _then,
  ) = _$LiveRecordingCopyWithImpl;
  @useResult
  $Res call({
    bool active,
    int epoch,
    DateTime? startedAt,
    List<LiveRecordingRequest> requests,
  });
}

/// @nodoc
class _$LiveRecordingCopyWithImpl<$Res>
    implements $LiveRecordingCopyWith<$Res> {
  _$LiveRecordingCopyWithImpl(this._self, this._then);

  final LiveRecording _self;
  final $Res Function(LiveRecording) _then;

  /// Create a copy of LiveRecording
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? active = null,
    Object? epoch = null,
    Object? startedAt = freezed,
    Object? requests = null,
  }) {
    return _then(
      LiveRecording(
        active: null == active
            ? _self.active
            : active // ignore: cast_nullable_to_non_nullable
                  as bool,
        epoch: null == epoch
            ? _self.epoch
            : epoch // ignore: cast_nullable_to_non_nullable
                  as int,
        startedAt: freezed == startedAt
            ? _self.startedAt
            : startedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        requests: null == requests
            ? _self.requests
            : requests // ignore: cast_nullable_to_non_nullable
                  as List<LiveRecordingRequest>,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [LiveRecording].
extension LiveRecordingPatterns on LiveRecording {
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
    TResult Function(_LiveRecording value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _LiveRecording() when $default != null:
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
    TResult Function(_LiveRecording value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LiveRecording():
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
    TResult? Function(_LiveRecording value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LiveRecording() when $default != null:
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
      bool active,
      int epoch,
      DateTime? startedAt,
      List<LiveRecordingRequest> requests,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _LiveRecording() when $default != null:
        return $default(
          _that.active,
          _that.epoch,
          _that.startedAt,
          _that.requests,
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
      bool active,
      int epoch,
      DateTime? startedAt,
      List<LiveRecordingRequest> requests,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LiveRecording():
        return $default(
          _that.active,
          _that.epoch,
          _that.startedAt,
          _that.requests,
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
      bool active,
      int epoch,
      DateTime? startedAt,
      List<LiveRecordingRequest> requests,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LiveRecording() when $default != null:
        return $default(
          _that.active,
          _that.epoch,
          _that.startedAt,
          _that.requests,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _LiveRecording implements LiveRecording {
  const _LiveRecording({
    this.active = false,
    this.epoch = 0,
    this.startedAt,
    List<LiveRecordingRequest> requests = const [],
  }) : _requests = requests;
  factory _LiveRecording.fromJson(Map<String, dynamic> json) =>
      _$LiveRecordingFromJson(json);

  @override
  @JsonKey()
  final bool active;
  @override
  @JsonKey()
  final int epoch;
  @override
  final DateTime? startedAt;
  final List<LiveRecordingRequest> _requests;
  @override
  @JsonKey()
  List<LiveRecordingRequest> get requests {
    if (_requests is EqualUnmodifiableListView) return _requests;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_requests);
  }

  /// Create a copy of LiveRecording
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$LiveRecordingCopyWith<_LiveRecording> get copyWith =>
      __$LiveRecordingCopyWithImpl<_LiveRecording>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$LiveRecordingToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _LiveRecording &&
            (identical(other.active, active) || other.active == active) &&
            (identical(other.epoch, epoch) || other.epoch == epoch) &&
            (identical(other.startedAt, startedAt) ||
                other.startedAt == startedAt) &&
            const DeepCollectionEquality().equals(other.requests, _requests));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(
      runtimeType,
      active,
      epoch,
      startedAt,
      const DeepCollectionEquality().hash(_requests),
    );
  }

  @override
  String toString() {
    return 'LiveRecording(active: $active, epoch: $epoch, startedAt: $startedAt, requests: $requests)';
  }
}

/// @nodoc
abstract mixin class _$LiveRecordingCopyWith<$Res>
    implements $LiveRecordingCopyWith<$Res> {
  factory _$LiveRecordingCopyWith(
    _LiveRecording value,
    $Res Function(_LiveRecording) _then,
  ) = __$LiveRecordingCopyWithImpl;
  @override
  @useResult
  $Res call({
    bool active,
    int epoch,
    DateTime? startedAt,
    List<LiveRecordingRequest> requests,
  });
}

/// @nodoc
class __$LiveRecordingCopyWithImpl<$Res>
    implements _$LiveRecordingCopyWith<$Res> {
  __$LiveRecordingCopyWithImpl(this._self, this._then);

  final _LiveRecording _self;
  final $Res Function(_LiveRecording) _then;

  /// Create a copy of LiveRecording
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? active = null,
    Object? epoch = null,
    Object? startedAt = freezed,
    Object? requests = null,
  }) {
    return _then(
      _LiveRecording(
        active: null == active
            ? _self.active
            : active // ignore: cast_nullable_to_non_nullable
                  as bool,
        epoch: null == epoch
            ? _self.epoch
            : epoch // ignore: cast_nullable_to_non_nullable
                  as int,
        startedAt: freezed == startedAt
            ? _self.startedAt
            : startedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        requests: null == requests
            ? _self._requests
            : requests // ignore: cast_nullable_to_non_nullable
                  as List<LiveRecordingRequest>,
      ),
    );
  }
}

/// @nodoc
mixin _$LiveRecordingRequest {
  String get participantId;
  String get requestId;
  String get name;
  String get status;

  /// Create a copy of LiveRecordingRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $LiveRecordingRequestCopyWith<LiveRecordingRequest> get copyWith =>
      _$LiveRecordingRequestCopyWithImpl<LiveRecordingRequest>(
        this as LiveRecordingRequest,
        _$identity,
      );

  /// Serializes this LiveRecordingRequest to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as LiveRecordingRequest;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is LiveRecordingRequest &&
            (identical(other.participantId, _this.participantId) ||
                other.participantId == _this.participantId) &&
            (identical(other.requestId, _this.requestId) ||
                other.requestId == _this.requestId) &&
            (identical(other.name, _this.name) || other.name == _this.name) &&
            (identical(other.status, _this.status) ||
                other.status == _this.status));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as LiveRecordingRequest;
    return Object.hash(
      runtimeType,
      _this.participantId,
      _this.requestId,
      _this.name,
      _this.status,
    );
  }

  @override
  String toString() {
    final _this = this as LiveRecordingRequest;
    return 'LiveRecordingRequest(participantId: ${_this.participantId}, requestId: ${_this.requestId}, name: ${_this.name}, status: ${_this.status})';
  }
}

/// @nodoc
abstract mixin class $LiveRecordingRequestCopyWith<$Res> {
  factory $LiveRecordingRequestCopyWith(
    LiveRecordingRequest value,
    $Res Function(LiveRecordingRequest) _then,
  ) = _$LiveRecordingRequestCopyWithImpl;
  @useResult
  $Res call({
    String participantId,
    String requestId,
    String name,
    String status,
  });
}

/// @nodoc
class _$LiveRecordingRequestCopyWithImpl<$Res>
    implements $LiveRecordingRequestCopyWith<$Res> {
  _$LiveRecordingRequestCopyWithImpl(this._self, this._then);

  final LiveRecordingRequest _self;
  final $Res Function(LiveRecordingRequest) _then;

  /// Create a copy of LiveRecordingRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? participantId = null,
    Object? requestId = null,
    Object? name = null,
    Object? status = null,
  }) {
    return _then(
      LiveRecordingRequest(
        participantId: null == participantId
            ? _self.participantId
            : participantId // ignore: cast_nullable_to_non_nullable
                  as String,
        requestId: null == requestId
            ? _self.requestId
            : requestId // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _self.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _self.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [LiveRecordingRequest].
extension LiveRecordingRequestPatterns on LiveRecordingRequest {
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
    TResult Function(_LiveRecordingRequest value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _LiveRecordingRequest() when $default != null:
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
    TResult Function(_LiveRecordingRequest value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LiveRecordingRequest():
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
    TResult? Function(_LiveRecordingRequest value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LiveRecordingRequest() when $default != null:
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
      String participantId,
      String requestId,
      String name,
      String status,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _LiveRecordingRequest() when $default != null:
        return $default(
          _that.participantId,
          _that.requestId,
          _that.name,
          _that.status,
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
      String participantId,
      String requestId,
      String name,
      String status,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LiveRecordingRequest():
        return $default(
          _that.participantId,
          _that.requestId,
          _that.name,
          _that.status,
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
      String participantId,
      String requestId,
      String name,
      String status,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LiveRecordingRequest() when $default != null:
        return $default(
          _that.participantId,
          _that.requestId,
          _that.name,
          _that.status,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _LiveRecordingRequest implements LiveRecordingRequest {
  const _LiveRecordingRequest({
    required this.participantId,
    required this.requestId,
    required this.name,
    required this.status,
  });
  factory _LiveRecordingRequest.fromJson(Map<String, dynamic> json) =>
      _$LiveRecordingRequestFromJson(json);

  @override
  final String participantId;
  @override
  final String requestId;
  @override
  final String name;
  @override
  final String status;

  /// Create a copy of LiveRecordingRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$LiveRecordingRequestCopyWith<_LiveRecordingRequest> get copyWith =>
      __$LiveRecordingRequestCopyWithImpl<_LiveRecordingRequest>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$LiveRecordingRequestToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _LiveRecordingRequest &&
            (identical(other.participantId, participantId) ||
                other.participantId == participantId) &&
            (identical(other.requestId, requestId) ||
                other.requestId == requestId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.status, status) || other.status == status));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(runtimeType, participantId, requestId, name, status);
  }

  @override
  String toString() {
    return 'LiveRecordingRequest(participantId: $participantId, requestId: $requestId, name: $name, status: $status)';
  }
}

/// @nodoc
abstract mixin class _$LiveRecordingRequestCopyWith<$Res>
    implements $LiveRecordingRequestCopyWith<$Res> {
  factory _$LiveRecordingRequestCopyWith(
    _LiveRecordingRequest value,
    $Res Function(_LiveRecordingRequest) _then,
  ) = __$LiveRecordingRequestCopyWithImpl;
  @override
  @useResult
  $Res call({
    String participantId,
    String requestId,
    String name,
    String status,
  });
}

/// @nodoc
class __$LiveRecordingRequestCopyWithImpl<$Res>
    implements _$LiveRecordingRequestCopyWith<$Res> {
  __$LiveRecordingRequestCopyWithImpl(this._self, this._then);

  final _LiveRecordingRequest _self;
  final $Res Function(_LiveRecordingRequest) _then;

  /// Create a copy of LiveRecordingRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? participantId = null,
    Object? requestId = null,
    Object? name = null,
    Object? status = null,
  }) {
    return _then(
      _LiveRecordingRequest(
        participantId: null == participantId
            ? _self.participantId
            : participantId // ignore: cast_nullable_to_non_nullable
                  as String,
        requestId: null == requestId
            ? _self.requestId
            : requestId // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _self.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _self.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
mixin _$LiveRoomState {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is LiveRoomState);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'LiveRoomState()';
  }
}

/// @nodoc
class $LiveRoomStateCopyWith<$Res> {
  $LiveRoomStateCopyWith(LiveRoomState _, $Res Function(LiveRoomState) __);
}

/// Adds pattern-matching-related methods to [LiveRoomState].
extension LiveRoomStatePatterns on LiveRoomState {
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
    TResult Function(RoomIdle value)? idle,
    TResult Function(RoomJoining value)? joining,
    TResult Function(RoomWaiting value)? waiting,
    TResult Function(RoomActive value)? active,
    TResult Function(RoomEnded value)? ended,
    TResult Function(RoomFailed value)? failed,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case RoomIdle() when idle != null:
        return idle(_that);
      case RoomJoining() when joining != null:
        return joining(_that);
      case RoomWaiting() when waiting != null:
        return waiting(_that);
      case RoomActive() when active != null:
        return active(_that);
      case RoomEnded() when ended != null:
        return ended(_that);
      case RoomFailed() when failed != null:
        return failed(_that);
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
    required TResult Function(RoomIdle value) idle,
    required TResult Function(RoomJoining value) joining,
    required TResult Function(RoomWaiting value) waiting,
    required TResult Function(RoomActive value) active,
    required TResult Function(RoomEnded value) ended,
    required TResult Function(RoomFailed value) failed,
  }) {
    final _that = this;
    switch (_that) {
      case RoomIdle():
        return idle(_that);
      case RoomJoining():
        return joining(_that);
      case RoomWaiting():
        return waiting(_that);
      case RoomActive():
        return active(_that);
      case RoomEnded():
        return ended(_that);
      case RoomFailed():
        return failed(_that);
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
    TResult? Function(RoomIdle value)? idle,
    TResult? Function(RoomJoining value)? joining,
    TResult? Function(RoomWaiting value)? waiting,
    TResult? Function(RoomActive value)? active,
    TResult? Function(RoomEnded value)? ended,
    TResult? Function(RoomFailed value)? failed,
  }) {
    final _that = this;
    switch (_that) {
      case RoomIdle() when idle != null:
        return idle(_that);
      case RoomJoining() when joining != null:
        return joining(_that);
      case RoomWaiting() when waiting != null:
        return waiting(_that);
      case RoomActive() when active != null:
        return active(_that);
      case RoomEnded() when ended != null:
        return ended(_that);
      case RoomFailed() when failed != null:
        return failed(_that);
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
    TResult Function()? idle,
    TResult Function()? joining,
    TResult Function(LiveRoom room, LiveParticipant self, String? error)?
    waiting,
    TResult Function(
      LiveRoom room,
      LiveParticipant self,
      List<LiveChat> chats,
      String connection,
      String media,
      bool busy,
      String capture,
      String? captureError,
      String? error,
    )?
    active,
    TResult Function(String? meetingId)? ended,
    TResult Function(String message)? failed,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case RoomIdle() when idle != null:
        return idle();
      case RoomJoining() when joining != null:
        return joining();
      case RoomWaiting() when waiting != null:
        return waiting(_that.room, _that.self, _that.error);
      case RoomActive() when active != null:
        return active(
          _that.room,
          _that.self,
          _that.chats,
          _that.connection,
          _that.media,
          _that.busy,
          _that.capture,
          _that.captureError,
          _that.error,
        );
      case RoomEnded() when ended != null:
        return ended(_that.meetingId);
      case RoomFailed() when failed != null:
        return failed(_that.message);
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
    required TResult Function() idle,
    required TResult Function() joining,
    required TResult Function(
      LiveRoom room,
      LiveParticipant self,
      String? error,
    )
    waiting,
    required TResult Function(
      LiveRoom room,
      LiveParticipant self,
      List<LiveChat> chats,
      String connection,
      String media,
      bool busy,
      String capture,
      String? captureError,
      String? error,
    )
    active,
    required TResult Function(String? meetingId) ended,
    required TResult Function(String message) failed,
  }) {
    final _that = this;
    switch (_that) {
      case RoomIdle():
        return idle();
      case RoomJoining():
        return joining();
      case RoomWaiting():
        return waiting(_that.room, _that.self, _that.error);
      case RoomActive():
        return active(
          _that.room,
          _that.self,
          _that.chats,
          _that.connection,
          _that.media,
          _that.busy,
          _that.capture,
          _that.captureError,
          _that.error,
        );
      case RoomEnded():
        return ended(_that.meetingId);
      case RoomFailed():
        return failed(_that.message);
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
    TResult? Function()? idle,
    TResult? Function()? joining,
    TResult? Function(LiveRoom room, LiveParticipant self, String? error)?
    waiting,
    TResult? Function(
      LiveRoom room,
      LiveParticipant self,
      List<LiveChat> chats,
      String connection,
      String media,
      bool busy,
      String capture,
      String? captureError,
      String? error,
    )?
    active,
    TResult? Function(String? meetingId)? ended,
    TResult? Function(String message)? failed,
  }) {
    final _that = this;
    switch (_that) {
      case RoomIdle() when idle != null:
        return idle();
      case RoomJoining() when joining != null:
        return joining();
      case RoomWaiting() when waiting != null:
        return waiting(_that.room, _that.self, _that.error);
      case RoomActive() when active != null:
        return active(
          _that.room,
          _that.self,
          _that.chats,
          _that.connection,
          _that.media,
          _that.busy,
          _that.capture,
          _that.captureError,
          _that.error,
        );
      case RoomEnded() when ended != null:
        return ended(_that.meetingId);
      case RoomFailed() when failed != null:
        return failed(_that.message);
      case _:
        return null;
    }
  }
}

/// @nodoc

class RoomIdle implements LiveRoomState {
  const RoomIdle();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is RoomIdle);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'LiveRoomState.idle()';
  }
}

/// @nodoc

class RoomJoining implements LiveRoomState {
  const RoomJoining();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is RoomJoining);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'LiveRoomState.joining()';
  }
}

/// @nodoc

class RoomWaiting implements LiveRoomState {
  const RoomWaiting({required this.room, required this.self, this.error});

  final LiveRoom room;
  final LiveParticipant self;
  final String? error;

  /// Create a copy of LiveRoomState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $RoomWaitingCopyWith<RoomWaiting> get copyWith =>
      _$RoomWaitingCopyWithImpl<RoomWaiting>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is RoomWaiting &&
            (identical(other.room, room) || other.room == room) &&
            (identical(other.self, self) || other.self == self) &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, room, self, error);
  }

  @override
  String toString() {
    return 'LiveRoomState.waiting(room: $room, self: $self, error: $error)';
  }
}

/// @nodoc
abstract mixin class $RoomWaitingCopyWith<$Res>
    implements $LiveRoomStateCopyWith<$Res> {
  factory $RoomWaitingCopyWith(
    RoomWaiting value,
    $Res Function(RoomWaiting) _then,
  ) = _$RoomWaitingCopyWithImpl;
  @useResult
  $Res call({LiveRoom room, LiveParticipant self, String? error});

  $LiveRoomCopyWith<$Res> get room;
  $LiveParticipantCopyWith<$Res> get self;
}

/// @nodoc
class _$RoomWaitingCopyWithImpl<$Res> implements $RoomWaitingCopyWith<$Res> {
  _$RoomWaitingCopyWithImpl(this._self, this._then);

  final RoomWaiting _self;
  final $Res Function(RoomWaiting) _then;

  /// Create a copy of LiveRoomState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? room = null,
    Object? self = null,
    Object? error = freezed,
  }) {
    return _then(
      RoomWaiting(
        room: null == room
            ? _self.room
            : room // ignore: cast_nullable_to_non_nullable
                  as LiveRoom,
        self: null == self
            ? _self.self
            : self // ignore: cast_nullable_to_non_nullable
                  as LiveParticipant,
        error: freezed == error
            ? _self.error
            : error // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }

  /// Create a copy of LiveRoomState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $LiveRoomCopyWith<$Res> get room {
    return $LiveRoomCopyWith<$Res>(_self.room, (value) {
      return _then(_self.copyWith(room: value));
    });
  }

  /// Create a copy of LiveRoomState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $LiveParticipantCopyWith<$Res> get self {
    return $LiveParticipantCopyWith<$Res>(_self.self, (value) {
      return _then(_self.copyWith(self: value));
    });
  }
}

/// @nodoc

class RoomActive implements LiveRoomState {
  const RoomActive({
    required this.room,
    required this.self,
    List<LiveChat> chats = const [],
    this.connection = 'connecting',
    this.media = 'idle',
    this.busy = false,
    this.capture = 'waiting',
    this.captureError,
    this.error,
  }) : _chats = chats;

  final LiveRoom room;
  final LiveParticipant self;
  final List<LiveChat> _chats;
  @JsonKey()
  List<LiveChat> get chats {
    if (_chats is EqualUnmodifiableListView) return _chats;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_chats);
  }

  @JsonKey()
  final String connection;
  @JsonKey()
  final String media;
  @JsonKey()
  final bool busy;
  @JsonKey()
  final String capture;
  final String? captureError;
  final String? error;

  /// Create a copy of LiveRoomState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $RoomActiveCopyWith<RoomActive> get copyWith =>
      _$RoomActiveCopyWithImpl<RoomActive>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is RoomActive &&
            (identical(other.room, room) || other.room == room) &&
            (identical(other.self, self) || other.self == self) &&
            const DeepCollectionEquality().equals(other.chats, _chats) &&
            (identical(other.connection, connection) ||
                other.connection == connection) &&
            (identical(other.media, media) || other.media == media) &&
            (identical(other.busy, busy) || other.busy == busy) &&
            (identical(other.capture, capture) || other.capture == capture) &&
            (identical(other.captureError, captureError) ||
                other.captureError == captureError) &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode {
    return Object.hash(
      runtimeType,
      room,
      self,
      const DeepCollectionEquality().hash(_chats),
      connection,
      media,
      busy,
      capture,
      captureError,
      error,
    );
  }

  @override
  String toString() {
    return 'LiveRoomState.active(room: $room, self: $self, chats: $chats, connection: $connection, media: $media, busy: $busy, capture: $capture, captureError: $captureError, error: $error)';
  }
}

/// @nodoc
abstract mixin class $RoomActiveCopyWith<$Res>
    implements $LiveRoomStateCopyWith<$Res> {
  factory $RoomActiveCopyWith(
    RoomActive value,
    $Res Function(RoomActive) _then,
  ) = _$RoomActiveCopyWithImpl;
  @useResult
  $Res call({
    LiveRoom room,
    LiveParticipant self,
    List<LiveChat> chats,
    String connection,
    String media,
    bool busy,
    String capture,
    String? captureError,
    String? error,
  });

  $LiveRoomCopyWith<$Res> get room;
  $LiveParticipantCopyWith<$Res> get self;
}

/// @nodoc
class _$RoomActiveCopyWithImpl<$Res> implements $RoomActiveCopyWith<$Res> {
  _$RoomActiveCopyWithImpl(this._self, this._then);

  final RoomActive _self;
  final $Res Function(RoomActive) _then;

  /// Create a copy of LiveRoomState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? room = null,
    Object? self = null,
    Object? chats = null,
    Object? connection = null,
    Object? media = null,
    Object? busy = null,
    Object? capture = null,
    Object? captureError = freezed,
    Object? error = freezed,
  }) {
    return _then(
      RoomActive(
        room: null == room
            ? _self.room
            : room // ignore: cast_nullable_to_non_nullable
                  as LiveRoom,
        self: null == self
            ? _self.self
            : self // ignore: cast_nullable_to_non_nullable
                  as LiveParticipant,
        chats: null == chats
            ? _self._chats
            : chats // ignore: cast_nullable_to_non_nullable
                  as List<LiveChat>,
        connection: null == connection
            ? _self.connection
            : connection // ignore: cast_nullable_to_non_nullable
                  as String,
        media: null == media
            ? _self.media
            : media // ignore: cast_nullable_to_non_nullable
                  as String,
        busy: null == busy
            ? _self.busy
            : busy // ignore: cast_nullable_to_non_nullable
                  as bool,
        capture: null == capture
            ? _self.capture
            : capture // ignore: cast_nullable_to_non_nullable
                  as String,
        captureError: freezed == captureError
            ? _self.captureError
            : captureError // ignore: cast_nullable_to_non_nullable
                  as String?,
        error: freezed == error
            ? _self.error
            : error // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }

  /// Create a copy of LiveRoomState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $LiveRoomCopyWith<$Res> get room {
    return $LiveRoomCopyWith<$Res>(_self.room, (value) {
      return _then(_self.copyWith(room: value));
    });
  }

  /// Create a copy of LiveRoomState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $LiveParticipantCopyWith<$Res> get self {
    return $LiveParticipantCopyWith<$Res>(_self.self, (value) {
      return _then(_self.copyWith(self: value));
    });
  }
}

/// @nodoc

class RoomEnded implements LiveRoomState {
  const RoomEnded({this.meetingId});

  final String? meetingId;

  /// Create a copy of LiveRoomState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $RoomEndedCopyWith<RoomEnded> get copyWith =>
      _$RoomEndedCopyWithImpl<RoomEnded>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is RoomEnded &&
            (identical(other.meetingId, meetingId) ||
                other.meetingId == meetingId));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, meetingId);
  }

  @override
  String toString() {
    return 'LiveRoomState.ended(meetingId: $meetingId)';
  }
}

/// @nodoc
abstract mixin class $RoomEndedCopyWith<$Res>
    implements $LiveRoomStateCopyWith<$Res> {
  factory $RoomEndedCopyWith(RoomEnded value, $Res Function(RoomEnded) _then) =
      _$RoomEndedCopyWithImpl;
  @useResult
  $Res call({String? meetingId});
}

/// @nodoc
class _$RoomEndedCopyWithImpl<$Res> implements $RoomEndedCopyWith<$Res> {
  _$RoomEndedCopyWithImpl(this._self, this._then);

  final RoomEnded _self;
  final $Res Function(RoomEnded) _then;

  /// Create a copy of LiveRoomState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? meetingId = freezed}) {
    return _then(
      RoomEnded(
        meetingId: freezed == meetingId
            ? _self.meetingId
            : meetingId // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class RoomFailed implements LiveRoomState {
  const RoomFailed(this.message);

  final String message;

  /// Create a copy of LiveRoomState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $RoomFailedCopyWith<RoomFailed> get copyWith =>
      _$RoomFailedCopyWithImpl<RoomFailed>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is RoomFailed &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, message);
  }

  @override
  String toString() {
    return 'LiveRoomState.failed(message: $message)';
  }
}

/// @nodoc
abstract mixin class $RoomFailedCopyWith<$Res>
    implements $LiveRoomStateCopyWith<$Res> {
  factory $RoomFailedCopyWith(
    RoomFailed value,
    $Res Function(RoomFailed) _then,
  ) = _$RoomFailedCopyWithImpl;
  @useResult
  $Res call({String message});
}

/// @nodoc
class _$RoomFailedCopyWithImpl<$Res> implements $RoomFailedCopyWith<$Res> {
  _$RoomFailedCopyWithImpl(this._self, this._then);

  final RoomFailed _self;
  final $Res Function(RoomFailed) _then;

  /// Create a copy of LiveRoomState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? message = null}) {
    return _then(
      RoomFailed(
        null == message
            ? _self.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}
