"use client";

import { useCallback, useEffect, useRef, useState } from 'react';
import { convertFileSrc, invoke } from '@tauri-apps/api/core';
import { listen } from '@tauri-apps/api/event';
import { AudioLines, Download, Loader2, Pause, Play, RotateCcw, RotateCw } from 'lucide-react';
import { toast } from 'sonner';
import { fetchMeetingAudio } from '@/lib/server';
import { useT } from '@/i18n';
import { cn } from '@/lib/utils';
import { formatClock } from '@/hooks/meeting-details/languageLabels';
import { useMeetingAudio } from './MeetingAudioContext';

interface MeetingAudioPlayerProps {
  meetingId: string;
  className?: string;
}

type AudioState =
  | { kind: 'idle' }
  | { kind: 'loading'; percent?: number }
  | { kind: 'ready'; src: string }
  | { kind: 'error'; message: string };

const SPEEDS = [1, 1.25, 1.5, 2, 0.75];

/**
 * Plays the meeting recording. If the local recording is missing, Rust downloads
 * it from the server (OSS) into the recordings folder only after a cloud-download click
 * (`server_fetch_meeting_audio`, progress via `audio-download-progress`) and
 * returns a local path that we hand to the webview through the asset protocol.
 * Playback state is shared through MeetingAudioContext so transcript rows can seek.
 */
