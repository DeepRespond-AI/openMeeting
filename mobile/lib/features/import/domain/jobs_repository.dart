import 'dart:async';

import '../../../core/api/models/job_models.dart';

/// Lets a caller abort an in-flight transfer without depending on the HTTP library.
class CancellationSignal {
  final Completer<void> _completer = Completer<void>();

  bool get isCancelled => _completer.isCompleted;

  /// Completes when [cancel] is called.
  Future<void> get whenCancelled => _completer.future;

  void cancel() {
    if (!_completer.isCompleted) _completer.complete();
  }
}

/// Reports upload progress: [sent] of [total] bytes ([total] ≤ 0 when unknown).
typedef TransferProgress = void Function(int sent, int total);

/// The audio file to import.
class ImportUpload {
  const ImportUpload({
    required this.filePath,
    required this.fileName,
    required this.title,
    this.language,
  });

  final String filePath;
  final String fileName;
  final String title;

  /// `null` = auto-detect (field omitted).
  final String? language;
}

/// Background jobs (server/API.md §1.5) — import & retranscription. Throws `ApiException`.
abstract interface class JobsRepository {
  /// `POST /jobs/import` (multipart `file`, `title`, `language?`).
  Future<Job> startImport(
    ImportUpload upload, {
    TransferProgress? onProgress,
    CancellationSignal? cancel,
  });

  /// `POST /jobs/retranscribe` `{"meeting_id","language"}`. 409 = already running.
  Future<Job> retranscribe(String meetingId, {String? language});

  /// `GET /jobs/{id}`.
  Future<Job> getJob(String jobId);

  /// `DELETE /jobs/{id}` → status `cancelled`.
  Future<Job> cancelJob(String jobId);
}
