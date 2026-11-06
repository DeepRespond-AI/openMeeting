"use client";

import { useMemo } from 'react';
import { Copy, FileText } from 'lucide-react';
import { Transcript, TranscriptSegmentData } from '@/types';
import { useT } from '@/i18n';
import Analytics from '@/lib/analytics';
import { MeetingTranscriptList } from './MeetingTranscriptList';
import type { TranscriptEmptyState } from '@/lib/meeting-processing';

interface TranscriptPanelProps {
  readOnly?: boolean;
  transcripts: Transcript[];
  customPrompt: string;
  onPromptChange: (value: string) => void;
  onCopyTranscript: () => void;
  isRecording: boolean;
  /** Background work (import transcription / post-recording sync) is still running. */
  isProcessing?: boolean;
  emptyState?: TranscriptEmptyState;

  // Optional pagination props (when using virtualization)
  usePagination?: boolean;
  segments?: TranscriptSegmentData[];
  hasMore?: boolean;
  isLoadingMore?: boolean;
  totalCount?: number;
  loadedCount?: number;
  onLoadMore?: () => void;
}

/** Transcript card: header with count + copy, timestamped rows, and the AI-summary context box. */
export function TranscriptPanel({
  readOnly = false,
  transcripts,
  customPrompt,
  onPromptChange,
  onCopyTranscript,
  isRecording,
  isProcessing = false,
  emptyState,
  usePagination = false,
  segments,
  hasMore,
  isLoadingMore,
  totalCount,
  loadedCount,
  onLoadMore,
}: TranscriptPanelProps) {
  const t = useT();

  // Convert transcripts to segments when the caller doesn't paginate
  const convertedSegments = useMemo(() => {
    if (usePagination && segments) {
      return segments;
    }
    return transcripts.map(tr => ({
      id: tr.id,
      timestamp: tr.audio_start_time ?? 0,
      endTime: tr.audio_end_time,
      text: tr.text,
      speaker: tr.speaker,
      confidence: tr.confidence,
    }));
  }, [transcripts, usePagination, segments]);

  const count = usePagination ? (totalCount ?? convertedSegments.length) : (transcripts?.length || 0);

  return (
    <section className="flex h-full min-w-0 w-full flex-col overflow-hidden rounded-xl border border-border bg-card shadow-card">
      <header className="flex shrink-0 items-center justify-between gap-3 border-b border-border px-5 py-3.5">
        {/* The h-8 copy button sets the row height; the AI summary header matches it (min-h-8). */}
        <div className="flex min-w-0 items-center gap-2">
          <FileText className="h-4 w-4 shrink-0 text-primary" />
          <h2 className="truncate text-base font-semibold text-foreground">{t('meeting.transcript.title')}</h2>
          {count > 0 && (
            <span className="shrink-0 rounded-full bg-secondary px-2 py-0.5 text-xs font-medium text-muted-foreground">
              {t('meeting.header.segments', { n: count })}
            </span>
          )}
        </div>
        <button
          type="button"
          disabled={count === 0}
          onClick={() => {
            Analytics.trackButtonClick('copy_transcript', 'meeting_details');
            onCopyTranscript();
          }}
          title={t('meeting.actions.copyTranscript')}
          aria-label={t('meeting.actions.copyTranscript')}
          className="inline-flex h-8 w-8 shrink-0 items-center justify-center rounded-lg text-muted-foreground transition-colors hover:bg-accent hover:text-accent-foreground disabled:pointer-events-none disabled:opacity-40"
        >
          <Copy className="h-4 w-4" />
        </button>
      </header>

      <div className="min-h-0 flex-1">
        <MeetingTranscriptList
          segments={convertedSegments}
          hasMore={hasMore}
          isLoadingMore={isLoadingMore}
          totalCount={totalCount}
          loadedCount={loadedCount}
          onLoadMore={onLoadMore}
          isProcessing={isProcessing}
          emptyState={emptyState}
        />
      </div>

      {/* Extra context sent with the next AI summary request */}
      {!readOnly && !isRecording && convertedSegments.length > 0 && (
        <div className="shrink-0 border-t border-border bg-muted/40 px-4 py-3">
          <label htmlFor="summary-context" className="mb-1.5 block text-xs font-medium text-muted-foreground">
            {t('meeting.transcript.contextLabel')}
          </label>
          <textarea
            id="summary-context"
            placeholder={t('meeting.transcript.contextPlaceholder')}
            className="min-h-[64px] w-full resize-y rounded-lg border border-input bg-card px-3 py-2 text-sm text-foreground shadow-sm placeholder:text-muted-foreground focus:border-primary focus:outline-none focus:ring-2 focus:ring-ring/30"
            value={customPrompt}
            onChange={(e) => onPromptChange(e.target.value)}
          />
        </div>
      )}
    </section>
  );
}