export function MeetingAudioPlayer({ meetingId, className }: MeetingAudioPlayerProps) {
  const t = useT();
  const sync = useMeetingAudio();
  const audioRef = useRef<HTMLAudioElement | null>(null);
  const [state, setState] = useState<AudioState>({ kind: 'idle' });
  const generation = useRef(0);
  const downloadingRef = useRef(false);
  const [time, setTime] = useState(0);
  const [duration, setDuration] = useState<number | null>(null);
  const [playing, setPlaying] = useState(false);
  const [speedIndex, setSpeedIndex] = useState(0);
  const [downloading, setDownloading] = useState(false);
  const [downloadError, setDownloadError] = useState<string | null>(null);
  const download = async () => {
    if (downloadingRef.current) return;
    const owner = generation.current;
    downloadingRef.current = true;
    setDownloading(true); setDownloadError(null); setState({ kind: 'loading' });
    try {
      const saved = await fetchMeetingAudio(meetingId);
      if (owner !== generation.current) return;
      if (!saved) throw new Error(t('meeting.shared.noAudio'));
      setState({ kind: 'ready', src: convertFileSrc(saved) });
      toast.success(t('meeting.shared.downloaded'), { description: saved,
        action: { label: t('meeting.actions.openFolder'), onClick: () => {
          void invoke('open_meeting_folder', { meetingId }).catch(error => toast.error(String(error)));
        } }, duration: 10000, position: 'bottom-right' });
    } catch (error) {
      if (owner === generation.current) {
        setDownloadError(String(error));
        setState({ kind: 'error', message: String(error) });
      }
    } finally {
      if (owner === generation.current) { downloadingRef.current = false; setDownloading(false); }
    }
  };

  useEffect(() => {
    const owner = ++generation.current;
    setState({ kind: 'idle' }); setTime(0); setDuration(null); setPlaying(false); setSpeedIndex(0);
    setDownloading(false); setDownloadError(null); downloadingRef.current = false;
    const unlisten = listen<{ meetingId: string; progress: number }>('audio-download-progress', (event) => {
      if (generation.current !== owner || event.payload.meetingId !== meetingId) return;
      setState((prev) => (prev.kind === 'loading' ? { kind: 'loading', percent: event.payload.progress } : prev));
    });
    return () => {
      generation.current++;
      void unlisten.then((fn) => fn()).catch(() => {});
    };
  }, [meetingId]);

  const registerAudio = sync?.registerAudio;
  const attachAudio = useCallback((el: HTMLAudioElement | null) => {
    audioRef.current = el;
    registerAudio?.(el);
  }, [registerAudio]);

  const togglePlay = useCallback(() => {
    const el = audioRef.current;
    if (!el) return;
    if (el.paused) void el.play().catch((error) => console.warn('[MeetingAudioPlayer] play() rejected:', error));
    else el.pause();
  }, []);

  const skip = useCallback((delta: number) => {
    const el = audioRef.current;
    if (!el) return;
    const max = Number.isFinite(el.duration) ? el.duration : Infinity;
    el.currentTime = Math.min(max, Math.max(0, el.currentTime + delta));
  }, []);

  const cycleSpeed = useCallback(() => {
    setSpeedIndex((i) => {
      const next = (i + 1) % SPEEDS.length;
      if (audioRef.current) audioRef.current.playbackRate = SPEEDS[next];
      return next;
    });
  }, []);

  const progress = duration ? Math.min(100, (time / duration) * 100) : 0;
  const isReady = state.kind === 'ready';

  return (
    <div
      className={cn(
        'flex flex-wrap items-center gap-3 rounded-xl border border-border bg-card px-4 py-2.5 shadow-card',
        className,
      )}
      aria-label={t('meeting.audio.label')}
      data-testid="meeting-audio-player"
      data-state={state.kind}
      role="group"
    >
      <button type="button" onClick={() => void download()} disabled={downloading || state.kind === 'loading'}
        className="inline-flex shrink-0 items-center gap-1.5 rounded-lg px-2 py-1.5 text-sm text-primary hover:bg-accent disabled:opacity-50"
        aria-label={t('meeting.shared.downloadAudio')} data-testid="download-meeting-audio">
        {downloading ? <Loader2 className="h-4 w-4 animate-spin" /> : <Download className="h-4 w-4" />}
        {t(downloading ? 'meeting.shared.downloading' : 'meeting.shared.downloadAudio')}
      </button>
      {downloadError && <p role="alert" className="w-full break-words text-xs text-destructive">{downloadError}</p>}
      {state.kind === 'idle' && <p className="flex min-w-0 items-center gap-2 text-sm text-muted-foreground"><AudioLines className="h-4 w-4 shrink-0" />{t('meeting.audio.cloudHint')}</p>}
      {state.kind === 'loading' && (
        <div className="flex h-9 items-center gap-2 text-sm text-muted-foreground">
          <Loader2 className="h-4 w-4 animate-spin text-primary" />
          {state.percent === undefined
            ? t('meeting.audio.loading')
            : t('meeting.audio.downloading', { percent: state.percent })}
        </div>
      )}

      {state.kind === 'error' && (
        <div className="flex h-9 w-full items-center justify-between gap-3 text-sm">
          <span className="flex min-w-0 items-center gap-2 text-destructive" title={state.message}>
            <AudioLines className="h-4 w-4 shrink-0" />
            <span className="truncate">{t('meeting.audio.loadFailed')}</span>
          </span>
          <button
            type="button"
            onClick={() => void download()}
            className="inline-flex shrink-0 items-center gap-1.5 rounded-lg px-2.5 py-1.5 text-sm font-medium text-primary hover:bg-accent"
          >
            <RotateCw className="h-4 w-4" />
            {t('common.actions.retry')}
          </button>
        </div>
      )}

      {isReady && (
        <>
          <audio
            ref={attachAudio}
            key={state.src}
            preload="metadata"
            src={state.src}
            className="hidden"
            onLoadedMetadata={(e) => {
              const d = e.currentTarget.duration;
              const value = Number.isFinite(d) ? d : null;
              setDuration(value);
              sync?.setDuration(value);
              sync?.setReady(true);
              e.currentTarget.playbackRate = SPEEDS[speedIndex];
            }}
            onTimeUpdate={(e) => {
              setTime(e.currentTarget.currentTime);
              sync?.setCurrentTime(e.currentTarget.currentTime);
            }}
            onPlay={() => { setPlaying(true); sync?.setIsPlaying(true); }}
            onPause={() => { setPlaying(false); sync?.setIsPlaying(false); }}
            onEnded={() => { setPlaying(false); sync?.setIsPlaying(false); }}
            onError={() => setState({ kind: 'error', message: t('meeting.audio.playFailed') })}
          />

          <div className="flex shrink-0 items-center gap-1">
            <button
              type="button"
              onClick={() => skip(-10)}
              title={t('meeting.audio.back')}
              aria-label={t('meeting.audio.back')}
              className="hidden h-8 w-8 items-center justify-center rounded-lg text-muted-foreground hover:bg-accent hover:text-accent-foreground sm:inline-flex"
            >
              <RotateCcw className="h-4 w-4" />
            </button>
            <button
              type="button"
              onClick={togglePlay}
              title={playing ? t('meeting.audio.pause') : t('meeting.audio.play')}
              aria-label={playing ? t('meeting.audio.pause') : t('meeting.audio.play')}
              className="inline-flex h-9 w-9 items-center justify-center rounded-full bg-primary text-primary-foreground shadow-sm transition-colors hover:bg-primary/90"
            >
              {playing ? <Pause className="h-4 w-4" fill="currentColor" /> : <Play className="ml-0.5 h-4 w-4" fill="currentColor" />}
            </button>
            <button
              type="button"
              onClick={() => skip(10)}
              title={t('meeting.audio.forward')}
              aria-label={t('meeting.audio.forward')}
              className="hidden h-8 w-8 items-center justify-center rounded-lg text-muted-foreground hover:bg-accent hover:text-accent-foreground sm:inline-flex"
            >
              <RotateCw className="h-4 w-4" />
            </button>
          </div>

          <span className="w-12 shrink-0 text-right text-xs tabular-nums text-muted-foreground">{formatClock(time)}</span>

          {/* Progress: visual track + transparent native range for seeking and keyboard access */}
          <div className="group relative flex h-5 min-w-0 flex-1 items-center">
            <div className="h-1.5 w-full overflow-hidden rounded-full bg-muted">
              <div className="h-full rounded-full bg-primary" style={{ width: `${progress}%` }} />
            </div>
            <div
              className="pointer-events-none absolute h-3.5 w-3.5 -translate-x-1/2 rounded-full border-2 border-primary bg-card shadow-sm opacity-0 transition-opacity group-hover:opacity-100"
              style={{ left: `${progress}%` }}
            />
            <input
              type="range"
              min={0}
              max={duration ?? 0}
              step={0.1}
              value={Math.min(time, duration ?? 0)}
              disabled={!duration}
              aria-label={t('meeting.audio.seek')}
              aria-valuetext={`${formatClock(time)} / ${formatClock(duration)}`}
              onChange={(e) => {
                const el = audioRef.current;
                if (!el) return;
                el.currentTime = Number(e.target.value);
                setTime(el.currentTime);
              }}
              className="absolute inset-0 h-full w-full cursor-pointer opacity-0 disabled:cursor-default"
            />
          </div>

          <span className="w-12 shrink-0 text-xs tabular-nums text-muted-foreground">{formatClock(duration)}</span>

          <button
            type="button"
            onClick={cycleSpeed}
            title={t('meeting.audio.speed')}
            aria-label={t('meeting.audio.speed')}
            className="shrink-0 rounded-full bg-secondary px-2.5 py-1 text-xs font-medium tabular-nums text-secondary-foreground hover:bg-accent hover:text-accent-foreground"
          >
            {SPEEDS[speedIndex]}×
          </button>
        </>
      )}
    </div>
  );
}
