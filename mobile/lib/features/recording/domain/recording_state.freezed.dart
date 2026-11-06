// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recording_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LiveTranscript {
  int get seq;
  String get text;
  double get startSec;
  double get endSec;

  /// Create a copy of LiveTranscript
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $LiveTranscriptCopyWith<LiveTranscript> get copyWith =>
      _$LiveTranscriptCopyWithImpl<LiveTranscript>(
        this as LiveTranscript,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    final _this = this as LiveTranscript;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is LiveTranscript &&
            (identical(other.seq, _this.seq) || other.seq == _this.seq) &&
            (identical(other.text, _this.text) || other.text == _this.text) &&
            (identical(other.startSec, _this.startSec) ||
                other.startSec == _this.startSec) &&
            (identical(other.endSec, _this.endSec) ||
                other.endSec == _this.endSec));
  }

  @override
  int get hashCode {
    final _this = this as LiveTranscript;
    return Object.hash(
      runtimeType,
      _this.seq,
      _this.text,
      _this.startSec,
      _this.endSec,
    );
  }

  @override
  String toString() {
    final _this = this as LiveTranscript;
    return 'LiveTranscript(seq: ${_this.seq}, text: ${_this.text}, startSec: ${_this.startSec}, endSec: ${_this.endSec})';
  }
}

/// @nodoc
abstract mixin class $LiveTranscriptCopyWith<$Res> {
  factory $LiveTranscriptCopyWith(
    LiveTranscript value,
    $Res Function(LiveTranscript) _then,
  ) = _$LiveTranscriptCopyWithImpl;
  @useResult
  $Res call({int seq, String text, double startSec, double endSec});
}

