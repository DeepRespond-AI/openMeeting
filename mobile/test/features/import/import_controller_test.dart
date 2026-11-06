import 'dart:async';
import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meeting/core/api/api_exception.dart';
import 'package:meeting/core/api/models/job_models.dart';
import 'package:meeting/core/data/background_work.dart';
import 'package:meeting/features/import/data/audio_file_picker_impl.dart';
import 'package:meeting/features/import/data/jobs_repository_impl.dart';
import 'package:meeting/features/import/domain/audio_file_picker.dart';
import 'package:meeting/features/import/domain/job_poller.dart';
import 'package:meeting/features/import/domain/job_run_state.dart';
import 'package:meeting/features/import/domain/jobs_repository.dart';
import 'package:meeting/features/import/presentation/import_controller.dart';
import 'package:meeting/features/meetings/presentation/retranscribe_controller.dart';

import '../../helpers/test_config.dart';

Job _job(JobStatus status, {int progress = 0, String? meetingId, int? segments, String? error}) =>
    Job(
      id: 'job-1',
      kind: JobKind.import,
      status: status,
      progress: progress,
      meetingId: meetingId,
      segments: segments,
      error: error,
    );

class FakeJobsRepository implements JobsRepository {
  final Queue<Object> polls = Queue(); // Job or error
  final List<String> calls = [];
  ImportUpload? lastUpload;
  String? lastLanguage;
  Object? startError;

  /// When set, startImport reports progress then waits for it (or for cancellation).
  Completer<void>? uploadGate;

  @override
  Future<Job> startImport(
    ImportUpload upload, {
    TransferProgress? onProgress,
    CancellationSignal? cancel,
  }) async {
    calls.add('import');
    lastUpload = upload;
    onProgress?.call(50, 100);
    if (uploadGate case final gate?) {
      await Future.any([gate.future, if (cancel != null) cancel.whenCancelled]);
      if (cancel?.isCancelled ?? false) throw const ApiException(kind: ApiErrorKind.cancelled);
    }
    onProgress?.call(100, 100);
    return _job(JobStatus.queued, meetingId: 'meeting-9');
  }

  @override
  Future<Job> retranscribe(String meetingId, {String? language}) async {
    calls.add('retranscribe');
    lastLanguage = language;
    if (startError case final e?) throw e;
    return _job(JobStatus.queued);
  }

  @override
  Future<Job> getJob(String jobId) async {
    calls.add('get');
    final next = polls.length > 1 ? polls.removeFirst() : polls.first;
    if (next is Job) return next;
    throw next;
  }

  @override
  Future<Job> cancelJob(String jobId) async {
    calls.add('cancel');
    return _job(JobStatus.cancelled);
  }
}

class FakePicker implements AudioFilePicker {
  List<String>? lastExtensions;

  @override
  Future<PickedAudioFile?> pick({required List<String> allowedExtensions}) async {
    lastExtensions = allowedExtensions;
    return const PickedAudioFile(path: '/tmp/周会 录音.m4a', name: '周会 录音.m4a', size: 2048);
  }
}

