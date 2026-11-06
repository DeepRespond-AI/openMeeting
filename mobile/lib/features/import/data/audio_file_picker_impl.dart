import 'package:file_picker/file_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/audio_file_picker.dart';

part 'audio_file_picker_impl.g.dart';

/// [AudioFilePicker] backed by `file_picker`.
class PlatformAudioFilePicker implements AudioFilePicker {
  const PlatformAudioFilePicker();

  @override
  Future<PickedAudioFile?> pick({required List<String> allowedExtensions}) async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
    );
    if (files.isEmpty) return null;
    final file = files.first;
    final path = file.path;
    if (path == null) return null;
    return PickedAudioFile(path: path, name: file.name, size: file.lengthSync());
  }
}

@Riverpod(keepAlive: true)
AudioFilePicker audioFilePicker(Ref ref) => const PlatformAudioFilePicker();