/// @nodoc
class _$LiveTranscriptCopyWithImpl<$Res>
    implements $LiveTranscriptCopyWith<$Res> {
  _$LiveTranscriptCopyWithImpl(this._self, this._then);

  final LiveTranscript _self;
  final $Res Function(LiveTranscript) _then;

  /// Create a copy of LiveTranscript
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? seq = null,
    Object? text = null,
    Object? startSec = null,
    Object? endSec = null,
  }) {
    return _then(
      LiveTranscript(
        seq: null == seq
            ? _self.seq
            : seq // ignore: cast_nullable_to_non_nullable
                  as int,
        text: null == text
            ? _self.text
            : text // ignore: cast_nullable_to_non_nullable
                  as String,
        startSec: null == startSec
            ? _self.startSec
            : startSec // ignore: cast_nullable_to_non_nullable
                  as double,
        endSec: null == endSec
            ? _self.endSec
            : endSec // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [LiveTranscript].
extension LiveTranscriptPatterns on LiveTranscript {
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
    TResult Function(_LiveTranscript value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _LiveTranscript() when $default != null:
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
    TResult Function(_LiveTranscript value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LiveTranscript():
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
    TResult? Function(_LiveTranscript value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LiveTranscript() when $default != null:
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
    TResult Function(int seq, String text, double startSec, double endSec)?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _LiveTranscript() when $default != null:
        return $default(_that.seq, _that.text, _that.startSec, _that.endSec);
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
    TResult Function(int seq, String text, double startSec, double endSec)
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LiveTranscript():
        return $default(_that.seq, _that.text, _that.startSec, _that.endSec);
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
    TResult? Function(int seq, String text, double startSec, double endSec)?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LiveTranscript() when $default != null:
        return $default(_that.seq, _that.text, _that.startSec, _that.endSec);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _LiveTranscript implements LiveTranscript {
  const _LiveTranscript({
    required this.seq,
    required this.text,
    required this.startSec,
    required this.endSec,
  });

  @override
  final int seq;
  @override
  final String text;
  @override
  final double startSec;
  @override
  final double endSec;

  /// Create a copy of LiveTranscript
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$LiveTranscriptCopyWith<_LiveTranscript> get copyWith =>
      __$LiveTranscriptCopyWithImpl<_LiveTranscript>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _LiveTranscript &&
            (identical(other.seq, seq) || other.seq == seq) &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.startSec, startSec) ||
                other.startSec == startSec) &&
            (identical(other.endSec, endSec) || other.endSec == endSec));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, seq, text, startSec, endSec);
  }

  @override
  String toString() {
    return 'LiveTranscript(seq: $seq, text: $text, startSec: $startSec, endSec: $endSec)';
  }
}

/// @nodoc
abstract mixin class _$LiveTranscriptCopyWith<$Res>
    implements $LiveTranscriptCopyWith<$Res> {
  factory _$LiveTranscriptCopyWith(
    _LiveTranscript value,
    $Res Function(_LiveTranscript) _then,
  ) = __$LiveTranscriptCopyWithImpl;
  @override
  @useResult
  $Res call({int seq, String text, double startSec, double endSec});
}

/// @nodoc
class __$LiveTranscriptCopyWithImpl<$Res>
    implements _$LiveTranscriptCopyWith<$Res> {
  __$LiveTranscriptCopyWithImpl(this._self, this._then);

  final _LiveTranscript _self;
  final $Res Function(_LiveTranscript) _then;

  /// Create a copy of LiveTranscript
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? seq = null,
    Object? text = null,
    Object? startSec = null,
    Object? endSec = null,
  }) {
    return _then(
      _LiveTranscript(
        seq: null == seq
            ? _self.seq
            : seq // ignore: cast_nullable_to_non_nullable
                  as int,
        text: null == text
            ? _self.text
            : text // ignore: cast_nullable_to_non_nullable
                  as String,
        startSec: null == startSec
            ? _self.startSec
            : startSec // ignore: cast_nullable_to_non_nullable
                  as double,
        endSec: null == endSec
            ? _self.endSec
            : endSec // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
mixin _$RecordingSession {
  String get meetingId;
  String get title;

  /// The user renamed the meeting during the recording → `PATCH` the title at stop.
  bool get titleEdited;
  RecordingSource get source;

  /// Transcription language; `null` = auto-detect.
  String? get language;

  /// Captured audio duration (pauses excluded).
  Duration get elapsed;

  /// Ordered by `seq`.
  List<LiveTranscript> get transcripts;

  /// Segments waiting in the persistent upload queue (offline / server errors).
  int get pendingUploads;

  /// Local `.m4a` path.
  String get audioPath;

  /// Create a copy of RecordingSession
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $RecordingSessionCopyWith<RecordingSession> get copyWith =>
      _$RecordingSessionCopyWithImpl<RecordingSession>(
        this as RecordingSession,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    final _this = this as RecordingSession;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is RecordingSession &&
            (identical(other.meetingId, _this.meetingId) ||
                other.meetingId == _this.meetingId) &&
            (identical(other.title, _this.title) ||
                other.title == _this.title) &&
            (identical(other.titleEdited, _this.titleEdited) ||
                other.titleEdited == _this.titleEdited) &&
            (identical(other.source, _this.source) ||
                other.source == _this.source) &&
            (identical(other.language, _this.language) ||
                other.language == _this.language) &&
            (identical(other.elapsed, _this.elapsed) ||
                other.elapsed == _this.elapsed) &&
            const DeepCollectionEquality().equals(
              other.transcripts,
              _this.transcripts,
            ) &&
            (identical(other.pendingUploads, _this.pendingUploads) ||
                other.pendingUploads == _this.pendingUploads) &&
            (identical(other.audioPath, _this.audioPath) ||
                other.audioPath == _this.audioPath));
  }

  @override
  int get hashCode {
    final _this = this as RecordingSession;
    return Object.hash(
      runtimeType,
      _this.meetingId,
      _this.title,
      _this.titleEdited,
      _this.source,
      _this.language,
      _this.elapsed,
      const DeepCollectionEquality().hash(_this.transcripts),
      _this.pendingUploads,
      _this.audioPath,
    );
  }

  @override
  String toString() {
    final _this = this as RecordingSession;
    return 'RecordingSession(meetingId: ${_this.meetingId}, title: ${_this.title}, titleEdited: ${_this.titleEdited}, source: ${_this.source}, language: ${_this.language}, elapsed: ${_this.elapsed}, transcripts: ${_this.transcripts}, pendingUploads: ${_this.pendingUploads}, audioPath: ${_this.audioPath})';
  }
}

/// @nodoc
abstract mixin class $RecordingSessionCopyWith<$Res> {
  factory $RecordingSessionCopyWith(
    RecordingSession value,
    $Res Function(RecordingSession) _then,
  ) = _$RecordingSessionCopyWithImpl;
  @useResult
  $Res call({
    String meetingId,
    String title,
    bool titleEdited,
    RecordingSource source,
    String? language,
    Duration elapsed,
    List<LiveTranscript> transcripts,
    int pendingUploads,
    String audioPath,
  });
}

/// @nodoc
class _$RecordingSessionCopyWithImpl<$Res>
    implements $RecordingSessionCopyWith<$Res> {
  _$RecordingSessionCopyWithImpl(this._self, this._then);

  final RecordingSession _self;
  final $Res Function(RecordingSession) _then;

  /// Create a copy of RecordingSession
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? meetingId = null,
    Object? title = null,
    Object? titleEdited = null,
    Object? source = null,
    Object? language = freezed,
    Object? elapsed = null,
    Object? transcripts = null,
    Object? pendingUploads = null,
    Object? audioPath = null,
  }) {
    return _then(
      RecordingSession(
        meetingId: null == meetingId
            ? _self.meetingId
            : meetingId // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _self.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        titleEdited: null == titleEdited
            ? _self.titleEdited
            : titleEdited // ignore: cast_nullable_to_non_nullable
                  as bool,
        source: null == source
            ? _self.source
            : source // ignore: cast_nullable_to_non_nullable
                  as RecordingSource,
        language: freezed == language
            ? _self.language
            : language // ignore: cast_nullable_to_non_nullable
                  as String?,
        elapsed: null == elapsed
            ? _self.elapsed
            : elapsed // ignore: cast_nullable_to_non_nullable
                  as Duration,
        transcripts: null == transcripts
            ? _self.transcripts
            : transcripts // ignore: cast_nullable_to_non_nullable
                  as List<LiveTranscript>,
        pendingUploads: null == pendingUploads
            ? _self.pendingUploads
            : pendingUploads // ignore: cast_nullable_to_non_nullable
                  as int,
        audioPath: null == audioPath
            ? _self.audioPath
            : audioPath // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [RecordingSession].
extension RecordingSessionPatterns on RecordingSession {
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
    TResult Function(_RecordingSession value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _RecordingSession() when $default != null:
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
    TResult Function(_RecordingSession value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RecordingSession():
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
    TResult? Function(_RecordingSession value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RecordingSession() when $default != null:
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
      String title,
      bool titleEdited,
      RecordingSource source,
      String? language,
      Duration elapsed,
      List<LiveTranscript> transcripts,
      int pendingUploads,
      String audioPath,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _RecordingSession() when $default != null:
        return $default(
          _that.meetingId,
          _that.title,
          _that.titleEdited,
          _that.source,
          _that.language,
          _that.elapsed,
          _that.transcripts,
          _that.pendingUploads,
          _that.audioPath,
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
      String title,
      bool titleEdited,
      RecordingSource source,
      String? language,
      Duration elapsed,
      List<LiveTranscript> transcripts,
      int pendingUploads,
      String audioPath,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RecordingSession():
        return $default(
          _that.meetingId,
          _that.title,
          _that.titleEdited,
          _that.source,
          _that.language,
          _that.elapsed,
          _that.transcripts,
          _that.pendingUploads,
          _that.audioPath,
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
      String title,
      bool titleEdited,
      RecordingSource source,
      String? language,
      Duration elapsed,
      List<LiveTranscript> transcripts,
      int pendingUploads,
      String audioPath,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RecordingSession() when $default != null:
        return $default(
          _that.meetingId,
          _that.title,
          _that.titleEdited,
          _that.source,
          _that.language,
          _that.elapsed,
          _that.transcripts,
          _that.pendingUploads,
          _that.audioPath,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc

class _RecordingSession implements RecordingSession {
  const _RecordingSession({
    required this.meetingId,
    required this.title,
    this.titleEdited = false,
    required this.source,
    this.language,
    this.elapsed = Duration.zero,
    List<LiveTranscript> transcripts = const <LiveTranscript>[],
    this.pendingUploads = 0,
    required this.audioPath,
  }) : _transcripts = transcripts;

  @override
  final String meetingId;
  @override
  final String title;

  /// The user renamed the meeting during the recording → `PATCH` the title at stop.
  @override
  @JsonKey()
  final bool titleEdited;
  @override
  final RecordingSource source;

  /// Transcription language; `null` = auto-detect.
  @override
  final String? language;

  /// Captured audio duration (pauses excluded).
  @override
  @JsonKey()
  final Duration elapsed;

  /// Ordered by `seq`.
  final List<LiveTranscript> _transcripts;

  /// Ordered by `seq`.
  @override
  @JsonKey()
  List<LiveTranscript> get transcripts {
    if (_transcripts is EqualUnmodifiableListView) return _transcripts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_transcripts);
  }

  /// Segments waiting in the persistent upload queue (offline / server errors).
  @override
  @JsonKey()
  final int pendingUploads;

  /// Local `.m4a` path.
  @override
  final String audioPath;

  /// Create a copy of RecordingSession
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$RecordingSessionCopyWith<_RecordingSession> get copyWith =>
      __$RecordingSessionCopyWithImpl<_RecordingSession>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _RecordingSession &&
            (identical(other.meetingId, meetingId) ||
                other.meetingId == meetingId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.titleEdited, titleEdited) ||
                other.titleEdited == titleEdited) &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.language, language) ||
                other.language == language) &&
            (identical(other.elapsed, elapsed) || other.elapsed == elapsed) &&
            const DeepCollectionEquality().equals(
              other.transcripts,
              _transcripts,
            ) &&
            (identical(other.pendingUploads, pendingUploads) ||
                other.pendingUploads == pendingUploads) &&
            (identical(other.audioPath, audioPath) ||
                other.audioPath == audioPath));
  }

  @override
  int get hashCode {
    return Object.hash(
      runtimeType,
      meetingId,
      title,
      titleEdited,
      source,
      language,
      elapsed,
      const DeepCollectionEquality().hash(_transcripts),
      pendingUploads,
      audioPath,
    );
  }

  @override
  String toString() {
    return 'RecordingSession(meetingId: $meetingId, title: $title, titleEdited: $titleEdited, source: $source, language: $language, elapsed: $elapsed, transcripts: $transcripts, pendingUploads: $pendingUploads, audioPath: $audioPath)';
  }
}

/// @nodoc
abstract mixin class _$RecordingSessionCopyWith<$Res>
    implements $RecordingSessionCopyWith<$Res> {
  factory _$RecordingSessionCopyWith(
    _RecordingSession value,
    $Res Function(_RecordingSession) _then,
  ) = __$RecordingSessionCopyWithImpl;
  @override
  @useResult
  $Res call({
    String meetingId,
    String title,
    bool titleEdited,
    RecordingSource source,
    String? language,
    Duration elapsed,
    List<LiveTranscript> transcripts,
    int pendingUploads,
    String audioPath,
  });
}

/// @nodoc
class __$RecordingSessionCopyWithImpl<$Res>
    implements _$RecordingSessionCopyWith<$Res> {
  __$RecordingSessionCopyWithImpl(this._self, this._then);

  final _RecordingSession _self;
  final $Res Function(_RecordingSession) _then;

  /// Create a copy of RecordingSession
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? meetingId = null,
    Object? title = null,
    Object? titleEdited = null,
    Object? source = null,
    Object? language = freezed,
    Object? elapsed = null,
    Object? transcripts = null,
    Object? pendingUploads = null,
    Object? audioPath = null,
  }) {
    return _then(
      _RecordingSession(
        meetingId: null == meetingId
            ? _self.meetingId
            : meetingId // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _self.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        titleEdited: null == titleEdited
            ? _self.titleEdited
            : titleEdited // ignore: cast_nullable_to_non_nullable
                  as bool,
        source: null == source
            ? _self.source
            : source // ignore: cast_nullable_to_non_nullable
                  as RecordingSource,
        language: freezed == language
            ? _self.language
            : language // ignore: cast_nullable_to_non_nullable
                  as String?,
        elapsed: null == elapsed
            ? _self.elapsed
            : elapsed // ignore: cast_nullable_to_non_nullable
                  as Duration,
        transcripts: null == transcripts
            ? _self._transcripts
            : transcripts // ignore: cast_nullable_to_non_nullable
                  as List<LiveTranscript>,
        pendingUploads: null == pendingUploads
            ? _self.pendingUploads
            : pendingUploads // ignore: cast_nullable_to_non_nullable
                  as int,
        audioPath: null == audioPath
            ? _self.audioPath
            : audioPath // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
mixin _$RecordingState {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is RecordingState);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'RecordingState()';
  }
}

/// @nodoc
class $RecordingStateCopyWith<$Res> {
  $RecordingStateCopyWith(RecordingState _, $Res Function(RecordingState) __);
}

/// Adds pattern-matching-related methods to [RecordingState].
extension RecordingStatePatterns on RecordingState {
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
    TResult Function(RecordingIdle value)? idle,
    TResult Function(RecordingPreparing value)? preparing,
    TResult Function(RecordingActive value)? recording,
    TResult Function(RecordingPaused value)? paused,
    TResult Function(RecordingStopping value)? stopping,
    TResult Function(RecordingDone value)? done,
    TResult Function(RecordingError value)? error,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case RecordingIdle() when idle != null:
        return idle(_that);
      case RecordingPreparing() when preparing != null:
        return preparing(_that);
      case RecordingActive() when recording != null:
        return recording(_that);
      case RecordingPaused() when paused != null:
        return paused(_that);
      case RecordingStopping() when stopping != null:
        return stopping(_that);
      case RecordingDone() when done != null:
        return done(_that);
      case RecordingError() when error != null:
        return error(_that);
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
    required TResult Function(RecordingIdle value) idle,
    required TResult Function(RecordingPreparing value) preparing,
    required TResult Function(RecordingActive value) recording,
    required TResult Function(RecordingPaused value) paused,
    required TResult Function(RecordingStopping value) stopping,
    required TResult Function(RecordingDone value) done,
    required TResult Function(RecordingError value) error,
  }) {
    final _that = this;
    switch (_that) {
      case RecordingIdle():
        return idle(_that);
      case RecordingPreparing():
        return preparing(_that);
      case RecordingActive():
        return recording(_that);
      case RecordingPaused():
        return paused(_that);
      case RecordingStopping():
        return stopping(_that);
      case RecordingDone():
        return done(_that);
      case RecordingError():
        return error(_that);
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
    TResult? Function(RecordingIdle value)? idle,
    TResult? Function(RecordingPreparing value)? preparing,
    TResult? Function(RecordingActive value)? recording,
    TResult? Function(RecordingPaused value)? paused,
    TResult? Function(RecordingStopping value)? stopping,
    TResult? Function(RecordingDone value)? done,
    TResult? Function(RecordingError value)? error,
  }) {
    final _that = this;
    switch (_that) {
      case RecordingIdle() when idle != null:
        return idle(_that);
      case RecordingPreparing() when preparing != null:
        return preparing(_that);
      case RecordingActive() when recording != null:
        return recording(_that);
      case RecordingPaused() when paused != null:
        return paused(_that);
      case RecordingStopping() when stopping != null:
        return stopping(_that);
      case RecordingDone() when done != null:
        return done(_that);
      case RecordingError() when error != null:
        return error(_that);
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
    TResult Function(RecordingSource source)? preparing,
    TResult Function(RecordingSession session)? recording,
    TResult Function(RecordingSession session, bool interrupted)? paused,
    TResult Function(RecordingSession session)? stopping,
    TResult Function(String meetingId, bool autoSummary)? done,
    TResult Function(
      Object error,
      RecordingErrorStage stage,
      RecordingSession? session,
    )?
    error,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case RecordingIdle() when idle != null:
        return idle();
      case RecordingPreparing() when preparing != null:
        return preparing(_that.source);
      case RecordingActive() when recording != null:
        return recording(_that.session);
      case RecordingPaused() when paused != null:
        return paused(_that.session, _that.interrupted);
      case RecordingStopping() when stopping != null:
        return stopping(_that.session);
      case RecordingDone() when done != null:
        return done(_that.meetingId, _that.autoSummary);
      case RecordingError() when error != null:
        return error(_that.error, _that.stage, _that.session);
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
    required TResult Function(RecordingSource source) preparing,
    required TResult Function(RecordingSession session) recording,
    required TResult Function(RecordingSession session, bool interrupted)
    paused,
    required TResult Function(RecordingSession session) stopping,
    required TResult Function(String meetingId, bool autoSummary) done,
    required TResult Function(
      Object error,
      RecordingErrorStage stage,
      RecordingSession? session,
    )
    error,
  }) {
    final _that = this;
    switch (_that) {
      case RecordingIdle():
        return idle();
      case RecordingPreparing():
        return preparing(_that.source);
      case RecordingActive():
        return recording(_that.session);
      case RecordingPaused():
        return paused(_that.session, _that.interrupted);
      case RecordingStopping():
        return stopping(_that.session);
      case RecordingDone():
        return done(_that.meetingId, _that.autoSummary);
      case RecordingError():
        return error(_that.error, _that.stage, _that.session);
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
    TResult? Function(RecordingSource source)? preparing,
    TResult? Function(RecordingSession session)? recording,
    TResult? Function(RecordingSession session, bool interrupted)? paused,
    TResult? Function(RecordingSession session)? stopping,
    TResult? Function(String meetingId, bool autoSummary)? done,
    TResult? Function(
      Object error,
      RecordingErrorStage stage,
      RecordingSession? session,
    )?
    error,
  }) {
    final _that = this;
    switch (_that) {
      case RecordingIdle() when idle != null:
        return idle();
      case RecordingPreparing() when preparing != null:
        return preparing(_that.source);
      case RecordingActive() when recording != null:
        return recording(_that.session);
      case RecordingPaused() when paused != null:
        return paused(_that.session, _that.interrupted);
      case RecordingStopping() when stopping != null:
        return stopping(_that.session);
      case RecordingDone() when done != null:
        return done(_that.meetingId, _that.autoSummary);
      case RecordingError() when error != null:
        return error(_that.error, _that.stage, _that.session);
      case _:
        return null;
    }
  }
}

/// @nodoc

class RecordingIdle extends RecordingState {
  const RecordingIdle() : super._();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is RecordingIdle);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'RecordingState.idle()';
  }
}

/// @nodoc

class RecordingPreparing extends RecordingState {
  const RecordingPreparing({required this.source}) : super._();

  final RecordingSource source;

  /// Create a copy of RecordingState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $RecordingPreparingCopyWith<RecordingPreparing> get copyWith =>
      _$RecordingPreparingCopyWithImpl<RecordingPreparing>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is RecordingPreparing &&
            (identical(other.source, source) || other.source == source));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, source);
  }

  @override
  String toString() {
    return 'RecordingState.preparing(source: $source)';
  }
}

