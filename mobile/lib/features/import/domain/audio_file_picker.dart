import 'package:freezed_annotation/freezed_annotation.dart';

part 'audio_file_picker.freezed.dart';

/// A local audio file chosen for import.
@freezed
abstract class PickedAudioFile with _$PickedAudioFile {
  const factory PickedAudioFile({
    required String path,
    required String name,

    /// Bytes, when known.
    int? size,
  }) = _PickedAudioFile;

  const PickedAudioFile._();

  /// File name without its extension — the default meeting title.
  String get baseName {
    final dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(0, dot) : name;
  }
}

/// System file picker restricted to audio files.
abstract interface class AudioFilePicker {
  /// Returns `null` when the user cancelled.
  Future<PickedAudioFile?> pick({required List<String> allowedExtensions});
}
