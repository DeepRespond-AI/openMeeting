// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedules_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(LiveSchedules)
final liveSchedulesProvider = LiveSchedulesProvider._();

final class LiveSchedulesProvider
    extends $AsyncNotifierProvider<LiveSchedules, List<LiveSchedule>> {
  LiveSchedulesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'liveSchedulesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$liveSchedulesHash();

  @$internal
  @override
  LiveSchedules create() => LiveSchedules();
}

String _$liveSchedulesHash() => r'f4d89ee56d90102430c54537ca004b73c8a23ef5';

abstract class _$LiveSchedules extends $AsyncNotifier<List<LiveSchedule>> {
  FutureOr<List<LiveSchedule>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<LiveSchedule>>, List<LiveSchedule>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<LiveSchedule>>, List<LiveSchedule>>,
              AsyncValue<List<LiveSchedule>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(UpcomingSchedules)
final upcomingSchedulesProvider = UpcomingSchedulesProvider._();

final class UpcomingSchedulesProvider
    extends $AsyncNotifierProvider<UpcomingSchedules, List<LiveSchedule>> {
  UpcomingSchedulesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'upcomingSchedulesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$upcomingSchedulesHash();

  @$internal
  @override
  UpcomingSchedules create() => UpcomingSchedules();
}

String _$upcomingSchedulesHash() => r'b43933543b6de2fa0697747048243ea718b627bb';

abstract class _$UpcomingSchedules extends $AsyncNotifier<List<LiveSchedule>> {
  FutureOr<List<LiveSchedule>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<LiveSchedule>>, List<LiveSchedule>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<LiveSchedule>>, List<LiveSchedule>>,
              AsyncValue<List<LiveSchedule>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
