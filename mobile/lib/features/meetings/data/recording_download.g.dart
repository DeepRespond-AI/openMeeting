// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recording_download.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(recordingFiles)
final recordingFilesProvider = RecordingFilesProvider._();

final class RecordingFilesProvider
    extends $FunctionalProvider<RecordingFiles, RecordingFiles, RecordingFiles>
    with $Provider<RecordingFiles> {
  RecordingFilesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recordingFilesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recordingFilesHash();

  @$internal
  @override
  $ProviderElement<RecordingFiles> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RecordingFiles create(Ref ref) {
    return recordingFiles(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecordingFiles value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecordingFiles>(value),
    );
  }
}

String _$recordingFilesHash() => r'6feb43b318145db242c18950360e2d2462c9543b';

@ProviderFor(RecordingDownloadController)
final recordingDownloadControllerProvider =
    RecordingDownloadControllerFamily._();

final class RecordingDownloadControllerProvider
    extends $AsyncNotifierProvider<RecordingDownloadController, File?> {
  RecordingDownloadControllerProvider._({
    required RecordingDownloadControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'recordingDownloadControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$recordingDownloadControllerHash();

  @override
  String toString() {
    return r'recordingDownloadControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  RecordingDownloadController create() => RecordingDownloadController();

  @override
  bool operator ==(Object other) {
    return other is RecordingDownloadControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$recordingDownloadControllerHash() =>
    r'40120e4de145ff2734a2b0ff7918a24524436ee8';

final class RecordingDownloadControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          RecordingDownloadController,
          AsyncValue<File?>,
          File?,
          FutureOr<File?>,
          String
        > {
  RecordingDownloadControllerFamily._()
    : super(
        retry: null,
        name: r'recordingDownloadControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  RecordingDownloadControllerProvider call(String meetingId) =>
      RecordingDownloadControllerProvider._(argument: meetingId, from: this);

  @override
  String toString() => r'recordingDownloadControllerProvider';
}

abstract class _$RecordingDownloadController extends $AsyncNotifier<File?> {
  late final _$args = ref.$arg as String;
  String get meetingId => _$args;

  FutureOr<File?> build(String meetingId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<File?>, File?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<File?>, File?>,
              AsyncValue<File?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
