import 'package:deeprespond_im/deeprespond_im.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meeting/core/im/rtc_telemetry.dart';

import '../../helpers/test_config.dart';

const audio = ChannelTrack(
  sessionId: 'session',
  username: 'peer-id',
  kind: 'audio',
  track: 'authorized-track-fixture',
  local: false,
);
RtcStat inbound(double time, int received, int lost, {double level = 0}) => (
  id: 'inbound',
  type: 'inbound-rtp',
  timestamp: time,
  values: {'kind': 'audio', 'packetsReceived': received, 'packetsLost': lost, 'audioLevel': level},
);
const pair = (
  id: 'pair',
  type: 'candidate-pair',
  timestamp: 1.0,
  values: <String, dynamic>{'state': 'succeeded', 'nominated': true, 'currentRoundTripTime': .35},
);

void main() {
  final config = loadConfigFile('dev').live;
  final now = DateTime.utc(2026, 10, 27);
  test('interval loss, actual RTT and speaker thresholds use real stats', () {
    final sampler = RtcSampler(config);
    final first = sampler.sample(
      {
        audio: [inbound(1, 100, 10, level: .1), pair],
      },
      {'peer-id'},
      now,
    );
    expect(first.speaker, 'peer-id');
    expect(first.network['peer-id']!.rttMs, 350);
    expect(first.network['peer-id']!.lossPercent, isNull);
    final second = sampler.sample(
      {
        audio: [inbound(2, 190, 20), pair],
      },
      {'peer-id'},
      now.add(const Duration(milliseconds: 500)),
    );
    expect(second.network['peer-id']!.lossPercent, 10);
    expect(second.network['peer-id']!.quality(config, now), RtcQuality.poor);
    expect(second.speaker, 'peer-id');
  });
  test('repeated samples expire instead of claiming a healthy link forever', () {
    final sampler = RtcSampler(config),
        reports = {
          audio: [inbound(1, 100, 0, level: .2), pair],
        };
    sampler.sample(reports, {'peer-id'}, now);
    final stale = sampler.sample(reports, {
      'peer-id',
    }, now.add(Duration(milliseconds: config.rtcStaleMs + 1)));
    expect(stale.speaker, isNull);
    expect(stale.network, isEmpty);
  });
  test('reset counters, missing stats and muted/removed users never invent activity', () {
    final sampler = RtcSampler(config);
    sampler.sample(
      {
        audio: [inbound(1, 100, 10)],
      },
      {'peer-id'},
      now,
    );
    final reset = sampler.sample(
      {
        audio: [inbound(2, 1, 0, level: .8)],
      },
      {},
      now.add(const Duration(seconds: 1)),
    );
    expect(reset.network, isEmpty);
    expect(reset.speaker, isNull);
    expect(sampler.sample({}, {'peer-id'}, now).network, isEmpty);
  });
  test('outbound loss uses RTCP feedback timestamps rather than sender ticks', () {
    final sampler = RtcSampler(config);
    const local = ChannelTrack(
      sessionId: 'local',
      username: 'self',
      kind: 'audio',
      track: 'fixture',
      local: true,
    );
    List<RtcStat> stats(double timestamp, double remoteTime, int sent, int lost) => [
      (
        id: 'out',
        type: 'outbound-rtp',
        timestamp: timestamp,
        values: {'packetsSent': sent, 'remoteId': 'remote', 'kind': 'audio'},
      ),
      (
        id: 'remote',
        type: 'remote-inbound-rtp',
        timestamp: remoteTime,
        values: {'packetsLost': lost, 'roundTripTime': .1},
      ),
    ];
    sampler.sample({local: stats(1, 1, 100, 0)}, {}, now);
    final next = sampler.sample(
      {local: stats(2, 2, 200, 5)},
      {},
      now.add(const Duration(seconds: 1)),
    );
    expect(next.network['self']!.lossPercent, 5);
    final duplicate = sampler.sample(
      {local: stats(3, 2, 300, 5)},
      {},
      now.add(const Duration(seconds: 7)),
    );
    expect(duplicate.network, isEmpty);
  });
}
