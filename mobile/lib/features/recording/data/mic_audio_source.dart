import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

import '../../../core/config/app_enums.dart';
import '../domain/audio_source.dart';
import '../domain/pcm.dart';

/// Microphone capture via the `record` plugin: PCM16 stream at the configured sample rate and
/// channel count. On iOS `record` configures the AVAudioSession (`playAndRecord`), which with
/// the `audio` background mode keeps capturing in the background.
///
/// Interruptions (phone call, another app taking the microphone) make `record` pause
/// ([AudioInterruptionMode.pause]); they are reported as [AudioSourceInterrupted]. A stop the
/// app did not request is reported as [AudioSourceStoppedExternally].
///
/// Streams are per capture session: subscribe after [start] returns; [frames] completes
/// after [stop].
class MicAudioSource implements AudioSource {
  MicAudioSource({
    required this._levelFloorDb,
    required this._levelInterval,
    AudioRecorder Function()? recorderFactory,
  }) : _recorderFactory = recorderFactory ?? AudioRecorder.new;

  final double _levelFloorDb;
  final Duration _levelInterval;
  final AudioRecorder Function() _recorderFactory;

  AudioRecorder? _recorder;
  StreamController<Uint8List>? _frames;
  StreamController<double>? _level;
  StreamController<AudioSourceEvent>? _events;
  final List<StreamSubscription<Object?>> _subs = [];
  bool _pausedByApp = false;
  bool _stopping = false;

  @override
  RecordingSource get kind => RecordingSource.microphone;

  @override
  Future<AudioSourceAvailability> availability() async {
    final recorder = _recorderFactory();
    try {
      final granted = await recorder.hasPermission(request: false);
      return granted ? AudioSourceAvailability.available : AudioSourceAvailability.needsPermission;
    } on Object catch (e) {
      debugPrint('MicAudioSource.availability: $e');
      return AudioSourceAvailability.needsPermission;
    } finally {
      unawaited(recorder.dispose());
    }
  }

  @override
  Future<void> start(AudioCaptureOptions options) async {
    await stop();
    final recorder = _recorder = _recorderFactory();
    final bool granted;
    try {
      granted = await recorder.hasPermission();
    } on Object catch (e) {
      throw AudioSourceException(AudioSourceErrorCode.platform, '$e');
    }
    if (!granted) throw const AudioSourceException(AudioSourceErrorCode.permissionDenied);

    _frames = StreamController<Uint8List>();
    _level = StreamController<double>.broadcast();
    _events = StreamController<AudioSourceEvent>.broadcast();
    _pausedByApp = false;
    _stopping = false;

    final Stream<Uint8List> stream;
    try {
      stream = await recorder.startStream(
        RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: options.sampleRate,
          numChannels: options.channels,
          audioInterruption: AudioInterruptionMode.pause,
        ),
      );
    } on Object catch (e) {
      await stop();
      throw AudioSourceException(AudioSourceErrorCode.busy, '$e');
    }

    _subs
      ..add(
        stream.listen(
          (chunk) => _frames?.add(chunk),
          onError: (Object e) => _events?.add(
            AudioSourceFailed(AudioSourceException(AudioSourceErrorCode.platform, '$e')),
          ),
        ),
      )
      ..add(
        recorder
            .onAmplitudeChanged(_levelInterval)
            .listen(
              (a) => _level?.add(Pcm16.levelFromDb(a.current, floorDb: _levelFloorDb)),
              onError: (Object _) {},
            ),
      )
      ..add(recorder.onStateChanged().listen(_onState, onError: (Object _) {}));
  }

  void _onState(RecordState state) {
    switch (state) {
      case RecordState.pause when !_pausedByApp:
        _events?.add(const AudioSourceInterrupted());
      case RecordState.record when !_pausedByApp:
        _events?.add(const AudioSourceInterruptionEnded());
      case RecordState.stop when !_stopping:
        _events?.add(const AudioSourceStoppedExternally());
      default:
        break;
    }
  }

  @override
  Future<void> pause() async {
    _pausedByApp = true;
    await _recorder?.pause();
  }

  @override
  Future<void> resume() async {
    _pausedByApp = false;
    await _recorder?.resume();
  }

  @override
  Future<void> stop() async {
    final recorder = _recorder;
    if (recorder == null) return;
    _stopping = true;
    _recorder = null;
    try {
      await recorder.stop();
    } on Object catch (e) {
      debugPrint('MicAudioSource.stop: $e');
    }
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    await recorder.dispose();
    // Not awaited: a close() only completes once a listener received the done event.
    unawaited(_frames?.close());
    unawaited(_level?.close());
    unawaited(_events?.close());
  }

  @override
  Stream<Uint8List> get frames => _frames?.stream ?? const Stream.empty();

  @override
  Stream<double> get level => _level?.stream ?? const Stream.empty();

  @override
  Stream<AudioSourceEvent> get events => _events?.stream ?? const Stream.empty();
}
