// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'retranscribe_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Retranscription of one meeting (`POST /jobs/retranscribe`, then job polling with
/// `AppConfig.polling.job*`). A 409 means a job is already running (`JobFailed.error.kind ==
/// conflict`). On completion the transcript list reloads.

@ProviderFor(RetranscribeController)
final retranscribeControllerProvider = RetranscribeControllerFamily._();

/// Retranscription of one meeting (`POST /jobs/retranscribe`, then job polling with
/// `AppConfig.polling.job*`). A 409 means a job is already running (`JobFailed.error.kind ==
/// conflict`). On completion the transcript list reloads.
final class RetranscribeControllerProvider
    extends $NotifierProvider<RetranscribeController, JobRunState> {
  /// Retranscription of one meeting (`POST /jobs/retranscribe`, then job polling with
  /// `AppConfig.polling.job*`). A 409 means a job is already running (`JobFailed.error.kind ==
  /// conflict`). On completion the transcript list reloads.
  RetranscribeControllerProvider._({
    required RetranscribeControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'retranscribeControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$retranscribeControllerHash();

  @override
  String toString() {
    return r'retranscribeControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  RetranscribeController create() => RetranscribeController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(JobRunState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<JobRunState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RetranscribeControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$retranscribeControllerHash() =>
    r'45d77f76abbf07e9839d7ea4ba7798154915b8c4';

/// Retranscription of one meeting (`POST /jobs/retranscribe`, then job polling with
/// `AppConfig.polling.job*`). A 409 means a job is already running (`JobFailed.error.kind ==
/// conflict`). On completion the transcript list reloads.

final class RetranscribeControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          RetranscribeController,
          JobRunState,
          JobRunState,
          JobRunState,
          String
        > {
  RetranscribeControllerFamily._()
    : super(
        retry: null,
        name: r'retranscribeControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Retranscription of one meeting (`POST /jobs/retranscribe`, then job polling with
  /// `AppConfig.polling.job*`). A 409 means a job is already running (`JobFailed.error.kind ==
  /// conflict`). On completion the transcript list reloads.

  RetranscribeControllerProvider call(String meetingId) =>
      RetranscribeControllerProvider._(argument: meetingId, from: this);

  @override
  String toString() => r'retranscribeControllerProvider';
}

/// Retranscription of one meeting (`POST /jobs/retranscribe`, then job polling with
/// `AppConfig.polling.job*`). A 409 means a job is already running (`JobFailed.error.kind ==
/// conflict`). On completion the transcript list reloads.

abstract class _$RetranscribeController extends $Notifier<JobRunState> {
  late final _$args = ref.$arg as String;
  String get meetingId => _$args;

  JobRunState build(String meetingId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<JobRunState, JobRunState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<JobRunState, JobRunState>,
              JobRunState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
