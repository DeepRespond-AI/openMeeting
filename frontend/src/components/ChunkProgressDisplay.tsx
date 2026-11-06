'use client';

import React from 'react';
import { CheckCircle2, Clock, Loader2, Timer, XCircle, PartyPopper } from 'lucide-react';
import { useT } from '@/i18n';
import { cn } from '@/lib/utils';

export interface ChunkStatus {
  chunk_id: number;
  status: 'pending' | 'processing' | 'completed' | 'failed';
  start_time?: number;
  end_time?: number;
  duration_ms?: number;
  text_preview?: string;
  error_message?: string;
}

export interface ProcessingProgress {
  total_chunks: number;
  completed_chunks: number;
  processing_chunks: number;
  failed_chunks: number;
  estimated_remaining_ms?: number;
  chunks: ChunkStatus[];
}

interface ChunkProgressDisplayProps {
  progress: ProcessingProgress;
  onPause?: () => void;
  onResume?: () => void;
  onCancel?: () => void;
  isPaused?: boolean;
  className?: string;
}

type TFn = ReturnType<typeof useT>;

function formatDuration(ms: number, t: TFn): string {
  const seconds = Math.floor(ms / 1000);
  const minutes = Math.floor(seconds / 60);
  const hours = Math.floor(minutes / 60);
  if (hours > 0) return t('recording.chunks.hours', { h: hours, m: minutes % 60, s: seconds % 60 });
  if (minutes > 0) return t('recording.chunks.minutes', { m: minutes, s: seconds % 60 });
  return t('recording.chunks.seconds', { s: seconds });
}

const STATUS_STYLE: Record<ChunkStatus['status'], string> = {
  completed: 'border-success/20 bg-success/5 text-success',
  processing: 'border-primary/20 bg-accent text-accent-foreground',
  failed: 'border-destructive/20 bg-destructive/5 text-destructive',
  pending: 'border-border bg-muted text-muted-foreground',
};

function StatusIcon({ status }: { status: ChunkStatus['status'] }) {
  switch (status) {
    case 'completed':
      return <CheckCircle2 className="h-3.5 w-3.5" />;
    case 'processing':
      return <Loader2 className="h-3.5 w-3.5 animate-spin" />;
    case 'failed':
      return <XCircle className="h-3.5 w-3.5" />;
    case 'pending':
    default:
      return <Clock className="h-3.5 w-3.5" />;
  }
}

