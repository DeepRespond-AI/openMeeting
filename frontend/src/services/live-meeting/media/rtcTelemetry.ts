import type { MediaTrack, NetworkSample } from './types';

/**
 * The alpha IM channel API exposes tracks but no getStats handle. Observe native
 * peer creation while the channel is alive, preserving its constructor/prototype.
 * Only peers containing the channel's actual track objects are ever sampled.
 * Remove this compatibility bridge when ChannelHandle exposes standard stats.
 */
export class RtcTelemetry {
  private peers = new Set<RTCPeerConnection>();
  private peerIds = new WeakMap<RTCPeerConnection, number>();
  private nextPeerId = 0;
  private native: typeof RTCPeerConnection | null = null;
  private wrapper: typeof RTCPeerConnection | null = null;
  private previous = new Map<
    string,
    {
      received: number | undefined;
      lost: number | undefined;
      energy: number;
      duration: number;
      feedbackAt?: number;
      lossPercent?: number;
      lossAt?: number;
    }
  >();
  private timer: ReturnType<typeof setInterval> | null = null;
  private busy = false;
  private epoch = 0;
  private speakingUntil = new Map<string, number>();
  start(
    tracks: () => MediaTrack[],
    emit: (
      active: string | null,
      network: Record<string, NetworkSample>,
    ) => void,
  ) {
    this.stop();
    if (
      typeof window === 'undefined' ||
      typeof window.RTCPeerConnection !== 'function'
    )
      return;
    const epoch = this.epoch;
    this.native = window.RTCPeerConnection;
    const peers = this.peers;
    this.wrapper = new Proxy(this.native, {
      construct(target, args, newTarget) {
        const pc = Reflect.construct(
          target,
          args,
          newTarget,
        ) as RTCPeerConnection;
        peers.add(pc);
        return pc;
      },
    });
    try {
      window.RTCPeerConnection = this.wrapper;
    } catch {
      // Metrics are optional; a locked-down WebView must still join the channel.
      this.native = null;
      this.wrapper = null;
      return;
    }
    this.timer = setInterval(() => {
      if (this.busy) return;
      this.busy = true;
      void this.sample(tracks())
        .then(({ active, network }) => {
          if (epoch === this.epoch) emit(active, network);
        })
        .catch(() => {})
        .finally(() => {
          this.busy = false;
        });
    }, 500);
  }
  private async sample(tracks: MediaTrack[]) {
    const epoch = this.epoch;
    const now = Date.now(),
      network: Record<string, NetworkSample> = {},
      levels = new Map<string, number>();
    const trackMap = new Map(
      tracks.filter((t) => t.source !== 'screen').map((t) => [t.track.id, t]),
    );
    for (const pc of this.peers) {
      if (pc.connectionState === 'closed') {
        this.peers.delete(pc);
        continue;
      }
      if (!this.peerIds.has(pc)) this.peerIds.set(pc, ++this.nextPeerId);
      const peerIndex = this.peerIds.get(pc)!;
      if (
        ![...pc.getSenders(), ...pc.getReceivers()].some(
          (r) => r.track && trackMap.has(r.track.id),
        )
      )
        continue;
      let report: RTCStatsReport;
      try {
        report = await pc.getStats();
      } catch {
        continue;
      }
      if (epoch !== this.epoch) return { active: null, network: {} };
      let rtt: number | undefined;
      report.forEach((s) => {
        if (s.type === 'transport' && s.selectedCandidatePairId) {
          const pair = report.get(s.selectedCandidatePairId);
          if (typeof pair?.currentRoundTripTime === 'number')
            rtt = pair.currentRoundTripTime * 1000;
        }
      });
      report.forEach((s) => {
        if (
          s.type !== 'inbound-rtp' &&
          s.type !== 'outbound-rtp' &&
          s.type !== 'media-source'
        )
          return;
        const source = s.mediaSourceId ? report.get(s.mediaSourceId) : null;
        const identifier = s.trackIdentifier ?? source?.trackIdentifier;
        const item =
          typeof identifier === 'string' ? trackMap.get(identifier) : undefined;
        if (!item || !item.username) return;
        const user = item.username,
          key = `${peerIndex}:${s.id}`;
        const remote = s.remoteId ? report.get(s.remoteId) : null;
        const received =
          s.type === 'outbound-rtp' ? s.packetsSent : s.packetsReceived;
        const lost = s.packetsLost ?? remote?.packetsLost;
        const energy = s.totalAudioEnergy ?? source?.totalAudioEnergy ?? 0,
          duration =
            s.totalSamplesDuration ?? source?.totalSamplesDuration ?? 0;
        const prev = this.previous.get(key);
        const outbound = s.type === 'outbound-rtp';
        const feedbackAt =
          typeof remote?.timestamp === 'number' ? remote.timestamp : undefined;
        // RTCP receiver reports arrive less often than local stats. Keep the
        // send-counter baseline until a NEW report, rather than dividing loss
        // over several seconds by only the last 500 ms of sent packets.
        const freshFeedback =
          !outbound ||
          (feedbackAt !== undefined && feedbackAt !== prev?.feedbackAt);
        const dr =
          typeof prev?.received === 'number' && typeof received === 'number'
            ? received - prev.received
            : 0;
        const dl =
          typeof prev?.lost === 'number' && typeof lost === 'number'
            ? Math.max(0, lost - prev.lost)
            : 0;
        const total = s.type === 'outbound-rtp' ? dr : dr + dl;
        const measuredLoss =
          freshFeedback &&
          typeof prev?.lost === 'number' &&
          typeof lost === 'number' &&
          dr >= 0 &&
          total > 0
            ? Math.min(100, (dl / total) * 100)
            : undefined;
        const loss =
          measuredLoss ??
          (outbound && prev?.lossAt !== undefined && now - prev.lossAt < 5000
            ? prev.lossPercent
            : undefined);
        this.previous.set(key, {
          received: freshFeedback ? received : prev?.received,
          lost: freshFeedback ? lost : prev?.lost,
          energy,
          duration,
          feedbackAt,
          lossPercent: loss,
          lossAt: measuredLoss !== undefined ? now : prev?.lossAt,
        });
        const currentRtt =
          typeof remote?.roundTripTime === 'number'
            ? remote.roundTripTime * 1000
            : rtt;
        if (
          s.type !== 'media-source' &&
          (currentRtt !== undefined || loss !== undefined)
        ) {
          const previous = network[user];
          const rtts = [currentRtt, previous?.rttMs].filter(
            (value): value is number =>
              typeof value === 'number' && Number.isFinite(value) && value >= 0,
          );
          network[user] = {
            rttMs: rtts.length ? Math.max(...rtts) : undefined,
            lossPercent:
              loss === undefined
                ? previous?.lossPercent
                : Math.max(loss, previous?.lossPercent ?? 0),
            sampledAt: now,
          };
        }
        if (
          item.kind === 'audio' &&
          item.track.enabled &&
          !item.track.muted &&
          item.track.readyState === 'live'
        ) {
          const delta =
            prev && duration > prev.duration
              ? Math.sqrt(
                  Math.max(0, energy - prev.energy) /
                    (duration - prev.duration),
                )
              : 0;
          const level =
            typeof s.audioLevel === 'number'
              ? s.audioLevel
              : typeof source?.audioLevel === 'number'
                ? source.audioLevel
                : delta;
          if (level > 0.025) {
            levels.set(user, Math.max(level, levels.get(user) ?? 0));
            this.speakingUntil.set(user, now + 900);
          }
        }
      });
    }
    const active =
      [...levels].sort((a, b) => b[1] - a[1])[0]?.[0] ??
      [...this.speakingUntil].find(
        ([user, until]) =>
          until > now &&
          tracks.some(
            (t) =>
              t.username === user &&
              t.kind === 'audio' &&
              t.track.enabled &&
              !t.track.muted,
          ),
      )?.[0] ??
      null;
    return { active, network };
  }
  stop() {
    ++this.epoch;
    if (this.timer) clearInterval(this.timer);
    this.timer = null;
    if (
      typeof window !== 'undefined' &&
      this.native &&
      window.RTCPeerConnection === this.wrapper
    )
      window.RTCPeerConnection = this.native;
    this.native = null;
    this.wrapper = null;
    this.peers.clear();
    this.previous.clear();
    this.speakingUntil.clear();
  }
}