/// @nodoc
abstract mixin class $RecordingPreparingCopyWith<$Res>
    implements $RecordingStateCopyWith<$Res> {
  factory $RecordingPreparingCopyWith(
    RecordingPreparing value,
    $Res Function(RecordingPreparing) _then,
  ) = _$RecordingPreparingCopyWithImpl;
  @useResult
  $Res call({RecordingSource source});
}

/// @nodoc
class _$RecordingPreparingCopyWithImpl<$Res>
    implements $RecordingPreparingCopyWith<$Res> {
  _$RecordingPreparingCopyWithImpl(this._self, this._then);

  final RecordingPreparing _self;
  final $Res Function(RecordingPreparing) _then;

  /// Create a copy of RecordingState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? source = null}) {
    return _then(
      RecordingPreparing(
        source: null == source
            ? _self.source
            : source // ignore: cast_nullable_to_non_nullable
                  as RecordingSource,
      ),
    );
  }
}

/// @nodoc

class RecordingActive extends RecordingState {
  const RecordingActive({required this.session}) : super._();

  final RecordingSession session;

  /// Create a copy of RecordingState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $RecordingActiveCopyWith<RecordingActive> get copyWith =>
      _$RecordingActiveCopyWithImpl<RecordingActive>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is RecordingActive &&
            (identical(other.session, session) || other.session == session));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, session);
  }

  @override
  String toString() {
    return 'RecordingState.recording(session: $session)';
  }
}

