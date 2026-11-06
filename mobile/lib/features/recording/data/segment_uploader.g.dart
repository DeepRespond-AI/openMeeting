// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'segment_uploader.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The app-wide uploader. Created lazily (by the recording controller); flushes segments left
/// over from earlier sessions right away.

@ProviderFor(segmentUploader)
final segmentUploaderProvider = SegmentUploaderProvider._();

/// The app-wide uploader. Created lazily (by the recording controller); flushes segments left
/// over from earlier sessions right away.

final class SegmentUploaderProvider
    extends
        $FunctionalProvider<SegmentUploader, SegmentUploader, SegmentUploader>
    with $Provider<SegmentUploader> {
  /// The app-wide uploader. Created lazily (by the recording controller); flushes segments left
  /// over from earlier sessions right away.
  SegmentUploaderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'segmentUploaderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$segmentUploaderHash();

  @$internal
  @override
  $ProviderElement<SegmentUploader> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SegmentUploader create(Ref ref) {
    return segmentUploader(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SegmentUploader value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SegmentUploader>(value),
    );
  }
}

String _$segmentUploaderHash() => r'6344fc11c79194c73e48385c60ef846bb012eab5';
