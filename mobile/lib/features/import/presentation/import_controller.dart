import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/models/job_models.dart';
import '../../../core/config/app_config_provider.dart';
import '../../../core/config/settings_controller.dart';
import '../data/audio_file_picker_impl.dart';
import '../data/jobs_repository_impl.dart';
import '../domain/audio_file_picker.dart';
import '../domain/job_poller.dart';
import '../domain/job_run_state.dart';
import '../domain/jobs_repository.dart';
import 'background_imports.dart';

part 'import_controller.freezed.dart';
part 'import_controller.g.dart';

/// Import page state: the form plus the upload/job lifecycle.
@freezed
abstract class ImportState with _$ImportState {
  const factory ImportState({
    PickedAudioFile? file,
    @Default('') String title,

    /// Transcription language code (`auto` = detect).
    required String language,
    @Default(JobRunState.idle()) JobRunState run,
  }) = _ImportState;

  const ImportState._();

  bool get canStart => file != null && title.trim().isNotEmpty && !run.isActive;
}

/// Audio import (desktop `import.rs`): pick → multipart upload with progress → submitted.
/// Only the upload blocks the page; [BackgroundImports] follows the server transcription.
@riverpod
class ImportController extends _$ImportController {
  CancellationSignal? _uploadCancel;

  @override
  ImportState build() {
    ref.onDispose(() => _uploadCancel?.cancel());
    return ImportState(language: ref.read(effectiveSettingsProvider).transcriptionLanguage);
  }

  /// Opens the system picker; the title defaults to the file name without extension.
  Future<void> pickFile() async {
    if (state.run.isActive) return;
    final extensions = ref.read(appConfigProvider).importFile.allowedExtensions;
    final file = await ref.read(audioFilePickerProvider).pick(allowedExtensions: extensions);
    if (file == null || !ref.mounted) return;
    final title = String.fromCharCodes(
      file.baseName.runes.take(ref.read(appConfigProvider).live.titleMax),
    );
    state = state.copyWith(file: file, title: title, run: const JobRunState.idle());
  }

  void setTitle(String title) => state = state.copyWith(title: title);

  void setLanguage(String language) => state = state.copyWith(language: language);

  /// Uploads the file and hands the server job to [BackgroundImports].
  Future<void> start() async {
    final file = state.file;
    if (file == null ||
        !state.canStart ||
        state.title.trim().runes.length > ref.read(appConfigProvider).live.titleMax) {
      return;
    }
    final cancel = CancellationSignal();
    _uploadCancel = cancel;
    state = state.copyWith(run: const JobRunState.uploading());
    final Job job;
    try {
      job = await ref
          .read(jobsRepositoryProvider)
          .startImport(
            ImportUpload(
              filePath: file.path,
              fileName: file.name,
              title: state.title.trim(),
              language: TranscriptionLanguage.toParam(state.language),
            ),
            cancel: cancel,
            onProgress: (sent, total) {
              if (!ref.mounted || total <= 0 || state.run is! JobUploading) return;
              state = state.copyWith(run: JobRunState.uploading(fraction: sent / total));
            },
          );
    } on Object catch (e) {
      if (!ref.mounted) return;
      final error = ApiException.from(e);
      state = state.copyWith(
        run: error.kind == ApiErrorKind.cancelled
            ? const JobRunState.cancelled()
            : JobRunState.failed(error: error),
      );
      return;
    } finally {
      _uploadCancel = null;
    }
    if (!ref.mounted) return;
    // The upload is all the page waits for; the transcription is followed in the background.
    ref.read(backgroundImportsProvider.notifier).follow(job, state.title.trim());
    state = state.copyWith(run: JobRunState.submitted(job));
  }

  /// Cancels the upload (CancelToken); a submitted import is no longer cancellable.
  void cancel() {
    if (state.run is JobUploading) _uploadCancel?.cancel(); // start() → JobCancelled
  }
}
