import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/models/job_models.dart';
import '../../../core/config/app_config_provider.dart';
import '../../import/data/jobs_repository_impl.dart';
import '../../import/domain/job_poller.dart';
import '../../import/domain/job_run_state.dart';
import 'meeting_detail_controller.dart';

part 'retranscribe_controller.g.dart';

/// Retranscription of one meeting (`POST /jobs/retranscribe`, then job polling with
/// `AppConfig.polling.job*`). A 409 means a job is already running (`JobFailed.error.kind ==
/// conflict`). On completion the transcript list reloads.
@riverpod
class RetranscribeController extends _$RetranscribeController {
  StreamSubscription<Job>? _poll;

  @override
  JobRunState build(String meetingId) {
    ref.onDispose(() => unawaited(_poll?.cancel()));
    return const JobRunState.idle();
  }

  /// Starts retranscribing with [language] (`auto` = detect).
  Future<void> start(String language) async {
    if (state.isActive) return;
    final repo = ref.read(jobsRepositoryProvider);
    state = const JobRunState.uploading(fraction: 1);
    try {
      final job = await repo.retranscribe(
        meetingId,
        language: TranscriptionLanguage.toParam(language),
      );
      if (!ref.mounted) return;
      state = JobRunState.running(job);
      _follow(job.id);
    } on Object catch (e) {
      if (ref.mounted) state = JobRunState.failed(error: ApiException.from(e));
    }
  }

  void _follow(String jobId) {
    final polling = ref.read(appConfigProvider).polling;
    unawaited(_poll?.cancel());
    _poll =
        pollJob(
          ref.read(jobsRepositoryProvider),
          jobId,
          interval: polling.jobInterval,
          maxConsecutiveErrors: polling.jobMaxConsecutiveErrors,
        ).listen(
          _onJob,
          onError: (Object e) {
            if (ref.mounted) state = JobRunState.failed(error: ApiException.from(e));
          },
        );
  }

  void _onJob(Job job) {
    if (!ref.mounted) return;
    state = switch (job.status) {
      JobStatus.completed => JobRunState.completed(job),
      JobStatus.failed => JobRunState.failed(message: job.error ?? job.message),
      JobStatus.cancelled => const JobRunState.cancelled(),
      _ => JobRunState.running(job),
    };
    if (job.status == JobStatus.completed) {
      ref.invalidate(transcriptsControllerProvider(meetingId));
      ref.invalidate(meetingDetailControllerProvider(meetingId));
    }
  }

  /// Cancels the running job (`DELETE /jobs/{id}`).
  Future<void> cancel() async {
    final current = state;
    if (current is! JobRunning) return;
    await _poll?.cancel();
    _poll = null;
    try {
      await ref.read(jobsRepositoryProvider).cancelJob(current.job.id);
    } on Object {
      // The job may have finished meanwhile; nothing else to do.
    }
    if (ref.mounted) state = const JobRunState.cancelled();
  }

  /// Back to idle (dialog closed after a terminal state).
  void reset() {
    if (!state.isActive) state = const JobRunState.idle();
  }
}
