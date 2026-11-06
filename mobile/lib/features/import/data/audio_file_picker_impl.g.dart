// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audio_file_picker_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(audioFilePicker)
final audioFilePickerProvider = AudioFilePickerProvider._();

final class AudioFilePickerProvider
    extends
        $FunctionalProvider<AudioFilePicker, AudioFilePicker, AudioFilePicker>
    with $Provider<AudioFilePicker> {
  AudioFilePickerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'audioFilePickerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$audioFilePickerHash();

  @$internal
  @override
  $ProviderElement<AudioFilePicker> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AudioFilePicker create(Ref ref) {
    return audioFilePicker(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AudioFilePicker value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AudioFilePicker>(value),
    );
  }
}

String _$audioFilePickerHash() => r'85b3acc2735dde6e356349b3a2f6992faecf6323';