void main() {
  group('pollJob', () {
    test('emits until terminal and tolerates transient errors', () async {
      final repo = FakeJobsRepository()
        ..polls.addAll([
          _job(JobStatus.running, progress: 10),
          const ApiException(kind: ApiErrorKind.network),
          _job(JobStatus.completed, progress: 100),
        ]);
      final jobs = await pollJob(
        repo,
        'job-1',
        interval: Duration.zero,
        maxConsecutiveErrors: 3,
      ).toList();
      expect(jobs.map((j) => j.status), [JobStatus.running, JobStatus.completed]);
    });

    test('gives up after maxConsecutiveErrors', () async {
      final repo = FakeJobsRepository()..polls.add(const ApiException(kind: ApiErrorKind.network));
      await expectLater(
        pollJob(repo, 'job-1', interval: Duration.zero, maxConsecutiveErrors: 2).toList(),
        throwsA(isA<ApiException>()),
      );
      expect(repo.calls.length, 2);
    });
  });

  group('ImportController', () {
    late FakeJobsRepository repo;
    late FakePicker picker;
    late ProviderContainer c;

    setUp(() async {
      repo = FakeJobsRepository();
      picker = FakePicker();
      final base = loadConfigFile('dev');
      c = await createTestContainer(
        config: base.copyWith(polling: base.polling.copyWith(jobIntervalSec: 0)),
        overrides: [
          jobsRepositoryProvider.overrideWithValue(repo),
          audioFilePickerProvider.overrideWithValue(picker),
        ],
      );
      final sub = c.listen(importControllerProvider, (_, _) {});
      addTearDown(sub.close);
    });

    Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 10));

    test(
      'pick → title from file name → upload → submitted; transcribed in the background',
      () async {
        final notifier = c.read(importControllerProvider.notifier);
        await notifier.pickFile();
        expect(picker.lastExtensions, contains('m4a'));
        expect(c.read(importControllerProvider).title, '周会 录音');
        expect(c.read(importControllerProvider).language, 'auto');

        final gate = Completer<void>();
        repo.polls.addAll([
          _job(JobStatus.running, progress: 50, meetingId: 'meeting-9'),
          _job(JobStatus.completed, progress: 100, meetingId: 'meeting-9', segments: 12),
        ]);
        final runs = <JobRunState>[];
        final syncs = <Set<String>>[];
        c.listen(importControllerProvider, (_, next) => runs.add(next.run));
        c.listen(meetingSyncProvider, (_, next) {
          syncs.add(next);
          if (next.isEmpty && !gate.isCompleted) gate.complete();
        });
        await notifier.start();

        expect(repo.lastUpload!.title, '周会 录音');
        expect(repo.lastUpload!.language, isNull, reason: 'auto is omitted');
        expect(runs.first, const JobRunState.uploading());
        expect(runs, contains(const JobRunState.uploading(fraction: 0.5)));
        // The page is done as soon as the upload is.
        final submitted = c.read(importControllerProvider).run as JobSubmitted;
        expect(submitted.job.meetingId, 'meeting-9');
        expect(c.read(meetingSyncProvider), {'meeting-9'});

        await gate.future;
        expect(syncs.last, isEmpty);
        final notice = c.read(backgroundNoticesProvider) as ImportTranscribedNotice;
        expect(notice.meetingId, 'meeting-9');
        expect(notice.title, '周会 录音');
        expect(notice.segments, 12);
      },
    );

    test('a chosen language is sent', () async {
      final notifier = c.read(importControllerProvider.notifier);
      await notifier.pickFile();
      notifier
        ..setLanguage('zh')
        ..setTitle('  自定义  ');
      repo.polls.add(_job(JobStatus.completed, meetingId: 'meeting-9'));
      await notifier.start();
      await settle();
      expect(repo.lastUpload!.language, 'zh');
      expect(repo.lastUpload!.title, '自定义');
    });

    test('cancel during upload', () async {
      final notifier = c.read(importControllerProvider.notifier);
      await notifier.pickFile();
      repo.uploadGate = Completer<void>();
      final started = notifier.start();
      await Future<void>.delayed(Duration.zero);
      expect(c.read(importControllerProvider).run, isA<JobUploading>());
      notifier.cancel();
      await started;
      expect(c.read(importControllerProvider).run, const JobRunState.cancelled());
      expect(c.read(meetingSyncProvider), isEmpty);
    });

    test('server-side failure is posted as a background notice', () async {
      final notifier = c.read(importControllerProvider.notifier);
      await notifier.pickFile();
      repo.polls.add(_job(JobStatus.failed, meetingId: 'meeting-9', error: '音频解码失败'));
      await notifier.start();
      await settle();
      expect(c.read(importControllerProvider).run, isA<JobSubmitted>());
      final notice = c.read(backgroundNoticesProvider) as ImportFailedNotice;
      expect(notice.meetingId, 'meeting-9');
      expect(notice.message, '音频解码失败');
      expect(c.read(meetingSyncProvider), isEmpty);
    });

    test('losing the job (poll errors) ends the sync with a notice without message', () async {
      final notifier = c.read(importControllerProvider.notifier);
      await notifier.pickFile();
      repo.polls.add(const ApiException(kind: ApiErrorKind.network));
      await notifier.start();
      await settle();
      final notice = c.read(backgroundNoticesProvider) as ImportFailedNotice;
      expect(notice.message, isNull);
      expect(c.read(meetingSyncProvider), isEmpty);
    });
  });

  group('RetranscribeController', () {
    late FakeJobsRepository repo;
    late ProviderContainer c;
    final provider = retranscribeControllerProvider('m1');

    setUp(() async {
      repo = FakeJobsRepository();
      final base = loadConfigFile('dev');
      c = await createTestContainer(
        config: base.copyWith(polling: base.polling.copyWith(jobIntervalSec: 0)),
        overrides: [jobsRepositoryProvider.overrideWithValue(repo)],
      );
      final sub = c.listen(provider, (_, _) {});
      addTearDown(sub.close);
    });

    test('409 → already running', () async {
      repo.startError = const ApiException(kind: ApiErrorKind.conflict, statusCode: 409);
      await c.read(provider.notifier).start('zh');
      final state = c.read(provider) as JobFailed;
      expect(state.error!.kind, ApiErrorKind.conflict);
      expect(repo.lastLanguage, 'zh');
    });

    test('runs to completion', () async {
      repo.polls.addAll([
        _job(JobStatus.running, progress: 30),
        _job(JobStatus.completed, progress: 100, segments: 4),
      ]);
      await c.read(provider.notifier).start('auto');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(repo.lastLanguage, isNull);
      expect((c.read(provider) as JobCompleted).job.segments, 4);
    });
  });
}
