import '../../../core/api/models/job_models.dart';
import '../../../core/api/retry.dart';
import 'jobs_repository.dart';

Future<void> _defaultSleep(Duration d) => Future<void>.delayed(d);

/// Transcription language codes (`AppConfig.transcription.languages`).
abstract final class TranscriptionLanguage {
  /// Pseudo-code meaning "let the server detect" — sent as `null` / omitted.
  static const String auto = 'auto';

  /// Value for the `language` field/parameter.
  static String? toParam(String code) => code == auto || code.isEmpty ? null : code;
}

/// Polls `GET /jobs/{id}` every [interval] and emits each [Job] until it reaches a terminal
/// status (that job is emitted last). Transient failures are tolerated until
/// [maxConsecutiveErrors] happen in a row, then the last error is thrown.
///
/// Cancel the subscription to stop polling (values from `AppConfig.polling.job*`).
Stream<Job> pollJob(
  JobsRepository repo,
  String jobId, {
  required Duration interval,
  required int maxConsecutiveErrors,
  Sleeper sleep = _defaultSleep,
}) async* {
  var errors = 0;
  while (true) {
    await sleep(interval);
    final Job job;
    try {
      job = await repo.getJob(jobId);
    } on Object {
      errors++;
      if (errors >= maxConsecutiveErrors) rethrow;
      continue;
    }
    errors = 0;
    yield job;
    if (job.status.isTerminal) return;
  }
}
