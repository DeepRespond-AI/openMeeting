import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:meeting/core/api/api_exception.dart';
import 'package:meeting/core/api/models/meeting_models.dart';
import 'package:meeting/core/config/app_enums.dart';
import 'package:meeting/features/recording/data/connectivity_monitor.dart';
import 'package:meeting/features/recording/domain/aac_writer.dart';
import 'package:meeting/features/recording/domain/audio_source.dart';
import 'package:meeting/features/recording/domain/recording_background.dart';
import 'package:meeting/features/recording/domain/recording_repository.dart';
import 'package:meeting/features/recording/domain/segment_upload.dart';

// ignore_for_file: close_sinks

class FakeAudioSource implements AudioSource {
  FakeAudioSource({this.kind = RecordingSource.microphone});

  @override
  final RecordingSource kind;

  AudioSourceAvailability availabilityResult = AudioSourceAvailability.available;
  AudioSourceException? startError;
  AudioCaptureOptions? startedWith;
  final List<String> calls = [];

  StreamController<Uint8List> _frames = StreamController<Uint8List>();
  final StreamController<double> _level = StreamController<double>.broadcast();
  final StreamController<AudioSourceEvent> _events = StreamController<AudioSourceEvent>.broadcast();

  void emitFrame(Uint8List pcm) => _frames.add(pcm);
  void emitLevel(double level) => _level.add(level);
  void emitEvent(AudioSourceEvent event) => _events.add(event);

  @override
  Future<AudioSourceAvailability> availability() async => availabilityResult;

  @override
  Future<void> start(AudioCaptureOptions options) async {
    calls.add('start');
    if (startError case final e?) throw e;
    startedWith = options;
    if (_frames.isClosed) _frames = StreamController<Uint8List>();
  }

  @override
  Future<void> pause() async => calls.add('pause');

  @override
  Future<void> resume() async => calls.add('resume');

  @override
  Future<void> stop() async {
    calls.add('stop');
    if (!_frames.isClosed) unawaited(_frames.close());
  }

  @override
  Stream<Uint8List> get frames => _frames.stream;

  @override
  Stream<double> get level => _level.stream;

  @override
  Stream<AudioSourceEvent> get events => _events.stream;
}

/// Writes the raw PCM to the file on close (so the "m4a" exists and has content).
class FakeAacWriter implements AacWriter {
  String? path;
  Map<String, int>? params;
  final BytesBuilder written = BytesBuilder();
  int closeCount = 0;

  @override
  Future<void> open({
    required String path,
    required int sampleRate,
    required int channels,
    required int bitrate,
  }) async {
    this.path = path;
    params = {'sampleRate': sampleRate, 'channels': channels, 'bitrate': bitrate};
  }

  @override
  Future<void> write(Uint8List pcm16) async => written.add(pcm16);

  @override
  Future<void> close() async {
    closeCount++;
    final p = path;
    if (p != null && closeCount == 1) File(p).writeAsBytesSync(written.toBytes());
  }
}

class FakeRecordingRepository implements RecordingRepository {
  final List<String> calls = [];
  final List<SegmentUpload> segments = [];
  String? renamedTo;
  Object? createError;

  /// Number of upcoming audio uploads that fail (with a non-retryable error).
  int failAudioUploads = 0;

  @override
  Future<MeetingMetadata> createMeeting(String title) async {
    calls.add('create:$title');
    if (createError case final e?) throw e;
    return MeetingMetadata(id: 'm1', title: title);
  }

  @override
  Future<SegmentResult> uploadSegment(SegmentUpload upload, Uint8List pcm) async {
    segments.add(upload);
    return SegmentResult(id: 't${upload.seq}', text: 'line ${upload.seq}', seq: upload.seq);
  }

  @override
  Future<AudioUploadResult> uploadAudio(
    String meetingId,
    File file, {
    double? duration,
    UploadProgress? onProgress,
  }) async {
    calls.add('audio:$meetingId');
    if (failAudioUploads > 0) {
      failAudioUploads--;
      throw const ApiException(kind: ApiErrorKind.badRequest, statusCode: 400);
    }
    final size = file.lengthSync();
    onProgress?.call(size ~/ 2, size);
    onProgress?.call(size, size);
    return AudioUploadResult(size: size);
  }

  @override
  Future<void> renameMeeting(String meetingId, String title) async {
    calls.add('rename:$meetingId');
    renamedTo = title;
  }

  @override
  Future<void> deleteMeeting(String meetingId) async => calls.add('delete:$meetingId');
}

class FakeBackground implements RecordingBackground {
  final List<String> calls = [];
  final StreamController<void> stops = StreamController<void>.broadcast();

  @override
  Future<void> start({
    required String channelName,
    required String title,
    required String text,
    required String stopLabel,
  }) async => calls.add('start');

  @override
  Future<void> update({required String text}) async => calls.add('update:$text');

  @override
  Future<void> stop() async => calls.add('stop');

  @override
  Stream<void> get stopRequests => stops.stream;
}

class FakeConnectivity implements ConnectivityMonitor {
  final StreamController<bool> controller = StreamController<bool>.broadcast();

  @override
  Stream<bool> get onlineChanges => controller.stream;
}
