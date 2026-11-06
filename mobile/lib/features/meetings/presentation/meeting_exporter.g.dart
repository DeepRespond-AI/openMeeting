// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meeting_exporter.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(meetingExporter)
final meetingExporterProvider = MeetingExporterProvider._();

final class MeetingExporterProvider
    extends
        $FunctionalProvider<MeetingExporter, MeetingExporter, MeetingExporter>
    with $Provider<MeetingExporter> {
  MeetingExporterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'meetingExporterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$meetingExporterHash();

  @$internal
  @override
  $ProviderElement<MeetingExporter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MeetingExporter create(Ref ref) {
    return meetingExporter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MeetingExporter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MeetingExporter>(value),
    );
  }
}

String _$meetingExporterHash() => r'e9d2ce99c8b84d957b409ddadfc7f50a920494e1';
