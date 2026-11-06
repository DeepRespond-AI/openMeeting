'use client';

import { VirtualizedTranscriptView } from '@/components/VirtualizedTranscriptView';
import { PermissionWarning } from '@/components/PermissionWarning';
import { Button } from '@/components/ui/button';
import { Copy, AudioLines } from 'lucide-react';
import { useTranscripts } from '@/contexts/TranscriptContext';
import { useRecordingState } from '@/contexts/RecordingStateContext';
import { useConfig } from '@/contexts/ConfigContext';
import { usePermissionCheck } from '@/hooks/usePermissionCheck';
import { useIsLinux } from '@/hooks/usePlatform';
import { useT } from '@/i18n';
import { cn } from '@/lib/utils';
import { useMemo, type ReactNode } from 'react';

/**
 * TranscriptPanel Component
 *
 * Live transcript card on the recording screen: header (title, segment count, copy)
 * and an auto-scrolling, virtualized list of timestamped segments.
 */

interface TranscriptPanelProps {
  // indicates stop-processing state for transcripts; derived from backend statuses.
  isProcessingStop: boolean;
  isStopping: boolean;
  /** Shown when idle and there is no transcript yet. */
  emptyState?: ReactNode;
  /** Right side of the card header (e.g. import button / recording status). */
  headerAction?: ReactNode;
  className?: string;
}

export function TranscriptPanel({
  isProcessingStop,
  isStopping,
  emptyState,
  headerAction,
  className,
}: TranscriptPanelProps) {
  const t = useT();
  // Contexts
  const { transcripts, transcriptContainerRef, copyTranscript } = useTranscripts();
  const { isRecording, isPaused } = useRecordingState();
  const { showConfidenceIndicator } = useConfig();
  const { checkPermissions, isChecking, hasSystemAudio, hasMicrophone } = usePermissionCheck();
  const isLinux = useIsLinux();

  // Convert transcripts to segments for virtualized view
  const segments = useMemo(() =>
    transcripts.map(tr => ({
      id: tr.id,
      timestamp: tr.audio_start_time ?? 0,
      endTime: tr.audio_end_time,
      text: tr.text,
      confidence: tr.confidence,
    })),
    [transcripts]
  );

  const hasTranscript = transcripts?.length > 0;

  return (
    <section
      ref={transcriptContainerRef}
      className={cn('flex min-h-0 flex-col overflow-hidden rounded-xl border border-border bg-card shadow-card', className)}
    >
      {/* Card header */}
      <div className="flex items-center justify-between gap-3 border-b border-border px-5 py-3">
        <div className="flex min-w-0 items-center gap-2">
          <AudioLines className="h-4 w-4 shrink-0 text-primary" />
          <h2 className="truncate text-base font-semibold text-foreground">{t('transcript.title')}</h2>
          {hasTranscript && (
            <span className="shrink-0 rounded-full bg-muted px-2 py-0.5 text-xs text-muted-foreground tabular-nums">
              {t('transcript.segmentCount', { count: transcripts.length })}
            </span>
          )}
        </div>
        <div className="flex shrink-0 items-center gap-2">
          {hasTranscript && (
            <Button
              variant="ghost"
              size="sm"
              onClick={copyTranscript}
              title={t('transcript.copyTitle')}
              className="shrink-0 text-muted-foreground"
            >
              <Copy />
              <span>{t('transcript.copy')}</span>
            </Button>
          )}
          {headerAction}
        </div>
      </div>

      {/* Permission Warning - Not needed on Linux */}
      {!isRecording && !isChecking && !isLinux && (!hasMicrophone || !hasSystemAudio) && (
        <div className="border-b border-border px-5 py-3">
          <PermissionWarning
            hasMicrophone={hasMicrophone}
            hasSystemAudio={hasSystemAudio}
            onRecheck={checkPermissions}
            isRechecking={isChecking}
          />
        </div>
      )}

      {/* Transcript content */}
      <div className="min-h-0 flex-1 px-2">
        <VirtualizedTranscriptView
          segments={segments}
          isRecording={isRecording}
          isPaused={isPaused}
          isProcessing={isProcessingStop}
          isStopping={isStopping}
          enableStreaming={isRecording}
          showConfidence={showConfidenceIndicator}
          showStatusBar={false}
          emptyState={emptyState}
        />
      </div>
    </section>
  );
}