/// @nodoc
abstract mixin class $RecordingActiveCopyWith<$Res>
    implements $RecordingStateCopyWith<$Res> {
  factory $RecordingActiveCopyWith(
    RecordingActive value,
    $Res Function(RecordingActive) _then,
  ) = _$RecordingActiveCopyWithImpl;
  @useResult
  $Res call({RecordingSession session});

  $RecordingSessionCopyWith<$Res> get session;
}

/// @nodoc
class _$RecordingActiveCopyWithImpl<$Res>
    implements $RecordingActiveCopyWith<$Res> {
  _$RecordingActiveCopyWithImpl(this._self, this._then);

  final RecordingActive _self;
  final $Res Function(RecordingActive) _then;

  /// Create a copy of RecordingState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? session = null}) {
    return _then(
      RecordingActive(
        session: null == session
            ? _self.session
            : session // ignore: cast_nullable_to_non_nullable
                  as RecordingSession,
      ),
    );
  }

  /// Create a copy of RecordingState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $RecordingSessionCopyWith<$Res> get session {
    return $RecordingSessionCopyWith<$Res>(_self.session, (value) {
      return _then(_self.copyWith(session: value));
    });
  }
}

/// @nodoc

class RecordingPaused extends RecordingState {
  const RecordingPaused({required this.session, this.interrupted = false})
    : super._();

