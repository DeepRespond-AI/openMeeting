import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/models/job_models.dart';

part 'job_run_state.freezed.dart';

/// Lifecycle of a client-driven background job (import or retranscription):
/// `idle → (uploading →) running → completed | failed | cancelled`; an import ends at
/// `uploading → submitted` and its job continues in the background.
@freezed
sealed class JobRunState with _$JobRunState {
  const factory JobRunState.idle() = JobIdle;

  /// Import only: multipart upload in flight; [fraction] 0..1.
  const factory JobRunState.uploading({@Default(0) double fraction}) = JobUploading;

  /// Import only: the upload finished and the server job was accepted; the transcription is
  /// followed in the background (`BackgroundImports`), so the import page is done.
  const factory JobRunState.submitted(Job job) = JobSubmitted;

  /// Server job accepted / running.
  const factory JobRunState.running(Job job) = JobRunning;

  const factory JobRunState.completed(Job job) = JobCompleted;

  /// [error] for request failures; [message] = server job `error` text.
  const factory JobRunState.failed({ApiException? error, String? message}) = JobFailed;

  const factory JobRunState.cancelled() = JobCancelled;

  const JobRunState._();

  bool get isActive => this is JobUploading || this is JobRunning;
}
