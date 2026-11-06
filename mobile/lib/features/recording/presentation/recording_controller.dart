import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/retry.dart';
import '../../../core/config/app_config.dart';
import '../../../core/config/app_config_provider.dart';
import '../../../core/config/app_enums.dart';
import '../../../core/config/settings_controller.dart';
import '../../../core/data/background_work.dart';
import '../../../core/data/meetings_changed.dart';
import '../../../core/heartbeat/recording_status.dart';
import '../data/aac_writer_impl.dart';
import '../data/audio_sources.dart';
import '../data/recording_background_impl.dart';
import '../data/recording_repository_impl.dart';
import '../data/recording_storage.dart';
import '../data/segment_uploader.dart';
import '../domain/aac_writer.dart';
import '../domain/audio_source.dart';
import '../domain/energy_vad.dart';
import '../domain/pcm.dart';
import '../domain/recording_state.dart';
import '../domain/segment_upload.dart';
import '../domain/time_format.dart';
import 'recording_l10n.dart';
import 'recording_levels_controller.dart';
import 'recording_options_controller.dart';

part 'recording_controller.g.dart';

/// Clock used for the meeting title; overridable in tests.
@Riverpod(keepAlive: true)
DateTime Function() recordingClock(Ref ref) => DateTime.now;

/// The recording flow (DEVELOPMENT.md §2): one global state machine that aggregates the audio
/// source, VAD, segment uploader and AAC writer. Pages and the notification only observe it.
///
/// `idle → preparing → recording ⇄ paused → stopping → done | error`
///
/// - start: create the meeting (`POST /meetings`), open the m4a writer, start the foreground
///   service and capture; every frame goes to the AAC writer and the streaming VAD, whose
///   segments are uploaded live (results → [RecordingSession.transcripts]).
/// - stop: stop capture, submit the VAD tail and finalize the local m4a, then [RecordingDone]
///   right away (the page navigates to the meeting). The rest runs in the background while
///   the meeting is marked in [MeetingSync] (desktop `finish_meeting_sync`): apply a rename,
///   flush the segment queue, upload the audio (`PUT /meetings/{id}/audio`,
///   `AppConfig.network.audioUploadRetry`). A failed upload keeps the local file and posts a
///   [BackgroundNotice.recordingUploadFailed]; [retryUpload] tries again.
@Riverpod(keepAlive: true)
class RecordingController extends _$RecordingController {
  ProviderSubscription<AudioSource>? _sourceSub;
  AudioSource? _source;
  AacWriter? _writer;
  Object? _writerError;
  EnergyVad? _vad;
  int _nextSeq = 0;
  int _capturedBytes = 0;
  final List<StreamSubscription<Object?>> _subs = [];
  Completer<void>? _framesDone;
  bool _stopRequested = false;

  /// Stopped recordings whose audio upload failed, by meeting id (for [retryUpload]).
  final Map<String, RecordingSession> _failedUploads = {};

  @override
  RecordingState build() {
    ref.onDispose(() => unawaited(_teardownCapture()));
    return const RecordingState.idle();
  }

  AppConfig get _config => ref.read(appConfigProvider);

