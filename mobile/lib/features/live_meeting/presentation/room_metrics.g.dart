// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_metrics.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(roomMetrics)
final roomMetricsProvider = RoomMetricsProvider._();

final class RoomMetricsProvider
    extends
        $FunctionalProvider<
          AsyncValue<RoomMetrics>,
          RoomMetrics,
          Stream<RoomMetrics>
        >
    with $FutureModifier<RoomMetrics>, $StreamProvider<RoomMetrics> {
  RoomMetricsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'roomMetricsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$roomMetricsHash();

  @$internal
  @override
  $StreamProviderElement<RoomMetrics> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<RoomMetrics> create(Ref ref) {
    return roomMetrics(ref);
  }
}

String _$roomMetricsHash() => r'0f77462dc8100292b2ad43f257d27b4fcbd253fc';