  final RecordingSession session;
  @JsonKey()
  final bool interrupted;

  /// Create a copy of RecordingState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $RecordingPausedCopyWith<RecordingPaused> get copyWith =>
      _$RecordingPausedCopyWithImpl<RecordingPaused>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is RecordingPaused &&
            (identical(other.session, session) || other.session == session) &&
            (identical(other.interrupted, interrupted) ||
                other.interrupted == interrupted));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, session, interrupted);
  }

  @override
  String toString() {
    return 'RecordingState.paused(session: $session, interrupted: $interrupted)';
  }
}

/// @nodoc
abstract mixin class $RecordingPausedCopyWith<$Res>
    implements $RecordingStateCopyWith<$Res> {
  factory $RecordingPausedCopyWith(
    RecordingPaused value,
    $Res Function(RecordingPaused) _then,
  ) = _$RecordingPausedCopyWithImpl;
  @useResult
  $Res call({RecordingSession session, bool interrupted});

  $RecordingSessionCopyWith<$Res> get session;
}

/// @nodoc
class _$RecordingPausedCopyWithImpl<$Res>
    implements $RecordingPausedCopyWith<$Res> {
  _$RecordingPausedCopyWithImpl(this._self, this._then);

  final RecordingPaused _self;
  final $Res Function(RecordingPaused) _then;

  /// Create a copy of RecordingState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? session = null, Object? interrupted = null}) {
    return _then(
      RecordingPaused(
        session: null == session
            ? _self.session
            : session // ignore: cast_nullable_to_non_nullable
                  as RecordingSession,
        interrupted: null == interrupted
            ? _self.interrupted
            : interrupted // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }

  /// Create a copy of RecordingState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $RecordingSessionCopyWith<$Res> get session {
    return $RecordingSessionCopyWith<$Res>(_self.session, (value) {
      return _then(_self.copyWith(session: value));
    });
  }
}

/// @nodoc

class RecordingStopping extends RecordingState {
  const RecordingStopping({required this.session}) : super._();

  final RecordingSession session;

  /// Create a copy of RecordingState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $RecordingStoppingCopyWith<RecordingStopping> get copyWith =>
      _$RecordingStoppingCopyWithImpl<RecordingStopping>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is RecordingStopping &&
            (identical(other.session, session) || other.session == session));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, session);
  }

  @override
  String toString() {
    return 'RecordingState.stopping(session: $session)';
  }
}