  /// Starts a recording with the current [RecordingOptions].
  Future<void> start() async {
    if (state.isBusy) return;
    final options = ref.read(recordingOptionsControllerProvider);
    final config = _config;
    final repo = ref.read(recordingRepositoryProvider);
    final l10n = ref.read(recordingL10nProvider);
    state = RecordingState.preparing(source: options.source);
    _stopRequested = false;
    _writerError = null;
    _nextSeq = 0;
    _capturedBytes = 0;

    String? meetingId;
    String? audioPath;
    try {
      final source = _acquireSource(options.source);
      if (await source.availability() == AudioSourceAvailability.unsupported) {
        throw const AudioSourceException(AudioSourceErrorCode.unsupported);
      }

      final stamp = DateFormat(config.recording.titleFormat)
          .format(ref.read(recordingClockProvider)());
      final meeting = await repo.createMeeting(l10n.recordingMeetingTitle(stamp));
      meetingId = meeting.id;
      ref.read(meetingsChangedProvider.notifier).bump();

      final dir = await ref.read(recordingStorageProvider).recordingsDir();
      audioPath =
          '${dir.path}${Platform.pathSeparator}$meetingId.${config.recording.audioFileExtension}';
      final writer = _writer = ref.read(aacWriterFactoryProvider)();
      await writer.open(
        path: audioPath,
        sampleRate: config.audio.sampleRate,
        channels: config.audio.channels,
        bitrate: config.audio.aacBitrate,
      );
      _vad = EnergyVad(config: config.vad, sampleRate: config.audio.sampleRate);

      final uploader = ref.read(segmentUploaderProvider);
      final id = meetingId;
      _subs
        ..add(uploader.results.where((r) => r.upload.meetingId == id).listen(_onResult))
        ..add(uploader.pendingChanges.listen((_) => unawaited(_refreshPending(id))));

      final background = ref.read(recordingBackgroundProvider);
      // System capture runs its own mediaProjection foreground service (one notification);
      // the microphone service is only needed for the microphone source.
      if (options.source == RecordingSource.microphone) {
        await background.start(
          channelName: l10n.recordingNotificationChannel,
          title: l10n.recordingNotificationTitle,
          text: l10n.recordingNotificationText(formatElapsed(Duration.zero)),
          stopLabel: l10n.recordingStop,
        );
      }
      _subs.add(background.stopRequests.listen((_) => unawaited(stop())));

      await source.start(
        AudioCaptureOptions(
          sampleRate: config.audio.sampleRate,
          channels: config.audio.channels,
          micGain: config.recording.systemAudioMicGain,
          systemDuckingRatio: config.recording.systemAudioDuckingRatio,
        ),
      );
      final framesDone = _framesDone = Completer<void>();
      _subs
        ..add(
          source.frames.listen(
            _onFrame,
            onDone: () {
              if (!framesDone.isCompleted) framesDone.complete();
            },
            onError: (Object e) => debugPrint('Recording frames error: $e'),
          ),
        )
        ..add(source.level.listen(ref.read(recordingLevelsControllerProvider.notifier).push))
        ..add(source.events.listen(_onSourceEvent));

      final language = options.language == config.transcription.autoLanguageCode
          ? null
          : options.language;
      state = RecordingState.recording(
        session: RecordingSession(
          meetingId: meeting.id,
          title: meeting.title,
          source: options.source,
          language: language,
          audioPath: audioPath,
        ),
      );
      ref
          .read(recordingStatusControllerProvider.notifier)
          .set(recording: true, meetingId: meeting.id);
    } catch (e, st) {
      debugPrint('Recording start failed: $e\n$st');
      _cancelSubs();
      await _teardownCapture();
      await _closeWriter();
      if (audioPath != null) await _deleteFile(audioPath);
      if (meetingId != null) {
        unawaited(
          repo
              .deleteMeeting(meetingId)
              .catchError((Object err) => debugPrint('Cleanup of meeting $meetingId failed: $err')),
        );
      }
      state = RecordingState.error(error: e, stage: RecordingErrorStage.start);
    }
  }

  Future<void> pause() async {
    final current = state;
    if (current is! RecordingActive) return;
    await _source?.pause();
    state = RecordingState.paused(session: current.session);
  }

  Future<void> resume() async {
    final current = state;
    if (current is! RecordingPaused) return;
    await _source?.resume();
    state = RecordingState.recording(session: current.session);
  }