export function ChunkProgressDisplay({
  progress,
  onPause,
  onResume,
  onCancel,
  isPaused = false,
  className = ''
}: ChunkProgressDisplayProps) {
  const t = useT();
  const completionPercentage = progress.total_chunks > 0
    ? Math.round((progress.completed_chunks / progress.total_chunks) * 100)
    : 0;
  const pendingCount = progress.total_chunks - progress.completed_chunks - progress.processing_chunks - progress.failed_chunks;

  const formatTimeRemaining = (ms?: number) => {
    if (!ms || ms <= 0) return t('recording.chunks.calculating');
    return formatDuration(ms, t);
  };

  const stats = [
    { value: progress.completed_chunks, label: t('recording.chunks.completed'), color: 'text-success' },
    { value: progress.processing_chunks, label: t('recording.chunks.processing'), color: 'text-primary' },
    { value: pendingCount, label: t('recording.chunks.pending'), color: 'text-muted-foreground' },
    { value: progress.failed_chunks, label: t('recording.chunks.failed'), color: 'text-destructive' },
  ];

  return (
    <div className={cn('rounded-xl border border-border bg-card p-5 shadow-card', className)}>
      {/* Progress Header */}
      <div className="mb-4 flex flex-wrap items-center justify-between gap-3">
        <div className="flex items-center gap-3">
          <h3 className="text-base font-semibold text-foreground">{t('recording.chunks.title')}</h3>
          {isPaused && (
            <span className="rounded-full bg-warning/10 px-2 py-0.5 text-xs font-medium text-warning">
              {t('recording.chunks.paused')}
            </span>
          )}
        </div>

        <div className="flex items-center gap-2">
          {!isPaused ? (
            <button
              type="button"
              onClick={onPause}
              className="rounded-lg border border-border bg-card px-3 py-1.5 text-sm font-medium text-foreground transition-colors hover:bg-muted disabled:opacity-50"
              disabled={progress.processing_chunks === 0 && progress.completed_chunks === progress.total_chunks}
            >
              {t('recording.chunks.pause')}
            </button>
          ) : (
            <button
              type="button"
              onClick={onResume}
              className="rounded-lg bg-primary px-3 py-1.5 text-sm font-medium text-primary-foreground transition-colors hover:bg-primary/90"
            >
              {t('recording.chunks.resume')}
            </button>
          )}

          <button
            type="button"
            onClick={onCancel}
            className="rounded-lg px-3 py-1.5 text-sm font-medium text-destructive transition-colors hover:bg-destructive/10"
          >
            {t('recording.chunks.cancel')}
          </button>
        </div>
      </div>

      {/* Progress Bar */}
      <div className="mb-4">
        <div className="mb-2 flex items-center justify-between text-sm font-medium text-foreground">
          <span>{t('recording.chunks.completedOf', { done: progress.completed_chunks, total: progress.total_chunks })}</span>
          <span className="tabular-nums">{completionPercentage}%</span>
        </div>
        <div className="h-2 w-full overflow-hidden rounded-full bg-muted">
          <div
            className="h-2 rounded-full bg-primary transition-all duration-300 ease-out"
            style={{ width: `${completionPercentage}%` }}
          />
        </div>
      </div>

      {/* Processing Stats */}
      <div className="mb-4 grid grid-cols-4 gap-3 text-sm">
        {stats.map((stat) => (
          <div key={stat.label} className="rounded-lg bg-muted/60 py-2 text-center">
            <div className={cn('text-lg font-semibold tabular-nums', stat.color)}>{stat.value}</div>
            <div className="text-xs text-muted-foreground">{stat.label}</div>
          </div>
        ))}
      </div>

      {/* Time Estimate */}
      {progress.estimated_remaining_ms && progress.estimated_remaining_ms > 0 && (
        <div className="mb-4 flex items-center gap-2 rounded-lg bg-accent p-3 text-sm text-accent-foreground">
          <Timer className="h-4 w-4" />
          <span>{t('recording.chunks.remaining', { time: formatTimeRemaining(progress.estimated_remaining_ms) })}</span>
        </div>
      )}

      {/* Recent Chunks */}
      <div className="space-y-2">
        <h4 className="text-sm font-medium text-foreground">
          {t('recording.chunks.recent', { shown: Math.min(progress.chunks.length, 10), total: progress.total_chunks })}
        </h4>

        <div className="max-h-48 space-y-1 overflow-y-auto">
          {progress.chunks
            .slice(-10) // Show last 10 chunks
            .reverse() // Most recent first
            .map((chunk) => (
              <div key={chunk.chunk_id} className={cn('rounded-lg border p-2 text-xs', STATUS_STYLE[chunk.status])}>
                <div className="flex items-center gap-2">
                  <StatusIcon status={chunk.status} />
                  <span className="font-medium">{t('recording.chunks.chunk', { id: chunk.chunk_id })}</span>
                  {chunk.duration_ms && (
                    <span className="text-muted-foreground">({formatDuration(chunk.duration_ms, t)})</span>
                  )}
                </div>

                {chunk.text_preview && (
                  <div className="mt-1 truncate text-foreground/80">&ldquo;{chunk.text_preview}&rdquo;</div>
                )}

                {chunk.error_message && (
                  <div className="mt-1 text-destructive">{t('recording.chunks.error', { message: chunk.error_message })}</div>
                )}
              </div>
            ))}
        </div>
      </div>

      {/* Processing Complete */}
      {progress.completed_chunks === progress.total_chunks && progress.total_chunks > 0 && (
        <div className="mt-4 flex items-center gap-2 rounded-lg bg-success/10 p-3 text-sm font-medium text-success">
          <PartyPopper className="h-4 w-4" />
          <span>{t('recording.chunks.allDone', { total: progress.total_chunks })}</span>
        </div>
      )}
    </div>
  );
}

// Mini version for sidebar or compact display
export function ChunkProgressMini({ progress, className = '' }: { progress: ProcessingProgress; className?: string }) {
  const t = useT();
  const completionPercentage = progress.total_chunks > 0
    ? Math.round((progress.completed_chunks / progress.total_chunks) * 100)
    : 0;

  return (
    <div className={cn('rounded-lg border border-border bg-muted/60 p-3', className)}>
      <div className="mb-2 flex items-center justify-between text-sm font-medium text-foreground">
        <span>{t('recording.chunks.miniTitle')}</span>
        <span className="tabular-nums">{completionPercentage}%</span>
      </div>

      <div className="mb-2 h-1.5 w-full overflow-hidden rounded-full bg-muted">
        <div
          className="h-1.5 rounded-full bg-primary transition-all duration-300"
          style={{ width: `${completionPercentage}%` }}
        />
      </div>

      <div className="text-xs text-muted-foreground">
        {t('recording.chunks.miniCount', { done: progress.completed_chunks, total: progress.total_chunks })}
        {progress.processing_chunks > 0 && (
          <span className="ml-2 text-primary">
            {t('recording.chunks.miniProcessing', { count: progress.processing_chunks })}
          </span>
        )}
      </div>
    </div>
  );
}
