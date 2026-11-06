import 'dart:math' as math;
import 'dart:typed_data';

import '../../../core/config/app_config.dart';
import 'pcm.dart';

/// A chunk of speech cut by [EnergyVad], ready for `POST /meetings/{id}/segments`.
class SpeechSegment {
  const SpeechSegment({required this.pcm, required this.startSec, required this.endSec});

  /// Mono PCM16 little-endian audio of `[startSec, endSec)`.
  final Uint8List pcm;

  /// Position on the recording timeline (seconds of captured audio, pauses excluded).
  final double startSec;
  final double endSec;

  double get durationSec => endSec - startSec;

  @override
  String toString() =>
      'SpeechSegment(${startSec.toStringAsFixed(3)}–${endSec.toStringAsFixed(3)}, ${pcm.length} B)';
}

/// Streaming port of the server's `_energy_vad` (`server/app/stt/audio.py`).
///
/// - Audio is cut into frames of `vad.frameMs`; a frame's energy is
///   `10·log10(mean(x²) + 1e-10)` dBFS.
/// - Noise floor = `vad.noiseFloorPercentile`-th percentile of the last
///   `vad.noiseFloorWindowSec` of frames (the server uses the whole file);
///   threshold = `max(floor + vad.thresholdDbAboveNoise, vad.minThresholdDb)`.
/// - A segment ends after more than `vad.silenceToEndMs` of non-speech frames, is padded by
///   `vad.paddingMs` on both sides and dropped when it has less than `vad.minSpeechMs` of speech.
/// - When a segment reaches `vad.maxSegmentSec` it is split at the quietest frame within the
///   last `vad.splitSearchWindowSec`; the remainder continues as the next segment.
///
/// Input must be mono PCM16 LE at [sampleRate]. Feed audio with [add]; call [flush] at the end.
class EnergyVad {
  EnergyVad({required VadConfig config, required this.sampleRate})
    : _frame = math.max(1, sampleRate * config.frameMs ~/ 1000),
      _pad = sampleRate * config.paddingMs ~/ 1000,
      _minGapFrames = config.silenceToEndMs ~/ config.frameMs,
      _minSpeechFrames = config.minSpeechMs ~/ config.frameMs,
      _maxSegmentSamples = (config.maxSegmentSec * sampleRate).round(),
      _splitWindowFrames = math.max(
        1,
        (config.splitSearchWindowSec * 1000 / config.frameMs).round(),
      ),
      _noiseWindow = List<double>.filled(
        math.max(1, (config.noiseFloorWindowSec * 1000 / config.frameMs).round()),
        0,
      ),
      _percentile = config.noiseFloorPercentile.toDouble(),
      _thresholdAboveNoise = config.thresholdDbAboveNoise,
      _minThresholdDb = config.minThresholdDb;

  final int sampleRate;

  final int _frame;
  final int _pad;
  final int _minGapFrames;
  final int _minSpeechFrames;
  final int _maxSegmentSamples;
  final int _splitWindowFrames;
  final double _percentile;
  final double _thresholdAboveNoise;
  final double _minThresholdDb;

  // Rolling noise window (ring buffer of frame energies).
  final List<double> _noiseWindow;
  int _noiseCount = 0;
  int _noiseNext = 0;

  // Retained samples: _buf[0] is global sample index _bufStart.
  Int16List _buf = Int16List(0);
  int _bufStart = 0;
  int _bufLen = 0;
  int? _carryByte;

  int _framesProcessed = 0;
  int _lastEmittedEnd = 0;

  // Open segment state.
  bool _inSpeech = false;
  bool _continued = false;
  int _segStart = 0;
  int _speechStartFrame = 0;
  int _endFrame = 0;
  int _silence = 0;
  final List<double> _segDb = [];
  int _segDbBase = 0;

  int get _totalSamples => _bufStart + _bufLen;

  /// Samples received so far (the recording timeline position).
  int get samplesReceived => _totalSamples;

  /// Feeds PCM16 LE bytes; returns the segments completed by this chunk (usually none).
  List<SpeechSegment> add(Uint8List bytes) {
    if (bytes.isEmpty) return const [];
    var data = bytes;
    if (_carryByte case final carry?) {
      data = Uint8List(bytes.length + 1)
        ..[0] = carry
        ..setRange(1, bytes.length + 1, bytes);
      _carryByte = null;
    }
    if (data.length.isOdd) {
      _carryByte = data.last;
      data = Uint8List.sublistView(data, 0, data.length - 1);
    }
    _append(Pcm16.decode(data));

    final out = <SpeechSegment>[];
    while ((_framesProcessed + 1) * _frame <= _totalSamples) {
      _processFrame(_framesProcessed, out);
      _framesProcessed++;
    }
    _trim();
    return out;
  }