  /// Renames the meeting; applied on the server when the recording is finalized.
  void rename(String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty || trimmed.runes.length > _config.live.titleMax) return;
    _updateSession((s) => s.copyWith(title: trimmed, titleEdited: true));
  }

  /// Stops capturing and saves the recording locally; the server sync continues in the
  /// background (see the class comment), so the user never waits for uploads.
  Future<void> stop() async {
    final session = state.session;
    if (!state.isLive || session == null || _stopRequested) return;
    _stopRequested = true;
    state = RecordingState.stopping(session: session);

    await _stopCapture();
    final vad = _vad;
    _vad = null;
    if (vad != null) {
      for (final segment in vad.flush()) {
        _submit(session.meetingId, segment);
      }
    }
    await _closeWriter();
    // Late transcripts are not shown live; the meeting page reloads when the sync ends.
    _cancelSubs();

    final latest = state.session ?? session;
    ref.read(meetingSyncProvider.notifier).begin(latest.meetingId);
    unawaited(_syncInBackground(latest));
    ref.read(meetingsChangedProvider.notifier).bump();
    state = RecordingState.done(
      meetingId: latest.meetingId,
      autoSummary: ref.read(effectiveSettingsProvider).autoSummary,
    );
  }

  /// Retries the audio upload of a stopped recording after
  /// [BackgroundNotice.recordingUploadFailed].
  Future<void> retryUpload(String meetingId) async {
    final session = _failedUploads.remove(meetingId);
    if (session == null) return;
    ref.read(meetingSyncProvider.notifier).begin(meetingId);
    await _syncInBackground(session.copyWith(titleEdited: false));
  }

  /// Back to idle after [RecordingDone] / [RecordingError].
  void reset() {
    if (state is! RecordingDone && state is! RecordingError) return;
    _cancelSubs();
    ref.read(recordingLevelsControllerProvider.notifier).clear();
    state = const RecordingState.idle();
  }

  /// Everything Stop leaves to the background: rename, remaining segments, audio upload.
  /// Always ends the meeting's [MeetingSync] mark.
  Future<void> _syncInBackground(RecordingSession session) async {
    final config = _config;
    final repo = ref.read(recordingRepositoryProvider);
    final meetingId = session.meetingId;
    try {
      if (session.titleEdited) {
        try {
          await retry(
            () => repo.renameMeeting(meetingId, session.title),
            policy: config.network.retry,
          );
        } on Object catch (e) {
          debugPrint('Renaming meeting $meetingId failed: $e');
        }
      }
      await ref.read(segmentUploaderProvider).flush(meetingId: meetingId);
      final file = File(session.audioPath);
      if (file.existsSync() && file.lengthSync() > 0) {
        await retry(
          () =>
              repo.uploadAudio(meetingId, file, duration: session.elapsed.inMicroseconds / 1000000),
          policy: config.network.audioUploadRetry,
        );
      }
      if (!ref.read(effectiveSettingsProvider).keepLocalAudio) await _deleteFile(session.audioPath);
    } catch (e, st) {
      debugPrint('Recording upload failed: $e\n$st');
      if (!ref.mounted) return;
      _failedUploads[meetingId] = session;
      final notices = ref.read(backgroundNoticesProvider.notifier);
      notices.post(
        BackgroundNotice.recordingUploadFailed(id: notices.nextId(), meetingId: meetingId),
      );
    } finally {
      if (ref.mounted) {
        ref.read(meetingSyncProvider.notifier).end(meetingId);
        ref.read(meetingsChangedProvider.notifier).bump(); // final title / audio
      }
    }
  }

  AudioSource _acquireSource(RecordingSource kind) {
    _sourceSub?.close();
    final sub = _sourceSub = ref.listen(audioSourceProvider(kind), (_, _) {});
    return _source = sub.read();
  }

  void _onFrame(Uint8List chunk) {
    final current = state;
    if (current is! RecordingActive && current is! RecordingStopping) return;
    final session = current.session;
    if (session == null) return;
    final writer = _writer;
    if (writer != null) {
      writer.write(chunk).catchError((Object e) {
        _writerError ??= e;
        debugPrint('AAC write failed: $e');
      });
    }
    final vad = _vad;
    if (vad != null) {
      for (final segment in vad.add(chunk)) {
        _submit(session.meetingId, segment);
      }
    }
    final before = _elapsed();
    _capturedBytes += chunk.length;
    final after = _elapsed();
    if (after.inSeconds != before.inSeconds) {
      _updateSession((s) => s.copyWith(elapsed: after));
      final l10n = ref.read(recordingL10nProvider);
      unawaited(
        ref
            .read(recordingBackgroundProvider)
            .update(text: l10n.recordingNotificationText(formatElapsed(after)))
            .catchError((Object _) {}),
      );
    }
  }

  Duration _elapsed() => Pcm16.durationOf(
    _capturedBytes,
    sampleRate: _config.audio.sampleRate,
    channels: _config.audio.channels,
  );

  void _submit(String meetingId, SpeechSegment segment) {
    final upload = SegmentUpload(
      meetingId: meetingId,
      seq: _nextSeq++,
      startSec: segment.startSec,
      endSec: segment.endSec,
      language: state.session?.language,
    );
    unawaited(
      ref
          .read(segmentUploaderProvider)
          .submit(upload, segment.pcm)
          .catchError((Object e) => debugPrint('Segment ${upload.seq} submit failed: $e')),
    );
  }

  void _onResult(SegmentUploadResult result) {
    final text = result.text.trim();
    if (text.isEmpty) return;
    final line = LiveTranscript(
      seq: result.upload.seq,
      text: text,
      startSec: result.upload.startSec,
      endSec: result.upload.endSec,
    );
    _updateSession((s) {
      final list = [...s.transcripts.where((t) => t.seq != line.seq), line]
        ..sort((a, b) => a.seq.compareTo(b.seq));
      return s.copyWith(transcripts: list);
    });
  }

  Future<void> _refreshPending(String meetingId) async {
    final count = await ref.read(segmentUploaderProvider).pendingCount(meetingId: meetingId);
    if (!ref.mounted || state.session?.meetingId != meetingId) return;
    _updateSession((s) => s.copyWith(pendingUploads: count));
  }

  void _onSourceEvent(AudioSourceEvent event) {
    final current = state;
    switch (event) {
      case AudioSourceInterrupted():
        if (current is RecordingActive) {
          state = RecordingState.paused(session: current.session, interrupted: true);
        }
      case AudioSourceInterruptionEnded():
        if (current is RecordingPaused && current.interrupted) unawaited(resume());
      case AudioSourceStoppedExternally():
        unawaited(stop());
      case AudioSourceFailed(:final error):
        debugPrint('Audio source failed: $error');
        unawaited(stop());
    }
  }

  /// Applies [update] to the session of the current state (any phase that has one).
  void _updateSession(RecordingSession Function(RecordingSession) update) {
    state = switch (state) {
      RecordingActive(:final session) => RecordingState.recording(session: update(session)),
      RecordingPaused(:final session, :final interrupted) => RecordingState.paused(
        session: update(session),
        interrupted: interrupted,
      ),
      RecordingStopping(:final session) => RecordingState.stopping(session: update(session)),
      RecordingError(:final error, :final stage, :final session?) => RecordingState.error(
        error: error,
        stage: stage,
        session: update(session),
      ),
      final other => other,
    };
  }

  /// Stops the source, waits (bounded) for its last frames and releases it.
  Future<void> _stopCapture() async {
    final source = _source;
    try {
      await source?.stop();
    } on Object catch (e) {
      debugPrint('Stopping audio source failed: $e');
    }
    final done = _framesDone;
    if (done != null) {
      await done.future.timeout(_config.recording.stopDrainTimeout, onTimeout: () {});
    }
    await _teardownCapture();
  }

  Future<void> _teardownCapture() async {
    _framesDone = null;
    final source = _source;
    _source = null;
    if (source != null) {
      try {
        await source.stop();
      } on Object catch (_) {}
    }
    final sub = _sourceSub;
    _sourceSub = null;
    if (sub != null) {
      final kind = source?.kind;
      sub.close();
      // Next recording gets a fresh source instance.
      if (kind != null && ref.mounted) ref.invalidate(audioSourceProvider(kind));
    }
    if (ref.mounted) {
      ref.read(recordingStatusControllerProvider.notifier).setIdle();
      unawaited(ref.read(recordingBackgroundProvider).stop().catchError((Object _) {}));
    }
  }

  Future<void> _closeWriter() async {
    final writer = _writer;
    _writer = null;
    if (writer == null) return;
    try {
      await writer.close();
    } on Object catch (e) {
      _writerError ??= e;
      debugPrint('Closing AAC writer failed: $e');
    }
  }

  void _cancelSubs() {
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    _subs.clear();
  }

  Future<void> _deleteFile(String path) async {
    try {
      final file = File(path);
      if (file.existsSync()) await file.delete();
    } on Object catch (e) {
      debugPrint('Deleting $path failed: $e');
    }
  }
}
