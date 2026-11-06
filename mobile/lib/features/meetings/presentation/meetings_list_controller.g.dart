// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meetings_list_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Meeting list state. Reloads when the signed-in user changes or meetings change elsewhere.

@ProviderFor(MeetingsListController)
final meetingsListControllerProvider = MeetingsListControllerProvider._();

/// Meeting list state. Reloads when the signed-in user changes or meetings change elsewhere.
final class MeetingsListControllerProvider
    extends
        $AsyncNotifierProvider<MeetingsListController, List<MeetingSummary>> {
  /// Meeting list state. Reloads when the signed-in user changes or meetings change elsewhere.
  MeetingsListControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'meetingsListControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$meetingsListControllerHash();

  @$internal
  @override
  MeetingsListController create() => MeetingsListController();
}

String _$meetingsListControllerHash() =>
    r'4f52c0279cfa9d9e54d0ec4ad792b3442353b839';

/// Meeting list state. Reloads when the signed-in user changes or meetings change elsewhere.

abstract class _$MeetingsListController
    extends $AsyncNotifier<List<MeetingSummary>> {
  FutureOr<List<MeetingSummary>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<MeetingSummary>>, List<MeetingSummary>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<MeetingSummary>>,
                List<MeetingSummary>
              >,
              AsyncValue<List<MeetingSummary>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Debounced transcript search (`AppConfig.pagination.meetingSearchDebounce`); responses for
/// an outdated query are dropped.

@ProviderFor(MeetingSearchController)
final meetingSearchControllerProvider = MeetingSearchControllerProvider._();

/// Debounced transcript search (`AppConfig.pagination.meetingSearchDebounce`); responses for
/// an outdated query are dropped.
final class MeetingSearchControllerProvider
    extends $NotifierProvider<MeetingSearchController, MeetingSearchState> {
  /// Debounced transcript search (`AppConfig.pagination.meetingSearchDebounce`); responses for
  /// an outdated query are dropped.
  MeetingSearchControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'meetingSearchControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$meetingSearchControllerHash();

  @$internal
  @override
  MeetingSearchController create() => MeetingSearchController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MeetingSearchState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MeetingSearchState>(value),
    );
  }
}

String _$meetingSearchControllerHash() =>
    r'cee93f1f622d8c0c996c796ff0557bbf7aec106d';

/// Debounced transcript search (`AppConfig.pagination.meetingSearchDebounce`); responses for
/// an outdated query are dropped.

abstract class _$MeetingSearchController extends $Notifier<MeetingSearchState> {
  MeetingSearchState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<MeetingSearchState, MeetingSearchState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MeetingSearchState, MeetingSearchState>,
              MeetingSearchState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