/// @nodoc
abstract mixin class $RecordingStoppingCopyWith<$Res>
    implements $RecordingStateCopyWith<$Res> {
  factory $RecordingStoppingCopyWith(
    RecordingStopping value,
    $Res Function(RecordingStopping) _then,
  ) = _$RecordingStoppingCopyWithImpl;
  @useResult
  $Res call({RecordingSession session});

  $RecordingSessionCopyWith<$Res> get session;
}

/// @nodoc
class _$RecordingStoppingCopyWithImpl<$Res>
    implements $RecordingStoppingCopyWith<$Res> {
  _$RecordingStoppingCopyWithImpl(this._self, this._then);

  final RecordingStopping _self;
  final $Res Function(RecordingStopping) _then;

  /// Create a copy of RecordingState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? session = null}) {
    return _then(
      RecordingStopping(
        session: null == session
            ? _self.session
            : session // ignore: cast_nullable_to_non_nullable
                  as RecordingSession,
      ),
    );
  }

  /// Create a copy of RecordingState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $RecordingSessionCopyWith<$Res> get session {
    return $RecordingSessionCopyWith<$Res>(_self.session, (value) {
      return _then(_self.copyWith(session: value));
    });
  }
}

/// @nodoc

class RecordingDone extends RecordingState {
  const RecordingDone({required this.meetingId, required this.autoSummary})
    : super._();

