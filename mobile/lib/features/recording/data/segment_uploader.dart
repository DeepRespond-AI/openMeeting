import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/retry.dart';
import '../../../core/config/app_config.dart';
import '../../../core/config/app_config_provider.dart';
import '../domain/recording_repository.dart';
import '../domain/segment_upload.dart';
import 'connectivity_monitor.dart';
import 'pending_queue.dart';
import 'recording_repository_impl.dart';
import 'serial_executor.dart';

part 'segment_uploader.g.dart';

/// Uploads live speech segments (`POST /meetings/{id}/segments`).
///
/// - Each upload is retried per `AppConfig.network.retry` (network errors, timeouts, 429, 5xx).
/// - A segment that still fails goes to the persistent [PendingQueue]; while the queue is not
///   empty, new segments are queued behind it so uploads stay in order.
/// - The queue is flushed in FIFO order when connectivity returns, after a backoff, and on
///   [flush] (e.g. at stop). The server dedups on `(meeting_id, seq)`, so re-sending is safe.
/// - Segments rejected for good (e.g. 413, 404) are dropped and reported on [errors].
///
/// All work is serialized; [submit] returns once the segment was uploaded or queued.
class SegmentUploader {
  SegmentUploader({
    required this._repository,
    required this._queue,
    required this._policy,
    Stream<bool>? onlineChanges,
    Sleeper? sleep,
  }) : _sleep = sleep ?? Future<void>.delayed {
    _onlineSub = onlineChanges?.listen((online) {
      if (online) _flushInBackground();
    });
  }

  final RecordingRepository _repository;
  final PendingQueue _queue;
  final RetryConfig _policy;
  final Sleeper _sleep;
  final SerialExecutor _serial = SerialExecutor();
  final StreamController<SegmentUploadResult> _results =
      StreamController<SegmentUploadResult>.broadcast();
  final StreamController<Object> _errors = StreamController<Object>.broadcast();
  StreamSubscription<bool>? _onlineSub;
  Timer? _retryTimer;
  bool _disposed = false;

  /// `true` after a failure until a flush succeeds: new segments go straight to the queue.
  bool _suspended = false;

  /// Transcription results, in upload order.
  Stream<SegmentUploadResult> get results => _results.stream;

  /// Uploads dropped because the server rejected them permanently.
  Stream<Object> get errors => _errors.stream;

  /// Number of queued segments after each change.
  Stream<int> get pendingChanges => _queue.changes;

  Future<int> pendingCount({String? meetingId}) => _queue.count(meetingId: meetingId);

  /// Uploads [pcm] for [upload] (or queues it).
  Future<void> submit(SegmentUpload upload, Uint8List pcm) => _serial.run(() async {
    if (_suspended || await _queue.count() > 0) {
      await _queue.add(upload, pcm);
      if (!_suspended) await _flushLocked();
      return;
    }
    try {
      await _upload(upload, pcm);
    } catch (e) {
      if (!_isQueueable(e)) {
        _report(e);
        return;
      }
      await _queue.add(upload, pcm);
      _suspend();
    }
  });

  /// Uploads queued segments in order until one fails. Returns the number still queued
  /// (for [meetingId] when given, else in total).
  Future<int> flush({String? meetingId}) => _serial.run(() async {
    await _flushLocked();
    return _queue.count(meetingId: meetingId);
  });

  Future<void> _flushLocked() async {
    if (_disposed) return;
    _retryTimer?.cancel();
    for (final entry in await _queue.entries()) {
      if (_disposed) return;
      final Uint8List pcm;
      try {
        pcm = await _queue.read(entry);
      } on Object {
        await _queue.remove(entry);
        continue;
      }
      try {
        await _upload(entry, pcm);
        await _queue.remove(entry);
      } catch (e) {
        if (!_isQueueable(e)) {
          _report(e);
          await _queue.remove(entry);
          continue;
        }
        _suspend();
        return;
      }
    }
    _suspended = false;
  }

  Future<void> _upload(SegmentUpload upload, Uint8List pcm) async {
    final result = await retry(
      () => _repository.uploadSegment(upload, pcm),
      policy: _policy,
      sleep: _sleep,
    );
    if (!_results.isClosed) {
      _results.add(SegmentUploadResult(upload: upload, text: result.text, transcriptId: result.id));
    }
  }

  void _suspend() {
    _suspended = true;
    _retryTimer?.cancel();
    if (_disposed) return;
    _retryTimer = Timer(_policy.delayFor(_policy.maxRetries), _flushInBackground);
  }

  void _flushInBackground() {
    if (_disposed) return;
    unawaited(
      flush().then<void>((_) {}, onError: (Object e) => debugPrint('Segment flush failed: $e')),
    );
  }

  /// Flushes leftovers from earlier sessions without awaiting.
  void flushLater() => _flushInBackground();

  void _report(Object error) {
    debugPrint('SegmentUploader: dropping segment: $error');
    if (!_errors.isClosed) _errors.add(error);
  }

  /// Worth keeping for later: transient failures, or a session that may be renewed.
  static bool _isQueueable(Object error) {
    final e = ApiException.from(error);
    return e.isRetryable ||
        e.kind == ApiErrorKind.unauthorized ||
        e.kind == ApiErrorKind.notConfigured;
  }

  Future<void> dispose() async {
    _disposed = true;
    _retryTimer?.cancel();
    await _onlineSub?.cancel();
    await _results.close();
    await _errors.close();
  }
}

/// The app-wide uploader. Created lazily (by the recording controller); flushes segments left
/// over from earlier sessions right away.
@Riverpod(keepAlive: true)
SegmentUploader segmentUploader(Ref ref) {
  final uploader = SegmentUploader(
    repository: ref.watch(recordingRepositoryProvider),
    queue: ref.watch(pendingQueueProvider),
    policy: ref.watch(appConfigProvider.select((c) => c.network.retry)),
    onlineChanges: ref.watch(connectivityMonitorProvider).onlineChanges,
  );
  ref.onDispose(uploader.dispose);
  uploader.flushLater();
  return uploader;
}
