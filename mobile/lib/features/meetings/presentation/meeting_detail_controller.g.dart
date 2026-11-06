// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meeting_detail_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Meeting metadata (title, created time, duration). Also watched by list cards for the date.

@ProviderFor(MeetingDetailController)
final meetingDetailControllerProvider = MeetingDetailControllerFamily._();

/// Meeting metadata (title, created time, duration). Also watched by list cards for the date.
final class MeetingDetailControllerProvider
    extends $AsyncNotifierProvider<MeetingDetailController, MeetingMetadata> {
  /// Meeting metadata (title, created time, duration). Also watched by list cards for the date.
  MeetingDetailControllerProvider._({
    required MeetingDetailControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'meetingDetailControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$meetingDetailControllerHash();

  @override
  String toString() {
    return r'meetingDetailControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  MeetingDetailController create() => MeetingDetailController();

  @override
  bool operator ==(Object other) {
    return other is MeetingDetailControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$meetingDetailControllerHash() =>
    r'f697af5a92ac49bb519eb1c4365a8f96d80de5c3';

/// Meeting metadata (title, created time, duration). Also watched by list cards for the date.

final class MeetingDetailControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          MeetingDetailController,
          AsyncValue<MeetingMetadata>,
          MeetingMetadata,
          FutureOr<MeetingMetadata>,
          String
        > {
  MeetingDetailControllerFamily._()
    : super(
        retry: null,
        name: r'meetingDetailControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Meeting metadata (title, created time, duration). Also watched by list cards for the date.

  MeetingDetailControllerProvider call(String meetingId) =>
      MeetingDetailControllerProvider._(argument: meetingId, from: this);

  @override
  String toString() => r'meetingDetailControllerProvider';
}

/// Meeting metadata (title, created time, duration). Also watched by list cards for the date.

abstract class _$MeetingDetailController
    extends $AsyncNotifier<MeetingMetadata> {
  late final _$args = ref.$arg as String;
  String get meetingId => _$args;

  FutureOr<MeetingMetadata> build(String meetingId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<MeetingMetadata>, MeetingMetadata>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<MeetingMetadata>, MeetingMetadata>,
              AsyncValue<MeetingMetadata>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// Transcript list with infinite scrolling (`AppConfig.pagination.transcriptPageSize`).

@ProviderFor(TranscriptsController)
final transcriptsControllerProvider = TranscriptsControllerFamily._();

/// Transcript list with infinite scrolling (`AppConfig.pagination.transcriptPageSize`).
final class TranscriptsControllerProvider
    extends $AsyncNotifierProvider<TranscriptsController, TranscriptsState> {
  /// Transcript list with infinite scrolling (`AppConfig.pagination.transcriptPageSize`).
  TranscriptsControllerProvider._({
    required TranscriptsControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'transcriptsControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$transcriptsControllerHash();

  @override
  String toString() {
    return r'transcriptsControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  TranscriptsController create() => TranscriptsController();

  @override
  bool operator ==(Object other) {
    return other is TranscriptsControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$transcriptsControllerHash() =>
    r'16227489111b8c33b976cebfc754a75fcacec58f';

/// Transcript list with infinite scrolling (`AppConfig.pagination.transcriptPageSize`).

final class TranscriptsControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          TranscriptsController,
          AsyncValue<TranscriptsState>,
          TranscriptsState,
          FutureOr<TranscriptsState>,
          String
        > {
  TranscriptsControllerFamily._()
    : super(
        retry: null,
        name: r'transcriptsControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Transcript list with infinite scrolling (`AppConfig.pagination.transcriptPageSize`).

  TranscriptsControllerProvider call(String meetingId) =>
      TranscriptsControllerProvider._(argument: meetingId, from: this);

  @override
  String toString() => r'transcriptsControllerProvider';
}

/// Transcript list with infinite scrolling (`AppConfig.pagination.transcriptPageSize`).

abstract class _$TranscriptsController
    extends $AsyncNotifier<TranscriptsState> {
  late final _$args = ref.$arg as String;
  String get meetingId => _$args;

  FutureOr<TranscriptsState> build(String meetingId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<TranscriptsState>, TranscriptsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<TranscriptsState>, TranscriptsState>,
              AsyncValue<TranscriptsState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
