// Debug harness for the system_audio_capture plugin (not part of the app).
//
// Start → plays nothing itself; play audio in another app (or the emulator), then Stop.
// The captured PCM is written as a WAV file whose path is shown on screen, e.g. on Android:
//   adb exec-out run-as cn.deeprespond.system_audio_capture_example cat cache/capture.wav > capture.wav
// The values below mirror assets/config/app_config.dev.json of the app.
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:system_audio_capture/system_audio_capture.dart';

void main() => runApp(const MaterialApp(home: HarnessPage()));

const _sampleRate = 16000;

SystemAudioStartOptions _options({required bool mic}) => SystemAudioStartOptions(
  sampleRate: _sampleRate,
  includeMicrophone: mic,
  micGain: 1.0,
  duckingRatio: 0.6,
  frameMs: 20,
  jitterBufferMs: 120,
  maxBufferMs: 1000,
  micActiveRmsThreshold: 0.01,
  duckingAttackMs: 50,
  duckingReleaseMs: 400,
  softClipKnee: 0.8,
  levelIntervalMs: 100,
  levelFloorDb: -60,
  androidCaptureUsages: const ['media', 'game', 'unknown'],
  androidMicSource: 'voiceRecognition',
  androidFallbackCaptureSampleRate: 48000,
  androidNotificationChannelId: 'system_audio_capture',
  androidNotificationId: 7301,
  iosChunkMs: 200,
  iosStartTimeoutMs: 60000,
  iosStopTimeoutMs: 3000,
  iosPollIntervalMs: 250,
  iosMaxPendingChunks: 600,
  iosKeepAliveInBackground: true,
  texts: const SystemAudioTexts(
    notificationChannelName: 'Harness',
    notificationTitle: 'Harness capturing',
    notificationText: 'system audio harness',
    broadcastStoppedByApp: 'Stopped by harness',
    broadcastNotStartedFromApp: 'Start from the harness',
  ),
);

class HarnessPage extends StatefulWidget {
  const HarnessPage({super.key});

  @override
  State<HarnessPage> createState() => _HarnessPageState();
}

class _HarnessPageState extends State<HarnessPage> {
  final _capture = SystemAudioCapture();
  final _pcm = BytesBuilder(copy: false);
  final _log = <String>[];
  final _subs = <StreamSubscription<Object?>>[];
  double _level = 0;
  String _status = 'idle';
  DateTime? _startedAt;

  @override
  void initState() {
    super.initState();
    _subs
      ..add(_capture.pcm.listen(_pcm.add))
      ..add(_capture.level.listen((l) => setState(() => _level = l)))
      ..add(_capture.events.listen((e) => _add('event: $e')));
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _capture.dispose();
    super.dispose();
  }

  void _add(String line) {
    debugPrint('[harness] $line');
    setState(() => _log.insert(0, line));
  }

  Future<void> _availability() async => _add('availability: ${await _capture.availability()}');

  Future<void> _start(bool mic) async {
    _pcm.clear();
    setState(() => _status = 'starting');
    try {
      await _capture.start(_options(mic: mic));
      _startedAt = DateTime.now();
      setState(() => _status = 'capturing');
      _add('started (mic=$mic)');
    } on SystemAudioCaptureException catch (e) {
      setState(() => _status = 'idle');
      _add('start failed: $e');
    }
  }

  Future<void> _stop() async {
    await _capture.stop();
    final bytes = _pcm.takeBytes();
    final elapsed = _startedAt == null ? Duration.zero : DateTime.now().difference(_startedAt!);
    final file = File('${Directory.systemTemp.path}/capture.wav');
    await file.writeAsBytes([..._wavHeader(bytes.length), ...bytes]);
    final seconds = bytes.length / 2 / _sampleRate;
    setState(() => _status = 'idle');
    _add(
      'stopped: ${seconds.toStringAsFixed(2)} s audio in ${elapsed.inMilliseconds / 1000} s, '
      'peak ${_peak(bytes)} → ${file.path}',
    );
  }

  static int _peak(Uint8List bytes) {
    final d = ByteData.sublistView(bytes);
    var peak = 0;
    for (var i = 0; i + 1 < bytes.length; i += 2) {
      final v = d.getInt16(i, Endian.little).abs();
      if (v > peak) peak = v;
    }
    return peak;
  }

  static Uint8List _wavHeader(int dataLength) {
    final h = ByteData(44);
    void str(int o, String s) {
      for (var i = 0; i < s.length; i++) {
        h.setUint8(o + i, s.codeUnitAt(i));
      }
    }

    str(0, 'RIFF');
    h.setUint32(4, 36 + dataLength, Endian.little);
    str(8, 'WAVE');
    str(12, 'fmt ');
    h.setUint32(16, 16, Endian.little);
    h.setUint16(20, 1, Endian.little);
    h.setUint16(22, 1, Endian.little);
    h.setUint32(24, _sampleRate, Endian.little);
    h.setUint32(28, _sampleRate * 2, Endian.little);
    h.setUint16(32, 2, Endian.little);
    h.setUint16(34, 16, Endian.little);
    str(36, 'data');
    h.setUint32(40, dataLength, Endian.little);
    return h.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('system_audio_capture harness')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('status: $_status'),
          LinearProgressIndicator(value: _level),
          Wrap(
            spacing: 8,
            children: [
              ElevatedButton(onPressed: _availability, child: const Text('Availability')),
              ElevatedButton(onPressed: () => _start(false), child: const Text('Start system')),
              ElevatedButton(onPressed: () => _start(true), child: const Text('Start system+mic')),
              ElevatedButton(onPressed: _stop, child: const Text('Stop')),
              ElevatedButton(
                onPressed: () => const MethodChannel(
                  'harness/tone',
                ).invokeMethod<void>('play', {'hz': 440, 'seconds': 3}),
                child: const Text('Play tone'),
              ),
            ],
          ),
          Expanded(child: ListView(children: [for (final l in _log) Text(l)])),
        ],
      ),
    ),
  );
}
