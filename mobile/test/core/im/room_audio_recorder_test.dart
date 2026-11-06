import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:deeprespond_im/deeprespond_im.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meeting/core/im/room_audio_recorder.dart';

class Frames implements RoomAudioSource {
  final callbacks = <Object, void Function(Uint8List)>{};
  final detached = <Object>[];
  @override
  DetachAudio attach(Object track, void Function(Uint8List) onData) {
    callbacks[track] = onData;
    return () async {
      detached.add(track);
      callbacks.remove(track);
    };
  }

  void emit(Object track, List<int> bytes) => callbacks[track]?.call(Uint8List.fromList(bytes));
}

ChannelTrack audio(Object track, String user) => ChannelTrack(
  sessionId: user,
  username: user,
  kind: 'audio',
  track: track,
  local: user == 'host',
);

void main() {
  late Frames source;
  late List<Map<String, Object?>> uploads;
  late List<String> errors;
  RoomAudioRecorder make({
    Future<void> Function(Map<String, Object?>)? upload,
    int maxPending = 120,
  }) => RoomAudioRecorder(
    epoch: 3,
    startedAt: DateTime.utc(2026),
    source: source,
    upload:
        upload ??
        (chunk) async {
          uploads.add(chunk);
        },
    report: (_, error) {
      if (error != null) errors.add(error);
    },
    chunkMs: 5000,
    maxPending: maxPending,
    frameTimeout: const Duration(seconds: 10),
    retryDelay: const Duration(hours: 1),
    now: () => DateTime.utc(2026).add(const Duration(seconds: 10)),
  );
  setUp(() {
    source = Frames();
    uploads = [];
    errors = [];
  });

  test('independent authorized tracks retain identity and final partial bytes', () async {
    final recorder = make(), a = Object(), b = Object(), stranger = Object();
    recorder.sync(
      [audio(a, 'host'), audio(b, 'member'), audio(stranger, 'stranger')],
      {'host': 'p-host', 'member': 'p-member'},
    );
    expect(source.callbacks.containsKey(stranger), false);
    source.emit(a, [1, 0, 2, 0]);
    source.emit(b, [3, 0]);
    await recorder.finish();
    expect(uploads.map((c) => c['participantId']), ['p-host', 'p-member']);
    expect(base64Decode(uploads.first['pcm']! as String), [1, 0, 2, 0]);
    expect(uploads.every((c) => c['epoch'] == 3), true);
    expect(source.detached, containsAll([a, b]));
    await recorder.dispose();
  });
  test('large callback is split into server-safe five second chunks', () async {
    final recorder = make(), track = Object();
    recorder.sync([audio(track, 'host')], {'host': 'p'});
    source.emit(track, List.filled(160004, 0));
    await recorder.finish();
    expect(uploads.map((c) => base64Decode(c['pcm']! as String).length), [160000, 4]);
    await recorder.dispose();
  });
  test('failed final upload blocks completion and retries the exact same chunk', () async {
    final attempts = <Map<String, Object?>>[];
    var fail = true;
    final recorder = make(
      upload: (chunk) async {
        attempts.add(Map.of(chunk));
        if (fail) throw StateError('503');
      },
    );
    final track = Object();
    recorder.sync([audio(track, 'host')], {'host': 'p'});
    source.emit(track, [4, 0]);
    await expectLater(recorder.finish(), throwsStateError);
    expect(recorder.pendingCount, 1);
    fail = false;
    await recorder.finish();
    expect(attempts.length, greaterThanOrEqualTo(2));
    for (final attempt in attempts.skip(1)) {
      expect(attempt, attempts.first);
    }
    expect(recorder.pendingCount, 0);
    await recorder.dispose();
  });
  test('muted/removed track flushes once and later native callbacks are ignored', () async {
    final recorder = make(), track = Object();
    recorder.sync([audio(track, 'host')], {'host': 'p'});
    final callback = source.callbacks[track]!;
    callback(Uint8List.fromList([1, 0]));
    recorder.sync([audio(track, 'host')], {});
    callback(Uint8List.fromList([2, 0]));
    await recorder.finish();
    expect(uploads.length, 1);
    expect(base64Decode(uploads.single['pcm']! as String), [1, 0]);
    await recorder.dispose();
  });
  test('queue pressure detaches capture and resumes only after pending upload succeeds', () async {
    final gate = Completer<void>();
    final recorder = make(maxPending: 1, upload: (_) => gate.future);
    final track = Object();
    recorder.sync([audio(track, 'host')], {'host': 'p'});
    source.emit(track, List.filled(160000, 0));
    await Future<void>.delayed(Duration.zero);
    expect(errors, contains('recording_backlog'));
    expect(source.detached, contains(track));
    gate.complete();
    await recorder.retry();
    expect(source.callbacks.containsKey(track), true);
    await recorder.dispose();
  });
  test('no-frame native renderer is reported as error rather than recording success', () {
    fakeAsync((async) {
      final recorder = make(), track = Object();
      recorder.sync([audio(track, 'host')], {'host': 'p'});
      async.elapse(const Duration(seconds: 10));
      expect(errors, contains('audio_frames_unavailable'));
      unawaited(recorder.dispose());
      async.flushMicrotasks();
    });
  });
  test('late frames after disposal do not enqueue or publish new data', () async {
    final recorder = make(), track = Object();
    recorder.sync([audio(track, 'host')], {'host': 'p'});
    final callback = source.callbacks[track]!;
    await recorder.dispose();
    callback(Uint8List.fromList([1, 0]));
    expect(uploads, isEmpty);
    expect(source.callbacks, isEmpty);
  });
}
