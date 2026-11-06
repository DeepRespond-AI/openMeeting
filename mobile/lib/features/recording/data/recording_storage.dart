import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/config/app_config_provider.dart';

part 'recording_storage.g.dart';

/// Local directories of the recording feature (under the app support directory, names from
/// `AppConfig.recording`). Override in tests with a temp directory.
class RecordingStorage {
  RecordingStorage({
    required this._baseDir,
    required this.recordingsDirName,
    required this.pendingQueueDirName,
  });

  final Future<Directory> Function() _baseDir;
  final String recordingsDirName;
  final String pendingQueueDirName;

  /// Local recordings (`<meetingId>.<audioFileExtension>`).
  Future<Directory> recordingsDir() => _sub(recordingsDirName);

  /// Persistent pending segment queue.
  Future<Directory> pendingQueueDir() => _sub(pendingQueueDirName);

  Future<Directory> _sub(String name) async {
    final base = await _baseDir();
    return Directory('${base.path}${Platform.pathSeparator}$name').create(recursive: true);
  }
}

@Riverpod(keepAlive: true)
RecordingStorage recordingStorage(Ref ref) {
  final config = ref.watch(appConfigProvider).recording;
  return RecordingStorage(
    baseDir: getApplicationSupportDirectory,
    recordingsDirName: config.recordingsDirName,
    pendingQueueDirName: config.pendingQueueDirName,
  );
}