  final String meetingId;
  final bool autoSummary;

  /// Create a copy of RecordingState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $RecordingDoneCopyWith<RecordingDone> get copyWith =>
      _$RecordingDoneCopyWithImpl<RecordingDone>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is RecordingDone &&
            (identical(other.meetingId, meetingId) ||
                other.meetingId == meetingId) &&
            (identical(other.autoSummary, autoSummary) ||
                other.autoSummary == autoSummary));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, meetingId, autoSummary);
  }

  @override
  String toString() {
    return 'RecordingState.done(meetingId: $meetingId, autoSummary: $autoSummary)';
  }
}

/// @nodoc
abstract mixin class $RecordingDoneCopyWith<$Res>
    implements $RecordingStateCopyWith<$Res> {
  factory $RecordingDoneCopyWith(
    RecordingDone value,
    $Res Function(RecordingDone) _then,
  ) = _$RecordingDoneCopyWithImpl;
  @useResult
  $Res call({String meetingId, bool autoSummary});
}

/// @nodoc
class _$RecordingDoneCopyWithImpl<$Res>
    implements $RecordingDoneCopyWith<$Res> {
  _$RecordingDoneCopyWithImpl(this._self, this._then);

  final RecordingDone _self;
  final $Res Function(RecordingDone) _then;

  /// Create a copy of RecordingState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? meetingId = null, Object? autoSummary = null}) {
    return _then(
      RecordingDone(
        meetingId: null == meetingId
            ? _self.meetingId
            : meetingId // ignore: cast_nullable_to_non_nullable
                  as String,
        autoSummary: null == autoSummary
            ? _self.autoSummary
            : autoSummary // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc

class RecordingError extends RecordingState {
  const RecordingError({required this.error, required this.stage, this.session})
    : super._();

  final Object error;
  final RecordingErrorStage stage;
  final RecordingSession? session;

  /// Create a copy of RecordingState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $RecordingErrorCopyWith<RecordingError> get copyWith =>
      _$RecordingErrorCopyWithImpl<RecordingError>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is RecordingError &&
            const DeepCollectionEquality().equals(other.error, error) &&
            (identical(other.stage, stage) || other.stage == stage) &&
            (identical(other.session, session) || other.session == session));
  }

  @override
  int get hashCode {
    return Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(error),
      stage,
      session,
    );
  }

  @override
  String toString() {
    return 'RecordingState.error(error: $error, stage: $stage, session: $session)';
  }
}

