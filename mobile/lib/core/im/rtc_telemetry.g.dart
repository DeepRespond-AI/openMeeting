// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rtc_telemetry.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(readRtcStats)
final readRtcStatsProvider = ReadRtcStatsProvider._();

final class ReadRtcStatsProvider
    extends $FunctionalProvider<ReadRtcStats, ReadRtcStats, ReadRtcStats>
    with $Provider<ReadRtcStats> {
  ReadRtcStatsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'readRtcStatsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$readRtcStatsHash();

  @$internal
  @override
  $ProviderElement<ReadRtcStats> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ReadRtcStats create(Ref ref) {
    return readRtcStats(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReadRtcStats value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReadRtcStats>(value),
    );
  }
}

String _$readRtcStatsHash() => r'badccb1430cd4a4474b3b44e80d6c8da659ecdab';
