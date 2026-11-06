import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meeting/core/api/api_exception.dart';
import 'package:meeting/core/config/app_enums.dart';
import 'package:meeting/core/data/background_work.dart';
import 'package:meeting/core/heartbeat/recording_status.dart';
import 'package:meeting/core/l10n/l10n.dart';
import 'package:meeting/features/recording/data/aac_writer_impl.dart';
import 'package:meeting/features/recording/data/audio_sources.dart';
import 'package:meeting/features/recording/data/connectivity_monitor.dart';
import 'package:meeting/features/recording/data/recording_background_impl.dart';
import 'package:meeting/features/recording/data/recording_repository_impl.dart';
import 'package:meeting/features/recording/data/recording_storage.dart';
import 'package:meeting/features/recording/domain/audio_source.dart';
import 'package:meeting/features/recording/domain/recording_state.dart';
import 'package:meeting/features/recording/presentation/recording_controller.dart';
import 'package:meeting/features/recording/presentation/recording_l10n.dart';
import 'package:meeting/features/recording/presentation/recording_levels_controller.dart';
import 'package:meeting/features/recording/presentation/recording_options_controller.dart';

import '../../helpers/test_config.dart';
import 'fakes.dart';
import 'signal.dart';

void main() {
  final config = loadConfigFile('dev');
  final sr = config.audio.sampleRate;
  late Directory dir;
  late FakeAudioSource mic;
  late FakeAacWriter writer;
  late FakeRecordingRepository repo;
  late FakeBackground background;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('recording_controller_test');
    mic = FakeAudioSource();
    writer = FakeAacWriter();
    repo = FakeRecordingRepository();
    background = FakeBackground();
  });

  tearDown(() => dir.deleteSync(recursive: true));

  Future<ProviderContainer> container({
    Map<String, Object> prefs = const {},
    FakeAudioSource? system,
  }) => createTestContainer(
    config: config,
    prefs: prefs,
    overrides: [
      if (system != null) audioSourceProvider(RecordingSource.system).overrideWithValue(system),
      audioSourceProvider(RecordingSource.microphone).overrideWithValue(mic),
      aacWriterFactoryProvider.overrideWithValue(() => writer),
      recordingRepositoryProvider.overrideWithValue(repo),
      recordingBackgroundProvider.overrideWithValue(background),
      connectivityMonitorProvider.overrideWithValue(FakeConnectivity()),
      recordingStorageProvider.overrideWithValue(
        RecordingStorage(
          baseDir: () async => dir,
          recordingsDirName: config.recording.recordingsDirName,
          pendingQueueDirName: config.recording.pendingQueueDirName,
        ),
      ),
      recordingL10nProvider.overrideWithValue(lookupAppLocalizations(const Locale('zh'))),
      recordingClockProvider.overrideWithValue(() => DateTime(2026, 10, 7, 9, 30, 5)),
    ],
  );

  /// Records the sequence of state types.
  List<Type> track(ProviderContainer c) {
    final types = <Type>[];
    c.listen(
      recordingControllerProvider,
      (_, next) => types.add(next.runtimeType),
      fireImmediately: true,
    );
    return types;
  }

  Future<void> settle() => pumpEventQueue(times: 50);

  /// Pumps the event queue until [done] holds (or fails after [maxRounds]); the capture →
  /// writer/VAD → upload chain spans a variable number of async turns under load.
  Future<void> settleUntil(bool Function() done, {int maxRounds = 200}) async {
    for (var i = 0; i < maxRounds && !done(); i++) {
      await pumpEventQueue();
    }
  }

  test('start: creates the meeting, opens the writer, starts capture and reports status', () async {
    final c = await container();
    final states = track(c);
    await c.read(recordingControllerProvider.notifier).start();

    expect(states, [RecordingIdle, RecordingPreparing, RecordingActive]);
    final session = c.read(recordingControllerProvider).session!;
    expect(session.meetingId, 'm1');
    expect(session.title, '会议 2026-10-07_09-30-05');
    expect(session.language, isNull, reason: 'auto → no language parameter');
    expect(repo.calls, ['create:会议 2026-10-07_09-30-05']);
    expect(writer.params, {
      'sampleRate': config.audio.sampleRate,
      'channels': config.audio.channels,
      'bitrate': config.audio.aacBitrate,
    });
    expect(writer.path, endsWith('m1.${config.recording.audioFileExtension}'));
    expect(mic.startedWith?.sampleRate, config.audio.sampleRate);
    expect(background.calls, ['start']);
    expect(
      c.read(recordingStatusControllerProvider),
      const RecordingStatus(recording: true, meetingId: 'm1'),
    );
  });

  test('frames go to the writer and VAD; segments are uploaded and shown live', () async {
    final c = await container(prefs: {'settings.transcriptionLanguage': 'zh'});
    final controller = c.read(recordingControllerProvider.notifier);
    await controller.start();

    final audio = SignalBuilder(sr).silence(1).tone(1).silence(1).tone(1).silence(1).build();
    const chunk = 3200;
    for (var i = 0; i < audio.length; i += chunk) {
      mic.emitFrame(Uint8List.sublistView(audio, i, (i + chunk).clamp(0, audio.length)));
    }
    mic.emitLevel(0.5);
    await settleUntil(
      () =>
          writer.written.length == audio.length &&
          (c.read(recordingControllerProvider).session?.transcripts.length ?? 0) == 2,
    );

    final session = c.read(recordingControllerProvider).session!;
    expect(writer.written.length, audio.length);
    expect(session.elapsed, const Duration(seconds: 5));
    expect(repo.segments.map((s) => s.seq), [0, 1]);
    expect(repo.segments.every((s) => s.language == 'zh' && s.meetingId == 'm1'), isTrue);
    expect(session.transcripts.map((t) => t.text), ['line 0', 'line 1']);
    expect(c.read(recordingLevelsControllerProvider).last, 0.5);
    expect(background.calls.where((x) => x.startsWith('update:')), isNotEmpty);
  });

  test('pause/resume and system interruptions', () async {
    final c = await container();
    final controller = c.read(recordingControllerProvider.notifier);
    await controller.start();

    await controller.pause();
    expect(c.read(recordingControllerProvider), isA<RecordingPaused>());
    await controller.resume();
    expect(c.read(recordingControllerProvider), isA<RecordingActive>());
    expect(mic.calls, ['start', 'pause', 'resume']);

    mic.emitEvent(const AudioSourceInterrupted());
    await settle();
    expect(
      c.read(recordingControllerProvider),
      isA<RecordingPaused>().having((s) => s.interrupted, 'interrupted', isTrue),
    );
    mic.emitEvent(const AudioSourceInterruptionEnded());
    await settle();
    expect(c.read(recordingControllerProvider), isA<RecordingActive>());
  });

  test(
    'stop: done right after the local save; rename, segments and audio sync in the background',
    () async {
      final c = await container(
        prefs: {'settings.keepLocalAudio': false, 'settings.autoSummary': true},
      );
      final states = track(c);
      final controller = c.read(recordingControllerProvider.notifier);
      await controller.start();
      // Speech still open when stopping → flushed from the VAD tail.
      mic.emitFrame(SignalBuilder(sr).silence(1).tone(1).build());
      await settle();
      controller.rename('  周会  ');
      await controller.stop();

      final done = c.read(recordingControllerProvider);
      expect(done, const RecordingState.done(meetingId: 'm1', autoSummary: true));
      expect(c.read(meetingSyncProvider), {'m1'}, reason: 'the sync continues in the background');
      await settle();

      expect(c.read(meetingSyncProvider), isEmpty);
      expect(repo.segments.map((s) => s.seq), [0]);
      expect(repo.calls, containsAllInOrder(['rename:m1', 'audio:m1']));
      expect(repo.renamedTo, '周会');
      expect(writer.closeCount, 1);
      expect(mic.calls.last, 'stop');
      expect(File(writer.path!).existsSync(), isFalse, reason: 'keepLocalAudio off');
      expect(background.calls.last, 'stop');
      expect(c.read(recordingStatusControllerProvider), const RecordingStatus());
      expect(states.first, RecordingIdle);
      expect(states.last, RecordingDone);
      expect(states, containsAllInOrder([RecordingStopping, RecordingDone]));

      c.read(recordingControllerProvider.notifier).reset();
      expect(c.read(recordingControllerProvider), const RecordingState.idle());
    },
  );

  test('keeps the local audio file when keepLocalAudio is on', () async {
    final c = await container(
      prefs: {'settings.keepLocalAudio': true, 'settings.autoSummary': false},
    );
    final controller = c.read(recordingControllerProvider.notifier);
    await controller.start();
    mic.emitFrame(SignalBuilder(sr).tone(0.5).build());
    await settle();
    await controller.stop();
    await settle();

    expect(
      c.read(recordingControllerProvider),
      const RecordingState.done(meetingId: 'm1', autoSummary: false),
    );
    expect(File(writer.path!).existsSync(), isTrue);
    expect(repo.calls, isNot(contains('rename:m1')));
  });

  test('meeting creation failure → error(start), capture never started', () async {
    repo.createError = const ApiException(kind: ApiErrorKind.network);
    final c = await container();
    await c.read(recordingControllerProvider.notifier).start();

    final state = c.read(recordingControllerProvider);
    expect(state, isA<RecordingError>().having((e) => e.stage, 'stage', RecordingErrorStage.start));
    expect(mic.calls, isNot(contains('start')));
    expect(writer.path, isNull);
    expect(c.read(recordingStatusControllerProvider).recording, isFalse);
  });

  test('capture start failure (permission) → error(start) and the meeting is deleted', () async {
    mic.startError = const AudioSourceException(AudioSourceErrorCode.permissionDenied);
    final c = await container();
    await c.read(recordingControllerProvider.notifier).start();
    await settle();

    final state = c.read(recordingControllerProvider);
    expect(state, isA<RecordingError>().having((e) => e.error, 'error', mic.startError));
    expect(repo.calls, contains('delete:m1'));
    expect(background.calls, ['start', 'stop']);

    c.read(recordingControllerProvider.notifier).reset();
    expect(c.read(recordingControllerProvider), isA<RecordingIdle>());
  });

  test('unsupported source is rejected before creating a meeting', () async {
    final system = FakeAudioSource(kind: RecordingSource.system)
      ..availabilityResult = AudioSourceAvailability.unsupported;
    final scoped = await container(system: system);
    scoped.read(recordingOptionsControllerProvider.notifier).setSource(RecordingSource.system);
    await scoped.read(recordingControllerProvider.notifier).start();

    expect(scoped.read(recordingControllerProvider), isA<RecordingError>());
    expect(repo.calls, isEmpty);
  });

  test('audio upload failure → notice, local file kept; retryUpload uploads again', () async {
    repo.failAudioUploads = 1;
    final c = await container(prefs: {'settings.keepLocalAudio': false});
    final controller = c.read(recordingControllerProvider.notifier);
    await controller.start();
    mic.emitFrame(SignalBuilder(sr).tone(0.5).build());
    await settle();
    await controller.stop();
    await settle();

    expect(c.read(recordingControllerProvider), isA<RecordingDone>());
    final notice = c.read(backgroundNoticesProvider);
    expect(
      notice,
      isA<RecordingUploadFailedNotice>().having((n) => n.meetingId, 'meetingId', 'm1'),
    );
    expect(c.read(meetingSyncProvider), isEmpty);
    expect(File(writer.path!).existsSync(), isTrue, reason: 'kept for the retry');

    await controller.retryUpload('m1');
    expect(repo.calls.where((x) => x == 'audio:m1'), hasLength(2));
    expect(c.read(backgroundNoticesProvider), same(notice), reason: 'no new failure');
    expect(File(writer.path!).existsSync(), isFalse);
    expect(c.read(meetingSyncProvider), isEmpty);
  });

  test('capture stopped externally / notification stop action → recording is finalized', () async {
    final c = await container();
    final controller = c.read(recordingControllerProvider.notifier);
    await controller.start();
    mic.emitEvent(const AudioSourceStoppedExternally());
    await settle();
    expect(c.read(recordingControllerProvider), isA<RecordingDone>());
  });

  test('notification stop action stops the recording', () async {
    final c = await container();
    final controller = c.read(recordingControllerProvider.notifier);
    await controller.start();
    background.stops.add(null);
    await settle();
    expect(c.read(recordingControllerProvider), isA<RecordingDone>());
  });
}