/// @nodoc
abstract mixin class $RecordingErrorCopyWith<$Res>
    implements $RecordingStateCopyWith<$Res> {
  factory $RecordingErrorCopyWith(
    RecordingError value,
    $Res Function(RecordingError) _then,
  ) = _$RecordingErrorCopyWithImpl;
  @useResult
  $Res call({
    Object error,
    RecordingErrorStage stage,
    RecordingSession? session,
  });

  $RecordingSessionCopyWith<$Res>? get session;
}

/// @nodoc
class _$RecordingErrorCopyWithImpl<$Res>
    implements $RecordingErrorCopyWith<$Res> {
  _$RecordingErrorCopyWithImpl(this._self, this._then);

  final RecordingError _self;
  final $Res Function(RecordingError) _then;

  /// Create a copy of RecordingState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? error = null,
    Object? stage = null,
    Object? session = freezed,
  }) {
    return _then(
      RecordingError(
        error: null == error ? _self.error : error,
        stage: null == stage
            ? _self.stage
            : stage // ignore: cast_nullable_to_non_nullable
                  as RecordingErrorStage,
        session: freezed == session
            ? _self.session
            : session // ignore: cast_nullable_to_non_nullable
                  as RecordingSession?,
      ),
    );
  }

  /// Create a copy of RecordingState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $RecordingSessionCopyWith<$Res>? get session {
    if (_self.session == null) {
      return null;
    }

    return $RecordingSessionCopyWith<$Res>(_self.session!, (value) {
      return _then(_self.copyWith(session: value));
    });
  }
}
