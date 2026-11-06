import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/models/job_models.dart';
import '../../../core/config/app_config_provider.dart';
import '../../../core/data/background_work.dart';
import '../../../core/data/meetings_changed.dart';
import '../data/jobs_repository_impl.dart';
import '../domain/job_poller.dart';

part 'background_imports.g.dart';

/// Follows uploaded import jobs until the server has transcribed them, independent of any
/// page (desktop `import.rs`): the meeting is marked in [MeetingSync] meanwhile and the
/// outcome is posted to [BackgroundNotices]. State = ids of the jobs being followed.
@Riverpod(keepAlive: true)
class BackgroundImports extends _$BackgroundImports {
  final Map<String, StreamSubscription<Job>> _polls = {};

  @override
  Set<String> build() {
    ref.onDispose(() {
      for (final poll in _polls.values) {
        unawaited(poll.cancel());
      }
      _polls.clear();
    });
    return const {};
  }

  /// Starts following [job] (just returned by the upload) for the meeting titled [title].
  void follow(Job job, String title) {
    final meetingId = job.meetingId;
    if (meetingId == null || _polls.containsKey(job.id)) return;
    ref.read(meetingSyncProvider.notifier).begin(meetingId);
    ref.read(meetingsChangedProvider.notifier).bump(); // the new meeting shows up in the list
    if (job.status.isTerminal) {
      _finish(job, meetingId, title);
      return;
    }
    state = {...state, job.id};
    final polling = ref.read(appConfigProvider).polling;
    _polls[job.id] =
        pollJob(
          ref.read(jobsRepositoryProvider),
          job.id,
          interval: polling.jobInterval,
          maxConsecutiveErrors: polling.jobMaxConsecutiveErrors,
        ).listen((update) {
          if (update.status.isTerminal) _finish(update, meetingId, title);
        }, onError: (Object _) => _finish(job, meetingId, title, requestFailed: true));
  }

  void _finish(Job job, String meetingId, String title, {bool requestFailed = false}) {
    unawaited(_polls.remove(job.id)?.cancel());
    if (!ref.mounted) return;
    state = {...state}..remove(job.id);
    ref.read(meetingSyncProvider.notifier).end(meetingId);
    ref.read(meetingsChangedProvider.notifier).bump();
    final notices = ref.read(backgroundNoticesProvider.notifier);
    if (!requestFailed && job.status == JobStatus.completed) {
      notices.post(
        BackgroundNotice.importTranscribed(
          id: notices.nextId(),
          meetingId: meetingId,
          title: title,
          segments: job.segments ?? 0,
        ),
      );
    } else if (requestFailed || job.status == JobStatus.failed) {
      notices.post(
        BackgroundNotice.importFailed(
          id: notices.nextId(),
          meetingId: meetingId,
          title: title,
          message: requestFailed ? null : job.error ?? job.message,
        ),
      );
    }
  }
}
