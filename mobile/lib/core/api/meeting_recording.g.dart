// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meeting_recording.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(meetingRecording)
final meetingRecordingProvider = MeetingRecordingFamily._();

final class MeetingRecordingProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, dynamic>>,
          Map<String, dynamic>,
          FutureOr<Map<String, dynamic>>
        >
    with
        $FutureModifier<Map<String, dynamic>>,
        $FutureProvider<Map<String, dynamic>> {
  MeetingRecordingProvider._({
    required MeetingRecordingFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'meetingRecordingProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$meetingRecordingHash();

  @override
  String toString() {
    return r'meetingRecordingProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Map<String, dynamic>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, dynamic>> create(Ref ref) {
    final argument = this.argument as String;
    return meetingRecording(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MeetingRecordingProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$meetingRecordingHash() => r'7c0f6e15a57d9b7bf91b43af6c7aead2cb24c887';

final class MeetingRecordingFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Map<String, dynamic>>, String> {
  MeetingRecordingFamily._()
    : super(
        retry: null,
        name: r'meetingRecordingProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  MeetingRecordingProvider call(String id) =>
      MeetingRecordingProvider._(argument: id, from: this);

  @override
  String toString() => r'meetingRecordingProvider';
}

@ProviderFor(RecordingRetry)
final recordingRetryProvider = RecordingRetryFamily._();

final class RecordingRetryProvider
    extends $AsyncNotifierProvider<RecordingRetry, void> {
  RecordingRetryProvider._({
    required RecordingRetryFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'recordingRetryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$recordingRetryHash();

  @override
  String toString() {
    return r'recordingRetryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  RecordingRetry create() => RecordingRetry();

  @override
  bool operator ==(Object other) {
    return other is RecordingRetryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$recordingRetryHash() => r'6f534f130d0c14043e5c92edab33417608b50db4';

final class RecordingRetryFamily extends $Family
    with
        $ClassFamilyOverride<
          RecordingRetry,
          AsyncValue<void>,
          void,
          FutureOr<void>,
          String
        > {
  RecordingRetryFamily._()
    : super(
        retry: null,
        name: r'recordingRetryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  RecordingRetryProvider call(String id) =>
      RecordingRetryProvider._(argument: id, from: this);

  @override
  String toString() => r'recordingRetryProvider';
}

abstract class _$RecordingRetry extends $AsyncNotifier<void> {
  late final _$args = ref.$arg as String;
  String get id => _$args;

  FutureOr<void> build(String id);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
