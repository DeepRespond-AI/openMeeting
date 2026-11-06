// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'summary_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Sleep used between summary polls; overridden in tests.

@ProviderFor(summaryPollSleeper)
final summaryPollSleeperProvider = SummaryPollSleeperProvider._();

/// Sleep used between summary polls; overridden in tests.

final class SummaryPollSleeperProvider
    extends $FunctionalProvider<Sleeper, Sleeper, Sleeper>
    with $Provider<Sleeper> {
  /// Sleep used between summary polls; overridden in tests.
  SummaryPollSleeperProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'summaryPollSleeperProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$summaryPollSleeperHash();

  @$internal
  @override
  $ProviderElement<Sleeper> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Sleeper create(Ref ref) {
    return summaryPollSleeper(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Sleeper value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Sleeper>(value),
    );
  }
}

String _$summaryPollSleeperHash() =>
    r'736ebe4bc1b4669ad0f7c481982ff8663120b560';

/// Summary tab state machine for one meeting (desktop `useSummaryGeneration`):
/// - `build` restores the stored summary and resumes polling if one is in progress;
/// - [generate] POSTs (the server picks the template), then polls every
///   `AppConfig.polling.summaryInterval` up to `summaryMaxPolls`; `pending`/`processing` mean
///   in progress; responses whose `start` differs from our `process_id` are ignored;
/// - [stop] DELETEs and restores the previous summary;
/// - [save] PUTs `{"summary":{"markdown": md}}` (Markdown summaries only; HTML / mixed are read-only).
///
/// The server may rename the meeting when a summary completes: the detail page listens for
/// `generating → ready` and reloads the meeting metadata.

@ProviderFor(SummaryController)
final summaryControllerProvider = SummaryControllerFamily._();

/// Summary tab state machine for one meeting (desktop `useSummaryGeneration`):
/// - `build` restores the stored summary and resumes polling if one is in progress;
/// - [generate] POSTs (the server picks the template), then polls every
///   `AppConfig.polling.summaryInterval` up to `summaryMaxPolls`; `pending`/`processing` mean
///   in progress; responses whose `start` differs from our `process_id` are ignored;
/// - [stop] DELETEs and restores the previous summary;
/// - [save] PUTs `{"summary":{"markdown": md}}` (Markdown summaries only; HTML / mixed are read-only).
///
/// The server may rename the meeting when a summary completes: the detail page listens for
/// `generating → ready` and reloads the meeting metadata.
final class SummaryControllerProvider
    extends $AsyncNotifierProvider<SummaryController, SummaryState> {
  /// Summary tab state machine for one meeting (desktop `useSummaryGeneration`):
  /// - `build` restores the stored summary and resumes polling if one is in progress;
  /// - [generate] POSTs (the server picks the template), then polls every
  ///   `AppConfig.polling.summaryInterval` up to `summaryMaxPolls`; `pending`/`processing` mean
  ///   in progress; responses whose `start` differs from our `process_id` are ignored;
  /// - [stop] DELETEs and restores the previous summary;
  /// - [save] PUTs `{"summary":{"markdown": md}}` (Markdown summaries only; HTML / mixed are read-only).
  ///
  /// The server may rename the meeting when a summary completes: the detail page listens for
  /// `generating → ready` and reloads the meeting metadata.
  SummaryControllerProvider._({
    required SummaryControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'summaryControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$summaryControllerHash();

  @override
  String toString() {
    return r'summaryControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SummaryController create() => SummaryController();

  @override
  bool operator ==(Object other) {
    return other is SummaryControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$summaryControllerHash() => r'cd2e8490423dc9cfdeba98e1bc5cd57bbdb59222';

/// Summary tab state machine for one meeting (desktop `useSummaryGeneration`):
/// - `build` restores the stored summary and resumes polling if one is in progress;
/// - [generate] POSTs (the server picks the template), then polls every
///   `AppConfig.polling.summaryInterval` up to `summaryMaxPolls`; `pending`/`processing` mean
///   in progress; responses whose `start` differs from our `process_id` are ignored;
/// - [stop] DELETEs and restores the previous summary;
/// - [save] PUTs `{"summary":{"markdown": md}}` (Markdown summaries only; HTML / mixed are read-only).
///
/// The server may rename the meeting when a summary completes: the detail page listens for
/// `generating → ready` and reloads the meeting metadata.

final class SummaryControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          SummaryController,
          AsyncValue<SummaryState>,
          SummaryState,
          FutureOr<SummaryState>,
          String
        > {
  SummaryControllerFamily._()
    : super(
        retry: null,
        name: r'summaryControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Summary tab state machine for one meeting (desktop `useSummaryGeneration`):
  /// - `build` restores the stored summary and resumes polling if one is in progress;
  /// - [generate] POSTs (the server picks the template), then polls every
  ///   `AppConfig.polling.summaryInterval` up to `summaryMaxPolls`; `pending`/`processing` mean
  ///   in progress; responses whose `start` differs from our `process_id` are ignored;
  /// - [stop] DELETEs and restores the previous summary;
  /// - [save] PUTs `{"summary":{"markdown": md}}` (Markdown summaries only; HTML / mixed are read-only).
  ///
  /// The server may rename the meeting when a summary completes: the detail page listens for
  /// `generating → ready` and reloads the meeting metadata.

  SummaryControllerProvider call(String meetingId) =>
      SummaryControllerProvider._(argument: meetingId, from: this);

  @override
  String toString() => r'summaryControllerProvider';
}

/// Summary tab state machine for one meeting (desktop `useSummaryGeneration`):
/// - `build` restores the stored summary and resumes polling if one is in progress;
/// - [generate] POSTs (the server picks the template), then polls every
///   `AppConfig.polling.summaryInterval` up to `summaryMaxPolls`; `pending`/`processing` mean
///   in progress; responses whose `start` differs from our `process_id` are ignored;
/// - [stop] DELETEs and restores the previous summary;
/// - [save] PUTs `{"summary":{"markdown": md}}` (Markdown summaries only; HTML / mixed are read-only).
///
/// The server may rename the meeting when a summary completes: the detail page listens for
/// `generating → ready` and reloads the meeting metadata.

abstract class _$SummaryController extends $AsyncNotifier<SummaryState> {
  late final _$args = ref.$arg as String;
  String get meetingId => _$args;

  FutureOr<SummaryState> build(String meetingId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<SummaryState>, SummaryState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<SummaryState>, SummaryState>,
              AsyncValue<SummaryState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
