import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/endpoints.dart';
import '../../../core/auth/session_controller.dart';
import '../../../core/config/app_config_provider.dart';

part 'recording_download.g.dart';

/// Downloads incrementally to account-specific app storage. A failed or cancelled
/// transfer never publishes its partial file. The platform share sheet exports
/// that file without reading a whole meeting recording back into Dart memory.
class RecordingFiles {
  RecordingFiles({
    required this.dio,
    required this.directory,
    required this.export,
    required this.folder,
    required this.timeout,
  });
  final Dio dio;
  final Future<Directory> Function() directory;
  final Future<void> Function(File) export;
  final String folder;
  final Duration timeout;

  Future<File> download(String meetingId, String userId, CancelToken cancel) => apiCall(() async {
    if (!RegExp(r'^[\w-]{1,80}$').hasMatch(meetingId)) {
      throw const ApiException(kind: ApiErrorKind.validation);
    }
    final base = await directory();
    final user = sha256.convert(utf8.encode(userId)).toString();
    final dir = await Directory('${base.path}/$folder/$user').create(recursive: true);
    final stem = '${dir.path}/$meetingId-${const Uuid().v4()}';
    final partial = File('$stem.part');
    try {
      final response = await dio.download(
        Endpoints.meetingAudio(meetingId),
        partial.path,
        cancelToken: cancel,
        options: Options(receiveTimeout: timeout, sendTimeout: timeout),
      );
      if (cancel.isCancelled) throw const ApiException(kind: ApiErrorKind.cancelled);
      if (await partial.length() == 0) throw const ApiException(kind: ApiErrorKind.server);
      final disposition = response.headers.value('content-disposition') ?? '';
      final extension =
          RegExp(
            r'\.(wav|m4a|aac|mp3|ogg|flac|webm|mp4)(?:[";\s]|$)',
            caseSensitive: false,
          ).firstMatch(disposition)?.group(1)?.toLowerCase() ??
          ((response.headers.value('content-type') ?? '').contains('wav') ? 'wav' : 'audio');
      return await partial.rename('$stem.$extension');
    } finally {
      if (partial.existsSync()) await partial.delete();
    }
  });
}

@riverpod
RecordingFiles recordingFiles(Ref ref) => RecordingFiles(
  dio: ref.watch(apiClientProvider),
  directory: getApplicationSupportDirectory,
  folder: ref.watch(appConfigProvider).recording.recordingsDirName,
  timeout: ref.watch(appConfigProvider).network.transferTimeout,
  export: (file) async {
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
  },
);

@riverpod
class RecordingDownloadController extends _$RecordingDownloadController {
  CancelToken? _cancel;
  @override
  FutureOr<File?> build(String meetingId) {
    ref.watch(currentUserProvider.select((user) => user?.id));
    ref.onDispose(() => _cancel?.cancel());
    return null;
  }

  Future<bool> download() async {
    if (state.isLoading) return false;
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return false;
    final cancel = CancelToken();
    _cancel = cancel;
    final files = ref.read(recordingFilesProvider);
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() => files.download(meetingId, userId, cancel));
    if (!ref.mounted || cancel.isCancelled) return false;
    state = result;
    return !result.hasError;
  }

  Future<void> export() async {
    final file = state.value;
    if (file == null || state.isLoading) return;
    state = const AsyncLoading();
    try {
      await ref.read(recordingFilesProvider).export(file);
      if (ref.mounted) state = AsyncData(file);
    } on Object catch (error, stack) {
      if (ref.mounted) state = AsyncError<File?>(error, stack);
    }
  }
}
