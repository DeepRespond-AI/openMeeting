'use client';

import { motion } from 'framer-motion';
import { useRecordingState, RecordingStatus } from '@/contexts/RecordingStateContext';
import { useT } from '@/i18n';
import { cn } from '@/lib/utils';

/** Formats seconds as MM:SS, or H:MM:SS past one hour. */
export function formatElapsed(totalSeconds: number): string {
  const s = Math.max(0, Math.floor(totalSeconds));
  const h = Math.floor(s / 3600);
  const m = Math.floor((s % 3600) / 60);
  const sec = s % 60;
  const mm = m.toString().padStart(2, '0');
  const ss = sec.toString().padStart(2, '0');
  return h > 0 ? `${h}:${mm}:${ss}` : `${mm}:${ss}`;
}

/** Active recording time (excluding pauses), synced from the backend every ~500ms. */
function useElapsedSeconds(): number {
  const { activeDuration } = useRecordingState();
  return activeDuration !== null ? Math.floor(activeDuration) : 0;
}

type ChipTone = 'idle' | 'live' | 'paused' | 'busy' | 'done' | 'error';

const TONE_CLASS: Record<ChipTone, string> = {
  idle: 'bg-muted text-muted-foreground',
  live: 'bg-destructive/10 text-destructive',
  paused: 'bg-warning/10 text-warning',
  busy: 'bg-accent text-accent-foreground',
  done: 'bg-success/10 text-success',
  error: 'bg-destructive/10 text-destructive',
};

const DOT_CLASS: Record<ChipTone, string> = {
  idle: 'bg-muted-foreground/50',
  live: 'bg-destructive animate-pulse',
  paused: 'bg-warning',
  busy: 'bg-primary animate-pulse',
  done: 'bg-success',
  error: 'bg-destructive',
};

/**
 * Header status chip for the recording screen: 未开始 / 录音中 00:12 / 已暂停 00:12 / …
 */
export function RecordingStatusChip({ className }: { className?: string }) {
  const t = useT();
  const { status, isRecording, isPaused } = useRecordingState();
  const elapsed = useElapsedSeconds();

  let tone: ChipTone = 'idle';
  let label = t('home.status.idle');
  let showTimer = false;

  if (isRecording && isPaused) {
    tone = 'paused';
    label = t('home.status.paused');
    showTimer = true;
  } else if (isRecording && status !== RecordingStatus.STOPPING) {
    tone = 'live';
    label = t('home.status.recording');
    showTimer = true;
  } else {
    switch (status) {
      case RecordingStatus.STARTING:
        tone = 'busy';
        label = t('home.status.starting');
        break;
      case RecordingStatus.STOPPING:
        tone = 'busy';
        label = t('home.status.stopping');
        break;
      case RecordingStatus.PROCESSING_TRANSCRIPTS:
        tone = 'busy';
        label = t('home.status.processing');
        break;
      case RecordingStatus.SAVING:
        tone = 'busy';
        label = t('home.status.saving');
        break;
      case RecordingStatus.COMPLETED:
        tone = 'done';
        label = t('home.status.completed');
        break;
      case RecordingStatus.ERROR:
        tone = 'error';
        label = t('home.status.error');
        break;
    }
  }

  return (
    <div
      role="status"
      aria-live="polite"
      className={cn(
        'inline-flex shrink-0 items-center gap-2 rounded-full px-3 py-1 text-sm font-medium',
        TONE_CLASS[tone],
        className,
      )}
    >
      <span className={cn('h-2 w-2 rounded-full', DOT_CLASS[tone])} />
      <span>{label}</span>
      {showTimer && <span className="font-mono tabular-nums">{formatElapsed(elapsed)}</span>}
    </div>
  );
}

interface RecordingStatusBarProps {
  isPaused?: boolean;
}

/** Inline status row used inside transcript views while recording. */
export const RecordingStatusBar: React.FC<RecordingStatusBarProps> = ({ isPaused = false }) => {
  const t = useT();
  const elapsed = useElapsedSeconds();

  return (
    <motion.div
      initial={{ opacity: 0, y: -10 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, y: -10 }}
      transition={{ duration: 0.2 }}
      className={cn(
        'mb-2 inline-flex items-center gap-2 rounded-full px-3 py-1 text-sm font-medium',
        isPaused ? 'bg-warning/10 text-warning' : 'bg-destructive/10 text-destructive',
      )}
    >
      <span className={cn('h-2 w-2 rounded-full', isPaused ? 'bg-warning' : 'bg-destructive animate-pulse')} />
      <span>{isPaused ? t('home.status.paused') : t('home.status.recording')}</span>
      <span className="font-mono tabular-nums">{formatElapsed(elapsed)}</span>
    </motion.div>
  );
};
