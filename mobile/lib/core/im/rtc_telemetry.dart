import 'dart:math' as math;

import 'package:deeprespond_im/deeprespond_im.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../config/app_config.dart';

part 'rtc_telemetry.g.dart';
part 'rtc_telemetry.freezed.dart';

typedef ReadRtcStats = Future<List<RtcStat>> Function(ChannelTrack track);
typedef RtcStat = ({String id, String type, double timestamp, Map<String, dynamic> values});

@Riverpod(keepAlive: true)
ReadRtcStats readRtcStats(Ref ref) => (item) async {
  final track = item.track;
  if (track is! lk.Track) return [];
  final reports = item.local ? await track.sender?.getStats() : await track.receiver?.getStats();
  return [
    for (final report in reports ?? const <rtc.StatsReport>[])
      (
        id: report.id,
        type: report.type,
        timestamp: report.timestamp,
        values: Map<String, dynamic>.from(report.values),
      ),
  ];
};

enum RtcQuality { unknown, good, fair, poor }

@freezed
abstract class NetworkMetrics with _$NetworkMetrics {
  const NetworkMetrics._();
  const factory NetworkMetrics({double? rttMs, double? lossPercent, required DateTime measuredAt}) =
      _NetworkMetrics;
  RtcQuality quality(LiveConfig config, DateTime now) {
    if (now.difference(measuredAt).inMilliseconds >= config.rtcStaleMs ||
        (rttMs == null && lossPercent == null)) {
      return RtcQuality.unknown;
    }
    if ((rttMs ?? 0) > config.rtcPoorRttMs || (lossPercent ?? 0) > config.rtcPoorLossPercent) {
      return RtcQuality.poor;
    }
    if ((rttMs ?? 0) > config.rtcFairRttMs || (lossPercent ?? 0) > config.rtcFairLossPercent) {
      return RtcQuality.fair;
    }
    return RtcQuality.good;
  }
}

@freezed
abstract class RoomMetrics with _$RoomMetrics {
  const factory RoomMetrics({String? speaker, @Default({}) Map<String, NetworkMetrics> network}) =
      _RoomMetrics;
}

typedef _Baseline = ({
  double timestamp,
  double? packets,
  double? lost,
  double energy,
  double duration,
});

/// Each input is from one SDK-authorized track's sender/receiver. Counter deltas
/// are interval loss, not lifetime percentages. Repeated timestamps never refresh
/// stale indicators; resetting or disappearing counters must not invent zero loss.
class RtcSampler {
  RtcSampler(this.config);
  final LiveConfig config;
  final _previous = <String, _Baseline>{};
  final _network = <String, NetworkMetrics>{};
  final _speaking = <String, DateTime>{};

  RoomMetrics sample(Map<ChannelTrack, List<RtcStat>> reports, Set<String> audible, DateTime now) {
    final liveKeys = <String>{}, users = <String>{}, levels = <String, double>{};
    for (final entry in reports.entries) {
      final item = entry.key, stats = entry.value;
      final user = item.username;
      if (user == null) continue;
      users.add(user);
      final byId = {for (final s in stats) s.id: s};
      double? pairRtt;
      for (final s in stats) {
        final v = s.values;
        if (s.type == 'transport' && v['selectedCandidatePairId'] is String) {
          pairRtt = _number(byId[v['selectedCandidatePairId']]?.values['currentRoundTripTime']);
        }
        if (s.type == 'candidate-pair' &&
            v['state'] == 'succeeded' &&
            (v['selected'] == true || v['nominated'] == true)) {
          pairRtt ??= _number(v['currentRoundTripTime']);
        }
      }
      for (final s in stats) {
        if (!['inbound-rtp', 'outbound-rtp', 'media-source'].contains(s.type)) continue;
        final v = s.values;
        if (v['isRemote'] == true) continue;
        if (v['kind'] != null && v['kind'] != item.kind) continue;
        final track = item.track;
        if (track is lk.Track &&
            v['trackIdentifier'] != null &&
            v['trackIdentifier'] != track.mediaStreamTrack.id) {
          continue;
        }
        final outbound = s.type == 'outbound-rtp';
        final remote = outbound ? byId[v['remoteId']] : null;
        final source = outbound ? byId[v['mediaSourceId']] : null;
        final feedback = remote ?? s;
        final key = '${item.sessionId}:${item.kind}:${s.id}';
        liveKeys.add(key);
        final old = _previous[key];
        if (old != null && feedback.timestamp <= old.timestamp) continue;
        final packets = _number(v[outbound ? 'packetsSent' : 'packetsReceived']);
        final lost = _number(outbound ? remote?.values['packetsLost'] : v['packetsLost']);
        final energy = _number(v['totalAudioEnergy'] ?? source?.values['totalAudioEnergy']) ?? 0;
        final duration =
            _number(v['totalSamplesDuration'] ?? source?.values['totalSamplesDuration']) ?? 0;
        double? loss;
        if (old != null &&
            packets != null &&
            lost != null &&
            old.packets != null &&
            old.lost != null) {
          final count = packets - old.packets!, missing = lost - old.lost!;
          final total = count + (outbound ? 0 : missing);
          if (count >= 0 && missing >= 0 && total > 0) loss = (100 * missing / total).clamp(0, 100);
        }
        _previous[key] = (
          timestamp: feedback.timestamp,
          packets: packets,
          lost: lost,
          energy: energy,
          duration: duration,
        );
        final rtt = _number(remote?.values['roundTripTime']) ?? pairRtt;
        if (s.type != 'media-source' && (rtt != null || loss != null)) {
          final existing = _network[user];
          final sameInterval = existing?.measuredAt == now;
          _network[user] = NetworkMetrics(
            rttMs: _max(rtt == null ? null : rtt * 1000, sameInterval ? existing?.rttMs : null),
            lossPercent: _max(loss, sameInterval ? existing?.lossPercent : null),
            measuredAt: now,
          );
        }
        if (item.kind == 'audio' && audible.contains(user)) {
          final rms = old != null && duration > old.duration
              ? math.sqrt(math.max(0, energy - old.energy) / (duration - old.duration))
              : 0.0;
          final level = _number(v['audioLevel'] ?? source?.values['audioLevel']) ?? rms;
          if (level > config.rtcSpeakingLevel) {
            levels[user] = math.max(level, levels[user] ?? 0);
            _speaking[user] = now.add(Duration(milliseconds: config.rtcSpeakingHoldMs));
          }
        }
      }
    }
    _previous.removeWhere((k, _) => !liveKeys.contains(k));
    _network.removeWhere(
      (u, m) =>
          !users.contains(u) || now.difference(m.measuredAt).inMilliseconds >= config.rtcStaleMs,
    );
    _speaking.removeWhere(
      (u, until) => !audible.contains(u) || !users.contains(u) || !until.isAfter(now),
    );
    final sorted = levels.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return RoomMetrics(
      speaker: sorted.firstOrNull?.key ?? _speaking.keys.firstOrNull,
      network: Map.unmodifiable(_network),
    );
  }

  static double? _number(Object? value) {
    final n = value is num ? value.toDouble() : double.tryParse('$value');
    return n != null && n.isFinite && n >= 0 ? n : null;
  }

  static double? _max(double? a, double? b) => a == null
      ? b
      : b == null
      ? a
      : math.max(a, b);
}