  /// Ends the stream: closes an open segment (if long enough) and returns it.
  List<SpeechSegment> flush() {
    final out = <SpeechSegment>[];
    if (_inSpeech) {
      if (_continued || _endFrame - _speechStartFrame >= _minSpeechFrames) {
        _emit(_segStart, _endFrame * _frame + _pad, out);
      }
      _inSpeech = false;
    }
    _segDb.clear();
    return out;
  }

  void _processFrame(int index, List<SpeechSegment> out) {
    final frameStart = index * _frame;
    final db = Pcm16.energyDb(_buf, frameStart - _bufStart, frameStart - _bufStart + _frame);
    _pushNoise(db);
    final threshold = math.max(_noiseFloor() + _thresholdAboveNoise, _minThresholdDb);
    final speech = db > threshold;

    if (!_inSpeech) {
      if (!speech) return;
      _inSpeech = true;
      _continued = false;
      _speechStartFrame = index;
      _endFrame = index + 1;
      _silence = 0;
      _segStart = math.max(_lastEmittedEnd, math.max(0, frameStart - _pad));
      _segDb
        ..clear()
        ..add(db);
      _segDbBase = index;
    } else {
      _segDb.add(db);
      if (speech) {
        _silence = 0;
        _endFrame = index + 1;
      } else {
        _silence++;
        if (_silence > _minGapFrames) {
          if (_continued || _endFrame - _speechStartFrame >= _minSpeechFrames) {
            _emit(_segStart, _endFrame * _frame + _pad, out);
          }
          _inSpeech = false;
          _segDb.clear();
          return;
        }
      }
    }

    // Too long: split at the quietest frame of the recent search window.
    final processedEnd = (index + 1) * _frame;
    if (processedEnd - _segStart >= _maxSegmentSamples) _split(index, out);
  }

  void _split(int currentFrame, List<SpeechSegment> out) {
    final firstCandidate = math.max(
      math.max(_segDbBase, currentFrame - _splitWindowFrames + 1),
      // The cut must leave a non-empty segment.
      (_segStart ~/ _frame) + 1,
    );
    var best = currentFrame;
    var bestDb = double.infinity;
    for (var f = firstCandidate; f <= currentFrame; f++) {
      final db = _segDb[f - _segDbBase];
      if (db < bestDb) {
        bestDb = db;
        best = f;
      }
    }
    final cut = math.min(best * _frame + _frame ~/ 2, (currentFrame + 1) * _frame);
    _emit(_segStart, cut, out);

    if (cut >= _endFrame * _frame) {
      // Only silence after the cut: the utterance is over.
      _inSpeech = false;
      _segDb.clear();
      return;
    }
    _continued = true;
    _segStart = cut;
    _speechStartFrame = best + 1;
    final keepFrom = best + 1 - _segDbBase;
    _segDb.removeRange(0, math.min(keepFrom, _segDb.length));
    _segDbBase = best + 1;
  }

  void _emit(int start, int end, List<SpeechSegment> out) {
    final s = math.max(start, _lastEmittedEnd);
    final e = math.min(end, _totalSamples);
    if (e <= s) return;
    out.add(
      SpeechSegment(
        pcm: Pcm16.encode(_buf, s - _bufStart, e - _bufStart),
        startSec: s / sampleRate,
        endSec: e / sampleRate,
      ),
    );
    _lastEmittedEnd = e;
  }

  void _pushNoise(double db) {
    _noiseWindow[_noiseNext] = db;
    _noiseNext = (_noiseNext + 1) % _noiseWindow.length;
    if (_noiseCount < _noiseWindow.length) _noiseCount++;
  }

  /// Linear-interpolated percentile (numpy's default) of the noise window.
  double _noiseFloor() {
    final values = _noiseWindow.sublist(0, _noiseCount)..sort();
    final rank = _percentile / 100 * (values.length - 1);
    final lo = rank.floor();
    final hi = rank.ceil();
    return values[lo] + (values[hi] - values[lo]) * (rank - lo);
  }

  void _append(Int16List samples) {
    final needed = _bufLen + samples.length;
    if (needed > _buf.length) {
      final grown = Int16List(math.max(needed, _buf.length * 2));
      grown.setRange(0, _bufLen, _buf);
      _buf = grown;
    }
    _buf.setRange(_bufLen, needed, samples);
    _bufLen = needed;
  }

  /// Drops samples no future segment can reach.
  void _trim() {
    final processed = _framesProcessed * _frame;
    final keepFrom = _inSpeech ? _segStart : math.max(0, processed - _pad);
    final drop = keepFrom - _bufStart;
    if (drop <= 0 || drop < _buf.length ~/ 2) return;
    _buf.setRange(0, _bufLen - drop, _buf, drop);
    _bufLen -= drop;
    _bufStart = keepFrom;
  }
}
